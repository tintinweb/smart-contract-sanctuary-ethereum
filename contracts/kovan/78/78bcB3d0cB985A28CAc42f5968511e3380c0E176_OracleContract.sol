// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IOracle.sol";

contract OracleContract is IOracle {
    /**
     * @dev The SXT chainlink price data feed contract
     *      Kovan (DAI/USD): 	0x777A68032a88E5A84678A77Af2CD65A7b3c0775a
     */
    AggregatorV3Interface public immutable SXT_ORACLE;

    /**
     * @dev The ETH chainlink price data feed contract
     *      Mainnet (LINK/ETH):     0xDC530D9457755926550b59e8ECcdaE7624181557
     *      Kovan (LINK/ETH):       0x3Af8C569ab77af5230596Acf0E8c2F9351d24C38
     */
    AggregatorV3Interface public immutable ETH_ORACLE;

    /**
     * @dev The LINK chainlink price data feed contract
     *      Mainnet (LINK/USD):     0xDC530D9457755926550b59e8ECcdaE7624181557
     *      Kovan (LINK/USD):       0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0
     */
    AggregatorV3Interface public immutable LINK_ORACLE;

    constructor(
        AggregatorV3Interface _sxtOracle,
        AggregatorV3Interface _ethOracle,
        AggregatorV3Interface _linkOracle
    ) {
        SXT_ORACLE = _sxtOracle;
        ETH_ORACLE = _ethOracle;
        LINK_ORACLE = _linkOracle;
    }

    /**
     * Returns the SXT latest price
     */
    function getSXTLatestPrice() public view override returns (uint80, int256) {
        (uint80 roundID, int256 price, , , ) = SXT_ORACLE.latestRoundData();
        return (roundID, price);
    }

    /**
     * Returns the ETH latest price
     */
    function getETHLatestPrice() public view override returns (uint80, int256) {
        (uint80 roundID, int256 price, , , ) = ETH_ORACLE.latestRoundData();
        return (roundID, price);
    }

    /**
     * Returns the LINK latest price
     */
    function getLINKLatestPrice()
        public
        view
        override
        returns (uint80, int256)
    {
        (uint80 roundID, int256 price, , , ) = LINK_ORACLE.latestRoundData();
        return (roundID, price);
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOracle {
    function getSXTLatestPrice() external view returns (uint80, int256);

    function getETHLatestPrice() external view returns (uint80, int256);

    function getLINKLatestPrice() external view returns (uint80, int256);
}