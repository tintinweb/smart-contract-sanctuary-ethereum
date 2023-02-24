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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IStakedToken {
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address owner) external returns(uint256);
    function name() external returns(string memory);
    function symbol() external returns(string memory);

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library DetailsLibraryUpdated {
    
    struct eachTransaction {
        
        uint128 stakeAmount;
        uint128 depositTime;
        uint128 fullWithdrawlTime;
        uint128 lastClaimTime;
        
        
    }

    struct StakeTypeData {
        uint128 stakeType;
        uint128 stakePeriod;
        uint128 depositFees;
        uint128 withdrawlFees;
        uint128 rewardRate;
        uint128 totalStakedIn;
        bool isActive;
    }

    
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interface/IStakedToken.sol";
import "./library/DetailsLibraryUpdated.sol";

contract SaitaStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint128;

    using DetailsLibraryUpdated for DetailsLibraryUpdated.eachTransaction;
    using DetailsLibraryUpdated for DetailsLibraryUpdated.StakeTypeData;

    IStakedToken public stakedToken;

    string public name;
    string public symbol;
    address public ownerWallet;
    address public treasury;
    uint128 public totalStaked;
    uint128 public emergencyFees;
    uint128 public platformFee;
    uint128 public maxStakeLimit;


    bool public claimAndWithdrawFreeze;

    DetailsLibraryUpdated.StakeTypeData[] public stakeTypesList;

    mapping(address => mapping(uint128 => DetailsLibraryUpdated.eachTransaction)) public userStakesData;

    event Deposit(uint128 stakeAmount, uint128 stakeType, uint128 stakePeriod, uint256 time, uint128 poolTotalStaked);
    event Withdraw(address indexed user, uint128 stakeAmount, uint128 stakeType, uint128 rewardAmount, uint256 time, uint128 poolTotalStaked);
    event Compound(address indexed user, uint128 rewardAmount, uint128 stakeType, uint256 time, uint128 poolTotalStaked);
    event Claim(address indexed user, uint128 rewardAmount, uint128 stakeType, uint256 time);
    event AddStakeType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate);
    event UpdateStakeType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate);
    event DeleteStakeType(uint128 _stakeType);
    event UpdateStakeToken(address indexed newTokenAddr);
    event EmergencyWithdrawn(address indexed user, uint128 amount, uint128 stakeType, uint256 time, uint128 poolTotalStaked);
    event UpdateEmergencyFee(address indexed _stakeToken, uint128 oldFee, uint128 newFee);
    event UpdatePlatformFee(address indexed _stakeToken, uint128 oldFee, uint128 newFee);
    event UpdateOwnerWallet(address indexed _stakeToken, address indexed oldOwnerWallet, address indexed newOwnerWallet);
    event UpdateTreasuryWallet(address indexed _stakeToken, address indexed oldTreasuryWallet, address indexed newTreasuryWallet);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _ownerWallet, address _stakedToken, 
                        uint128 _stakePeriod, uint128 _depositFees, 
                        uint128 _withdrawlsFees, uint128 _rewardRate, uint128 _emergencyFees, uint128 _platformFee, address _treasury, uint128 _maxStakeLimit) 
                        public initializer {
        require(_treasury != address(0), "TREASURY_WALLET_CANT_BE_NULL_ADDRESS");
        require(_emergencyFees > 0, "EMERGENCY_FEES_CANT_BE_ZERO");
        require(_platformFee > 0, "PLATFORM_FEE_CANT_BE_NULL");
        require(_ownerWallet !=address(0), "OWNER_WALLET_CANT_BE_NULL_ADDRESS");
        require(_stakedToken !=address(0), "TOKEN_ADDRESS_CANT_BE_NULL_ADDRESS");
        require(_depositFees < 10000 && _withdrawlsFees < 10000, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100%");             // FOR DEPOSIT AND WITHDRAWL FESS
                                                                                                                        // 0.01 % -----> input is 1
                                                                                                                        // 0.1% ------> input is 10
                                                                                                                        // 1% -------> input is 100
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        __Ownable_init();

        stakedToken = IStakedToken(_stakedToken);
        ownerWallet = _ownerWallet;    
        name = IStakedToken(_stakedToken).name();
        symbol = IStakedToken(_stakedToken).symbol();
        emergencyFees = _emergencyFees;
        platformFee = _platformFee;
        treasury = _treasury;
        maxStakeLimit = _maxStakeLimit;

        stakeTypesList.push(DetailsLibraryUpdated.StakeTypeData(0,_stakePeriod,_depositFees,_withdrawlsFees,_rewardRate,0, true));

    }
    
    function deposit(address user,uint128 _amount, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128 emitAmount, uint128 _period, uint128 _totalPoolStaked) {
        require(_amount>0, "STAKE_MORE_THAN_ZERO");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        transferPlatformFee(treasury, user, uint128(msg.value));

        DetailsLibraryUpdated.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        require(stakeType.isActive, "POOL_DISABLED");
        DetailsLibraryUpdated.eachTransaction storage stakes = userStakesData[user][_stakeType];
        {
        uint128 limitLeft;
        if(maxStakeLimit > stakes.stakeAmount) limitLeft = maxStakeLimit - stakes.stakeAmount;
        require(limitLeft > 0,"MAX_STAKE_LIMIT_REACHED");
        if(_amount > limitLeft) _amount = limitLeft;
        }

        _period = stakeType.stakePeriod;
        uint128 fees;
        uint128 actualAmount = _amount;

        if(stakeType.depositFees !=0) {
            fees = _amount * stakeType.depositFees *100 / 1000000;
            actualAmount = _amount - fees;
        }

        if(fees > 0) stakedToken.transferFrom(user, ownerWallet, fees);
        uint128 beforeAmount = uint128(stakedToken.balanceOf(address(this)));
        stakedToken.transferFrom(user, address(this), actualAmount);

        uint128 realAmount = uint128(stakedToken.balanceOf(address(this))) - beforeAmount;

        if(stakes.stakeAmount == 0) {
            stakes.depositTime = uint128(block.timestamp);
            stakes.lastClaimTime = uint128(block.timestamp);
            stakes.fullWithdrawlTime = uint128(uint128(block.timestamp).add(stakeType.stakePeriod * 60));            
            stakes.stakeAmount = realAmount;

            stakeType.totalStakedIn = uint128(stakeType.totalStakedIn.add(realAmount));
            // userTotalPerPool[user][_stakeType] +=  realAmount;
            totalStaked += realAmount;
            emit Deposit(realAmount, _stakeType, stakeType.stakePeriod, block.timestamp, stakeType.totalStakedIn);
            emitAmount = realAmount;
            _totalPoolStaked = stakeType.totalStakedIn;
        } else {
            {
            uint128 stakeTimeTillNow;
            uint128 totalRewardTillNow;

            if(uint128(block.timestamp) < userStakesData[user][_stakeType].fullWithdrawlTime) {
                stakeTimeTillNow = uint128(block.timestamp) - userStakesData[user][_stakeType].lastClaimTime;
                totalRewardTillNow = rewardCalculation(actualAmount, _stakeType, stakeTimeTillNow); 
            } else {
                if(stakeType.stakePeriod == 0) {
                    stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;
                    stakes.lastClaimTime = uint128(block.timestamp);
                    }
                else {
                    stakeTimeTillNow = stakes.fullWithdrawlTime - stakes.lastClaimTime;
                    stakes.lastClaimTime = stakes.fullWithdrawlTime;
                    }
                if(stakeTimeTillNow > 0 ) totalRewardTillNow = rewardCalculation(realAmount, _stakeType, stakeTimeTillNow); 
            }
            stakes.stakeAmount += totalRewardTillNow;
            stakeType.totalStakedIn += realAmount + totalRewardTillNow;
            totalStaked += realAmount + totalRewardTillNow;
            stakes.stakeAmount += realAmount;
            stakes.depositTime = uint128(block.timestamp);
            stakes.lastClaimTime = uint128(block.timestamp);
            stakes.fullWithdrawlTime = uint128(block.timestamp) + (stakeType.stakePeriod * 60);
            if(totalRewardTillNow > 0) claimReward(address(this), totalRewardTillNow);
            emitAmount = totalRewardTillNow + realAmount;
            }
            _totalPoolStaked = stakeType.totalStakedIn;
            emit Deposit(emitAmount, _stakeType, stakeType.stakePeriod, block.timestamp, stakeType.totalStakedIn);
        }
    }

    function compound(address user, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128, uint128, uint128) {
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        DetailsLibraryUpdated.eachTransaction storage stakes = userStakesData[user][_stakeType];
        require(stakes.stakeAmount > 0, "NOTHING_AT_STAKE");

        transferPlatformFee(treasury, user, uint128(msg.value));

        DetailsLibraryUpdated.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        require(stakeType.isActive, "POOL_DISABLED");

        uint128 totalRewardTillNow;
        uint128 actualAmount = stakes.stakeAmount;
        uint128 stakeTimeTillNow;

            if(uint128(block.timestamp) < stakes.fullWithdrawlTime) {
                stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;
                totalRewardTillNow = rewardCalculation(actualAmount, _stakeType, stakeTimeTillNow); 
                stakes.lastClaimTime = uint128(block.timestamp);
            } else {
                if(stakeType.stakePeriod == 0) {
                    stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;
                    stakes.lastClaimTime = uint128(block.timestamp);
                    }
                else {
                    stakeTimeTillNow = stakes.fullWithdrawlTime - stakes.lastClaimTime;
                    stakes.lastClaimTime = stakes.fullWithdrawlTime;
                    }

                if(stakeTimeTillNow > 0)
                totalRewardTillNow = rewardCalculation(actualAmount, _stakeType, stakeTimeTillNow);                
            }

            uint128 beforeAmount = uint128(stakedToken.balanceOf(address(this)));

            if(totalRewardTillNow > 0)
            claimReward(address(this), totalRewardTillNow);

            uint128 realAmount = uint128(stakedToken.balanceOf(address(this))) - beforeAmount;

            stakes.stakeAmount += realAmount;

            stakeType.totalStakedIn +=  realAmount;
            totalStaked += realAmount;
            emit Compound(user, realAmount, _stakeType, block.timestamp, stakeType.totalStakedIn);
            return (realAmount, stakeType.stakePeriod, stakeType.totalStakedIn);
    }

    function withdraw(address user, uint128 _amount, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128, uint128, uint128) {

        DetailsLibraryUpdated.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        require(stakeType.isActive, "POOL_DISABLED");

        require(_amount > 0, "WITHDRAW_MORE_THAN_ZERO");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        DetailsLibraryUpdated.eachTransaction storage stakes = userStakesData[user][_stakeType];
        require(_amount <= stakes.stakeAmount, "CANT_WITHDRAW_MORE_THAN_STAKED");   // --------

        require(uint128(block.timestamp) > stakes.fullWithdrawlTime, "CANT_UNSTAKE_BEFORE_LOCKUP_TIME");

        transferPlatformFee(treasury, user, uint128(msg.value));

        uint128 stakeTimeTillNow;
        if(stakeType.stakePeriod == 0) {
            stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;
            stakes.lastClaimTime = uint128(block.timestamp);

            }
        else {
            stakeTimeTillNow = stakes.fullWithdrawlTime - stakes.lastClaimTime;
            stakes.lastClaimTime = stakes.fullWithdrawlTime;
            }
        uint128 rewardTillNow;
        if(stakeTimeTillNow > 0) rewardTillNow = rewardCalculation(_amount, _stakeType, stakeTimeTillNow);         

        uint128 _withdrawlFees = stakeType.withdrawlFees;
        uint128 fees;
        uint128 actualAmount = _amount;

        stakes.stakeAmount -= actualAmount;
        stakeType.totalStakedIn -=  actualAmount;
        totalStaked -= actualAmount;

        if(_withdrawlFees !=0) {
            fees = _amount * _withdrawlFees *100 / 1000000;
            actualAmount = _amount - fees;
        }
        if(rewardTillNow > 0) claimReward(user, rewardTillNow);
        bool success;
        if(fees > 0)
        {
            success = stakedToken.transfer(ownerWallet, fees);
            if(!success) revert();
        }
        if(actualAmount > 0) {
            success = stakedToken.transfer(user, actualAmount);
            if(!success) revert();
        }
        emit Withdraw(user, actualAmount, _stakeType, rewardTillNow, block.timestamp, stakeType.totalStakedIn);
        return (actualAmount, stakeType.stakePeriod, stakeType.totalStakedIn);
    }

    function claim(address user, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128, uint128) {
        // require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        DetailsLibraryUpdated.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        require(stakeType.isActive, "POOL_DISABLED");

        require(stakeType.stakePeriod == 0, "CANT_CLAIM_FOR_THIS_TYPE");

        DetailsLibraryUpdated.eachTransaction storage stakes = userStakesData[user][_stakeType];
        require(uint128(block.timestamp) > stakes.fullWithdrawlTime, "WAIT_TO_CLAIM");
        uint128 totalRewardTillNow;
        uint128 actualAmount = stakes.stakeAmount;
        require(actualAmount > 0, "NOTHING_AT_STAKE");

        transferPlatformFee(treasury, user, uint128(msg.value));

        uint128 stakeTimeTillNow;
    
        stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;

        if(stakeTimeTillNow > 0) totalRewardTillNow = rewardCalculation(actualAmount, _stakeType, stakeTimeTillNow); 
        stakes.lastClaimTime = uint128(block.timestamp);
            
           
        if(totalRewardTillNow > 0)
        claimReward(user, totalRewardTillNow);

        emit Claim(user, totalRewardTillNow, _stakeType, block.timestamp);
        return (totalRewardTillNow, stakeType.stakePeriod);
    }

    function rewardCalculation(uint128 _amount, uint128 _stakeType, uint128 _time) public view returns(uint128) {
        DetailsLibraryUpdated.StakeTypeData memory stakeType = stakeTypesList[_stakeType];

        require(_amount > 0, "AMOUNT_SHOULD_BE_GREATER_THAN_ZERO");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        require(_time > 0, "INVALID_TIME");
        uint128 rate = stakeType.rewardRate;
        uint128 interest = (_amount * rate * _time) / (100 * 365 days);
        return interest;
    }

    function claimReward(address to, uint128 _rewardAmount) private {
        require(to != address(0), "INVALID_CLAIMER");
        require(_rewardAmount > 0, "INVALID_REWARD_AMOUNT");
        uint128 ownerBal = uint128(stakedToken.balanceOf(ownerWallet));
        if(_rewardAmount > ownerBal) claimAndWithdrawFreeze = true;
        require(!claimAndWithdrawFreeze, "CLAIM_AND_WITHDRAW_FREEZED");
        bool success = stakedToken.transferFrom(ownerWallet, to, _rewardAmount);
        if(!success) revert();
    }
    // FOR DEPOSIT AND WITHDRAWL FEES
    // 0.01 % -----> input is 1
    // 0.1% ------> input is 10
    // 1% -------> input is 100
    function addStakedType(uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate) external onlyOwner returns(uint128){
        // require(!stakeTypeExist[_stakeType], "STAKE_TYPE_EXISTS");
        require(_depositFees < 10000 && _withdrawlFees < 10000, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        // stakeTypeExist[_stakeType] = true;
        uint128 poolType = uint128(stakeTypesList.length);

        stakeTypesList.push(DetailsLibraryUpdated.StakeTypeData(poolType,_stakePeriod,_depositFees,_withdrawlFees,_rewardRate,0, true));

        emit AddStakeType(poolType, _stakePeriod, _depositFees, _withdrawlFees, _rewardRate);
        return poolType;
    }
    // FOR DEPOSIT AND WITHDRAWL FESS
    // 0.01 % -----> input is 1
    // 0.1% ------> input is 10
    // 1% -------> input is 100
    function updateStakeType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate) external onlyOwner {
        // require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        require(_depositFees < 10000 && _withdrawlFees < 10000, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");

        DetailsLibraryUpdated.StakeTypeData storage stakeType = stakeTypesList[_stakeType];

        stakeType.stakeType = _stakeType;
        stakeType.stakePeriod = _stakePeriod;
        stakeType.depositFees = _depositFees;
        stakeType.withdrawlFees = _withdrawlFees;
        stakeType.rewardRate = _rewardRate;

        emit UpdateStakeType(_stakeType, _stakePeriod, _depositFees, _withdrawlFees, _rewardRate);
    }

    function getPoolData(uint128 _stakeType) external view returns(DetailsLibraryUpdated.StakeTypeData memory) {
        // require(stakeTypeExist[_stakeType], "INVALID_STAKE_TYPE");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        require(stakeTypesList[_stakeType].isActive, "POOL_DISABLED");

        return stakeTypesList[_stakeType];
    }

    function deleteStakeType(uint128 _stakeType) external onlyOwner returns(bool) {
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        require(stakeTypesList[_stakeType].totalStakedIn == 0, "CANT_DELETE");

        stakeTypesList[_stakeType].isActive = false;

        emit DeleteStakeType(_stakeType);
        return false;
    }    

    function getPoolLength() external view returns(uint128) {
        return uint128(stakeTypesList.length);
    }

    function emergencyWithdraw(address user, uint128 _stakeType) external payable onlyOwner returns(uint128, uint128, uint128){
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        DetailsLibraryUpdated.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        DetailsLibraryUpdated.eachTransaction storage stakes = userStakesData[user][_stakeType];
        uint128 amount = stakes.stakeAmount;
        require( amount > 0, "NOTHING_TO_WITHDRAW");

        transferPlatformFee(treasury, user, uint128(msg.value));


        stakes.stakeAmount = 0;
        stakes.lastClaimTime = uint128(block.timestamp);

        stakeType.totalStakedIn -=  amount;
        totalStaked -= amount;

        uint128 fees = (amount * emergencyFees) / 100 ;
        bool success;
        if(fees > 0 ) {
            success = stakedToken.transfer(ownerWallet, fees);
            if(!success) revert();
            amount -= fees;
        }

        success = stakedToken.transfer(user, amount);
        if(!success) revert();

        emit EmergencyWithdrawn(user, amount, _stakeType, block.timestamp, stakeType.totalStakedIn);
        return (amount, stakeType.stakePeriod, stakeType.totalStakedIn);
    }

    function updateEmergencyFees(uint128 newFees) external onlyOwner {
        require(newFees > 0, "EMERGENCY_FEES_CANT_BE_ZERO");
        require(newFees != emergencyFees, "CANT_SET SAME_FEES");
        uint128 oldFee = emergencyFees;
        emergencyFees = newFees;
        
        emit UpdateEmergencyFee(address(stakedToken), oldFee, newFees);
    }

    function transferPlatformFee(address to, address _user,  uint128 _value) private {
        require(to != address(0), "CANT_SEND_TO_NULL_ADDRESS");
        require(_value >= platformFee, "INCREASE_PLATFORM_FEE");
        (bool success, ) = payable(to).call{value:platformFee}("");
        require(success, "PLATFORM_FEE_TRANSFER_FAILED");
        uint128 remainingEth = _value - platformFee;
        if (remainingEth > 0) {
            (success,) = payable(_user).call{value: remainingEth}("");
            require(success, "REFUND_REMAINING_ETHER_SENT_FAILED");
        }
    }

    function updatePlatformFee(uint128 newFee) external onlyOwner {
        require(newFee > 0, "PLATFORM_FEE_CANT_BE_NULL");
        require(newFee != platformFee, "PLATFORM_FEE_CANT_BE_SAME");

        uint128 oldFee = platformFee;
        platformFee = newFee;

        emit UpdatePlatformFee(address(stakedToken), oldFee, newFee);
    }

    function updateOwnerWallet(address newOwnerWallet) external onlyOwner {
        require(newOwnerWallet != address(0), "OWNER_CANT_BE_ZERO_ADDRESS");
        require(newOwnerWallet != ownerWallet, "ALREADY_SET_THIS OWNER");

        address oldOwnerWallet = ownerWallet;
        ownerWallet = newOwnerWallet;

        emit UpdateOwnerWallet(address(stakedToken), oldOwnerWallet, newOwnerWallet);
    }

    function updateTreasuryWallet(address newTreasuryWallet) external onlyOwner {
        require(newTreasuryWallet != address(0), "TREASURY_WALLET_CANT_BE_NULL");
        require(newTreasuryWallet != treasury, "ALREADY_SET_THS_WALLET");

        address oldTreasuryWallet = ownerWallet;
        treasury = newTreasuryWallet;

        emit UpdateTreasuryWallet(address(stakedToken), oldTreasuryWallet, newTreasuryWallet);
    }

    function updateStakeLimit(uint128 _newLimit) external onlyOwner {
        require(maxStakeLimit != _newLimit);
        maxStakeLimit = _newLimit;

    }
}