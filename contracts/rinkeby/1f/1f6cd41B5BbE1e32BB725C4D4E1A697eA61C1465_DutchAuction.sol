// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Auction begins with a high asking price and
// lowers it until some participant accepts the price.
// The starting price is discounted every time x blocks pass
// where x is defined as the discountPeriod.
// The amount of the discount is defined as the discountValue

// Beneficiary: contract creator
// Time: based on block.number
// Bid visibility: open

contract DutchAuction {
    address public immutable beneficiary;
    uint256 public immutable startingPrice;
    uint256 public immutable discountValue;
    uint256 public immutable discountPeriod;
    uint256 public immutable startBlock;
    uint256 public immutable endBlock;
    bool public sold = false;

    /// @notice Create the auction. Beneficiary set to constructor
    /// caller and the auction starts with this transaction.
    /// @param _startingPrice the price to start the auction with
    /// @param _discountValue the value to discount the starting price every discount period
    /// @param _discountPeriod the number of blocks after passing the starting price is discounted
    /// @param _biddingBlocks the number of blocks the auction runs
    constructor(
        uint256 _startingPrice,
        uint256 _discountValue,
        uint256 _discountPeriod,
        uint256 _biddingBlocks
    ) {
        require(
            _startingPrice > _discountValue,
            "The starting price must be greater then discount value"
        );
        require(
            _discountValue > 0,
            "The discount value must be greater then 0"
        );
        require(
            _discountPeriod > 0,
            "The discount period must be greater then 0"
        );
        require(
            _biddingBlocks > 0,
            "The bidding period in blocks must be greater then 0"
        );

        startingPrice = _startingPrice;
        discountValue = _discountValue;
        discountPeriod = _discountPeriod;
        startBlock = block.number;
        endBlock = block.number + _biddingBlocks;
        beneficiary = payable(msg.sender);
        // NOTE: would need to transfer item to the contract here
    }

    /// @notice Get the current (discounted) price
    /// Discount is: floor(# discountPeriods passed) * discountValue
    /// The minium discounted price is set to the discountValue.
    /// @return discountedPrice
    function getPrice() public view returns (uint256 discountedPrice) {
        uint256 blocksPassed = block.number - startBlock;
        uint256 n = blocksPassed / discountPeriod;
        uint256 discount = discountValue * n;

        if (discount >= startingPrice) {
            discountedPrice = discountValue;
        } else {
            discountedPrice = startingPrice - discount;
        }
        return discountedPrice;
    }

    /// @notice Buy to the current (discounted) price. Excess is refunded.
    function buy() external payable {
        require(block.number < endBlock, "Auction expired");
        require(!sold, "Someone else was quicker");

        uint256 price = getPrice();
        require(msg.value >= price, "Not enough funds");

        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        payable(beneficiary).transfer(price);
        sold = true;

        // NOTE: would need to transfer item here too
    }
}