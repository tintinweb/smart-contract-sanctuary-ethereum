//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract sampleTimestamp {
    uint public auctionEndTime;
    string hiMessage;
    constructor(
        uint biddingTime,
        string memory message
    ) {
        auctionEndTime = block.timestamp + biddingTime;
        hiMessage = message;
        // console.log("block.timestamp 1 :", block.timestamp);
        // console.log("biddingTime 1 :", biddingTime);
        // console.log("auctionEndTime 1 :", auctionEndTime);
    }

    function getTimestamp() public view returns (string memory) {
        if (block.timestamp < auctionEndTime){
            return "message hide";
        }else{
            return hiMessage;
        }
    }
}