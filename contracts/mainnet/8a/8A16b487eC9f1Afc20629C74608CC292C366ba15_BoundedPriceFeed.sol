// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { AggregatorV2V3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import { PERCENTAGE_FACTOR } from "../libraries/PercentageMath.sol";
import { PriceFeedType, IPriceFeedType } from "../interfaces/IPriceFeedType.sol";

// EXCEPTIONS
import { NotImplementedException } from "../interfaces/IErrors.sol";

interface ChainlinkReadableAggregator {
    function aggregator() external view returns (address);

    function phaseAggregators(uint16 idx)
        external
        view
        returns (AggregatorV2V3Interface);

    function phaseId() external view returns (uint16);
}

/// @title Price feed with an upper bound on price
/// @notice Used to limit prices on assets that should not rise above
///         a certain level, such as stablecoins and other pegged assets
contract BoundedPriceFeed is
    ChainlinkReadableAggregator,
    AggregatorV3Interface,
    IPriceFeedType
{
    /// @dev Chainlink price feed for the Vault's underlying
    AggregatorV3Interface public immutable priceFeed;

    /// @dev The upper bound on Chainlink price for the asset
    int256 public immutable upperBound;

    /// @dev Decimals of the returned result.
    uint8 public immutable override decimals;

    /// @dev Price feed description
    string public override description;

    uint256 public constant override version = 1;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.BOUNDED_ORACLE;

    bool public constant override skipPriceCheck = false;

    /// @dev Constructor
    /// @param _priceFeed Chainlink price feed to receive results from
    /// @param _upperBound Initial upper bound for the Chainlink price
    constructor(address _priceFeed, int256 _upperBound) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        description = string(
            abi.encodePacked(priceFeed.description(), " Bounded")
        );
        decimals = priceFeed.decimals();
        upperBound = _upperBound;
    }

    /// @dev Implemented for compatibility, but reverts since Gearbox's price feeds
    ///      do not store historical data.
    function getRoundData(uint80)
        external
        pure
        virtual
        override
        returns (
            uint80, // roundId,
            int256, // answer,
            uint256, // startedAt,
            uint256, // updatedAt,
            uint80 // answeredInRound
        )
    {
        revert NotImplementedException(); // F:[LPF-2]
    }

    /// @dev Returns the value if it is below the upper bound, otherwise returns the upper bound
    /// @param value Value to be checked and bounded
    function _upperBoundValue(int256 value) internal view returns (int256) {
        return (value > upperBound) ? upperBound : value;
    }

    /// @dev Returns the upper-bounded USD price of the token
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
        (roundId, answer, startedAt, updatedAt, answeredInRound) = priceFeed
            .latestRoundData(); // F:[OYPF-4]

        answer = _upperBoundValue(answer);
    }

    /// @dev Returns the current phase's aggregator address
    function aggregator() external view returns (address) {
        return ChainlinkReadableAggregator(address(priceFeed)).aggregator();
    }

    /// @dev Returns a phase aggregator by index
    function phaseAggregators(uint16 idx)
        external
        view
        returns (AggregatorV2V3Interface)
    {
        return
            ChainlinkReadableAggregator(address(priceFeed)).phaseAggregators(
                idx
            );
    }

    function phaseId() external view returns (uint16) {
        return ChainlinkReadableAggregator(address(priceFeed)).phaseId();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE,
    WSTETH_ORACLE,
    BOUNDED_ORACLE,
    COMPOSITE_ORACLE
}

interface IPriceFeedType {
    /// @dev Returns the price feed type
    function priceFeedType() external view returns (PriceFeedType);

    /// @dev Returns whether sanity checks on price feed result should be skipped
    function skipPriceCheck() external view returns (bool);
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

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import { Errors } from "./Errors.sol";

uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0; // T:[PM-1]
        }

        //        require(
        //            value <= (type(uint256).max - HALF_PERCENT) / percentage,
        //            Errors.MATH_MULTIPLICATION_OVERFLOW
        //        ); // T:[PM-1]

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR; // T:[PM-1]
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[PM-2]
        uint256 halfPercentage = percentage / 2; // T:[PM-2]

        //        require(
        //            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
        //            Errors.MATH_MULTIPLICATION_OVERFLOW
        //        ); // T:[PM-2]

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
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

error TokenIsNotAddedToCreditManagerException(address token);

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
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Errors library
library Errors {
    //
    // COMMON
    //
    string public constant ZERO_ADDRESS_IS_NOT_ALLOWED = "Z0";
    string public constant NOT_IMPLEMENTED = "NI";
    string public constant INCORRECT_PATH_LENGTH = "PL";
    string public constant INCORRECT_ARRAY_LENGTH = "CR";
    string public constant REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY = "CP";
    string public constant REGISTERED_POOLS_ONLY = "RP";
    string public constant INCORRECT_PARAMETER = "IP";

    //
    // MATH
    //
    string public constant MATH_MULTIPLICATION_OVERFLOW = "M1";
    string public constant MATH_ADDITION_OVERFLOW = "M2";
    string public constant MATH_DIVISION_BY_ZERO = "M3";

    //
    // POOL
    //
    string public constant POOL_CONNECTED_CREDIT_MANAGERS_ONLY = "PS0";
    string public constant POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER = "PS1";
    string public constant POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT = "PS2";
    string public constant POOL_INCORRECT_WITHDRAW_FEE = "PS3";
    string public constant POOL_CANT_ADD_CREDIT_MANAGER_TWICE = "PS4";

    //
    // ACCOUNT FACTORY
    //
    string public constant AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK =
        "AF1";
    string public constant AF_MINING_IS_FINISHED = "AF2";
    string public constant AF_CREDIT_ACCOUNT_NOT_IN_STOCK = "AF3";
    string public constant AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN = "AF4";

    //
    // ADDRESS PROVIDER
    //
    string public constant AS_ADDRESS_NOT_FOUND = "AP1";

    //
    // CONTRACTS REGISTER
    //
    string public constant CR_POOL_ALREADY_ADDED = "CR1";
    string public constant CR_CREDIT_MANAGER_ALREADY_ADDED = "CR2";

    //
    // CREDIT ACCOUNT
    //
    string public constant CA_CONNECTED_CREDIT_MANAGER_ONLY = "CA1";
    string public constant CA_FACTORY_ONLY = "CA2";

    //
    // ACL
    //
    string public constant ACL_CALLER_NOT_PAUSABLE_ADMIN = "ACL1";
    string public constant ACL_CALLER_NOT_CONFIGURATOR = "ACL2";

    //
    // WETH GATEWAY
    //
    string public constant WG_DESTINATION_IS_NOT_WETH_COMPATIBLE = "WG1";
    string public constant WG_RECEIVE_IS_NOT_ALLOWED = "WG2";
    string public constant WG_NOT_ENOUGH_FUNDS = "WG3";

    //
    // TOKEN DISTRIBUTOR
    //
    string public constant TD_WALLET_IS_ALREADY_CONNECTED_TO_VC = "TD1";
    string public constant TD_INCORRECT_WEIGHTS = "TD2";
    string public constant TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION = "TD3";
    string public constant TD_CONTRIBUTOR_IS_NOT_REGISTERED = "TD4";
}