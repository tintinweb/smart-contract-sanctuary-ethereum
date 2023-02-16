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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IERC721AUpgradeable} from "../ERC721A/upgradeable/IERC721AUpgradeable.sol";
import {ILevelsArtERC721TokenURI} from "./ILevelsArtERC721TokenURI.sol";
import {LevelsArtERC721Storage} from "./LevelsArtERC721Storage.sol";

interface ILevelsArtERC721 is IERC721AUpgradeable {
    // Errors
    error MaxSupplyMinted();

    /// @custom:oz-upgrades-unsafe-allow constructor

    function initialize(string memory _name, string memory _symbol) external;

    function setupCollection(
        address _tokenUriContract,
        uint256 _maxEditions,
        string memory _description,
        string memory _externalLink
    ) external;

    function setTokenURIContract(address _tokenUriContract) external;

    function setMaxEditions(uint256 _maxEditions) external;

    function setContractMetadata(
        string memory _description,
        string memory _externalLink
    ) external;

    function setMinter(address _minter) external;

    /*
      Getter functions
    */

    function version() external view returns (uint16);

    function tokenURIContract() external view returns (address);

    function description() external view returns (string memory);

    function maxEditions() external view returns (uint256);

    function externalLink() external view returns (string memory);

    function MINTER() external view returns (address);

    /**
     * @notice Function that returns the Contract URI
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Function that returns the Token URI from the TokenURI contract
     */
    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory);

    function mint(address to, uint quantity) external;

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override;

    function approve(
        address operator,
        uint256 tokenId
    ) external payable override;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable override;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable override;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable override;

    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    /**
     * @notice Disable the isOperatorFilterRegistryRevoked flag. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() external;

    function isOperatorFilterRegistryRevoked() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @dev Interface of LevelsArtERC721TokenURI
 */
interface ILevelsArtERC721TokenURI {
    /**
     * @dev Used to return the token's URI
     */
    function tokenURI(uint256 tokenId) external pure returns (string memory);

    /**
     * @dev Used to return the token's URI
     */
    function tokenURI(
        uint256 tokenId,
        uint256 seed
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ILevelsArtERC721TokenURI.sol";

library LevelsArtERC721Storage {
    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The contract that generates and returns tokenURIs
        ILevelsArtERC721TokenURI _tokenUriContract;
        // Contract version
        uint16 _version;
        // Contract description
        string _description;
        // Contract external link
        string _externalLink;
        // Max number of editions that can be minted
        uint256 _maxEditions;
        // Designated address of the Minter
        address _MINTER;
        // Keep tabs on mintTime of each tokenId
        mapping(uint256 tokenId => uint256 timestamp) _tokenIdMintedAt;
        // Seed for randomizing the URIs
        uint256 _tokenUriSeed;
        // The designated admin of the contract
        address _ADMIN;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("LevelsArt.contracts.storage.LevelsArtERC721");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ILevelsArtERC721} from "./ILevelsArtERC721.sol";

/*\      $$$$$$$$\ $$\    $$\ $$$$$$$$\ $$\      $$$$$$\                        $$\     
$$ |     $$  _____|$$ |   $$ |$$  _____|$$ |    $$  __$$\                       $$ |    
$$ |     $$ |      $$ |   $$ |$$ |      $$ |    $$ /  \__|   $$$$$$\   $$$$$$\$$$$$$\   
$$ |     $$$$$\    \$$\  $$  |$$$$$\    $$ |    \$$$$$$\     \____$$\ $$  __$$\_$$  _|  
$$ |     $$  __|    \$$\$$  / $$  __|   $$ |     \____$$\    $$$$$$$ |$$ |  \__|$$ |    
$$ |     $$ |        \$$$  /  $$ |      $$ |    $$\   $$ |  $$  __$$ |$$ |      $$ |$$\ 
$$$$$$$$\$$$$$$$$\    \$  /   $$$$$$$$\ $$$$$$$$\$$$$$$  |$$\$$$$$$$ |$$ |      \$$$$  |
\________\________|    \_/    \________|\________\______/ \__\_______|\__|       \___*/

contract LevelsArtSaleManager is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /*
        Events
    */

    // Event fired when a purchase is made
    event Purchase(address nft, uint256 qty);
    // Event fired when a sale is created
    event SaleCreated(
        string saleType,
        address nft,
        uint64 startTime,
        uint64 lowestPriceTime,
        uint64 endTime,
        uint256[] prices,
        uint256 editions,
        uint256 maxPurchaseQuantity,
        address payee
    );
    // Event fired when a sale is updated
    event SaleUpdated(
        uint32 index,
        string saleType,
        address nft,
        uint64 startTime,
        uint64 lowestPriceTime,
        uint64 endTime,
        uint256[] prices,
        uint256 editions,
        uint256 maxPurchaseQuantity,
        address payee
    );

    /*
        Data Types
    */

    enum SaleType {
        FLAT, // Flat sale. Like "buy at this price"
        DUTCH // Dutch auction. Decreases over time.
    }

    struct Sale {
        SaleType saleType;           // Type of sale, can be DUTCH or FLAT
        address nft;                 // The address of the NFT on sale
        uint32 index;                // Each NFT has a list of sales, this is its index
        uint64 startTime;            // The start time of the sale
        uint64 lowestPriceTime;      // If it's a dutch option, it's the time of lowest price
        uint64 endTime;              // (optional) End time of the sale
        uint256[] prices;            // Prices to iterate through for dutch, single index for flat
        uint256 editions;            // Number of editions for sale
        uint256 maxPurchaseQuantity; // Max each wallet can purchase
        address payable payee;       // Address that payment goes to
        uint256 sold;                // Count of how many have sold
        bool paused;                 // Whether the sale is paused or not
    }

    struct ComplimentaryMint {
        address account; // Account that gets a complimentary mint
        uint32 amount;   // Amount that the account gets
    }

    /*
        Storage
    */

    // Keccack of FLAT and DUTCH for comparisons in the create functions
    bytes32 private constant FLAT_256 = keccak256(bytes("FLAT"));
    bytes32 private constant DUTCH_256 = keccak256(bytes("DUTCH"));

    // List of nfts and their sales
    mapping(address nft => Sale[] saleList) private _salesByNft;
    // Mapping to figure out how many purchases a user has made in each sale
    mapping(address nft => mapping(uint32 index => mapping(address account => uint256)))
        private _userPurchasesBySaleByNft;
    // List of nft addreses with sales
    address[] private _nftsWithSales;

    /*
        Constructor
    */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public virtual initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    /**
     * @notice Creates a new sale
     *
     * @param saleType_ Used to determine the saleType. Can be 'FLAT' or
     * 'DUTCH'
     * @param nft_ Address of the NFT on sale
     * @param startTime_ The start time of the sale
     * @param lowestPriceTime_ For dutch auctions, the time that the lowest
     * price will be reached. 0 otherwise
     * @param endTime_ The end time of the sale. If no end, set to 0
     * @param prices_ Tiered prices equally spaced between startTime and
     * lowestPriceTime. Should be ordered from highest to lowest. If it's a
     * FLAT sale then there should only be one value in this array.
     * @param editions_ Number of editions being sold in the sale.
     * @param maxPurchaseQuantity_ Maximum number of editions each individual
     * wallet can purchase
     * @param payee_ The address that gets paid for the sale
     */
    function createSale(
        string calldata saleType_,
        address nft_,
        uint64 startTime_,
        uint64 lowestPriceTime_,
        uint64 endTime_,
        uint256[] calldata prices_,
        uint256 editions_,
        uint256 maxPurchaseQuantity_,
        address payable payee_
    ) public onlyOwner {
            // Check that the values are all valid and get some derived values
            (Sale[] storage salesForNft, SaleType saleType) = _checkSaleValues(
                saleType_,
                nft_,
                startTime_,
                lowestPriceTime_,
                endTime_,
                prices_,
                editions_,
                payee_
            );

            // The index of the new sale in the array
            uint32 index = uint32(salesForNft.length);

            // Check to make sure that Sales are added in chronological order
            // and that no two sales can happen at the same time
            _checkSurroundingSaleValues(salesForNft, index, startTime_, endTime_);

            // Add sale to the list of sales for the NFT
            salesForNft.push(
                Sale(
                    saleType,
                    nft_,
                    index,
                    startTime_,
                    lowestPriceTime_,
                    endTime_,
                    prices_,
                    editions_,
                    maxPurchaseQuantity_,
                    payee_,
                    0,
                    false
                )
            );

        emit SaleCreated(
            saleType_,
            nft_,
            startTime_,
            lowestPriceTime_,
            endTime_,
            prices_,
            editions_,
            maxPurchaseQuantity_,
            payee_
        );
    }

    /**
     * @notice Send the complimentary mints for a sale to the respective accounts
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index in the NFT's sales array that this sale is
     * @param complimentaryMints_ The list of accounts to mint complimentary NFTs to
     */
    function mintComplimentary(
        address nft_,
        uint32 index_,
        ComplimentaryMint[] calldata complimentaryMints_
    ) public onlyOwner {
        Sale storage sale = _salesByNft[nft_][index_];

        require(sale.nft != address(0), "Sale does not exist");
        require(
            block.timestamp < sale.startTime,
            "Cannot complimentary mint after sale has started"
        );

        for (uint256 i = 0; i < complimentaryMints_.length;) {
            uint256 amount = complimentaryMints_[i].amount;
            address account = complimentaryMints_[i].account;
            sale.sold += amount;
            ILevelsArtERC721(nft_).mint(account, amount);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Updates the values of an existing sale
     *
     * @param index_ The index in the NFT's sales array that this sale is
     * @param saleType_ Used to determine the saleType. Can be 'FLAT' or
     * 'DUTCH'
     * @param nft_ Address of the NFT on sale
     * @param startTime_ The start time of the sale
     * @param lowestPriceTime_ For dutch auctions, the time that the lowest
     * price will be reached. 0 otherwise
     * @param endTime_ The end time of the sale. If no end, set to 0
     * @param prices_ Tiered prices equally spaced between startTime and
     * lowestPriceTime. Should be ordered from highest to lowest. If it's a
     * FLAT sale then there should only be one value in this array.
     * @param editions_ Number of editions being sold in the sale.
     * @param maxPurchaseQuantity_ Maximum number of editions each individual
     * wallet acn purchase
     * @param payee_ The address that gets paid for the sale
     */
    function updateSale(
        uint32 index_,
        string calldata saleType_,
        address nft_,
        uint64 startTime_,
        uint64 lowestPriceTime_,
        uint64 endTime_,
        uint256[] calldata prices_,
        uint256 editions_,
        uint256 maxPurchaseQuantity_,
        address payable payee_
    ) public onlyOwner {
        // Validate that all of the new values are coo
        (Sale[] storage salesForNft, SaleType saleType) = _checkSaleValues(
            saleType_,
            nft_,
            startTime_,
            lowestPriceTime_,
            endTime_,
            prices_,
            editions_,
            payee_
        );

        require(salesForNft[index_].nft != address(0), "Sale does not exist");

        // Check to make sure that Sales are added in chronological order
        // and that no two sales can happen at the same time
        _checkSurroundingSaleValues(salesForNft, index_, startTime_, endTime_);

        Sale storage update = salesForNft[index_];

        // Make sure that we're not setting the max number of available
        // editions in the sale to a number less than what's already sold
        require(editions_ >= update.sold, "Already sold more than new value");

        // Do all of the updates
        update.saleType = saleType;
        update.startTime = startTime_;
        update.lowestPriceTime = lowestPriceTime_;
        update.endTime = endTime_;
        update.prices = prices_;
        update.editions = editions_;
        update.maxPurchaseQuantity = maxPurchaseQuantity_;
        update.payee = payee_;

        emit SaleUpdated(
            index_,
            saleType_,
            nft_,
            startTime_,
            lowestPriceTime_,
            endTime_,
            prices_,
            editions_,
            maxPurchaseQuantity_,
            payee_
        );
    }

    /**
     * @notice Does all of the validity checks for the values passed when
     * creating or updating a Sale
     *
     * @param saleType_ Used to determine the saleType.
     * Can be 'FLAT' or 'DUTCH'
     * @param nft_ Address of the NFT on sale
     * @param startTime_ The start time of the sale
     * @param lowestPriceTime_ For dutch auctions, the time that the lowest
     * price will be reached. 0 otherwise
     * @param endTime_ The end time of the sale. If no end, set to 0
     * @param prices_ Tiered prices equally spaced between startTime and
     * lowestPriceTime. Should be ordered from highest to
     * lowest. If it's a FLAT sale then there should only
     * be one value in this array.
     * @param editions_ Number of editions being sold in the sale.
     * @param payee_ The address that gets paid for the sale
     * @return salesForNft The Sale in storage that's being checked
     * @return saleType the enum value that _saleType maps to
     */
    function _checkSaleValues(
        string calldata saleType_,
        address nft_,
        uint64 startTime_,
        uint64 lowestPriceTime_,
        uint64 endTime_,
        uint256[] calldata prices_,
        uint256 editions_,
        address payee_
    ) internal view returns (Sale[] storage salesForNft, SaleType saleType) {
        // Revert is NFT is empty or zero
        require(nft_ != address(0), "Cannot create sale for zero address");
        // Revert if endTime exists and is less than start Time
        require(endTime_ > startTime_ || endTime_ == 0, "Invalid end time");
        // Revery if the sale won't sell anything (lol editions for sale == 0)
        require(editions_ != 0, "Cannot sell zero editions");

        // So we can check the value against FLAT_256 and DUTCH_256
        bytes32 saleType256 = keccak256(bytes(saleType_));

        // Verifies that the sale type is valid (FLAT || DUTCH)  and then runs
        // the checks for that type
        if (saleType256 == FLAT_256) {
            //   - Revert if there are more than 1 price given
            require(prices_.length == 1, "Invalid prices for flat sale");
            //   - Revert if there is lowestPriceTime
            //     (only applicable to dutch auctions)
            require(lowestPriceTime_ == 0, "Invalid lowest price time");
        } else if (saleType256 == DUTCH_256) {
            //   - Revert if there are less than 2 tiers in sale
            require(prices_.length >= 2, "Invalid price for flat sale");
            //   - Revert if the lowestPriceTime is before startTime
            require(lowestPriceTime_ > startTime_, "Invalid lowest price time");
        } else {
            // If the saleType doesn't match one of the two allowed, revert
            revert("Invalid sale type");
        }

        // Checks that the payee isn't the zero address
        require(payee_ != address(0), "Payee cannot be zero");

        // Get the sales created for the individual NFT
        salesForNft = _salesByNft[nft_];
        // Set the saleType
        saleType = saleType256 == FLAT_256 ? SaleType.FLAT : SaleType.DUTCH;
    }

    /**
     * @notice Check to make sure that Sales are added in chronological order
     * and that no two sales can happen at the same time
     *
     * @param salesForNft_ The list of sales that an NFT has
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     * @param startTime_ The start time one the currently referenced sale
     * @param endTime_ The end time one the currently referenced sale
     */
    function _checkSurroundingSaleValues(
        Sale[] memory salesForNft_,
        uint32 index_,
        uint64 startTime_,
        uint64 endTime_
    ) internal pure {
        if (salesForNft_.length == 0) return;

        if (index_ > 0) {
            uint64 prevEnd = salesForNft_[index_ - 1].endTime;
            require(
                prevEnd != 0 && startTime_ >= prevEnd,
                "Cannot have two sales at once"
            );
        }

        if (index_ + 1 < salesForNft_.length - 1) {
            uint64 nextStart = salesForNft_[index_ + 1].startTime;
            require(
                endTime_ < nextStart && endTime_ != 0,
                "Cannot have two sales at once"
            );
        }
    }

    /**
     * @notice Purchase an NFT from a sale
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     * @param qty_ The number the account is trying to purchase
     */
    function purchase(
        address nft_,
        uint32 index_,
        uint256 qty_
    ) public payable nonReentrant isNotPaused(nft_, index_) {
        // Get the sale for NFT at x index
        Sale storage sale = _salesByNft[nft_][index_];

        // Run all of the checks to make sure that the sale can happen
        _handlePurchaseVerification(sale, qty_);

        // Handle the payment for the sale
        _handlePurchasePayment(sale, qty_);

        // Increment the sold quantities
        sale.sold += qty_;
        _userPurchasesBySaleByNft[nft_][index_][msg.sender] += qty_;

        // Mint the NFT
        ILevelsArtERC721(nft_).mint(msg.sender, qty_);

        // Emit event
        emit Purchase(nft_, qty_);
    }

    /**
     * @notice Verify that the purchase is eligible to go through
     *
     * @param sale_ The sale to get the price from
     * @param qty_ The number of editions being sold
     */
    function _handlePurchaseVerification(
        Sale memory sale_,
        uint256 qty_
    ) internal view {
        // For some readability
        (uint64 startTime, uint64 endTime) = (sale_.startTime, sale_.endTime);

        // If it's currently before the start time, the sale hasn't started
        require(block.timestamp >= startTime, "Sale has not started");
        // If there's an endTime and it's past the end time, the sale has ended
        require(endTime == 0 || block.timestamp < endTime, "Sale has ended");
        // If the address is 0, then the sale does not exist
        require(sale_.nft != address(0), "Sale does not exist");
        // If this sale would go over the max limit
        require(
            sale_.sold + qty_ <= sale_.editions,
            "Would exceed max editions"
        );

        // Grab the number of previouses purchases that the user has made
        uint256 purchased = _userPurchasesBySaleByNft[sale_.nft][sale_.index][
            msg.sender
        ];

        // If the sale has a max purchase limit and this sale would drive the
        // account over that limit
        require(
            sale_.maxPurchaseQuantity == 0 ||
                purchased + qty_ <= sale_.maxPurchaseQuantity,
            "Would exceed purchase limit"
        );
    }

    /**
     * @notice Helper function to abstract payment for a sale
     *
     * @param sale_ The sale to get the price from
     * @param qty_ The number of editions being sold
     */
    function _handlePurchasePayment(Sale memory sale_, uint256 qty_) internal {
        // Get the price that the user must pay
        uint256 price = _getSalePrice(sale_) * qty_;

        // If the account sent too little ETH
        require(msg.value >= price, "Insufficient ether");

        // If the account sent too much, let's refund them
        uint256 refund = msg.value - price;
        if (refund > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: refund}("");
            require(refunded, "Refund failed");
        }

        // Pay the payee wallet
        (bool success, ) = sale_.payee.call{value: price}("");
        require(success, "Payment failed");
    }

    /**
     * @notice Pauses a sale
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     */
    function pauseSale(address nft_, uint32 index_) public onlyOwner {
        Sale storage sale = _salesByNft[nft_][index_];
        require(sale.nft != address(0), "Sale does not exist");
        sale.paused = true;
    }

    /**
     * @notice Unpauses a sale
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     */
    function unpauseSale(address nft_, uint32 index_) public onlyOwner {
        Sale storage sale = _salesByNft[nft_][index_];
        require(sale.nft != address(0), "Sale does not exist");
        sale.paused = false;
    }

    /**
     * @notice Gets the current price of a sale
     *
     * @param sale The Sale we're getting the price for.
     */
    function _getSalePrice(Sale memory sale) internal view returns (uint256) {
        uint256[] memory prices = sale.prices;
        uint64 startTime = sale.startTime;
        uint64 lowestPriceTime = sale.lowestPriceTime;

        // If the sale is a FLAT sale, return the only price in the array
        if (prices.length == 1) {
            return prices[0];
        }

        // If the sale is a DUTCH sale, calculate which tier the current
        // timestap falls into and return that price
        uint256 maxIndex = prices.length - 1;
        uint256 range = lowestPriceTime - startTime;
        uint256 timeInEachTier = range / maxIndex;
        uint256 timeSinceStart = block.timestamp - startTime;
        uint256 tier = timeSinceStart / timeInEachTier;
        tier = tier > maxIndex ? maxIndex : tier;

        return prices[tier];
    }

    /**
     * @notice Returns the address of every NFT that there is a sale for
     */
    function getNftsWithSales() public view returns (address[] memory) {
        return _nftsWithSales;
    }

    /**
     * @notice Returns the sales for a specific NFT
     * @param nft_ The address of the NFT
     */
    function getSalesForNft(
        address nft_
    ) public view returns (Sale[] memory sales) {
        sales = _salesByNft[nft_];
    }

    /**
     * @notice Returns a specific sale for a specific NFT
     * @param nft_ The address of the NFT
     * @param index_ The index of the sale in the NFT's sale array
     */
    function getSale(
        address nft_,
        uint32 index_
    ) public view returns (Sale memory sale) {
        sale = _salesByNft[nft_][index_];
    }

    /**
     * @notice Returns a the number of editions sold for an NFT in a sale
     * @param nft_ The address of the NFT
     * @param index_ The index of the sale in the NFT's sale array
     */
    function getSoldInSale(
        address nft_,
        uint32 index_
    ) public view returns (uint256 sold) {
        sold = _salesByNft[nft_][index_].sold;
    }

    /**
     * @notice Returns a the the number of purchases a specific account has
     * made in a sale
     * @param nft_ The address of the NFT
     * @param index_ The index of the sale in the NFT's sale array
     */
    function getWalletPurchasesForSale(
        address nft_,
        uint32 index_,
        address account
    ) public view returns (uint256 purchases) {
        purchases = _userPurchasesBySaleByNft[nft_][index_][account];
    }

    /**
     * @notice Returns every sale that's been listed in this contract
     */
    function getAllSales() public view returns (Sale[] memory) {
        uint256 count = _getSalesCount();
        uint256 iterator = 0;
        Sale[] memory sales = new Sale[](count);

        for (uint i = 0; i < _nftsWithSales.length; i++) {
            address nft = _nftsWithSales[i];
            for (uint j = 0; j < _salesByNft[nft].length; j++) {
                sales[iterator++] = _salesByNft[nft][j];
            }
        }

        return sales;
    }

    /**
     * @notice Helper function that returns the number of sales that have been listed
     */
    function _getSalesCount() internal view returns (uint256 count) {
        count = 0;
        for (uint i = 0; i < _nftsWithSales.length; i++) {
            address nft = _nftsWithSales[i];
            for (uint j = 0; j < _salesByNft[nft].length; j++) {
                count++;
            }
        }
    }

    /**
     * @notice Modifier for checking whether a sale is paused before purchases
     */
    modifier isNotPaused(address nft_, uint32 index_) {
        require(!_salesByNft[nft_][index_].paused, "Sale is paused");
        _;
    }
}