// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IPriceFeedType, PriceFeedType} from "../interfaces/IPriceFeedType.sol";

// EXCEPTIONS
import {NotImplementedException} from "../interfaces/IErrors.sol";

/// @title Pricefeed which returns 0 always
contract ZeroPriceFeed is AggregatorV3Interface, IPriceFeedType {
    string public constant override description = "Zero pricefeed"; // F:[ZPF-1]
    uint8 public constant override decimals = 8; // F:[ZPF-1]

    uint256 public constant override version = 1;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.ZERO_ORACLE;
    bool public constant override dependsOnAddress = false; // F:[ZPF-1]
    bool public constant override skipPriceCheck = true; // F:[ZPF-1]

    function getRoundData(
        uint80 //_roundId)
    )
        external
        pure
        override
        returns (
            uint80, // roundId,
            int256, //answer,
            uint256, // startedAt,
            uint256, // updatedAt,
            uint80 // answeredInRound
        )
    {
        revert NotImplementedException(); // F:[ZPF-2]
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1; // F:[ZPF-3]
        answer = 0; // F:[ZPF-3]
        startedAt = block.timestamp; // F:[ZPF-3]
        updatedAt = block.timestamp; // F:[ZPF-3]
        answeredInRound = 1; // F:[ZPF-3]
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
pragma solidity ^0.8.0;

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE
}

interface IPriceFeedType {
    function priceFeedType() external view returns (PriceFeedType);

    function dependsOnAddress() external view returns (bool);

    function skipPriceCheck() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev throws if zero address is provided
error ZeroAddressException();

/// @dev throws if non implemented method was called
error NotImplementedException();

/// @dev throws if expected contract but provided non-contract address
error AddressIsNotContractException(address);

/// @dev throws if token has no balanceOf(address) method, or this method reverts
error IncorrectTokenContractException();

/// @dev throws if token has no priceFeed in PriceOracle
error IncorrectPriceFeedException();

/// @dev throw if caller is not CONFIGURATOR
error CallerNotConfiguratorException();

/// @dev throw if caller is not PAUSABLE ADMIN
error CallerNotPausableAdminException();

/// @dev throw if caller is not UNPAUSABLE ADMIN
error CallerNotUnPausableAdminException();