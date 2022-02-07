/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct BidOffer {
    address payable addr;
    uint value;
}

contract MyEnergyAuction {

    address payable public auctionCompanyAddr;
    uint public energyMw;
    BidOffer[] public bids;

    BidOffer public auctionWinner;

    constructor(uint _energyMw) {
        auctionCompanyAddr = payable(msg.sender);
        energyMw = _energyMw;
    }

    // Create bid. Indicate a value!!
    function bid() public payable {
        require(msg.value > .01 ether);
        bids.push(BidOffer(payable(msg.sender), msg.value));
    }

    function closeAuction() public payable {
        require(msg.sender == auctionCompanyAddr);
        require(bids.length > 0);

        uint bestBidIndex = 0;

        // Get winner
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].value > bids[bestBidIndex].value) {
                bestBidIndex = i;
            }
        }
        auctionWinner = bids[bestBidIndex];

        // Return money to non winners
        for (uint i = 0; i < bids.length; i++) {
            if (i != bestBidIndex) {
                bids[i].addr.transfer(bids[i].value);
            }
        }

        // Send money of auction winner to contract founder
        auctionCompanyAddr.transfer(bids[bestBidIndex].value);
    }

    // Get current balance of contract
    function balance() public view returns (uint) {
        return address(this).balance;
    }
}