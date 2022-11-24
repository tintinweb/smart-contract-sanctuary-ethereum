// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/helpers/IAuthentication.sol";
import "../vault/IVault.sol";

interface IAuthorizerAdaptor is IAuthentication {
    /**
     * @notice Returns the Balancer Vault
     */
    function getVault() external view returns (IVault);

    /**
     * @notice Returns the Authorizer
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @notice Performs an arbitrary function call on a target contract, provided the caller is authorized to do so.
     * @param target - Address of the contract to be called
     * @param data - Calldata to be sent to the target contract
     * @return The bytes encoded return value from the performed function call
     */
    function performAction(address target, bytes calldata data) external payable returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface ILendingPool {
    /**
     * @dev returns a 27 decimal fixed point 'ray' value so a rate of 1 is represented as 1e27
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";
import "../vault/IBasePool.sol";

interface ILinearPool is IBasePool {
    /**
     * @dev Returns the Pool's main token.
     */
    function getMainToken() external view returns (IERC20);

    /**
     * @dev Returns the Pool's wrapped token.
     */
    function getWrappedToken() external view returns (IERC20);

    /**
     * @dev Returns the index of the Pool's BPT in the Pool tokens array (as returned by IVault.getPoolTokens).
     */
    function getBptIndex() external view returns (uint256);

    /**
     * @dev Returns the index of the Pool's main token in the Pool tokens array (as returned by IVault.getPoolTokens).
     */
    function getMainIndex() external view returns (uint256);

    /**
     * @dev Returns the index of the Pool's wrapped token in the Pool tokens array (as returned by
     * IVault.getPoolTokens).
     */
    function getWrappedIndex() external view returns (uint256);

    /**
     * @dev Returns the Pool's targets for the main token balance. These values have had the main token's scaling
     * factor applied to them.
     */
    function getTargets() external view returns (uint256 lowerTarget, uint256 upperTarget);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "./ILendingPool.sol";

interface IStaticAToken {
    /**
     * @dev returns the address of the staticAToken's underlying asset
     */
    // solhint-disable-next-line func-name-mixedcase
    function ASSET() external view returns (address);

    /**
     * @dev returns the address of the staticAToken's lending pool
     */
    // solhint-disable-next-line func-name-mixedcase
    function LENDING_POOL() external view returns (ILendingPool);

    /**
     * @dev returns a 27 decimal fixed point 'ray' value so a rate of 1 is represented as 1e27
     */
    function rate() external view returns (uint256);

    function deposit(
        address,
        uint256,
        uint16,
        bool
    ) external returns (uint256);

    function withdraw(
        address,
        uint256,
        bool
    ) external returns (uint256, uint256);

    function staticToDynamicAmount(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

library BasePoolUserData {
    // Special ExitKind for all pools, used in Recovery Mode. Use the max 8-bit value to prevent conflicts
    // with future additions to the ExitKind enums (or any front-end code that maps to existing values)
    uint8 public constant RECOVERY_MODE_EXIT_KIND = 255;

    // Return true if this is the special exit kind.
    function isRecoveryModeExitKind(bytes memory self) internal pure returns (bool) {
        // Check for the "no data" case, or abi.decode would revert
        return self.length > 0 && abi.decode(self, (uint8)) == RECOVERY_MODE_EXIT_KIND;
    }

    // Parse the bptAmountIn out of the userData
    function recoveryModeExit(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (uint8, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/helpers/IAuthentication.sol";

interface IBasePoolFactory is IAuthentication {
    /**
     * @dev Returns true if `pool` was created by this factory.
     */
    function isPoolFromFactory(address pool) external view returns (bool);

    /**
     * @dev Check whether the derived factory has been disabled.
     */
    function isDisabled() external view returns (bool);

    /**
     * @dev Disable the factory, preventing the creation of more pools. Already existing pools are unaffected.
     * Once a factory is disabled, it cannot be re-enabled.
     */
    function disable() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IBasePoolFactory.sol";

interface ILastCreatedPoolFactory is IBasePoolFactory {
    /**
     * @dev Returns the address of the last Pool created by this factory.
     *
     * This is typically only useful in complex Pool deployment schemes, where multiple subsystems need to know about
     * each other. Note that this value will only be updated once construction of the last created Pool finishes.
     */
    function getLastCreatedPool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @notice Simple interface to retrieve the version of pools deployed by a pool factory.
 */
interface IPoolVersion {
    /**
     * @dev Returns a JSON representation of the deployed pool version containing name, version number and task ID.
     *
     * This is typically only useful in complex Pool deployment schemes, where multiple subsystems need to know about
     * each other. Note that this value will only be updated at factory creation time.
     */
    function getPoolVersion() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IRateProvider {
    /**
     * @dev Returns an 18 decimal fixed point number that is the exchange rate of the token to some other underlying
     * token. The meaning of this rate depends on the context.
     */
    function getRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface for the RecoveryMode module.
 */
interface IRecoveryMode {
    /**
     * @dev Emitted when the Recovery Mode status changes.
     */
    event RecoveryModeStateChanged(bool enabled);

    /**
     * @notice Enables Recovery Mode in the Pool, disabling protocol fee collection and allowing for safe proportional
     * exits with low computational complexity and no dependencies.
     */
    function enableRecoveryMode() external;

    /**
     * @notice Disables Recovery Mode in the Pool, restoring protocol fee collection and disallowing proportional exits.
     */
    function disableRecoveryMode() external;

    /**
     * @notice Returns true if the Pool is in Recovery Mode.
     */
    function inRecoveryMode() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @notice Simple interface to retrieve the version of a deployed contract.
 */
interface IVersion {
    /**
     * @dev Returns a JSON representation of the contract version containing name, version number and task ID.
     */
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(
    bool condition,
    uint256 errorCode,
    bytes3 prefix
) pure {
    if (!condition) _revert(errorCode, prefix);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _revert(uint256 errorCode) pure {
    _revert(errorCode, 0x42414c); // This is the raw byte representation of "BAL"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode, bytes3 prefix) pure {
    uint256 prefixUint = uint256(uint24(prefix));
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string.
        // We first append the '#' character (0x23) to the prefix. In the case of 'BAL', it results in 0x42414c23 ('BAL#')
        // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).
        let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

        let revertReason := shl(200, add(formattedPrefix, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;
    uint256 internal constant INSUFFICIENT_DATA = 105;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant FEATURE_DISABLED = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
    uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
    uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
    uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
    uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
    uint256 internal constant MAX_WEIGHT = 350;
    uint256 internal constant UNAUTHORIZED_JOIN = 351;
    uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;
    uint256 internal constant FRACTIONAL_TARGET = 353;
    uint256 internal constant ADD_OR_REMOVE_BPT = 354;
    uint256 internal constant INVALID_CIRCUIT_BREAKER_BOUNDS = 355;
    uint256 internal constant CIRCUIT_BREAKER_TRIPPED = 356;
    uint256 internal constant MALICIOUS_QUERY_REVERT = 357;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
    uint256 internal constant INVALID_OPERATION = 435;
    uint256 internal constant CODEC_OVERFLOW = 436;
    uint256 internal constant IN_RECOVERY_MODE = 437;
    uint256 internal constant NOT_IN_RECOVERY_MODE = 438;
    uint256 internal constant INDUCED_FAILURE = 439;
    uint256 internal constant EXPIRED_SIGNATURE = 440;
    uint256 internal constant MALFORMED_SIGNATURE = 441;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_UINT64 = 442;
    uint256 internal constant UNHANDLED_FEE_TYPE = 443;
    uint256 internal constant BURN_FROM_ZERO = 444;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
    uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;

    // FeeSplitter
    uint256 internal constant SPLITTER_FEE_PERCENTAGE_TOO_HIGH = 700;

    // Misc
    uint256 internal constant UNIMPLEMENTED = 998;
    uint256 internal constant SHOULD_NOT_HAPPEN = 999;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin/IERC20.sol";

/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../vault/IVault.sol";

/**
 * @dev Provides a way to perform queries on swaps, joins and exits, simulating these operations and returning the exact
 * result they would have if called on the Vault given the current state. Note that the results will be affected by
 * other transactions interacting with the Pools involved.
 *
 * All query functions can be called both on-chain and off-chain.
 *
 * If calling them from a contract, note that all query functions are not `view`. Despite this, these functions produce
 * no net state change, and for all intents and purposes can be thought of as if they were indeed `view`. However,
 * calling them via STATICCALL will fail.
 *
 * If calling them from an off-chain client, make sure to use eth_call: most clients default to eth_sendTransaction for
 * non-view functions.
 *
 * In all cases, the `fromInternalBalance` and `toInternalBalance` fields are entirely ignored: we just use the same
 * structs for simplicity.
 */
interface IBalancerQueries {
    function querySwap(IVault.SingleSwap memory singleSwap, IVault.FundManagement memory funds)
        external
        returns (uint256);

    function queryBatchSwap(
        IVault.SwapKind kind,
        IVault.BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        IVault.FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Source of truth for all Protocol Fee percentages, that is, how much the protocol charges certain actions. Some
 * of these values may also be retrievable from other places (such as the swap fee percentage), but this is the
 * preferred source nonetheless.
 */
interface IProtocolFeePercentagesProvider {
    // All fee percentages are 18-decimal fixed point numbers, so e.g. 1e18 = 100% and 1e16 = 1%.

    // Emitted when a new fee type is registered.
    event ProtocolFeeTypeRegistered(uint256 indexed feeType, string name, uint256 maximumPercentage);

    // Emitted when the value of a fee type changes.
    // IMPORTANT: it is possible for a third party to modify the SWAP and FLASH_LOAN fee type values directly in the
    // ProtocolFeesCollector, which will result in this event not being emitted despite their value changing. Such usage
    // of the ProtocolFeesCollector is however discouraged: all state-changing interactions with it should originate in
    // this contract.
    event ProtocolFeePercentageChanged(uint256 indexed feeType, uint256 percentage);

    /**
     * @dev Registers a new fee type in the system, making it queryable via `getFeeTypePercentage` and `getFeeTypeName`,
     * as well as configurable via `setFeeTypePercentage`.
     *
     * `feeType` can be any arbitrary value (that is not in use).
     *
     * It is not possible to de-register fee types, nor change their name or maximum value.
     */
    function registerFeeType(
        uint256 feeType,
        string memory name,
        uint256 maximumValue,
        uint256 initialValue
    ) external;

    /**
     * @dev Returns true if `feeType` has been registered and can be queried.
     */
    function isValidFeeType(uint256 feeType) external view returns (bool);

    /**
     * @dev Returns true if `value` is a valid percentage value for `feeType`.
     */
    function isValidFeeTypePercentage(uint256 feeType, uint256 value) external view returns (bool);

    /**
     * @dev Sets the percentage value for `feeType` to `newValue`.
     *
     * IMPORTANT: it is possible for a third party to modify the SWAP and FLASH_LOAN fee type values directly in the
     * ProtocolFeesCollector, without invoking this function. This will result in the `ProtocolFeePercentageChanged`
     * event not being emitted despite their value changing. Such usage of the ProtocolFeesCollector is however
     * discouraged: only this contract should be granted permission to call `setSwapFeePercentage` and
     * `setFlashLoanFeePercentage`.
     */
    function setFeeTypePercentage(uint256 feeType, uint256 newValue) external;

    /**
     * @dev Returns the current percentage value for `feeType`. This is the preferred mechanism for querying these -
     * whenever possible, use this fucntion instead of e.g. querying the ProtocolFeesCollector.
     */
    function getFeeTypePercentage(uint256 feeType) external view returns (uint256);

    /**
     * @dev Returns `feeType`'s maximum value.
     */
    function getFeeTypeMaximumPercentage(uint256 feeType) external view returns (uint256);

    /**
     * @dev Returns `feeType`'s name.
     */
    function getFeeTypeName(uint256 feeType) external view returns (string memory);
}

library ProtocolFeeType {
    // This list is not exhaustive - more fee types can be added to the system. It is expected for this list to be
    // extended with new fee types as they are registered, to keep them all in one place and reduce
    // likelihood of user error.

    // solhint-disable private-vars-leading-underscore
    uint256 internal constant SWAP = 0;
    uint256 internal constant FLASH_LOAN = 1;
    uint256 internal constant YIELD = 2;
    uint256 internal constant AUM = 3;
    // solhint-enable private-vars-leading-underscore
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IVault.sol";
import "./IPoolSwapStructs.sol";

/**
 * @dev Interface for adding and removing liquidity that all Pool contracts should implement. Note that this is not
 * the complete Pool contract interface, as it is missing the swap hooks. Pool contracts should also inherit from
 * either IGeneralPool or IMinimalSwapInfoPool
 */
interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `balances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `balances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Returns this Pool's ID, used when interacting with the Vault (to e.g. join the Pool or swap with it).
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @dev Returns the current swap fee percentage as a 18 decimal fixed point number, so e.g. 1e17 corresponds to a
     * 10% swap fee.
     */
    function getSwapFeePercentage() external view returns (uint256);

    /**
     * @dev Returns the scaling factors of each of the Pool's tokens. This is an implementation detail that is typically
     * not relevant for outside parties, but which might be useful for some types of Pools.
     */
    function getScalingFactors() external view returns (uint256[] memory);

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "../solidity-utils/openzeppelin/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

/**
 * @dev IPools with the General specialization setting should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will
 * grant to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IGeneralPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

/**
 * @dev Pool contracts with the MinimalSwapInfo or TwoToken specialization settings should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will grant
 * to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IMinimalSwapInfoPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

import "./IVault.sol";

interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

import "./IVault.sol";
import "./IAuthorizer.sol";

interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";
import "../solidity-utils/helpers/IAuthentication.sol";
import "../solidity-utils/helpers/ISignaturesValidator.sol";
import "../solidity-utils/helpers/ITemporarilyPausable.sol";
import "../solidity-utils/misc/IWETH.sol";

import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";
import "./IProtocolFeesCollector.sol";

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable, IAuthentication {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ERC20Permit.sol";

/**
 * @title Highly opinionated token implementation
 * @author Balancer Labs
 * @dev
 * - Includes functions to increase and decrease allowance as a workaround
 *   for the well-known issue with `approve`:
 *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * - Allows for 'infinite allowance', where an allowance of 0xff..ff is not
 *   decreased by calls to transferFrom
 * - Lets a token holder use `transferFrom` to send their own tokens,
 *   without first setting allowance
 * - Emits 'Approval' events whenever allowance is changed by `transferFrom`
 * - Assigns infinite allowance for all token holders to the Vault
 */
contract BalancerPoolToken is ERC20Permit {
    IVault private immutable _vault;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        IVault vault
    ) ERC20(tokenName, tokenSymbol) ERC20Permit(tokenName) {
        _vault = vault;
    }

    function getVault() public view returns (IVault) {
        return _vault;
    }

    // Overrides

    /**
     * @dev Override to grant the Vault infinite allowance, causing for Pool Tokens to not require approval.
     *
     * This is sound as the Vault already provides authorization mechanisms when initiation token transfers, which this
     * contract inherits.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        if (spender == address(getVault())) {
            return uint256(-1);
        } else {
            return super.allowance(owner, spender);
        }
    }

    /**
     * @dev Override to allow for 'infinite allowance' and let the token owner use `transferFrom` with no self-allowance
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        _require(msg.sender == sender || currentAllowance >= amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE);

        _transfer(sender, recipient, amount);

        if (msg.sender != sender && currentAllowance != uint256(-1)) {
            // Because of the previous require, we know that if msg.sender != sender then currentAllowance >= amount
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Override to allow decreasing allowance by more than the current amount (setting it to zero)
     */
    function decreaseAllowance(address spender, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);

        if (amount >= currentAllowance) {
            _approve(msg.sender, spender, 0);
        } else {
            // No risk of underflow due to if condition
            _approve(msg.sender, spender, currentAllowance - amount);
        }

        return true;
    }

    // Internal functions

    function _mintPoolTokens(address recipient, uint256 amount) internal {
        _mint(recipient, amount);
    }

    function _burnPoolTokens(address sender, uint256 amount) internal {
        _burn(sender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/vault/IAuthorizer.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/Authentication.sol";

/**
 * @dev Base authorization layer implementation for Pools.
 *
 * The owner account can call some of the permissioned functions - access control of the rest is delegated to the
 * Authorizer. Note that this owner is immutable: more sophisticated permission schemes, such as multiple ownership,
 * granular roles, etc., could be built on top of this by making the owner a smart contract.
 *
 * Access control of all other permissioned functions is delegated to an Authorizer. It is also possible to delegate
 * control of *all* permissioned functions to the Authorizer by setting the owner address to `_DELEGATE_OWNER`.
 */
abstract contract BasePoolAuthorization is Authentication {
    address private immutable _owner;

    address internal constant _DELEGATE_OWNER = 0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B;

    constructor(address owner) {
        _owner = owner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        if ((getOwner() != _DELEGATE_OWNER) && _isOwnerOnlyAction(actionId)) {
            // Only the owner can perform "owner only" actions, unless the owner is delegated.
            return msg.sender == getOwner();
        } else {
            // Non-owner actions are always processed via the Authorizer, as "owner only" ones are when delegated.
            return _getAuthorizer().canPerform(actionId, account, address(this));
        }
    }

    function _isOwnerOnlyAction(bytes32) internal view virtual returns (bool) {
        return false;
    }

    function _getAuthorizer() internal view virtual returns (IAuthorizer);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IProtocolFeePercentagesProvider.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/IBasePoolFactory.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/BaseSplitCodeFactory.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/SingletonAuthentication.sol";

/**
 * @notice Base contract for Pool factories.
 *
 * Pools are deployed from factories to allow third parties to reason about them. Unknown Pools may have arbitrary
 * logic: being able to assert that a Pool's behavior follows certain rules (those imposed by the contracts created by
 * the factory) is very powerful.
 *
 * @dev By using the split code mechanism, we can deploy Pools with creation code so large that a regular factory
 * contract would not be able to store it.
 *
 * Since we expect to release new versions of pool types regularly - and the blockchain is forever - versioning will
 * become increasingly important. Governance can deprecate a factory by calling `disable`, which will permanently
 * prevent the creation of any future pools from the factory.
 */
abstract contract BasePoolFactory is IBasePoolFactory, BaseSplitCodeFactory, SingletonAuthentication {
    IProtocolFeePercentagesProvider private immutable _protocolFeeProvider;

    mapping(address => bool) private _isPoolFromFactory;
    bool private _disabled;

    event PoolCreated(address indexed pool);
    event FactoryDisabled();

    constructor(
        IVault vault,
        IProtocolFeePercentagesProvider protocolFeeProvider,
        bytes memory creationCode
    ) BaseSplitCodeFactory(creationCode) SingletonAuthentication(vault) {
        _protocolFeeProvider = protocolFeeProvider;
    }

    function isPoolFromFactory(address pool) external view override returns (bool) {
        return _isPoolFromFactory[pool];
    }

    function isDisabled() public view override returns (bool) {
        return _disabled;
    }

    function disable() external override authenticate {
        _ensureEnabled();

        _disabled = true;

        emit FactoryDisabled();
    }

    function _ensureEnabled() internal view {
        _require(!isDisabled(), Errors.DISABLED);
    }

    function getProtocolFeePercentagesProvider() public view returns (IProtocolFeePercentagesProvider) {
        return _protocolFeeProvider;
    }

    function _create(bytes memory constructorArgs) internal virtual override returns (address) {
        _ensureEnabled();

        address pool = super._create(constructorArgs);

        _isPoolFromFactory[pool] = true;

        emit PoolCreated(pool);

        return pool;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Utility to create Pool factories for Pools that use the `TemporarilyPausable` contract.
 *
 * By calling `TemporarilyPausable`'s constructor with the result of `getPauseConfiguration`, all Pools created by this
 * factory will share the same Pause Window end time, after which both old and new Pools will not be pausable.
 */
contract FactoryWidePauseWindow {
    // This contract relies on timestamps in a similar way as `TemporarilyPausable` does - the same caveats apply.
    // solhint-disable not-rely-on-time

    uint256 private constant _INITIAL_PAUSE_WINDOW_DURATION = 90 days;
    uint256 private constant _BUFFER_PERIOD_DURATION = 30 days;

    // Time when the pause window for all created Pools expires, and the pause window duration of new Pools becomes
    // zero.
    uint256 private immutable _poolsPauseWindowEndTime;

    constructor() {
        _poolsPauseWindowEndTime = block.timestamp + _INITIAL_PAUSE_WINDOW_DURATION;
    }

    /**
     * @dev Returns the current `TemporarilyPausable` configuration that will be applied to Pools created by this
     * factory.
     *
     * `pauseWindowDuration` will decrease over time until it reaches zero, at which point both it and
     * `bufferPeriodDuration` will be zero forever, meaning deployed Pools will not be pausable.
     */
    function getPauseConfiguration() public view returns (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        uint256 currentTime = block.timestamp;
        if (currentTime < _poolsPauseWindowEndTime) {
            // The buffer period is always the same since its duration is related to how much time is needed to respond
            // to a potential emergency. The Pause Window duration however decreases as the end time approaches.

            pauseWindowDuration = _poolsPauseWindowEndTime - currentTime; // No need for checked arithmetic.
            bufferPeriodDuration = _BUFFER_PERIOD_DURATION;
        } else {
            // After the end time, newly created Pools have no Pause Window, nor Buffer Period (since they are not
            // pausable in the first place).

            pauseWindowDuration = 0;
            bufferPeriodDuration = 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

library ExternalCallLib {
    function bubbleUpNonMaliciousRevert(bytes memory errorData) internal pure {
        uint256 errorLength = errorData.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // If the first 4 bytes match the selector for one of the error signatures used by `BasePool._queryAction`
            // or `Vault.queryBatchSwap` then this error is attempting to impersonate the query mechanism used by these
            // contracts in order to inject bogus data. This can result in loss of funds if the return value is then
            // used in a later calculation.
            //
            // We then want to reject the following error signatures:
            // - `QueryError(uint256,uint256[])` (used by `BasePool._queryAction`)
            // - `QueryError(int256[])` (used by `Vault.queryBatchSwap`)

            // We only bubble up the revert reason if it doesn't match the any of the selectors for these error
            // sigatures, otherwise we revert with a new error message flagging that the revert was malicious.
            let error := and(
                mload(add(errorData, 0x20)),
                0xffffffff00000000000000000000000000000000000000000000000000000000
            )
            if iszero(
                or(
                    // BasePool._queryAction
                    eq(error, 0x43adbafb00000000000000000000000000000000000000000000000000000000),
                    // Vault.queryBatchSwap
                    eq(error, 0xfa61cc1200000000000000000000000000000000000000000000000000000000)
                )
            ) {
                revert(add(errorData, 0x20), errorLength)
            }
        }

        // We expect the assembly block to revert for all non-malicious errors.
        _revert(Errors.MALICIOUS_QUERY_REVERT);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/InputHelpers.sol";

library PoolRegistrationLib {
    function registerPool(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens
    ) internal returns (bytes32) {
        return registerPoolWithAssetManagers(vault, specialization, tokens, new address[](tokens.length));
    }

    function registerPoolWithAssetManagers(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) internal returns (bytes32) {
        // The Vault only requires the token list to be ordered for the Two Token Pools specialization. However,
        // to make the developer experience consistent, we are requiring this condition for all the native pools.
        //
        // Note that for Pools which can register and deregister tokens after deployment, this property may not hold
        // as tokens which are added to the Pool after deployment are always added to the end of the array.
        InputHelpers.ensureArrayIsSorted(tokens);

        return _registerPool(vault, specialization, tokens, assetManagers);
    }

    function registerComposablePool(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) internal returns (bytes32) {
        // The Vault only requires the token list to be ordered for the Two Token Pools specialization. However,
        // to make the developer experience consistent, we are requiring this condition for all the native pools.
        //
        // Note that for Pools which can register and deregister tokens after deployment, this property may not hold
        // as tokens which are added to the Pool after deployment are always added to the end of the array.
        InputHelpers.ensureArrayIsSorted(tokens);

        IERC20[] memory composableTokens = new IERC20[](tokens.length + 1);
        // We insert the Pool's BPT address into the first position.
        // This allows us to know the position of the BPT token in the tokens array without explicitly tracking it.
        // When deregistering a token, the token at the end of the array is moved into the index of the deregistered
        // token, changing its index. By placing BPT at the beginning of the tokens array we can be sure that its index
        // will never change unless it is deregistered itself (something which composable pools must prevent anyway).
        composableTokens[0] = IERC20(address(this));
        for (uint256 i = 0; i < tokens.length; i++) {
            composableTokens[i + 1] = tokens[i];
        }

        address[] memory composableAssetManagers = new address[](assetManagers.length + 1);
        // We do not allow an asset manager for the Pool's BPT.
        composableAssetManagers[0] = address(0);
        for (uint256 i = 0; i < assetManagers.length; i++) {
            composableAssetManagers[i + 1] = assetManagers[i];
        }
        return _registerPool(vault, specialization, composableTokens, composableAssetManagers);
    }

    function _registerPool(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) private returns (bytes32) {
        bytes32 poolId = vault.registerPool(specialization);

        // We don't need to check that tokens and assetManagers have the same length, since the Vault already performs
        // that check.
        vault.registerTokens(poolId, tokens, assetManagers);

        return poolId;
    }

    function registerToken(
        IVault vault,
        bytes32 poolId,
        IERC20 token,
        address assetManager
    ) internal {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = token;

        address[] memory assetManagers = new address[](1);
        assetManagers[0] = assetManager;

        vault.registerTokens(poolId, tokens, assetManagers);
    }

    function deregisterToken(
        IVault vault,
        bytes32 poolId,
        IERC20 token
    ) internal {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = token;

        vault.deregisterTokens(poolId, tokens);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IBasePool.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IGeneralPool.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IMinimalSwapInfoPool.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/TemporarilyPausable.sol";

import "./BalancerPoolToken.sol";
import "./BasePoolAuthorization.sol";
import "./RecoveryMode.sol";

// solhint-disable max-states-count

/**
 * @notice Reference implementation for the base layer of a Pool contract.
 * @dev Reference implementation for the base layer of a Pool contract that manages a single Pool with optional
 * Asset Managers, an admin-controlled swap fee percentage, and an emergency pause mechanism.
 *
 * This Pool pays protocol fees by minting BPT directly to the ProtocolFeeCollector instead of using the
 * `dueProtocolFees` return value. This results in the underlying tokens continuing to provide liquidity
 * for traders, while still keeping gas usage to a minimum since only a single token (the BPT) is transferred.
 *
 * Note that neither swap fees nor the pause mechanism are used by this contract. They are passed through so that
 * derived contracts can use them via the `_addSwapFeeAmount` and `_subtractSwapFeeAmount` functions, and the
 * `whenNotPaused` modifier.
 *
 * No admin permissions are checked here: instead, this contract delegates that to the Vault's own Authorizer.
 *
 * Because this contract doesn't implement the swap hooks, derived contracts should generally inherit from
 * BaseGeneralPool or BaseMinimalSwapInfoPool. Otherwise, subclasses must inherit from the corresponding interfaces
 * and implement the swap callbacks themselves.
 */
abstract contract NewBasePool is
    IBasePool,
    IGeneralPool,
    IMinimalSwapInfoPool,
    BasePoolAuthorization,
    BalancerPoolToken,
    TemporarilyPausable,
    RecoveryMode
{
    using BasePoolUserData for bytes;

    uint256 private constant _DEFAULT_MINIMUM_BPT = 1e6;

    bytes32 private immutable _poolId;

    // Note that this value is immutable in the Vault, so we can make it immutable here and save gas
    IProtocolFeesCollector private immutable _protocolFeesCollector;

    constructor(
        IVault vault,
        bytes32 poolId,
        string memory name,
        string memory symbol,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        // Base Pools are expected to be deployed using factories. By using the factory address as the action
        // disambiguator, we make all Pools deployed by the same factory share action identifiers. This allows for
        // simpler management of permissions (such as being able to manage granting the 'set fee percentage' action in
        // any Pool created by the same factory), while still making action identifiers unique among different factories
        // if the selectors match, preventing accidental errors.
        Authentication(bytes32(uint256(msg.sender)))
        BalancerPoolToken(name, symbol, vault)
        BasePoolAuthorization(owner)
        TemporarilyPausable(pauseWindowDuration, bufferPeriodDuration)
    {
        // Set immutable state variables - these cannot be read from during construction
        _poolId = poolId;
        _protocolFeesCollector = vault.getProtocolFeesCollector();
    }

    // Getters

    /**
     * @notice Return the pool id.
     */
    function getPoolId() public view override returns (bytes32) {
        return _poolId;
    }

    function _getAuthorizer() internal view override returns (IAuthorizer) {
        // Access control management is delegated to the Vault's Authorizer. This lets Balancer Governance manage which
        // accounts can call permissioned functions: for example, to perform emergency pauses.
        // If the owner is delegated, then *all* permissioned functions, including `updateSwapFeeGradually`, will be
        // under Governance control.
        return getVault().getAuthorizer();
    }

    /**
     * @dev Returns the minimum BPT supply. This amount is minted to the zero address during initialization, effectively
     * locking it.
     *
     * This is useful to make sure Pool initialization happens only once, but derived Pools can change this value (even
     * to zero) by overriding this function.
     */
    function _getMinimumBpt() internal pure virtual returns (uint256) {
        return _DEFAULT_MINIMUM_BPT;
    }

    // Protocol Fees

    /**
     * @notice Return the ProtocolFeesCollector contract.
     * @dev This is immutable, and retrieved from the Vault on construction. (It is also immutable in the Vault.)
     */
    function getProtocolFeesCollector() public view returns (IProtocolFeesCollector) {
        return _protocolFeesCollector;
    }

    /**
     * @dev Pays protocol fees by minting `bptAmount` to the Protocol Fee Collector.
     */
    function _payProtocolFees(uint256 bptAmount) internal {
        if (bptAmount > 0) {
            _mintPoolTokens(address(getProtocolFeesCollector()), bptAmount);
        }
    }

    /**
     * @notice Pause the pool: an emergency action which disables all pool functions.
     * @dev This is a permissioned function that will only work during the Pause Window set during pool factory
     * deployment (see `TemporarilyPausable`).
     */
    function pause() external authenticate {
        _setPaused(true);
    }

    /**
     * @notice Reverse a `pause` operation, and restore a pool to normal functionality.
     * @dev This is a permissioned function that will only work on a paused pool within the Buffer Period set during
     * pool factory deployment (see `TemporarilyPausable`). Note that any paused pools will automatically unpause
     * after the Buffer Period expires.
     */
    function unpause() external authenticate {
        _setPaused(false);
    }

    modifier onlyVault(bytes32 poolId) {
        _require(msg.sender == address(getVault()), Errors.CALLER_NOT_VAULT);
        _require(poolId == getPoolId(), Errors.INVALID_POOL_ID);
        _;
    }

    // Swap / Join / Exit Hooks

    function onSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) external override onlyVault(request.poolId) returns (uint256) {
        _ensureNotPaused();

        return _onSwapMinimal(request, balanceTokenIn, balanceTokenOut);
    }

    function _onSwapMinimal(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal virtual returns (uint256);

    function onSwap(
        SwapRequest memory request,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external override onlyVault(request.poolId) returns (uint256) {
        _ensureNotPaused();

        return _onSwapGeneral(request, balances, indexIn, indexOut);
    }

    function _onSwapGeneral(
        SwapRequest memory request,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal virtual returns (uint256);

    /**
     * @notice Vault hook for adding liquidity to a pool (including the first time, "initializing" the pool).
     * @dev This function can only be called from the Vault, from `joinPool`.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override onlyVault(poolId) returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFees) {
        uint256 bptAmountOut;

        _ensureNotPaused();
        if (totalSupply() == 0) {
            (bptAmountOut, amountsIn) = _onInitializePool(sender, recipient, userData);

            // On initialization, we lock _getMinimumBpt() by minting it for the zero address. This BPT acts as a
            // minimum as it will never be burned, which reduces potential issues with rounding, and also prevents the
            // Pool from ever being fully drained.
            // Some pool types do not require this mechanism, and the minimum BPT might be zero.
            _require(bptAmountOut >= _getMinimumBpt(), Errors.MINIMUM_BPT);
            _mintPoolTokens(address(0), _getMinimumBpt());

            _mintPoolTokens(recipient, bptAmountOut - _getMinimumBpt());
        } else {
            (bptAmountOut, amountsIn) = _onJoinPool(sender, balances, userData);

            // Note we no longer use `balances` after calling `_onJoinPool`, which may mutate it.

            _mintPoolTokens(recipient, bptAmountOut);
        }

        // This Pool ignores the `dueProtocolFees` return value, so we simply return a zeroed-out array.
        dueProtocolFees = new uint256[](amountsIn.length);
    }

    /**
     * @notice Vault hook for removing liquidity from a pool.
     * @dev This function can only be called from the Vault, from `exitPool`.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override onlyVault(poolId) returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFees) {
        uint256 bptAmountIn;

        // When a user calls `exitPool`, this is the first point of entry from the Vault.
        // We first check whether this is a Recovery Mode exit - if so, we proceed using this special lightweight exit
        // mechanism which avoids computing any complex values, interacting with external contracts, etc., and generally
        // should always work, even if the Pool's mathematics or a dependency break down.
        if (userData.isRecoveryModeExitKind()) {
            // This exit kind is only available in Recovery Mode.
            _ensureInRecoveryMode();

            // Note that we don't upscale balances nor downscale amountsOut - we don't care about scaling factors during
            // a recovery mode exit.
            (bptAmountIn, amountsOut) = _doRecoveryModeExit(balances, totalSupply(), userData);
        } else {
            // Note that we only call this if we're not in a recovery mode exit.
            _ensureNotPaused();

            (bptAmountIn, amountsOut) = _onExitPool(sender, balances, userData);
        }

        // Note we no longer use `balances` after calling `_onExitPool`, which may mutate it.

        _burnPoolTokens(sender, bptAmountIn);

        // This Pool ignores the `dueProtocolFees` return value, so we simply return a zeroed-out array.
        dueProtocolFees = new uint256[](amountsOut.length);
    }

    // Query functions

    /**
     * @notice "Dry run" `onJoinPool`.
     * @dev Returns the amount of BPT that would be granted to `recipient` if the `onJoinPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `sender` would have to supply.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
    function queryJoin(
        bytes32,
        address sender,
        address,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override returns (uint256 bptOut, uint256[] memory amountsIn) {
        _queryAction(sender, balances, userData, _onJoinPool);

        // The `return` opcode is executed directly inside `_queryAction`, so execution never reaches this statement,
        // and we don't need to return anything here - it just silences compiler warnings.
        return (bptOut, amountsIn);
    }

    /**
     * @notice "Dry run" `onExitPool`.
     * @dev Returns the amount of BPT that would be burned from `sender` if the `onExitPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `recipient` would receive.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
    function queryExit(
        bytes32,
        address sender,
        address,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override returns (uint256 bptIn, uint256[] memory amountsOut) {
        _queryAction(sender, balances, userData, _onExitPool);

        // The `return` opcode is executed directly inside `_queryAction`, so execution never reaches this statement,
        // and we don't need to return anything here - it just silences compiler warnings.
        return (bptIn, amountsOut);
    }

    // Internal hooks to be overridden by derived contracts - all token amounts (except BPT) in these interfaces are
    // upscaled.

    /**
     * @dev Called when the Pool is joined for the first time; that is, when the BPT total supply is zero.
     *
     * Returns the amount of BPT to mint, and the token amounts the Pool will receive in return.
     *
     * Minted BPT will be sent to `recipient`, except for _getMinimumBpt(), which will be deducted from this amount and
     * sent to the zero address instead. This will cause that BPT to remain forever locked there, preventing total BTP
     * from ever dropping below that value, and ensuring `_onInitializePool` can only be called once in the entire
     * Pool's lifetime.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     */
    function _onInitializePool(
        address sender,
        address recipient,
        bytes memory userData
    ) internal virtual returns (uint256 bptAmountOut, uint256[] memory amountsIn);

    /**
     * @dev Called whenever the Pool is joined after the first initialization join (see `_onInitializePool`).
     *
     * Returns the amount of BPT to mint, the token amounts that the Pool will receive in return, and the number of
     * tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * Minted BPT will be sent to `recipient`.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onJoinPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     */
    function _onJoinPool(
        address sender,
        uint256[] memory balances,
        bytes memory userData
    ) internal virtual returns (uint256 bptAmountOut, uint256[] memory amountsIn);

    /**
     * @dev Called whenever the Pool is exited.
     *
     * Returns the amount of BPT to burn, the token amounts for each Pool token that the Pool will grant in return, and
     * the number of tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * BPT will be burnt from `sender`.
     *
     * The Pool will grant tokens to `recipient`. These amounts are considered upscaled and will be downscaled
     * (rounding down) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onExitPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     */
    function _onExitPool(
        address sender,
        uint256[] memory balances,
        bytes memory userData
    ) internal virtual returns (uint256 bptAmountIn, uint256[] memory amountsOut);

    function _queryAction(
        address sender,
        uint256[] memory balances,
        bytes memory userData,
        function(address, uint256[] memory, bytes memory) internal returns (uint256, uint256[] memory) _action
    ) private {
        // This uses the same technique used by the Vault in queryBatchSwap. Refer to that function for a detailed
        // explanation.

        if (msg.sender != address(this)) {
            // We perform an external call to ourselves, forwarding the same calldata. In this call, the else clause of
            // the preceding if statement will be executed instead.

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(msg.data);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // This call should always revert to decode the bpt and token amounts from the revert reason
                switch success
                    case 0 {
                        // Note we are manually writing the memory slot 0. We can safely overwrite whatever is
                        // stored there as we take full control of the execution and then immediately return.

                        // We copy the first 4 bytes to check if it matches with the expected signature, otherwise
                        // there was another revert reason and we should forward it.
                        returndatacopy(0, 0, 0x04)
                        let error := and(mload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

                        // If the first 4 bytes don't match with the expected signature, we forward the revert reason.
                        if eq(eq(error, 0x43adbafb00000000000000000000000000000000000000000000000000000000), 0) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }

                        // The returndata contains the signature, followed by the raw memory representation of the
                        // `bptAmount` and `tokenAmounts` (array: length + data). We need to return an ABI-encoded
                        // representation of these.
                        // An ABI-encoded response will include one additional field to indicate the starting offset of
                        // the `tokenAmounts` array. The `bptAmount` will be laid out in the first word of the
                        // returndata.
                        //
                        // In returndata:
                        // [ signature ][ bptAmount ][ tokenAmounts length ][ tokenAmounts values ]
                        // [  4 bytes  ][  32 bytes ][       32 bytes      ][ (32 * length) bytes ]
                        //
                        // We now need to return (ABI-encoded values):
                        // [ bptAmount ][ tokeAmounts offset ][ tokenAmounts length ][ tokenAmounts values ]
                        // [  32 bytes ][       32 bytes     ][       32 bytes      ][ (32 * length) bytes ]

                        // We copy 32 bytes for the `bptAmount` from returndata into memory.
                        // Note that we skip the first 4 bytes for the error signature
                        returndatacopy(0, 0x04, 32)

                        // The offsets are 32-bytes long, so the array of `tokenAmounts` will start after
                        // the initial 64 bytes.
                        mstore(0x20, 64)

                        // We now copy the raw memory array for the `tokenAmounts` from returndata into memory.
                        // Since bpt amount and offset take up 64 bytes, we start copying at address 0x40. We also
                        // skip the first 36 bytes from returndata, which correspond to the signature plus bpt amount.
                        returndatacopy(0x40, 0x24, sub(returndatasize(), 36))

                        // We finally return the ABI-encoded uint256 and the array, which has a total length equal to
                        // the size of returndata, plus the 32 bytes of the offset but without the 4 bytes of the
                        // error signature.
                        return(0, add(returndatasize(), 28))
                    }
                    default {
                        // This call should always revert, but we fail nonetheless if that didn't happen
                        invalid()
                    }
            }
        } else {
            (uint256 bptAmount, uint256[] memory tokenAmounts) = _action(sender, balances, userData);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // We will return a raw representation of `bptAmount` and `tokenAmounts` in memory, which is composed of
                // a 32-byte uint256, followed by a 32-byte for the array length, and finally the 32-byte uint256 values
                // Because revert expects a size in bytes, we multiply the array length (stored at `tokenAmounts`) by 32
                let size := mul(mload(tokenAmounts), 32)

                // We store the `bptAmount` in the previous slot to the `tokenAmounts` array. We can make sure there
                // will be at least one available slot due to how the memory scratch space works.
                // We can safely overwrite whatever is stored in this slot as we will revert immediately after that.
                let start := sub(tokenAmounts, 0x20)
                mstore(start, bptAmount)

                // We send one extra value for the error signature "QueryError(uint256,uint256[])" which is 0x43adbafb
                // We use the previous slot to `bptAmount`.
                mstore(sub(start, 0x20), 0x0000000000000000000000000000000000000000000000000000000043adbafb)
                start := sub(start, 0x04)

                // When copying from `tokenAmounts` into returndata, we copy the additional 68 bytes to also return
                // the `bptAmount`, the array 's length, and the error signature.
                revert(start, add(size, 68))
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/WordCodec.sol";

/**
 * Price rate caches are used to avoid querying the price rate for a token every time we need to work with it. It is
 * useful for slow changing rates, such as those that arise from interest-bearing tokens (e.g. waDAI into DAI).
 *
 * The cache data is packed into a single bytes32 value with the following structure:
 * [ 32 bits |  32 bits  |  96 bits  |    96 bits    ]
 * [ expires | duration  | old rate  | current rate  ]
 * |MSB                                           LSB|
 *
 * 'rate' is an 18 decimal fixed point number, supporting rates of up to ~3e10. 'expires' is a Unix timestamp, and
 * 'duration' is expressed in seconds.
 */
library PriceRateCache {
    using WordCodec for bytes32;

    uint256 private constant _CURRENT_PRICE_RATE_OFFSET = 0;
    uint256 private constant _OLD_PRICE_RATE_OFFSET = 96;
    uint256 private constant _PRICE_RATE_CACHE_DURATION_OFFSET = 192;
    uint256 private constant _PRICE_RATE_CACHE_EXPIRES_OFFSET = 224;

    uint256 private constant _RATE_BIT_LENGTH = 96;
    uint256 private constant _DURATION_BIT_LENGTH = 32;

    /**
     * @dev Returns the current rate in the price rate cache.
     */
    function getCurrentRate(bytes32 cache) internal pure returns (uint256) {
        return cache.decodeUint(_CURRENT_PRICE_RATE_OFFSET, _RATE_BIT_LENGTH);
    }

    /**
     * @dev Returns the old rate in the price rate cache.
     */
    function getOldRate(bytes32 cache) internal pure returns (uint256) {
        return cache.decodeUint(_OLD_PRICE_RATE_OFFSET, _RATE_BIT_LENGTH);
    }

    /**
     * @dev Copies the current rate to the old rate.
     */
    function updateOldRate(bytes32 cache) internal pure returns (bytes32) {
        return cache.insertUint(getCurrentRate(cache), _OLD_PRICE_RATE_OFFSET, _RATE_BIT_LENGTH);
    }

    /**
     * @dev Returns the duration of a price rate cache.
     */
    function getDuration(bytes32 cache) internal pure returns (uint256) {
        return cache.decodeUint(_PRICE_RATE_CACHE_DURATION_OFFSET, _DURATION_BIT_LENGTH);
    }

    /**
     * @dev Returns the duration and expiration time of a price rate cache.
     */
    function getTimestamps(bytes32 cache) internal pure returns (uint256 duration, uint256 expires) {
        duration = getDuration(cache);
        expires = cache.decodeUint(_PRICE_RATE_CACHE_EXPIRES_OFFSET, _DURATION_BIT_LENGTH);
    }

    /**
     * @dev Encodes rate and duration into a price rate cache. The expiration time is computed automatically, counting
     * from the current time.
     */
    function updateRateAndDuration(
        bytes32 cache,
        uint256 rate,
        uint256 duration
    ) internal view returns (bytes32) {
        _require(rate >> _RATE_BIT_LENGTH == 0, Errors.PRICE_RATE_OVERFLOW);

        // solhint-disable not-rely-on-time
        return
            cache
                .insertUint(rate, _CURRENT_PRICE_RATE_OFFSET, _RATE_BIT_LENGTH)
                .insertUint(duration, _PRICE_RATE_CACHE_DURATION_OFFSET, _DURATION_BIT_LENGTH)
                .insertUint(block.timestamp + duration, _PRICE_RATE_CACHE_EXPIRES_OFFSET, _DURATION_BIT_LENGTH);
    }

    /**
     * @dev Update the current rate in a price rate cache.
     */
    function updateCurrentRate(bytes32 cache, uint256 rate) internal pure returns (bytes32) {
        _require(rate >> _RATE_BIT_LENGTH == 0, Errors.PRICE_RATE_OVERFLOW);

        return cache.insertUint(rate, _CURRENT_PRICE_RATE_OFFSET, _RATE_BIT_LENGTH);
    }

    /**
     * @dev Update the duration (and expiration) in a price rate cache.
     */
    function updateDuration(bytes32 cache, uint256 duration) internal view returns (bytes32) {
        return
            cache.insertUint(duration, _PRICE_RATE_CACHE_DURATION_OFFSET, _DURATION_BIT_LENGTH).insertUint(
                block.timestamp + duration,
                _PRICE_RATE_CACHE_EXPIRES_OFFSET,
                _DURATION_BIT_LENGTH
            );
    }

    /**
     * @dev Returns rate, duration and expiration time of a price rate cache.
     */
    function decode(bytes32 cache)
        internal
        pure
        returns (
            uint256 rate,
            uint256 duration,
            uint256 expires
        )
    {
        rate = getCurrentRate(cache);
        (duration, expires) = getTimestamps(cache);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/BasePoolUserData.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/IRecoveryMode.sol";

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";

import "./BasePoolAuthorization.sol";

/**
 * @notice Handle storage and state changes for pools that support "Recovery Mode".
 *
 * @dev This is intended to provide a safe way to exit any pool during some kind of emergency, to avoid locking funds
 * in the event the pool enters a non-functional state (i.e., some code that normally runs during exits is causing
 * them to revert).
 *
 * Recovery Mode is *not* the same as pausing the pool. The pause function is only available during a short window
 * after factory deployment. Pausing can only be intentionally reversed during a buffer period, and the contract
 * will permanently unpause itself thereafter. Paused pools are completely disabled, in a kind of suspended animation,
 * until they are voluntarily or involuntarily unpaused.
 *
 * By contrast, a privileged account - typically a governance multisig - can place a pool in Recovery Mode at any
 * time, and it is always reversible. The pool is *not* disabled while in this mode: though of course whatever
 * condition prompted the transition to Recovery Mode has likely effectively disabled some functions. Rather,
 * a special "clean" exit is enabled, which runs the absolute minimum code necessary to exit proportionally.
 * In particular, stable pools do not attempt to compute the invariant (which is a complex, iterative calculation
 * that can fail in extreme circumstances), and no protocol fees are collected.
 *
 * It is critical to ensure that turning on Recovery Mode would do no harm, if activated maliciously or in error.
 */
abstract contract RecoveryMode is IRecoveryMode, BasePoolAuthorization {
    using FixedPoint for uint256;
    using BasePoolUserData for bytes;

    /**
     * @dev Reverts if the contract is in Recovery Mode.
     */
    modifier whenNotInRecoveryMode() {
        _ensureNotInRecoveryMode();
        _;
    }

    /**
     * @notice Enable recovery mode, which enables a special safe exit path for LPs.
     * @dev Does not otherwise affect pool operations (beyond deferring payment of protocol fees), though some pools may
     * perform certain operations in a "safer" manner that is less likely to fail, in an attempt to keep the pool
     * running, even in a pathological state. Unlike the Pause operation, which is only available during a short window
     * after factory deployment, Recovery Mode can always be enabled.
     */
    function enableRecoveryMode() external override authenticate {
        // Unlike when recovery mode is disabled, derived contracts should *not* do anything when it is enabled.
        // We do not want to make any calls that could fail and prevent the pool from entering recovery mode.
        // Accordingly, this should have no effect, but for consistency with `disableRecoveryMode`, revert if
        // recovery mode was already enabled.
        _ensureNotInRecoveryMode();

        _setRecoveryMode(true);

        emit RecoveryModeStateChanged(true);
    }

    /**
     * @notice Disable recovery mode, which disables the special safe exit path for LPs.
     * @dev Protocol fees are not paid while in Recovery Mode, so it should only remain active for as long as strictly
     * necessary.
     */
    function disableRecoveryMode() external override authenticate {
        // Some derived contracts respond to disabling recovery mode with state changes (e.g., related to protocol fees,
        // or otherwise ensuring that enabling and disabling recovery mode has no ill effects on LPs). When called
        // outside of recovery mode, these state changes might lead to unexpected behavior.
        _ensureInRecoveryMode();

        _setRecoveryMode(false);

        emit RecoveryModeStateChanged(false);
    }

    // Defer implementation for functions that require storage

    /**
     * @notice Override to check storage and return whether the pool is in Recovery Mode
     */
    function inRecoveryMode() public view virtual override returns (bool);

    /**
     * @dev Override to update storage and emit the event
     *
     * No complex code or external calls that could fail should be placed in the implementations,
     * which could jeopardize the ability to enable and disable Recovery Mode.
     */
    function _setRecoveryMode(bool enabled) internal virtual;

    /**
     * @dev Reverts if the contract is not in Recovery Mode.
     */
    function _ensureInRecoveryMode() internal view {
        _require(inRecoveryMode(), Errors.NOT_IN_RECOVERY_MODE);
    }

    /**
     * @dev Reverts if the contract is in Recovery Mode.
     */
    function _ensureNotInRecoveryMode() internal view {
        _require(!inRecoveryMode(), Errors.IN_RECOVERY_MODE);
    }

    /**
     * @dev A minimal proportional exit, suitable as is for most pools: though not for pools with preminted BPT
     * or other special considerations. Designed to be overridden if a pool needs to do extra processing,
     * such as scaling a stored invariant, or caching the new total supply.
     *
     * No complex code or external calls should be made in derived contracts that override this!
     */
    function _doRecoveryModeExit(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) internal virtual returns (uint256, uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/pool-utils/IVersion.sol";

/**
 * @notice Retrieves a contract's version set at creation time from storage.
 */
contract Version is IVersion {
    string private _version;

    constructor(string memory version) {
        _version = version;
    }

    function version() external view override returns (string memory) {
        return _version;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

/**
 * @dev Building block for performing access control on external functions.
 *
 * This contract is used via the `authenticate` modifier (or the `_authenticateCaller` function), which can be applied
 * to external functions to only make them callable by authorized accounts.
 *
 * Derived contracts must implement the `_canPerform` function, which holds the actual access control logic.
 */
abstract contract Authentication is IAuthentication {
    bytes32 private immutable _actionIdDisambiguator;

    /**
     * @dev The main purpose of the `actionIdDisambiguator` is to prevent accidental function selector collisions in
     * multi contract systems.
     *
     * There are two main uses for it:
     *  - if the contract is a singleton, any unique identifier can be used to make the associated action identifiers
     *    unique. The contract's own address is a good option.
     *  - if the contract belongs to a family that shares action identifiers for the same functions, an identifier
     *    shared by the entire family (and no other contract) should be used instead.
     */
    constructor(bytes32 actionIdDisambiguator) {
        _actionIdDisambiguator = actionIdDisambiguator;
    }

    /**
     * @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
     */
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    /**
     * @dev Reverts unless the caller is allowed to call the entry point function.
     */
    function _authenticateCaller() internal view {
        bytes32 actionId = getActionId(msg.sig);
        _require(_canPerform(actionId, msg.sender), Errors.SENDER_NOT_ALLOWED);
    }

    function getActionId(bytes4 selector) public view override returns (bytes32) {
        // Each external function is dynamically assigned an action identifier as the hash of the disambiguator and the
        // function selector. Disambiguation is necessary to avoid potential collisions in the function selectors of
        // multiple contracts.
        return keccak256(abi.encodePacked(_actionIdDisambiguator, selector));
    }

    function _canPerform(bytes32 actionId, address user) internal view virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./CodeDeployer.sol";

/**
 * @dev Base factory for contracts whose creation code is so large that the factory cannot hold it. This happens when
 * the contract's creation code grows close to 24kB.
 *
 * Note that this factory cannot help with contracts that have a *runtime* (deployed) bytecode larger than 24kB.
 */
abstract contract BaseSplitCodeFactory {
    // The contract's creation code is stored as code in two separate addresses, and retrieved via `extcodecopy`. This
    // means this factory supports contracts with creation code of up to 48kB.
    // We rely on inline-assembly to achieve this, both to make the entire operation highly gas efficient, and because
    // `extcodecopy` is not available in Solidity.

    // solhint-disable no-inline-assembly

    address private immutable _creationCodeContractA;
    uint256 private immutable _creationCodeSizeA;

    address private immutable _creationCodeContractB;
    uint256 private immutable _creationCodeSizeB;

    /**
     * @dev The creation code of a contract Foo can be obtained inside Solidity with `type(Foo).creationCode`.
     */
    constructor(bytes memory creationCode) {
        uint256 creationCodeSize = creationCode.length;

        // We are going to deploy two contracts: one with approximately the first half of `creationCode`'s contents
        // (A), and another with the remaining half (B).
        // We store the lengths in both immutable and stack variables, since immutable variables cannot be read during
        // construction.
        uint256 creationCodeSizeA = creationCodeSize / 2;
        _creationCodeSizeA = creationCodeSizeA;

        uint256 creationCodeSizeB = creationCodeSize - creationCodeSizeA;
        _creationCodeSizeB = creationCodeSizeB;

        // To deploy the contracts, we're going to use `CodeDeployer.deploy()`, which expects a memory array with
        // the code to deploy. Note that we cannot simply create arrays for A and B's code by copying or moving
        // `creationCode`'s contents as they are expected to be very large (> 24kB), so we must operate in-place.

        // Memory: [ code length ] [ A.data ] [ B.data ]

        // Creating A's array is simple: we simply replace `creationCode`'s length with A's length. We'll later restore
        // the original length.

        bytes memory creationCodeA;
        assembly {
            creationCodeA := creationCode
            mstore(creationCodeA, creationCodeSizeA)
        }

        // Memory: [ A.length ] [ A.data ] [ B.data ]
        //         ^ creationCodeA

        _creationCodeContractA = CodeDeployer.deploy(creationCodeA);

        // Creating B's array is a bit more involved: since we cannot move B's contents, we are going to create a 'new'
        // memory array starting at A's last 32 bytes, which will be replaced with B's length. We'll back-up this last
        // byte to later restore it.

        bytes memory creationCodeB;
        bytes32 lastByteA;

        assembly {
            // `creationCode` points to the array's length, not data, so by adding A's length to it we arrive at A's
            // last 32 bytes.
            creationCodeB := add(creationCode, creationCodeSizeA)
            lastByteA := mload(creationCodeB)
            mstore(creationCodeB, creationCodeSizeB)
        }

        // Memory: [ A.length ] [ A.data[ : -1] ] [ B.length ][ B.data ]
        //         ^ creationCodeA                ^ creationCodeB

        _creationCodeContractB = CodeDeployer.deploy(creationCodeB);

        // We now restore the original contents of `creationCode` by writing back the original length and A's last byte.
        assembly {
            mstore(creationCodeA, creationCodeSize)
            mstore(creationCodeB, lastByteA)
        }
    }

    /**
     * @dev Returns the two addresses where the creation code of the contract crated by this factory is stored.
     */
    function getCreationCodeContracts() public view returns (address contractA, address contractB) {
        return (_creationCodeContractA, _creationCodeContractB);
    }

    /**
     * @dev Returns the creation code of the contract this factory creates.
     */
    function getCreationCode() public view returns (bytes memory) {
        return _getCreationCodeWithArgs("");
    }

    /**
     * @dev Returns the creation code that will result in a contract being deployed with `constructorArgs`.
     */
    function _getCreationCodeWithArgs(bytes memory constructorArgs) private view returns (bytes memory code) {
        // This function exists because `abi.encode()` cannot be instructed to place its result at a specific address.
        // We need for the ABI-encoded constructor arguments to be located immediately after the creation code, but
        // cannot rely on `abi.encodePacked()` to perform concatenation as that would involve copying the creation code,
        // which would be prohibitively expensive.
        // Instead, we compute the creation code in a pre-allocated array that is large enough to hold *both* the
        // creation code and the constructor arguments, and then copy the ABI-encoded arguments (which should not be
        // overly long) right after the end of the creation code.

        // Immutable variables cannot be used in assembly, so we store them in the stack first.
        address creationCodeContractA = _creationCodeContractA;
        uint256 creationCodeSizeA = _creationCodeSizeA;
        address creationCodeContractB = _creationCodeContractB;
        uint256 creationCodeSizeB = _creationCodeSizeB;

        uint256 creationCodeSize = creationCodeSizeA + creationCodeSizeB;
        uint256 constructorArgsSize = constructorArgs.length;

        uint256 codeSize = creationCodeSize + constructorArgsSize;

        assembly {
            // First, we allocate memory for `code` by retrieving the free memory pointer and then moving it ahead of
            // `code` by the size of the creation code plus constructor arguments, and 32 bytes for the array length.
            code := mload(0x40)
            mstore(0x40, add(code, add(codeSize, 32)))

            // We now store the length of the code plus constructor arguments.
            mstore(code, codeSize)

            // Next, we concatenate the creation code stored in A and B.
            let dataStart := add(code, 32)
            extcodecopy(creationCodeContractA, dataStart, 0, creationCodeSizeA)
            extcodecopy(creationCodeContractB, add(dataStart, creationCodeSizeA), 0, creationCodeSizeB)
        }

        // Finally, we copy the constructorArgs to the end of the array. Unfortunately there is no way to avoid this
        // copy, as it is not possible to tell Solidity where to store the result of `abi.encode()`.
        uint256 constructorArgsDataPtr;
        uint256 constructorArgsCodeDataPtr;
        assembly {
            constructorArgsDataPtr := add(constructorArgs, 32)
            constructorArgsCodeDataPtr := add(add(code, 32), creationCodeSize)
        }

        _memcpy(constructorArgsCodeDataPtr, constructorArgsDataPtr, constructorArgsSize);
    }

    /**
     * @dev Deploys a contract with constructor arguments. To create `constructorArgs`, call `abi.encode()` with the
     * contract's constructor arguments, in order.
     */
    function _create(bytes memory constructorArgs) internal virtual returns (address) {
        bytes memory creationCode = _getCreationCodeWithArgs(constructorArgs);

        address destination;
        assembly {
            destination := create(0, add(creationCode, 32), mload(creationCode))
        }

        if (destination == address(0)) {
            // Bubble up inner revert reason
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return destination;
    }

    // From
    // https://github.com/Arachnid/solidity-stringutils/blob/b9a6f6615cf18a87a823cbc461ce9e140a61c305/src/strings.sol
    function _memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Library used to deploy contracts with specific code. This can be used for long-term storage of immutable data as
 * contract code, which can be retrieved via the `extcodecopy` opcode.
 */
library CodeDeployer {
    // During contract construction, the full code supplied exists as code, and can be accessed via `codesize` and
    // `codecopy`. This is not the contract's final code however: whatever the constructor returns is what will be
    // stored as its code.
    //
    // We use this mechanism to have a simple constructor that stores whatever is appended to it. The following opcode
    // sequence corresponds to the creation code of the following equivalent Solidity contract, plus padding to make the
    // full code 32 bytes long:
    //
    // contract CodeDeployer {
    //     constructor() payable {
    //         uint256 size;
    //         assembly {
    //             size := sub(codesize(), 32) // size of appended data, as constructor is 32 bytes long
    //             codecopy(0, 32, size) // copy all appended data to memory at position 0
    //             return(0, size) // return appended data for it to be stored as code
    //         }
    //     }
    // }
    //
    // More specifically, it is composed of the following opcodes (plus padding):
    //
    // [1] PUSH1 0x20
    // [2] CODESIZE
    // [3] SUB
    // [4] DUP1
    // [6] PUSH1 0x20
    // [8] PUSH1 0x00
    // [9] CODECOPY
    // [11] PUSH1 0x00
    // [12] RETURN
    //
    // The padding is just the 0xfe sequence (invalid opcode). It is important as it lets us work in-place, avoiding
    // memory allocation and copying.
    bytes32
        private constant _DEPLOYER_CREATION_CODE = 0x602038038060206000396000f3fefefefefefefefefefefefefefefefefefefe;

    /**
     * @dev Deploys a contract with `code` as its code, returning the destination address.
     *
     * Reverts if deployment fails.
     */
    function deploy(bytes memory code) internal returns (address destination) {
        bytes32 deployerCreationCode = _DEPLOYER_CREATION_CODE;

        // We need to concatenate the deployer creation code and `code` in memory, but want to avoid copying all of
        // `code` (which could be quite long) into a new memory location. Therefore, we operate in-place using
        // assembly.

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let codeLength := mload(code)

            // `code` is composed of length and data. We've already stored its length in `codeLength`, so we simply
            // replace it with the deployer creation code (which is exactly 32 bytes long).
            mstore(code, deployerCreationCode)

            // At this point, `code` now points to the deployer creation code immediately followed by `code`'s data
            // contents. This is exactly what the deployer expects to receive when created.
            destination := create(0, code, add(codeLength, 32))

            // Finally, we restore the original length in order to not mutate `code`.
            mstore(code, codeLength)
        }

        // The create opcode returns the zero address when contract creation fails, so we revert if this happens.
        _require(destination != address(0), Errors.CODE_DEPLOYMENT_FAILED);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/ISignaturesValidator.sol";

import "../openzeppelin/EIP712.sol";

/**
 * @dev Utility for signing Solidity function calls.
 */
abstract contract EOASignaturesValidator is ISignaturesValidator, EIP712 {
    // Replay attack prevention for each account.
    mapping(address => uint256) internal _nextNonce;

    function getDomainSeparator() public view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getNextNonce(address account) public view override returns (uint256) {
        return _nextNonce[account];
    }

    function _ensureValidSignature(
        address account,
        bytes32 structHash,
        bytes memory signature,
        uint256 errorCode
    ) internal {
        return _ensureValidSignature(account, structHash, signature, type(uint256).max, errorCode);
    }

    function _ensureValidSignature(
        address account,
        bytes32 structHash,
        bytes memory signature,
        uint256 deadline,
        uint256 errorCode
    ) internal {
        bytes32 digest = _hashTypedDataV4(structHash);
        _require(_isValidSignature(account, digest, signature), errorCode);

        // We could check for the deadline before validating the signature, but this leads to saner error processing (as
        // we only care about expired deadlines if the signature is correct) and only affects the gas cost of the revert
        // scenario, which will only occur infrequently, if ever.
        // The deadline is timestamp-based: it should not be relied upon for sub-minute accuracy.
        // solhint-disable-next-line not-rely-on-time
        _require(deadline >= block.timestamp, Errors.EXPIRED_SIGNATURE);

        // We only advance the nonce after validating the signature. This is irrelevant for this module, but it can be
        // important in derived contracts that override _isValidSignature (e.g. SignaturesValidator), as we want for
        // the observable state to still have the current nonce as the next valid one.
        _nextNonce[account] += 1;
    }

    function _isValidSignature(
        address account,
        bytes32 digest,
        bytes memory signature
    ) internal view virtual returns (bool) {
        _require(signature.length == 65, Errors.MALFORMED_SIGNATURE);

        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the r, s and v signature parameters, and the only way to get them is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        address recoveredAddress = ecrecover(digest, v, r, s);

        // ecrecover returns the zero address on recover failure, so we need to handle that explicitly.
        return (recoveredAddress != address(0) && recoveredAddress == account);
    }

    function _toArraySignature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory) {
        bytes memory signature = new bytes(65);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(signature, 32), r)
            mstore(add(signature, 64), s)
            mstore8(add(signature, 96), v)
        }

        return signature;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";

// solhint-disable

function _asIAsset(IERC20[] memory tokens) pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
        assets := tokens
    }
}

function _sortTokens(
    IERC20 tokenA,
    IERC20 tokenB
) pure returns (IERC20[] memory tokens) {
    bool aFirst = tokenA < tokenB;
    IERC20[] memory sortedTokens = new IERC20[](2);

    sortedTokens[0] = aFirst ? tokenA : tokenB;
    sortedTokens[1] = aFirst ? tokenB : tokenA;

    return sortedTokens;
}

function _insertSorted(IERC20[] memory tokens, IERC20 token) pure returns (IERC20[] memory sorted) {
    sorted = new IERC20[](tokens.length + 1);

    if (tokens.length == 0) {
        sorted[0] = token;
        return sorted;
    }

    uint256 i;
    for (i = tokens.length; i > 0 && tokens[i - 1] > token; i--) sorted[i] = tokens[i - 1];
    for (uint256 j = 0; j < i; j++) sorted[j] = tokens[j];
    sorted[i] = token;
}

function _findTokenIndex(IERC20[] memory tokens, IERC20 token) pure returns (uint256) {
    // Note that while we know tokens are initially sorted, we cannot assume this will hold throughout
    // the pool's lifetime, as pools with mutable tokens can append and remove tokens in any order.
    uint256 tokensLength = tokens.length;
    for (uint256 i = 0; i < tokensLength; i++) {
        if (tokens[i] == token) {
            return i;
        }
    }

    _revert(Errors.INVALID_TOKEN);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../math/FixedPoint.sol";
import "../math/Math.sol";
import "../openzeppelin/ERC20.sol";
import "./InputHelpers.sol";

// solhint-disable

// To simplify Pool logic, all token balances and amounts are normalized to behave as if the token had 18 decimals.
// e.g. When comparing DAI (18 decimals) and USDC (6 decimals), 1 USDC and 1 DAI would both be represented as 1e18,
// whereas without scaling 1 USDC would be represented as 1e6.
// This allows us to not consider differences in token decimals in the internal Pool maths, simplifying it greatly.

// Single Value

/**
 * @dev Applies `scalingFactor` to `amount`, resulting in a larger or equal value depending on whether it needed
 * scaling or not.
 */
function _upscale(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    // Upscale rounding wouldn't necessarily always go in the same direction: in a swap for example the balance of
    // token in should be rounded up, and that of token out rounded down. This is the only place where we round in
    // the same direction for all amounts, as the impact of this rounding is expected to be minimal.
    return FixedPoint.mulDown(amount, scalingFactor);
}

/**
 * @dev Reverses the `scalingFactor` applied to `amount`, resulting in a smaller or equal value depending on
 * whether it needed scaling or not. The result is rounded down.
 */
function _downscaleDown(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    return FixedPoint.divDown(amount, scalingFactor);
}

/**
 * @dev Reverses the `scalingFactor` applied to `amount`, resulting in a smaller or equal value depending on
 * whether it needed scaling or not. The result is rounded up.
 */
function _downscaleUp(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    return FixedPoint.divUp(amount, scalingFactor);
}

// Array

/**
 * @dev Same as `_upscale`, but for an entire array. This function does not return anything, but instead *mutates*
 * the `amounts` array.
 */
function _upscaleArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.mulDown(amounts[i], scalingFactors[i]);
    }
}

/**
 * @dev Same as `_downscaleDown`, but for an entire array. This function does not return anything, but instead
 * *mutates* the `amounts` array.
 */
function _downscaleDownArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.divDown(amounts[i], scalingFactors[i]);
    }
}

/**
 * @dev Same as `_downscaleUp`, but for an entire array. This function does not return anything, but instead
 * *mutates* the `amounts` array.
 */
function _downscaleUpArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.divUp(amounts[i], scalingFactors[i]);
    }
}

function _computeScalingFactor(IERC20 token) view returns (uint256) {
    // Tokens that don't implement the `decimals` method are not supported.
    uint256 tokenDecimals = ERC20(address(token)).decimals();

    // Tokens with more than 18 decimals are not supported.
    uint256 decimalsDifference = Math.sub(18, tokenDecimals);
    return FixedPoint.ONE * 10**decimalsDifference;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/liquidity-mining/IAuthorizerAdaptor.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

import "./Authentication.sol";

abstract contract SingletonAuthentication is Authentication {
    IVault private immutable _vault;

    // Use the contract's own address to disambiguate action identifiers
    constructor(IVault vault) Authentication(bytes32(uint256(address(this)))) {
        _vault = vault;
    }

    /**
     * @notice Returns the Balancer Vault
     */
    function getVault() public view returns (IVault) {
        return _vault;
    }

    /**
     * @notice Returns the Authorizer
     */
    function getAuthorizer() public view returns (IAuthorizer) {
        return getVault().getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        return getAuthorizer().canPerform(actionId, account, address(this));
    }

    function _canPerform(
        bytes32 actionId,
        address account,
        address where
    ) internal view returns (bool) {
        return getAuthorizer().canPerform(actionId, account, where);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/ITemporarilyPausable.sol";

/**
 * @dev Allows for a contract to be paused during an initial period after deployment, disabling functionality. Can be
 * used as an emergency switch in case a security vulnerability or threat is identified.
 *
 * The contract can only be paused during the Pause Window, a period that starts at deployment. It can also be
 * unpaused and repaused any number of times during this period. This is intended to serve as a safety measure: it lets
 * system managers react quickly to potentially dangerous situations, knowing that this action is reversible if careful
 * analysis later determines there was a false alarm.
 *
 * If the contract is paused when the Pause Window finishes, it will remain in the paused state through an additional
 * Buffer Period, after which it will be automatically unpaused forever. This is to ensure there is always enough time
 * to react to an emergency, even if the threat is discovered shortly before the Pause Window expires.
 *
 * Note that since the contract can only be paused within the Pause Window, unpausing during the Buffer Period is
 * irreversible.
 */
abstract contract TemporarilyPausable is ITemporarilyPausable {
    // The Pause Window and Buffer Period are timestamp-based: they should not be relied upon for sub-minute accuracy.
    // solhint-disable not-rely-on-time

    uint256 private constant _MAX_PAUSE_WINDOW_DURATION = 90 days;
    uint256 private constant _MAX_BUFFER_PERIOD_DURATION = 30 days;

    uint256 private immutable _pauseWindowEndTime;
    uint256 private immutable _bufferPeriodEndTime;

    bool private _paused;

    constructor(uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        _require(pauseWindowDuration <= _MAX_PAUSE_WINDOW_DURATION, Errors.MAX_PAUSE_WINDOW_DURATION);
        _require(bufferPeriodDuration <= _MAX_BUFFER_PERIOD_DURATION, Errors.MAX_BUFFER_PERIOD_DURATION);

        uint256 pauseWindowEndTime = block.timestamp + pauseWindowDuration;

        _pauseWindowEndTime = pauseWindowEndTime;
        _bufferPeriodEndTime = pauseWindowEndTime + bufferPeriodDuration;
    }

    /**
     * @dev Reverts if the contract is paused.
     */
    modifier whenNotPaused() {
        _ensureNotPaused();
        _;
    }

    /**
     * @dev Returns the current contract pause status, as well as the end times of the Pause Window and Buffer
     * Period.
     */
    function getPausedState()
        external
        view
        override
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        )
    {
        paused = !_isNotPaused();
        pauseWindowEndTime = _getPauseWindowEndTime();
        bufferPeriodEndTime = _getBufferPeriodEndTime();
    }

    /**
     * @dev Sets the pause state to `paused`. The contract can only be paused until the end of the Pause Window, and
     * unpaused until the end of the Buffer Period.
     *
     * Once the Buffer Period expires, this function reverts unconditionally.
     */
    function _setPaused(bool paused) internal {
        if (paused) {
            _require(block.timestamp < _getPauseWindowEndTime(), Errors.PAUSE_WINDOW_EXPIRED);
        } else {
            _require(block.timestamp < _getBufferPeriodEndTime(), Errors.BUFFER_PERIOD_EXPIRED);
        }

        _paused = paused;
        emit PausedStateChanged(paused);
    }

    /**
     * @dev Reverts if the contract is paused.
     */
    function _ensureNotPaused() internal view {
        _require(_isNotPaused(), Errors.PAUSED);
    }

    /**
     * @dev Reverts if the contract is not paused.
     */
    function _ensurePaused() internal view {
        _require(!_isNotPaused(), Errors.NOT_PAUSED);
    }

    /**
     * @dev Returns true if the contract is unpaused.
     *
     * Once the Buffer Period expires, the gas cost of calling this function is reduced dramatically, as storage is no
     * longer accessed.
     */
    function _isNotPaused() internal view returns (bool) {
        // After the Buffer Period, the (inexpensive) timestamp check short-circuits the storage access.
        return block.timestamp > _getBufferPeriodEndTime() || !_paused;
    }

    // These getters lead to reduced bytecode size by inlining the immutable variables in a single place.

    function _getPauseWindowEndTime() private view returns (uint256) {
        return _pauseWindowEndTime;
    }

    function _getBufferPeriodEndTime() private view returns (uint256) {
        return _bufferPeriodEndTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

import "../math/Math.sol";

/**
 * @dev Library for encoding and decoding values stored inside a 256 bit word. Typically used to pack multiple values in
 * a single storage slot, saving gas by performing less storage accesses.
 *
 * Each value is defined by its size and the least significant bit in the word, also known as offset. For example, two
 * 128 bit values may be encoded in a word by assigning one an offset of 0, and the other an offset of 128.
 *
 * We could use Solidity structs to pack values together in a single storage slot instead of relying on a custom and
 * error-prone library, but unfortunately Solidity only allows for structs to live in either storage, calldata or
 * memory. Because a memory struct uses not just memory but also a slot in the stack (to store its memory location),
 * using memory for word-sized values (i.e. of 256 bits or less) is strictly less gas performant, and doesn't even
 * prevent stack-too-deep issues. This is compounded by the fact that Balancer contracts typically are memory-intensive,
 * and the cost of accesing memory increases quadratically with the number of allocated words. Manual packing and
 * unpacking is therefore the preferred approach.
 */
library WordCodec {
    // solhint-disable no-inline-assembly

    // Masks are values with the least significant N bits set. They can be used to extract an encoded value from a word,
    // or to insert a new one replacing the old.
    uint256 private constant _MASK_1 = 2**(1) - 1;
    uint256 private constant _MASK_192 = 2**(192) - 1;

    // In-place insertion

    /**
     * @dev Inserts an unsigned integer of bitLength, shifted by an offset, into a 256 bit word,
     * replacing the old value. Returns the new word.
     */
    function insertUint(
        bytes32 word,
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32 result) {
        _validateEncodingParams(value, offset, bitLength);
        // Equivalent to:
        // uint256 mask = (1 << bitLength) - 1;
        // bytes32 clearedWord = bytes32(uint256(word) & ~(mask << offset));
        // result = clearedWord | bytes32(value << offset);
        assembly {
            let mask := sub(shl(bitLength, 1), 1)
            let clearedWord := and(word, not(shl(offset, mask)))
            result := or(clearedWord, shl(offset, value))
        }
    }

    /**
     * @dev Inserts a signed integer shifted by an offset into a 256 bit word, replacing the old value. Returns
     * the new word.
     *
     * Assumes `value` can be represented using `bitLength` bits.
     */
    function insertInt(
        bytes32 word,
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        uint256 mask = (1 << bitLength) - 1;
        bytes32 clearedWord = bytes32(uint256(word) & ~(mask << offset));
        // Integer values need masking to remove the upper bits of negative values.
        return clearedWord | bytes32((uint256(value) & mask) << offset);
    }

    // Encoding

    /**
     * @dev Encodes an unsigned integer shifted by an offset. Ensures value fits within
     * `bitLength` bits.
     *
     * The return value can be ORed bitwise with other encoded values to form a 256 bit word.
     */
    function encodeUint(
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        return bytes32(value << offset);
    }

    /**
     * @dev Encodes a signed integer shifted by an offset.
     *
     * The return value can be ORed bitwise with other encoded values to form a 256 bit word.
     */
    function encodeInt(
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        uint256 mask = (1 << bitLength) - 1;
        // Integer values need masking to remove the upper bits of negative values.
        return bytes32((uint256(value) & mask) << offset);
    }

    // Decoding

    /**
     * @dev Decodes and returns an unsigned integer with `bitLength` bits, shifted by an offset, from a 256 bit word.
     */
    function decodeUint(
        bytes32 word,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = uint256(word >> offset) & ((1 << bitLength) - 1);
        assembly {
            result := and(shr(offset, word), sub(shl(bitLength, 1), 1))
        }
    }

    /**
     * @dev Decodes and returns a signed integer with `bitLength` bits, shifted by an offset, from a 256 bit word.
     */
    function decodeInt(
        bytes32 word,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (int256 result) {
        int256 maxInt = int256((1 << (bitLength - 1)) - 1);
        uint256 mask = (1 << bitLength) - 1;

        int256 value = int256(uint256(word >> offset) & mask);
        // In case the decoded value is greater than the max positive integer that can be represented with bitLength
        // bits, we know it was originally a negative integer. Therefore, we mask it to restore the sign in the 256 bit
        // representation.
        //
        // Equivalent to:
        // result = value > maxInt ? (value | int256(~mask)) : value;
        assembly {
            result := or(mul(gt(value, maxInt), not(mask)), value)
        }
    }

    // Special cases

    /**
     * @dev Decodes and returns a boolean shifted by an offset from a 256 bit word.
     */
    function decodeBool(bytes32 word, uint256 offset) internal pure returns (bool result) {
        // Equivalent to:
        // result = (uint256(word >> offset) & 1) == 1;
        assembly {
            result := and(shr(offset, word), 1)
        }
    }

    /**
     * @dev Inserts a 192 bit value shifted by an offset into a 256 bit word, replacing the old value.
     * Returns the new word.
     *
     * Assumes `value` can be represented using 192 bits.
     */
    function insertBits192(
        bytes32 word,
        bytes32 value,
        uint256 offset
    ) internal pure returns (bytes32) {
        bytes32 clearedWord = bytes32(uint256(word) & ~(_MASK_192 << offset));
        return clearedWord | bytes32((uint256(value) & _MASK_192) << offset);
    }

    /**
     * @dev Inserts a boolean value shifted by an offset into a 256 bit word, replacing the old value. Returns the new
     * word.
     */
    function insertBool(
        bytes32 word,
        bool value,
        uint256 offset
    ) internal pure returns (bytes32 result) {
        // Equivalent to:
        // bytes32 clearedWord = bytes32(uint256(word) & ~(1 << offset));
        // bytes32 referenceInsertBool = clearedWord | bytes32(uint256(value ? 1 : 0) << offset);
        assembly {
            let clearedWord := and(word, not(shl(offset, 1)))
            result := or(clearedWord, shl(offset, value))
        }
    }

    // Helpers

    function _validateEncodingParams(
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) private pure {
        _require(offset < 256, Errors.OUT_OF_BOUNDS);
        // We never accept 256 bit values (which would make the codec pointless), and the larger the offset the smaller
        // the maximum bit length.
        _require(bitLength >= 1 && bitLength <= Math.min(255, 256 - offset), Errors.OUT_OF_BOUNDS);

        // Testing unsigned values for size is straightforward: their upper bits must be cleared.
        _require(value >> bitLength == 0, Errors.CODEC_OVERFLOW);
    }

    function _validateEncodingParams(
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) private pure {
        _require(offset < 256, Errors.OUT_OF_BOUNDS);
        // We never accept 256 bit values (which would make the codec pointless), and the larger the offset the smaller
        // the maximum bit length.
        _require(bitLength >= 1 && bitLength <= Math.min(255, 256 - offset), Errors.OUT_OF_BOUNDS);

        // Testing signed values for size is a bit more involved.
        if (value >= 0) {
            // For positive values, we can simply check that the upper bits are clear. Notice we remove one bit from the
            // length for the sign bit.
            _require(value >> (bitLength - 1) == 0, Errors.CODEC_OVERFLOW);
        } else {
            // Negative values can receive the same treatment by making them positive, with the caveat that the range
            // for negative values in two's complement supports one more value than for the positive case.
            _require(Math.abs(value + 1) >> (bitLength - 1) == 0, Errors.CODEC_OVERFLOW);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

import "./LogExpMath.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    // solhint-disable no-inline-assembly

    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant TWO = 2 * ONE;
    uint256 internal constant FOUR = 4 * ONE;
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, if x == 0 then the result is zero
        //
        // Equivalent to:
        // result = product == 0 ? 0 : ((product - 1) / FixedPoint.ONE) + 1;
        assembly {
            result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        uint256 aInflated = a * ONE;
        _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

        return aInflated / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        _require(b != 0, Errors.ZERO_DIVISION);

        uint256 aInflated = a * ONE;
        _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, if x == 0 then the result is zero
        //
        // Equivalent to:
        // result = a == 0 ? 0 : (a * FixedPoint.ONE - 1) / b + 1;
        assembly {
            result := mul(iszero(iszero(aInflated)), add(div(sub(aInflated, 1), b), 1))
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulDown(x, x);
        } else if (y == FOUR) {
            uint256 square = mulDown(x, x);
            return mulDown(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            if (raw < maxError) {
                return 0;
            } else {
                return sub(raw, maxError);
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulUp(x, x);
        } else if (y == FOUR) {
            uint256 square = mulUp(x, x);
            return mulUp(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            return add(raw, maxError);
        }
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = (x < ONE) ? (ONE - x) : 0;
        assembly {
            result := mul(lt(x, ONE), sub(ONE, x))
        }
    }
}

// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x >> 255 == 0, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = _ln_36(base);
        } else {
            logBase = _ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = _ln_36(arg);
        } else {
            logArg = _ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Errors.OUT_OF_BOUNDS);
        if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
            return _ln_36(a) / ONE_18;
        } else {
            return _ln(a);
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library.
 */
library Math {
    // solhint-disable no-inline-assembly

    /**
     * @dev Returns the absolute value of a signed integer.
     */
    function abs(int256 a) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = a > 0 ? uint256(a) : uint256(-a)
        assembly {
            let s := sar(255, a)
            result := sub(xor(a, s), s)
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = (a < b) ? b : a;
        assembly {
            result := sub(a, mul(sub(a, b), lt(a, b)))
        }
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to `result = (a < b) ? a : b`
        assembly {
            result := sub(a, mul(sub(a, b), gt(a, b)))
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? divUp(a, b) : divDown(a, b);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        _require(b != 0, Errors.ZERO_DIVISION);

        // Equivalent to:
        // result = a == 0 ? 0 : 1 + (a - 1) / b;
        assembly {
            result := mul(iszero(iszero(a)), add(1, div(sub(a, 1), b)))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "CREATE2_INSUFFICIENT_BALANCE");
        require(bytecode.length != 0, "CREATE2_BYTECODE_ZERO");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "CREATE2_DEPLOY_FAILED");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    // solc-ignore-next-line func-mutability
    function _getChainId() private view returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}. The total supply should only be read using this function
     *
     * Can be overridden by derived contracts to store the total supply in a different way (e.g. packed with other
     * storage values).
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Sets a new value for the total supply. It should only be set using this function.
     *
     * * Can be overridden by derived contracts to store the total supply in a different way (e.g. packed with other
     * storage values).
     */
    function _setTotalSupply(uint256 value) internal virtual {
        _totalSupply = value;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE)
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, Errors.ERC20_DECREASED_ALLOWANCE_BELOW_ZERO)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _require(sender != address(0), Errors.ERC20_TRANSFER_FROM_ZERO_ADDRESS);
        _require(recipient != address(0), Errors.ERC20_TRANSFER_TO_ZERO_ADDRESS);

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_BALANCE);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), account, amount);

        _setTotalSupply(totalSupply().add(amount));
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _require(account != address(0), Errors.ERC20_BURN_FROM_ZERO_ADDRESS);

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, Errors.ERC20_BURN_EXCEEDS_BALANCE);
        _setTotalSupply(totalSupply().sub(amount));
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20Permit.sol";

import "./ERC20.sol";
import "../helpers/EOASignaturesValidator.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EOASignaturesValidator {
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, getNextNonce(owner), deadline)
        );

        _ensureValidSignature(owner, structHash, _toArraySignature(v, r, s), deadline, Errors.INVALID_SIGNATURE);

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return getNextNonce(owner);
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return getDomainSeparator();
    }
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce bytecode size.
// Modifier code is inlined by the compiler, which causes its code to appear multiple times in the codebase. By using
// private functions, we achieve the same end result with slightly higher runtime gas costs, but reduced bytecode size.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _enterNonReentrant();
        _;
        _exitNonReentrant();
    }

    function _enterNonReentrant() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        _require(_status != _ENTERED, Errors.REENTRANCY);

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _exitNonReentrant() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // Some contracts need their allowance reduced to 0 before setting it to an arbitrary amount.
        if (value != 0 && token.allowance(address(this), address(to)) != 0) {
            _callOptionalReturn(address(token), abi.encodeWithSelector(token.approve.selector, to, 0));
        }

        _callOptionalReturn(address(token), abi.encodeWithSelector(token.approve.selector, to, value));
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     *
     * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
     */
    function _callOptionalReturn(address token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = token.call(data);

        // If the low-level call didn't succeed we return whatever was returned from it.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
        _require(returndata.length == 0 || abi.decode(returndata, (bool)), Errors.SAFE_ERC20_CALL_FAILED);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, Errors.SUB_OVERFLOW);
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        uint256 errorCode
    ) internal pure returns (uint256) {
        _require(b <= a, errorCode);
        uint256 c = a - b;

        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/pool-linear/IStaticAToken.sol";
import "@balancer-labs/v2-pool-utils/contracts/lib/ExternalCallLib.sol";
import "@balancer-labs/v2-pool-utils/contracts/Version.sol";

import "../LinearPool.sol";

contract AaveLinearPool is LinearPool, Version {
    ILendingPool private immutable _lendingPool;

    struct ConstructorArgs {
        IVault vault;
        string name;
        string symbol;
        IERC20 mainToken;
        IERC20 wrappedToken;
        address assetManager;
        uint256 upperTarget;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
        string version;
    }

    constructor(ConstructorArgs memory args)
        LinearPool(
            args.vault,
            args.name,
            args.symbol,
            args.mainToken,
            args.wrappedToken,
            args.upperTarget,
            _toAssetManagerArray(args),
            args.swapFeePercentage,
            args.pauseWindowDuration,
            args.bufferPeriodDuration,
            args.owner
        )
        Version(args.version)
    {
        _lendingPool = IStaticAToken(address(args.wrappedToken)).LENDING_POOL();
        _require(address(args.mainToken) == IStaticAToken(address(args.wrappedToken)).ASSET(), Errors.TOKENS_MISMATCH);
    }

    function _toAssetManagerArray(ConstructorArgs memory args) private pure returns (address[] memory) {
        // We assign the same asset manager to both the main and wrapped tokens.
        address[] memory assetManagers = new address[](2);
        assetManagers[0] = args.assetManager;
        assetManagers[1] = args.assetManager;

        return assetManagers;
    }

    function _getWrappedTokenRate() internal view override returns (uint256) {
        // This pulls in the implementation of `rate` used in the StaticAToken contract
        // except avoiding storing relevant variables in storage for gas reasons.
        // solhint-disable-next-line max-line-length
        // see: https://github.com/aave/protocol-v2/blob/ac58fea62bb8afee23f66197e8bce6d79ecda292/contracts/protocol/tokenization/StaticATokenLM.sol#L255-L257
        try _lendingPool.getReserveNormalizedIncome(address(getMainToken())) returns (uint256 rate) {
            // This function returns a 18 decimal fixed point number, but `rate` has 27 decimals (i.e. a 'ray' value)
            // so we need to convert it.
            return rate / 10**9;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Aave (or any other contract in the call stack) could trick the Pool into
            // reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerQueries.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/ILastCreatedPoolFactory.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/IPoolVersion.sol";

import "@balancer-labs/v2-pool-utils/contracts/Version.sol";
import "@balancer-labs/v2-pool-utils/contracts/factories/BasePoolFactory.sol";
import "@balancer-labs/v2-pool-utils/contracts/factories/FactoryWidePauseWindow.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Create2.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ReentrancyGuard.sol";

import "./AaveLinearPool.sol";
import "./AaveLinearPoolRebalancer.sol";

contract AaveLinearPoolFactory is
    ILastCreatedPoolFactory,
    IPoolVersion,
    Version,
    BasePoolFactory,
    ReentrancyGuard,
    FactoryWidePauseWindow
{
    // Used for create2 deployments
    uint256 private _nextRebalancerSalt;

    IBalancerQueries private immutable _queries;

    address private _lastCreatedPool;
    string private _poolVersion;

    constructor(
        IVault vault,
        IProtocolFeePercentagesProvider protocolFeeProvider,
        IBalancerQueries queries,
        string memory factoryVersion,
        string memory poolVersion
    ) BasePoolFactory(vault, protocolFeeProvider, type(AaveLinearPool).creationCode) Version(factoryVersion) {
        _queries = queries;
        _poolVersion = poolVersion;
    }

    function getLastCreatedPool() external view override returns (address) {
        return _lastCreatedPool;
    }

    function getPoolVersion() public view override returns (string memory) {
        return _poolVersion;
    }

    function _create(bytes memory constructorArgs) internal virtual override returns (address) {
        address pool = super._create(constructorArgs);
        _lastCreatedPool = pool;

        return pool;
    }

    /**
     * @dev Deploys a new `AaveLinearPool`.
     */
    function create(
        string memory name,
        string memory symbol,
        IERC20 mainToken,
        IERC20 wrappedToken,
        uint256 upperTarget,
        uint256 swapFeePercentage,
        address owner
    ) external nonReentrant returns (AaveLinearPool) {
        // We are going to deploy both an AaveLinearPool and an AaveLinearPoolRebalancer set as its Asset Manager, but
        // this creates a circular dependency problem: the Pool must know the Asset Manager's address in order to call
        // `IVault.registerTokens` with it, and the Asset Manager must know about the Pool in order to store its Pool
        // ID, wrapped and main tokens, etc., as immutable variables.
        // We could forego immutable storage in the Rebalancer and simply have a two-step initialization process that
        // uses storage, but we can keep those gas savings by instead making the deployment a bit more complicated.
        //
        // Note that the Pool does not interact with the Asset Manager: it only needs to know about its address.
        // We therefore use create2 to deploy the Asset Manager, first computing the address where it will be deployed.
        // With that knowledge, we can then create the Pool, and finally the Asset Manager. The only issue with this
        // approach is that create2 requires the full creation code, including constructor arguments, and among those is
        // the Pool's address. To work around this, we have the Rebalancer fetch this address from `getLastCreatedPool`,
        // which will hold the Pool's address after we call `_create`.

        bytes32 rebalancerSalt = bytes32(_nextRebalancerSalt);
        _nextRebalancerSalt += 1;

        bytes memory rebalancerCreationCode = abi.encodePacked(
            type(AaveLinearPoolRebalancer).creationCode,
            abi.encode(getVault(), _queries)
        );
        address expectedRebalancerAddress = Create2.computeAddress(rebalancerSalt, keccak256(rebalancerCreationCode));

        (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) = getPauseConfiguration();

        AaveLinearPool.ConstructorArgs memory args = AaveLinearPool.ConstructorArgs({
            vault: getVault(),
            name: name,
            symbol: symbol,
            mainToken: mainToken,
            wrappedToken: wrappedToken,
            assetManager: expectedRebalancerAddress,
            upperTarget: upperTarget,
            swapFeePercentage: swapFeePercentage,
            pauseWindowDuration: pauseWindowDuration,
            bufferPeriodDuration: bufferPeriodDuration,
            owner: owner,
            version: getPoolVersion()
        });

        AaveLinearPool pool = AaveLinearPool(_create(abi.encode(args)));

        // LinearPools have a separate post-construction initialization step: we perform it here to
        // ensure deployment and initialization are atomic.
        pool.initialize();

        // Not that the Linear Pool's deployment is complete, we can deploy the Rebalancer, verifying that we correctly
        // predicted its deployment address.
        address actualRebalancerAddress = Create2.deploy(0, rebalancerSalt, rebalancerCreationCode);
        require(expectedRebalancerAddress == actualRebalancerAddress, "Rebalancer deployment failed");

        // We don't return the Rebalancer's address, but that can be queried in the Vault by calling `getPoolTokenInfo`.
        return pool;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/pool-linear/IStaticAToken.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/ILastCreatedPoolFactory.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

import "../LinearPoolRebalancer.sol";

contract AaveLinearPoolRebalancer is LinearPoolRebalancer {
    using SafeERC20 for IERC20;

    // These Rebalancers can only be deployed from a factory to work around a circular dependency: the Pool must know
    // the address of the Rebalancer in order to register it, and the Rebalancer must know the address of the Pool
    // during construction.
    constructor(IVault vault, IBalancerQueries queries)
        LinearPoolRebalancer(ILinearPool(ILastCreatedPoolFactory(msg.sender).getLastCreatedPool()), vault, queries)
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _wrapTokens(uint256 amount) internal override {
        // No referral code, depositing from underlying (i.e. DAI, USDC, etc. instead of aDAI or aUSDC). Before we can
        // deposit however, we need to approve the wrapper in the underlying token.
        _mainToken.safeApprove(address(_wrappedToken), amount);
        IStaticAToken(address(_wrappedToken)).deposit(address(this), amount, 0, true);
    }

    function _unwrapTokens(uint256 amount) internal override {
        // Withdrawing into underlying (i.e. DAI, USDC, etc. instead of aDAI or aUSDC). Approvals are not necessary here
        // as the wrapped token is simply burnt.
        IStaticAToken(address(_wrappedToken)).withdraw(address(this), amount, true);
    }

    function _getRequiredTokensToWrap(uint256 wrappedAmount) internal view override returns (uint256) {
        // staticToDynamic returns how many main tokens will be returned when unwrapping. Since there's fixed point
        // divisions and multiplications with rounding involved, this value might be off by one. We add one to ensure
        // the returned value will always be enough to get `wrappedAmount` when unwrapping. This might result in some
        // dust being left in the Rebalancer.
        return IStaticAToken(address(_wrappedToken)).staticToDynamicAmount(wrappedAmount) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

// These functions start with an underscore, as if they were part of a contract and not a library. At some point this
// should be fixed.
// solhint-disable private-vars-leading-underscore

library LinearMath {
    using FixedPoint for uint256;

    // A thorough derivation of the formulas and derivations found here exceeds the scope of this file, so only
    // introductory notions will be presented.

    // A Linear Pool holds three tokens: the main token, the wrapped token, and the Pool share token (BPT). It is
    // possible to exchange any of these tokens for any of the other two (so we have three trading pairs) in both
    // directions (the first token of each pair can be bought or sold for the second) and by specifying either the input
    // or output amount (typically referred to as 'given in' or 'given out'). A full description thus requires
    // 3*2*2 = 12 functions.
    // Wrapped tokens have a known, trusted exchange rate to main tokens. All functions here assume such a rate has
    // already been applied, meaning main and wrapped balances can be compared as they are both expressed in the same
    // units (those of main token).
    // Additionally, Linear Pools feature a lower and upper target that represent the desired range of values for the
    // main token balance. Any action that moves the main balance away from this range is charged a proportional fee,
    // and any action that moves it towards this range is incentivized by paying the actor using these collected fees.
    // The collected fees are not stored in a separate data structure: they are a function of the current main balance,
    // targets and fee percentage. The main balance sans fees is known as the 'nominal balance', which is always smaller
    // than the real balance except when the real balance is within the targets.
    // The rule under which Linear Pools conduct trades between main and wrapped tokens is by keeping the sum of nominal
    // main balance and wrapped balance constant: this value is known as the 'invariant'. BPT is backed by nominal
    // reserves, meaning its supply is proportional to the invariant. As the wrapped token appreciates in value and its
    // exchange rate to the main token increases, so does the invariant and thus the value of BPT (in main token units).

    struct Params {
        uint256 fee;
        uint256 lowerTarget;
        uint256 upperTarget;
    }

    function _calcBptOutPerMainIn(
        uint256 mainIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        if (bptSupply == 0) {
            // BPT typically grows in the same ratio the invariant does. The first time liquidity is added however, the
            // BPT supply is initialized to equal the invariant (which in this case is just the nominal main balance as
            // there is no wrapped balance).
            return _toNominal(mainIn, params);
        }

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.add(mainIn), params);
        uint256 deltaNominalMain = afterNominalMain.sub(previousNominalMain);
        uint256 invariant = _calcInvariant(previousNominalMain, wrappedBalance);
        return Math.divDown(Math.mul(bptSupply, deltaNominalMain), invariant);
    }

    function _calcBptInPerMainOut(
        uint256 mainOut,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.sub(mainOut), params);
        uint256 deltaNominalMain = previousNominalMain.sub(afterNominalMain);
        uint256 invariant = _calcInvariant(previousNominalMain, wrappedBalance);
        return Math.divUp(Math.mul(bptSupply, deltaNominalMain), invariant);
    }

    function _calcWrappedOutPerMainIn(
        uint256 mainIn,
        uint256 mainBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.add(mainIn), params);
        return afterNominalMain.sub(previousNominalMain);
    }

    function _calcWrappedInPerMainOut(
        uint256 mainOut,
        uint256 mainBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.sub(mainOut), params);
        return previousNominalMain.sub(afterNominalMain);
    }

    function _calcMainInPerBptOut(
        uint256 bptOut,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        if (bptSupply == 0) {
            // BPT typically grows in the same ratio the invariant does. The first time liquidity is added however, the
            // BPT supply is initialized to equal the invariant (which in this case is just the nominal main balance as
            // there is no wrapped balance).
            return _fromNominal(bptOut, params);
        }

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 invariant = _calcInvariant(previousNominalMain, wrappedBalance);
        uint256 deltaNominalMain = Math.divUp(Math.mul(invariant, bptOut), bptSupply);
        uint256 afterNominalMain = previousNominalMain.add(deltaNominalMain);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return newMainBalance.sub(mainBalance);
    }

    function _calcMainOutPerBptIn(
        uint256 bptIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 invariant = _calcInvariant(previousNominalMain, wrappedBalance);
        uint256 deltaNominalMain = Math.divDown(Math.mul(invariant, bptIn), bptSupply);
        uint256 afterNominalMain = previousNominalMain.sub(deltaNominalMain);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return mainBalance.sub(newMainBalance);
    }

    function _calcMainOutPerWrappedIn(
        uint256 wrappedIn,
        uint256 mainBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = previousNominalMain.sub(wrappedIn);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return mainBalance.sub(newMainBalance);
    }

    function _calcMainInPerWrappedOut(
        uint256 wrappedOut,
        uint256 mainBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = previousNominalMain.add(wrappedOut);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return newMainBalance.sub(mainBalance);
    }

    function _calcBptOutPerWrappedIn(
        uint256 wrappedIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        if (bptSupply == 0) {
            // BPT typically grows in the same ratio the invariant does. The first time liquidity is added however, the
            // BPT supply is initialized to equal the invariant (which in this case is just the wrapped balance as
            // there is no main balance).
            return wrappedIn;
        }

        uint256 nominalMain = _toNominal(mainBalance, params);
        uint256 previousInvariant = _calcInvariant(nominalMain, wrappedBalance);

        uint256 newWrappedBalance = wrappedBalance.add(wrappedIn);
        uint256 newInvariant = _calcInvariant(nominalMain, newWrappedBalance);

        uint256 newBptBalance = Math.divDown(Math.mul(bptSupply, newInvariant), previousInvariant);

        return newBptBalance.sub(bptSupply);
    }

    function _calcBptInPerWrappedOut(
        uint256 wrappedOut,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        uint256 nominalMain = _toNominal(mainBalance, params);
        uint256 previousInvariant = _calcInvariant(nominalMain, wrappedBalance);

        uint256 newWrappedBalance = wrappedBalance.sub(wrappedOut);
        uint256 newInvariant = _calcInvariant(nominalMain, newWrappedBalance);

        uint256 newBptBalance = Math.divDown(Math.mul(bptSupply, newInvariant), previousInvariant);

        return bptSupply.sub(newBptBalance);
    }

    function _calcWrappedInPerBptOut(
        uint256 bptOut,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        if (bptSupply == 0) {
            // BPT typically grows in the same ratio the invariant does. The first time liquidity is added however, the
            // BPT supply is initialized to equal the invariant (which in this case is just the wrapped balance as
            // there is no main balance).
            return bptOut;
        }

        uint256 nominalMain = _toNominal(mainBalance, params);
        uint256 previousInvariant = _calcInvariant(nominalMain, wrappedBalance);

        uint256 newBptBalance = bptSupply.add(bptOut);
        uint256 newWrappedBalance = Math.divUp(Math.mul(newBptBalance, previousInvariant), bptSupply).sub(nominalMain);

        return newWrappedBalance.sub(wrappedBalance);
    }

    function _calcWrappedOutPerBptIn(
        uint256 bptIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 nominalMain = _toNominal(mainBalance, params);
        uint256 previousInvariant = _calcInvariant(nominalMain, wrappedBalance);

        uint256 newBptBalance = bptSupply.sub(bptIn);
        uint256 newWrappedBalance = Math.divUp(Math.mul(newBptBalance, previousInvariant), bptSupply).sub(nominalMain);

        return wrappedBalance.sub(newWrappedBalance);
    }

    function _calcInvariant(uint256 nominalMainBalance, uint256 wrappedBalance) internal pure returns (uint256) {
        return nominalMainBalance.add(wrappedBalance);
    }

    function _toNominal(uint256 real, Params memory params) internal pure returns (uint256) {
        // Fees are always rounded down: either direction would work but we need to be consistent, and rounding down
        // uses less gas.

        if (real < params.lowerTarget) {
            uint256 fees = (params.lowerTarget - real).mulDown(params.fee);
            return real.sub(fees);
        } else if (real <= params.upperTarget) {
            return real;
        } else {
            uint256 fees = (real - params.upperTarget).mulDown(params.fee);
            return real.sub(fees);
        }
    }

    function _fromNominal(uint256 nominal, Params memory params) internal pure returns (uint256) {
        // Since real = nominal + fees, rounding down fees is equivalent to rounding down real.

        if (nominal < params.lowerTarget) {
            return (nominal.add(params.fee.mulDown(params.lowerTarget))).divDown(FixedPoint.ONE.add(params.fee));
        } else if (nominal <= params.upperTarget) {
            return nominal;
        } else {
            return (nominal.sub(params.fee.mulDown(params.upperTarget)).divDown(FixedPoint.ONE.sub(params.fee)));
        }
    }

    function _calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 bptIndex
    ) internal pure returns (uint256[] memory) {
        /**********************************************************************************************
        // exactBPTInForTokensOut                                                                    //
        // (per token)                                                                               //
        // aO = tokenAmountOut             /        bptIn         \                                  //
        // b = tokenBalance      a0 = b * | ---------------------  |                                 //
        // bptIn = bptAmountIn             \     bptTotalSupply    /                                 //
        // bpt = bptTotalSupply                                                                      //
        **********************************************************************************************/

        // Since we're computing an amount out, we round down overall. This means rounding down on both the
        // multiplication and division.

        uint256 bptRatio = bptAmountIn.divDown(bptTotalSupply);

        uint256[] memory amountsOut = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            // BPT is skipped as those tokens are not the LPs, but rather the preminted and undistributed amount.
            if (i != bptIndex) {
                amountsOut[i] = balances[i].mulDown(bptRatio);
            }
        }

        return amountsOut;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/BasePoolUserData.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/IRateProvider.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-linear/ILinearPool.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IGeneralPool.sol";

import "@balancer-labs/v2-pool-utils/contracts/NewBasePool.sol";
import "@balancer-labs/v2-pool-utils/contracts/rates/PriceRateCache.sol";
import "@balancer-labs/v2-pool-utils/contracts/lib/PoolRegistrationLib.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/ERC20Helpers.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/ScalingHelpers.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";

import "./LinearMath.sol";

/**
 * @dev Linear Pools are designed to hold two assets: "main" and "wrapped" tokens that have an equal value underlying
 * token (e.g., DAI and waDAI). There must be an external feed available to provide an exact, non-manipulable exchange
 * rate between the tokens. In particular, any reversible manipulation (e.g. causing the rate to increase and then
 * decrease) can lead to severe issues and loss of funds.
 *
 * The Pool will register three tokens in the Vault however: the two assets and the BPT itself,
 * so that BPT can be exchanged (effectively joining and exiting) via swaps.
 *
 * Despite inheriting from BasePool, much of the basic behavior changes. This Pool does not support regular joins
 * and exits, as the initial BPT supply is 'preminted' during initialization. No further BPT can be minted, and BPT can
 * only be burned if governance enables Recovery Mode and LPs use it to exit proportionally.
 *
 * Unlike most other Pools, this one does not attempt to create revenue by charging fees: value is derived by holding
 * the wrapped, yield-bearing asset. However, the 'swap fee percentage' value is still used, albeit with a different
 * meaning. This Pool attempts to hold a certain amount of "main" tokens, between a lower and upper target value.
 * The pool charges fees on trades that move the balance outside that range, which are then paid back as incentives to
 * traders whose swaps return the balance to the desired region.
 *
 * The net revenue via fees is expected to be zero: all collected fees are used to pay for this 'rebalancing'.
 * Accordingly, this Pool does not pay any protocol fees.
 */
abstract contract LinearPool is ILinearPool, IGeneralPool, IRateProvider, NewBasePool {
    using WordCodec for bytes32;
    using FixedPoint for uint256;
    using PriceRateCache for bytes32;
    using BasePoolUserData for bytes;

    uint256 private constant _TOTAL_TOKENS = 3; // Main token, wrapped token, BPT

    // This is the maximum token amount the Vault can hold. In regular operation, the total BPT supply remains constant
    // and equal to _INITIAL_BPT_SUPPLY, but most of it remains in the Pool, waiting to be exchanged for tokens. The
    // actual amount of BPT in circulation is the total supply minus the amount held by the Pool, and is known as the
    // 'virtual supply'.
    // The total supply can only change if recovery mode is enabled and recovery mode exits are processed, resulting in
    // BPT being burned. This BPT can never be minted again, so it is technically possible for the preminted supply to
    // run out, but a) this process is controlled by Governance via enabling and disabling recovery mode, and b) the
    // initial supply is so large that it would take a huge number of interactions to acquire sufficient tokens to join
    // the Pool, and then burn the acquired BPT, resulting in prohibitively large gas costs.
    uint256 private constant _INITIAL_BPT_SUPPLY = 2**(112) - 1;

    // 1e18 corresponds to 1.0, or a 100% fee
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 1e17; // 10%

    IERC20 private immutable _mainToken;
    IERC20 private immutable _wrappedToken;

    // The indices of each token when registered, which can then be used to access the balances array.
    uint256 private immutable _mainIndex;
    uint256 private immutable _wrappedIndex;

    // Both BPT and the main token have a regular, constant scaling factor (equal to FixedPoint.ONE for BPT, and
    // dependent on the number of decimals for the main token). However, the wrapped token's scaling factor has two
    // components: the usual token decimal scaling factor, and an externally provided rate used to convert wrapped
    // tokens to an equivalent main token amount. This external rate is expected to be ever increasing, reflecting the
    // fact that the wrapped token appreciates in value over time (e.g. because it is accruing interest).
    uint256 private immutable _scalingFactorMainToken;
    uint256 private immutable _scalingFactorWrappedToken;

    // The lower and upper targets are stored in the pool state field, along with the swap fee percentage and recovery
    // mode flag, which together take up 64 bits).
    bytes32 private _poolState;

    // The targets are already scaled by the main token's scaling factor (which makes the token behave as if it had 18
    // decimals), but we only store the integer part: the targets must be multiplied by 1e18 before being used.
    // This means the targets' resolution does not include decimal places in the main token (so e.g. a target of 500.1
    // DAI is impossible). Since targets are expected to be relatively large, this is a non-issue. With 32 bits per
    // target, we can represent values as high as ~4 billion (2^32).
    // [   1 bit  |  63 bits  |    32 bits   |    32 bits    | 128 bits ]
    // [ recovery | swap  fee | upper target |  lower target | reserved ]
    // [ MSB                                                        LSB ]

    uint256 private constant _TARGET_SCALING = 1e18;

    uint256 private constant _TARGET_BITS = 32;

    uint256 private constant _LOWER_TARGET_OFFSET = 32;
    uint256 private constant _UPPER_TARGET_OFFSET = 64;
    uint256 private constant _SWAP_FEE_PERCENTAGE_OFFSET = 192;
    uint256 private constant _RECOVERY_MODE_BIT_OFFSET = 255;

    // A fee can never be larger than FixedPoint.ONE, which fits in 60 bits, so 63 is more than enough.
    uint256 private constant _SWAP_FEE_PERCENTAGE_BIT_LENGTH = 63;

    uint256 private constant _MAX_UPPER_TARGET = (2**(32) - 1) * _TARGET_SCALING;

    // Composable Pool registration will put the BPT at index 0, with the main/wrapped following in sorted order.
    uint256 private constant _BPT_INDEX = 0;

    event SwapFeePercentageChanged(uint256 swapFeePercentage);
    event TargetsSet(IERC20 indexed token, uint256 lowerTarget, uint256 upperTarget);

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20 mainToken,
        IERC20 wrappedToken,
        uint256 upperTarget,
        address[] memory assetManagers,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        NewBasePool(
            vault,
            PoolRegistrationLib.registerComposablePool(
                vault,
                IVault.PoolSpecialization.GENERAL,
                _sortTokens(mainToken, wrappedToken),
                assetManagers
            ),
            name,
            symbol,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
        // Set tokens
        _mainToken = mainToken;
        _wrappedToken = wrappedToken;

        // Set token indexes. BPT is always 0; other tokens follow in sorted order.
        _mainIndex = mainToken < wrappedToken ? 1 : 2;
        _wrappedIndex = mainToken < wrappedToken ? 2 : 1;

        // Set scaling factors
        _scalingFactorMainToken = _computeScalingFactor(mainToken);
        _scalingFactorWrappedToken = _computeScalingFactor(wrappedToken);

        // Set initial targets. The lower target must be set to zero because initially there are no accumulated fees.
        // Otherwise the pool would owe fees from the start, which would make the rate manipulable.
        uint256 lowerTarget = 0;
        _setTargets(mainToken, lowerTarget, upperTarget);

        // Set the initial swap fee percentage.
        _setSwapFeePercentage(swapFeePercentage);
    }

    /**
     * @notice Return the main token address as an IERC20.
     */
    function getMainToken() public view override returns (IERC20) {
        return _mainToken;
    }

    /**
     * @notice Return the wrapped token address as an IERC20.
     */
    function getWrappedToken() public view override returns (IERC20) {
        return _wrappedToken;
    }

    /**
     * @notice Return the index of the BPT token.
     * @dev Note that this is an index into the registered token list (with 3 tokens).
     */
    function getBptIndex() public pure override returns (uint256) {
        return _BPT_INDEX;
    }

    /**
     * @notice Return the index of the main token.
     * @dev Note that this is an index into the registered token list, which includes the BPT token.
     */
    function getMainIndex() external view override returns (uint256) {
        return _mainIndex;
    }

    /**
     * @notice Return the index of the wrapped token.
     * @dev Note that this is an index into the registered token list, which includes the BPT token.
     */
    function getWrappedIndex() external view override returns (uint256) {
        return _wrappedIndex;
    }

    /**
     * @dev Finishes initialization of the Linear Pool: it is unusable before calling this function as no BPT will
     * have been minted.
     *
     * Since Linear Pools have preminted BPT stored in the Vault, they require an initial join to deposit said BPT as
     * their balance. Unfortunately, this cannot be performed during construction, as a join involves calling the
     * `onJoinPool` function on the Pool, and the Pool will not have any code until construction finishes. Therefore,
     * this must happen in a separate call.
     *
     * It is highly recommended to create Linear pools using the LinearPoolFactory, which calls `initialize`
     * automatically.
     */
    function initialize() external {
        bytes32 poolId = getPoolId();
        (IERC20[] memory tokens, , ) = getVault().getPoolTokens(poolId);

        // Joins typically involve the Pool receiving tokens in exchange for newly-minted BPT. In this case however, the
        // Pool will mint the entire BPT supply to itself, and join itself with it.
        uint256[] memory maxAmountsIn = new uint256[](_TOTAL_TOKENS);
        maxAmountsIn[_BPT_INDEX] = _INITIAL_BPT_SUPPLY;

        // The first time this executes, it will call `_onInitializePool` (as the BPT supply will be zero). Future calls
        // will be routed to `_onJoinPool`, which always reverts, meaning `initialize` will only execute once.
        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: _asIAsset(tokens),
            maxAmountsIn: maxAmountsIn,
            userData: "",
            fromInternalBalance: false
        });

        getVault().joinPool(poolId, address(this), address(this), request);
    }

    /**
     * @dev Implement the BasePool hook for a general swap (see `IGeneralPool`).
     */
    function _onSwapGeneral(
        SwapRequest memory request,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal view override returns (uint256) {
        // In most Pools, swaps involve exchanging one token held by the Pool for another. In this case however, since
        // one of the three tokens is the BPT itself, a swap might also be a join (main/wrapped for BPT) or an exit
        // (BPT for main/wrapped).
        // All three swap types (swaps, joins and exits) are fully disabled if the emergency pause is enabled. Under
        // these circumstances, the Pool can only be exited using Recovery Mode, if it is enabled.

        // Sanity check: this is not entirely necessary as the Vault's interface enforces the indices to be valid, but
        // the check is cheap to perform.
        _require(indexIn < _TOTAL_TOKENS && indexOut < _TOTAL_TOKENS, Errors.OUT_OF_BOUNDS);

        // Note that we already know the indices of the main token, wrapped token and BPT, so there is no need to pass
        // these indices to the inner functions.

        // Upscale balances by the scaling factors (taking into account the wrapped token rate)
        uint256[] memory scalingFactors = getScalingFactors();
        _upscaleArray(balances, scalingFactors);

        (uint256 lowerTarget, uint256 upperTarget) = getTargets();
        LinearMath.Params memory params = LinearMath.Params({
            fee: getSwapFeePercentage(),
            lowerTarget: lowerTarget,
            upperTarget: upperTarget
        });

        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // The amount given is for token in, the amount calculated is for token out
            request.amount = _upscale(request.amount, scalingFactors[indexIn]);
            uint256 amountOut = _onSwapGivenIn(request, balances, params);

            // amountOut tokens are exiting the Pool, so we round down.
            return _downscaleDown(amountOut, scalingFactors[indexOut]);
        } else {
            // The amount given is for token out, the amount calculated is for token in
            request.amount = _upscale(request.amount, scalingFactors[indexOut]);
            uint256 amountIn = _onSwapGivenOut(request, balances, params);

            // amountIn tokens are entering the Pool, so we round up.
            return _downscaleUp(amountIn, scalingFactors[indexIn]);
        }
    }

    function _onSwapGivenIn(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        if (request.tokenIn == this) {
            return _swapGivenBptIn(request, balances, params);
        } else if (request.tokenIn == _mainToken) {
            return _swapGivenMainIn(request, balances, params);
        } else if (request.tokenIn == _wrappedToken) {
            return _swapGivenWrappedIn(request, balances, params);
        } else {
            _revert(Errors.INVALID_TOKEN);
        }
    }

    function _swapGivenBptIn(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        _require(request.tokenOut == _mainToken || request.tokenOut == _wrappedToken, Errors.INVALID_TOKEN);
        return
            (request.tokenOut == _mainToken ? LinearMath._calcMainOutPerBptIn : LinearMath._calcWrappedOutPerBptIn)(
                request.amount,
                balances[_mainIndex],
                balances[_wrappedIndex],
                _getVirtualSupply(balances[_BPT_INDEX]),
                params
            );
    }

    function _swapGivenMainIn(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        _require(request.tokenOut == _wrappedToken || request.tokenOut == this, Errors.INVALID_TOKEN);
        return
            request.tokenOut == this
                ? LinearMath._calcBptOutPerMainIn(
                    request.amount,
                    balances[_mainIndex],
                    balances[_wrappedIndex],
                    _getVirtualSupply(balances[_BPT_INDEX]),
                    params
                )
                : LinearMath._calcWrappedOutPerMainIn(request.amount, balances[_mainIndex], params);
    }

    function _swapGivenWrappedIn(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        _require(request.tokenOut == _mainToken || request.tokenOut == this, Errors.INVALID_TOKEN);
        return
            request.tokenOut == this
                ? LinearMath._calcBptOutPerWrappedIn(
                    request.amount,
                    balances[_mainIndex],
                    balances[_wrappedIndex],
                    _getVirtualSupply(balances[_BPT_INDEX]),
                    params
                )
                : LinearMath._calcMainOutPerWrappedIn(request.amount, balances[_mainIndex], params);
    }

    function _onSwapGivenOut(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        if (request.tokenOut == this) {
            return _swapGivenBptOut(request, balances, params);
        } else if (request.tokenOut == _mainToken) {
            return _swapGivenMainOut(request, balances, params);
        } else if (request.tokenOut == _wrappedToken) {
            return _swapGivenWrappedOut(request, balances, params);
        } else {
            _revert(Errors.INVALID_TOKEN);
        }
    }

    function _swapGivenBptOut(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        _require(request.tokenIn == _mainToken || request.tokenIn == _wrappedToken, Errors.INVALID_TOKEN);
        return
            (request.tokenIn == _mainToken ? LinearMath._calcMainInPerBptOut : LinearMath._calcWrappedInPerBptOut)(
                request.amount,
                balances[_mainIndex],
                balances[_wrappedIndex],
                _getVirtualSupply(balances[_BPT_INDEX]),
                params
            );
    }

    function _swapGivenMainOut(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        _require(request.tokenIn == _wrappedToken || request.tokenIn == this, Errors.INVALID_TOKEN);
        return
            request.tokenIn == this
                ? LinearMath._calcBptInPerMainOut(
                    request.amount,
                    balances[_mainIndex],
                    balances[_wrappedIndex],
                    _getVirtualSupply(balances[_BPT_INDEX]),
                    params
                )
                : LinearMath._calcWrappedInPerMainOut(request.amount, balances[_mainIndex], params);
    }

    function _swapGivenWrappedOut(
        SwapRequest memory request,
        uint256[] memory balances,
        LinearMath.Params memory params
    ) internal view returns (uint256) {
        _require(request.tokenIn == _mainToken || request.tokenIn == this, Errors.INVALID_TOKEN);
        return
            request.tokenIn == this
                ? LinearMath._calcBptInPerWrappedOut(
                    request.amount,
                    balances[_mainIndex],
                    balances[_wrappedIndex],
                    _getVirtualSupply(balances[_BPT_INDEX]),
                    params
                )
                : LinearMath._calcMainInPerWrappedOut(request.amount, balances[_mainIndex], params);
    }

    function _onInitializePool(
        address sender,
        address recipient,
        bytes memory
    ) internal view override returns (uint256, uint256[] memory) {
        // Linear Pools can only be initialized by the Pool performing the initial join via the `initialize` function.
        _require(sender == address(this), Errors.INVALID_INITIALIZATION);
        _require(recipient == address(this), Errors.INVALID_INITIALIZATION);

        // The full BPT supply will be minted and deposited in the Pool. Note that there is no need to approve the Vault
        // as it already has infinite BPT allowance.
        uint256 bptAmountOut = _INITIAL_BPT_SUPPLY;

        uint256[] memory amountsIn = new uint256[](_TOTAL_TOKENS);
        amountsIn[_BPT_INDEX] = _INITIAL_BPT_SUPPLY;

        return (bptAmountOut, amountsIn);
    }

    function _onSwapMinimal(
        SwapRequest memory,
        uint256,
        uint256
    ) internal pure override returns (uint256) {
        _revert(Errors.UNIMPLEMENTED);
    }

    function _onJoinPool(
        address,
        uint256[] memory,
        bytes memory
    ) internal pure override returns (uint256, uint256[] memory) {
        _revert(Errors.UNIMPLEMENTED);
    }

    function _onExitPool(
        address,
        uint256[] memory,
        bytes memory
    ) internal pure override returns (uint256, uint256[] memory) {
        _revert(Errors.UNIMPLEMENTED);
    }

    function _doRecoveryModeExit(
        uint256[] memory registeredBalances,
        uint256,
        bytes memory userData
    ) internal view override returns (uint256, uint256[] memory) {
        uint256 bptAmountIn = userData.recoveryModeExit();
        uint256[] memory amountsOut = new uint256[](registeredBalances.length);

        uint256 bptIndex = getBptIndex();

        uint256 virtualSupply = _getVirtualSupply(registeredBalances[bptIndex]);
        uint256 bptRatio = bptAmountIn.divDown(virtualSupply);

        for (uint256 i = 0; i < registeredBalances.length; i++) {
            amountsOut[i] = i != bptIndex ? registeredBalances[i].mulDown(bptRatio) : 0;
        }

        return (bptAmountIn, amountsOut);
    }

    function _getMinimumBpt() internal pure override returns (uint256) {
        // Linear Pools don't lock any BPT, as the total supply will already be forever non-zero due to the preminting
        // mechanism, ensuring initialization only occurs once.
        return 0;
    }

    // Scaling factors

    function _scalingFactor(IERC20 token) internal view virtual returns (uint256) {
        if (token == _mainToken) {
            return _scalingFactorMainToken;
        } else if (token == _wrappedToken) {
            // The wrapped token's scaling factor is not constant, but increases over time as the wrapped token
            // increases in value.
            return _scalingFactorWrappedToken.mulDown(_getWrappedTokenRate());
        } else if (token == this) {
            return FixedPoint.ONE;
        } else {
            _revert(Errors.INVALID_TOKEN);
        }
    }

    /**
     * @notice Return the scaling factors for all tokens, including the BPT.
     */
    function getScalingFactors() public view virtual override returns (uint256[] memory) {
        uint256[] memory scalingFactors = new uint256[](_TOTAL_TOKENS);

        // The wrapped token's scaling factor is not constant, but increases over time as the wrapped token increases in
        // value.
        scalingFactors[_mainIndex] = _scalingFactorMainToken;
        scalingFactors[_wrappedIndex] = _scalingFactorWrappedToken.mulDown(_getWrappedTokenRate());
        scalingFactors[_BPT_INDEX] = FixedPoint.ONE;

        return scalingFactors;
    }

    // Price rates

    /**
     * @dev For a Linear Pool, the rate represents the appreciation of BPT with respect to the underlying tokens. This
     * rate increases slowly as the wrapped token appreciates in value.
     */
    function getRate() external view override returns (uint256) {
        bytes32 poolId = getPoolId();
        (, uint256[] memory balances, ) = getVault().getPoolTokens(poolId);
        _upscaleArray(balances, getScalingFactors());

        (uint256 lowerTarget, uint256 upperTarget) = getTargets();
        LinearMath.Params memory params = LinearMath.Params({
            fee: getSwapFeePercentage(),
            lowerTarget: lowerTarget,
            upperTarget: upperTarget
        });

        uint256 totalBalance = LinearMath._calcInvariant(
            LinearMath._toNominal(balances[_mainIndex], params),
            balances[_wrappedIndex]
        );

        // Note that we're dividing by the virtual supply, which may be zero (causing this call to revert). However, the
        // only way for that to happen would be for all LPs to exit the Pool, and nothing prevents new LPs from
        // joining it later on.
        return totalBalance.divUp(_getVirtualSupply(balances[_BPT_INDEX]));
    }

    /**
     * @notice Return the conversion rate between the wrapped and main tokens.
     * @dev This is an 18-decimal fixed point value.
     */
    function getWrappedTokenRate() external view returns (uint256) {
        return _getWrappedTokenRate();
    }

    /**
     * @dev Should be an 18-decimal fixed point value that represents the value of the wrapped token in terms of the
     * main token. The final wrapped token scaling factor is this value multiplied by the wrapped token's decimal
     * scaling factor.
     */
    function _getWrappedTokenRate() internal view virtual returns (uint256);

    // Targets

    /**
     * @notice Return the lower and upper bounds of the zero-fee trading range for the main token balance.
     */
    function getTargets() public view override returns (uint256 lowerTarget, uint256 upperTarget) {
        bytes32 poolState = _poolState;

        // Since targets are stored downscaled by _TARGET_SCALING, we undo that when reading them.
        lowerTarget = poolState.decodeUint(_LOWER_TARGET_OFFSET, _TARGET_BITS) * _TARGET_SCALING;
        upperTarget = poolState.decodeUint(_UPPER_TARGET_OFFSET, _TARGET_BITS) * _TARGET_SCALING;
    }

    /**
     * @notice Set the lower and upper bounds of the zero-fee trading range for the main token balance.
     * @dev For a new target range to be valid:
     *      - the current balance must be between the current targets (meaning no fees are currently pending)
     *      - the current balance must be between the new targets (meaning setting them does not create pending fees)
     *
     * The first requirement could be relaxed, as the LPs actually benefit from the pending fees not being paid out,
     * but being stricter makes analysis easier at little expense.
     */
    function setTargets(uint256 newLowerTarget, uint256 newUpperTarget) external authenticate {
        (uint256 currentLowerTarget, uint256 currentUpperTarget) = getTargets();
        _require(_isMainBalanceWithinTargets(currentLowerTarget, currentUpperTarget), Errors.OUT_OF_TARGET_RANGE);
        _require(_isMainBalanceWithinTargets(newLowerTarget, newUpperTarget), Errors.OUT_OF_NEW_TARGET_RANGE);

        _setTargets(_mainToken, newLowerTarget, newUpperTarget);
    }

    function _setTargets(
        IERC20 mainToken,
        uint256 lowerTarget,
        uint256 upperTarget
    ) private {
        _require(lowerTarget <= upperTarget, Errors.LOWER_GREATER_THAN_UPPER_TARGET);
        _require(upperTarget <= _MAX_UPPER_TARGET, Errors.UPPER_TARGET_TOO_HIGH);

        // Targets are stored downscaled by _TARGET_SCALING to make them fit in _TARGET_BITS at the cost of some
        // resolution. We check that said resolution is not being used before downscaling.

        _require(upperTarget % _TARGET_SCALING == 0, Errors.FRACTIONAL_TARGET);
        _require(lowerTarget % _TARGET_SCALING == 0, Errors.FRACTIONAL_TARGET);

        _poolState = _poolState
            .insertUint(lowerTarget / _TARGET_SCALING, _LOWER_TARGET_OFFSET, _TARGET_BITS)
            .insertUint(upperTarget / _TARGET_SCALING, _UPPER_TARGET_OFFSET, _TARGET_BITS);

        emit TargetsSet(mainToken, lowerTarget, upperTarget);
    }

    function _isMainBalanceWithinTargets(uint256 lowerTarget, uint256 upperTarget) private view returns (bool) {
        (uint256 cash, uint256 managed, , ) = getVault().getPoolTokenInfo(getPoolId(), _mainToken);

        uint256 mainTokenBalance = _upscale(cash + managed, _scalingFactor(_mainToken));

        return mainTokenBalance >= lowerTarget && mainTokenBalance <= upperTarget;
    }

    // Swap Fees

    /**
     * @notice Return the current value of the swap fee percentage.
     * @dev This is stored in `_poolState`.
     */
    function getSwapFeePercentage() public view virtual override returns (uint256) {
        return _poolState.decodeUint(_SWAP_FEE_PERCENTAGE_OFFSET, _SWAP_FEE_PERCENTAGE_BIT_LENGTH);
    }

    /**
     * @notice Set the swap fee percentage.
     * @dev This is a permissioned function.
     */
    function setSwapFeePercentage(uint256 swapFeePercentage) external authenticate {
        // For the swap fee percentage to be changeable:
        //  - the pool must currently be between the current targets (meaning no fees are currently pending)
        //
        // As the amount of accrued fees is not explicitly stored but rather derived from the main token balance and the
        // current swap fee percentage, requiring for no fees to be pending prevents the fee setter from changing the
        // amount of pending fees, which they could use to e.g. drain Pool funds in the form of inflated fees.

        (uint256 lowerTarget, uint256 upperTarget) = getTargets();
        _require(_isMainBalanceWithinTargets(lowerTarget, upperTarget), Errors.OUT_OF_TARGET_RANGE);

        _setSwapFeePercentage(swapFeePercentage);
    }

    /**
     * @dev Validate the swap fee, update storage, and emit an event.
     */
    function _setSwapFeePercentage(uint256 swapFeePercentage) internal {
        _require(swapFeePercentage >= _MIN_SWAP_FEE_PERCENTAGE, Errors.MIN_SWAP_FEE_PERCENTAGE);
        _require(swapFeePercentage <= _MAX_SWAP_FEE_PERCENTAGE, Errors.MAX_SWAP_FEE_PERCENTAGE);

        _poolState = _poolState.insertUint(
            swapFeePercentage,
            _SWAP_FEE_PERCENTAGE_OFFSET,
            _SWAP_FEE_PERCENTAGE_BIT_LENGTH
        );

        emit SwapFeePercentageChanged(swapFeePercentage);
    }

    // Virtual Supply

    /**
     * @notice Returns the number of tokens in circulation.
     *
     * @dev In other pools, this would be the same as `totalSupply`, but since this pool pre-mints BPT and holds it in
     * the Vault as a token, we need to subtract the Vault's balance to get the total "circulating supply". Both the
     * totalSupply and Vault balance can change. If users join or exit using swaps, some of the preminted BPT are
     * exchanged, so the Vault's balance increases after joins and decreases after exits. If users call the recovery
     * mode exit function, the totalSupply can change as BPT are burned.
     */
    function getVirtualSupply() external view returns (uint256) {
        // For a 3 token General Pool, it is cheaper to query the balance for a single token than to read all balances,
        // as getPoolTokenInfo will check for token existence, token balance and Asset Manager (3 reads), while
        // getPoolTokens will read the number of tokens, their addresses and balances (7 reads).
        (uint256 cash, uint256 managed, , ) = getVault().getPoolTokenInfo(getPoolId(), IERC20(this));

        // Note that unlike all other balances, the Vault's BPT balance does not need scaling as its scaling factor is
        // ONE. This addition cannot overflow due to the Vault's balance limits.
        return _getVirtualSupply(cash + managed);
    }

    // The initial amount of BPT pre-minted is _PREMINTED_TOKEN_BALANCE, and it goes entirely to the pool balance in the
    // vault. So the virtualSupply (the actual supply in circulation) is defined as:
    // virtualSupply = totalSupply() - _balances[_bptIndex]
    function _getVirtualSupply(uint256 bptBalance) internal view returns (uint256) {
        return totalSupply().sub(bptBalance);
    }

    // Recovery Mode

    /**
     * @notice Returns whether the pool is in Recovery Mode.
     */
    function inRecoveryMode() public view override returns (bool) {
        return _poolState.decodeBool(_RECOVERY_MODE_BIT_OFFSET);
    }

    /**
     * @dev Sets the recoveryMode state, and emits the corresponding event.
     */
    function _setRecoveryMode(bool enabled) internal virtual override {
        _poolState = _poolState.insertBool(enabled, _RECOVERY_MODE_BIT_OFFSET);

        emit RecoveryModeStateChanged(enabled);
    }

    // Misc

    /**
     * @dev Enumerates all ownerOnly functions in Linear Pool.
     */
    function _isOwnerOnlyAction(bytes32 actionId) internal view virtual override returns (bool) {
        return
            actionId == getActionId(this.setTargets.selector) ||
            actionId == getActionId(this.setSwapFeePercentage.selector);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerQueries.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-linear/ILinearPool.sol";

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

abstract contract LinearPoolRebalancer {
    using SafeERC20 for IERC20;

    ILinearPool internal immutable _pool;
    bytes32 internal immutable _poolId;

    IERC20 internal immutable _mainToken;
    IERC20 internal immutable _wrappedToken;

    uint256 internal immutable _mainTokenScalingFactor;

    IVault internal immutable _vault;

    IBalancerQueries internal immutable _queries;

    constructor(
        ILinearPool pool,
        IVault vault,
        IBalancerQueries queries
    ) {
        _mainTokenScalingFactor = pool.getScalingFactors()[pool.getMainIndex()];

        _pool = pool;
        _poolId = pool.getPoolId();
        _mainToken = pool.getMainToken();
        _wrappedToken = pool.getWrappedToken();
        _vault = vault;
        _queries = queries;
    }

    function getPool() external view returns (ILinearPool) {
        return _pool;
    }

    /**
     * @notice Rebalance a Linear Pool from an asset manager to maintain optimal operating conditions.
     * @dev Use the asset manager mechanism to wrap/unwrap tokens as necessary to keep the main token
     * balance as close as possible to the midpoint between the upper and lower targets: the fee-free zone
     * where trading volume is highest.
     *
     * Note that this function may fail if called while the Pool is in the no-fee zone - use `rebalanceWithExtraMain` to
     * guarantee a successful execution.
     */
    function rebalance(address recipient) external returns (uint256) {
        return _rebalance(recipient);
    }

    /**
     * @notice Rebalance a Linear Pool from an asset manager to maintain optimal operating conditions.
     * @dev This function performs the same action as `rebalance`, except this also works in scenarios where the Pool
     * is in the no-fee zone. This is done by first taking `extraMain` tokens from the caller, to cover for rounding
     * errors that are normally offset by acccumulated fees. Any extra tokens unused during the rebalance are sent to
     * the recipient as usual.
     */
    function rebalanceWithExtraMain(address recipient, uint256 extraMain) external returns (uint256) {
        // The Pool rounds rates in its favor, which means that the fees it has collected are actually not quite enough
        // to cover for the cost of wrapping/unwrapping. However, this error is so small that it is typically a
        // non-issue, and simply results in slightly reduced returns for the recipient.
        // However, while the Pool is in the no-fee zone, the lack of fees to cover for this rate discrepancy is a
        // problem. We therefore require a minute amount of extra main token so that we'll be able to account for this
        // rounding error. Values in the order of a few wei are typically sufficient.

        _mainToken.safeTransferFrom(msg.sender, address(this), extraMain);
        return _rebalance(recipient);
    }

    function _rebalance(address recipient) private returns (uint256) {
        // The first thing we need to test is whether the Pool is below or above the target level, which will
        // determine whether we need to deposit or withdraw main tokens.
        uint256 desiredMainTokenBalance = _getDesiredMainTokenBalance();

        // For a 3 token General Pool, it is cheaper to query the balance for a single token than to read all balances,
        // as getPoolTokenInfo will check for token existence, token balance and Asset Manager (3 reads), while
        // getPoolTokens will read the number of tokens, their addresses and balances (7 reads).
        // We can assume that the managed balance is zero (since we're the Pool's Asset Manager and we always set it to
        // zero), and work with the cash directly as if it were the total balance.
        (uint256 mainTokenBalance, , , ) = _vault.getPoolTokenInfo(_poolId, _mainToken);

        if (mainTokenBalance < desiredMainTokenBalance) {
            return _rebalanceLackOfMainToken(desiredMainTokenBalance - mainTokenBalance, recipient);
        } else if (mainTokenBalance > desiredMainTokenBalance) {
            return _rebalanceExcessOfMainToken(mainTokenBalance - desiredMainTokenBalance, recipient);
        }
    }

    function _rebalanceLackOfMainToken(uint256 missingMainAmount, address recipient) private returns (uint256) {
        // The Pool needs to increase the main token balance, so we prepare a swap where we provide the missing main
        // token amount in exchange for wrapped tokens, that is, the main token is the token in. Since we know this
        // amount, this is a 'given in' swap.
        IVault.SingleSwap memory swap = IVault.SingleSwap({
            poolId: _poolId,
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(address(_mainToken)),
            assetOut: IAsset(address(_wrappedToken)),
            amount: missingMainAmount,
            userData: ""
        });

        // We can now query how much wrapped token the Pool would return if we were to execute this swap. The Linear
        // Pool invariant guarantees that this amount can be unwrapped to an amount greater than `missingMainAmount`,
        // with the difference originating from swap fees.

        IVault.FundManagement memory funds; // This is unused in the query, so we don't bother initializing it.
        uint256 wrappedAmountOut = _queries.querySwap(swap, funds);

        // Since we lack the main tokens required to actually execute the swap, we instead use our Asset Manager
        // permission to withdraw wrapped tokens from the Pool, unwrap them, and then deposit them as main tokens.
        // The amounts involved will be the exact same amounts as the one in the swap above, meaning the overall state
        // transition will be the same, except we will never actually call the Linear Pool. However, since the Linear
        // Pool's `onSwap` function is `view`, this is irrelevant.

        _withdrawFromPool(_wrappedToken, wrappedAmountOut);
        _unwrapTokens(wrappedAmountOut);
        _depositToPool(_mainToken, missingMainAmount);

        // This contract will now hold excess main token, since unwrapping `wrappedAmountOut` should have resulted in
        // more than `missingMainAmount` being obtained. These are sent to the caller to refund the gas cost.
        uint256 reward = _mainToken.balanceOf(address(this));
        _mainToken.safeTransfer(recipient, reward);
        return reward;
    }

    function _rebalanceExcessOfMainToken(uint256 excessMainAmount, address recipient) private returns (uint256) {
        // The Pool needs to reduce its main token balance, so we do a swap where we take the excess main token amount
        // and send wrapped tokens in exchange, that is, the main token is the token out. Since we know this amount,
        // this is a 'given out' swap.
        IVault.SingleSwap memory swap = IVault.SingleSwap({
            poolId: _poolId,
            kind: IVault.SwapKind.GIVEN_OUT,
            assetIn: IAsset(address(_wrappedToken)),
            assetOut: IAsset(address(_mainToken)),
            amount: excessMainAmount,
            userData: ""
        });

        // We can now query how much wrapped token we would need to send to the Pool if we were to execute this swap.
        // The Linear Pool invariant guarantees that this amount is less than what would be obtained by wrapping
        // `excessMainAmount`, with the difference originating from swap fees.

        IVault.FundManagement memory funds; // This is unused in the query, so we don't bother initializing it.
        uint256 wrappedAmountIn = _queries.querySwap(swap, funds);

        // Since we lack the wrapped tokens required to actually execute the swap, we instead use our Asset Manager
        // permission to withdraw main tokens from the Pool, wrap them, and then deposit them as wrapped tokens. The
        // amounts involved will be the exact same amounts as the those in the swap above, meaning the overall
        // state will be the same, except we will never actually call the Linear Pool. However, since the Linear
        // Pool's `onSwap` function is `view`, this is irrelevant.

        _withdrawFromPool(_mainToken, excessMainAmount);
        // We're not going to wrap the full amount, only what is required to get `wrappedAmountIn` back. Any remaining
        // main tokens will be transferred to the sender to refund the gas cost.
        _wrapTokens(_getRequiredTokensToWrap(wrappedAmountIn));
        _depositToPool(_wrappedToken, wrappedAmountIn);

        // This contract will now hold excess main token, since we didn't wrap all that was withdrawn. These are sent to
        // the caller to refund the gas cost.
        uint256 reward = _mainToken.balanceOf(address(this));
        _mainToken.safeTransfer(recipient, reward);
        return reward;
    }

    function _withdrawFromPool(IERC20 token, uint256 amount) private {
        // Tokens can be withdrawn from the Vault with a 'withdraw' operation, but that will create 'managed' balance
        // and leave the 'total' balance unchanged. We therefore have to perform two operations: one to withdraw, and
        // another to clear the 'managed' balance (as the tokens withdrawn are about to be wrapped or unwrapped, and
        // therefore lost to the Pool in their current format).
        IVault.PoolBalanceOp[] memory withdrawal = new IVault.PoolBalanceOp[](2);

        // First, we withdraw the tokens, creating a non-zero 'managed' balance in the Pool.
        withdrawal[0].kind = IVault.PoolBalanceOpKind.WITHDRAW;
        withdrawal[0].poolId = _poolId;
        withdrawal[0].amount = amount;
        withdrawal[0].token = token;

        // Then, we clear the 'managed' balance.
        withdrawal[1].kind = IVault.PoolBalanceOpKind.UPDATE;
        withdrawal[1].poolId = _poolId;
        withdrawal[1].amount = 0;
        withdrawal[1].token = token;

        _vault.managePoolBalance(withdrawal);
    }

    function _depositToPool(IERC20 token, uint256 amount) private {
        // Tokens can be deposited to the Vault with a 'deposit' operation, but that requires a prior 'managed'
        // balance to exist. We therefore have to perform two operations: one to set the 'managed' balance (representing
        // the new tokens that resulted from wrapping or unwrapping and which we are managing for the Pool), and
        // another to deposit.
        IVault.PoolBalanceOp[] memory deposit = new IVault.PoolBalanceOp[](2);

        // First, we inform the Vault of the 'managed' tokens.
        deposit[0].kind = IVault.PoolBalanceOpKind.UPDATE;
        deposit[0].poolId = _poolId;
        deposit[0].amount = amount;
        deposit[0].token = token;

        // Then, we deposit them, clearing the 'managed' balance.
        deposit[1].kind = IVault.PoolBalanceOpKind.DEPOSIT;
        deposit[1].poolId = _poolId;
        deposit[1].amount = amount;
        deposit[1].token = token;

        // Before we can deposit tokens into the Vault however, we must approve them.
        token.safeApprove(address(_vault), amount);

        _vault.managePoolBalance(deposit);
    }

    function _getDesiredMainTokenBalance() private view returns (uint256) {
        // The desired main token balance is the midpoint of the lower and upper targets. Keeping the balance
        // close to that value maximizes Pool swap volume by allowing zero-fee swaps in either direction.
        (uint256 lowerTarget, uint256 upperTarget) = _pool.getTargets();
        uint256 midpoint = (lowerTarget + upperTarget) / 2;

        // The targets are upscaled by the main token's scaling factor, so we undo that. Note that we're assuming that
        // the main token's scaling factor is constant.
        return FixedPoint.divDown(midpoint, _mainTokenScalingFactor);
    }

    /**
     * @dev Wraps `amount` of `_mainToken` into `_wrappedToken`.
     */
    function _wrapTokens(uint256 amount) internal virtual;

    /**
     * @dev Unwraps `amount` of `_wrappedToken` into `_mainToken`.
     */
    function _unwrapTokens(uint256 amount) internal virtual;

    /**
     * @dev Returns how many main tokens must be wrapped in order to get `wrappedAmount` back.
     */
    function _getRequiredTokensToWrap(uint256 wrappedAmount) internal view virtual returns (uint256);
}