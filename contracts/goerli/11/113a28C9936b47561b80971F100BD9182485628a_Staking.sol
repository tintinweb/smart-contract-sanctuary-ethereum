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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
                                                                                                             
NNNNNNNN        NNNNNNNNFFFFFFFFFFFFFFFFFFFFFFTTTTTTTTTTTTTTTTTTTTTTTUUUUUUUU     UUUUUUUU     OOOOOOOOO     
N:::::::N       N::::::NF::::::::::::::::::::FT:::::::::::::::::::::TU::::::U     U::::::U   OO:::::::::OO   
N::::::::N      N::::::NF::::::::::::::::::::FT:::::::::::::::::::::TU::::::U     U::::::U OO:::::::::::::OO 
N:::::::::N     N::::::NFF::::::FFFFFFFFF::::FT:::::TT:::::::TT:::::TUU:::::U     U:::::UUO:::::::OOO:::::::O
N::::::::::N    N::::::N  F:::::F       FFFFFFTTTTTT  T:::::T  TTTTTT U:::::U     U:::::U O::::::O   O::::::O
N:::::::::::N   N::::::N  F:::::F                     T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N:::::::N::::N  N::::::N  F::::::FFFFFFFFFF           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N N::::N N::::::N  F:::::::::::::::F           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N  N::::N:::::::N  F:::::::::::::::F           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N   N:::::::::::N  F::::::FFFFFFFFFF           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N    N::::::::::N  F:::::F                     T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N     N:::::::::N  F:::::F                     T:::::T         U::::::U   U::::::U O::::::O   O::::::O
N::::::N      N::::::::NFF:::::::FF                 TT:::::::TT       U:::::::UUU:::::::U O:::::::OOO:::::::O
N::::::N       N:::::::NF::::::::FF                 T:::::::::T        UU:::::::::::::UU   OO:::::::::::::OO 
N::::::N        N::::::NF::::::::FF                 T:::::::::T          UU:::::::::UU       OO:::::::::OO   
NNNNNNNN         NNNNNNNFFFFFFFFFFF                 TTTTTTTTTTT            UUUUUUUUU           OOOOOOOOO     
                                                                                                             

*/

/**
 * @title Staking contract for a token
 * @author Muhammad Usman
 * @dev Contract to manage staking of Nuo tokens.
 * Contract that allows users to stake a token in any of the three available vaults (Vaults.vault_1, Vaults.vault_2, Vaults.vault_3). The contract is Ownable and Pausable, ensuring only the owner can perform certain operations while the contract can be paused to stop certain functionality.
 * Users can deposit tokens, stake in any of the three vaults and withdraw their funds along with any accrued rewards. The contract has an airdropContractAddress that can deposit tokens on behalf of its users. The contract also has a configurable harvesting bonus percentage that will be given to users on withdrawal of their stakes.
 * Allows users to stake Nuo tokens into a specific Vault for a set period of time.
 * Also allows users to withdraw their staked tokens before the end of the lockup period.
 * The contract is pausable by the owner in case of emergency or upgrade requirements.
 * The owner can also set the Nuo token address and the wallet address for the contract.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Vault.sol";

contract Staking is
    Initializable,
    Vault,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private stakeId;

    IERC20Upgradeable private Token;
    address private wallet;

    address private airdropContractAddress;

    /**
     * Initializer function that initializes the Staking contract.
     * @param _tokenAddress The address of the ERC20 token that will be staked.
     * @param _wallet The address of the wallet where the stake rewards will be transferred.
     * @param _airdropAddress The address of the airdrop contract that can deposit tokens on behalf of its users.
     * @param _harvestingBonusPercentage The percentage of reward bonus that will be given to users on withdrawal of their stakes.
     */

    function initialise(
        IERC20Upgradeable _tokenAddress,
        address _wallet,
        address _airdropAddress,
        uint256 _harvestingBonusPercentage
    ) public initializer {
        require(_wallet != address(0), "Stake: Invalid address");
        require(_airdropAddress != address(0), "Stake: Invalid address");

        Token = _tokenAddress;
        wallet = _wallet;
        airdropContractAddress = _airdropAddress;

        VAULTS[uint256(Vaults.vault_1)] = VaultConfig(
            60,
            1_000_000_000_000 ether,
            365 days
        );
        VAULTS[uint256(Vaults.vault_2)] = VaultConfig(
            90,
            500_000_000_000 ether,
            2 * 365 days
        );
        VAULTS[uint256(Vaults.vault_3)] = VaultConfig(
            120,
            500_000_000_000 ether,
            3 * 365 days
        );
        harvestingBonusPercentage = _harvestingBonusPercentage;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Modifier to only allow the airdrop contract to call a function.
     * @notice This modifier checks if the sender is the airdrop contract.
     */

    modifier onlyAirdropContract() {
        require(msg.sender == airdropContractAddress, "Stake: Invalid sender");
        _;
    }

    /**
     * @dev Modifier to check if the sender has reached the maximum number of stakes in a vault.
     * @param _sender The address of the sender.
     * @param _vault The Vaults enum.
     * @notice This modifier checks if the sender has already staked 5 times in the given vault.
     */
    modifier checkSendersStakeLimit(address _sender, Vaults _vault) {
        require(
            stakesInVaultByAddress[_sender][_vault] < 5,
            "Stake: A wallet can Stake upto 5 times in a Vault"
        );
        _;
    }

    /**
     * @dev Pauses the contract. Only callable by the owner of the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *@dev Unpauses the contract. Only callable by the owner of the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *@dev Gets the address of the Nuo token contract.
     *@return Address of the Nuo token contract.
     */
    function getNuoToken() public view returns (address) {
        return address(Token);
    }

    /**
     *@dev Sets the address of the Nuo token contract. Only callable by the owner of the contract.
     *@param _tokenAddr Address of the Nuo token contract.
     */
    function setNuoToken(IERC20Upgradeable _tokenAddr) public onlyOwner {
        require(address(_tokenAddr) != address(0), "Stake: Invalid address");
        Token = _tokenAddr;
    }

    /**
     *@dev Gets the address of the wallet associated with the contract.
     *@return Address of the wallet associated with the contract.
     */
    function getWalletAddress() public view returns (address) {
        return wallet;
    }

    /**
     *@dev Sets the address of the wallet associated with the contract. Only callable by the owner of the contract.
     *@param _wallet Address of the wallet associated with the contract.
     */
    function setWalletAddress(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Stake: Invalid address");
        wallet = _wallet;
    }

    /**
     *@dev Returns the address of the airdrop contract.
     *@return The address of the airdrop contract.
     */
    function getAirdropContractAddress() public view returns (address) {
        return airdropContractAddress;
    }

    /**
     *@dev Sets the address of the airdrop contract.
     *@param _airdropContractAddress The new address of the airdrop contract.
     */
    function setAirdropContractAddress(address _airdropContractAddress)
        public
        onlyOwner
    {
        require(
            address(_airdropContractAddress) != address(0),
            "Stake: Invalid address"
        );

        airdropContractAddress = _airdropContractAddress;
    }

    /**
     *@dev Returns all the available vaults as an enum.
     *@return The vaults enum.
     */
    function getVaults()
        public
        pure
        returns (
            Vaults,
            Vaults,
            Vaults
        )
    {
        return (Vaults.vault_1, Vaults.vault_2, Vaults.vault_3);
    }

    /**
     *@dev Returns the configuration for the specified vault.
     *@param _vault The vault to get the configuration for.
     *@return The configuration of the specified vault.
     */
    function getVaultConfiguration(Vaults _vault)
        public
        view
        returns (VaultConfig memory)
    {
        return VAULTS[uint256(_vault)];
    }

    /**
     *@dev Returns the percentage of harvesting bonus.
     *@return The percentage of harvesting bonus.
     */
    function getHarvestingBonusPercentage() public view returns (uint256) {
        return harvestingBonusPercentage;
    }

    /**
     *@dev Sets the percentage of harvesting bonus.
     *@param _harvestingBonusPercentage The new percentage of harvesting bonus.
     */
    function setHarvestingBonusPercentage(uint256 _harvestingBonusPercentage)
        public
        onlyOwner
    {
        harvestingBonusPercentage = _harvestingBonusPercentage;
    }

    /**
     *@dev Allows a user to stake a certain amount of tokens in a specified vault
     *@param _amount The amount of tokens to be staked
     *@param _vault The vault in which the tokens are to be staked
     *Requirements:
     *The contract must not be paused
     *The user must not have staked more than 5 times in the same vault
     *The user must have sufficient balance to stake the amount of tokens
     *The user must have approved the contract to spend at least _amount of tokens
     *The total amount of tokens staked in the specified vault must not exceed the max cap of that vault
     *Effects:
     *Increments the stakeId to keep track of stakes made
     *Updates the number of stakes made by the user in the specified vault
     *Calls the internal _stakeInVault function to handle the staking logic
     *Transfers the staked tokens from the user to the contract
     *Emits a Staked event with the user's address, stake ID, amount staked, vault, and timestamp
     */
    function stake(uint256 _amount, Vaults _vault)
        public
        whenNotPaused
        checkSendersStakeLimit(msg.sender, _vault)
    {
        require(
            Token.balanceOf(msg.sender) >= _amount,
            "Stake: Insufficient balance"
        );

        require(
            Token.allowance(msg.sender, address(this)) >= _amount,
            "Stake: Insufficient allowance"
        );

        require(
            (totalStakedInVault[_vault] + _amount) <=
                VAULTS[uint256(_vault)].maxCap,
            "Stake: Max stake cap reached"
        );

        stakeId.increment();

        stakesInVaultByAddress[msg.sender][_vault]++;
        _stakeInVault(msg.sender, _amount, _vault, stakeId.current());

        Token.transferFrom(msg.sender, address(this), _amount);

        emit Staked(
            msg.sender,
            stakeId.current(),
            _amount,
            _vault,
            block.timestamp
        );
    }

    /**
     *@dev Stake _amount of Token in a specific _vault by _sender through Airdrop contract.
     *@param _sender address The address of the sender.
     *@param _amount uint256 The amount of Token to stake.
     *@param _vault Vaults The enum of the vault where the stake will be made.
     *Requirements:
     *Only the Airdrop contract can call this function.
     *_sender must not have staked more than 5 times in the given _vault.
     *The total staked amount in the given _vault plus _amount must not exceed the maximum capacity of the vault.
     *Emits a {Staked} event indicating the amount of tokens staked, the sender, the vault, and the current timestamp.
     */
    function stakeByContract(
        address _sender,
        uint256 _amount,
        Vaults _vault
    ) external onlyAirdropContract checkSendersStakeLimit(_sender, _vault) {
        require(
            (totalStakedInVault[_vault] + _amount) <=
                VAULTS[uint256(_vault)].maxCap,
            "Stake: Max stake cap reached"
        );

        stakeId.increment();
        stakesInVaultByAddress[_sender][_vault]++;
        _stakeInVault(_sender, _amount, _vault, stakeId.current());

        emit Staked(
            _sender,
            stakeId.current(),
            _amount,
            _vault,
            block.timestamp
        );
    }

    /**
     *@dev Harvest rewards earned from a specific stake and restake them in the specified vault with a bonus.
     *@param _stakeId The ID of the stake to harvest rewards from.
     *@param _vault The vault where the rewards will be restaked with a bonus.
     *Requirements:
     *The function can only be called when the contract is not paused.
     *The function can only be called by the staker of the specified stake.
     *The stake must not have been unstaked.
     *There must be rewards to harvest.
     *The restaked amount plus bonus must not exceed the maximum capacity of the specified vault.
     *Effects:
     *Calculates the rewards earned from the specified stake.
     *Adds a bonus to the calculated rewards.
     *Restakes the calculated rewards plus bonus in the specified vault.
     *Transfers the bonus to the contract from the wallet.
     *Updates the stake information.
     *Emits a Harvest event with the staker address, the new stake ID, the harvested amount, the vault, the timestamp, and the bonus amount.
     */
    function harvestRewardTokens(uint256 _stakeId, Vaults _vault)
        public
        whenNotPaused
        nonReentrant
        checkSendersStakeLimit(msg.sender, _vault)
    {
        StakeInfo storage _stakeInfo = stakeInfoById[_stakeId];
        require(
            _stakeInfo.walletAddress == msg.sender,
            "Stake: Not the previous staker"
        );
        require(!_stakeInfo.unstaked, "Stake: No staked Tokens in the vault");
        uint256 _amountToRestake = _calculateRewards(_stakeId);

        require(_amountToRestake > 0, "Stake: Insufficient rewards to stake");

        uint256 _bonusAmount = ((_amountToRestake * harvestingBonusPercentage) /
            NUMERATOR);
        uint256 _amountWithBonus = _amountToRestake + _bonusAmount;

        require(
            (totalStakedInVault[_stakeInfo.vault] + _amountWithBonus) <=
                VAULTS[uint256(_stakeInfo.vault)].maxCap,
            "Stake: Max stake cap reached"
        );

        _stakeInfo.lastClaimedAt = block.timestamp;
        _stakeInfo.totalClaimed += _amountToRestake;

        stakeId.increment();

        stakesInVaultByAddress[msg.sender][_vault]++;
        _stakeInVault(msg.sender, _amountWithBonus, _vault, stakeId.current());
        Token.transferFrom(wallet, address(this), _bonusAmount);

        emit Harvest(
            msg.sender,
            stakeId.current(),
            _stakeId,
            _amountToRestake,
            _vault,
            block.timestamp,
            (_amountWithBonus - _amountToRestake)
        );
    }

    /**
     *
     *@dev Harvest all reward tokens from a particular vault and stake them again
     *@param _vault Address of the vault from which rewards will be harvested and staked
     *Requirements:
     *Function can only be called when contract is not paused
     *Function must not be reentrant
     *The sender must not exceed their stake limit
     *The total restake amount must be greater than zero
     *The total amount to be staked, including bonuses, must not exceed the maximum cap for the vault
     *The harvesting bonus percentage must be valid
     *Effects:
     *Increases the amount staked in the vault by the sender
     *Transfers the bonus amount from the wallet to the contract
     *Emits:
     *HarvestAll event when all rewards are harvested and restaked successfully
     */
    function harvestAllRewardTokens(Vaults _vault)
        public
        whenNotPaused
        nonReentrant
        checkSendersStakeLimit(msg.sender, _vault)
    {
        uint256 _totalRestakeAmount;
        uint256[] memory stakeIds = stakeIdsInVault[_vault][msg.sender];

        for (uint256 i = 0; i < stakeIds.length; i++) {
            StakeInfo storage _stakeInfo = stakeInfoById[stakeIds[i]];
            require(
                _stakeInfo.walletAddress == msg.sender,
                "Stake: Not the previous staker"
            );
            if (!_stakeInfo.unstaked) {
                uint256 restakeAmount = _calculateRewards(stakeIds[i]);
                _totalRestakeAmount += restakeAmount;

                _stakeInfo.lastClaimedAt = block.timestamp;
                _stakeInfo.totalClaimed += restakeAmount;
            }
        }

        require(
            _totalRestakeAmount > 0,
            "Stake: Insufficient rewards to stake"
        );

        uint256 _totalBonusAmount = ((_totalRestakeAmount *
            harvestingBonusPercentage) / NUMERATOR);
        uint256 _totalAmountWithBonus = _totalRestakeAmount + _totalBonusAmount;

        require(
            (totalStakedInVault[_vault] + _totalAmountWithBonus) <=
                VAULTS[uint256(_vault)].maxCap,
            "Stake: Max stake cap reached"
        );

        stakeId.increment();

        stakesInVaultByAddress[msg.sender][_vault]++;
        _stakeInVault(
            msg.sender,
            _totalAmountWithBonus,
            _vault,
            stakeId.current()
        );
        Token.transferFrom(wallet, address(this), _totalBonusAmount);

        emit HarvestAll(
            msg.sender,
            stakeId.current(),
            stakeIds,
            _totalRestakeAmount,
            _vault,
            block.timestamp,
            (_totalAmountWithBonus - _totalRestakeAmount)
        );
    }

    /**
     * @notice This function allows the staker to unstake their tokens and claim their rewards.
     * @dev The function first retrieves the stake information using the `_stakeId` parameter from the `stakeInfoById` mapping and stores it in the `_stakeInfo` variable.
     * It checks if the `walletAddress` in the `_stakeInfo` matches the `msg.sender`, i.e., the address calling the function. If not, it reverts with the message "Stake: Not the staker".
     * It checks if the stake has already been unstaked by checking the `unstaked` variable in the `_stakeInfo`. If it is true, it reverts with the message "Stake: No staked Tokens in the vault".
     * It retrieves the `VaultConfig` from the `VAULTS` mapping using the `_stakeInfo.vault` and stores it in the `vaultConfig` variable.
     * It checks if the current timestamp minus the `_stakeInfo.stakedAt` timestamp is greater than or equal to the `cliffInDays` of the `vaultConfig`. If not, it reverts with the message "Stake: Cannot unstake before the cliff".
     * It calculates the reward amount by calling the `_calculateRewards` function with the `_stakeId` parameter and stores it in the `_rewardAmount` variable.
     * It updates the `lastClaimedAt`, `totalClaimed`, and `unstaked` variables in the `_stakeInfo`.
     * It transfers the staked tokens back to the staker's address using the `transfer` function of the `Token` contract with the parameters `msg.sender` (i.e., staker's address) and `_stakeInfo.stakedAmount`.
     * It transfers the reward tokens from the `wallet` address to the staker's address using the `transferFrom` function of the `Token` contract with the parameters `wallet` (i.e., owner's address), `msg.sender` (i.e., staker's address), and `_rewardAmount`.
     * It emits an `Unstaked` event with the staker's address, `_stakeId`, `_stakeInfo.stakedAmount`, `_stakeInfo.totalClaimed`, `_stakeInfo.vault`, and the current timestamp as parameters.
     * @param _stakeId The ID of the stake to be unstaked
     */
    function unstake(uint256 _stakeId) public whenNotPaused nonReentrant {
        StakeInfo storage _stakeInfo = stakeInfoById[_stakeId];
        require(
            _stakeInfo.walletAddress == msg.sender,
            "Stake: Not the staker"
        );
        require(!_stakeInfo.unstaked, "Stake: No staked Tokens in the vault");
        VaultConfig memory vaultConfig = VAULTS[uint256(_stakeInfo.vault)];
        require(
            block.timestamp - _stakeInfo.stakedAt >= vaultConfig.cliffInDays,
            "Stake: Cannot unstake before the cliff"
        );

        uint256 _rewardAmount = _calculateRewards(_stakeId);

        _stakeInfo.lastClaimedAt = block.timestamp;
        _stakeInfo.totalClaimed += _rewardAmount;
        _stakeInfo.unstaked = true;

        Token.transfer(msg.sender, _stakeInfo.stakedAmount);
        Token.transferFrom(wallet, msg.sender, _rewardAmount);

        emit Unstaked(
            msg.sender,
            _stakeId,
            _stakeInfo.stakedAmount,
            _stakeInfo.totalClaimed,
            _stakeInfo.vault,
            block.timestamp
        );
    }

    /**
     *
     *@dev Allows the staker to claim their rewards from a specific stake
     *dev called the internal function _claimReward() to claim the reward tokens.
     *@param _stakeId The ID of the stake to claim rewards from
     *Emits a Claimed event with the details of the claim including the reward amount, stake ID, and timestamp
     *Throws an error if the caller is not the staker of the stake, or if there are no rewards to claim
     */
    function claimReward(uint256 _stakeId) public whenNotPaused nonReentrant {
        StakeInfo storage _stakeInfo = stakeInfoById[_stakeId];

        require(
            _stakeInfo.walletAddress == msg.sender,
            "Stake: Not the staker"
        );

        uint256 _rewardAmount = _calculateRewards(_stakeId);

        require(_rewardAmount > 0, "Stake: No Rewards to Claim");

        _stakeInfo.lastClaimedAt = block.timestamp;
        _stakeInfo.totalClaimed += _rewardAmount;

        Token.transferFrom(wallet, msg.sender, _rewardAmount);

        emit Claimed(
            msg.sender,
            _stakeId,
            _rewardAmount,
            _stakeInfo.vault,
            block.timestamp
        );
    }

    /**
     *
     *@dev Claim all reward tokens from a particular vault for the sender
     *@param _vault Address of the vault from which rewards will be claimed
     *Requirements:
     *Function can only be called when contract is not paused
     *Function must not be reentrant
     *Effects:
     *Increases the total amount claimed by the sender for each staked amount
     *Transfers the total reward amount from the wallet to the sender
     *Emits:
     *ClaimedAll event when all rewards are claimed successfully
     */
    function claimAllReward(Vaults _vault) public whenNotPaused nonReentrant {
        uint256 _totalReward;

        uint256[] memory stakeIds = stakeIdsInVault[_vault][msg.sender];

        for (uint256 i = 0; i < stakeIds.length; i++) {
            StakeInfo storage _stakeInfo = stakeInfoById[stakeIds[i]];

            require(
                _stakeInfo.walletAddress == msg.sender,
                "Stake: Not the staker"
            );

            uint256 _rewardAmount = _calculateRewards(stakeIds[i]);

            if (_rewardAmount > 0) {
                _totalReward += _rewardAmount;
                _stakeInfo.lastClaimedAt = block.timestamp;
                _stakeInfo.totalClaimed += _rewardAmount;
            }
        }
        require(_totalReward > 0, "Stake: No Rewards to Claim");
        Token.transferFrom(wallet, msg.sender, _totalReward);

        emit ClaimedAll(
            msg.sender,
            stakeIds,
            _totalReward,
            _vault,
            block.timestamp
        );
    }

    /**
     *
     *@dev Returns the amount of rewards that a staker would receive if they were to claim rewards for a specific stake
     *@param _stakeId The ID of the stake to calculate rewards for
     *@return The amount of rewards that can be claimed for the specified stake
     */
    function getStakingReward(uint256 _stakeId) public view returns (uint256) {
        return _calculateRewards(_stakeId);
    }

    /**
     *
     *@dev Returns an array of StakeInfo structs representing all stakes made by a specific wallet address in a specific vault
     *@param _addr The address of the wallet to retrieve stake info for
     *@param _vault The enum value representing the vault to retrieve stake info for
     *@return stakeInfos An array of StakeInfo structs representing all stakes made by the specified wallet address in the specified vault
     */
    function getStakeInfo(address _addr, Vaults _vault)
        public
        view
        returns (StakeInfo[] memory stakeInfos)
    {
        uint256[] memory stakeIds = stakeIdsInVault[_vault][_addr];
        stakeInfos = new StakeInfo[](stakeIds.length);

        for (uint256 i = 0; i < stakeIds.length; i++) {
            stakeInfos[i] = stakeInfoById[uint256(stakeIds[i])];
        }
    }

    /**
     *
     *@dev Returns the StakeInfo struct for a specific stake ID
     *@param _stakeId The ID of the stake to retrieve information for
     *@return The StakeInfo struct representing the specified stake
     */
    function getStakeInfoById(uint256 _stakeId)
        public
        view
        returns (StakeInfo memory)
    {
        return stakeInfoById[_stakeId];
    }

    /**
     *
     *@dev Returns the total number of stakes that have been made
     *@return The total number of stakes
     */
    function totalStakes() public view returns (uint256) {
        return stakeId.current();
    }

    /**
     *
     *@dev Returns the total amount of tokens staked in a specific vault
     *@param _vault The enum value representing the vault to retrieve the total staked tokens for
     *@return The total amount of tokens staked in the specified vault
     */
    function tokensStakedInVault(Vaults _vault) public view returns (uint256) {
        return totalStakedInVault[_vault];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Vault
 * @author Muhammad Usman
 * @dev An abstract contract that provides functionality for staking and harvesting rewards in multiple vaults.
 */

abstract contract Vault {
    /// @dev Constants used in calculations.
    uint256 constant NUMERATOR = 1000;
    uint256 constant ONE_YEAR = 365 days;

    /// @dev The percentage of bonus rewards earned when harvesting.
    uint256 harvestingBonusPercentage;

    /// @dev Enum defining the different types of vaults available for staking.
    enum Vaults {
        vault_1,
        vault_2,
        vault_3
    }

    /// @dev Struct containing information about a specific stake.
    struct StakeInfo {
        address walletAddress;
        uint256 stakeId;
        uint256 stakedAmount;
        uint256 lastClaimedAt;
        uint256 totalClaimed;
        uint256 stakedAt;
        Vaults vault;
        bool unstaked;
    }

    /// @dev Struct containing configuration information for a specific vault.
    struct VaultConfig {
        uint256 apr;
        uint256 maxCap;
        uint256 cliffInDays;
    }

    /// @dev An array containing the configuration for each of the three vaults.
    VaultConfig[3] VAULTS;

    /// @dev A mapping of the stake IDs associated with each wallet and vault.
    mapping(Vaults => mapping(address => uint256[])) internal stakeIdsInVault;
    /// @dev A mapping of the total amount staked in each vault.
    mapping(Vaults => uint256) internal totalStakedInVault;
    /// @dev A mapping of stake information associated with each stake ID.
    mapping(uint256 => StakeInfo) stakeInfoById;
    /// @dev A mapping of the number of stakes associated with each wallet and vault.
    mapping(address => mapping(Vaults => uint8)) stakesInVaultByAddress;

    /**
     * @dev Event emitted when a new stake is made.
     * @param walletAddr The address of the wallet making the stake.
     * @param stakeId The ID of the new stake.
     * @param amount The amount being staked.
     * @param vault The type of vault the stake is being made in.
     * @param timestamp The timestamp of the stake.
     */
    event Staked(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 amount,
        Vaults indexed vault,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a harvest is made.
     * @param walletAddr The address of the wallet making the harvest.
     * @param stakeId The ID of the stake being harvested.
     * @param previousStakeId The ID of the previous stake.
     * @param amount The amount being harvested.
     * @param vault The type of vault the stake is being harvested from.
     * @param timestamp The timestamp of the harvest.
     * @param bonus The amount of bonus rewards earned.
     */
    event Harvest(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 previousStakeId,
        uint256 amount,
        Vaults indexed vault,
        uint256 timestamp,
        uint256 bonus
    );

    event HarvestAll(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256[] previousStakeIds,
        uint256 amount,
        Vaults indexed vault,
        uint256 timestamp,
        uint256 bonus
    );

    /**
     * @dev Even emitted when unstaked
     * @param walletAddr The address of the wallet which is Unstaking
     * @param stakeId The ID of the stake being unstaked
     * @param stakedAmount Amount that was staked
     * @param totalRewardsClaimed Total reward earned
     * @param vault Vault where tokens were staked
     * @param timestamp Unix timestamp for unstake time
     */
    event Unstaked(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 stakedAmount,
        uint256 totalRewardsClaimed,
        Vaults indexed vault,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a user claims rewards from a staked amount.
     * @param walletAddr The address of the user who claimed the rewards.
     * @param stakeId The ID of the stake.
     * @param claimedAmount The amount of rewards claimed by the user.
     * @param vault The vault in which the stake was made.
     * @param timestamp The timestamp at which the rewards were claimed.
     */
    event Claimed(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 claimedAmount,
        Vaults indexed vault,
        uint256 timestamp
    );

    event ClaimedAll(
        address indexed walletAddr,
        uint256[] stakeId,
        uint256 claimedAmount,
        Vaults indexed vault,
        uint256 timestamp
    );

    /**
     *
     *@dev Internal function for staking an amount in a vault. This function creates a new StakeInfo object and stores it in stakeInfoById mapping. It also adds the stake ID to the stakeIdsInVault mapping and increments the totalStakedInVault value for the specified vault.
     *@param _address The address of the wallet that is staking.
     *@param _amount The amount to be staked.
     *@param _vault The vault to which the stake belongs.
     *@param _currentStakeId The current stake ID.
     */
    function _stakeInVault(
        address _address,
        uint256 _amount,
        Vaults _vault,
        uint256 _currentStakeId
    ) internal {
        stakeIdsInVault[_vault][_address].push(_currentStakeId);
        stakeInfoById[_currentStakeId] = StakeInfo(
            _address,
            _currentStakeId,
            _amount,
            block.timestamp,
            0,
            block.timestamp,
            _vault,
            false
        );

        totalStakedInVault[_vault] += _amount;
    }

    /**
     *
     *@dev Calculates the reward amount for a given stake ID based on the time elapsed
     *and the APR of the associated vault.
     *@param _stakeId The ID of the stake to calculate rewards for.
     *@return rewardAmount The amount of rewards to be claimed for the stake.
     */
    function _calculateRewards(uint256 _stakeId)
        internal
        view
        returns (uint256 rewardAmount)
    {
        StakeInfo memory stakeInfo = stakeInfoById[_stakeId];
        VaultConfig memory vault = VAULTS[uint256(stakeInfo.vault)];
        uint256 endTime = block.timestamp >
            (stakeInfo.stakedAt + vault.cliffInDays)
            ? stakeInfo.stakedAt + vault.cliffInDays
            : block.timestamp;

        if (endTime < stakeInfo.lastClaimedAt) {
            return (0);
        }

        uint256 totalTime = ((endTime - stakeInfo.lastClaimedAt) * NUMERATOR) /
            ONE_YEAR;

        uint256 rewardPercentage = totalTime * vault.apr;
        rewardAmount =
            (stakeInfo.stakedAmount * rewardPercentage) /
            (100 * NUMERATOR);
    }
}