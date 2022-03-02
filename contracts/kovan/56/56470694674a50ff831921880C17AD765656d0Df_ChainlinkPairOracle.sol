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

pragma solidity 0.8.4;

interface IPairOracle {
    function twap(address token, uint256 pricePrecision) external view returns (uint256 amountOut);

    function spot(address token, uint256 pricePrecision) external view returns (uint256 amountOut);

    function update() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ChainlinkOracle {
    function getPriceToUsd(address oracleAddress, uint256 pricePrecition) internal view returns (uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(oracleAddress);
        (, int256 price, , , ) = oracle.latestRoundData();
        uint8 _decimals = oracle.decimals();
        return (uint256(price) * pricePrecition) / _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IPairOracle.sol";
import "../libs/ChainlinkOracle.sol";

contract ChainlinkPairOracle {
    IPairOracle public pairOracle;
    address public token;
    address public oracleAddress;

    constructor(
        address _token,
        address _pairAddress,
        address _oracleAddress
    ) {
        require(_token != address(0), "Token invalid address");
        require(_pairAddress != address(0), "Pair address invalid address");
        require(_oracleAddress != address(0), "Oracle invalid address");
        token = _token;
        pairOracle = IPairOracle(_pairAddress);
        oracleAddress = _oracleAddress;
    }

    function getPriceSpot(uint256 _pricePrecision) public view returns (uint256) {
        return (pairOracle.spot(token, _pricePrecision) * ChainlinkOracle.getPriceToUsd(oracleAddress, _pricePrecision)) / _pricePrecision;
    }

    function getPriceTWAP(uint256 _pricePrecision) public view returns (uint256) {
        return (pairOracle.twap(token, _pricePrecision) * ChainlinkOracle.getPriceToUsd(oracleAddress, _pricePrecision)) / _pricePrecision;
    }
}