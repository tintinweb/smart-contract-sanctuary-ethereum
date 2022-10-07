// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import { Auction } from './Auction.sol';

contract AuctionFactory {
    address[] public auctions;
    
    event AuctionCreated(address auctionContract, address beneficiary, uint numAuctions, address[] allAuctions);

    function createAuction(uint _biddingTime, string memory _name, uint _bidMin, uint _energy) public {
        Auction newAuction = new Auction(_biddingTime, payable(msg.sender), _name, _bidMin, _energy);
        auctions.push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender, auctions.length, auctions);
    }

    function allAuctions() public view returns (address[] memory) {
        return auctions;
    }
}