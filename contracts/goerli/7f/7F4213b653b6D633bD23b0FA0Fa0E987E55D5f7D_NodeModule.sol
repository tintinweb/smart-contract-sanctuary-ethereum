//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    // solhint-disable numcast/safe-cast

    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // solhint-enable numcast/safe-cast

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint x, uint factor) internal pure returns (uint) {
        return x * 10 ** factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint x, uint factor) internal pure returns (uint) {
        return x / 10 ** factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x * (10 ** factor).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x / (10 ** factor).to128();
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int x, uint factor) internal pure returns (int) {
        return x * (10 ** factor).toInt();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int x, uint factor) internal pure returns (int) {
        return x / (10 ** factor).toInt();
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x * ((10 ** factor).toInt()).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x / ((10 ** factor).toInt().to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC165.sol";

library ERC165Helper {
    function safeSupportsInterface(
        address candidate,
        bytes4 interfaceID
    ) internal returns (bool supportsInterface) {
        (bool success, bytes memory response) = candidate.call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceID)
        );

        if (!success) {
            return false;
        }

        if (response.length == 0) {
            return false;
        }

        assembly {
            supportsInterface := mload(add(response, 32))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int(type(int32).min) || x > int(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int(type(int24).min) || x > int(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/// @title Interface an aggregator needs to adhere.
interface IAggregatorV3Interface {
    /// @notice decimals used by the aggregator
    function decimals() external view returns (uint8);

    /// @notice aggregator's description
    function description() external view returns (string memory);

    /// @notice aggregator's version
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    /// @notice get's round data for requested id
    function getRoundData(
        uint80 id
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

    /// @notice get's latest round data
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

import "../../storage/NodeOutput.sol";
import "../../storage/NodeDefinition.sol";

/// @title Interface for an external node
interface IExternalNode is IERC165 {
    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters
    ) external view returns (NodeOutput.Data memory);

    function validate(NodeDefinition.Data memory nodeDefinition) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.11 <0.9.0;

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @dev Emitted when an update for price feed with `id` is processed successfully.
    /// @param id The Pyth Price Feed ID.
    /// @param fresh True if the price update is more recent and stored.
    /// @param chainId ID of the source chain that the batch price update containing this price.
    /// This value comes from Wormhole, and you can find the corresponding chains at https://docs.wormholenetwork.com/wormhole/contracts.
    /// @param sequenceNumber Sequence number of the batch price update containing this price.
    /// @param lastPublishTime Publish time of the previously stored price.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        bool indexed fresh,
        uint16 chainId,
        uint64 sequenceNumber,
        uint lastPublishTime,
        uint publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    /// @param batchSize Number of prices within the batch price update.
    /// @param freshPricesInBatch Number of prices that were more recent and were stored.
    event BatchPriceFeedUpdate(
        uint16 chainId,
        uint64 sequenceNumber,
        uint batchSize,
        uint freshPricesInBatch
    );

    /// @dev Emitted when a call to `updatePriceFeeds` is processed successfully.
    /// @param sender Sender of the call (`msg.sender`).
    /// @param batchCount Number of batches that this function processed.
    /// @param fee Amount of paid fee for updating the prices.
    event UpdatePriceFeeds(address indexed sender, uint batchCount, uint fee);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateDataSize Number of price updates.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(uint updateDataSize) external view returns (uint feeAmount);
}

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.11 <0.9.0;

interface IUniswapV3Pool {
    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeOutput.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface INodeModule {
    /**
     * @notice Thrown when the specified nodeId has not been registered in the system.
     */
    error NodeNotRegistered(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered without a valid definition.
     */
    error InvalidNodeDefinition(NodeDefinition.Data nodeType);

    /**
     * @notice Thrown when a node cannot be processed
     */
    error UnprocessableNode(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered with an invalid external node
     */
    error IncorrectExternalNodeInterface(address externalNode);

    /**
     * @notice Emitted when `registerNode` is called.
     * @param nodeId The id of the registered node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     */
    event NodeRegistered(
        bytes32 nodeId,
        NodeDefinition.NodeType nodeType,
        bytes parameters,
        bytes32[] parents
    );

    /**
     * @notice Registers a node
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     * @return The id of the registered node.
     */
    function registerNode(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32);

    /**
     * @notice Returns the ID of a node, whether or not it has been registered.
     * @param parents The parents assigned to this node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @return The id of the node.
     */
    function getNodeId(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32);

    /**
     * @notice Returns a node's definition (type, parameters, and parents)
     * @param nodeId The node ID
     * @return The node's definition data
     */
    function getNode(bytes32 nodeId) external view returns (NodeDefinition.Data memory);

    /**
     * @notice Returns a node current output data
     * @param nodeId The node ID
     * @return The node's output data
     */
    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/external/IExternalNode.sol";

contract MockExternalNode is IExternalNode {
    NodeOutput.Data private output;

    constructor(int256 price, uint256 timestamp) {
        output.price = price;
        output.timestamp = timestamp;
    }

    function process(
        NodeOutput.Data[] memory,
        bytes memory
    ) external view override returns (NodeOutput.Data memory) {
        return output;
    }

    function validate(
        NodeDefinition.Data memory nodeDefinition
    ) external pure override returns (bool) {
        return nodeDefinition.nodeType == NodeDefinition.NodeType.EXTERNAL;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IExternalNode).interfaceId ||
            interfaceId == this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

contract MockObservable {
    Observation private observation0;
    Observation private observation1;

    address public immutable token0;
    address public immutable token1;

    struct Observation {
        uint32 secondsAgo;
        int56 tickCumulatives;
        uint160 secondsPerLiquidityCumulativeX128s;
    }

    constructor(
        uint32[] memory secondsAgos,
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulativeX128s,
        address _token0,
        address _token1
    ) {
        require(
            secondsAgos.length == 2 &&
                tickCumulatives.length == 2 &&
                secondsPerLiquidityCumulativeX128s.length == 2,
            "Invalid test case size"
        );

        observation0 = Observation(
            secondsAgos[0],
            tickCumulatives[0],
            secondsPerLiquidityCumulativeX128s[0]
        );
        observation1 = Observation(
            secondsAgos[1],
            tickCumulatives[1],
            secondsPerLiquidityCumulativeX128s[1]
        );

        token0 = _token0;
        token1 = _token1;
    }

    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        )
    {
        require(
            secondsAgos[0] == observation0.secondsAgo && secondsAgos[1] == observation1.secondsAgo,
            "Invalid test case"
        );

        int56[] memory _tickCumulatives = new int56[](2);
        _tickCumulatives[0] = observation0.tickCumulatives;
        _tickCumulatives[1] = observation1.tickCumulatives;

        uint160[] memory _secondsPerLiquidityCumulativeX128s = new uint160[](2);
        _secondsPerLiquidityCumulativeX128s[0] = observation0.secondsPerLiquidityCumulativeX128s;
        _secondsPerLiquidityCumulativeX128s[1] = observation1.secondsPerLiquidityCumulativeX128s;

        return (_tickCumulatives, _secondsPerLiquidityCumulativeX128s);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/INodeModule.sol";
import "../nodes/ReducerNode.sol";
import "../nodes/ExternalNode.sol";
import "../nodes/PythNode.sol";
import "../nodes/ChainlinkNode.sol";
import "../nodes/PriceDeviationCircuitBreakerNode.sol";
import "../nodes/StalenessCircuitBreakerNode.sol";
import "../nodes/UniswapNode.sol";

import "../storage/NodeOutput.sol";
import "../storage/NodeDefinition.sol";

/**
 * @title Module for managing nodes
 * @dev See INodeModule.
 */
contract NodeModule is INodeModule {
    /**
     * @inheritdoc INodeModule
     */
    function registerNode(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32) {
        NodeDefinition.Data memory nodeDefinition = NodeDefinition.Data({
            parents: parents,
            nodeType: nodeType,
            parameters: parameters
        });

        return _registerNode(nodeDefinition);
    }

    /**
     * @inheritdoc INodeModule
     */
    function getNodeId(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external pure returns (bytes32) {
        NodeDefinition.Data memory nodeDefinition = NodeDefinition.Data({
            parents: parents,
            nodeType: nodeType,
            parameters: parameters
        });

        return _getNodeId(nodeDefinition);
    }

    /**
     * @inheritdoc INodeModule
     */
    function getNode(bytes32 nodeId) external pure returns (NodeDefinition.Data memory) {
        return _getNode(nodeId);
    }

    /**
     * @inheritdoc INodeModule
     */
    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory) {
        return _process(nodeId);
    }

    /**
     * @dev Returns node definition data for a given node id.
     */
    function _getNode(bytes32 nodeId) internal pure returns (NodeDefinition.Data storage) {
        return NodeDefinition.load(nodeId);
    }

    /**
     * @dev Returns the ID of a node, whether or not it has been registered.
     */
    function _getNodeId(NodeDefinition.Data memory nodeDefinition) internal pure returns (bytes32) {
        return NodeDefinition.getId(nodeDefinition);
    }

    /**
     * @dev Returns the ID of a node after registering it
     */
    function _registerNode(
        NodeDefinition.Data memory nodeDefinition
    ) internal returns (bytes32 nodeId) {
        // If the node has already been registered with the system, return its ID.
        nodeId = _getNodeId(nodeDefinition);
        if (_isNodeRegistered(nodeId)) {
            return nodeId;
        }

        // Validate that the node definition
        if (!_validateNodeDefinition(nodeDefinition)) {
            revert InvalidNodeDefinition(nodeDefinition);
        }

        // Confirm that all of the parent node IDs have been registered.
        for (uint256 i = 0; i < nodeDefinition.parents.length; i++) {
            if (!_isNodeRegistered(nodeDefinition.parents[i])) {
                revert NodeNotRegistered(nodeDefinition.parents[i]);
            }
        }

        // Register the node
        (, nodeId) = NodeDefinition.create(nodeDefinition);
        emit NodeRegistered(
            nodeId,
            nodeDefinition.nodeType,
            nodeDefinition.parameters,
            nodeDefinition.parents
        );
    }

    /**
     * @dev Returns whether a given node ID has already been registered.
     */
    function _isNodeRegistered(bytes32 nodeId) internal view returns (bool) {
        NodeDefinition.Data storage nodeDefinition = NodeDefinition.load(nodeId);
        return (nodeDefinition.nodeType != NodeDefinition.NodeType.NONE);
    }

    /**
     * @dev Returns the output of a specified node.
     */
    function _process(bytes32 nodeId) internal view returns (NodeOutput.Data memory price) {
        NodeDefinition.Data storage nodeDefinition = NodeDefinition.load(nodeId);

        if (nodeDefinition.nodeType == NodeDefinition.NodeType.REDUCER) {
            return
                ReducerNode.process(
                    _processParentNodeOutputs(nodeDefinition),
                    nodeDefinition.parameters
                );
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.EXTERNAL) {
            return
                ExternalNode.process(
                    _processParentNodeOutputs(nodeDefinition),
                    nodeDefinition.parameters
                );
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.CHAINLINK) {
            return ChainlinkNode.process(nodeDefinition.parameters);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.UNISWAP) {
            return UniswapNode.process(nodeDefinition.parameters);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.PYTH) {
            return PythNode.process(nodeDefinition.parameters);
        } else if (
            nodeDefinition.nodeType == NodeDefinition.NodeType.PRICE_DEVIATION_CIRCUIT_BREAKER
        ) {
            return
                PriceDeviationCircuitBreakerNode.process(
                    _processParentNodeOutputs(nodeDefinition),
                    nodeDefinition.parameters
                );
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.STALENESS_CIRCUIT_BREAKER) {
            return
                StalenessCircuitBreakerNode.process(
                    _processParentNodeOutputs(nodeDefinition),
                    nodeDefinition.parameters
                );
        }
        revert UnprocessableNode(nodeId);
    }

    /**
     * @dev Returns the output of a specified node.
     */
    function _validateNodeDefinition(
        NodeDefinition.Data memory nodeDefinition
    ) internal returns (bool) {
        if (nodeDefinition.nodeType == NodeDefinition.NodeType.REDUCER) {
            return ReducerNode.validate(nodeDefinition);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.EXTERNAL) {
            return ExternalNode.validate(nodeDefinition);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.CHAINLINK) {
            return ChainlinkNode.validate(nodeDefinition);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.UNISWAP) {
            return UniswapNode.validate(nodeDefinition);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.PYTH) {
            return PythNode.validate(nodeDefinition);
        } else if (
            nodeDefinition.nodeType == NodeDefinition.NodeType.PRICE_DEVIATION_CIRCUIT_BREAKER
        ) {
            return PriceDeviationCircuitBreakerNode.validate(nodeDefinition);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.STALENESS_CIRCUIT_BREAKER) {
            return StalenessCircuitBreakerNode.validate(nodeDefinition);
        }
        return false;
    }

    /**
     * @dev helper function that calls process on parent nodes.
     */
    function _processParentNodeOutputs(
        NodeDefinition.Data storage nodeDefinition
    ) private view returns (NodeOutput.Data[] memory parentNodeOutputs) {
        parentNodeOutputs = new NodeOutput.Data[](nodeDefinition.parents.length);
        for (uint256 i = 0; i < nodeDefinition.parents.length; i++) {
            parentNodeOutputs[i] = this.process(nodeDefinition.parents[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";
import "../interfaces/external/IAggregatorV3Interface.sol";

library ChainlinkNode {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using DecimalMath for int256;

    uint256 public constant PRECISION = 18;

    function process(bytes memory parameters) internal view returns (NodeOutput.Data memory) {
        (address chainlinkAddr, uint256 twapTimeInterval, uint8 decimals) = abi.decode(
            parameters,
            (address, uint256, uint8)
        );
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(chainlinkAddr);
        (uint80 roundId, int256 price, , uint256 updatedAt, ) = chainlink.latestRoundData();

        int256 finalPrice = twapTimeInterval == 0
            ? price
            : getTwapPrice(chainlink, roundId, price, twapTimeInterval);

        finalPrice = decimals > PRECISION
            ? finalPrice.downscale(decimals - PRECISION)
            : finalPrice.upscale(PRECISION - decimals);

        return NodeOutput.Data(finalPrice, updatedAt, 0, 0);
    }

    function getTwapPrice(
        IAggregatorV3Interface chainlink,
        uint80 latestRoundId,
        int256 latestPrice,
        uint256 twapTimeInterval
    ) internal view returns (int256) {
        int256 priceSum = latestPrice;
        uint256 priceCount = 1;

        uint256 startTime = block.timestamp - twapTimeInterval;

        while (latestRoundId > 0) {
            try chainlink.getRoundData(--latestRoundId) returns (
                uint80,
                int256 answer,
                uint256,
                uint256 updatedAt,
                uint80
            ) {
                if (updatedAt < startTime) {
                    break;
                }
                priceSum += answer;
                priceCount++;
            } catch {
                break;
            }
        }

        return priceSum / priceCount.toInt();
    }

    function validate(NodeDefinition.Data memory nodeDefinition) internal view returns (bool) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32 * 3) {
            return false;
        }

        (address chainlinkAddr, , uint8 decimals) = abi.decode(
            nodeDefinition.parameters,
            (address, uint256, uint8)
        );
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(chainlinkAddr);

        // Must return latestRoundData without error
        chainlink.latestRoundData();

        // Must return decimals that match the definition
        if (decimals != chainlink.decimals()) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/ERC165Helper.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";
import "../interfaces/external/IExternalNode.sol";

library ExternalNode {
    function process(
        NodeOutput.Data[] memory prices,
        bytes memory parameters
    ) internal view returns (NodeOutput.Data memory) {
        IExternalNode externalNode = IExternalNode(abi.decode(parameters, (address)));
        return externalNode.process(prices, parameters);
    }

    function validate(NodeDefinition.Data memory nodeDefinition) internal returns (bool) {
        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length < 32) {
            return false;
        }

        address externalNode = abi.decode(nodeDefinition.parameters, (address));
        if (!ERC165Helper.safeSupportsInterface(externalNode, type(IExternalNode).interfaceId)) {
            return false;
        }

        if (!IExternalNode(externalNode).validate(nodeDefinition)) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";

library PriceDeviationCircuitBreakerNode {
    using SafeCastU256 for uint256;
    using DecimalMath for int256;

    error InvalidPrice();
    error DeviationToleranceExceeded(int256 deviation);

    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters
    ) internal pure returns (NodeOutput.Data memory) {
        uint256 deviationTolerance = abi.decode(parameters, (uint256));

        int256 primaryPrice = parentNodeOutputs[0].price;
        int256 comparisonPrice = parentNodeOutputs[1].price;

        if (primaryPrice != comparisonPrice) {
            int256 difference = abs(primaryPrice - comparisonPrice);
            if (
                primaryPrice == 0 ||
                deviationTolerance.toInt() < ((difference.upscale(18)) / abs(primaryPrice))
            ) {
                if (parentNodeOutputs.length > 2) {
                    return parentNodeOutputs[2];
                } else {
                    revert DeviationToleranceExceeded(
                        primaryPrice == 0 ? type(int256).max : difference / primaryPrice
                    );
                }
            }
        }

        return parentNodeOutputs[0];
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function validate(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool) {
        // Must have 2-3 parents
        if (!(nodeDefinition.parents.length == 2 || nodeDefinition.parents.length == 3)) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";
import "../interfaces/external/IPyth.sol";

library PythNode {
    using DecimalMath for int64;
    using SafeCastI256 for int256;

    int256 public constant PRECISION = 18;

    function process(bytes memory parameters) internal view returns (NodeOutput.Data memory) {
        (address pythAddress, bytes32 priceFeedId, bool useEma) = abi.decode(
            parameters,
            (address, bytes32, bool)
        );
        IPyth pyth = IPyth(pythAddress);
        PythStructs.Price memory pythData = useEma
            ? pyth.getEmaPriceUnsafe(priceFeedId)
            : pyth.getPriceUnsafe(priceFeedId);

        int256 factor = PRECISION + pythData.expo;
        int256 price = factor > 0
            ? pythData.price.upscale(factor.toUint())
            : pythData.price.downscale((-factor).toUint());

        return NodeOutput.Data(price, pythData.publishTime, 0, 0);
    }

    function validate(NodeDefinition.Data memory nodeDefinition) internal view returns (bool) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32 * 3) {
            return false;
        }

        (address pythAddress, bytes32 priceFeedId, bool useEma) = abi.decode(
            nodeDefinition.parameters,
            (address, bytes32, bool)
        );
        IPyth pyth = IPyth(pythAddress);

        // Must return relevant function without error
        useEma ? pyth.getEmaPriceUnsafe(priceFeedId) : pyth.getPriceUnsafe(priceFeedId);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";

library ReducerNode {
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;

    error UnsupportedOperation(Operations operation);
    error InvalidPrice(int256 price);

    enum Operations {
        RECENT,
        MIN,
        MAX,
        MEAN,
        MEDIAN,
        MUL,
        DIV
    }

    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters
    ) internal pure returns (NodeOutput.Data memory) {
        Operations operation = abi.decode(parameters, (Operations));

        if (operation == Operations.RECENT) {
            return recent(parentNodeOutputs);
        }
        if (operation == Operations.MIN) {
            return min(parentNodeOutputs);
        }
        if (operation == Operations.MAX) {
            return max(parentNodeOutputs);
        }
        if (operation == Operations.MEAN) {
            return mean(parentNodeOutputs);
        }
        if (operation == Operations.MEDIAN) {
            return median(parentNodeOutputs);
        }
        if (operation == Operations.MUL) {
            return mul(parentNodeOutputs);
        }
        if (operation == Operations.DIV) {
            return div(parentNodeOutputs);
        }

        revert UnsupportedOperation(operation);
    }

    function median(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory medianPrice) {
        quickSort(parentNodeOutputs, SafeCastI256.zero(), (parentNodeOutputs.length - 1).toInt());
        if (parentNodeOutputs.length % 2 == 0) {
            NodeOutput.Data[] memory middleSet = new NodeOutput.Data[](2);
            middleSet[0] = parentNodeOutputs[(parentNodeOutputs.length / 2) - 1];
            middleSet[1] = parentNodeOutputs[(parentNodeOutputs.length / 2)];
            return mean(middleSet);
        } else {
            return parentNodeOutputs[parentNodeOutputs.length / 2];
        }
    }

    function mean(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory meanPrice) {
        for (uint256 i = 0; i < parentNodeOutputs.length; i++) {
            meanPrice.price += parentNodeOutputs[i].price;
            meanPrice.timestamp += parentNodeOutputs[i].timestamp;
        }

        meanPrice.price = meanPrice.price / parentNodeOutputs.length.toInt();
        meanPrice.timestamp = meanPrice.timestamp / parentNodeOutputs.length;
    }

    function recent(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory recentPrice) {
        for (uint256 i = 0; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].timestamp > recentPrice.timestamp) {
                recentPrice = parentNodeOutputs[i];
            }
        }
    }

    function max(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory maxPrice) {
        maxPrice = parentNodeOutputs[0];
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].price > maxPrice.price) {
                maxPrice = parentNodeOutputs[i];
            }
        }
    }

    function min(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory minPrice) {
        minPrice = parentNodeOutputs[0];
        for (uint256 i = 0; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].price < minPrice.price) {
                minPrice = parentNodeOutputs[i];
            }
        }
    }

    function mul(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory mulPrice) {
        mulPrice.price = parentNodeOutputs[0].price;
        mulPrice.timestamp = parentNodeOutputs[0].timestamp;
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            mulPrice.price *= parentNodeOutputs[i].price;
            mulPrice.timestamp += parentNodeOutputs[i].timestamp;
        }
        mulPrice.timestamp = mulPrice.timestamp / parentNodeOutputs.length;
    }

    function div(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory divPrice) {
        divPrice.price = parentNodeOutputs[0].price;
        divPrice.timestamp = parentNodeOutputs[0].timestamp;
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].price == 0) {
                revert InvalidPrice(parentNodeOutputs[i].price);
            }
            divPrice.price /= parentNodeOutputs[i].price;
            divPrice.timestamp += parentNodeOutputs[i].timestamp;
        }
        divPrice.timestamp = divPrice.timestamp / parentNodeOutputs.length;
    }

    function quickSort(NodeOutput.Data[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        int pivot = arr[(left + (right - left) / 2).toUint()].price;
        while (i <= j) {
            while (arr[i.toUint()].price < pivot) i++;
            while (pivot < arr[j.toUint()].price) j--;
            if (i <= j) {
                (arr[i.toUint()], arr[j.toUint()]) = (arr[j.toUint()], arr[i.toUint()]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function validate(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool) {
        // Must have at least 2 parents
        if (nodeDefinition.parents.length < 2) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32) {
            return false;
        }

        // Must have valid operation
        uint operationId = abi.decode(nodeDefinition.parameters, (uint));
        if (operationId > 6) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";

library StalenessCircuitBreakerNode {
    error StalenessToleranceExceeded();

    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters
    ) internal view returns (NodeOutput.Data memory) {
        uint256 stalenessTolerance = abi.decode(parameters, (uint256));

        if (block.timestamp - parentNodeOutputs[0].timestamp <= stalenessTolerance) {
            return parentNodeOutputs[0];
        } else if (parentNodeOutputs.length == 1 || parentNodeOutputs[1].price == 0) {
            revert StalenessToleranceExceeded();
        }
        return parentNodeOutputs[1];
    }

    function validate(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool) {
        // Must have 1-2 parents
        if (!(nodeDefinition.parents.length == 1 || nodeDefinition.parents.length == 2)) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

import "../utils/FullMath.sol";
import "../utils/TickMath.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";
import "../interfaces/external/IUniswapV3Pool.sol";

library UniswapNode {
    using SafeCastU256 for uint256;
    using SafeCastU160 for uint160;
    using SafeCastU56 for uint56;
    using SafeCastU32 for uint32;
    using SafeCastI56 for int56;
    using SafeCastI256 for int256;

    using DecimalMath for int256;

    uint8 public constant PRECISION = 18;

    function process(bytes memory parameters) internal view returns (NodeOutput.Data memory) {
        (
            address token,
            address stablecoin,
            uint8 decimalsToken,
            uint8 decimalsStablecoin,
            address pool,
            uint32 secondsAgo
        ) = abi.decode(parameters, (address, address, uint8, uint8, address, uint32));

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        int24 tick = (tickCumulativesDelta / secondsAgo.to56().toInt()).to24();

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo.to256().toInt() != 0)) {
            tick--;
        }

        uint256 baseAmount = 10 ** decimalsToken;
        int256 price = getQuoteAtTick(tick, baseAmount, token, stablecoin).toInt();

        int256 finalPrice = PRECISION > decimalsStablecoin
            ? price.upscale(PRECISION - decimalsStablecoin)
            : price.downscale(decimalsStablecoin - PRECISION);

        return NodeOutput.Data(finalPrice, 0, 0, 0);
    }

    function getQuoteAtTick(
        int24 tick,
        uint256 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint256).max) {
            uint256 ratioX192 = sqrtRatioX96.to256() * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    function validate(NodeDefinition.Data memory nodeDefinition) internal view returns (bool) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 192) {
            return false;
        }

        (
            address token,
            address stablecoin,
            uint8 decimalsToken,
            uint8 decimalsStablecoin,
            address pool,
            uint32 secondsAgo
        ) = abi.decode(
                nodeDefinition.parameters,
                (address, address, uint8, uint8, address, uint32)
            );

        if (IERC20(token).decimals() != decimalsToken) {
            return false;
        }

        if (IERC20(stablecoin).decimals() != decimalsStablecoin) {
            return false;
        }

        address poolToken0 = IUniswapV3Pool(pool).token0();
        address poolToken1 = IUniswapV3Pool(pool).token1();

        if (
            !(poolToken0 == token && poolToken1 == stablecoin) &&
            !(poolToken0 == stablecoin && poolToken1 == token)
        ) {
            return false;
        }

        if (decimalsToken > 18 || decimalsStablecoin > 18) {
            return false;
        }

        // Must return relevant function without error
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;
        IUniswapV3Pool(pool).observe(secondsAgos);

        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeDefinition {
    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        UNISWAP,
        PYTH,
        PRICE_DEVIATION_CIRCUIT_BREAKER,
        STALENESS_CIRCUIT_BREAKER
    }

    struct Data {
        NodeType nodeType;
        bytes parameters;
        bytes32[] parents;
    }

    function load(bytes32 id) internal pure returns (Data storage node) {
        bytes32 s = keccak256(abi.encode("io.synthetix.oracle-manager.Node", id));
        assembly {
            node.slot := s
        }
    }

    function create(
        Data memory nodeDefinition
    ) internal returns (NodeDefinition.Data storage node, bytes32 id) {
        id = getId(nodeDefinition);

        node = load(id);

        node.nodeType = nodeDefinition.nodeType;
        node.parameters = nodeDefinition.parameters;
        node.parents = nodeDefinition.parents;
    }

    function getId(Data memory nodeDefinition) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    nodeDefinition.nodeType,
                    nodeDefinition.parameters,
                    nodeDefinition.parents
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeOutput {
    struct Data {
        int256 price;
        uint256 timestamp;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse1;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0, "Handle non-overflow cases");
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1, "prevents denominator == 0");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (-denominator.toInt() & denominator.toInt()).toUint();
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max, "result more than max");
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using SafeCastI24 for int24;
    using SafeCastU160 for uint160;

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? (-tick.to256()).toUint() : tick.to256().toUint();
        require(absTick <= MAX_TICK.to256().toUint(), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = ((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)).to160();
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = sqrtPriceX96.to256() << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 _log2 = (msb.toInt() - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(50, f))
        }

        int256 logSqrt10001 = _log2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = (logSqrt10001 - 3402992956809132418596140100660247210).to24() >> 128;
        int24 tickHi = (logSqrt10001 + 291339464771989622907027621153398088495).to24() >> 128;

        if (tickLow == tickHi) {
            tick = tickLow;
        } else {
            tick = getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}