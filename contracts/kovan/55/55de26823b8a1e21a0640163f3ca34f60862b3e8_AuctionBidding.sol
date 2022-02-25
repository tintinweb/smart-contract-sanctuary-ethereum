/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

contract AuctionBidding {
    uint currentHighestBid;
    mapping(address => uint256) biddingMapping;

    function placeBid(address bidderAddress, uint bidCount) public {

        if (bidCount > currentHighestBid) {
            currentHighestBid = bidCount;
        }

        biddingMapping[bidderAddress] = bidCount;
    }

    function getHighestBid () public view returns (uint) {
        return currentHighestBid;
    }

    function getOwnBid(address bidderAddress) public view returns(uint) {
        return biddingMapping[bidderAddress];
    }
}