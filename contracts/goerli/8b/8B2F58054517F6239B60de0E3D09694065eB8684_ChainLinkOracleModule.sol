// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

import "../wagers/IWagerModule.sol";

interface IWagerOracle {
    // -- methods --
    function getResult(Wager memory wager) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../oracles/IWagerOracle.sol";

// -- structs --
struct Wager {
    address partyOne;
    bytes partyOneWagerData;
    address partyTwo;
    bytes partyTwoWagerData;
    uint256 wagerAmount;
    uint80 expirationBlock;
    
    bytes wagerOracleData; // ancillary wager data
    bytes supplumentalWagerOracleData;
    bytes result; // wager outcome
    
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracle oracleImpl; // oracle impl
}

// -- wager states
enum WagerState {
    active,
    created,
    completed,
    voided
}

interface IWagerModule {
    // -- methods --
    function settle(Wager memory wager) external returns (Wager memory, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../interfaces/wagers/IWagerModule.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 @title ChainLinkOracleModule
 @author Henry Wrightman

 @notice ChainLink oracle module for wager price-related data resolution
 */

contract ChainLinkOracleModule is IWagerOracle {
    /// @notice getResult
    /// @dev result is always bytes & up to wager module / inheritor to decode desired field(s)
    /// @param wager wager who needs to be settled & its result acquired
    /// @return bytes oracle result to be decoded
    function getResult(
        Wager memory wager
    ) external view override returns (bytes memory) {
        AggregatorV3Interface feed = AggregatorV3Interface(
            address(wager.oracleImpl)
        );

        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = feed.getRoundData(wager.expirationBlock);

        return toBytes(uint256(price));
    }

    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
}