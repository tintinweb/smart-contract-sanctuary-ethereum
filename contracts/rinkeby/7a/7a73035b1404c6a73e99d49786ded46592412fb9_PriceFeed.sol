// SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

import "./Ownable.sol";

import "./IPriceFeed.sol";
import "./AggregatorV3Interface.sol";

/*
* PriceFeed for mainnet deployment, to be connected to Chainlink's live ETH:USD aggregator reference 
* contract, and a wrapper contract TellorCaller, which connects to TellorMaster contract.
*
* The PriceFeed uses Chainlink as primary oracle, and Tellor as fallback. It contains logic for
* switching oracles based on oracle failures, timeouts, and conditions for returning to the primary
* Chainlink oracle.
*/
contract PriceFeed is Ownable, IPriceFeed {

    string constant public NAME = "PriceFeed";

    AggregatorV3Interface public priceAggregator;  // Mainnet Chainlink aggregator

    uint constant public DECIMAL_PRECISION = 1e18;

    // Use to convert a price answer to an 18-digit precision uint
    uint constant public TARGET_DIGITS = 18;  

    // Maximum time period allowed since Chainlink's latest round data timestamp, beyond which Chainlink is considered frozen.
    uint constant public TIMEOUT = 14400;  // 4 hours: 60 * 60 * 4
    
    // Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    uint constant public MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND =  5e17; // 50%

    /* 
    * The maximum relative price difference between two oracle responses allowed in order for the PriceFeed
    * to return to using the Chainlink oracle. 18-digit precision.
    */
    uint constant public MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%

    // The last good price seen from an oracle by ourProject
    uint public lastGoodPrice;

    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    enum Status {
        chainlinkWorking, 
        usingTellorChainlinkUntrusted, 
        bothOraclesUntrusted,
        usingTellorChainlinkFrozen, 
        usingChainlinkTellorUntrusted
    }

    // The current status of the PricFeed, which determines the conditions for the next price fetch attempt
    Status public status;

    // --- Dependency setters ---
    
    function setAddress(
        address _priceAggregatorAddress
    )
        external
        onlyOwner
    {
       
        priceAggregator = AggregatorV3Interface(_priceAggregatorAddress);

        emit PriceAggregatorAddressChanged(_priceAggregatorAddress);

        // Explicitly set initial system status
        status = Status.chainlinkWorking;

        // Get an initial price from Chainlink to serve as first reference for lastGoodPrice
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();

        _storeChainlinkPrice(chainlinkResponse);
    }

    // --- Functions ---

    /*
    * fetchPrice():
    * Returns the latest price obtained from the Oracle. Called by ourProject functions that require a current price.
    *
    * Also callable by anyone externally.
    *
    * Non-view function - it stores the last good price seen by ourProject.
    *
    * Uses a main oracle (Chainlink) and a fallback oracle (Tellor) in case Chainlink fails. If both fail, 
    * it uses the last good price seen by ourProject.
    *
    */
    function fetchPrice() external view override returns (uint) {
        // Get current and previous price data from Chainlink, and current price data from Tellor
        ChainlinkResponse memory _chainlinkResponse = _getCurrentChainlinkResponse();
        uint scaledChainlinkPrice = _scaleChainlinkPriceByDigits(uint256(_chainlinkResponse.answer), _chainlinkResponse.decimals);
        return scaledChainlinkPrice;
    }

    function _storePrice(uint _currentPrice) internal {
        lastGoodPrice = _currentPrice;
        emit LastGoodPriceUpdated(_currentPrice);
    }

    function _scaleChainlinkPriceByDigits(uint _price, uint _answerDigits) internal pure returns (uint) {
        /*
        * Convert the price returned by the Chainlink oracle to an 18-digit decimal for use by ourProject.
        * At date of ourProject launch, Chainlink uses an 8-digit price, but we also handle the possibility of
        * future changes.
        *
        */
        uint price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to ourProject's target precision
            price = _price / (10 ** (_answerDigits - TARGET_DIGITS));
        }
        else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to ourProject's target precision
            price = _price * (10 ** (TARGET_DIGITS - _answerDigits));
        }
        return price;
    }
    
    function _storeChainlinkPrice(ChainlinkResponse memory _chainlinkResponse) internal returns (uint) {
        uint scaledChainlinkPrice = _scaleChainlinkPriceByDigits(uint256(_chainlinkResponse.answer), _chainlinkResponse.decimals);
        _storePrice(scaledChainlinkPrice);

        return scaledChainlinkPrice;
    }

    function _getCurrentChainlinkResponse() internal view returns (ChainlinkResponse memory chainlinkResponse) {
        // First, try to get current decimal precision:
        try priceAggregator.decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponse.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // Secondly, try to get latest price data:
        try priceAggregator.latestRoundData() returns
        (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = answer;
            chainlinkResponse.timestamp = timestamp;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }
    }

}