// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IPriceFeedType, PriceFeedType } from "../interfaces/IPriceFeedType.sol";

// EXCEPTIONS
import { NotImplementedException } from "../interfaces/IErrors.sol";

/// @title Pricefeed which always returns 0
/// @notice Used for collateral tokens that do not have a valid USD price feed
contract ZeroPriceFeed is AggregatorV3Interface, IPriceFeedType {
    string public constant override description = "Zero pricefeed"; // F:[ZPF-1]

    uint8 public constant override decimals = 8; // F:[ZPF-1]

    uint256 public constant override version = 1;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.ZERO_ORACLE;

    bool public constant override skipPriceCheck = true; // F:[ZPF-1]

    /// @dev Not implemented, since Gearbox does not use historical data
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

    /// @dev Returns the latest result according to Chainlink spec
    /// @notice 'answer' is always 0
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
    /// @dev Returns the price feed type
    function priceFeedType() external view returns (PriceFeedType);

    /// @dev Returns whether sanity checks on price feed result should be skipped
    function skipPriceCheck() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @dev Thrown on attempting to call a non-implemented function
error NotImplementedException();

/// @dev Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @dev Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @dev Thrown on attempting to set a token price feed to an address that is not a
///      correct price feed
error IncorrectPriceFeedException();

/// @dev Thrown on attempting to call an access restricted function as a non-Configurator
error CallerNotConfiguratorException();

/// @dev Thrown on attempting to pause a contract as a non-Pausable admin
error CallerNotPausableAdminException();

/// @dev Thrown on attempting to pause a contract as a non-Unpausable admin
error CallerNotUnPausableAdminException();