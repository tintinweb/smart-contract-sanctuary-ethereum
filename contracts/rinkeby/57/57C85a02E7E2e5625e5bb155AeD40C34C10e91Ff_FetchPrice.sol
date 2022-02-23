/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File contracts/FetchPrice.sol

pragma solidity ^0.8.4;

contract FetchPrice {
    // token address => chainlink aggregator v3 interface
    mapping(address => AggregatorV3Interface) priceOracles;

    /**
     *@dev Returns the latest price
     *@param _token token address
     *@param _chainlink chainlink price feed address
     */
    // 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D
    // usdt usd price
    constructor(address _token, address _chainlink) {
        _setTokenPriceOracle(_token, _chainlink);
    }

    /**
     *@dev Returns the latest price
     *@param _token token address
     *@param _chainlink chainlink price feed address
     */
    function setTokenPriceOracle(address _token, address _chainlink) external {
        _setTokenPriceOracle(_token, _chainlink);
    }

    /**
     *@dev Returns the latest price
     *@param _token token address
     */
    function getLatestPrice(address _token) public view returns (int256) {
        AggregatorV3Interface priceFeed = priceOracles[_token];
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *@dev Returns the latest price
     *@param _token token address
     *@param _chainlink chainlink price feed address
     */
    function _setTokenPriceOracle(address _token, address _chainlink) internal {
        require(_token != address(0), "Token Address is missing");
        require(_chainlink != address(0), "Oracle Address is missing");

        priceOracles[_token] = AggregatorV3Interface(_chainlink);
    }
}