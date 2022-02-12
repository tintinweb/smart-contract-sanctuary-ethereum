// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "IAuction.sol";

contract Auction is IAuction {
    /// State variables

    // todo: change for the deployer
    address private constant ADMIN = 0x000000724350d0b24747bd816dC5031AcB7EFE0B;
    mapping(address => uint256) public bids;
    /// This would be inefficient to have on L1. But to avoid depending on
    /// the indexer, this saves a lot of time on L2
    address payable[] bidders;

    uint256 public constant MINIMUM_BID_INCREMENT = 0.1 ether;

    uint256 public floorPrice;
    uint256 public auctionEndBlock;
    address public whitelistedCollection;

    /// @dev true if active
    bool private auctionActive = false;
    bool private initialized = false;

    /// Modifiers

    modifier onlyOwner() {
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    /// Init

    /// @inheritdoc IAuction
    function initialize(
        uint256 initFloorPrice,
        uint256 initAuctionEndBlock,
        address initWhitelistedCollection
    ) external override onlyOwner {
        if (initialized) revert AlreadyInitialized();

        floorPrice = initFloorPrice;
        auctionEndBlock = initAuctionEndBlock;
        whitelistedCollection = initWhitelistedCollection;

        initialized = true;
    }

    /// Receiver

    /// @dev Reject direct contract payments
    receive() external payable {
        revert RejectDirectPayments();
    }

    /// Place Bid, Refund Bidders

    /// @inheritdoc IAuction
    function placeBid() external payable override {
        if (!auctionActive) revert AuctionNotActive();
        if (msg.value <= 0) revert NoEtherSent();
        if (msg.value < floorPrice)
            revert LessThanFloorPrice({actualSent: msg.value});
        /// Ensures that if the bidder has an existing bid, the delta that
        /// he sent, is at least MINIMUM_BID_INCREMENT
        if (bids[msg.sender] > 0) {
            if (msg.value > MINIMUM_BID_INCREMENT) {
                revert LessThanMinIncrement({actualSent: msg.value});
            }
            /// Do not need to add the bidder to bidders, since the bidder
            /// is already there
        } else {
            /// Would be expensive on L1
            bidders.push(payable(msg.sender));
        }

        bids[msg.sender] += msg.value;

        emit PlaceBid({bidder: msg.sender, price: msg.value});

        if (block.number >= auctionEndBlock) endAuction();
    }

    /// Admin

    /// @inheritdoc IAuction
    function refundBidders(
        uint256 losingThreshold,
        uint256 fromIx,
        uint256 toIx
    ) external override onlyOwner {
        if (auctionActive) revert AuctionIsActive();

        uint256 refundAmount;

        for (uint256 i = fromIx; i <= toIx; i++) {
            address payable bidder = bidders[i];

            if (bids[bidder] < losingThreshold) refundAmount = bids[bidder];

            (bool success, ) = bidder.call{value: refundAmount}("");
            if (!success) revert TransferFailed();

            emit RefundBid({bidder: bidder, refundAmount: refundAmount});
        }
    }

    function startAuction() external override onlyOwner {
        auctionActive = true;
        emit StartAuction();
    }

    function endAuction() internal {
        auctionActive = false;
        emit EndAuction();
    }

    function withdrawSaleProceeds() external onlyOwner {
        (bool success, ) = payable(ADMIN).call{value: address(this).balance}(
            ""
        );
        if (!success) revert TransferFailed();
    }
}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * Auction.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IAuction {
    error AlreadyInitialized();
    error AuctionIsActive();
    error AuctionNotActive();
    error LessThanFloorPrice(uint256 actualSent);
    error LessThanMinIncrement(uint256 actualSent);
    error NotAdmin();
    error NoEtherSent();
    error RejectDirectPayments();
    error TransferFailed();

    /// @notice Emitted when auction starts
    event StartAuction();
    /// @notice Emitted when auction ends
    event EndAuction();

    /// @notice Emitted when bid is placed
    /// @param bidder Address of the bidder
    /// @param price Amount the bidder has bid
    event PlaceBid(address indexed bidder, uint256 indexed price);
    /// @notice Emitted when lost bid was refunded
    /// @param bidder Address of the bidder that lost the auction
    /// @param refundAmount Amount the bidder is refunded
    event RefundBid(address indexed bidder, uint256 indexed refundAmount);

    /// @notice This function should be ran first thing after deploy.
    /// It initializes the state of the contract
    /// @param initFloorPrice Auction floor price
    /// @param initAuctionEndBlock Auction end block number
    /// @param initWhitelistedCollection Collection that is whitelisted to
    /// participate in the auction
    function initialize(
        uint256 initFloorPrice,
        uint256 initAuctionEndBlock,
        address initWhitelistedCollection
    ) external;

    /// @notice Starts the auction
    function startAuction() external;

    /// @notice Places the bid. Handles modifying the bid as well.
    /// If the same bidder calls this function again, then that alters
    /// their original bid
    function placeBid() external payable;

    /// @notice Refunds all the lost bids. Makes an assumption that
    /// the contract keeps track of all of the bids.
    /// @param losingThreshold Refund all the bids below this price
    /// @param fromIx Loop through all of the bidders starting at this index
    /// @param toIx Loop through all of the bidders ending at this index
    function refundBidders(
        uint256 losingThreshold,
        uint256 fromIx,
        uint256 toIx
    ) external;
}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * IAuction.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */