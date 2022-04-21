// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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
pragma solidity ^0.8.4;

interface IOracle {

    /* ---------- Views ---------- */
    function token() external view returns (address);
    function getPrice() external view returns (uint256);
    function updatable() external view returns (bool);

    /* ---------- Functions ---------- */
    function update() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol';
import "../interface/IOracle.sol";

contract OracleLink is IOracle {
    
    AggregatorV2V3Interface internal priceFeed;
    address public override token;
    
    constructor(address _token, address _priceFeed) {
        token = _token;
        priceFeed = AggregatorV2V3Interface(_priceFeed);
    }

    /* ---------- Views ---------- */
    function getPrice() external view override returns (uint256){
        (,int256 quotePrice,,,) = priceFeed.latestRoundData();
        return uint256(quotePrice) * 1e6 / 10 ** priceFeed.decimals();
    }

    function updatable() external override pure returns (bool){
        return false;
    }

    /* ---------- Functions ---------- */
    function update() external override {}
}