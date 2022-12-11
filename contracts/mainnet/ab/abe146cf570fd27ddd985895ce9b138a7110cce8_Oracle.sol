/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

/**
@title Oracle
@notice Oracle used by markets. Uses Chainlink-style feeds for prices.
The Pessimistic Oracle introduces collateral factor into the pricing formula. It ensures that any given oracle price is dampened to prevent borrowers from borrowing more than the lowest recorded value of their collateral over the past 2 days.
This has the advantage of making price manipulation attacks more difficult, as an attacker needs to log artificially high lows.
It has the disadvantage of reducing borrow power of borrowers to a 2-day minimum value of their collateral, where the value must have been seen by the oracle.
*/
contract Oracle {

    struct FeedData {
        IChainlinkFeed feed;
        uint8 tokenDecimals;
    }

    address public operator;
    address public pendingOperator;
    mapping (address => FeedData) public feeds;
    mapping (address => mapping(uint => uint)) public dailyLows; // token => day => price

    constructor(
        address _operator
    ) {
        operator = _operator;
    }

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR");
        _;
    }
    
    /**
    @notice Sets the pending operator of the oracle. Only callable by operator.
    @param newOperator_ The address of the pending operator.
    */
    function setPendingOperator(address newOperator_) public onlyOperator { pendingOperator = newOperator_; }

    /**
    @notice Sets the price feed of a specific token address.
    @dev Even though the price feeds implement the chainlink interface, it's possible to use other price oracle.
    @param token Address of the ERC20 token to set a feed for
    @param feed The chainlink feed of the ERC20 token.
    @param tokenDecimals uint8 representing the decimal precision of the token
    */
    function setFeed(address token, IChainlinkFeed feed, uint8 tokenDecimals) public onlyOperator { feeds[token] = FeedData(feed, tokenDecimals); }

    /**
    @notice Claims the operator role. Only successfully callable by the pending operator.
    */
    function claimOperator() public {
        require(msg.sender == pendingOperator, "ONLY PENDING OPERATOR");
        operator = pendingOperator;
        pendingOperator = address(0);
        emit ChangeOperator(operator);
    }

    /**
    @notice Gets the price of a specific token in DOLA
    @param token The address of the token to get price of
    @return The price of the token in DOLA, adjusted for token and feed decimals
    */
    function viewPrice(address token, uint collateralFactorBps) external view returns (uint) {
        if(feeds[token].feed != IChainlinkFeed(address(0))) {

            //get normalized price
            uint normalizedPrice = getNormalizedPrice(token);
            uint day = block.timestamp / 1 days;
            // get today's low
            uint todaysLow = dailyLows[token][day];
            if(todaysLow == 0 || normalizedPrice < todaysLow) {
                todaysLow = normalizedPrice;
            }
            // if collateralFactorBps is 0, return normalizedPrice;
            if(collateralFactorBps == 0) return normalizedPrice;
            // get yesterday's low
            uint yesterdaysLow = dailyLows[token][day - 1];
            // calculate new borrowing power based on collateral factor
            uint newBorrowingPower = normalizedPrice * collateralFactorBps / 10000;
            uint twoDayLow = todaysLow > yesterdaysLow && yesterdaysLow > 0 ? yesterdaysLow : todaysLow;
            if(twoDayLow > 0 && newBorrowingPower > twoDayLow) {
                uint dampenedPrice = twoDayLow * 10000 / collateralFactorBps;
                return dampenedPrice < normalizedPrice ? dampenedPrice: normalizedPrice;
            }
            return normalizedPrice;

        }
        revert("Price not found");
    }

    /**
    @notice Gets the price of a specific token in DOLA while also saving the price if it is the day's lowest.
    @param token The address of the token to get price of
    @return The price of the token in DOLA, adjusted for token and feed decimals
    */
    function getPrice(address token, uint collateralFactorBps) external returns (uint) {
        if(feeds[token].feed != IChainlinkFeed(address(0))) {
            // get normalized price
            uint normalizedPrice = getNormalizedPrice(token);
            // potentially store price as today's low
            uint day = block.timestamp / 1 days;
            uint todaysLow = dailyLows[token][day];
            if(todaysLow == 0 || normalizedPrice < todaysLow) {
                dailyLows[token][day] = normalizedPrice;
                todaysLow = normalizedPrice;
                emit RecordDailyLow(token, normalizedPrice);
            }
            // if collateralFactorBps is 0, return normalizedPrice;
            if(collateralFactorBps == 0) return normalizedPrice;
            // get yesterday's low
            uint yesterdaysLow = dailyLows[token][day - 1];
            // calculate new borrowing power based on collateral factor
            uint newBorrowingPower = normalizedPrice * collateralFactorBps / 10000;
            uint twoDayLow = todaysLow > yesterdaysLow && yesterdaysLow > 0 ? yesterdaysLow : todaysLow;
            if(twoDayLow > 0 && newBorrowingPower > twoDayLow) {
                uint dampenedPrice = twoDayLow * 10000 / collateralFactorBps;
                return dampenedPrice < normalizedPrice ? dampenedPrice: normalizedPrice;
            }
            return normalizedPrice;

        }
        revert("Price not found");
    }
    
    /**
    @notice Gets the price from the price feed and normalizes it.
    @param token The token to get the normalized price for.
    @return normalizedPrice Returns the normalized price.
    */
    function getNormalizedPrice(address token) internal view returns (uint normalizedPrice) {
        //get price from feed
        uint price = getFeedPrice(token);
        // normalize price
        uint8 feedDecimals = feeds[token].feed.decimals();
        uint8 tokenDecimals = feeds[token].tokenDecimals;
        if(feedDecimals + tokenDecimals <= 36) {
            uint8 decimals = 36 - feedDecimals - tokenDecimals;
            normalizedPrice = price * (10 ** decimals);
        } else {
            uint8 decimals = feedDecimals + tokenDecimals - 36;
            normalizedPrice = price / 10 ** decimals;
        }

    }

    /**
    @notice returns the underlying feed price of the given token address
    @dev Will revert if price is negative or token is not in the oracle
    @param token The address of the token to get the price of
    @return Return the unaltered price of the underlying token
    */
    function getFeedPrice(address token) public view returns(uint) {
        (,int256 price,,,) = feeds[token].feed.latestRoundData();
        require(price > 0, "Invalid feed price");
        return uint(price);
    }

    event ChangeOperator(address indexed newOperator);
    event RecordDailyLow(address indexed token, uint price);

}