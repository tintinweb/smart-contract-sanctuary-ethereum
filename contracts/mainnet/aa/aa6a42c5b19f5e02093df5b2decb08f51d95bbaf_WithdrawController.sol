// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControlEnumerable.sol";
import "AccessControl.sol";
import "EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

/**
 * @title Contract used for checking whether given address is allowed to put funds into an instrument according to implemented strategy
 * @dev Used by DepositController
 */
interface ILenderVerifier {
    /**
     * @param lender Address of lender to verify
     * @return Value indicating whether given lender address is allowed to put funds into an instrument or not
     */
    function isAllowed(address lender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {IERC20} from "IERC20.sol";

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {IERC721Upgradeable} from "IERC721Upgradeable.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";

interface IFinancialInstrument is IERC721Upgradeable {
    function principal(uint256 instrumentId) external view returns (uint256);

    function asset(uint256 instrumentId) external view returns (IERC20WithDecimals);

    function recipient(uint256 instrumentId) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {IFinancialInstrument} from "IFinancialInstrument.sol";

interface IDebtInstrument is IFinancialInstrument {
    function endDate(uint256 instrumentId) external view returns (uint256);

    function repay(uint256 instrumentId, uint256 amount) external returns (uint256 principalRepaid, uint256 interestRepaid);

    function start(uint256 instrumentId) external;

    function cancel(uint256 instrumentId) external;

    function markAsDefaulted(uint256 instrumentId) external;

    function issueInstrumentSelector() external pure returns (bytes4);

    function updateInstrumentSelector() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {IDebtInstrument} from "IDebtInstrument.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";

enum FixedInterestOnlyLoanStatus {
    Created,
    Accepted,
    Started,
    Repaid,
    Canceled,
    Defaulted
}

interface IFixedInterestOnlyLoans is IDebtInstrument {
    struct LoanMetadata {
        uint256 principal;
        uint256 periodPayment;
        FixedInterestOnlyLoanStatus status;
        uint16 periodCount;
        uint32 periodDuration;
        uint40 currentPeriodEndDate;
        address recipient;
        bool canBeRepaidAfterDefault;
        uint16 periodsRepaid;
        uint32 gracePeriod;
        uint40 endDate;
        IERC20WithDecimals asset;
    }

    function issueLoan(
        IERC20WithDecimals _asset,
        uint256 _principal,
        uint16 _periodCount,
        uint256 _periodPayment,
        uint32 _periodDuration,
        address _recipient,
        uint32 _gracePeriod,
        bool _canBeRepaidAfterDefault
    ) external returns (uint256);

    function loanData(uint256 instrumentId) external view returns (LoanMetadata memory);

    function updateInstrument(uint256 _instrumentId, uint32 _gracePeriod) external;

    function status(uint256 instrumentId) external view returns (FixedInterestOnlyLoanStatus);

    function expectedRepaymentAmount(uint256 instrumentId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {IAccessControlUpgradeable} from "IAccessControlUpgradeable.sol";
import {IFixedInterestOnlyLoans} from "IFixedInterestOnlyLoans.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";

struct AddLoanParams {
    uint256 principal;
    uint16 periodCount;
    uint256 periodPayment;
    uint32 periodDuration;
    address recipient;
    uint32 gracePeriod;
    bool canBeRepaidAfterDefault;
}

/// @title Manager of a Structured Portfolio's active loans
interface ILoansManager {
    /**
     * @notice Event emitted when the loan is added
     * @param loanId Loan id
     */
    event LoanAdded(uint256 indexed loanId);

    /**
     * @notice Event emitted when the loan is funded
     * @param loanId Loan id
     */
    event LoanFunded(uint256 indexed loanId);

    /**
     * @notice Event emitted when the loan is repaid
     * @param loanId Loan id
     * @param amount Repaid amount
     */
    event LoanRepaid(uint256 indexed loanId, uint256 amount);

    /**
     * @notice Event emitted when the loan is marked as defaulted
     * @param loanId Loan id
     */
    event LoanDefaulted(uint256 indexed loanId);

    /**
     * @notice Event emitted when the loan grace period is updated
     * @param loanId Loan id
     * @param newGracePeriod New loan grace period
     */
    event LoanGracePeriodUpdated(uint256 indexed loanId, uint32 newGracePeriod);

    /**
     * @notice Event emitted when the loan is cancelled
     * @param loanId Loan id
     */
    event LoanCancelled(uint256 indexed loanId);

    /**
     * @notice Event emitted when the loan is fully repaid, cancelled or defaulted
     * @param loanId Loan id
     */
    event ActiveLoanRemoved(uint256 indexed loanId);

    /// @return FixedInterestOnlyLoans contract address
    function fixedInterestOnlyLoans() external view returns (IFixedInterestOnlyLoans);

    /// @return Underlying asset address
    function asset() external view returns (IERC20WithDecimals);

    /**
     * @param index Index of loan in array
     * @return Loan id
     */
    function activeLoanIds(uint256 index) external view returns (uint256);

    /**
     * @param loanId Loan id
     * @return Value indicating whether loan with given id was issued by this contract
     */
    function issuedLoanIds(uint256 loanId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

interface IProtocolConfig {
    /**
     * @notice Event emitted when new defaultProtocolFeeRate is set
     * @param newProtocolFeeRate Newly set protocol fee rate (in BPS)
     */
    event DefaultProtocolFeeRateChanged(uint256 newProtocolFeeRate);

    /**
     * @notice Event emitted when new custom fee rate for a specific address is set
     * @param contractAddress Address of the contract for which new custom fee rate has been set
     * @param newProtocolFeeRate Newly set custom protocol fee rate (in BPS)
     */
    event CustomProtocolFeeRateChanged(address contractAddress, uint16 newProtocolFeeRate);

    /**
     * @notice Event emitted when custom fee rate for a specific address is unset
     * @param contractAddress Address of the contract for which custom fee rate has been unset
     */
    event CustomProtocolFeeRateRemoved(address contractAddress);

    /**
     * @notice Event emitted when new protocolAdmin address is set
     * @param newProtocolAdmin Newly set protocolAdmin address
     */
    event ProtocolAdminChanged(address indexed newProtocolAdmin);

    /**
     * @notice Event emitted when new protocolTreasury address is set
     * @param newProtocolTreasury Newly set protocolTreasury address
     */
    event ProtocolTreasuryChanged(address indexed newProtocolTreasury);

    /**
     * @notice Event emitted when new pauser address is set
     * @param newPauserAddress Newly set pauser address
     */
    event PauserAddressChanged(address indexed newPauserAddress);

    /**
     * @notice Setups the contract with given params
     * @dev Used by Initializable contract (can be called only once)
     * @param _defaultProtocolFeeRate Default fee rate valid for every contract except those with custom fee rate set
     * @param _protocolAdmin Address of the account/contract that should be able to upgrade Upgradeable contracts
     * @param _protocolTreasury Address of the account/contract to which collected fee should be transferred
     * @param _pauserAddress Address of the account/contract that should be grnated PAUSER role on TrueFi Pausable contracts
     */
    function initialize(
        uint256 _defaultProtocolFeeRate,
        address _protocolAdmin,
        address _protocolTreasury,
        address _pauserAddress
    ) external;

    /// @return Protocol fee rate valid for the message sender
    function protocolFeeRate() external view returns (uint256);

    /**
     * @return Protocol fee rate valid for the given address
     * @param contractAddress Address of contract queried for it's protocol fee rate
     */
    function protocolFeeRate(address contractAddress) external view returns (uint256);

    /// @return Default fee rate valid for every contract except those with custom fee rate set
    function defaultProtocolFeeRate() external view returns (uint256);

    /// @return Address of the account/contract that should be able to upgrade Upgradeable contracts
    function protocolAdmin() external view returns (address);

    /// @return Address of the account/contract to which collected fee should be transferred
    function protocolTreasury() external view returns (address);

    /// @return Address of the account/contract that should be grnated PAUSER role on TrueFi Pausable contracts
    function pauserAddress() external view returns (address);

    /**
     * @notice Custom protocol fee rate setter
     * @param contractAddress Address of the contract for which new custom fee rate should be set
     * @param newFeeRate Custom protocol fee rate (in BPS) which should be set for the given address
     */
    function setCustomProtocolFeeRate(address contractAddress, uint16 newFeeRate) external;

    /**
     * @notice Removes custom protocol fee rate from the given contract address
     * @param contractAddress Address of the contract for which custom fee rate should be unset
     */
    function removeCustomProtocolFeeRate(address contractAddress) external;

    /**
     * @notice Default protocol fee rate setter
     * @param newFeeRate New protocol fee rate (in BPS) to set
     */
    function setDefaultProtocolFeeRate(uint256 newFeeRate) external;

    /**
     * @notice Protocol admin address setter
     * @param newProtocolAdmin New protocol admin address to set
     */
    function setProtocolAdmin(address newProtocolAdmin) external;

    /**
     * @notice Protocol treasury address setter
     * @param newProtocolTreasury New protocol treasury address to set
     */
    function setProtocolTreasury(address newProtocolTreasury) external;

    /**
     * @notice TrueFi contracts pauser address setter
     * @param newPauserAddress New pauser address to set
     */
    function setPauserAddress(address newPauserAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {IAccessControlUpgradeable} from "IAccessControlUpgradeable.sol";
import {ITrancheVault} from "ITrancheVault.sol";
import {ILoansManager, AddLoanParams} from "ILoansManager.sol";
import {IFixedInterestOnlyLoans} from "IFixedInterestOnlyLoans.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";

uint256 constant BASIS_PRECISION = 10000;
uint256 constant YEAR = 365 days;

enum Status {
    CapitalFormation,
    Live,
    Closed
}

struct LoansDeficitCheckpoint {
    /// @dev Tranche missing funds due to defaulted loans
    uint256 deficit;
    /// @dev Timestamp of checkpoint
    uint256 timestamp;
}

struct TrancheData {
    /// @dev The APY expected to be granted at the end of the portfolio Live phase (in BPS)
    uint128 targetApy;
    /// @dev The minimum required ratio of the sum of subordinate tranches assets to the tranche assets (in BPS)
    uint128 minSubordinateRatio;
    /// @dev The amount of assets transferred to the tranche after close() was called
    uint256 distributedAssets;
    /// @dev The potential maximum amount of tranche assets available for withdraw after close() was called
    uint256 maxValueOnClose;
    /// @dev Checkpoint tracking how many assets should be returned to the tranche due to defaulted loans
    LoansDeficitCheckpoint loansDeficitCheckpoint;
}

struct TrancheInitData {
    /// @dev Address of the tranche vault
    ITrancheVault tranche;
    /// @dev The APY expected to be granted at the end of the portfolio Live phase (in BPS)
    uint128 targetApy;
    /// @dev The minimum ratio of the sum of subordinate tranches assets to the tranche assets (in BPS)
    uint128 minSubordinateRatio;
}

struct PortfolioParams {
    /// @dev Portfolio name
    string name;
    /// @dev Portfolio duration in seconds
    uint256 duration;
    /// @dev Capital formation period in seconds, used to calculate portfolio start deadline
    uint256 capitalFormationPeriod;
    /// @dev Minimum deposited amount needed to start the portfolio
    uint256 minimumSize;
}

struct ExpectedEquityRate {
    /// @dev Minimum expected APY on tranche 0 (expressed in bps)
    uint256 from;
    /// @dev Maximum expected APY on tranche 0 (expressed in bps)
    uint256 to;
}

/**
 * @title Structured Portfolio used for obtaining funds and managing loans
 * @notice Portfolio consists of multiple tranches, each offering a different yield for the lender
 * based on the respective risk.
 */

interface IStructuredPortfolio is IAccessControlUpgradeable {
    /**
     * @notice Event emitted when portfolio is initialized
     * @param tranches Array of tranches addresses
     */
    event PortfolioInitialized(ITrancheVault[] tranches);

    /**
     * @notice Event emitted when portfolio status is changed
     * @param newStatus Portfolio status set
     */
    event PortfolioStatusChanged(Status newStatus);

    /**
     * @notice Event emitted when tranches checkpoint is changed
     * @param totalAssets New values of tranches
     * @param protocolFeeRates New protocol fee rates for each tranche
     */
    event CheckpointUpdated(uint256[] totalAssets, uint256[] protocolFeeRates);

    /// @return Portfolio manager role used for access control
    function MANAGER_ROLE() external view returns (bytes32);

    /// @return Name of the StructuredPortfolio
    function name() external view returns (string memory);

    /// @return Current portfolio status
    function status() external view returns (Status);

    /// @return Timestamp of block in which StructuredPortfolio was switched to Live phase
    function startDate() external view returns (uint256);

    /**
     * @dev Returns expected end date or actual end date if portfolio was closed prematurely.
     * @return The date by which the manager is supposed to close the portfolio.
     */
    function endDate() external view returns (uint256);

    /**
     * @dev Timestamp after which anyone can close the portfolio if it's in capital formation.
     * @return The date by which the manager is supposed to launch the portfolio.
     */
    function startDeadline() external view returns (uint256);

    /// @return Minimum sum of all tranches assets required to be met to switch StructuredPortfolio to Live phase
    function minimumSize() external view returns (uint256);

    /**
     * @notice Launches the portfolio making it possible to issue loans.
     * @dev
     * - reverts if tranches ratios and portfolio min size are not met,
     * - changes status to `Live`,
     * - sets `startDate` and `endDate`,
     * - transfers assets obtained in tranches to the portfolio.
     */
    function start() external;

    /**
     * @notice Closes the portfolio, making it possible to withdraw funds from tranche vaults.
     * @dev
     * - reverts if there are any active loans before end date,
     * - changes status to `Closed`,
     * - calculates waterfall values for tranches and transfers the funds to the vaults,
     * - updates `endDate`.
     */
    function close() external;

    /**
     * @notice Distributes portfolio value among tranches respecting their target apys and fees.
     * Returns zeros for CapitalFormation and Closed portfolio status.
     * @return Array of current tranche values
     */
    function calculateWaterfall() external view returns (uint256[] memory);

    /**
     * @notice Distributes portfolio value among tranches respecting their target apys, but not fees.
     * Returns zeros for CapitalFormation and Closed portfolio status.
     * @return Array of current tranche values (with pending fees not deducted)
     */
    function calculateWaterfallWithoutFees() external view returns (uint256[] memory);

    /**
     * @param trancheIndex Index of tranche
     * @return Current value of tranche in Live status, 0 for other statuses
     */
    function calculateWaterfallForTranche(uint256 trancheIndex) external view returns (uint256);

    /**
     * @param trancheIndex Index of tranche
     * @return Current value of tranche (with pending fees not deducted) in Live status, 0 for other statuses
     */
    function calculateWaterfallForTrancheWithoutFee(uint256 trancheIndex) external view returns (uint256);

    /**
     * @notice Setup contract with given params
     * @dev Used by Initializable contract (can be called only once)
     * @param manager Address on which MANAGER_ROLE is granted
     * @param underlyingToken Address of ERC20 token used by portfolio
     * @param fixedInterestOnlyLoans Address of FixedInterestOnlyLoans contract
     * @param _protocolConfig Address of ProtocolConfig contract
     * @param portfolioParams Parameters to configure portfolio
     * @param tranchesInitData Parameters to configure tranches
     * @param _expectedEquityRate APY range that is expected to be reached by Equity tranche
     */
    function initialize(
        address manager,
        IERC20WithDecimals underlyingToken,
        IFixedInterestOnlyLoans fixedInterestOnlyLoans,
        IProtocolConfig _protocolConfig,
        PortfolioParams memory portfolioParams,
        TrancheInitData[] memory tranchesInitData,
        ExpectedEquityRate memory _expectedEquityRate
    ) external;

    /// @return Array of portfolio's tranches addresses
    function getTranches() external view returns (ITrancheVault[] memory);

    /**
     * @return i-th tranche data
     */
    function getTrancheData(uint256) external view returns (TrancheData memory);

    /**
     * @notice Updates checkpoints on each tranche and pay pending fees
     * @dev Can be executed only in Live status
     */
    function updateCheckpoints() external;

    /// @return Total value locked in the contract including yield from outstanding loans
    function totalAssets() external view returns (uint256);

    /// @return Underlying token balance of portfolio reduced by pending fees
    function liquidAssets() external view returns (uint256);

    /// @return Sum of current values of all active loans
    function loansValue() external view returns (uint256);

    /// @return Sum of all unsettled fees that tranches should pay
    function totalPendingFees() external view returns (uint256);

    /// @return Array of all active loans' ids
    function getActiveLoans() external view returns (uint256[] memory);

    /**
     * @notice Creates a loan that should be accepted next by the loan recipient
     * @dev
     * - can be executed only by StructuredPortfolio manager
     * - can be executed only in Live status
     */
    function addLoan(AddLoanParams calldata params) external;

    /**
     * @notice Starts a loan with given id and transfers assets to loan recipient
     * @dev
     * - can be executed only by StructuredPortfolio manager
     * - can be executed only in Live status
     * @param loanId Id of the loan that should be started
     */
    function fundLoan(uint256 loanId) external;

    /**
     * @notice Allows sender to repay a loan with given id
     * @dev
     * - cannot be executed in CapitalFormation
     * - can be executed only by loan recipient
     * - automatically calculates amount to repay based on data stored in FixedInterestOnlyLoans contract
     * @param loanId Id of the loan that should be repaid
     */
    function repayLoan(uint256 loanId) external;

    /**
     * @notice Cancels the loan with provided loan id
     * @dev Can be executed only by StructuredPortfolio manager
     * @param loanId Id of the loan to cancel
     */
    function cancelLoan(uint256 loanId) external;

    /**
     * @notice Sets the status of a loan with given id to Defaulted and excludes it from active loans array
     * @dev Can be executed only by StructuredPortfolio manager
     * @param loanId Id of the loan that should be defaulted
     */
    function markLoanAsDefaulted(uint256 loanId) external;

    /**
     * @notice Sets new grace period for the existing loan
     * @dev Can be executed only by StructuredPortfolio manager
     * @param loanId Id of the loan which grace period should be updated
     * @param newGracePeriod New grace period to set (in seconds)
     */
    function updateLoanGracePeriod(uint256 loanId, uint32 newGracePeriod) external;

    /**
     * @notice Virtual value of the portfolio
     */
    function virtualTokenBalance() external view returns (uint256);

    /**
     * @notice Increase virtual portfolio value
     * @dev Must be called by a tranche
     */
    function increaseVirtualTokenBalance(uint256 delta) external;

    /**
     * @notice Decrease virtual portfolio value
     * @dev Must be called by a tranche
     */
    function decreaseVirtualTokenBalance(uint256 delta) external;

    /**
     * @notice Reverts if tranche ratios are not met
     * @param newTotalAssets new total assets value of the tranche calling this function.
     * Is ignored if not called by tranche
     */
    function checkTranchesRatiosFromTranche(uint256 newTotalAssets) external view;
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {ILenderVerifier} from "ILenderVerifier.sol";
import {Status} from "IStructuredPortfolio.sol";

struct DepositAllowed {
    /// @dev StructuredPortfolio status for which deposits should be enabled or disabled
    Status status;
    /// @dev Value indicating whether deposits should be enabled or disabled
    bool value;
}

/**
 * @title Contract for managing deposit related settings
 * @dev Used by TrancheVault contract
 */
interface IDepositController {
    /**
     * @notice Event emitted when new ceiling is set
     * @param newCeiling New ceiling value
     */
    event CeilingChanged(uint256 newCeiling);

    /**
     * @notice Event emitted when deposits are disabled or enabled for a specific StructuredPortfolio status
     * @param newDepositAllowed Value indicating whether deposits should be enabled or disabled
     * @param portfolioStatus StructuredPortfolio status for which changes are applied
     */
    event DepositAllowedChanged(bool newDepositAllowed, Status portfolioStatus);

    /**
     * @notice Event emitted when deposit fee rate is switched
     * @param newFeeRate New deposit fee rate value (in BPS)
     */
    event DepositFeeRateChanged(uint256 newFeeRate);

    /**
     * @notice Event emitted when lender verifier is switched
     * @param newLenderVerifier New lender verifier contract address
     */
    event LenderVerifierChanged(ILenderVerifier indexed newLenderVerifier);

    /// @return DepositController manager role used for access control
    function MANAGER_ROLE() external view returns (bytes32);

    /// @return Address of contract used for checking whether given address is allowed to put funds into an instrument according to implemented strategy
    function lenderVerifier() external view returns (ILenderVerifier);

    /// @return Max asset capacity defined for TrancheVaults interracting with DepositController
    function ceiling() external view returns (uint256);

    /// @return Rate (in BPS) of the fee applied to the deposit amount
    function depositFeeRate() external view returns (uint256);

    /// @return Value indicating whether deposits are allowed when related StructuredPortfolio is in given status
    /// @param status StructuredPortfolio status
    function depositAllowed(Status status) external view returns (bool);

    /**
     * @notice Setup contract with given params
     * @dev Used by Initializable contract (can be called only once)
     * @param manager Address to which MANAGER_ROLE should be granted
     * @param lenderVerfier Address of LenderVerifier contract
     * @param _depositFeeRate Deposit fee rate (in BPS)
     * @param ceiling Ceiling value
     */
    function initialize(
        address manager,
        address lenderVerfier,
        uint256 _depositFeeRate,
        uint256 ceiling
    ) external;

    /**
     * @return assets Max assets amount that can be deposited with TrancheVault shares minted to given receiver
     * @param receiver Shares receiver address
     */
    function maxDeposit(address receiver) external view returns (uint256 assets);

    /**
     * @return shares Max TrancheVault shares amount given address can receive
     * @param receiver Shares receiver address
     */
    function maxMint(address receiver) external view returns (uint256 shares);

    /**
     * @notice Simulates deposit assets conversion including fees
     * @return shares Shares amount that can be obtained from the given assets amount
     * @param assets Tested assets amount
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Simulates mint shares conversion including fees
     * @return assets Assets amount that needs to be deposited to obtain given shares amount
     * @param shares Tested shares amount
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice Simulates deposit result
     * @return shares Shares amount that can be obtained from the deposit with given params
     * @return depositFee Fee for a deposit with given params
     * @param sender Supposed deposit transaction sender address
     * @param assets Supposed assets amount
     * @param receiver Supposed shares receiver address
     */
    function onDeposit(
        address sender,
        uint256 assets,
        address receiver
    ) external returns (uint256 shares, uint256 depositFee);

    /**
     * @notice Simulates mint result
     * @return assets Assets amount that needs to be provided to execute mint with given params
     * @return mintFee Fee for a mint with given params
     * @param sender Supposed mint transaction sender address
     * @param shares Supposed shares amount
     * @param receiver Supposed shares receiver address
     */
    function onMint(
        address sender,
        uint256 shares,
        address receiver
    ) external returns (uint256 assets, uint256 mintFee);

    /**
     * @notice Ceiling setter
     * @param newCeiling New ceiling value
     */
    function setCeiling(uint256 newCeiling) external;

    /**
     * @notice Deposit allowed setter
     * @param newDepositAllowed Value indicating whether deposits should be allowed when related StructuredPortfolio is in given status
     * @param portfolioStatus StructuredPortfolio status for which changes are applied
     */
    function setDepositAllowed(bool newDepositAllowed, Status portfolioStatus) external;

    /**
     * @notice Deposit fee rate setter
     * @param newFeeRate New deposit fee rate (in BPS)
     */
    function setDepositFeeRate(uint256 newFeeRate) external;

    /**
     * @notice Lender verifier setter
     * @param newLenderVerifier New LenderVerifer contract address
     */
    function setLenderVerifier(ILenderVerifier newLenderVerifier) external;

    /**
     * @notice Allows to change ceiling, deposit fee rate, lender verifier and enable or disable deposits at once
     * @param newCeiling New ceiling value
     * @param newFeeRate New deposit fee rate (in BPS)
     * @param newLenderVerifier New LenderVerifier contract address
     * @param newDepositAllowed New deposit allowed settings
     */
    function configure(
        uint256 newCeiling,
        uint256 newFeeRate,
        ILenderVerifier newLenderVerifier,
        DepositAllowed memory newDepositAllowed
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {Status} from "IStructuredPortfolio.sol";

struct WithdrawAllowed {
    /// @dev StructuredPortfolio status for which withdrawals should be enabled or disabled
    Status status;
    /// @dev Value indicating whether withdrawals should be enabled or disabled
    bool value;
}

/**
 * @title Contract for managing withdraw related settings
 * @dev Used by TrancheVault contract
 */
interface IWithdrawController {
    /**
     * @notice Event emitted when new floor is set
     * @param newFloor New floor value
     */
    event FloorChanged(uint256 newFloor);

    /**
     * @notice Event emitted when withdrawals are disabled or enabled for a specific StructuredPortfolio status
     * @param newWithdrawAllowed Value indicating whether withdrawals should be enabled or disabled
     * @param portfolioStatus StructuredPortfolio status for which changes are applied
     */
    event WithdrawAllowedChanged(bool newWithdrawAllowed, Status portfolioStatus);

    /**
     * @notice Event emitted when withdraw fee rate is switched
     * @param newFeeRate New withdraw fee rate value (in BPS)
     */
    event WithdrawFeeRateChanged(uint256 newFeeRate);

    /// @return WithdrawController manager role used for access control
    function MANAGER_ROLE() external view returns (bytes32);

    /// @return Min assets amount that needs to stay in TrancheVault interracting with WithdrawController when related StructuredPortfolio is not in Closed state
    function floor() external view returns (uint256);

    /// @return Rate (in BPS) of the fee applied to the withdraw amount
    function withdrawFeeRate() external view returns (uint256);

    /// @return Value indicating whether withdrawals are allowed when related StructuredPortfolio is in given status
    /// @param status StructuredPortfolio status
    function withdrawAllowed(Status status) external view returns (bool);

    /**
     * @notice Setup contract with given params
     * @dev Used by Initializable contract (can be called only once)
     * @param manager Address to which MANAGER_ROLE should be granted
     * @param withdrawFeeRate Withdraw fee rate (in BPS)
     * @param floor Floor value
     */
    function initialize(
        address manager,
        uint256 withdrawFeeRate,
        uint256 floor
    ) external;

    /**
     * @return assets Max assets amount that can be withdrawn from TrancheVault for shares of given owner
     * @param owner Shares owner address
     */
    function maxWithdraw(address owner) external view returns (uint256 assets);

    /**
     * @return shares Max TrancheVault shares amount given owner can burn to withdraw assets
     * @param owner Shares owner address
     */
    function maxRedeem(address owner) external view returns (uint256 shares);

    /**
     * @notice Simulates withdraw assets conversion including fees
     * @return shares Shares amount that needs to be burnt to obtain given assets amount
     * @param assets Tested assets amount
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Simulates redeem shares conversion including fees
     * @return assets Assets amount that will be obtained from the given shares burnt
     * @param shares Tested shares amount
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice Simulates withdraw result
     * @return shares Shares amount that needs to be burnt to make a withdrawal with given params
     * @return withdrawFee Fee for a withdrawal with given params
     * @param sender Supposed withdraw transaction sender address
     * @param assets Supposed assets amount
     * @param receiver Supposed assets receiver address
     * @param owner Supposed shares owner
     */
    function onWithdraw(
        address sender,
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares, uint256 withdrawFee);

    /**
     * @notice Simulates redeem result
     * @return assets Assets amount that will be obtained from the redeem with given params
     * @return redeemFee Fee for a redeem with given params
     * @param sender Supposed redeem transaction sender address
     * @param shares Supposed shares amount
     * @param receiver Supposed assets receiver address
     * @param owner Supposed shares owner
     */
    function onRedeem(
        address sender,
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets, uint256 redeemFee);

    /**
     * @notice Floor setter
     * @param newFloor New floor value
     */
    function setFloor(uint256 newFloor) external;

    /**
     * @notice Withdraw allowed setter
     * @param newWithdrawAllowed Value indicating whether withdrawals should be allowed when related StructuredPortfolio is in given status
     * @param portfolioStatus StructuredPortfolio status for which changes are applied
     */
    function setWithdrawAllowed(bool newWithdrawAllowed, Status portfolioStatus) external;

    /**
     * @notice Withdraw fee rate setter
     * @param newFeeRate New withdraw fee rate (in BPS)
     */
    function setWithdrawFeeRate(uint256 newFeeRate) external;

    /**
     * @notice Allows to change floor, withdraw fee rate and enable or disable withdrawals at once
     * @param newFloor New floor value
     * @param newFeeRate New withdraw fee rate (in BPS)
     * @param newWithdrawAllowed New withdraw allowed settings
     */
    function configure(
        uint256 newFloor,
        uint256 newFeeRate,
        WithdrawAllowed memory newWithdrawAllowed
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

interface ITransferController {
    /**
     * @notice Setup contract with given params
     * @dev Used by Initializable contract (can be called only once)
     * @param manager Address to which MANAGER_ROLE should be granted
     */
    function initialize(address manager) external;

    /**
     * @notice Verifies TrancheVault shares transfers
     * @return isTransferAllowed Value indicating whether TrancheVault shares transfer with given params is allowed
     * @param sender Transfer transaction sender address
     * @param from Transferred funds owner address
     * @param to Transferred funds recipient address
     * @param value Transferred assets amount
     */
    function onTransfer(
        address sender,
        address from,
        address to,
        uint256 value
    ) external view returns (bool isTransferAllowed);
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {IERC4626Upgradeable} from "IERC4626Upgradeable.sol";
import {IERC165} from "IERC165.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {ITransferController} from "ITransferController.sol";
import {IStructuredPortfolio} from "IStructuredPortfolio.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";

struct SizeRange {
    uint256 floor;
    uint256 ceiling;
}

struct Checkpoint {
    uint256 totalAssets;
    uint256 protocolFeeRate;
    uint256 timestamp;
}

struct Configuration {
    uint256 managerFeeRate;
    address managerFeeBeneficiary;
    IDepositController depositController;
    IWithdrawController withdrawController;
    ITransferController transferController;
}

interface ITrancheVault is IERC4626Upgradeable, IERC165 {
    /**
     * @notice Event emitted when checkpoint is changed
     * @param totalAssets Tranche total assets at the moment of checkpoint creation
     * @param protocolFeeRate Protocol fee rate at the moment of checkpoint creation
     */
    event CheckpointUpdated(uint256 totalAssets, uint256 protocolFeeRate);

    /**
     * @notice Event emitted when fee is transfered to protocol
     * @param protocolAddress Address to which protocol fees are transfered
     * @param fee Fee amount paid to protocol
     */
    event ProtocolFeePaid(address indexed protocolAddress, uint256 fee);

    /**
     * @notice Event emitted when fee is transfered to manager
     * @param managerFeeBeneficiary Address to which manager fees are transfered
     * @param fee Fee amount paid to protocol
     */
    event ManagerFeePaid(address indexed managerFeeBeneficiary, uint256 fee);

    /**
     * @notice Event emitted when manager fee rate is changed by the manager
     * @param newManagerFeeRate New fee rate
     */
    event ManagerFeeRateChanged(uint256 newManagerFeeRate);

    /**
     * @notice Event emitted when manager fee beneficiary is changed by the manager
     * @param newManagerFeeBeneficiary New beneficiary address to which manager fee will be transferred
     */
    event ManagerFeeBeneficiaryChanged(address newManagerFeeBeneficiary);

    /**
     * @notice Event emitted when new DepositController address is set
     * @param newController New DepositController address
     */
    event DepositControllerChanged(IDepositController indexed newController);

    /**
     * @notice Event emitted when new WithdrawController address is set
     * @param newController New WithdrawController address
     */
    event WithdrawControllerChanged(IWithdrawController indexed newController);

    /**
     * @notice Event emitted when new TransferController address is set
     * @param newController New TransferController address
     */
    event TransferControllerChanged(ITransferController indexed newController);

    /// @notice Tranche manager role used for access control
    function MANAGER_ROLE() external view returns (bytes32);

    /// @notice Role used to access tranche controllers setters
    function TRANCHE_CONTROLLER_OWNER_ROLE() external view returns (bytes32);

    /// @return Associated StructuredPortfolio address
    function portfolio() external view returns (IStructuredPortfolio);

    /// @return Address of DepositController contract responsible for deposit-related operations on TrancheVault
    function depositController() external view returns (IDepositController);

    /// @return Address of WithdrawController contract responsible for withdraw-related operations on TrancheVault
    function withdrawController() external view returns (IWithdrawController);

    /// @return Address of TransferController contract deducing whether a specific transfer is allowed or not
    function transferController() external view returns (ITransferController);

    /// @return TrancheVault index in StructuredPortfolio tranches order
    function waterfallIndex() external view returns (uint256);

    /// @return Annual rate of continuous fee accrued on every block on the top of checkpoint tranche total assets (expressed in bps)
    function managerFeeRate() external view returns (uint256);

    /// @return Address to which manager fee should be transferred
    function managerFeeBeneficiary() external view returns (address);

    /// @return Address of ProtocolConfig contract used to collect protocol fee
    function protocolConfig() external view returns (IProtocolConfig);

    /**
     * @notice DepositController address setter
     * @dev Can be executed only by TrancheVault manager
     * @param newController New DepositController address
     */
    function setDepositController(IDepositController newController) external;

    /**
     * @notice WithdrawController address setter
     * @dev Can be executed only by TrancheVault manager
     * @param newController New WithdrawController address
     */
    function setWithdrawController(IWithdrawController newController) external;

    /**
     * @notice TransferController address setter
     * @dev Can be executed only by TrancheVault manager
     * @param newController New TransferController address
     */
    function setTransferController(ITransferController newController) external;

    /**
     * @notice Sets address of StructuredPortfolio associated with TrancheVault
     * @dev Can be executed only once
     * @param _portfolio StructuredPortfolio address
     */
    function setPortfolio(IStructuredPortfolio _portfolio) external;

    /**
     * @notice Manager fee rate setter
     * @dev Can be executed only by TrancheVault manager
     * @param newFeeRate New manager fee rate (expressed in bps)
     */
    function setManagerFeeRate(uint256 newFeeRate) external;

    /**
     * @notice Manager fee beneficiary setter
     * @dev Can be executed only by TrancheVault manager
     * @param newBeneficiary New manager fee beneficiary address
     */
    function setManagerFeeBeneficiary(address newBeneficiary) external;

    /**
     * @notice Setup contract with given params
     * @dev Used by Initializable contract (can be called only once)
     * @param _name Contract name
     * @param _symbol Contract symbol
     * @param _token Address of ERC20 token used by TrancheVault
     * @param _depositController Address of DepositController contract responsible for deposit-related operations on TrancheVault
     * @param _withdrawController Address of WithdrawController contract responsible for withdraw-related operations on TrancheVault
     * @param _transferController Address of TransferController contract deducing whether a specific transfer is allowed or not
     * @param _protocolConfig Address of ProtocolConfig contract storing TrueFi protocol-related data
     * @param _waterfallIndex TrancheVault index in StructuredPortfolio tranches order
     * @param manager Address on which MANAGER_ROLE is granted
     * @param _managerFeeRate Annual rate of continuous fee accrued on every block on the top of checkpoint tranche total assets (expressed in bps)
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20WithDecimals _token,
        IDepositController _depositController,
        IWithdrawController _withdrawController,
        ITransferController _transferController,
        IProtocolConfig _protocolConfig,
        uint256 _waterfallIndex,
        address manager,
        uint256 _managerFeeRate
    ) external;

    /**
     * @notice Updates TrancheVault checkpoint with current total assets and pays pending fees
     */
    function updateCheckpoint() external;

    /**
     * @notice Updates TrancheVault checkpoint with total assets value calculated in StructuredPortfolio waterfall
     * @dev
     * - can be executed only by associated StructuredPortfolio
     * - is used by StructuredPortfolio only in Live portfolio status
     * @param _totalAssets Total assets amount to save in the checkpoint
     */
    function updateCheckpointFromPortfolio(uint256 _totalAssets) external;

    /// @return Total tranche assets including accrued but yet not paid fees
    function totalAssetsBeforeFees() external view returns (uint256);

    /// @return Sum of all unpaid fees and fees accrued since last checkpoint update
    function totalPendingFees() external view returns (uint256);

    /**
     * @return Sum of all unpaid fees and fees accrued on the given amount since last checkpoint update
     * @param amount Asset amount with which fees should be calculated
     */
    function totalPendingFeesForAssets(uint256 amount) external view returns (uint256);

    /// @return Sum of unpaid protocol fees and protocol fees accrued since last checkpoint update
    function pendingProtocolFee() external view returns (uint256);

    /// @return Sum of unpaid manager fees and manager fees accrued since last checkpoint update
    function pendingManagerFee() external view returns (uint256);

    /// @return checkpoint Checkpoint tracking info about TrancheVault total assets and protocol fee rate at last checkpoint update, and timestamp of that update
    function getCheckpoint() external view returns (Checkpoint memory checkpoint);

    /// @return protocolFee Remembered value of fee unpaid to protocol due to insufficient TrancheVault funds at the moment of transfer
    function unpaidProtocolFee() external view returns (uint256 protocolFee);

    /// @return managerFee Remembered value of fee unpaid to manager due to insufficient TrancheVault funds at the moment of transfer
    function unpaidManagerFee() external view returns (uint256);

    /**
     * @notice Initializes TrancheVault checkpoint and transfers all TrancheVault assets to associated StructuredPortfolio
     * @dev
     * - can be executed only by associated StructuredPortfolio
     * - called by associated StructuredPortfolio on transition to Live status
     */
    function onPortfolioStart() external;

    /**
     * @notice Updates virtualTokenBalance and checkpoint after transferring assets from StructuredPortfolio to TrancheVault
     * @dev Can be executed only by associated StructuredPortfolio
     * @param assets Transferred assets amount
     */
    function onTransfer(uint256 assets) external;

    /**
     * @notice Converts given amount of token assets to TrancheVault LP tokens at the current price, without respecting fees
     * @param assets Amount of assets to convert
     */
    function convertToSharesCeil(uint256 assets) external view returns (uint256);

    /**
     * @notice Converts given amount of TrancheVault LP tokens to token assets at the current price, without respecting fees
     * @param shares Amount of TrancheVault LP tokens to convert
     */
    function convertToAssetsCeil(uint256 shares) external view returns (uint256);

    /**
     * @notice Allows to change managerFeeRate, managerFeeBeneficiary, depositController and withdrawController
     * @dev Can be executed only by TrancheVault manager
     */
    function configure(Configuration memory newConfiguration) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {Math} from "Math.sol";
import {Initializable} from "Initializable.sol";
import {AccessControlEnumerable} from "AccessControlEnumerable.sol";
import {ITrancheVault} from "ITrancheVault.sol";
import {IStructuredPortfolio} from "IStructuredPortfolio.sol";
import {IWithdrawController, Status, WithdrawAllowed} from "IWithdrawController.sol";

uint256 constant BASIS_PRECISION = 10000;

contract WithdrawController is IWithdrawController, Initializable, AccessControlEnumerable {
    /// @dev Manager role used for access control
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 public floor;
    uint256 public withdrawFeeRate;
    mapping(Status => bool) public withdrawAllowed;

    constructor() {}

    function initialize(
        address manager,
        uint256 _withdrawFeeRate,
        uint256 _floor
    ) external initializer {
        withdrawFeeRate = _withdrawFeeRate;
        _grantRole(MANAGER_ROLE, manager);
        withdrawAllowed[Status.Closed] = true;

        floor = _floor;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        ITrancheVault vault = ITrancheVault(msg.sender);
        Status status = vault.portfolio().status();
        if (!withdrawAllowed[status]) {
            return 0;
        }

        uint256 ownerShares = vault.balanceOf(owner);
        uint256 userMaxWithdraw = vault.convertToAssets(ownerShares);
        if (status == Status.Closed) {
            return userMaxWithdraw;
        }

        uint256 globalMaxWithdraw = _globalMaxWithdraw(vault, status);

        return Math.min(userMaxWithdraw, globalMaxWithdraw);
    }

    function maxRedeem(address owner) external view returns (uint256) {
        ITrancheVault vault = ITrancheVault(msg.sender);
        Status status = vault.portfolio().status();
        if (!withdrawAllowed[status]) {
            return 0;
        }

        uint256 userMaxRedeem = vault.balanceOf(owner);
        if (status == Status.Closed) {
            return userMaxRedeem;
        }

        uint256 globalMaxWithdraw = _globalMaxWithdraw(vault, status);
        uint256 globalMaxRedeem = vault.convertToShares(globalMaxWithdraw);

        return Math.min(userMaxRedeem, globalMaxRedeem);
    }

    function _globalMaxWithdraw(ITrancheVault vault, Status status) internal view returns (uint256) {
        uint256 totalWithdrawableAssets = vault.totalAssets();
        IStructuredPortfolio portfolio = vault.portfolio();
        if (status == Status.Live) {
            uint256 virtualTokenBalance = portfolio.virtualTokenBalance();
            if (virtualTokenBalance < totalWithdrawableAssets) {
                totalWithdrawableAssets = virtualTokenBalance;
            }
        }
        return totalWithdrawableAssets > floor ? totalWithdrawableAssets - floor : 0;
    }

    function onWithdraw(
        address,
        uint256 assets,
        address,
        address
    ) external view returns (uint256, uint256) {
        uint256 withdrawFee = _getWithdrawFee(assets);
        return (previewWithdraw(assets), withdrawFee);
    }

    function onRedeem(
        address,
        uint256 shares,
        address,
        address
    ) external view returns (uint256, uint256) {
        uint256 assets = ITrancheVault(msg.sender).convertToAssets(shares);
        uint256 withdrawFee = _getWithdrawFee(assets);
        return (assets - withdrawFee, withdrawFee);
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        uint256 assets = ITrancheVault(msg.sender).convertToAssets(shares);
        uint256 withdrawFee = _getWithdrawFee(assets);
        return assets - withdrawFee;
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        uint256 withdrawFee = _getWithdrawFee(assets);
        return ITrancheVault(msg.sender).convertToSharesCeil(assets + withdrawFee);
    }

    function setFloor(uint256 newFloor) public {
        _requireManagerRole();
        floor = newFloor;
        emit FloorChanged(newFloor);
    }

    function setWithdrawAllowed(bool newWithdrawAllowed, Status portfolioStatus) public {
        _requireManagerRole();
        require(portfolioStatus == Status.CapitalFormation || portfolioStatus == Status.Live, "WC: No custom value in Closed");
        withdrawAllowed[portfolioStatus] = newWithdrawAllowed;
        emit WithdrawAllowedChanged(newWithdrawAllowed, portfolioStatus);
    }

    function setWithdrawFeeRate(uint256 newFeeRate) public {
        _requireManagerRole();
        withdrawFeeRate = newFeeRate;
        emit WithdrawFeeRateChanged(newFeeRate);
    }

    function configure(
        uint256 newFloor,
        uint256 newFeeRate,
        WithdrawAllowed memory newWithdrawAllowed
    ) external {
        if (floor != newFloor) {
            setFloor(newFloor);
        }
        if (withdrawFeeRate != newFeeRate) {
            setWithdrawFeeRate(newFeeRate);
        }
        if (withdrawAllowed[newWithdrawAllowed.status] != newWithdrawAllowed.value) {
            setWithdrawAllowed(newWithdrawAllowed.value, newWithdrawAllowed.status);
        }
    }

    function _getWithdrawFee(uint256 assets) internal view returns (uint256) {
        return (assets * withdrawFeeRate) / BASIS_PRECISION;
    }

    function _requireManagerRole() internal view {
        require(hasRole(MANAGER_ROLE, msg.sender), "WC: Only manager");
    }
}