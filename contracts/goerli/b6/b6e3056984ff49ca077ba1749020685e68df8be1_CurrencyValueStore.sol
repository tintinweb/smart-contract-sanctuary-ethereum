/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CurrencyValueStore
 * @author Pavle Prica (https://github.com/pavleprica)
 * @dev set the current currency price
 * Used for storing current price of a currency, with a condition that it differs at least by 2%.
 * Supports up to 4 decimals. Expects all values to be provided like value * 10^4. Meaning that for the price of 1302,24 it expects 13022400.
 * Currently supports: [BTC, ETH].
 */
contract CurrencyValueStore {

    address private owner;

    /**
    * @dev We will use blockNumber to force one transaction per block. It's considered illegal state
    * because that way we can't follow through correctly with price updates and what is going to be the latest one.
    */
    uint256 private blockNumber;

    // Currently supported currencies.
    enum Currency {
        BTC, ETH
    }

    // Used for 2% calculation.
    uint40 private threshold = 2;

    // Number of decimal places that are supported.
    uint8 constant public supportedDecimalPlaces = 4;

    // Only allowing unsigned int 40 because unlikely that the prices overreaches that number. MAX_VALUE = 1,099,511,627,775
    // Current sanity check for price is at 500.000 (5000000000 - because of 10^4)
    mapping (Currency=>uint40) currencyPrices;

    event PriceUpdated(Currency currencyUpdated, uint40 price, uint256 timestamp);

    modifier isInDifferentBlock() {
        require(blockNumber < block.number, "Illegal state, transactions must be in different blocks");
        _;
    }

    modifier isAboveThreshold(Currency currency, uint40 newPrice) {
        uint40 currentPrice = currencyPrices[currency];
        uint40 desiredMinimumThreshold = (currentPrice * threshold) / 100;

        require(getPositiveDifference(currentPrice, newPrice) >= desiredMinimumThreshold, "Insufficient price difference. Expecting a minimum of 2%.");
        _;
    }

    // This is a sanity check of a price, prices probably won't go above 500.000 in the next N amount of years.
    modifier isUnrealisticHighPrice(uint40 newPrice) {
        require(newPrice <= uint40(5000000000), "Unable to set higher price than 500.000");
        _;
    }

    // We do it manually because it would be more expensive to first convert to int to only check absolute value.
    function getPositiveDifference(uint40 first, uint40 second) private pure returns (uint40) {
        if (first >= second) {
            return first - second;
        } else {
            return second - first;
        }
    }

    /**
     * @dev Set contract deployer as owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Updates the price of the currency, always expects a zero or positive value. In addition it must be a minimum of 2% difference than the last value.
     * Please provide values in a form of <currency> * 10^4 to support decimal values. Example for the price of 1302.24, 13022400 is expected.
     * @param currency - Currency price to update, supported: [0, 1]
     * @param newPrice - the value of the new price.
     */
    function set(Currency currency, uint40 newPrice) public isInDifferentBlock() isAboveThreshold(currency, newPrice) isUnrealisticHighPrice(newPrice) {
        blockNumber = block.number;
        currencyPrices[currency] = newPrice;
        emit PriceUpdated(currency, newPrice, block.timestamp);
    }

    /**
     * @dev Returns price of the currency. If not updated, default values are 0. Can always expect a positive or zero value. Emits event upon update.
     * @param currency - Currency price to fetch, supported: [0, 1]
     * @return price of currency.
     */
    function getPriceByCurrency(Currency currency) public view returns (uint40) {
        return currencyPrices[currency];
    }

    /**
     * @dev Returns the owner address values;
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

}