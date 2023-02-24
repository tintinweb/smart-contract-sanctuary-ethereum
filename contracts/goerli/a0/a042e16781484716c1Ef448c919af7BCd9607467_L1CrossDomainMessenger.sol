// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Predeploys } from "../libraries/Predeploys.sol";
import { OptimismPortal } from "./OptimismPortal.sol";
import { CrossDomainMessenger } from "../universal/CrossDomainMessenger.sol";
import { Semver } from "../universal/Semver.sol";

/**
 * @custom:proxied
 * @title L1CrossDomainMessenger
 * @notice The L1CrossDomainMessenger is a message passing interface between L1 and L2 responsible
 *         for sending and receiving data on the L1 side. Users are encouraged to use this
 *         interface instead of interacting with lower-level contracts directly.
 */
contract L1CrossDomainMessenger is CrossDomainMessenger, Semver {
    /**
     * @notice Address of the OptimismPortal.
     */
    OptimismPortal public immutable PORTAL;

    /**
     * @custom:semver 1.0.0
     *
     * @param _portal Address of the OptimismPortal contract on this network.
     */
    constructor(OptimismPortal _portal)
        Semver(1, 0, 0)
        CrossDomainMessenger(Predeploys.L2_CROSS_DOMAIN_MESSENGER)
    {
        PORTAL = _portal;
        initialize(address(0));
    }

    /**
     * @notice Initializer.
     *
     * @param _owner Address of the initial owner of this contract.
     */
    function initialize(address _owner) public initializer {
        __CrossDomainMessenger_init();
        _transferOwnership(_owner);
    }

    /**
     * @inheritdoc CrossDomainMessenger
     */
    function _sendMessage(
        address _to,
        uint64 _gasLimit,
        uint256 _value,
        bytes memory _data
    ) internal override {
        PORTAL.depositTransaction{ value: _value }(_to, _value, _gasLimit, false, _data);
    }

    /**
     * @inheritdoc CrossDomainMessenger
     */
    function _isOtherMessenger() internal view override returns (bool) {
        return msg.sender == address(PORTAL) && PORTAL.l2Sender() == OTHER_MESSENGER;
    }

    /**
     * @inheritdoc CrossDomainMessenger
     */
    function _isUnsafeTarget(address _target) internal view override returns (bool) {
        return _target == address(this) || _target == address(PORTAL);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Semver } from "../universal/Semver.sol";
import { Types } from "../libraries/Types.sol";

/**
 * @custom:proxied
 * @title L2OutputOracle
 * @notice The L2OutputOracle contains an array of L2 state outputs, where each output is a
 *         commitment to the state of the L2 chain. Other contracts like the OptimismPortal use
 *         these outputs to verify information about the state of L2.
 */
contract L2OutputOracle is Initializable, Semver {
    /**
     * @notice The interval in L2 blocks at which checkpoints must be submitted. Although this is
     *         immutable, it can safely be modified by upgrading the implementation contract.
     */
    uint256 public immutable SUBMISSION_INTERVAL;

    /**
     * @notice The time between L2 blocks in seconds. Once set, this value MUST NOT be modified.
     */
    uint256 public immutable L2_BLOCK_TIME;

    /**
     * @notice The address of the challenger. Can be updated via upgrade.
     */
    address public immutable CHALLENGER;

    /**
     * @notice The address of the proposer. Can be updated via upgrade.
     */
    address public immutable PROPOSER;

    /**
     * @notice The number of the first L2 block recorded in this contract.
     */
    uint256 public startingBlockNumber;

    /**
     * @notice The timestamp of the first L2 block recorded in this contract.
     */
    uint256 public startingTimestamp;

    /**
     * @notice Array of L2 output proposals.
     */
    Types.OutputProposal[] internal l2Outputs;

    /**
     * @notice Emitted when an output is proposed.
     *
     * @param outputRoot    The output root.
     * @param l2OutputIndex The index of the output in the l2Outputs array.
     * @param l2BlockNumber The L2 block number of the output root.
     * @param l1Timestamp   The L1 timestamp when proposed.
     */
    event OutputProposed(
        bytes32 indexed outputRoot,
        uint256 indexed l2OutputIndex,
        uint256 indexed l2BlockNumber,
        uint256 l1Timestamp
    );

    /**
     * @notice Emitted when outputs are deleted.
     *
     * @param prevNextOutputIndex Next L2 output index before the deletion.
     * @param newNextOutputIndex  Next L2 output index after the deletion.
     */
    event OutputsDeleted(uint256 indexed prevNextOutputIndex, uint256 indexed newNextOutputIndex);

    /**
     * @custom:semver 1.0.0
     *
     * @param _submissionInterval  Interval in blocks at which checkpoints must be submitted.
     * @param _l2BlockTime         The time per L2 block, in seconds.
     * @param _startingBlockNumber The number of the first L2 block.
     * @param _startingTimestamp   The timestamp of the first L2 block.
     * @param _proposer            The address of the proposer.
     * @param _challenger          The address of the challenger.
     */
    constructor(
        uint256 _submissionInterval,
        uint256 _l2BlockTime,
        uint256 _startingBlockNumber,
        uint256 _startingTimestamp,
        address _proposer,
        address _challenger
    ) Semver(1, 0, 0) {
        SUBMISSION_INTERVAL = _submissionInterval;
        L2_BLOCK_TIME = _l2BlockTime;
        PROPOSER = _proposer;
        CHALLENGER = _challenger;

        initialize(_startingBlockNumber, _startingTimestamp);
    }

    /**
     * @notice Initializer.
     *
     * @param _startingBlockNumber Block number for the first recoded L2 block.
     * @param _startingTimestamp   Timestamp for the first recoded L2 block.
     */
    function initialize(uint256 _startingBlockNumber, uint256 _startingTimestamp)
        public
        initializer
    {
        require(
            _startingTimestamp <= block.timestamp,
            "L2OutputOracle: starting L2 timestamp must be less than current time"
        );

        startingTimestamp = _startingTimestamp;
        startingBlockNumber = _startingBlockNumber;
    }

    /**
     * @notice Deletes all output proposals after and including the proposal that corresponds to
     *         the given output index. Only the challenger address can delete outputs.
     *
     * @param _l2OutputIndex Index of the first L2 output to be deleted. All outputs after this
     *                       output will also be deleted.
     */
    // solhint-disable-next-line ordering
    function deleteL2Outputs(uint256 _l2OutputIndex) external {
        require(
            msg.sender == CHALLENGER,
            "L2OutputOracle: only the challenger address can delete outputs"
        );

        // Make sure we're not *increasing* the length of the array.
        require(
            _l2OutputIndex < l2Outputs.length,
            "L2OutputOracle: cannot delete outputs after the latest output index"
        );

        uint256 prevNextL2OutputIndex = nextOutputIndex();

        // Use assembly to delete the array elements because Solidity doesn't allow it.
        assembly {
            sstore(l2Outputs.slot, _l2OutputIndex)
        }

        emit OutputsDeleted(prevNextL2OutputIndex, _l2OutputIndex);
    }

    /**
     * @notice Accepts an outputRoot and the timestamp of the corresponding L2 block. The timestamp
     *         must be equal to the current value returned by `nextTimestamp()` in order to be
     *         accepted. This function may only be called by the Proposer.
     *
     * @param _outputRoot    The L2 output of the checkpoint block.
     * @param _l2BlockNumber The L2 block number that resulted in _outputRoot.
     * @param _l1BlockHash   A block hash which must be included in the current chain.
     * @param _l1BlockNumber The block number with the specified block hash.
     */
    function proposeL2Output(
        bytes32 _outputRoot,
        uint256 _l2BlockNumber,
        bytes32 _l1BlockHash,
        uint256 _l1BlockNumber
    ) external payable {
        require(
            msg.sender == PROPOSER,
            "L2OutputOracle: only the proposer address can propose new outputs"
        );

        require(
            _l2BlockNumber == nextBlockNumber(),
            "L2OutputOracle: block number must be equal to next expected block number"
        );

        require(
            computeL2Timestamp(_l2BlockNumber) < block.timestamp,
            "L2OutputOracle: cannot propose L2 output in the future"
        );

        require(
            _outputRoot != bytes32(0),
            "L2OutputOracle: L2 output proposal cannot be the zero hash"
        );

        if (_l1BlockHash != bytes32(0)) {
            // This check allows the proposer to propose an output based on a given L1 block,
            // without fear that it will be reorged out.
            // It will also revert if the blockheight provided is more than 256 blocks behind the
            // chain tip (as the hash will return as zero). This does open the door to a griefing
            // attack in which the proposer's submission is censored until the block is no longer
            // retrievable, if the proposer is experiencing this attack it can simply leave out the
            // blockhash value, and delay submission until it is confident that the L1 block is
            // finalized.
            require(
                blockhash(_l1BlockNumber) == _l1BlockHash,
                "L2OutputOracle: block hash does not match the hash at the expected height"
            );
        }

        emit OutputProposed(_outputRoot, nextOutputIndex(), _l2BlockNumber, block.timestamp);

        l2Outputs.push(
            Types.OutputProposal({
                outputRoot: _outputRoot,
                timestamp: uint128(block.timestamp),
                l2BlockNumber: uint128(_l2BlockNumber)
            })
        );
    }

    /**
     * @notice Returns an output by index. Exists because Solidity's array access will return a
     *         tuple instead of a struct.
     *
     * @param _l2OutputIndex Index of the output to return.
     *
     * @return The output at the given index.
     */
    function getL2Output(uint256 _l2OutputIndex)
        external
        view
        returns (Types.OutputProposal memory)
    {
        return l2Outputs[_l2OutputIndex];
    }

    /**
     * @notice Returns the index of the L2 output that checkpoints a given L2 block number. Uses a
     *         binary search to find the first output greater than or equal to the given block.
     *
     * @param _l2BlockNumber L2 block number to find a checkpoint for.
     *
     * @return Index of the first checkpoint that commits to the given L2 block number.
     */
    function getL2OutputIndexAfter(uint256 _l2BlockNumber) public view returns (uint256) {
        // Make sure an output for this block number has actually been proposed.
        require(
            _l2BlockNumber <= latestBlockNumber(),
            "L2OutputOracle: cannot get output for a block that has not been proposed"
        );

        // Make sure there's at least one output proposed.
        require(
            l2Outputs.length > 0,
            "L2OutputOracle: cannot get output as no outputs have been proposed yet"
        );

        // Find the output via binary search, guaranteed to exist.
        uint256 lo = 0;
        uint256 hi = l2Outputs.length;
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            if (l2Outputs[mid].l2BlockNumber < _l2BlockNumber) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        }

        return lo;
    }

    /**
     * @notice Returns the L2 output proposal that checkpoints a given L2 block number. Uses a
     *         binary search to find the first output greater than or equal to the given block.
     *
     * @param _l2BlockNumber L2 block number to find a checkpoint for.
     *
     * @return First checkpoint that commits to the given L2 block number.
     */
    function getL2OutputAfter(uint256 _l2BlockNumber)
        external
        view
        returns (Types.OutputProposal memory)
    {
        return l2Outputs[getL2OutputIndexAfter(_l2BlockNumber)];
    }

    /**
     * @notice Returns the number of outputs that have been proposed. Will revert if no outputs
     *         have been proposed yet.
     *
     * @return The number of outputs that have been proposed.
     */
    function latestOutputIndex() external view returns (uint256) {
        return l2Outputs.length - 1;
    }

    /**
     * @notice Returns the index of the next output to be proposed.
     *
     * @return The index of the next output to be proposed.
     */
    function nextOutputIndex() public view returns (uint256) {
        return l2Outputs.length;
    }

    /**
     * @notice Returns the block number of the latest submitted L2 output proposal. If no proposals
     *         been submitted yet then this function will return the starting block number.
     *
     * @return Latest submitted L2 block number.
     */
    function latestBlockNumber() public view returns (uint256) {
        return
            l2Outputs.length == 0
                ? startingBlockNumber
                : l2Outputs[l2Outputs.length - 1].l2BlockNumber;
    }

    /**
     * @notice Computes the block number of the next L2 block that needs to be checkpointed.
     *
     * @return Next L2 block number.
     */
    function nextBlockNumber() public view returns (uint256) {
        return latestBlockNumber() + SUBMISSION_INTERVAL;
    }

    /**
     * @notice Returns the L2 timestamp corresponding to a given L2 block number.
     *
     * @param _l2BlockNumber The L2 block number of the target block.
     *
     * @return L2 timestamp of the given block.
     */
    function computeL2Timestamp(uint256 _l2BlockNumber) public view returns (uint256) {
        return startingTimestamp + ((_l2BlockNumber - startingBlockNumber) * L2_BLOCK_TIME);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { SafeCall } from "../libraries/SafeCall.sol";
import { L2OutputOracle } from "./L2OutputOracle.sol";
import { Constants } from "../libraries/Constants.sol";
import { Types } from "../libraries/Types.sol";
import { Hashing } from "../libraries/Hashing.sol";
import { SecureMerkleTrie } from "../libraries/trie/SecureMerkleTrie.sol";
import { AddressAliasHelper } from "../vendor/AddressAliasHelper.sol";
import { ResourceMetering } from "./ResourceMetering.sol";
import { Semver } from "../universal/Semver.sol";

/**
 * @custom:proxied
 * @title OptimismPortal
 * @notice The OptimismPortal is a low-level contract responsible for passing messages between L1
 *         and L2. Messages sent directly to the OptimismPortal have no form of replayability.
 *         Users are encouraged to use the L1CrossDomainMessenger for a higher-level interface.
 */
contract OptimismPortal is Initializable, ResourceMetering, Semver {
    /**
     * @notice Represents a proven withdrawal.
     *
     * @custom:field outputRoot    Root of the L2 output this was proven against.
     * @custom:field timestamp     Timestamp at whcih the withdrawal was proven.
     * @custom:field l2OutputIndex Index of the output this was proven against.
     */
    struct ProvenWithdrawal {
        bytes32 outputRoot;
        uint128 timestamp;
        uint128 l2OutputIndex;
    }

    /**
     * @notice Version of the deposit event.
     */
    uint256 internal constant DEPOSIT_VERSION = 0;

    /**
     * @notice The L2 gas limit set when eth is deposited using the receive() function.
     */
    uint64 internal constant RECEIVE_DEFAULT_GAS_LIMIT = 100_000;

    /**
     * @notice Additional gas reserved for clean up after finalizing a transaction withdrawal.
     */
    uint256 internal constant FINALIZE_GAS_BUFFER = 20_000;

    /**
     * @notice Minimum time (in seconds) that must elapse before a withdrawal can be finalized.
     */
    uint256 public immutable FINALIZATION_PERIOD_SECONDS;

    /**
     * @notice Address of the L2OutputOracle.
     */
    L2OutputOracle public immutable L2_ORACLE;

    /**
     * @notice Address of the L2 account which initiated a withdrawal in this transaction. If the
     *         of this variable is the default L2 sender address, then we are NOT inside of a call
     *         to finalizeWithdrawalTransaction.
     */
    address public l2Sender;

    /**
     * @notice A list of withdrawal hashes which have been successfully finalized.
     */
    mapping(bytes32 => bool) public finalizedWithdrawals;

    /**
     * @notice A mapping of withdrawal hashes to `ProvenWithdrawal` data.
     */
    mapping(bytes32 => ProvenWithdrawal) public provenWithdrawals;

    /**
     * @notice Emitted when a transaction is deposited from L1 to L2. The parameters of this event
     *         are read by the rollup node and used to derive deposit transactions on L2.
     *
     * @param from       Address that triggered the deposit transaction.
     * @param to         Address that the deposit transaction is directed to.
     * @param version    Version of this deposit transaction event.
     * @param opaqueData ABI encoded deposit data to be parsed off-chain.
     */
    event TransactionDeposited(
        address indexed from,
        address indexed to,
        uint256 indexed version,
        bytes opaqueData
    );

    /**
     * @notice Emitted when a withdrawal transaction is proven.
     *
     * @param withdrawalHash Hash of the withdrawal transaction.
     */
    event WithdrawalProven(
        bytes32 indexed withdrawalHash,
        address indexed from,
        address indexed to
    );

    /**
     * @notice Emitted when a withdrawal transaction is finalized.
     *
     * @param withdrawalHash Hash of the withdrawal transaction.
     * @param success        Whether the withdrawal transaction was successful.
     */
    event WithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);

    /**
     * @custom:semver 1.0.0
     *
     * @param _l2Oracle                  Address of the L2OutputOracle contract.
     * @param _finalizationPeriodSeconds Output finalization time in seconds.
     */
    constructor(L2OutputOracle _l2Oracle, uint256 _finalizationPeriodSeconds) Semver(1, 0, 0) {
        L2_ORACLE = _l2Oracle;
        FINALIZATION_PERIOD_SECONDS = _finalizationPeriodSeconds;
        initialize();
    }

    /**
     * @notice Initializer.
     */
    function initialize() public initializer {
        l2Sender = Constants.DEFAULT_L2_SENDER;
        __ResourceMetering_init();
    }

    /**
     * @notice Accepts value so that users can send ETH directly to this contract and have the
     *         funds be deposited to their address on L2. This is intended as a convenience
     *         function for EOAs. Contracts should call the depositTransaction() function directly
     *         otherwise any deposited funds will be lost due to address aliasing.
     */
    // solhint-disable-next-line ordering
    receive() external payable {
        depositTransaction(msg.sender, msg.value, RECEIVE_DEFAULT_GAS_LIMIT, false, bytes(""));
    }

    /**
     * @notice Accepts ETH value without triggering a deposit to L2. This function mainly exists
     *         for the sake of the migration between the legacy Optimism system and Bedrock.
     */
    function donateETH() external payable {
        // Intentionally empty.
    }

    /**
     * @notice Proves a withdrawal transaction.
     *
     * @param _tx              Withdrawal transaction to finalize.
     * @param _l2OutputIndex   L2 output index to prove against.
     * @param _outputRootProof Inclusion proof of the L2ToL1MessagePasser contract's storage root.
     * @param _withdrawalProof Inclusion proof of the withdrawal in L2ToL1MessagePasser contract.
     */
    function proveWithdrawalTransaction(
        Types.WithdrawalTransaction memory _tx,
        uint256 _l2OutputIndex,
        Types.OutputRootProof calldata _outputRootProof,
        bytes[] calldata _withdrawalProof
    ) external {
        // Prevent users from creating a deposit transaction where this address is the message
        // sender on L2. Because this is checked here, we do not need to check again in
        // `finalizeWithdrawalTransaction`.
        require(
            _tx.target != address(this),
            "OptimismPortal: you cannot send messages to the portal contract"
        );

        // Get the output root and load onto the stack to prevent multiple mloads. This will
        // revert if there is no output root for the given block number.
        bytes32 outputRoot = L2_ORACLE.getL2Output(_l2OutputIndex).outputRoot;

        // Verify that the output root can be generated with the elements in the proof.
        require(
            outputRoot == Hashing.hashOutputRootProof(_outputRootProof),
            "OptimismPortal: invalid output root proof"
        );

        // Load the ProvenWithdrawal into memory, using the withdrawal hash as a unique identifier.
        bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
        ProvenWithdrawal memory provenWithdrawal = provenWithdrawals[withdrawalHash];

        // We generally want to prevent users from proving the same withdrawal multiple times
        // because each successive proof will update the timestamp. A malicious user can take
        // advantage of this to prevent other users from finalizing their withdrawal. However,
        // since withdrawals are proven before an output root is finalized, we need to allow users
        // to re-prove their withdrawal only in the case that the output root for their specified
        // output index has been updated.
        require(
            provenWithdrawal.timestamp == 0 ||
                (_l2OutputIndex == provenWithdrawal.l2OutputIndex &&
                    outputRoot != provenWithdrawal.outputRoot),
            "OptimismPortal: withdrawal hash has already been proven"
        );

        // Compute the storage slot of the withdrawal hash in the L2ToL1MessagePasser contract.
        // Refer to the Solidity documentation for more information on how storage layouts are
        // computed for mappings.
        bytes32 storageKey = keccak256(
            abi.encode(
                withdrawalHash,
                uint256(0) // The withdrawals mapping is at the first slot in the layout.
            )
        );

        // Verify that the hash of this withdrawal was stored in the L2toL1MessagePasser contract
        // on L2. If this is true, under the assumption that the SecureMerkleTrie does not have
        // bugs, then we know that this withdrawal was actually triggered on L2 and can therefore
        // be relayed on L1.
        require(
            SecureMerkleTrie.verifyInclusionProof(
                abi.encode(storageKey),
                hex"01",
                _withdrawalProof,
                _outputRootProof.messagePasserStorageRoot
            ),
            "OptimismPortal: invalid withdrawal inclusion proof"
        );

        // Designate the withdrawalHash as proven by storing the `outputRoot`, `timestamp`, and
        // `l2BlockNumber` in the `provenWithdrawals` mapping. A `withdrawalHash` can only be
        // proven once unless it is submitted again with a different outputRoot.
        provenWithdrawals[withdrawalHash] = ProvenWithdrawal({
            outputRoot: outputRoot,
            timestamp: uint128(block.timestamp),
            l2OutputIndex: uint128(_l2OutputIndex)
        });

        // Emit a `WithdrawalProven` event.
        emit WithdrawalProven(withdrawalHash, _tx.sender, _tx.target);
    }

    /**
     * @notice Finalizes a withdrawal transaction.
     *
     * @param _tx Withdrawal transaction to finalize.
     */
    function finalizeWithdrawalTransaction(Types.WithdrawalTransaction memory _tx) external {
        // Make sure that the l2Sender has not yet been set. The l2Sender is set to a value other
        // than the default value when a withdrawal transaction is being finalized. This check is
        // a defacto reentrancy guard.
        require(
            l2Sender == Constants.DEFAULT_L2_SENDER,
            "OptimismPortal: can only trigger one withdrawal per transaction"
        );

        // Grab the proven withdrawal from the `provenWithdrawals` map.
        bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
        ProvenWithdrawal memory provenWithdrawal = provenWithdrawals[withdrawalHash];

        // A withdrawal can only be finalized if it has been proven. We know that a withdrawal has
        // been proven at least once when its timestamp is non-zero. Unproven withdrawals will have
        // a timestamp of zero.
        require(
            provenWithdrawal.timestamp != 0,
            "OptimismPortal: withdrawal has not been proven yet"
        );

        // As a sanity check, we make sure that the proven withdrawal's timestamp is greater than
        // starting timestamp inside the L2OutputOracle. Not strictly necessary but extra layer of
        // safety against weird bugs in the proving step.
        require(
            provenWithdrawal.timestamp >= L2_ORACLE.startingTimestamp(),
            "OptimismPortal: withdrawal timestamp less than L2 Oracle starting timestamp"
        );

        // A proven withdrawal must wait at least the finalization period before it can be
        // finalized. This waiting period can elapse in parallel with the waiting period for the
        // output the withdrawal was proven against. In effect, this means that the minimum
        // withdrawal time is proposal submission time + finalization period.
        require(
            _isFinalizationPeriodElapsed(provenWithdrawal.timestamp),
            "OptimismPortal: proven withdrawal finalization period has not elapsed"
        );

        // Grab the OutputProposal from the L2OutputOracle, will revert if the output that
        // corresponds to the given index has not been proposed yet.
        Types.OutputProposal memory proposal = L2_ORACLE.getL2Output(
            provenWithdrawal.l2OutputIndex
        );

        // Check that the output root that was used to prove the withdrawal is the same as the
        // current output root for the given output index. An output root may change if it is
        // deleted by the challenger address and then re-proposed.
        require(
            proposal.outputRoot == provenWithdrawal.outputRoot,
            "OptimismPortal: output root proven is not the same as current output root"
        );

        // Check that the output proposal has also been finalized.
        require(
            _isFinalizationPeriodElapsed(proposal.timestamp),
            "OptimismPortal: output proposal finalization period has not elapsed"
        );

        // Check that this withdrawal has not already been finalized, this is replay protection.
        require(
            finalizedWithdrawals[withdrawalHash] == false,
            "OptimismPortal: withdrawal has already been finalized"
        );

        // Mark the withdrawal as finalized so it can't be replayed.
        finalizedWithdrawals[withdrawalHash] = true;

        // We want to maintain the property that the amount of gas supplied to the call to the
        // target contract is at least the gas limit specified by the user. We can do this by
        // enforcing that, at this point in time, we still have gaslimit + buffer gas available.
        require(
            gasleft() >= _tx.gasLimit + FINALIZE_GAS_BUFFER,
            "OptimismPortal: insufficient gas to finalize withdrawal"
        );

        // Set the l2Sender so contracts know who triggered this withdrawal on L2.
        l2Sender = _tx.sender;

        // Trigger the call to the target contract. We use SafeCall because we don't
        // care about the returndata and we don't want target contracts to be able to force this
        // call to run out of gas via a returndata bomb.
        bool success = SafeCall.call(
            _tx.target,
            gasleft() - FINALIZE_GAS_BUFFER,
            _tx.value,
            _tx.data
        );

        // Reset the l2Sender back to the default value.
        l2Sender = Constants.DEFAULT_L2_SENDER;

        // All withdrawals are immediately finalized. Replayability can
        // be achieved through contracts built on top of this contract
        emit WithdrawalFinalized(withdrawalHash, success);

        // Reverting here is useful for determining the exact gas cost to successfully execute the
        // sub call to the target contract if the minimum gas limit specified by the user would not
        // be sufficient to execute the sub call.
        if (success == false && tx.origin == Constants.ESTIMATION_ADDRESS) {
            revert("OptimismPortal: withdrawal failed");
        }
    }

    /**
     * @notice Accepts deposits of ETH and data, and emits a TransactionDeposited event for use in
     *         deriving deposit transactions. Note that if a deposit is made by a contract, its
     *         address will be aliased when retrieved using `tx.origin` or `msg.sender`. Consider
     *         using the CrossDomainMessenger contracts for a simpler developer experience.
     *
     * @param _to         Target address on L2.
     * @param _value      ETH value to send to the recipient.
     * @param _gasLimit   Minimum L2 gas limit (can be greater than or equal to this value).
     * @param _isCreation Whether or not the transaction is a contract creation.
     * @param _data       Data to trigger the recipient with.
     */
    function depositTransaction(
        address _to,
        uint256 _value,
        uint64 _gasLimit,
        bool _isCreation,
        bytes memory _data
    ) public payable metered(_gasLimit) {
        // Just to be safe, make sure that people specify address(0) as the target when doing
        // contract creations.
        if (_isCreation) {
            require(
                _to == address(0),
                "OptimismPortal: must send to address(0) when creating a contract"
            );
        }

        // Transform the from-address to its alias if the caller is a contract.
        address from = msg.sender;
        if (msg.sender != tx.origin) {
            from = AddressAliasHelper.applyL1ToL2Alias(msg.sender);
        }

        // Compute the opaque data that will be emitted as part of the TransactionDeposited event.
        // We use opaque data so that we can update the TransactionDeposited event in the future
        // without breaking the current interface.
        bytes memory opaqueData = abi.encodePacked(
            msg.value,
            _value,
            _gasLimit,
            _isCreation,
            _data
        );

        // Emit a TransactionDeposited event so that the rollup node can derive a deposit
        // transaction for this deposit.
        emit TransactionDeposited(from, _to, DEPOSIT_VERSION, opaqueData);
    }

    /**
     * @notice Determine if a given output is finalized. Reverts if the call to
     *         L2_ORACLE.getL2Output reverts. Returns a boolean otherwise.
     *
     * @param _l2OutputIndex Index of the L2 output to check.
     *
     * @return Whether or not the output is finalized.
     */
    function isOutputFinalized(uint256 _l2OutputIndex) external view returns (bool) {
        return _isFinalizationPeriodElapsed(L2_ORACLE.getL2Output(_l2OutputIndex).timestamp);
    }

    /**
     * @notice Determines whether the finalization period has elapsed w/r/t a given timestamp.
     *
     * @param _timestamp Timestamp to check.
     *
     * @return Whether or not the finalization period has elapsed.
     */
    function _isFinalizationPeriodElapsed(uint256 _timestamp) internal view returns (bool) {
        return block.timestamp > _timestamp + FINALIZATION_PERIOD_SECONDS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Burn } from "../libraries/Burn.sol";
import { Arithmetic } from "../libraries/Arithmetic.sol";

/**
 * @custom:upgradeable
 * @title ResourceMetering
 * @notice ResourceMetering implements an EIP-1559 style resource metering system where pricing
 *         updates automatically based on current demand.
 */
abstract contract ResourceMetering is Initializable {
    /**
     * @notice Represents the various parameters that control the way in which resources are
     *         metered. Corresponds to the EIP-1559 resource metering system.
     *
     * @custom:field prevBaseFee   Base fee from the previous block(s).
     * @custom:field prevBoughtGas Amount of gas bought so far in the current block.
     * @custom:field prevBlockNum  Last block number that the base fee was updated.
     */
    struct ResourceParams {
        uint128 prevBaseFee;
        uint64 prevBoughtGas;
        uint64 prevBlockNum;
    }

    /**
     * @notice Maximum amount of the resource that can be used within this block.
     */
    int256 public constant MAX_RESOURCE_LIMIT = 8_000_000;

    /**
     * @notice Along with the resource limit, determines the target resource limit.
     */
    int256 public constant ELASTICITY_MULTIPLIER = 4;

    /**
     * @notice Target amount of the resource that should be used within this block.
     */
    int256 public constant TARGET_RESOURCE_LIMIT = MAX_RESOURCE_LIMIT / ELASTICITY_MULTIPLIER;

    /**
     * @notice Denominator that determines max change on fee per block.
     */
    int256 public constant BASE_FEE_MAX_CHANGE_DENOMINATOR = 8;

    /**
     * @notice Minimum base fee value, cannot go lower than this.
     */
    int256 public constant MINIMUM_BASE_FEE = 10_000;

    /**
     * @notice Maximum base fee value, cannot go higher than this.
     */
    int256 public constant MAXIMUM_BASE_FEE = int256(uint256(type(uint128).max));

    /**
     * @notice Initial base fee value.
     */
    uint128 public constant INITIAL_BASE_FEE = 1_000_000_000;

    /**
     * @notice EIP-1559 style gas parameters.
     */
    ResourceParams public params;

    /**
     * @notice Reserve extra slots (to a total of 50) in the storage layout for future upgrades.
     */
    uint256[48] private __gap;

    /**
     * @notice Meters access to a function based an amount of a requested resource.
     *
     * @param _amount Amount of the resource requested.
     */
    modifier metered(uint64 _amount) {
        // Record initial gas amount so we can refund for it later.
        uint256 initialGas = gasleft();

        // Run the underlying function.
        _;

        // Update block number and base fee if necessary.
        uint256 blockDiff = block.number - params.prevBlockNum;
        if (blockDiff > 0) {
            // Handle updating EIP-1559 style gas parameters. We use EIP-1559 to restrict the rate
            // at which deposits can be created and therefore limit the potential for deposits to
            // spam the L2 system. Fee scheme is very similar to EIP-1559 with minor changes.
            int256 gasUsedDelta = int256(uint256(params.prevBoughtGas)) - TARGET_RESOURCE_LIMIT;
            int256 baseFeeDelta = (int256(uint256(params.prevBaseFee)) * gasUsedDelta) /
                TARGET_RESOURCE_LIMIT /
                BASE_FEE_MAX_CHANGE_DENOMINATOR;

            // Update base fee by adding the base fee delta and clamp the resulting value between
            // min and max.
            int256 newBaseFee = Arithmetic.clamp(
                int256(uint256(params.prevBaseFee)) + baseFeeDelta,
                MINIMUM_BASE_FEE,
                MAXIMUM_BASE_FEE
            );

            // If we skipped more than one block, we also need to account for every empty block.
            // Empty block means there was no demand for deposits in that block, so we should
            // reflect this lack of demand in the fee.
            if (blockDiff > 1) {
                // Update the base fee by repeatedly applying the exponent 1-(1/change_denominator)
                // blockDiff - 1 times. Simulates multiple empty blocks. Clamp the resulting value
                // between min and max.
                newBaseFee = Arithmetic.clamp(
                    Arithmetic.cdexp(
                        newBaseFee,
                        BASE_FEE_MAX_CHANGE_DENOMINATOR,
                        int256(blockDiff - 1)
                    ),
                    MINIMUM_BASE_FEE,
                    MAXIMUM_BASE_FEE
                );
            }

            // Update new base fee, reset bought gas, and update block number.
            params.prevBaseFee = uint128(uint256(newBaseFee));
            params.prevBoughtGas = 0;
            params.prevBlockNum = uint64(block.number);
        }

        // Make sure we can actually buy the resource amount requested by the user.
        params.prevBoughtGas += _amount;
        require(
            int256(uint256(params.prevBoughtGas)) <= MAX_RESOURCE_LIMIT,
            "ResourceMetering: cannot buy more gas than available gas limit"
        );

        // Determine the amount of ETH to be paid.
        uint256 resourceCost = _amount * params.prevBaseFee;

        // We currently charge for this ETH amount as an L1 gas burn, so we convert the ETH amount
        // into gas by dividing by the L1 base fee. We assume a minimum base fee of 1 gwei to avoid
        // division by zero for L1s that don't support 1559 or to avoid excessive gas burns during
        // periods of extremely low L1 demand. One-day average gas fee hasn't dipped below 1 gwei
        // during any 1 day period in the last 5 years, so should be fine.
        uint256 gasCost = resourceCost / Math.max(block.basefee, 1000000000);

        // Give the user a refund based on the amount of gas they used to do all of the work up to
        // this point. Since we're at the end of the modifier, this should be pretty accurate. Acts
        // effectively like a dynamic stipend (with a minimum value).
        uint256 usedGas = initialGas - gasleft();
        if (gasCost > usedGas) {
            Burn.gas(gasCost - usedGas);
        }
    }

    /**
     * @notice Sets initial resource parameter values. This function must either be called by the
     *         initializer function of an upgradeable child contract.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ResourceMetering_init() internal onlyInitializing {
        params = ResourceParams({
            prevBaseFee: INITIAL_BASE_FEE,
            prevBoughtGas: 0,
            prevBlockNum: uint64(block.number)
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import { FixedPointMathLib } from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

/**
 * @title Arithmetic
 * @notice Even more math than before.
 */
library Arithmetic {
    /**
     * @notice Clamps a value between a minimum and maximum.
     *
     * @param _value The value to clamp.
     * @param _min   The minimum value.
     * @param _max   The maximum value.
     *
     * @return The clamped value.
     */
    function clamp(
        int256 _value,
        int256 _min,
        int256 _max
    ) internal pure returns (int256) {
        return SignedMath.min(SignedMath.max(_value, _min), _max);
    }

    /**
     * @notice (c)oefficient (d)enominator (exp)onentiation function.
     *         Returns the result of: c * (1 - 1/d)^exp.
     *
     * @param _coefficient Coefficient of the function.
     * @param _denominator Fractional denominator.
     * @param _exponent    Power function exponent.
     *
     * @return Result of c * (1 - 1/d)^exp.
     */
    function cdexp(
        int256 _coefficient,
        int256 _denominator,
        int256 _exponent
    ) internal pure returns (int256) {
        return
            (_coefficient *
                (FixedPointMathLib.powWad(1e18 - (1e18 / _denominator), _exponent * 1e18))) / 1e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title Burn
 * @notice Utilities for burning stuff.
 */
library Burn {
    /**
     * Burns a given amount of ETH.
     *
     * @param _amount Amount of ETH to burn.
     */
    function eth(uint256 _amount) internal {
        new Burner{ value: _amount }();
    }

    /**
     * Burns a given amount of gas.
     *
     * @param _amount Amount of gas to burn.
     */
    function gas(uint256 _amount) internal view {
        uint256 i = 0;
        uint256 initialGas = gasleft();
        while (initialGas - gasleft() < _amount) {
            ++i;
        }
    }
}

/**
 * @title Burner
 * @notice Burner self-destructs on creation and sends all ETH to itself, removing all ETH given to
 *         the contract from the circulating supply. Self-destructing is the only way to remove ETH
 *         from the circulating supply.
 */
contract Burner {
    constructor() payable {
        selfdestruct(payable(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Bytes
 * @notice Bytes is a library for manipulating byte arrays.
 */
library Bytes {
    /**
     * @custom:attribution https://github.com/GNSPS/solidity-bytes-utils
     * @notice Slices a byte array with a given starting index and length. Returns a new byte array
     *         as opposed to a pointer to the original array. Will throw if trying to slice more
     *         bytes than exist in the array.
     *
     * @param _bytes Byte array to slice.
     * @param _start Starting index of the slice.
     * @param _length Length of the slice.
     *
     * @return Slice of the input byte array.
     */
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        unchecked {
            require(_length + 31 >= _length, "slice_overflow");
            require(_start + _length >= _start, "slice_overflow");
            require(_bytes.length >= _start + _length, "slice_outOfBounds");
        }

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /**
     * @notice Slices a byte array with a given starting index up to the end of the original byte
     *         array. Returns a new array rathern than a pointer to the original.
     *
     * @param _bytes Byte array to slice.
     * @param _start Starting index of the slice.
     *
     * @return Slice of the input byte array.
     */
    function slice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        if (_start >= _bytes.length) {
            return bytes("");
        }
        return slice(_bytes, _start, _bytes.length - _start);
    }

    /**
     * @notice Converts a byte array into a nibble array by splitting each byte into two nibbles.
     *         Resulting nibble array will be exactly twice as long as the input byte array.
     *
     * @param _bytes Input byte array to convert.
     *
     * @return Resulting nibble array.
     */
    function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        uint256 bytesLength = _bytes.length;
        bytes memory nibbles = new bytes(bytesLength * 2);
        bytes1 b;

        for (uint256 i = 0; i < bytesLength; ) {
            b = _bytes[i];
            nibbles[i * 2] = b >> 4;
            nibbles[i * 2 + 1] = b & 0x0f;
            unchecked {
                ++i;
            }
        }

        return nibbles;
    }

    /**
     * @notice Compares two byte arrays by comparing their keccak256 hashes.
     *
     * @param _bytes First byte array to compare.
     * @param _other Second byte array to compare.
     *
     * @return True if the two byte arrays are equal, false otherwise.
     */
    function equal(bytes memory _bytes, bytes memory _other) internal pure returns (bool) {
        return keccak256(_bytes) == keccak256(_other);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Constants
 * @notice Constants is a library for storing constants. Simple! Don't put everything in here, just
 *         the stuff used in multiple contracts. Constants that only apply to a single contract
 *         should be defined in that contract instead.
 */
library Constants {
    /**
     * @notice Special address to be used as the tx origin for gas estimation calls in the
     *         OptimismPortal and CrossDomainMessenger calls. You only need to use this address if
     *         the minimum gas limit specified by the user is not actually enough to execute the
     *         given message and you're attempting to estimate the actual necessary gas limit. We
     *         use address(1) because it's the ecrecover precompile and therefore guaranteed to
     *         never have any code on any EVM chain.
     */
    address internal constant ESTIMATION_ADDRESS = address(1);

    /**
     * @notice Value used for the L2 sender storage slot in both the OptimismPortal and the
     *         CrossDomainMessenger contracts before an actual sender is set. This value is
     *         non-zero to reduce the gas cost of message passing transactions.
     */
    address internal constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Types } from "./Types.sol";
import { Hashing } from "./Hashing.sol";
import { RLPWriter } from "./rlp/RLPWriter.sol";

/**
 * @title Encoding
 * @notice Encoding handles Optimism's various different encoding schemes.
 */
library Encoding {
    /**
     * @notice RLP encodes the L2 transaction that would be generated when a given deposit is sent
     *         to the L2 system. Useful for searching for a deposit in the L2 system. The
     *         transaction is prefixed with 0x7e to identify its EIP-2718 type.
     *
     * @param _tx User deposit transaction to encode.
     *
     * @return RLP encoded L2 deposit transaction.
     */
    function encodeDepositTransaction(Types.UserDepositTransaction memory _tx)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 source = Hashing.hashDepositSource(_tx.l1BlockHash, _tx.logIndex);
        bytes[] memory raw = new bytes[](8);
        raw[0] = RLPWriter.writeBytes(abi.encodePacked(source));
        raw[1] = RLPWriter.writeAddress(_tx.from);
        raw[2] = _tx.isCreation ? RLPWriter.writeBytes("") : RLPWriter.writeAddress(_tx.to);
        raw[3] = RLPWriter.writeUint(_tx.mint);
        raw[4] = RLPWriter.writeUint(_tx.value);
        raw[5] = RLPWriter.writeUint(uint256(_tx.gasLimit));
        raw[6] = RLPWriter.writeBool(false);
        raw[7] = RLPWriter.writeBytes(_tx.data);
        return abi.encodePacked(uint8(0x7e), RLPWriter.writeList(raw));
    }

    /**
     * @notice Encodes the cross domain message based on the version that is encoded into the
     *         message nonce.
     *
     * @param _nonce    Message nonce with version encoded into the first two bytes.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        (, uint16 version) = decodeVersionedNonce(_nonce);
        if (version == 0) {
            return encodeCrossDomainMessageV0(_target, _sender, _data, _nonce);
        } else if (version == 1) {
            return encodeCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
        } else {
            revert("Encoding: unknown cross domain message version");
        }
    }

    /**
     * @notice Encodes a cross domain message based on the V0 (legacy) encoding.
     *
     * @param _target Address of the target of the message.
     * @param _sender Address of the sender of the message.
     * @param _data   Data to send with the message.
     * @param _nonce  Message nonce.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessageV0(
        address _target,
        address _sender,
        bytes memory _data,
        uint256 _nonce
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(address,address,bytes,uint256)",
                _target,
                _sender,
                _data,
                _nonce
            );
    }

    /**
     * @notice Encodes a cross domain message based on the V1 (current) encoding.
     *
     * @param _nonce    Message nonce.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessageV1(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(uint256,address,address,uint256,uint256,bytes)",
                _nonce,
                _sender,
                _target,
                _value,
                _gasLimit,
                _data
            );
    }

    /**
     * @notice Adds a version number into the first two bytes of a message nonce.
     *
     * @param _nonce   Message nonce to encode into.
     * @param _version Version number to encode into the message nonce.
     *
     * @return Message nonce with version encoded into the first two bytes.
     */
    function encodeVersionedNonce(uint240 _nonce, uint16 _version) internal pure returns (uint256) {
        uint256 nonce;
        assembly {
            nonce := or(shl(240, _version), _nonce)
        }
        return nonce;
    }

    /**
     * @notice Pulls the version out of a version-encoded nonce.
     *
     * @param _nonce Message nonce with version encoded into the first two bytes.
     *
     * @return Nonce without encoded version.
     * @return Version of the message.
     */
    function decodeVersionedNonce(uint256 _nonce) internal pure returns (uint240, uint16) {
        uint240 nonce;
        uint16 version;
        assembly {
            nonce := and(_nonce, 0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            version := shr(240, _nonce)
        }
        return (nonce, version);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Types } from "./Types.sol";
import { Encoding } from "./Encoding.sol";

/**
 * @title Hashing
 * @notice Hashing handles Optimism's various different hashing schemes.
 */
library Hashing {
    /**
     * @notice Computes the hash of the RLP encoded L2 transaction that would be generated when a
     *         given deposit is sent to the L2 system. Useful for searching for a deposit in the L2
     *         system.
     *
     * @param _tx User deposit transaction to hash.
     *
     * @return Hash of the RLP encoded L2 deposit transaction.
     */
    function hashDepositTransaction(Types.UserDepositTransaction memory _tx)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(Encoding.encodeDepositTransaction(_tx));
    }

    /**
     * @notice Computes the deposit transaction's "source hash", a value that guarantees the hash
     *         of the L2 transaction that corresponds to a deposit is unique and is
     *         deterministically generated from L1 transaction data.
     *
     * @param _l1BlockHash Hash of the L1 block where the deposit was included.
     * @param _logIndex    The index of the log that created the deposit transaction.
     *
     * @return Hash of the deposit transaction's "source hash".
     */
    function hashDepositSource(bytes32 _l1BlockHash, uint256 _logIndex)
        internal
        pure
        returns (bytes32)
    {
        bytes32 depositId = keccak256(abi.encode(_l1BlockHash, _logIndex));
        return keccak256(abi.encode(bytes32(0), depositId));
    }

    /**
     * @notice Hashes the cross domain message based on the version that is encoded into the
     *         message nonce.
     *
     * @param _nonce    Message nonce with version encoded into the first two bytes.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes32) {
        (, uint16 version) = Encoding.decodeVersionedNonce(_nonce);
        if (version == 0) {
            return hashCrossDomainMessageV0(_target, _sender, _data, _nonce);
        } else if (version == 1) {
            return hashCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
        } else {
            revert("Hashing: unknown cross domain message version");
        }
    }

    /**
     * @notice Hashes a cross domain message based on the V0 (legacy) encoding.
     *
     * @param _target Address of the target of the message.
     * @param _sender Address of the sender of the message.
     * @param _data   Data to send with the message.
     * @param _nonce  Message nonce.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessageV0(
        address _target,
        address _sender,
        bytes memory _data,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return keccak256(Encoding.encodeCrossDomainMessageV0(_target, _sender, _data, _nonce));
    }

    /**
     * @notice Hashes a cross domain message based on the V1 (current) encoding.
     *
     * @param _nonce    Message nonce.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessageV1(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes32) {
        return
            keccak256(
                Encoding.encodeCrossDomainMessageV1(
                    _nonce,
                    _sender,
                    _target,
                    _value,
                    _gasLimit,
                    _data
                )
            );
    }

    /**
     * @notice Derives the withdrawal hash according to the encoding in the L2 Withdrawer contract
     *
     * @param _tx Withdrawal transaction to hash.
     *
     * @return Hashed withdrawal transaction.
     */
    function hashWithdrawal(Types.WithdrawalTransaction memory _tx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data)
            );
    }

    /**
     * @notice Hashes the various elements of an output root proof into an output root hash which
     *         can be used to check if the proof is valid.
     *
     * @param _outputRootProof Output root proof which should hash to an output root.
     *
     * @return Hashed output root proof.
     */
    function hashOutputRootProof(Types.OutputRootProof memory _outputRootProof)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _outputRootProof.version,
                    _outputRootProof.stateRoot,
                    _outputRootProof.messagePasserStorageRoot,
                    _outputRootProof.latestBlockhash
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Predeploys
 * @notice Contains constant addresses for contracts that are pre-deployed to the L2 system.
 */
library Predeploys {
    /**
     * @notice Address of the L2ToL1MessagePasser predeploy.
     */
    address internal constant L2_TO_L1_MESSAGE_PASSER = 0x4200000000000000000000000000000000000016;

    /**
     * @notice Address of the L2CrossDomainMessenger predeploy.
     */
    address internal constant L2_CROSS_DOMAIN_MESSENGER =
        0x4200000000000000000000000000000000000007;

    /**
     * @notice Address of the L2StandardBridge predeploy.
     */
    address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;

    /**
     * @notice Address of the L2ERC721Bridge predeploy.
     */
    address internal constant L2_ERC721_BRIDGE = 0x4200000000000000000000000000000000000014;

    /**
     * @notice Address of the SequencerFeeWallet predeploy.
     */
    address internal constant SEQUENCER_FEE_WALLET = 0x4200000000000000000000000000000000000011;

    /**
     * @notice Address of the OptimismMintableERC20Factory predeploy.
     */
    address internal constant OPTIMISM_MINTABLE_ERC20_FACTORY =
        0x4200000000000000000000000000000000000012;

    /**
     * @notice Address of the OptimismMintableERC721Factory predeploy.
     */
    address internal constant OPTIMISM_MINTABLE_ERC721_FACTORY =
        0x4200000000000000000000000000000000000017;

    /**
     * @notice Address of the L1Block predeploy.
     */
    address internal constant L1_BLOCK_ATTRIBUTES = 0x4200000000000000000000000000000000000015;

    /**
     * @notice Address of the GasPriceOracle predeploy. Includes fee information
     *         and helpers for computing the L1 portion of the transaction fee.
     */
    address internal constant GAS_PRICE_ORACLE = 0x420000000000000000000000000000000000000F;

    /**
     * @custom:legacy
     * @notice Address of the L1MessageSender predeploy. Deprecated. Use L2CrossDomainMessenger
     *         or access tx.origin (or msg.sender) in a L1 to L2 transaction instead.
     */
    address internal constant L1_MESSAGE_SENDER = 0x4200000000000000000000000000000000000001;

    /**
     * @custom:legacy
     * @notice Address of the DeployerWhitelist predeploy. No longer active.
     */
    address internal constant DEPLOYER_WHITELIST = 0x4200000000000000000000000000000000000002;

    /**
     * @custom:legacy
     * @notice Address of the LegacyERC20ETH predeploy. Deprecated. Balances are migrated to the
     *         state trie as of the Bedrock upgrade. Contract has been locked and write functions
     *         can no longer be accessed.
     */
    address internal constant LEGACY_ERC20_ETH = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    /**
     * @custom:legacy
     * @notice Address of the L1BlockNumber predeploy. Deprecated. Use the L1Block predeploy
     *         instead, which exposes more information about the L1 state.
     */
    address internal constant L1_BLOCK_NUMBER = 0x4200000000000000000000000000000000000013;

    /**
     * @custom:legacy
     * @notice Address of the LegacyMessagePasser predeploy. Deprecate. Use the updated
     *         L2ToL1MessagePasser contract instead.
     */
    address internal constant LEGACY_MESSAGE_PASSER = 0x4200000000000000000000000000000000000000;

    /**
     * @notice Address of the ProxyAdmin predeploy.
     */
    address internal constant PROXY_ADMIN = 0x4200000000000000000000000000000000000018;

    /**
     * @notice Address of the BaseFeeVault predeploy.
     */
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;

    /**
     * @notice Address of the L1FeeVault predeploy.
     */
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title SafeCall
 * @notice Perform low level safe calls
 */
library SafeCall {
    /**
     * @notice Perform a low level call without copying any returndata
     *
     * @param _target   Address to call
     * @param _gas      Amount of gas to pass to the call
     * @param _value    Amount of value to pass to the call
     * @param _calldata Calldata to pass to the call
     */
    function call(
        address _target,
        uint256 _gas,
        uint256 _value,
        bytes memory _calldata
    ) internal returns (bool) {
        bool _success;
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
        }
        return _success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Types
 * @notice Contains various types used throughout the Optimism contract system.
 */
library Types {
    /**
     * @notice OutputProposal represents a commitment to the L2 state. The timestamp is the L1
     *         timestamp that the output root is posted. This timestamp is used to verify that the
     *         finalization period has passed since the output root was submitted.
     *
     * @custom:field outputRoot    Hash of the L2 output.
     * @custom:field timestamp     Timestamp of the L1 block that the output root was submitted in.
     * @custom:field l2BlockNumber L2 block number that the output corresponds to.
     */
    struct OutputProposal {
        bytes32 outputRoot;
        uint128 timestamp;
        uint128 l2BlockNumber;
    }

    /**
     * @notice Struct representing the elements that are hashed together to generate an output root
     *         which itself represents a snapshot of the L2 state.
     *
     * @custom:field version                  Version of the output root.
     * @custom:field stateRoot                Root of the state trie at the block of this output.
     * @custom:field messagePasserStorageRoot Root of the message passer storage trie.
     * @custom:field latestBlockhash          Hash of the block this output was generated from.
     */
    struct OutputRootProof {
        bytes32 version;
        bytes32 stateRoot;
        bytes32 messagePasserStorageRoot;
        bytes32 latestBlockhash;
    }

    /**
     * @notice Struct representing a deposit transaction (L1 => L2 transaction) created by an end
     *         user (as opposed to a system deposit transaction generated by the system).
     *
     * @custom:field from        Address of the sender of the transaction.
     * @custom:field to          Address of the recipient of the transaction.
     * @custom:field isCreation  True if the transaction is a contract creation.
     * @custom:field value       Value to send to the recipient.
     * @custom:field mint        Amount of ETH to mint.
     * @custom:field gasLimit    Gas limit of the transaction.
     * @custom:field data        Data of the transaction.
     * @custom:field l1BlockHash Hash of the block the transaction was submitted in.
     * @custom:field logIndex    Index of the log in the block the transaction was submitted in.
     */
    struct UserDepositTransaction {
        address from;
        address to;
        bool isCreation;
        uint256 value;
        uint256 mint;
        uint64 gasLimit;
        bytes data;
        bytes32 l1BlockHash;
        uint256 logIndex;
    }

    /**
     * @notice Struct representing a withdrawal transaction.
     *
     * @custom:field nonce    Nonce of the withdrawal transaction
     * @custom:field sender   Address of the sender of the transaction.
     * @custom:field target   Address of the recipient of the transaction.
     * @custom:field value    Value to send to the recipient.
     * @custom:field gasLimit Gas limit of the transaction.
     * @custom:field data     Data of the transaction.
     */
    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @custom:attribution https://github.com/hamdiallam/Solidity-RLP
 * @title RLPReader
 * @notice RLPReader is a library for parsing RLP-encoded byte arrays into Solidity types. Adapted
 *         from Solidity-RLP (https://github.com/hamdiallam/Solidity-RLP) by Hamdi Allam with
 *         various tweaks to improve readability.
 */
library RLPReader {
    /**
     * Custom pointer type to avoid confusion between pointers and uint256s.
     */
    type MemoryPointer is uint256;

    /**
     * @notice RLP item types.
     *
     * @custom:value DATA_ITEM Represents an RLP data item (NOT a list).
     * @custom:value LIST_ITEM Represents an RLP list item.
     */
    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /**
     * @notice Struct representing an RLP item.
     *
     * @custom:field length Length of the RLP item.
     * @custom:field ptr    Pointer to the RLP item in memory.
     */
    struct RLPItem {
        uint256 length;
        MemoryPointer ptr;
    }

    /**
     * @notice Max list length that this library will accept.
     */
    uint256 internal constant MAX_LIST_LENGTH = 32;

    /**
     * @notice Converts bytes to a reference to memory position and length.
     *
     * @param _in Input bytes to convert.
     *
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        // Empty arrays are not RLP items.
        require(
            _in.length > 0,
            "RLPReader: length of an RLP item must be greater than zero to be decodable"
        );

        MemoryPointer ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({ length: _in.length, ptr: ptr });
    }

    /**
     * @notice Reads an RLP list value into a list of RLP items.
     *
     * @param _in RLP list value.
     *
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset, uint256 listLength, RLPItemType itemType) = _decodeLength(_in);

        require(
            itemType == RLPItemType.LIST_ITEM,
            "RLPReader: decoded item type for list is not a list item"
        );

        require(
            listOffset + listLength == _in.length,
            "RLPReader: list item has an invalid data remainder"
        );

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
                RLPItem({
                    length: _in.length - offset,
                    ptr: MemoryPointer.wrap(MemoryPointer.unwrap(_in.ptr) + offset)
                })
            );

            // We don't need to check itemCount < out.length explicitly because Solidity already
            // handles this check on our behalf, we'd just be wasting gas.
            out[itemCount] = RLPItem({
                length: itemLength + itemOffset,
                ptr: MemoryPointer.wrap(MemoryPointer.unwrap(_in.ptr) + offset)
            });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * @notice Reads an RLP list value into a list of RLP items.
     *
     * @param _in RLP list value.
     *
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * @notice Reads an RLP bytes value into bytes.
     *
     * @param _in RLP bytes value.
     *
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "RLPReader: decoded item type for bytes is not a data item"
        );

        require(
            _in.length == itemOffset + itemLength,
            "RLPReader: bytes value contains an invalid remainder"
        );

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * @notice Reads an RLP bytes value into bytes.
     *
     * @param _in RLP bytes value.
     *
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * @notice Reads the raw bytes of an RLP item.
     *
     * @param _in RLP item to read.
     *
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }

    /**
     * @notice Decodes the length of an RLP item.
     *
     * @param _in RLP item to decode.
     *
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        // Short-circuit if there's nothing to decode, note that we perform this check when
        // the user creates an RLP item via toRLPItem, but it's always possible for them to bypass
        // that function and create an RLP item directly. So we need to check this anyway.
        require(
            _in.length > 0,
            "RLPReader: length of an RLP item must be greater than zero to be decodable"
        );

        MemoryPointer ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.
            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            // slither-disable-next-line variable-scope
            uint256 strLen = prefix - 0x80;

            require(
                _in.length > strLen,
                "RLPReader: length of content must be greater than string length (short string)"
            );

            bytes1 firstByteOfContent;
            assembly {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                strLen != 1 || firstByteOfContent >= 0x80,
                "RLPReader: invalid prefix, single byte < 0x80 are not prefixed (short string)"
            );

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(
                _in.length > lenOfStrLen,
                "RLPReader: length of content must be > than length of string length (long string)"
            );

            bytes1 firstByteOfContent;
            assembly {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                firstByteOfContent != 0x00,
                "RLPReader: length of content must not have any leading zeros (long string)"
            );

            uint256 strLen;
            assembly {
                strLen := shr(sub(256, mul(8, lenOfStrLen)), mload(add(ptr, 1)))
            }

            require(
                strLen > 55,
                "RLPReader: length of content must be greater than 55 bytes (long string)"
            );

            require(
                _in.length > lenOfStrLen + strLen,
                "RLPReader: length of content must be greater than total length (long string)"
            );

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            // slither-disable-next-line variable-scope
            uint256 listLen = prefix - 0xc0;

            require(
                _in.length > listLen,
                "RLPReader: length of content must be greater than list length (short list)"
            );

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(
                _in.length > lenOfListLen,
                "RLPReader: length of content must be > than length of list length (long list)"
            );

            bytes1 firstByteOfContent;
            assembly {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                firstByteOfContent != 0x00,
                "RLPReader: length of content must not have any leading zeros (long list)"
            );

            uint256 listLen;
            assembly {
                listLen := shr(sub(256, mul(8, lenOfListLen)), mload(add(ptr, 1)))
            }

            require(
                listLen > 55,
                "RLPReader: length of content must be greater than 55 bytes (long list)"
            );

            require(
                _in.length > lenOfListLen + listLen,
                "RLPReader: length of content must be greater than total length (long list)"
            );

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * @notice Copies the bytes from a memory location.
     *
     * @param _src    Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     *
     * @return Copied bytes.
     */
    function _copy(
        MemoryPointer _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (_length == 0) {
            return out;
        }

        // Mostly based on Solidity's copy_memory_to_memory:
        // solhint-disable max-line-length
        // https://github.com/ethereum/solidity/blob/34dd30d71b4da730488be72ff6af7083cf2a91f6/libsolidity/codegen/YulUtilFunctions.cpp#L102-L114
        uint256 src = MemoryPointer.unwrap(_src) + _offset;
        assembly {
            let dest := add(out, 32)
            let i := 0
            for {

            } lt(i, _length) {
                i := add(i, 32)
            } {
                mstore(add(dest, i), mload(add(src, i)))
            }

            if gt(i, _length) {
                mstore(add(dest, _length), 0)
            }
        }

        return out;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:attribution https://github.com/bakaoh/solidity-rlp-encode
 * @title RLPWriter
 * @author RLPWriter is a library for encoding Solidity types to RLP bytes. Adapted from Bakaoh's
 *         RLPEncode library (https://github.com/bakaoh/solidity-rlp-encode) with minor
 *         modifications to improve legibility.
 */
library RLPWriter {
    /**
     * @notice RLP encodes a byte string.
     *
     * @param _in The byte string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * @notice RLP encodes a list of RLP encoded byte byte strings.
     *
     * @param _in The list of RLP encoded byte strings.
     *
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * @notice RLP encodes a string.
     *
     * @param _in The string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * @notice RLP encodes an address.
     *
     * @param _in The address to encode.
     *
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * @notice RLP encodes a uint.
     *
     * @param _in The uint256 to encode.
     *
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * @notice RLP encodes a bool.
     *
     * @param _in The bool to encode.
     *
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /**
     * @notice Encode the first byte and then the `len` in binary form if `length` is more than 55.
     *
     * @param _len    The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     *
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * @notice Encode integer in big endian binary form with no leading zeroes.
     *
     * @param _x The integer to encode.
     *
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * @custom:attribution https://github.com/Arachnid/solidity-stringutils
     * @notice Copies a piece of memory to another location.
     *
     * @param _dest Destination location.
     * @param _src  Source location.
     * @param _len  Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @custom:attribution https://github.com/sammayo/solidity-rlp-encoder
     * @notice Flattens a list of byte strings into one byte string.
     *
     * @param _list List of byte strings to flatten.
     *
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Bytes } from "../Bytes.sol";
import { RLPReader } from "../rlp/RLPReader.sol";

/**
 * @title MerkleTrie
 * @notice MerkleTrie is a small library for verifying standard Ethereum Merkle-Patricia trie
 *         inclusion proofs. By default, this library assumes a hexary trie. One can change the
 *         trie radix constant to support other trie radixes.
 */
library MerkleTrie {
    /**
     * @notice Struct representing a node in the trie.
     *
     * @custom:field encoded The RLP-encoded node.
     * @custom:field decoded The RLP-decoded node.
     */
    struct TrieNode {
        bytes encoded;
        RLPReader.RLPItem[] decoded;
    }

    /**
     * @notice Determines the number of elements per branch node.
     */
    uint256 internal constant TREE_RADIX = 16;

    /**
     * @notice Branch nodes have TREE_RADIX elements and one value element.
     */
    uint256 internal constant BRANCH_NODE_LENGTH = TREE_RADIX + 1;

    /**
     * @notice Leaf nodes and extension nodes have two elements, a `path` and a `value`.
     */
    uint256 internal constant LEAF_OR_EXTENSION_NODE_LENGTH = 2;

    /**
     * @notice Prefix for even-nibbled extension node paths.
     */
    uint8 internal constant PREFIX_EXTENSION_EVEN = 0;

    /**
     * @notice Prefix for odd-nibbled extension node paths.
     */
    uint8 internal constant PREFIX_EXTENSION_ODD = 1;

    /**
     * @notice Prefix for even-nibbled leaf node paths.
     */
    uint8 internal constant PREFIX_LEAF_EVEN = 2;

    /**
     * @notice Prefix for odd-nibbled leaf node paths.
     */
    uint8 internal constant PREFIX_LEAF_ODD = 3;

    /**
     * @notice Verifies a proof that a given key/value pair is present in the trie.
     *
     * @param _key   Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike traditional Merkle
     *               trees, this proof is executed top-down and consists of a list of RLP-encoded
     *               nodes that make a path down to the target node.
     * @param _root  Known root of the Merkle trie. Used to verify that the included proof is
     *               correctly constructed.
     *
     * @return Whether or not the proof is valid.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes[] memory _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        return Bytes.equal(_value, get(_key, _proof, _root));
    }

    /**
     * @notice Retrieves the value associated with a given key.
     *
     * @param _key   Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root  Known root of the Merkle trie.
     *
     * @return Value of the key if it exists.
     */
    function get(
        bytes memory _key,
        bytes[] memory _proof,
        bytes32 _root
    ) internal pure returns (bytes memory) {
        require(_key.length > 0, "MerkleTrie: empty key");

        TrieNode[] memory proof = _parseProof(_proof);
        bytes memory key = Bytes.toNibbles(_key);
        bytes memory currentNodeID = abi.encodePacked(_root);
        uint256 currentKeyIndex = 0;

        // Proof is top-down, so we start at the first element (root).
        for (uint256 i = 0; i < proof.length; i++) {
            TrieNode memory currentNode = proof[i];

            // Key index should never exceed total key length or we'll be out of bounds.
            require(
                currentKeyIndex <= key.length,
                "MerkleTrie: key index exceeds total key length"
            );

            if (currentKeyIndex == 0) {
                // First proof element is always the root node.
                require(
                    Bytes.equal(abi.encodePacked(keccak256(currentNode.encoded)), currentNodeID),
                    "MerkleTrie: invalid root hash"
                );
            } else if (currentNode.encoded.length >= 32) {
                // Nodes 32 bytes or larger are hashed inside branch nodes.
                require(
                    Bytes.equal(abi.encodePacked(keccak256(currentNode.encoded)), currentNodeID),
                    "MerkleTrie: invalid large internal hash"
                );
            } else {
                // Nodes smaller than 32 bytes aren't hashed.
                require(
                    Bytes.equal(currentNode.encoded, currentNodeID),
                    "MerkleTrie: invalid internal node hash"
                );
            }

            if (currentNode.decoded.length == BRANCH_NODE_LENGTH) {
                if (currentKeyIndex == key.length) {
                    // Value is the last element of the decoded list (for branch nodes). There's
                    // some ambiguity in the Merkle trie specification because bytes(0) is a
                    // valid value to place into the trie, but for branch nodes bytes(0) can exist
                    // even when the value wasn't explicitly placed there. Geth treats a value of
                    // bytes(0) as "key does not exist" and so we do the same.
                    bytes memory value = RLPReader.readBytes(currentNode.decoded[TREE_RADIX]);
                    require(
                        value.length > 0,
                        "MerkleTrie: value length must be greater than zero (branch)"
                    );

                    // Extra proof elements are not allowed.
                    require(
                        i == proof.length - 1,
                        "MerkleTrie: value node must be last node in proof (branch)"
                    );

                    return value;
                } else {
                    // We're not at the end of the key yet.
                    // Figure out what the next node ID should be and continue.
                    uint8 branchKey = uint8(key[currentKeyIndex]);
                    RLPReader.RLPItem memory nextNode = currentNode.decoded[branchKey];
                    currentNodeID = _getNodeID(nextNode);
                    currentKeyIndex += 1;
                }
            } else if (currentNode.decoded.length == LEAF_OR_EXTENSION_NODE_LENGTH) {
                bytes memory path = _getNodePath(currentNode);
                uint8 prefix = uint8(path[0]);
                uint8 offset = 2 - (prefix % 2);
                bytes memory pathRemainder = Bytes.slice(path, offset);
                bytes memory keyRemainder = Bytes.slice(key, currentKeyIndex);
                uint256 sharedNibbleLength = _getSharedNibbleLength(pathRemainder, keyRemainder);

                // Whether this is a leaf node or an extension node, the path remainder MUST be a
                // prefix of the key remainder (or be equal to the key remainder) or the proof is
                // considered invalid.
                require(
                    pathRemainder.length == sharedNibbleLength,
                    "MerkleTrie: path remainder must share all nibbles with key"
                );

                if (prefix == PREFIX_LEAF_EVEN || prefix == PREFIX_LEAF_ODD) {
                    // Prefix of 2 or 3 means this is a leaf node. For the leaf node to be valid,
                    // the key remainder must be exactly equal to the path remainder. We already
                    // did the necessary byte comparison, so it's more efficient here to check that
                    // the key remainder length equals the shared nibble length, which implies
                    // equality with the path remainder (since we already did the same check with
                    // the path remainder and the shared nibble length).
                    require(
                        keyRemainder.length == sharedNibbleLength,
                        "MerkleTrie: key remainder must be identical to path remainder"
                    );

                    // Our Merkle Trie is designed specifically for the purposes of the Ethereum
                    // state trie. Empty values are not allowed in the state trie, so we can safely
                    // say that if the value is empty, the key should not exist and the proof is
                    // invalid.
                    bytes memory value = RLPReader.readBytes(currentNode.decoded[1]);
                    require(
                        value.length > 0,
                        "MerkleTrie: value length must be greater than zero (leaf)"
                    );

                    // Extra proof elements are not allowed.
                    require(
                        i == proof.length - 1,
                        "MerkleTrie: value node must be last node in proof (leaf)"
                    );

                    return value;
                } else if (prefix == PREFIX_EXTENSION_EVEN || prefix == PREFIX_EXTENSION_ODD) {
                    // Prefix of 0 or 1 means this is an extension node. We move onto the next node
                    // in the proof and increment the key index by the length of the path remainder
                    // which is equal to the shared nibble length.
                    currentNodeID = _getNodeID(currentNode.decoded[1]);
                    currentKeyIndex += sharedNibbleLength;
                } else {
                    revert("MerkleTrie: received a node with an unknown prefix");
                }
            } else {
                revert("MerkleTrie: received an unparseable node");
            }
        }

        revert("MerkleTrie: ran out of proof elements");
    }

    /**
     * @notice Parses an array of proof elements into a new array that contains both the original
     *         encoded element and the RLP-decoded element.
     *
     * @param _proof Array of proof elements to parse.
     *
     * @return Proof parsed into easily accessible structs.
     */
    function _parseProof(bytes[] memory _proof) private pure returns (TrieNode[] memory) {
        uint256 length = _proof.length;
        TrieNode[] memory proof = new TrieNode[](length);
        for (uint256 i = 0; i < length; ) {
            proof[i] = TrieNode({ encoded: _proof[i], decoded: RLPReader.readList(_proof[i]) });
            unchecked {
                ++i;
            }
        }
        return proof;
    }

    /**
     * @notice Picks out the ID for a node. Node ID is referred to as the "hash" within the
     *         specification, but nodes < 32 bytes are not actually hashed.
     *
     * @param _node Node to pull an ID for.
     *
     * @return ID for the node, depending on the size of its contents.
     */
    function _getNodeID(RLPReader.RLPItem memory _node) private pure returns (bytes memory) {
        return _node.length < 32 ? RLPReader.readRawBytes(_node) : RLPReader.readBytes(_node);
    }

    /**
     * @notice Gets the path for a leaf or extension node.
     *
     * @param _node Node to get a path for.
     *
     * @return Node path, converted to an array of nibbles.
     */
    function _getNodePath(TrieNode memory _node) private pure returns (bytes memory) {
        return Bytes.toNibbles(RLPReader.readBytes(_node.decoded[0]));
    }

    /**
     * @notice Utility; determines the number of nibbles shared between two nibble arrays.
     *
     * @param _a First nibble array.
     * @param _b Second nibble array.
     *
     * @return Number of shared nibbles.
     */
    function _getSharedNibbleLength(bytes memory _a, bytes memory _b)
        private
        pure
        returns (uint256)
    {
        uint256 shared;
        uint256 max = (_a.length < _b.length) ? _a.length : _b.length;
        for (; shared < max && _a[shared] == _b[shared]; ) {
            unchecked {
                ++shared;
            }
        }
        return shared;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Library Imports */
import { MerkleTrie } from "./MerkleTrie.sol";

/**
 * @title SecureMerkleTrie
 * @notice SecureMerkleTrie is a thin wrapper around the MerkleTrie library that hashes the input
 *         keys. Ethereum's state trie hashes input keys before storing them.
 */
library SecureMerkleTrie {
    /**
     * @notice Verifies a proof that a given key/value pair is present in the Merkle trie.
     *
     * @param _key   Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike traditional Merkle
     *               trees, this proof is executed top-down and consists of a list of RLP-encoded
     *               nodes that make a path down to the target node.
     * @param _root  Known root of the Merkle trie. Used to verify that the included proof is
     *               correctly constructed.
     *
     * @return Whether or not the proof is valid.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes[] memory _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        bytes memory key = _getSecureKey(_key);
        return MerkleTrie.verifyInclusionProof(key, _value, _proof, _root);
    }

    /**
     * @notice Retrieves the value associated with a given key.
     *
     * @param _key   Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root  Known root of the Merkle trie.
     *
     * @return Value of the key if it exists.
     */
    function get(
        bytes memory _key,
        bytes[] memory _proof,
        bytes32 _root
    ) internal pure returns (bytes memory) {
        bytes memory key = _getSecureKey(_key);
        return MerkleTrie.get(key, _proof, _root);
    }

    /**
     * @notice Computes the hashed version of the input key.
     *
     * @param _key Key to hash.
     *
     * @return Hashed version of the key.
     */
    function _getSecureKey(bytes memory _key) private pure returns (bytes memory) {
        return abi.encodePacked(keccak256(_key));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeCall } from "../libraries/SafeCall.sol";
import { Hashing } from "../libraries/Hashing.sol";
import { Encoding } from "../libraries/Encoding.sol";
import { Constants } from "../libraries/Constants.sol";

/**
 * @custom:legacy
 * @title CrossDomainMessengerLegacySpacer
 * @notice Contract only exists to add a spacer to the CrossDomainMessenger where the
 *         libAddressManager variable used to exist. Must be the first contract in the inheritance
 *         tree of the CrossDomainMessenger
 */
contract CrossDomainMessengerLegacySpacer {
    /**
     * @custom:legacy
     * @custom:spacer libAddressManager
     * @notice Spacer for backwards compatibility.
     */
    address private spacer_0_0_20;
}

/**
 * @custom:upgradeable
 * @title CrossDomainMessenger
 * @notice CrossDomainMessenger is a base contract that provides the core logic for the L1 and L2
 *         cross-chain messenger contracts. It's designed to be a universal interface that only
 *         needs to be extended slightly to provide low-level message passing functionality on each
 *         chain it's deployed on. Currently only designed for message passing between two paired
 *         chains and does not support one-to-many interactions.
 */
abstract contract CrossDomainMessenger is
    CrossDomainMessengerLegacySpacer,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice Current message version identifier.
     */
    uint16 public constant MESSAGE_VERSION = 1;

    /**
     * @notice Constant overhead added to the base gas for a message.
     */
    uint64 public constant MIN_GAS_CONSTANT_OVERHEAD = 200_000;

    /**
     * @notice Numerator for dynamic overhead added to the base gas for a message.
     */
    uint64 public constant MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR = 1016;

    /**
     * @notice Denominator for dynamic overhead added to the base gas for a message.
     */
    uint64 public constant MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR = 1000;

    /**
     * @notice Extra gas added to base gas for each byte of calldata in a message.
     */
    uint64 public constant MIN_GAS_CALLDATA_OVERHEAD = 16;

    /**
     * @notice Minimum amount of gas required to relay a message.
     */
    uint256 internal constant RELAY_GAS_REQUIRED = 45_000;

    /**
     * @notice Amount of gas held in reserve to guarantee that relay execution completes.
     */
    uint256 internal constant RELAY_GAS_BUFFER = RELAY_GAS_REQUIRED - 5000;

    /**
     * @notice Address of the paired CrossDomainMessenger contract on the other chain.
     */
    address public immutable OTHER_MESSENGER;

    /**
     * @custom:legacy
     * @custom:spacer blockedMessages
     * @notice Spacer for backwards compatibility.
     */
    mapping(bytes32 => bool) private spacer_201_0_32;

    /**
     * @custom:legacy
     * @custom:spacer relayedMessages
     * @notice Spacer for backwards compatibility.
     */
    mapping(bytes32 => bool) private spacer_202_0_32;

    /**
     * @notice Mapping of message hashes to boolean receipt values. Note that a message will only
     *         be present in this mapping if it has successfully been relayed on this chain, and
     *         can therefore not be relayed again.
     */
    mapping(bytes32 => bool) public successfulMessages;

    /**
     * @notice Address of the sender of the currently executing message on the other chain. If the
     *         value of this variable is the default value (0x00000000...dead) then no message is
     *         currently being executed. Use the xDomainMessageSender getter which will throw an
     *         error if this is the case.
     */
    address internal xDomainMsgSender;

    /**
     * @notice Nonce for the next message to be sent, without the message version applied. Use the
     *         messageNonce getter which will insert the message version into the nonce to give you
     *         the actual nonce to be used for the message.
     */
    uint240 internal msgNonce;

    /**
     * @notice Mapping of message hashes to a boolean if and only if the message has failed to be
     *         executed at least once. A message will not be present in this mapping if it
     *         successfully executed on the first attempt.
     */
    mapping(bytes32 => bool) public failedMessages;

    /**
     * @notice Reserve extra slots in the storage layout for future upgrades.
     *         A gap size of 41 was chosen here, so that the first slot used in a child contract
     *         would be a multiple of 50.
     */
    uint256[42] private __gap;

    /**
     * @notice Emitted whenever a message is sent to the other chain.
     *
     * @param target       Address of the recipient of the message.
     * @param sender       Address of the sender of the message.
     * @param message      Message to trigger the recipient address with.
     * @param messageNonce Unique nonce attached to the message.
     * @param gasLimit     Minimum gas limit that the message can be executed with.
     */
    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );

    /**
     * @notice Additional event data to emit, required as of Bedrock. Cannot be merged with the
     *         SentMessage event without breaking the ABI of this contract, this is good enough.
     *
     * @param sender Address of the sender of the message.
     * @param value  ETH value sent along with the message to the recipient.
     */
    event SentMessageExtension1(address indexed sender, uint256 value);

    /**
     * @notice Emitted whenever a message is successfully relayed on this chain.
     *
     * @param msgHash Hash of the message that was relayed.
     */
    event RelayedMessage(bytes32 indexed msgHash);

    /**
     * @notice Emitted whenever a message fails to be relayed on this chain.
     *
     * @param msgHash Hash of the message that failed to be relayed.
     */
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /**
     * @param _otherMessenger Address of the messenger on the paired chain.
     */
    constructor(address _otherMessenger) {
        OTHER_MESSENGER = _otherMessenger;
    }

    /**
     * @notice Allows the owner of this contract to temporarily pause message relaying. Backup
     *         security mechanism just in case. Owner should be the same as the upgrade wallet to
     *         maintain the security model of the system as a whole.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows the owner of this contract to resume message relaying once paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sends a message to some target address on the other chain. Note that if the call
     *         always reverts, then the message will be unrelayable, and any ETH sent will be
     *         permanently locked. The same will occur if the target on the other chain is
     *         considered unsafe (see the _isUnsafeTarget() function).
     *
     * @param _target      Target contract or wallet address.
     * @param _message     Message to trigger the target address with.
     * @param _minGasLimit Minimum gas limit that the message can be executed with.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _minGasLimit
    ) external payable {
        // Triggers a message to the other messenger. Note that the amount of gas provided to the
        // message is the amount of gas requested by the user PLUS the base gas value. We want to
        // guarantee the property that the call to the target contract will always have at least
        // the minimum gas limit specified by the user.
        _sendMessage(
            OTHER_MESSENGER,
            baseGas(_message, _minGasLimit),
            msg.value,
            abi.encodeWithSelector(
                this.relayMessage.selector,
                messageNonce(),
                msg.sender,
                _target,
                msg.value,
                _minGasLimit,
                _message
            )
        );

        emit SentMessage(_target, msg.sender, _message, messageNonce(), _minGasLimit);
        emit SentMessageExtension1(msg.sender, msg.value);

        unchecked {
            ++msgNonce;
        }
    }

    /**
     * @notice Relays a message that was sent by the other CrossDomainMessenger contract. Can only
     *         be executed via cross-chain call from the other messenger OR if the message was
     *         already received once and is currently being replayed.
     *
     * @param _nonce       Nonce of the message being relayed.
     * @param _sender      Address of the user who sent the message.
     * @param _target      Address that the message is targeted at.
     * @param _value       ETH value to send with the message.
     * @param _minGasLimit Minimum amount of gas that the message can be executed with.
     * @param _message     Message to send to the target.
     */
    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    ) external payable nonReentrant whenNotPaused {
        (, uint16 version) = Encoding.decodeVersionedNonce(_nonce);
        require(
            version < 2,
            "CrossDomainMessenger: only version 0 or 1 messages are supported at this time"
        );

        // If the message is version 0, then it's a migrated legacy withdrawal. We therefore need
        // to check that the legacy version of the message has not already been relayed.
        if (version == 0) {
            bytes32 oldHash = Hashing.hashCrossDomainMessageV0(_target, _sender, _message, _nonce);
            require(
                successfulMessages[oldHash] == false,
                "CrossDomainMessenger: legacy withdrawal already relayed"
            );
        }

        // We use the v1 message hash as the unique identifier for the message because it commits
        // to the value and minimum gas limit of the message.
        bytes32 versionedHash = Hashing.hashCrossDomainMessageV1(
            _nonce,
            _sender,
            _target,
            _value,
            _minGasLimit,
            _message
        );

        if (_isOtherMessenger()) {
            // These properties should always hold when the message is first submitted (as
            // opposed to being replayed).
            assert(msg.value == _value);
            assert(!failedMessages[versionedHash]);
        } else {
            require(
                msg.value == 0,
                "CrossDomainMessenger: value must be zero unless message is from a system address"
            );

            require(
                failedMessages[versionedHash],
                "CrossDomainMessenger: message cannot be replayed"
            );
        }

        require(
            _isUnsafeTarget(_target) == false,
            "CrossDomainMessenger: cannot send message to blocked system address"
        );

        require(
            successfulMessages[versionedHash] == false,
            "CrossDomainMessenger: message has already been relayed"
        );

        require(
            gasleft() >= _minGasLimit + RELAY_GAS_REQUIRED,
            "CrossDomainMessenger: insufficient gas to relay message"
        );

        xDomainMsgSender = _sender;
        bool success = SafeCall.call(_target, gasleft() - RELAY_GAS_BUFFER, _value, _message);
        xDomainMsgSender = Constants.DEFAULT_L2_SENDER;

        if (success == true) {
            successfulMessages[versionedHash] = true;
            emit RelayedMessage(versionedHash);
        } else {
            failedMessages[versionedHash] = true;
            emit FailedRelayedMessage(versionedHash);

            // Revert in this case if the transaction was triggered by the estimation address. This
            // should only be possible during gas estimation or we have bigger problems. Reverting
            // here will make the behavior of gas estimation change such that the gas limit
            // computed will be the amount required to relay the message, even if that amount is
            // greater than the minimum gas limit specified by the user.
            if (tx.origin == Constants.ESTIMATION_ADDRESS) {
                revert("CrossDomainMessenger: failed to relay message");
            }
        }
    }

    /**
     * @notice Retrieves the address of the contract or wallet that initiated the currently
     *         executing message on the other chain. Will throw an error if there is no message
     *         currently being executed. Allows the recipient of a call to see who triggered it.
     *
     * @return Address of the sender of the currently executing message on the other chain.
     */
    function xDomainMessageSender() external view returns (address) {
        require(
            xDomainMsgSender != Constants.DEFAULT_L2_SENDER,
            "CrossDomainMessenger: xDomainMessageSender is not set"
        );

        return xDomainMsgSender;
    }

    /**
     * @notice Retrieves the next message nonce. Message version will be added to the upper two
     *         bytes of the message nonce. Message version allows us to treat messages as having
     *         different structures.
     *
     * @return Nonce of the next message to be sent, with added message version.
     */
    function messageNonce() public view returns (uint256) {
        return Encoding.encodeVersionedNonce(msgNonce, MESSAGE_VERSION);
    }

    /**
     * @notice Computes the amount of gas required to guarantee that a given message will be
     *         received on the other chain without running out of gas. Guaranteeing that a message
     *         will not run out of gas is important because this ensures that a message can always
     *         be replayed on the other chain if it fails to execute completely.
     *
     * @param _message     Message to compute the amount of required gas for.
     * @param _minGasLimit Minimum desired gas limit when message goes to target.
     *
     * @return Amount of gas required to guarantee message receipt.
     */
    function baseGas(bytes calldata _message, uint32 _minGasLimit) public pure returns (uint64) {
        // We peform the following math on uint64s to avoid overflow errors. Multiplying the
        // by MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR would otherwise limit the _minGasLimit to
        // type(uint32).max / MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR ~= 4.2m.
        return
            // Dynamic overhead
            ((uint64(_minGasLimit) * MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR) /
                MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR) +
            // Calldata overhead
            (uint64(_message.length) * MIN_GAS_CALLDATA_OVERHEAD) +
            // Constant overhead
            MIN_GAS_CONSTANT_OVERHEAD;
    }

    /**
     * @notice Intializer.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __CrossDomainMessenger_init() internal onlyInitializing {
        xDomainMsgSender = Constants.DEFAULT_L2_SENDER;
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /**
     * @notice Sends a low-level message to the other messenger. Needs to be implemented by child
     *         contracts because the logic for this depends on the network where the messenger is
     *         being deployed.
     *
     * @param _to       Recipient of the message on the other chain.
     * @param _gasLimit Minimum gas limit the message can be executed with.
     * @param _value    Amount of ETH to send with the message.
     * @param _data     Message data.
     */
    function _sendMessage(
        address _to,
        uint64 _gasLimit,
        uint256 _value,
        bytes memory _data
    ) internal virtual;

    /**
     * @notice Checks whether the message is coming from the other messenger. Implemented by child
     *         contracts because the logic for this depends on the network where the messenger is
     *         being deployed.
     *
     * @return Whether the message is coming from the other messenger.
     */
    function _isOtherMessenger() internal view virtual returns (bool);

    /**
     * @notice Checks whether a given call target is a system address that could cause the
     *         messenger to peform an unsafe action. This is NOT a mechanism for blocking user
     *         addresses. This is ONLY used to prevent the execution of messages to specific
     *         system addresses that could cause security issues, e.g., having the
     *         CrossDomainMessenger send messages to itself.
     *
     * @param _target Address of the contract to check.
     *
     * @return Whether or not the address is an unsafe system address.
     */
    function _isUnsafeTarget(address _target) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Semver
 * @notice Semver is a simple contract for managing contract versions.
 */
contract Semver {
    /**
     * @notice Contract version number (major).
     */
    uint256 private immutable MAJOR_VERSION;

    /**
     * @notice Contract version number (minor).
     */
    uint256 private immutable MINOR_VERSION;

    /**
     * @notice Contract version number (patch).
     */
    uint256 private immutable PATCH_VERSION;

    /**
     * @param _major Version number (major).
     * @param _minor Version number (minor).
     * @param _patch Version number (patch).
     */
    constructor(
        uint256 _major,
        uint256 _minor,
        uint256 _patch
    ) {
        MAJOR_VERSION = _major;
        MINOR_VERSION = _minor;
        PATCH_VERSION = _patch;
    }

    /**
     * @notice Returns the full semver contract version.
     *
     * @return Semver contract version as a string.
     */
    function version() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    Strings.toString(MAJOR_VERSION),
                    ".",
                    Strings.toString(MINOR_VERSION),
                    ".",
                    Strings.toString(PATCH_VERSION)
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + offset);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - offset);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }
}