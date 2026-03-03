// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";


contract FundeMeTest is Test{
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SENDVALUE = 3 ether;
    uint256 constant STARTINGBALANCE = 10 ether;

    function setUp() external{
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);   
        DeployFundMe deployFundMe  = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(USER, STARTINGBALANCE);
    }

    function testMinimumDollarIsFive() public {
    assertEq(fundMe.MINIMUM_USD(), 5e18);  
    }

    function testOwnerIsMsender() public{
        // console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(),msg.sender);
    }

    function testVersionIsFour() public{
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function test_RevertWhen_NotEnoughEthSent() public{
        vm.expectRevert("You need to spend more ETH!");
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER);
        fundMe.fund{value: SENDVALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SENDVALUE);
    }

    function testAddressIsAdded() public{
        vm.prank(USER);
        fundMe.fund{value: SENDVALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SENDVALUE}();
        _;
    }

    function testOnlyUserWithdraw()public funded{
        // first we fund the contract then we use expect revert for the contract

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();

    }

    function testAddsFunderToArrayOfFunders() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testWithdrawWithSingleFunder() public funded {
        // OWNER = address(this) - the test contract
        uint256 startingOwnerBalance = fundMe.getOwner().balance;  // Test contract's ETH
        
        // USER = 0x6CA6d1... - our fake funder (already sent money via funded modifier)
        uint256 startingFundMeBalance = address(fundMe).balance;   // 3 ETH from USER
        
        // ACT: Owner withdraws (test contract impersonating itself)
        vm.prank(fundMe.getOwner());  // owner = address(this)
        fundMe.withdraw();
        
        // Money moves: FundMe contract (3 ETH) → Owner (test contract)

        uint256 endingOwnerBalance  = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance +startingOwnerBalance ,endingOwnerBalance);
}

}
