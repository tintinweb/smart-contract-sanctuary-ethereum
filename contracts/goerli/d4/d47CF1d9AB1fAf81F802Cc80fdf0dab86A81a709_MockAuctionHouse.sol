// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract MockAuctionHouse {
    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 nounId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    Auction public auction;

    function createAuction(
        uint256 nounId,
        uint256 startTime,
        uint256 endTime,
        bool settled
    ) external {
        auction = Auction({
        nounId : nounId,
        amount : 0,
        startTime : startTime,
        endTime : endTime,
        bidder : payable(0),
        settled : settled
        });
    }
}