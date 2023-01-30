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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

library CheckContract {
	
    function isContract(address account) public view {
        bool b = AddressUpgradeable.isContract(account);
        require(b, "account is not contract");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../price/IPriceStrategyFactory.sol";
import "../interfaces/ILiquityBase.sol";
import "../depend/BaseMath.sol";
import "../interfaces/IActivePool.sol";
import "../interfaces/IDefaultPool.sol";
import "./LiquityMath.sol";

contract LiquityBase is BaseMath, ILiquityBase {

    using SafeMathUpgradeable for uint;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Amount of CUSD to be locked in gas pool on opening troves
    // uint constant public CUSD_GAS_COMPENSATION = 200e18;

    uint constant public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint constant public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool public activePool;

    IDefaultPool public defaultPool;


    IPriceStrategyFactory public override priceStrategy;


    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt, uint _cusd_gas_compensation) internal pure returns (uint) {
        return _debt.add(_cusd_gas_compensation);
    }

    function _getNetDebt(uint _debt, uint _cusd_gas_compensation) internal pure returns (uint) {
        return _debt.sub(_cusd_gas_compensation);
    }


    // Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal pure returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }


    function getEntireSystemColl(address _lpTokenAddress) public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getLPTokenAmount(_lpTokenAddress);
        uint liquidatedColl = defaultPool.getLPTokenAmount(_lpTokenAddress);

        return activeColl.add(liquidatedColl);
    }

    function getEntireSystemDebt(address _lpTokenAddress) public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getCUSDDebt(_lpTokenAddress);
        uint closedDebt = defaultPool.getCUSDDebt(_lpTokenAddress);

        return activeDebt.add(closedDebt);
    }

    function _getTCR(address _lpTokenAddress, uint _price) internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl(_lpTokenAddress);
        uint entireSystemDebt = getEntireSystemDebt(_lpTokenAddress);

        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt, _price);

        return TCR;
    }

    function _checkRecoveryMode(address _lpTokenAddress, uint _price, uint _CCR) internal view returns (bool) {
        uint TCR = _getTCR(_lpTokenAddress, _price);

        return TCR < _CCR;
    }


    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }
	
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";


library LiquityMath {

    using SafeMathUpgradeable for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division. 
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }


    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }


    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }


    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IPool.sol";


interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolCUSDDebtUpdated(address indexed _lpTokenAddress, uint _CUSDDebt);
    event ActivePoolLPTokenBalanceUpdated(address indexed _lpTokenAddres, uint _ETH);

    // --- Functions ---
    function sendLPToken(address _lpTokenAddress, address _account, uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICCVToken is IERC20Upgradeable {

    
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ICollateralManager {

    struct CollateralData {
        address lpTokenAddr;
        address stabilityPoolAddr;
        address cdlpTokenAddr;
        uint256 MCR; // Minimum collateral ratio for individual troves
        uint256 CCR; // Critical system collateral ratio.If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
        uint256 CUSD_GAS_COMPENSATION; // Amount of LUSD to be locked in gas pool on opening troves
        uint256 MIN_NET_DEBT; //Minimum amount of net LUSD debt a trove must have
        bool paused;
    }

    function addCollateral(address _lpTokenAddr, address _stabilityPoolAddr, address _cdlpTokenAddr) external;

    function removeCollateral(address _lpTokenAddr) external;


    function pauseCollateral(address _lpTokenAddr) external;

    function unpauseCollateral(address _lpTokenAddr) external;

    function updateCollateralStabilityPoolAddr(address _lpTokenAddr, address _stabilityPoolAddr) external;

    function getCollateralStabilityPoolAddr(address _lpTokenAddr) external view returns (address);

    function getCollateralList() external view returns (address[] memory);

    function getActiveCollateralList() external view returns (address[] memory);

    function exists(address _lpTokenAddr) external view returns(bool);

    function isActive(address _lpTokenAddr) external view returns(bool);

    function find(address _lpTokenAddr) external view returns(CollateralData memory);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ICollSurplusPool {


	// --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _lpTokenAddress, address indexed _account, uint _newBalance);
    event lpTokenSent(address _lpTokenAddress, address _to, uint _amount);


    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getLPTokenAmount(address _lpTokenAddress) external view returns (uint);

    function getCollateral(address _lpTokenAddress, address _account) external view returns (uint);

    function accountSurplus(address _lpTokenAddress, address _account, uint _amount) external;

    function claimColl(address _lpTokenAddress, address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IConcaveStaking {

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function increaseF_CUSD(uint256 cusdFee) external;

    function getPendingCUSDGain(address user) external view returns(uint256); 
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICUSDToken is IERC20Upgradeable {

    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    function mint(address _account, uint256 _amount) external;

    function burn(address _lpTokenAddr, address _account, uint256 _amount) external;

    function sendToPool(address _lpTokenAddr, address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address _lpTokenAddr, address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IPool.sol";


interface IDefaultPool is IPool {

    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolCUSDDebtUpdated(address _lpTokenAddress, uint _CUSDDebt);
    event DefaultPoolETHBalanceUpdated(address _lpTokenAddress, uint _lpTokenAmount);
    event lpTokenSent(address _lpTokenAddress, address _to, uint _amount);

    // --- Functions ---
    function sendLPTokenToActivePool(address _lpTokenAddress, uint _amount) external;
	
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../price/IPriceStrategyFactory.sol";


interface ILiquityBase {
    function priceStrategy() external view returns (IPriceStrategyFactory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event ETHBalanceUpdated(uint _newBalance);
    event LUSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event LPTokenSent(address indexed _lpTokenAddress, address _to, uint _amount);

    // --- Functions ---
    
    function getLPTokenAmount(address _lpTokenAddress) external view returns (uint);

    function getCUSDDebt(address _lpTokenAddress) external view returns (uint);

    function increaseCUSDDebt(address _lpTokenAddress, uint _amount) external;

    function decreaseCUSDDebt(address _lpTokenAddress, uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _lpTokenAddress, address _id, uint _NICR);
    event NodeRemoved(address _lpTokenAddress, address _id);


    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _lpTokenAddress, address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _lpTokenAddress, address _id) external;

    function reInsert(address _lpTokenAddress, address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _lpTokenAddress, address _id) external view returns (bool);

    function isFull(address _lpTokenAddress) external view returns (bool);

    function isEmpty(address _lpTokenAddress) external view returns (bool);

    function getSize(address _lpTokenAddress) external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst(address _lpTokenAddress) external view returns (address);

    function getLast(address _lpTokenAddress) external view returns (address);

    function getNext(address _lpTokenAddress, address _id) external view returns (address);

    function getPrev(address _lpTokenAddress, address _id) external view returns (address);

    function validInsertPosition(address _lpTokenAddress, uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(address _lpTokenAddress, uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolCUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event CUSDTokenAddressChanged(address _newCUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _CUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint _LQTY);
    event LQTYPaidToFrontEnd(address indexed _frontEnd, uint _LQTY);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _lpTokenAddress,
        address _collateralManager,
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _cusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount) external;


    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;


    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;


    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the CUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, uint _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint);

    /*
     * Returns CUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalCUSDDeposits() external view returns (uint);


    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint);
    

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedCUSDDeposit(address _depositor) external view returns (uint);



	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./ICUSDToken.sol";
import "./IConcaveStaking.sol";
import "./ICCVToken.sol";

interface ITroveManager is ILiquityBase {

    function setAddresses(
        address _collateralManagerAddress,
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        // address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _cusdTokenAddress,
        address _sortedTrovesAddress,
        address _ccvTokenAddress,
        address _concaveStakingAddress
    ) external;


    // function stabilityPool() external view returns (IStabilityPool);
    function cusdToken() external view returns (ICUSDToken);
    function ccvToken() external view returns (ICCVToken);
    function concaveStaking() external view returns (IConcaveStaking);

    function getTroveOwnersCount(address _lpTokenAddress) external view returns (uint);

    function getTroveFromTroveOwnersArray(address _lpTokenAddress, uint _index) external view returns (address);


    function getNominalICR(address _lpTokenAddress, address _borrower) external view returns (uint);
    function getCurrentICR(address _lpTokenAddress, address _borrower, uint _price) external view returns (uint);


    function liquidate(address _lpTokenAddress, address _borrower) external;

    function liquidateTroves(address _lpTokenAddress, uint _n) external;

    function batchLiquidateTroves(address _lpTokenAddress, address[] calldata _troveArray) external;


    function getPendingETHReward(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getPendingCUSDDebtReward(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getEntireDebtAndColl(address _lpTokenAddress, address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );

    function closeTrove(address _lpTokenAddress, address _borrower) external;

    function removeStake(address _lpTokenAddress, address _borrower) external;

    function applyPendingRewards(address _lpTokenAddress, address _borrower) external;

    function updateTroveRewardSnapshots(address _lpTokenAddress, address _borrower) external;

    function hasPendingRewards(address _lpTokenAddress, address _borrower) external view returns (bool);

    function updateStakeAndTotalStakes(address _lpTokenAddress, address _borrower) external returns (uint);


    function addTroveOwnerToArray(address _lpTokenAddress, address _borrower) external returns (uint index);


    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);
    function getBorrowingFee(uint CUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _CUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _lpTokenAddress, address _borrower) external view returns (uint);
    
    function getTroveStake(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getTroveDebt(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getTroveColl(address _lpTokenAddress, address _borrower) external view returns (uint);

    
    function setTroveStatus(address _lpTokenAddress, address _borrower, uint num) external;

    function increaseTroveColl(address _lpTokenAddress, address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _lpTokenAddress, address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _lpTokenAddress, address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _lpTokenAddress, address _borrower, uint _collDecrease) external returns (uint);


    function getTCR(address _lpTokenAddress, uint _price) external view returns (uint);

    function checkRecoveryMode(address _lpTokenAddress, uint _price, uint _CCR) external view returns (bool);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IPriceFeed {

    // --- Events ---
    // event LastGoodPriceUpdated(uint _lastGoodPrice);

    // --- Function: Calculate the LP token price---
    function fetchPrice() external returns (uint);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IPriceFeed.sol";

interface IPriceStrategyFactory {

    function register(address _lpTokenAddr, IPriceFeed _priceFeed) external;

    function updateRegister(address _lpTokenAddr, IPriceFeed _priceFeed) external;

    function unRegister(address _lpTokenAddr) external;

    function get(address _lpTokenAddr) external view returns(IPriceFeed);

    function fetchPrice(address _lpTokenAddr) external returns(uint);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ITroveManager.sol";
import "./depend/LiquityBase.sol";
import "./depend/CheckContract.sol";
import "./interfaces/IStabilityPool.sol";
import "./interfaces/ICUSDToken.sol";
import "./interfaces/IConcaveStaking.sol";
import "./interfaces/ICCVToken.sol";
import "./interfaces/ICollSurplusPool.sol";
import "./interfaces/ISortedTroves.sol";
import "./interfaces/IActivePool.sol";
import "./interfaces/IDefaultPool.sol";
import "./interfaces/ICollateralManager.sol";

/**
 * Manager Contract
 */
contract TroveManager is LiquityBase, ITroveManager, OwnableUpgradeable {

    using SafeMathUpgradeable for uint256;

    ICollateralManager public collateralManager;

    address public borrowerOperationsAddress;

    // IStabilityPool public override stabilityPool;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    ICUSDToken public override cusdToken;

    ICCVToken public override ccvToken;

    IConcaveStaking public override concaveStaking;

    // A doubly linked list of Troves, sorted by their sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    // --- Data structures ---

    uint public constant SECONDS_IN_ONE_MINUTE = 60;
    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint public constant MINUTE_DECAY_FACTOR = 999037758833783000;
    uint public constant REDEMPTION_FEE_FLOOR = (DECIMAL_PRECISION / 1000) * 5; // 0.5%
    uint public constant MAX_BORROWING_FEE = (DECIMAL_PRECISION / 100) * 5; // 5%

    uint public baseRate;

    // The timestamp of the latest fee operation (redemption or new LUSD issuance)
    uint public lastFeeOperationTime;

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a trove
    struct Trove {
        address collLPTokenAddr;
        uint debt;
        uint coll;
        uint stake;
        Status status;
        uint128 arrayIndex;
    }

    // mapping (address => Trove) public Troves;
    // lpTokenAddress => user address => Trove
    mapping(address => mapping(address => Trove)) public Troves;

    // uint public totalStakes;
    // address => totalStakes
    mapping(address => uint) totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    // uint public totalStakesSnapshot;
    mapping(address => uint) totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    // uint public totalCollateralSnapshot;
    mapping(address => uint) totalCollateralSnapshot;

    /*
     * L_ETH and L_LUSDDebt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
     *
     * An ETH gain of ( stake * [L_ETH - L_ETH(0)] )
     * A LUSDDebt increase  of ( stake * [L_LUSDDebt - L_LUSDDebt(0)] )
     *
     * Where L_ETH(0) and L_LUSDDebt(0) are snapshots of L_ETH and L_LUSDDebt for the active Trove taken at the instant the stake was made
     */
    // uint public L_ETH;
    mapping(address => uint) L_ETHMap;
    // uint public L_LUSDDebt;
    // lpTokenAddress => L_LUSDDebt
    mapping(address => uint) L_CUSDDebtMap;

    // Map addresses with active troves to their RewardSnapshot
    // mapping (address => RewardSnapshot) public rewardSnapshots;
    // lpTokenAddres => address => RewardSnapshot
    mapping(address => mapping(address => RewardSnapshot)) public rewardSnapshots;

    // Object containing the ETH and LUSD snapshots for a given active trove
    struct RewardSnapshot {
        uint ETH;
        uint CUSDDebt;
    }

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    // address[] public TroveOwners;
    // lpTokenAddress => TroveOwners
    mapping(address => address[]) TroveOwnersMap;

    // Error trackers for the trove redistribution calculation
    // uint public lastETHError_Redistribution;
    // lpTokenAddress => lastETHError_Redistribution
    mapping (address => uint) lastETHError_Redistribution;
    // uint public lastLUSDDebtError_Redistribution;
    // lpTokenAddress => lastCUSDDebtError_Redistribution
    mapping (address => uint) lastCUSDDebtError_Redistribution;

    /*
     * --- Variable container structs for liquidations ---
     *
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     **/
    struct LocalVariables_OuterLiquidationFunction {
        uint price;
        uint CUSDInStabPool;
        bool recoveryModeAtStart;
        uint liquidatedDebt;
        uint liquidatedColl;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        uint collToLiquidate;
        uint pendingDebtReward;
        uint pendingCollReward;
    }

    struct LocalVariables_LiquidationSequence {
        uint remainingCUSDInStabPool;
        uint i;
        uint ICR;
        address user;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
    }

    struct LiquidationValues {
        uint entireTroveDebt;
        uint entireTroveColl;
        uint collGasCompensation;
        uint LUSDGasCompensation;
        uint debtToOffset;
        uint collToSendToSP;
        uint debtToRedistribute;
        uint collToRedistribute;
        uint collSurplus;
    }

    struct LiquidationTotals {
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalCollGasCompensation;
        uint totalCUSDGasCompensation;
        uint totalDebtToOffset;
        uint totalCollToSendToSP;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        uint totalCollSurplus;
    }

    struct ContractsCache {
        address _lpTokenAddress;
        ICollateralManager collateralManager;
        IActivePool activePool;
        IDefaultPool defaultPool;
        ICUSDToken cusdToken;
        IConcaveStaking ccvStaking;
        ISortedTroves sortedTroves;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
    }

    // --- Events ---

    event CollateralManagerAddressChanged(address _newCollateralManagerAddress);
    event BorrowerOperationsAddressChanged(
        address _newBorrowerOperationsAddress
    );
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CUSDTokenAddressChanged(address _newCUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event CCVTokenAddressChanged(address _ccvTokenAddress);
    event CCVStakingAddressChanged(address _ccvStakingAddress);

    event Liquidation(
        uint _liquidatedDebt,
        uint _liquidatedColl,
        uint _collGasCompensation,
        uint _LUSDGasCompensation
    );
    event Redemption(
        uint _attemptedLUSDAmount,
        uint _actualLUSDAmount,
        uint _ETHSent,
        uint _ETHFee
    );
    event TroveUpdated(
        address indexed _borrower,
        uint _debt,
        uint _coll,
        uint _stake,
        TroveManagerOperation _operation
    );
    event TroveLiquidated(
        address indexed _borrower,
        uint _debt,
        uint _coll,
        TroveManagerOperation _operation
    );
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(
        uint _totalStakesSnapshot,
        uint _totalCollateralSnapshot
    );
    event LTermsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveIndexUpdated(
        address _lpTokenAddress,
        address _borrower,
        uint _newIndex
    );

    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }


    function initialize() public initializer {
        __Ownable_init();
    }


    // --- Dependency setter ---

    function setAddresses(
        address _collateralManagerAddress,
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        // address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceStrategyAddress,
        address _cusdTokenAddress,
        address _sortedTrovesAddress,
        address _ccvTokenAddress,
        address _concaveStakingAddress
    ) external override onlyOwner {
        CheckContract.isContract(_collateralManagerAddress);
        CheckContract.isContract(_borrowerOperationsAddress);
        CheckContract.isContract(_activePoolAddress);
        CheckContract.isContract(_defaultPoolAddress);
        // CheckContract.isContract(_stabilityPoolAddress);
        CheckContract.isContract(_gasPoolAddress);
        CheckContract.isContract(_collSurplusPoolAddress);
        CheckContract.isContract(_priceStrategyAddress);
        CheckContract.isContract(_cusdTokenAddress);
        CheckContract.isContract(_sortedTrovesAddress);
        CheckContract.isContract(_ccvTokenAddress);
        CheckContract.isContract(_concaveStakingAddress);

        collateralManager = ICollateralManager(_collateralManagerAddress);
        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        // stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceStrategy = IPriceStrategyFactory(_priceStrategyAddress);
        cusdToken = ICUSDToken(_cusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        ccvToken = ICCVToken(_ccvTokenAddress);
        concaveStaking = IConcaveStaking(_concaveStakingAddress);

        emit CollateralManagerAddressChanged(_collateralManagerAddress);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        // emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceStrategyAddress);
        emit CUSDTokenAddressChanged(_cusdTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit CCVTokenAddressChanged(_ccvTokenAddress);
        emit CCVStakingAddressChanged(_concaveStakingAddress);
    }

    // --- Getters ---

    function getTroveOwnersCount(
        address _lpTokenAddress
    ) external view override returns (uint) {
        return TroveOwnersMap[_lpTokenAddress].length;
    }

    function getTroveFromTroveOwnersArray(
        address _lpTokenAddress,
        uint _index
    ) external view override returns (address) {
        return TroveOwnersMap[_lpTokenAddress][_index];
    }

    // --- Trove Liquidation functions ---

    // Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
    function liquidate(
        address _lpTokenAddress,
        address _borrower
    ) external override {
        _requireTroveIsActive(_lpTokenAddress, _borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateTroves(_lpTokenAddress, borrowers);
    }

    // --- Inner single liquidation functions ---

    // Liquidate one trove, in Normal Mode.
    function _liquidateNormalMode(
        address _lpTokenAddress,
        ICollateralManager _collateralManager,
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint _CUSDInStabPool
    ) internal returns (LiquidationValues memory singleLiquidation) {

        ICollateralManager.CollateralData memory collateralData = _collateralManager.find(_lpTokenAddress);
        uint CUSD_GAS_COMPENSATION = collateralData.CUSD_GAS_COMPENSATION;

        LocalVariables_InnerSingleLiquidateFunction memory vars;

        (singleLiquidation.entireTroveDebt,
        singleLiquidation.entireTroveColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = getEntireDebtAndColl(_lpTokenAddress, _borrower);

        _movePendingTroveRewardsToActivePool(_lpTokenAddress, _activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
        _removeStake(_lpTokenAddress, _borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireTroveColl);
        singleLiquidation.LUSDGasCompensation = CUSD_GAS_COMPENSATION;
        uint collToLiquidate = singleLiquidation.entireTroveColl.sub(singleLiquidation.collGasCompensation);

        (singleLiquidation.debtToOffset,
        singleLiquidation.collToSendToSP,
        singleLiquidation.debtToRedistribute,
        singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireTroveDebt, collToLiquidate, _CUSDInStabPool);

        _closeTrove(_lpTokenAddress, _borrower, Status.closedByLiquidation);
        emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, TroveManagerOperation.liquidateInNormalMode);
        emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInNormalMode);
        return singleLiquidation;
    }

    // Liquidate one trove, in Recovery Mode.
    function _liquidateRecoveryMode(
        ContractsCache memory _contractsCache,
        address _borrower,
        uint _ICR,
        uint _LUSDInStabPool,
        uint _TCR,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        ICollateralManager.CollateralData memory collateralData = _contractsCache.collateralManager.find(_contractsCache._lpTokenAddress);

        uint CUSD_GAS_COMPENSATION = collateralData.CUSD_GAS_COMPENSATION;
        uint MCR = collateralData.MCR;

        LocalVariables_InnerSingleLiquidateFunction memory vars;
        if (TroveOwnersMap[_contractsCache._lpTokenAddress].length <= 1) {return singleLiquidation;} // don't liquidate if last trove
        (singleLiquidation.entireTroveDebt,
        singleLiquidation.entireTroveColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = getEntireDebtAndColl(_contractsCache._lpTokenAddress, _borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireTroveColl);
        singleLiquidation.LUSDGasCompensation = CUSD_GAS_COMPENSATION;
        vars.collToLiquidate = singleLiquidation.entireTroveColl.sub(singleLiquidation.collGasCompensation);

        // If ICR <= 100%, purely redistribute the Trove across all active Troves
        if (_ICR <= _100pct) {
            _movePendingTroveRewardsToActivePool(_contractsCache._lpTokenAddress, _contractsCache.activePool, _contractsCache.defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            _removeStake(_contractsCache._lpTokenAddress, _borrower);
           
            singleLiquidation.debtToOffset = 0;
            singleLiquidation.collToSendToSP = 0;
            singleLiquidation.debtToRedistribute = singleLiquidation.entireTroveDebt;
            singleLiquidation.collToRedistribute = vars.collToLiquidate;

            _closeTrove(_contractsCache._lpTokenAddress, _borrower, Status.closedByLiquidation);
            emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, TroveManagerOperation.liquidateInRecoveryMode);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInRecoveryMode);
            
        // If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
        } else if ((_ICR > _100pct) && (_ICR < MCR)) {
             _movePendingTroveRewardsToActivePool(_contractsCache._lpTokenAddress, _contractsCache.activePool, _contractsCache.defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            _removeStake(_contractsCache._lpTokenAddress, _borrower);

            (singleLiquidation.debtToOffset,
            singleLiquidation.collToSendToSP,
            singleLiquidation.debtToRedistribute,
            singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireTroveDebt, vars.collToLiquidate, _LUSDInStabPool);

            _closeTrove(_contractsCache._lpTokenAddress, _borrower, Status.closedByLiquidation);
            emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, TroveManagerOperation.liquidateInRecoveryMode);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInRecoveryMode);
        /*
        * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
        * and there is LUSD in the Stability Pool, only offset, with no redistribution,
        * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
        * The remainder due to the capped rate will be claimable as collateral surplus.
        */
        } else if ((_ICR >= MCR) && (_ICR < _TCR) && (singleLiquidation.entireTroveDebt <= _LUSDInStabPool)) {
            _movePendingTroveRewardsToActivePool(_contractsCache._lpTokenAddress, _contractsCache.activePool, _contractsCache.defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            assert(_LUSDInStabPool != 0);

            _removeStake(_contractsCache._lpTokenAddress, _borrower);
            singleLiquidation = _getCappedOffsetVals(MCR, CUSD_GAS_COMPENSATION, singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, _price);

            _closeTrove(_contractsCache._lpTokenAddress, _borrower, Status.closedByLiquidation);
            if (singleLiquidation.collSurplus > 0) {
                collSurplusPool.accountSurplus(_contractsCache._lpTokenAddress, _borrower, singleLiquidation.collSurplus);
            }

            emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.collToSendToSP, TroveManagerOperation.liquidateInRecoveryMode);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInRecoveryMode);

        } else { // if (_ICR >= MCR && ( _ICR >= _TCR || singleLiquidation.entireTroveDebt > _LUSDInStabPool))
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        return singleLiquidation;
    }

    /* In a full liquidation, returns the values for a trove's coll and debt to be offset, and coll and debt to be
     * redistributed to active troves.
     */
    function _getOffsetAndRedistributionVals(
        uint _debt,
        uint _coll,
        uint _CUSDInStabPool
    )
        internal
        pure
        returns (
            uint debtToOffset,
            uint collToSendToSP,
            uint debtToRedistribute,
            uint collToRedistribute
        )
    {
        if (_CUSDInStabPool > 0) {
            /*
             * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
             * between all active troves.
             *
             *  If the trove's debt is larger than the deposited LUSD in the Stability Pool:
             *
             *  - Offset an amount of the trove's debt equal to the LUSD in the Stability Pool
             *  - Send a fraction of the trove's collateral to the Stability Pool, equal to the fraction of its offset debt
             *
             */
            debtToOffset = MathUpgradeable.min(_debt, _CUSDInStabPool);
            collToSendToSP = _coll.mul(debtToOffset).div(_debt);
            debtToRedistribute = _debt.sub(debtToOffset);
            collToRedistribute = _coll.sub(collToSendToSP);
        } else {
            debtToOffset = 0;
            collToSendToSP = 0;
            debtToRedistribute = _debt;
            collToRedistribute = _coll;
        }
    }

    /*
    *  Get its offset coll/debt and ETH gas comp, and close the trove.
    */
    function _getCappedOffsetVals
    (
        uint _MCR,
        uint _LUSD_GAS_COMPENSATION,
        uint _entireTroveDebt,
        uint _entireTroveColl,
        uint _price
    )
        internal
        pure
        returns (LiquidationValues memory singleLiquidation)
    {
        singleLiquidation.entireTroveDebt = _entireTroveDebt;
        singleLiquidation.entireTroveColl = _entireTroveColl;
        uint cappedCollPortion = _entireTroveDebt.mul(_MCR).div(_price);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(cappedCollPortion);
        singleLiquidation.LUSDGasCompensation = _LUSD_GAS_COMPENSATION;

        singleLiquidation.debtToOffset = _entireTroveDebt;
        singleLiquidation.collToSendToSP = cappedCollPortion.sub(singleLiquidation.collGasCompensation);
        singleLiquidation.collSurplus = _entireTroveColl.sub(cappedCollPortion);
        singleLiquidation.debtToRedistribute = 0;
        singleLiquidation.collToRedistribute = 0;
    }

    /*
    * Liquidate a sequence of troves. Closes a maximum number of n under-collateralized Troves,
    * starting from the one with the lowest collateral ratio in the system, and moving upwards
    */
    function liquidateTroves(
        address _lpTokenAddress,
        uint _n
    ) public override {
        ContractsCache memory contractsCache = ContractsCache(
            _lpTokenAddress,
            collateralManager,
            activePool,
            defaultPool,
            ICUSDToken(address(0)),
            IConcaveStaking(address(0)),
            sortedTroves,
            ICollSurplusPool(address(0)),
            address(0)
        );
        IStabilityPool stabilityPoolCached = IStabilityPool(collateralManager.getCollateralStabilityPoolAddr(_lpTokenAddress));

        LocalVariables_OuterLiquidationFunction memory vars;

        LiquidationTotals memory totals;

        ICollateralManager.CollateralData memory collateralData = contractsCache.collateralManager.find(_lpTokenAddress);
        uint CCR = collateralData.CCR;
        uint MCR = collateralData.MCR;

        vars.price = priceStrategy.fetchPrice(_lpTokenAddress);
        vars.CUSDInStabPool = stabilityPoolCached.getTotalCUSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(_lpTokenAddress, vars.price, CCR);

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        if (vars.recoveryModeAtStart) {
            totals = _getTotalsFromLiquidateTrovesSequence_RecoveryMode(MCR, CCR, contractsCache, vars.price, vars.CUSDInStabPool, _n);
        } else { // if !vars.recoveryModeAtStart
            totals = _getTotalsFromLiquidateTrovesSequence_NormalMode(_lpTokenAddress, contractsCache.collateralManager, contractsCache.activePool, contractsCache.defaultPool, vars.price, vars.CUSDInStabPool, _n, MCR);
        }

        require(totals.totalDebtInSequence > 0, "TroveManager: nothing to liquidate");

        // Move liquidated ETH and LUSD to the appropriate pools
        stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        _redistributeDebtAndColl(_lpTokenAddress, contractsCache.activePool, contractsCache.defaultPool, totals.totalDebtToRedistribute, totals.totalCollToRedistribute);
        if (totals.totalCollSurplus > 0) {
            contractsCache.activePool.sendLPToken(_lpTokenAddress, address(collSurplusPool), totals.totalCollSurplus);
        }

        // Update system snapshots
        _updateSystemSnapshots_excludeCollRemainder(_lpTokenAddress, contractsCache.activePool, totals.totalCollGasCompensation);

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(totals.totalCollSurplus);
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalCUSDGasCompensation);

        // Send gas compensation to caller
        _sendGasCompensation(_lpTokenAddress, contractsCache.activePool, msg.sender, totals.totalCUSDGasCompensation, totals.totalCollGasCompensation);
    }

    /*
    * This function is used when the liquidateTroves sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalsFromLiquidateTrovesSequence_RecoveryMode
    (
        uint MCR,
        uint CCR,
        ContractsCache memory _contractsCache,
        uint _price,
        uint _CUSDInStabPool,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        // ICollateralManager.CollateralData memory collateralData = _contractsCache.collateralManager.find(_contractsCache._lpTokenAddress);
        // uint MCR = collateralData.MCR;
        // uint CCR = collateralData.CCR;

        vars.remainingCUSDInStabPool = _CUSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt(_contractsCache._lpTokenAddress);
        vars.entireSystemColl = getEntireSystemColl(_contractsCache._lpTokenAddress);

        vars.user = _contractsCache.sortedTroves.getLast(_contractsCache._lpTokenAddress);
        address firstUser = _contractsCache.sortedTroves.getFirst(_contractsCache._lpTokenAddress);
        for (vars.i = 0; vars.i < _n && vars.user != firstUser; vars.i++) {
            // we need to cache it, because current user is likely going to be deleted
            address nextUser = _contractsCache.sortedTroves.getPrev(_contractsCache._lpTokenAddress, vars.user);

            vars.ICR = getCurrentICR(_contractsCache._lpTokenAddress, vars.user, _price);

            if (!vars.backToNormalMode) {
                // Break the loop if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingCUSDInStabPool == 0) { break; }

                uint TCR = LiquityMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);

                singleLiquidation = _liquidateRecoveryMode(_contractsCache, vars.user, vars.ICR, vars.remainingCUSDInStabPool, TCR, _price);

                // Update aggregate trackers
                vars.remainingCUSDInStabPool = vars.remainingCUSDInStabPool.sub(singleLiquidation.debtToOffset);
                vars.entireSystemDebt = vars.entireSystemDebt.sub(singleLiquidation.debtToOffset);
                vars.entireSystemColl = vars.entireSystemColl.
                    sub(singleLiquidation.collToSendToSP).
                    sub(singleLiquidation.collGasCompensation).
                    sub(singleLiquidation.collSurplus);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price, CCR);
            }
            else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_contractsCache._lpTokenAddress, _contractsCache.collateralManager, _contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.remainingCUSDInStabPool);

                vars.remainingCUSDInStabPool = vars.remainingCUSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            }  else break;  // break if the loop reaches a Trove with ICR >= MCR

            vars.user = nextUser;
        }
    }

    function _getTotalsFromLiquidateTrovesSequence_NormalMode
    (
        address _lpTokenAddress,
        ICollateralManager _collateralManager,
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _CUSDInStabPool,
        uint _n,
        uint _MCR
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        ISortedTroves sortedTrovesCached = sortedTroves;

        vars.remainingCUSDInStabPool = _CUSDInStabPool;

        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = sortedTrovesCached.getLast(_lpTokenAddress);
            vars.ICR = getCurrentICR(_lpTokenAddress, vars.user, _price);

            if (vars.ICR < _MCR) {
                singleLiquidation = _liquidateNormalMode(_lpTokenAddress, _collateralManager, _activePool, _defaultPool, vars.user, vars.remainingCUSDInStabPool);

                vars.remainingCUSDInStabPool = vars.remainingCUSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else break;  // break if the loop reaches a Trove with ICR >= MCR
        }
    }

    /*
     * Attempt to liquidate a custom list of troves provided by the caller.
     */
    function batchLiquidateTroves(
        address _lpTokenAddress,
        address[] memory _troveArray
    ) public override {
        require(_troveArray.length != 0, "TroveManager: Calldata address array must not be empty");

        ICollateralManager.CollateralData memory collateralData = collateralManager.find(_lpTokenAddress);

        uint MCR = collateralData.MCR;
        uint CCR = collateralData.CCR;


        IActivePool activePoolCached = activePool;
        IDefaultPool defaultPoolCached = defaultPool;
        IStabilityPool stabilityPoolCached = IStabilityPool(collateralManager.getCollateralStabilityPoolAddr(_lpTokenAddress));

        ContractsCache memory contractsCache = ContractsCache(
            _lpTokenAddress,
            collateralManager,
            activePool,
            defaultPool,
            ICUSDToken(address(0)),
            IConcaveStaking(address(0)),
            sortedTroves,
            ICollSurplusPool(address(0)),
            address(0)
        );

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.price = priceStrategy.fetchPrice(_lpTokenAddress);
        vars.CUSDInStabPool = stabilityPoolCached.getTotalCUSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(_lpTokenAddress, vars.price, CCR);

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        if (vars.recoveryModeAtStart) {
            totals = _getTotalFromBatchLiquidate_RecoveryMode(MCR, CCR, contractsCache, vars.price, vars.CUSDInStabPool, _troveArray);
        } else {  //  if !vars.recoveryModeAtStart
            totals = _getTotalsFromBatchLiquidate_NormalMode(MCR, contractsCache, vars.price, vars.CUSDInStabPool, _troveArray);
        }

        require(totals.totalDebtInSequence > 0, "TroveManager: nothing to liquidate");

        // Move liquidated ETH and LUSD to the appropriate pools
        stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        _redistributeDebtAndColl(_lpTokenAddress, activePoolCached, defaultPoolCached, totals.totalDebtToRedistribute, totals.totalCollToRedistribute);
        if (totals.totalCollSurplus > 0) {
            activePoolCached.sendLPToken(_lpTokenAddress, address(collSurplusPool), totals.totalCollSurplus);
        }

        // Update system snapshots
        _updateSystemSnapshots_excludeCollRemainder(_lpTokenAddress, activePoolCached, totals.totalCollGasCompensation);

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(totals.totalCollSurplus);
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalCUSDGasCompensation);

        // Send gas compensation to caller
        _sendGasCompensation(_lpTokenAddress, activePoolCached, msg.sender, totals.totalCUSDGasCompensation, totals.totalCollGasCompensation);
    }

    /*
    * This function is used when the batch liquidation sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalFromBatchLiquidate_RecoveryMode
    (
        uint MCR,
        uint CCR,
        ContractsCache memory _contractsCache,
        uint _price,
        uint _CUSDInStabPool,
        address[] memory _troveArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingCUSDInStabPool = _CUSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt(_contractsCache._lpTokenAddress);
        vars.entireSystemColl = getEntireSystemColl(_contractsCache._lpTokenAddress);

        for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.user = _troveArray[vars.i];
            // Skip non-active troves
            if (Troves[_contractsCache._lpTokenAddress][vars.user].status != Status.active) { continue; }
            vars.ICR = getCurrentICR(_contractsCache._lpTokenAddress, vars.user, _price);

            if (!vars.backToNormalMode) {

                // Skip this trove if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingCUSDInStabPool == 0) { continue; }

                uint TCR = LiquityMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);

                singleLiquidation = _liquidateRecoveryMode(_contractsCache, vars.user, vars.ICR, vars.remainingCUSDInStabPool, TCR, _price);

                // Update aggregate trackers
                vars.remainingCUSDInStabPool = vars.remainingCUSDInStabPool.sub(singleLiquidation.debtToOffset);
                vars.entireSystemDebt = vars.entireSystemDebt.sub(singleLiquidation.debtToOffset);
                vars.entireSystemColl = vars.entireSystemColl.
                    sub(singleLiquidation.collToSendToSP).
                    sub(singleLiquidation.collGasCompensation).
                    sub(singleLiquidation.collSurplus);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price, CCR);
            }

            else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_contractsCache._lpTokenAddress, _contractsCache.collateralManager,_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.remainingCUSDInStabPool);
                vars.remainingCUSDInStabPool = vars.remainingCUSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else continue; // In Normal Mode skip troves with ICR >= MCR
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode
    (
        uint MCR,
        ContractsCache memory _contractsCache,
        uint _price,
        uint _LUSDInStabPool,
        address[] memory _troveArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingCUSDInStabPool = _LUSDInStabPool;

        for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.user = _troveArray[vars.i];
            vars.ICR = getCurrentICR(_contractsCache._lpTokenAddress, vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_contractsCache._lpTokenAddress, _contractsCache.collateralManager,_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.remainingCUSDInStabPool);
                vars.remainingCUSDInStabPool = vars.remainingCUSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

    // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(LiquidationTotals memory oldTotals, LiquidationValues memory singleLiquidation)
    internal pure returns(LiquidationTotals memory newTotals) {

        // Tally all the values with their respective running totals
        newTotals.totalCollGasCompensation = oldTotals.totalCollGasCompensation.add(singleLiquidation.collGasCompensation);
        newTotals.totalCUSDGasCompensation = oldTotals.totalCUSDGasCompensation.add(singleLiquidation.LUSDGasCompensation);
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence.add(singleLiquidation.entireTroveDebt);
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence.add(singleLiquidation.entireTroveColl);
        newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset.add(singleLiquidation.debtToOffset);
        newTotals.totalCollToSendToSP = oldTotals.totalCollToSendToSP.add(singleLiquidation.collToSendToSP);
        newTotals.totalDebtToRedistribute = oldTotals.totalDebtToRedistribute.add(singleLiquidation.debtToRedistribute);
        newTotals.totalCollToRedistribute = oldTotals.totalCollToRedistribute.add(singleLiquidation.collToRedistribute);
        newTotals.totalCollSurplus = oldTotals.totalCollSurplus.add(singleLiquidation.collSurplus);

        return newTotals;
    }

    function _sendGasCompensation(address _lpTokenAddress, IActivePool _activePool, address _liquidator, uint _LUSD, uint _ETH) internal {
        if (_LUSD > 0) {
            cusdToken.returnFromPool(_lpTokenAddress, gasPoolAddress, _liquidator, _LUSD);
        }

        if (_ETH > 0) {
            _activePool.sendLPToken(_lpTokenAddress, _liquidator, _ETH);
        }
    }

    // Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    // _ETH represent lpToken amount
    function _movePendingTroveRewardsToActivePool(
        address _lpTokenAddress,
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _CUSD,
        uint _ETH
    ) internal {
        _defaultPool.decreaseCUSDDebt(_lpTokenAddress, _CUSD);
        _activePool.increaseCUSDDebt(_lpTokenAddress, _CUSD);
        _defaultPool.sendLPTokenToActivePool(_lpTokenAddress, _ETH);
    }
    
    
    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Trove, without the price. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _lpTokenAddress, address _borrower) public view override returns (uint) {
        (uint currentETH, uint currentLUSDDebt) = _getCurrentTroveAmounts(_lpTokenAddress, _borrower);

        uint NICR = LiquityMath._computeNominalCR(currentETH, currentLUSDDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _lpTokenAddress, address _borrower, uint _price) public view override returns (uint) {
        (uint currentETH, uint currentCUSDDebt) = _getCurrentTroveAmounts(_lpTokenAddress, _borrower);

        uint ICR = LiquityMath._computeCR(currentETH, currentCUSDDebt, _price);
        return ICR;
    }


    function _getCurrentTroveAmounts(address _lpTokenAddress, address _borrower) internal view returns (uint, uint) {
        uint pendingETHReward = getPendingETHReward(_lpTokenAddress, _borrower);
        uint pendingLUSDDebtReward = getPendingCUSDDebtReward(_lpTokenAddress, _borrower);

        uint currentETH = Troves[_lpTokenAddress][_borrower].coll.add(pendingETHReward);
        uint currentLUSDDebt = Troves[_lpTokenAddress][_borrower].debt.add(pendingLUSDDebtReward);

        return (currentETH, currentLUSDDebt);
    }

    function applyPendingRewards(address _lpTokenAddress, address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _applyPendingRewards(_lpTokenAddress, activePool, defaultPool, _borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
    function _applyPendingRewards(address _lpTokenAddress, IActivePool _activePool, IDefaultPool _defaultPool, address _borrower) internal {
        if (hasPendingRewards(_lpTokenAddress, _borrower)) {
            _requireTroveIsActive(_lpTokenAddress, _borrower);

            // Compute pending rewards
            uint pendingETHReward = getPendingETHReward(_lpTokenAddress, _borrower);
            uint pendingLUSDDebtReward = getPendingCUSDDebtReward(_lpTokenAddress, _borrower);

            // Apply pending rewards to trove's state
            Troves[_lpTokenAddress][_borrower].coll = Troves[_lpTokenAddress][_borrower].coll.add(pendingETHReward);
            Troves[_lpTokenAddress][_borrower].debt = Troves[_lpTokenAddress][_borrower].debt.add(pendingLUSDDebtReward);

            _updateTroveRewardSnapshots(_lpTokenAddress, _borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingTroveRewardsToActivePool(_lpTokenAddress, _activePool, _defaultPool, pendingLUSDDebtReward, pendingETHReward);

            emit TroveUpdated(
                _borrower,
                Troves[_lpTokenAddress][_borrower].debt,
                Troves[_lpTokenAddress][_borrower].coll,
                Troves[_lpTokenAddress][_borrower].stake,
                TroveManagerOperation.applyPendingRewards
            );
        }
    }

    // Update borrower's snapshots of L_ETH and L_LUSDDebt to reflect the current values
    function updateTroveRewardSnapshots(address _lpTokenAddress, address _borrower) external override {
        _requireCallerIsBorrowerOperations();
       return _updateTroveRewardSnapshots(_lpTokenAddress, _borrower);
    }

    function _updateTroveRewardSnapshots(address _lpTokenAddress, address _borrower) internal {
        rewardSnapshots[_lpTokenAddress][_borrower].ETH = L_ETHMap[_lpTokenAddress];
        rewardSnapshots[_lpTokenAddress][_borrower].CUSDDebt = L_CUSDDebtMap[_lpTokenAddress];
        emit TroveSnapshotsUpdated(L_ETHMap[_lpTokenAddress], L_CUSDDebtMap[_lpTokenAddress]);
    }


    // Get the borrower's pending accumulated ETH reward, earned by their stake
    function getPendingETHReward(
        address _lpTokenAddress,
        address _borrower
    ) public view override returns (uint) {
        uint snapshotETH = rewardSnapshots[_lpTokenAddress][_borrower].ETH;
        uint rewardPerUnitStaked = L_ETHMap[_lpTokenAddress].sub(snapshotETH);

        if (
            rewardPerUnitStaked == 0 ||
            Troves[_lpTokenAddress][_borrower].status != Status.active
        ) {
            return 0;
        }

        uint stake = Troves[_lpTokenAddress][_borrower].stake;

        uint pendingETHReward = stake.mul(rewardPerUnitStaked).div(
            DECIMAL_PRECISION
        );

        return pendingETHReward;
    }

    // Get the borrower's pending accumulated CUSD reward, earned by their stake
    function getPendingCUSDDebtReward(
        address _lpTokenAddress,
        address _borrower
    ) public view override returns (uint) {
        uint snapshotLUSDDebt = rewardSnapshots[_lpTokenAddress][_borrower]
            .CUSDDebt;
        uint rewardPerUnitStaked = L_CUSDDebtMap[_lpTokenAddress].sub(
            snapshotLUSDDebt
        );

        if (
            rewardPerUnitStaked == 0 ||
            Troves[_lpTokenAddress][_borrower].status != Status.active
        ) {
            return 0;
        }

        uint stake = Troves[_lpTokenAddress][_borrower].stake;

        uint pendingCUSDDebtReward = stake.mul(rewardPerUnitStaked).div(
            DECIMAL_PRECISION
        );

        return pendingCUSDDebtReward;
    }

    function hasPendingRewards(address _lpTokenAddress, address _borrower) public view override returns (bool) {
        /*
        * A Trove has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
        * this indicates that rewards have occured since the snapshot was made, and the user therefore has
        * pending rewards
        */
        if (Troves[_lpTokenAddress][_borrower].status != Status.active) {return false;}
       
        return (rewardSnapshots[_lpTokenAddress][_borrower].ETH < L_ETHMap[_lpTokenAddress]);
    }


    // Return the Troves entire debt and coll, including pending rewards from redistributions.
    function getEntireDebtAndColl(
        address _lpTokenAddress,
        address _borrower
    )
        public
        view
        override
        returns (
            uint debt,
            uint coll,
            uint pendingLUSDDebtReward,
            uint pendingETHReward
        )
    {
        debt = Troves[_lpTokenAddress][_borrower].debt;
        coll = Troves[_lpTokenAddress][_borrower].coll;

        pendingLUSDDebtReward = getPendingCUSDDebtReward(
            _lpTokenAddress,
            _borrower
        );
        pendingETHReward = getPendingETHReward(_lpTokenAddress, _borrower);

        debt = debt.add(pendingLUSDDebtReward);
        coll = coll.add(pendingETHReward);
    }

    function removeStake(
        address _lpTokenAddress,
        address _borrower
    ) external override {
        _requireCallerIsBorrowerOperations();
        return _removeStake(_lpTokenAddress, _borrower);
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(address _lpTokenAddress, address _borrower) internal {
        uint stake = Troves[_lpTokenAddress][_borrower].stake;
        totalStakes[_lpTokenAddress] = totalStakes[_lpTokenAddress].sub(stake);
        Troves[_lpTokenAddress][_borrower].stake = 0;
    }


    function updateStakeAndTotalStakes(address _lpTokenAddress, address _borrower) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        return _updateStakeAndTotalStakes(_lpTokenAddress, _borrower);
    }

    // Update borrower's stake based on their latest collateral value
    function _updateStakeAndTotalStakes(address _lpTokenAddress, address _borrower) internal returns (uint) {
        uint newStake = _computeNewStake(_lpTokenAddress, Troves[_lpTokenAddress][_borrower].coll);
        uint oldStake = Troves[_lpTokenAddress][_borrower].stake;
        Troves[_lpTokenAddress][_borrower].stake = newStake;

        totalStakes[_lpTokenAddress] = totalStakes[_lpTokenAddress].sub(oldStake).add(newStake);
        emit TotalStakesUpdated(totalStakes[_lpTokenAddress]);

        return newStake;
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(address _lpTokenAddress, uint _coll) internal view returns (uint) {
        uint stake;
        if (totalCollateralSnapshot[_lpTokenAddress] == 0) {
            stake = _coll;
        } else {
            /*
            * The following assert() holds true because:
            * - The system always contains >= 1 trove
            * - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
            * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
            */
            assert(totalStakesSnapshot[_lpTokenAddress] > 0);
            stake = _coll.mul(totalStakesSnapshot[_lpTokenAddress]).div(totalCollateralSnapshot[_lpTokenAddress]);
        }
        return stake;
    }


    function _redistributeDebtAndColl(address _lpTokenAddress, IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, uint _coll) internal {
        if (_debt == 0) { return; }

        /*
        * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        * error correction, to keep the cumulative error low in the running totals L_ETH and L_LUSDDebt:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this
        * function was called.
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint ETHNumerator = _coll.mul(DECIMAL_PRECISION).add(lastETHError_Redistribution[_lpTokenAddress]);
        uint CUSDDebtNumerator = _debt.mul(DECIMAL_PRECISION).add(lastCUSDDebtError_Redistribution[_lpTokenAddress]);

        // Get the per-unit-staked terms
        uint ETHRewardPerUnitStaked = ETHNumerator.div(totalStakes[_lpTokenAddress]);
        uint CUSDDebtRewardPerUnitStaked = CUSDDebtNumerator.div(totalStakes[_lpTokenAddress]);

        lastETHError_Redistribution[_lpTokenAddress] = ETHNumerator.sub(ETHRewardPerUnitStaked.mul(totalStakes[_lpTokenAddress]));
        lastCUSDDebtError_Redistribution[_lpTokenAddress] = CUSDDebtNumerator.sub(CUSDDebtRewardPerUnitStaked.mul(totalStakes[_lpTokenAddress]));

        // Add per-unit-staked terms to the running totals
        L_ETHMap[_lpTokenAddress] = L_ETHMap[_lpTokenAddress].add(ETHRewardPerUnitStaked);
        L_CUSDDebtMap[_lpTokenAddress] = L_CUSDDebtMap[_lpTokenAddress].add(CUSDDebtRewardPerUnitStaked);

        emit LTermsUpdated(L_ETHMap[_lpTokenAddress], L_CUSDDebtMap[_lpTokenAddress]);

        // Transfer coll and debt from ActivePool to DefaultPool
        _activePool.decreaseCUSDDebt(_lpTokenAddress, _debt);
        _defaultPool.increaseCUSDDebt(_lpTokenAddress, _debt);
        _activePool.sendLPToken(_lpTokenAddress, address(_defaultPool), _coll);
    }

    function closeTrove(
        address _lpTokenAddress,
        address _borrower
    ) public override {
        _requireCallerIsBorrowerOperations();
        return _closeTrove(_lpTokenAddress, _borrower, Status.closedByOwner);
    }

    function _closeTrove(
        address _lpTokenAddress,
        address _borrower,
        Status closedStatus
    ) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint TroveOwnersArrayLength = TroveOwnersMap[_lpTokenAddress].length;
        _requireMoreThanOneTroveInSystem(_lpTokenAddress, TroveOwnersArrayLength);

        Troves[_lpTokenAddress][_borrower].status = closedStatus;
        Troves[_lpTokenAddress][_borrower].coll = 0;
        Troves[_lpTokenAddress][_borrower].debt = 0;

        rewardSnapshots[_lpTokenAddress][_borrower].ETH = 0;
        rewardSnapshots[_lpTokenAddress][_borrower].CUSDDebt = 0;

        _removeTroveOwner(_lpTokenAddress, _borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_lpTokenAddress, _borrower);
    }


    /*
    * Updates snapshots of system total stakes and total collateral, excluding a given collateral remainder from the calculation.
    * Used in a liquidation sequence.
    *
    * The calculation excludes a portion of collateral that is in the ActivePool:
    *
    * the total ETH gas compensation from the liquidation sequence
    *
    * The ETH as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
    */
    function _updateSystemSnapshots_excludeCollRemainder(address _lpTokenAddress, IActivePool _activePool, uint _collRemainder) internal {
        totalStakesSnapshot[_lpTokenAddress] = totalStakes[_lpTokenAddress];

        uint activeColl = _activePool.getLPTokenAmount(_lpTokenAddress);
        uint liquidatedColl = defaultPool.getLPTokenAmount(_lpTokenAddress);
        totalCollateralSnapshot[_lpTokenAddress] = activeColl.sub(_collRemainder).add(liquidatedColl);

        emit SystemSnapshotsUpdated(totalStakesSnapshot[_lpTokenAddress], totalCollateralSnapshot[_lpTokenAddress]);
    }

    // Push the owner's address to the Trove owners list, and record the corresponding array index on the Trove struct
    function addTroveOwnerToArray(address _lpTokenAddress, address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOperations();
        return _addTroveOwnerToArray(_lpTokenAddress, _borrower);
    }

    function _addTroveOwnerToArray(address _lpTokenAddress, address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 troves. No risk of overflow, since troves have minimum LUSD
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 LUSD dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the Troveowner to the array
        TroveOwnersMap[_lpTokenAddress].push(_borrower);

        // Record the index of the new Troveowner on their Trove struct
        index = uint128(TroveOwnersMap[_lpTokenAddress].length.sub(1));
        Troves[_lpTokenAddress][_borrower].arrayIndex = index;

        return index;
    }

    /*
     * Remove a Trove owner from the TroveOwners array, not preserving array order. Removing owner 'B' does the following:
     * [A B C D E] => [A E C D], and updates E's Trove struct to point to its new array index.
     */
    function _removeTroveOwner(
        address _lpTokenAddress,
        address _borrower,
        uint TroveOwnersArrayLength
    ) internal {
        Status troveStatus = Troves[_lpTokenAddress][_borrower].status;
        // It’s set in caller function `_closeTrove`
        assert(
            troveStatus != Status.nonExistent && troveStatus != Status.active
        );

        uint128 index = Troves[_lpTokenAddress][_borrower].arrayIndex;
        uint length = TroveOwnersArrayLength;
        uint idxLast = length.sub(1);

        assert(index <= idxLast);

        address addressToMove = TroveOwnersMap[_lpTokenAddress][idxLast];

        TroveOwnersMap[_lpTokenAddress][index] = addressToMove;
        Troves[_lpTokenAddress][addressToMove].arrayIndex = index;
        emit TroveIndexUpdated(_lpTokenAddress, addressToMove, index);

        TroveOwnersMap[_lpTokenAddress].pop();
    }

    // --- Recovery Mode and TCR functions ---

    function getTCR(address _lpTokenAddress, uint _price) external view override returns (uint) {
        return _getTCR(_lpTokenAddress, _price);
    }

    function checkRecoveryMode(address _lpTokenAddress, uint _price, uint _CCR) external view override returns (bool) {
        return _checkRecoveryMode(_lpTokenAddress, _price, _CCR);
    }


    // Check whether or not the system *would be* in Recovery Mode, given an ETH:USD price, and the entire system coll and debt.
    function _checkPotentialRecoveryMode(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price,
        uint CCR
    )
        internal
        pure
    returns (bool)
    {
        uint TCR = LiquityMath._computeCR(_entireSystemColl, _entireSystemDebt, _price);

        return TCR < CCR;
    }


    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view override returns (uint) {
        return _calcBorrowingRate(_calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint _baseRate) internal pure returns (uint) {
        return MathUpgradeable.min(
            BORROWING_FEE_FLOOR.add(_baseRate),
            MAX_BORROWING_FEE
        );
    }

    function getBorrowingFee(uint _CUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRate(), _CUSDDebt);
    }

    function getBorrowingFeeWithDecay(uint _CUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _CUSDDebt);
    }

    function _calcBorrowingFee(uint _borrowingRate, uint _CUSDDebt) internal pure returns (uint) {
        return _borrowingRate.mul(_CUSDDebt).div(DECIMAL_PRECISION);
    }


    // Updates the baseRate state variable based on time elapsed since the last redemption or LUSD borrowing operation.
    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOperations();

        uint decayedBaseRate = _calcDecayedBaseRate();
        assert(decayedBaseRate <= DECIMAL_PRECISION);  // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
    }


    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint timePassed = block.timestamp.sub(lastFeeOperationTime);

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function _calcDecayedBaseRate() internal view returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = LiquityMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate.mul(decayFactor).div(DECIMAL_PRECISION);
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint) {
        return (block.timestamp.sub(lastFeeOperationTime)).div(SECONDS_IN_ONE_MINUTE);
    }



    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "TroveManager: Caller is not the BorrowerOperations contract"
        );
    }

    function _requireTroveIsActive(
        address _lpTokenAddress,
        address _borrower
    ) internal view {
        require(
            Troves[_lpTokenAddress][_borrower].status == Status.active,
            "TroveManager: Trove does not exist or is closed"
        );
    }

    function _requireMoreThanOneTroveInSystem(
        address _lpTokenAddress,
        uint TroveOwnersArrayLength
    ) internal view {
        require(
            TroveOwnersArrayLength > 1 &&
                sortedTroves.getSize(_lpTokenAddress) > 1,
            "TroveManager: Only one trove in the system"
        );
    }

    // --- Trove property getters ---

    function getTroveStatus(address _lpTokenAddress, address _borrower) external view override returns (uint) {
        return uint(Troves[_lpTokenAddress][_borrower].status);
    }

    function getTroveStake(address _lpTokenAddress, address _borrower) external view override returns (uint) {
        return Troves[_lpTokenAddress][_borrower].stake;
    }

    function getTroveDebt(address _lpTokenAddress, address _borrower) external view override returns (uint) {
        return Troves[_lpTokenAddress][_borrower].debt;
    }

    function getTroveColl(address _lpTokenAddress, address _borrower) external view override returns (uint) {
        return Troves[_lpTokenAddress][_borrower].coll;
    }

    // --- Trove property setters, called by BorrowerOperations ---

    function setTroveStatus(address _lpTokenAddress, address _borrower, uint _num) external override {
        _requireCallerIsBorrowerOperations();
        Troves[_lpTokenAddress][_borrower].status = Status(_num);
    }

    function increaseTroveColl(address _lpTokenAddress, address _borrower, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Troves[_lpTokenAddress][_borrower].coll.add(_collIncrease);
        Troves[_lpTokenAddress][_borrower].coll = newColl;
        return newColl;
    }

    function decreaseTroveColl(address _lpTokenAddress, address _borrower, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Troves[_lpTokenAddress][_borrower].coll.sub(_collDecrease);
        Troves[_lpTokenAddress][_borrower].coll = newColl;
        return newColl;
    }

    function increaseTroveDebt(address _lpTokenAddress, address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Troves[_lpTokenAddress][_borrower].debt.add(_debtIncrease);
        Troves[_lpTokenAddress][_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseTroveDebt(address _lpTokenAddress, address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Troves[_lpTokenAddress][_borrower].debt.sub(_debtDecrease);
        Troves[_lpTokenAddress][_borrower].debt = newDebt;
        return newDebt;
    }
    
}