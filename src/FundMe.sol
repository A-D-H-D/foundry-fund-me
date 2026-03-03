// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
//import {AggregatorV3Interface} from "@chainlink/contracts/src/v1.3.0/shared/interfaces/AggregatorV3Interface.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";


error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private sAddressToAmountFunded;
    address[] private sFunders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private /* immutable */ iOwner;
    uint256 public constant MINIMUM_USD = 5e18;
    AggregatorV3Interface private sPriceFeed;

    constructor(address priceFeed) {
        iOwner = msg.sender;
        sPriceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(sPriceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        sAddressToAmountFunded[msg.sender] += msg.value;
        sFunders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return sPriceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != iOwner) revert NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < sFunders.length; funderIndex++) {
            address funder = sFunders[funderIndex];
            sAddressToAmountFunded[funder] = 0;
        }
        sFunders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }



    function getAddressToAmountFunded(address fundingAddress) public view returns(uint256){
        return sAddressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address){
        return sFunders[index];
    }

    // get entire array if needee
    function getAllFunders() external view returns(address[] memory){
        return sFunders;
    }

    function getOwner()external view returns(address){
        return iOwner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly