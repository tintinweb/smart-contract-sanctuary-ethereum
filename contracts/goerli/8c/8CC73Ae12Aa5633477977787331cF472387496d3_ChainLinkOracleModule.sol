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

/**
 @title IWagerOracleModule
 @author Henry Wrightman

 @notice interface for wager's oracle module (e.g ChainLinkOracleModule)
 */

interface IWagerOracleModule {
    // -- methods --
    function getResult(Wager memory wager) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../oracles/IWagerOracleModule.sol";

/**
 @title IWagerModule
 @author Henry Wrightman

 @notice Interface for wagers
 */

interface IWagerModule {
    // -- methods --
    function settle(
        Wager memory wager
    ) external returns (Wager memory, address);
}

// -- structs --
struct Wager {
    bytes parties; // party data; |partyOne|partyTwo|
    bytes partyOneWagerData; // wager data for wager module to discern; e.g |wagerStart|wagerValue|
    bytes partyTwoWagerData;
    bytes equityData; // wager equity data; |WagerType|ercContractAddr(s)|amount(s)|tokenId(s)|
    bytes blockData; // blocktime data; |created|expiration|enterLimit|
    bytes result; // wager outcome
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracleModule oracleModule; // oracle module semantics
    address oracleSource; // oracle source
    bytes supplementalOracleData; // supplemental wager oracle data
}

// -- wager type
enum WagerType {
    oneSided,
    twoSided
}

// -- wager states
enum WagerState {
    active,
    created,
    completed,
    voided
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

contract ChainLinkOracleModule is IWagerOracleModule {
    /// @notice getResult
    /// @dev result is always bytes & up to wager module / inheritor to decode desired field(s)
    /// @param wager wager who needs to be settled & its result acquired
    /// @return bytes oracle result to be decoded
    function getResult(
        Wager memory wager
    ) external view override returns (bytes memory) {
        AggregatorV3Interface feed = AggregatorV3Interface(wager.oracleSource);

        (, int256 answer, , , ) = feed.latestRoundData();

        return toBytes(uint256(answer));
    }

    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
}