// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error PriceSetter__InsufficientPriceDifference();
error PriceSetter__SymbolCantBeEmpty();

contract PriceSetter {
    mapping(string => uint256) public priceOf;

    // percent of minimum price difference
    uint256 public constant MIN_DIF = 2;

    event PriceChange(string indexed symbol, uint256 price, uint256 timestamp);

    modifier hasSymbol(string calldata _symbol) {
        if (bytes(_symbol).length == 0) revert PriceSetter__SymbolCantBeEmpty();
        _;
    }

    /*
     * @notice change the current price of a specific symbol
     * @param _symbol the symbol for which to change the price
     * @param _price the new price to be set
     * @dev new price difference needs to be higher than MIN_DIF
     */
    function set(string calldata _symbol, uint256 _price)
        public
        hasSymbol(_symbol)
    {
        uint256 currentPrice = priceOf[_symbol];

        if (getAbsDifference(currentPrice, _price) * 100 <= currentPrice * MIN_DIF) {
            revert PriceSetter__InsufficientPriceDifference();
        }

        priceOf[_symbol] = _price;

        emit PriceChange(_symbol, _price, block.timestamp);
    }

    /*
     * @notice get the absolute difference from two unsigned integers
     */
    function getAbsDifference(uint256 _a, uint256 _b)
        private
        pure
        returns (uint256)
    {
        return (_a >= _b) ? _a - _b : _b - _a;
    }
}