// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import "./interfaces/IEnglishAuction.sol";

// @autor donBarbos
// @notice English auction is an open-outcry ascending dynamic auction. It proceeds as follows.
contract EnglishAuction is IEnglishAuction {
    // @dev default share of expected price in ppm (needed to calculate the starting price)
    uint private constant INITIAL_SHARE = 25000;   // =25%

    // @dev default offer step in ppm
    uint private constant STEP = 1000;              // =1%

    // @dev see `./interfaces/IEnglishAuction.sol`
    Auction[] public auctions;

    // @dev queue
    mapping(bytes32 => bool) public queue;

    // @note for incorrect calls
    receive() external payable{
        revert("incorrect call!");
    }

    fallback() external payable{
        revert("incorrect call!");
    }

    function createAuction(
        uint _expectedPrice,
        string memory _item,
        uint _step,
        uint _initialShare
    ) external {
        // @dev if _parameter of function is zero then use CONSTANT
        uint initialShare = _initialShare == 0 ? INITIAL_SHARE : _initialShare;
        uint step = _step == 0 ? STEP : _step;

        // @dev convert from ppm to units
        uint startingPrice = _expectedPrice * initialShare / 100000;
        step = startingPrice * step / 100000;

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            reservePrice: _expectedPrice,
            currentPrice: startingPrice,
            currentBuyer: payable(msg.sender),
            step: step,
            item: _item,
            stopped: false
        });
        auctions.push(newAuction);
        emit AuctionCreated(auctions.length - 1, _item, startingPrice, step);
    }

    function makeBid(uint index, uint _offer) external payable {
        Auction storage cAuction = auctions[index];

        require(!cAuction.stopped, "auction stopped!");
        require(msg.value >= _offer, "not enough funds!");
        require(_offer >= (cAuction.currentPrice + cAuction.step), "next offer should be bigger!");
        // cAuction.stopped = true;
        cAuction.currentPrice = _offer;
        uint refund = msg.value - _offer;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        // cAuction.seller.transfer(cPrice);
        uint _timestamp = block.timestamp + 1 days;
        addToQueue(index, _timestamp);
        emit AuctionUpdated(index, _offer, msg.sender);
    }

    function getPrice(uint index) external view returns(uint) {
        Auction memory cAuction = auctions[index];

        require(!cAuction.stopped, "auction stopped!");
        return cAuction.currentPrice;
    }

    function addToQueue(uint index, uint _timestamp) private returns(bytes32) {
        Auction storage cAuction = auctions[index];

        require(
            // _timestamp > block.timestamp + MINIMUM_DELAY &&
            // _timestamp < block.timestamp + MAXIMUM_DELAY,
            _timestamp >= block.timestamp + 1 days &&
            _timestamp <= block.timestamp + 100 days,
            "invalid timestamp"
        );
        bytes32 txId = keccak256(abi.encode(
            cAuction.seller,
            msg.sender,
            cAuction.currentPrice,
            cAuction.item,
            _timestamp
        ));

        // @dev check if there is such a transaction in the queue
        require(!queue[txId], "already queued!");

        queue[txId] = true;
        emit AuctionUpdated(index, cAuction.currentPrice, cAuction.currentBuyer);
        return txId;
    }

    function execute(uint index, uint _timestamp) external payable {
        Auction storage cAuction = auctions[index];

        require(
            block.timestamp > _timestamp,
            "too early!"
        );
        bytes32 txId = keccak256(abi.encode(
            cAuction.seller,
            msg.sender,
            cAuction.currentPrice,
            cAuction.item,
            _timestamp
        ));

        emit AuctionEnded(index, cAuction.currentPrice, cAuction.currentBuyer);

        // @dev check if there isn't such a transaction in the queue
        require(queue[txId], "not queued!");
        delete queue[txId];
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

// @title Interface for EnglishAuction
// @author donBarbos
interface IEnglishAuction {
    // @notice this struct is immutable
    // @param seller Seller address
    // @param reservePrice Minimum price that a seller would be willing to accept from a buyer
    // (minimum bid)
    // @param currentPrice The price of potential buyers now offers
    // @param step This is the amount by which the price of the lot can change
    // @param item Unique product identifier
    // @param stopped Auction status (Still going / Ended) at start: `false`
    struct Auction {
        address payable seller;
        uint reservePrice;
        uint currentPrice;
        address payable currentBuyer;
        uint step;
        string item;
        bool stopped;
    }

    event AuctionCreated(uint index, string itemName, uint startingPrice, uint step);
    event AuctionUpdated(uint index, uint newPrice, address newBuyer);
    event AuctionEnded(uint index, uint finalPrice, address winner);

    receive() external payable;

    fallback() external payable;

    function createAuction(
        uint _startingPrice,
        string memory _item,
        uint _step,
        uint _startingShare
    ) external;

    function makeBid(uint index, uint _offer) external payable;

    function getPrice(uint index) external view returns (uint);

    function execute(uint index, uint _timestamp) external payable;
}