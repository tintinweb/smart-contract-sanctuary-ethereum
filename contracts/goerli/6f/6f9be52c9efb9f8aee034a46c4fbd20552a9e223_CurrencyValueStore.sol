/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CurrencyValueStore
 * @author Pavle Prica (https://github.com/pavleprica)
 * @dev set the current currency price
 * Used for storing current price of a currency, with a condition that it differs at least by 2%.
 * Currently supports: [BTC, ETH].
 */
contract CurrencyValueStore {

    address private owner;

    // Currently supported currencies.
    enum Currency {
        BTC, ETH
    }

    // Used for 2% calculation. Using higher values for precaution of decimals.
    uint32 private threshold = 200;

    // Only allowing unsigned int 32 because unlikely that the prices overreaches that number. MAX_VALUE = 4,294,967,295
    mapping (Currency=>uint32) currencyPrices;

    event PriceUpdated(Currency currencyUpdated, uint32 price);

    modifier isAboveThreshold(Currency currency, uint32 newPrice) {
        uint32 currentPrice = currencyPrices[currency];
        uint32 desiredMinimumThreshold = (currentPrice * threshold) / 10000;

        require(getPositiveDifference(currentPrice, newPrice) >= desiredMinimumThreshold, "Insufficient price difference. Expecting a minimum of 2%.");
        _;
    }

    // This is a sanity check of a price, prices probably won't go above 500.000 EUR in the next N amount of years.
    modifier isUnrealisticHighPrice(uint32 newPrice) {
        require(newPrice <= uint32(500000), "Unable to set higher price than 500.000");
        _;
    }

    // We do it manually because it would be more expensive to first convert to int to only check absolute value.
    function getPositiveDifference(uint32 first, uint32 second) private pure returns (uint32) {
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
     * 
     */
    function set(Currency currency, uint32 newPrice) public isAboveThreshold(currency, newPrice) isUnrealisticHighPrice(newPrice) {
        currencyPrices[currency] = newPrice;
        emit PriceUpdated(currency, newPrice);
    }

    /**
     * @dev Returns price of the currency. If not updated, default values are 0. Can always expect a positive or zero value. Emits event upon update.
     * @return price of currency.
     */
    function getPriceByCurrency(Currency currency) public view returns (uint32) {
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