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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IgETH {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function uri(uint256) external view returns (string memory);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function pause() external;

    function unpause() external;

    // gETH Specials

    function denominator() external view returns (uint256);

    function pricePerShare(uint256 id) external view returns (uint256);

    function priceUpdateTimestamp(uint256 id) external view returns (uint256);

    function setPricePerShare(uint256 price, uint256 id) external;

    function isInterface(
        address _interface,
        uint256 id
    ) external view returns (bool);

    function isAvoider(
        address account,
        uint256 id
    ) external view returns (bool);

    function avoidInterfaces(uint256 id, bool isAvoid) external;

    function setInterface(address _interface, uint256 id, bool isSet) external;

    function updateMinterRole(address Minter) external;

    function updatePauserRole(address Pauser) external;

    function updateOracleRole(address Oracle) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

interface ILPToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(string memory name, string memory symbol)
        external
        returns (bool);

    function mint(address recipient, uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "./IgETH.sol";

interface ISwap {
  // pool data view functions
  function getERC1155() external view returns (address);

  function getA() external view returns (uint256);

  function getAPrecise() external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function getToken() external view returns (uint256);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  function getDebt() external view returns (uint256);

  function getAdminBalance(uint256 index) external view returns (uint256);

  // min return calculation functions
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateTokenAmount(
    uint256[2] calldata amounts,
    bool deposit
  ) external view returns (uint256);

  function calculateRemoveLiquidity(
    uint256 amount
  ) external view returns (uint256[2] memory);

  function calculateRemoveLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256 availableTokenAmount);

  // state modifying functions
  function initialize(
    IgETH _gEth,
    uint256 _pooledTokenId,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    address lpTokenTargetAddress,
    address owner
  ) external returns (address lpToken);

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external payable returns (uint256);

  function addLiquidity(
    uint256[2] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external payable returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[2] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[2] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[2] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);

  function withdrawAdminFees() external;

  function setAdminFee(uint256 newAdminFee) external;

  function setSwapFee(uint256 newSwapFee) external;

  function rampA(uint256 futureA, uint256 futureTime) external;

  function stopRampA() external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title OwnerPausable
 * @notice An ownable contract allows the owner to pause and unpause the
 * contract without a delay.
 * @dev Only methods using the provided modifiers will be paused.
 */
abstract contract OwnerPausableUpgradeable is
    OwnableUpgradeable,
    PausableUpgradeable
{
    function __OwnerPausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    }

    /**
     * @notice Pause the contract. Revert if already paused.
     */
    function pause() external onlyOwner {
        PausableUpgradeable._pause();
    }

    /**
     * @notice Unpause the contract. Revert if already unpaused.
     */
    function unpause() external onlyOwner {
        PausableUpgradeable._unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../interfaces/IgETH.sol";
import "./helpers/OwnerPausableUpgradeable.sol";
import "./utils/SwapUtils.sol";
import "./utils/AmplificationUtils.sol";
import "../../interfaces/ISwap.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 * @dev The main functionality of Withdrawal Pools is allowing the depositors to have instant withdrawals
 * relying on the Oracle Price, with the help of Liquidity Providers.
 * It is important to change the focus point (1-1) of the pricing algorithm with PriceIn and PriceOut functions.
 * Because the underlying price of the staked assets are expected to raise in time.
 * One can see this similar to accomplishing a "rebasing" logic, with the help of a trusted price source.
 */
contract Swap is
  ISwap,
  OwnerPausableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC1155HolderUpgradeable
{
  using SwapUtils for SwapUtils.Swap;
  using AmplificationUtils for SwapUtils.Swap;

  // Struct storing data responsible for automatic market maker functionalities. In order to
  // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
  SwapUtils.Swap public swapStorage;

  /*** EVENTS ***/

  // events replicated from SwapUtils to make the ABI easier
  event TokenSwap(
    address indexed buyer,
    uint256 tokensSold,
    uint256 tokensBought,
    uint128 soldId,
    uint128 boughtId
  );
  event AddLiquidity(
    address indexed provider,
    uint256[2] tokenAmounts,
    uint256[2] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(
    address indexed provider,
    uint256[2] tokenAmounts,
    uint256 lpTokenSupply
  );
  event RemoveLiquidityOne(
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[2] tokenAmounts,
    uint256[2] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(uint256 newAdminFee);
  event NewSwapFee(uint256 newSwapFee);
  event NewWithdrawFee(uint256 newWithdrawFee);
  event RampA(
    uint256 oldA,
    uint256 newA,
    uint256 initialTime,
    uint256 futureTime
  );
  event StopRampA(uint256 currentA, uint256 time);

  /**
   * @notice Initializes this Swap contract with the given parameters.
   * This will also clone a LPToken contract that represents users'
   * LP positions. The owner of LPToken will be this contract - which means
   * only this contract is allowed to mint/burn tokens.
   *
   * @param _gETH reference of the ERC1155 contract
   * @param _pooledTokenId gEther ID that the Pool is operating with
   * @param lpTokenName the long-form name of the token to be deployed
   * @param lpTokenSymbol the short symbol for the token to be deployed
   * @param lpTokenTargetAddress the address of an existing LPToken contract to use as a target
   */
  function initialize(
    IgETH _gETH,
    uint256 _pooledTokenId,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    address lpTokenTargetAddress,
    address owner
  ) public virtual override initializer returns (address) {
    __OwnerPausable_init();
    __ReentrancyGuard_init();
    __ERC1155Holder_init();

    require(
      lpTokenTargetAddress != address(0),
      "Swap: lpTokenTargetAddress can not be zero"
    );
    require(owner != address(0), "Swap: owner can not be zero");
    require(address(_gETH) != address(0), "Swap: _gETH can not be zero");
    require(_pooledTokenId != 0, "Swap: _pooledTokenId can not be zero");

    // Clone and initialize a LPToken contract
    ILPToken lpToken = ILPToken(Clones.clone(lpTokenTargetAddress));

    require(
      lpToken.initialize(lpTokenName, lpTokenSymbol),
      "Swap: could not init lpToken clone"
    );

    // Initialize swapStorage struct
    swapStorage.gETH = _gETH;
    swapStorage.lpToken = lpToken;
    swapStorage.pooledTokenId = _pooledTokenId;
    swapStorage.initialA = 60 * AmplificationUtils.A_PRECISION;
    swapStorage.futureA = 60 * AmplificationUtils.A_PRECISION;
    swapStorage.swapFee = (4 * PERCENTAGE_DENOMINATOR) / 10000;
    swapStorage.adminFee = 0;

    super.transferOwnership(owner);
    return address(lpToken);
  }

  /*** MODIFIERS ***/

  /**
   * @notice Modifier to check deadline against current timestamp
   * @param deadline latest timestamp to accept this transaction
   */
  modifier deadlineCheck(uint256 deadline) {
    require(block.timestamp <= deadline, "Swap: Deadline not met");
    _;
  }

  /*** VIEW FUNCTIONS ***/
  function getERC1155() external view virtual override returns (address) {
    return address(swapStorage.gETH);
  }

  /**
   * @notice Return A, the amplification coefficient * n * (n - 1)
   * @dev See the StableSwap paper for details
   * @return A parameter
   */
  function getA() external view virtual override returns (uint256) {
    return swapStorage.getA();
  }

  /**
   * @notice Return A in its raw precision form
   * @dev See the StableSwap paper for details
   * @return A parameter in its raw precision form
   */
  function getAPrecise() external view virtual override returns (uint256) {
    return swapStorage.getAPrecise();
  }

  /**
   * @notice Return id of the pooled token
   * @return id of the pooled gEther token
   */
  function getSwapFee() external view virtual override returns (uint256) {
    return swapStorage.swapFee;
  }

  function getToken() external view virtual override returns (uint256) {
    return swapStorage.pooledTokenId;
  }

  /**
   * @notice Return current balance of the pooled token at given index
   * @param index the index of the token
   * @return current balance of the pooled token at given index with token's native precision
   */
  function getTokenBalance(
    uint8 index
  ) external view virtual override returns (uint256) {
    require(index < 2, "Swap: Index out of range");
    return swapStorage.balances[index];
  }

  /**
   * @notice Get the virtual price, to help calculate profit
   * @return the virtual price
   */
  function getVirtualPrice() external view virtual override returns (uint256) {
    return swapStorage.getVirtualPrice();
  }

  /**
   * @notice Debt, The amount of buyback for stable pricing (1=1).
   * @return debt the half of the D StableSwap invariant when debt is needed to be payed.
   */
  function getDebt() external view virtual override returns (uint256) {
    // might change when price is in.
    return swapStorage.getDebt();
  }

  /**
   * @notice Calculate amount of tokens you receive on swap
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell. If the token charges
   * a fee on transfers, use the amount that gets transferred after the fee.
   * @return amount of tokens the user will receive
   */
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view virtual override returns (uint256) {
    return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
  }

  /**
   * @notice A simple method to calculate prices from deposits or
   * withdrawals, excluding fees but including slippage. This is
   * helpful as an input into the various "min" parameters on calls
   * to fight front-running
   *
   * @dev This shouldn't be used outside frontends for user estimates.
   *
   * @param amounts an array of token amounts to deposit or withdrawal,
   * corresponding to pooledTokens. The amount should be in each
   * pooled token's native precision. If a token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @param deposit whether this is a deposit or a withdrawal
   * @return token amount the user will receive
   */
  function calculateTokenAmount(
    uint256[2] calldata amounts,
    bool deposit
  ) external view virtual override returns (uint256) {
    return swapStorage.calculateTokenAmount(amounts, deposit);
  }

  /**
   * @notice A simple method to calculate amount of each underlying
   * tokens that is returned upon burning given amount of LP tokens
   * @param amount the amount of LP tokens that would be burned on withdrawal
   * @return array of token balances that the user will receive
   */
  function calculateRemoveLiquidity(
    uint256 amount
  ) external view virtual override returns (uint256[2] memory) {
    return swapStorage.calculateRemoveLiquidity(amount);
  }

  /**
   * @notice Calculate the amount of underlying token available to withdraw
   * when withdrawing via only single token
   * @param tokenAmount the amount of LP token to burn
   * @param tokenIndex index of which token will be withdrawn
   * @return availableTokenAmount calculated amount of underlying token
   * available to withdraw
   */
  function calculateRemoveLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view virtual override returns (uint256 availableTokenAmount) {
    return swapStorage.calculateWithdrawOneToken(tokenAmount, tokenIndex);
  }

  /**
   * @notice This function reads the accumulated amount of admin fees of the token with given index
   * @param index Index of the pooled token
   * @return admin's token balance in the token's precision
   */
  function getAdminBalance(
    uint256 index
  ) external view virtual override returns (uint256) {
    return swapStorage.getAdminBalance(index);
  }

  /*** STATE MODIFYING FUNCTIONS ***/

  /**
   * @notice Swap two tokens using this pool
   * @param tokenIndexFrom the token the user wants to swap from
   * @param tokenIndexTo the token the user wants to swap to
   * @param dx the amount of tokens the user wants to swap from
   * @param minDy the min amount the user would like to receive, or revert.
   * @param deadline latest timestamp to accept this transaction
   */
  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  )
    external
    payable
    virtual
    override
    nonReentrant
    whenNotPaused
    deadlineCheck(deadline)
    returns (uint256)
  {
    return swapStorage.swap(tokenIndexFrom, tokenIndexTo, dx, minDy);
  }

  /**
   * @notice Add liquidity to the pool with the given amounts of tokens
   * @param amounts the amounts of each token to add, in their native precision
   * @param minToMint the minimum LP tokens adding this amount of liquidity
   * should mint, otherwise revert. Handy for front-running mitigation
   * @param deadline latest timestamp to accept this transaction
   * @return amount of LP token user minted and received
   */
  function addLiquidity(
    uint256[2] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  )
    external
    payable
    virtual
    override
    nonReentrant
    whenNotPaused
    deadlineCheck(deadline)
    returns (uint256)
  {
    return swapStorage.addLiquidity(amounts, minToMint);
  }

  /**
   * @notice Burn LP tokens to remove liquidity from the pool.
   * @dev Liquidity can always be removed, even when the pool is paused.
   * @param amount the amount of LP tokens to burn
   * @param minAmounts the minimum amounts of each token in the pool
   *        acceptable for this burn. Useful as a front-running mitigation
   * @param deadline latest timestamp to accept this transaction
   * @return amounts of tokens user received
   */
  function removeLiquidity(
    uint256 amount,
    uint256[2] calldata minAmounts,
    uint256 deadline
  )
    external
    virtual
    override
    nonReentrant
    deadlineCheck(deadline)
    returns (uint256[2] memory)
  {
    return swapStorage.removeLiquidity(amount, minAmounts);
  }

  /**
   * @notice Remove liquidity from the pool all in one token.
   * @param tokenAmount the amount of the token you want to receive
   * @param tokenIndex the index of the token you want to receive
   * @param minAmount the minimum amount to withdraw, otherwise revert
   * @param deadline latest timestamp to accept this transaction
   * @return amount of chosen token user received
   */
  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  )
    external
    virtual
    override
    nonReentrant
    whenNotPaused
    deadlineCheck(deadline)
    returns (uint256)
  {
    return
      swapStorage.removeLiquidityOneToken(tokenAmount, tokenIndex, minAmount);
  }

  /**
   * @notice Remove liquidity from the pool, weighted differently than the
   * pool's current balances.
   * @param amounts how much of each token to withdraw
   * @param maxBurnAmount the max LP token provider is willing to pay to
   * remove liquidity. Useful as a front-running mitigation.
   * @param deadline latest timestamp to accept this transaction
   * @return amount of LP tokens burned
   */
  function removeLiquidityImbalance(
    uint256[2] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  )
    external
    virtual
    override
    nonReentrant
    whenNotPaused
    deadlineCheck(deadline)
    returns (uint256)
  {
    return swapStorage.removeLiquidityImbalance(amounts, maxBurnAmount);
  }

  /*** ADMIN FUNCTIONS ***/

  /**
   * @notice Withdraw all admin fees to the contract owner
   */
  function withdrawAdminFees()
    external
    virtual
    override
    onlyOwner
    nonReentrant
  {
    swapStorage.withdrawAdminFees(owner());
  }

  /**
   * @notice Update the admin fee. Admin fee takes portion of the swap fee.
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setAdminFee(
    uint256 newAdminFee
  ) external virtual override onlyOwner {
    swapStorage.setAdminFee(newAdminFee);
  }

  /**
   * @notice Update the swap fee to be applied on swaps
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(uint256 newSwapFee) external virtual override onlyOwner {
    swapStorage.setSwapFee(newSwapFee);
  }

  /**
   * @notice Start ramping up or down A parameter towards given futureA and futureTime
   * Checks if the change is too rapid, and commits the new A value only when it falls under
   * the limit range.
   * @param futureA the new A to ramp towards
   * @param futureTime timestamp when the new A should be reached
   */
  function rampA(
    uint256 futureA,
    uint256 futureTime
  ) external virtual override onlyOwner {
    swapStorage.rampA(futureA, futureTime);
  }

  /**
   * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
   */
  function stopRampA() external virtual override onlyOwner {
    swapStorage.stopRampA();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "./SwapUtils.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
    event RampA(
        uint256 oldA,
        uint256 newA,
        uint256 initialTime,
        uint256 futureTime
    );
    event StopRampA(uint256 currentA, uint256 time);

    // Constant values used in ramping A calculations
    uint256 public constant A_PRECISION = 100;
    uint256 public constant MAX_A = 10**6;
    uint256 private constant MAX_A_CHANGE = 2;
    uint256 private constant MIN_RAMP_TIME = 14 days;

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter
     */
    function getA(SwapUtils.Swap storage self) internal view returns (uint256) {
        return _getAPrecise(self) / (A_PRECISION);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function getAPrecise(SwapUtils.Swap storage self)
        internal
        view
        returns (uint256)
    {
        return _getAPrecise(self);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function _getAPrecise(SwapUtils.Swap storage self)
        internal
        view
        returns (uint256)
    {
        uint256 t1 = self.futureATime; // time when ramp is finished
        uint256 a1 = self.futureA; // final A value when ramp is finished

        if (block.timestamp < t1) {
            uint256 t0 = self.initialATime; // time when ramp is started
            uint256 a0 = self.initialA; // initial A value when ramp is started
            if (a1 > a0) {
                // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
                return a0 + ((a1 - a0) * (block.timestamp - t0)) / (t1 - t0);
            } else {
                // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
                return a0 - ((a0 - a1) * (block.timestamp - t0)) / (t1 - t0);
            }
        } else {
            return a1;
        }
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param self Swap struct to update
     * @param futureA_ the new A to ramp towards
     * @param futureTime_ timestamp when the new A should be reached
     */
    function rampA(
        SwapUtils.Swap storage self,
        uint256 futureA_,
        uint256 futureTime_
    ) internal {
        require(
            block.timestamp >= self.initialATime + 1 days,
            "Wait 1 day before starting ramp"
        );
        require(
            futureTime_ >= block.timestamp + MIN_RAMP_TIME,
            "Insufficient ramp time"
        );
        require(
            futureA_ > 0 && futureA_ < MAX_A,
            "futureA_ must be > 0 and < MAX_A"
        );

        uint256 initialAPrecise = _getAPrecise(self);
        uint256 futureAPrecise = futureA_ * A_PRECISION;

        if (futureAPrecise < initialAPrecise) {
            require(
                futureAPrecise * MAX_A_CHANGE >= initialAPrecise,
                "futureA_ is too small"
            );
        } else {
            require(
                futureAPrecise <= initialAPrecise * MAX_A_CHANGE,
                "futureA_ is too large"
            );
        }

        self.initialA = initialAPrecise;
        self.futureA = futureAPrecise;
        self.initialATime = block.timestamp;
        self.futureATime = futureTime_;

        emit RampA(
            initialAPrecise,
            futureAPrecise,
            block.timestamp,
            futureTime_
        );
    }

    /**
     * @notice Stops ramping A immediately. Once this function is called, rampA()
     * cannot be called for another 24 hours
     * @param self Swap struct to update
     */
    function stopRampA(SwapUtils.Swap storage self) internal {
        require(self.futureATime > block.timestamp, "Ramp is already stopped");

        uint256 currentA = _getAPrecise(self);
        self.initialA = currentA;
        self.futureA = currentA;
        self.initialATime = block.timestamp;
        self.futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

/**
 * @title MathUtils library
 * @notice  Contains functions for calculating differences between two uint256.
 */
library MathUtils {
    /**
     * @notice Compares a and b and returns true if the difference between a and b
     *         is less than 1 or equal to each other.
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return True if the difference between a and b is less than 1 or equal,
     *         otherwise return false
     */
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        return (difference(a, b) <= 1);
    }

    /**
     * @notice Calculates absolute difference between a and b
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return Difference between a and b
     */
    function difference(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        }
        return b - a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./MathUtils.sol";
import "./AmplificationUtils.sol";
import {PERCENTAGE_DENOMINATOR} from "../../utils/globals.sol";
import "../../../interfaces/ILPToken.sol";
import "../../../interfaces/IgETH.sol";

/**
 * @title SwapUtils library
 *
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 *
 * @notice A library to be used within Swap.sol. Contains functions responsible for custody and AMM functionalities with some changes.
 * The main functionality of Withdrawal Pools is allowing the depositors to have instant withdrawals
 * relying on the Oracle Price, with the help of Liquidity Providers.
 * It is important to change the focus point (1-1) of the pricing algorithm with PriceIn and PriceOut functions.
 * Because the underlying price of the staked assets are expected to raise in time.
 * One can see this similar to accomplishing a "rebasing" logic, with the help of a trusted price source.
 *
 * @dev Whenever "Effective Balance" is mentioned it refers to the balance projected with the underlying price.
 */
library SwapUtils {
  using MathUtils for uint256;

  /*** EVENTS ***/

  event TokenSwap(
    address indexed buyer,
    uint256 tokensSold,
    uint256 tokensBought,
    uint128 soldId,
    uint128 boughtId
  );
  event AddLiquidity(
    address indexed provider,
    uint256[2] tokenAmounts,
    uint256[2] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(
    address indexed provider,
    uint256[2] tokenAmounts,
    uint256 lpTokenSupply
  );
  event RemoveLiquidityOne(
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[2] tokenAmounts,
    uint256[2] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(uint256 newAdminFee);
  event NewSwapFee(uint256 newSwapFee);

  /**
   * @param gETH ERC1155 contract reference
   * @param lpToken address of the LP Token
   * @param pooledTokenId gETH ID of the pooled derivative
   * @param initialA the amplification coefficient * n * (n - 1)
   * @param futureA the amplification coef that will be effective after futureATime
   * @param initialATime variable around the ramp management of A
   * @param futureATime variable around the ramp management of A
   * @param swapFee fee as a percentage/PERCENTAGE_DENOMINATOR, will be deducted from resulting tokens of a swap
   * @param adminFee fee as a percentage/PERCENTAGE_DENOMINATOR, will be deducted from swapFee
   * @param balances the pool balance as [ETH, gETH]; the contract's actual token balance might differ
   * @param __gap keep the contract size at 16
   */
  struct Swap {
    IgETH gETH;
    ILPToken lpToken;
    uint256 pooledTokenId;
    uint256 initialA;
    uint256 futureA;
    uint256 initialATime;
    uint256 futureATime;
    uint256 swapFee;
    uint256 adminFee;
    uint256[2] balances;
    uint256[8] __gap;
  }

  // Struct storing variables used in calculations in the
  // calculateWithdrawOneTokenDY function to avoid stack too deep errors
  struct CalculateWithdrawOneTokenDYInfo {
    uint256 d0;
    uint256 d1;
    uint256 newY;
    uint256 feePerToken;
    uint256 preciseA;
  }

  // Struct storing variables used in calculations in the
  // {add,remove} Liquidity functions to avoid stack too deep errors
  struct ManageLiquidityInfo {
    ILPToken lpToken;
    uint256 d0;
    uint256 d1;
    uint256 d2;
    uint256 preciseA;
    uint256 totalSupply;
    uint256[2] balances;
  }

  // Max swap fee is 1% or 100bps of each swap
  uint256 public constant MAX_SWAP_FEE = 10 ** 8;

  // Max adminFee is 100% of the swapFee
  // adminFee does not add additional fee on top of swapFee
  // instead it takes a certain percentage of the swapFee.
  // Therefore it has no impact on users but only on the earnings of LPs
  uint256 public constant MAX_ADMIN_FEE = 10 ** 10;

  // Constant value used as max loop limit
  uint256 private constant MAX_LOOP_LIMIT = 256;

  /*** VIEW & PURE FUNCTIONS ***/

  function _getAPrecise(Swap storage self) internal view returns (uint256) {
    return AmplificationUtils._getAPrecise(self);
  }

  /**
   * @notice This function MULTIPLIES the Staked Ether token (gETH) balance with underlying relative price (pricePerShare),
   * to keep pricing around 1-OraclePrice instead of 1-1 like stableSwap pool.
   * @dev this function assumes prices are sent with the indexes that [ETH, gETH]
   * @param balance balance that will be taken into calculation
   * @param i if i is 0 it means we are dealing with ETH, if i is 1 it is gETH
   */
  function _pricedIn(
    Swap storage self,
    uint256 balance,
    uint256 i
  ) internal view returns (uint256) {
    return
      i == 1
        ? (balance * self.gETH.pricePerShare(self.pooledTokenId)) /
          self.gETH.denominator()
        : balance;
  }

  /**
   * @notice This function DIVIDES the Staked Ether token (gETH) balance with underlying relative price (pricePerShare),
   * to keep pricing around 1-OraclePrice instead of 1-1 like stableSwap pool.
   * @dev this function assumes prices are sent with the indexes that [ETH, gETH]
   * @param balance balance that will be taken into calculation
   * @param i if i is 0 it means we are dealing with ETH, if i is 1 it is gETH
   */
  function _pricedOut(
    Swap storage self,
    uint256 balance,
    uint256 i
  ) internal view returns (uint256) {
    return
      i == 1
        ? (balance * self.gETH.denominator()) /
          self.gETH.pricePerShare(self.pooledTokenId)
        : balance;
  }

  /**
   * @notice This function MULTIPLIES the Staked Ether token (gETH) balance with underlying relative price (pricePerShare),
   * to keep pricing around 1-OraclePrice instead of 1-1 like stableSwap pool.
   * @dev this function assumes prices are sent with the indexes that [ETH, gETH]
   * @param balances ARRAY of balances that will be taken into calculation
   */
  function _pricedInBatch(
    Swap storage self,
    uint256[2] memory balances
  ) internal view returns (uint256[2] memory _p) {
    _p[0] = balances[0];
    _p[1] =
      (balances[1] * self.gETH.pricePerShare(self.pooledTokenId)) /
      self.gETH.denominator();
    return _p;
  }

  /**
   * @notice This function DIVIDES the Staked Ether token (gETH) balance with underlying relative price (pricePerShare),
   * to keep pricing around 1-OraclePrice instead of 1-1 like stableSwap pool.
   * @dev this function assumes prices are sent with the indexes that [ETH, gETH]
   * @param balances ARRAY of balances that will be taken into calculation
   */
  function _pricedOutBatch(
    Swap storage self,
    uint256[2] memory balances
  ) internal view returns (uint256[2] memory _p) {
    _p[0] = balances[0];
    _p[1] =
      (balances[1] * self.gETH.denominator()) /
      self.gETH.pricePerShare(self.pooledTokenId);
    return _p;
  }

  /**
   * @notice Calculate the dy, the amount of selected token that user receives and
   * the fee of withdrawing in one token
   * @param tokenAmount the amount to withdraw in the pool's precision
   * @param tokenIndex which token will be withdrawn
   * @param self Swap struct to read from
   * @return the amount of token user will receive
   */
  function calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256) {
    (uint256 availableTokenAmount, ) = _calculateWithdrawOneToken(
      self,
      tokenAmount,
      tokenIndex,
      self.lpToken.totalSupply()
    );
    return availableTokenAmount;
  }

  function _calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 totalSupply
  ) internal view returns (uint256, uint256) {
    uint256 dy;
    uint256 newY;
    uint256 currentY;

    (dy, newY, currentY) = calculateWithdrawOneTokenDY(
      self,
      tokenIndex,
      tokenAmount,
      totalSupply
    );

    uint256 dySwapFee = currentY - newY - dy;

    return (dy, dySwapFee);
  }

  /**
   * @notice Calculate the dy of withdrawing in one token
   * @param self Swap struct to read from
   * @param tokenIndex which token will be withdrawn
   * @param tokenAmount the amount to withdraw in the pools precision
   * @return the d and the new y after withdrawing one token
   */
  function calculateWithdrawOneTokenDY(
    Swap storage self,
    uint8 tokenIndex,
    uint256 tokenAmount,
    uint256 totalSupply
  ) internal view returns (uint256, uint256, uint256) {
    // Get the current D, then solve the stableswap invariant
    // y_i for D - tokenAmount

    require(tokenIndex < 2, "Token index out of range");

    CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(
      0,
      0,
      0,
      0,
      0
    );
    v.preciseA = _getAPrecise(self);
    v.d0 = getD(_pricedInBatch(self, self.balances), v.preciseA);
    v.d1 = v.d0 - ((tokenAmount * v.d0) / totalSupply);

    require(
      tokenAmount <= self.balances[tokenIndex],
      "Withdraw exceeds available"
    );

    v.newY = _pricedOut(
      self,
      getYD(v.preciseA, tokenIndex, _pricedInBatch(self, self.balances), v.d1),
      tokenIndex
    );

    uint256[2] memory xpReduced;

    v.feePerToken = self.swapFee / 2;
    for (uint256 i = 0; i < 2; ++i) {
      uint256 xpi = self.balances[i];
      xpReduced[i] =
        xpi -
        (((
          (i == tokenIndex)
            ? (xpi * v.d1) / v.d0 - v.newY
            : xpi - ((xpi * v.d1) / (v.d0))
        ) * (v.feePerToken)) / (PERCENTAGE_DENOMINATOR));
    }

    uint256 dy = xpReduced[tokenIndex] -
      _pricedOut(
        self,
        (getYD(v.preciseA, tokenIndex, _pricedInBatch(self, xpReduced), v.d1)),
        tokenIndex
      );
    dy = dy - 1;

    return (dy, v.newY, self.balances[tokenIndex]);
  }

  /**
   * @notice Get Debt, The amount of buyback for stable pricing.
   * @param xp a  set of pool balances. Array should be the same cardinality
   * as the pool.
   * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
   * See the StableSwap paper for details
   * @return debt the half of the D StableSwap invariant when debt is needed to be payed.
   */
  function _getDebt(
    Swap storage self,
    uint256[2] memory xp,
    uint256 a
  ) internal view returns (uint256) {
    uint256 halfD = getD(xp, a) / 2;
    if (xp[0] >= halfD) {
      return 0;
    } else {
      uint256 dy = xp[1] - halfD;
      uint256 feeHalf = (dy * self.swapFee) / PERCENTAGE_DENOMINATOR / 2;
      uint256 debt = halfD - xp[0] + feeHalf;
      return debt;
    }
  }

  /**
   * @return debt the half of the D StableSwap invariant when debt is needed to be payed.
   */
  function getDebt(Swap storage self) external view returns (uint256) {
    // might change when price is in.
    return
      _getDebt(self, _pricedInBatch(self, self.balances), _getAPrecise(self));
  }

  /**
   * @notice Calculate the price of a token in the pool with given
   *  balances and a particular D.
   *
   * @dev This is accomplished via solving the invariant iteratively.
   * See the StableSwap paper and Curve.fi implementation for further details.
   *
   * x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
   * x_1**2 + b*x_1 = c
   * x_1 = (x_1**2 + c) / (2*x_1 + b)
   *
   * @param a the amplification coefficient * n * (n - 1). See the StableSwap paper for details.
   * @param tokenIndex Index of token we are calculating for.
   * @param xp a  set of pool balances. Array should be
   * the same cardinality as the pool.
   * @param d the stableswap invariant
   * @return the price of the token, in the same precision as in xp
   */
  function getYD(
    uint256 a,
    uint8 tokenIndex,
    uint256[2] memory xp,
    uint256 d
  ) internal pure returns (uint256) {
    uint256 numTokens = 2;
    require(tokenIndex < numTokens, "Token not found");

    uint256 c = d;
    uint256 s;
    uint256 nA = a * numTokens;

    for (uint256 i = 0; i < numTokens; ++i) {
      if (i != tokenIndex) {
        s = s + xp[i];
        c = (c * d) / (xp[i] * (numTokens));
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // c = c * D * D * D * ... overflow!
      }
    }
    c = (c * d * AmplificationUtils.A_PRECISION) / (nA * numTokens);

    uint256 b = s + ((d * AmplificationUtils.A_PRECISION) / nA);
    uint256 yPrev;
    uint256 y = d;
    for (uint256 i = 0; i < MAX_LOOP_LIMIT; ++i) {
      yPrev = y;
      y = ((y * y) + c) / (2 * y + b - d);
      if (y.within1(yPrev)) {
        return y;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
   * @param xp a  set of pool balances. Array should be the same cardinality
   * as the pool.
   * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
   * See the StableSwap paper for details
   * @return the invariant, at the precision of the pool
   */
  function getD(
    uint256[2] memory xp,
    uint256 a
  ) internal pure returns (uint256) {
    uint256 numTokens = 2;
    uint256 s = xp[0] + xp[1];
    if (s == 0) {
      return 0;
    }

    uint256 prevD;
    uint256 d = s;
    uint256 nA = a * numTokens;

    for (uint256 i = 0; i < MAX_LOOP_LIMIT; ++i) {
      uint256 dP = (d ** (numTokens + 1)) /
        (numTokens ** numTokens * xp[0] * xp[1]);
      prevD = d;
      d =
        ((((nA * s) / AmplificationUtils.A_PRECISION) + dP * numTokens) * (d)) /
        (((nA - AmplificationUtils.A_PRECISION) * (d)) /
          (AmplificationUtils.A_PRECISION) +
          ((numTokens + 1) * dP));

      if (d.within1(prevD)) {
        return d;
      }
    }

    // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
    // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
    // function which does not rely on D.
    revert("D does not converge");
  }

  /**
   * @notice Get the virtual price, to help calculate profit
   * @param self Swap struct to read from
   * @return the virtual price
   */
  function getVirtualPrice(Swap storage self) external view returns (uint256) {
    uint256 d = getD(_pricedInBatch(self, self.balances), _getAPrecise(self));
    ILPToken lpToken = self.lpToken;
    uint256 supply = lpToken.totalSupply();
    if (supply > 0) {
      return (d * 10 ** 18) / supply;
    }
    return 0;
  }

  /**
   * @notice Calculate the new balances of the tokens given the indexes of the token
   * that is swapped from (FROM) and the token that is swapped to (TO).
   * This function is used as a helper function to calculate how much TO token
   * the user should receive on swap.
   *
   * @param preciseA precise form of amplification coefficient
   * @param tokenIndexFrom index of FROM token
   * @param tokenIndexTo index of TO token
   * @param x the new total amount of FROM token
   * @param xp balances of the tokens in the pool
   * @return the amount of TO token that should remain in the pool
   */
  function getY(
    uint256 preciseA,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 x,
    uint256[2] memory xp
  ) internal pure returns (uint256) {
    uint256 numTokens = 2;
    require(tokenIndexFrom != tokenIndexTo, "Can't compare token to itself");
    require(
      tokenIndexFrom < numTokens && tokenIndexTo < numTokens,
      "Tokens must be in pool"
    );

    uint256 d = getD(xp, preciseA);
    uint256 c = d;
    uint256 s = x;
    uint256 nA = numTokens * (preciseA);

    c = (c * d) / (x * numTokens);
    c = (c * d * (AmplificationUtils.A_PRECISION)) / (nA * numTokens);
    uint256 b = s + ((d * AmplificationUtils.A_PRECISION) / nA);

    uint256 yPrev;
    uint256 y = d;
    for (uint256 i = 0; i < MAX_LOOP_LIMIT; ++i) {
      yPrev = y;
      y = ((y * y) + c) / (2 * y + b - d);
      if (y.within1(yPrev)) {
        return y;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Externally calculates a swap between two tokens.
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get
   */
  function calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256 dy) {
    (dy, ) = _calculateSwap(
      self,
      tokenIndexFrom,
      tokenIndexTo,
      dx,
      self.balances
    );
  }

  /**
   * @notice Internally calculates a swap between two tokens.
   *
   * @dev The caller is expected to transfer the actual amounts (dx and dy)
   * using the token contracts.
   *
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get
   * @return dyFee the associated fee
   */
  function _calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256[2] memory balances
  ) internal view returns (uint256 dy, uint256 dyFee) {
    require(
      tokenIndexFrom < balances.length && tokenIndexTo < balances.length,
      "Token index out of range"
    );
    uint256 x = _pricedIn(self, dx + balances[tokenIndexFrom], tokenIndexFrom);

    uint256[2] memory pricedBalances = _pricedInBatch(self, balances);

    uint256 y = _pricedOut(
      self,
      getY(_getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, pricedBalances),
      tokenIndexTo // => not id, index !!!
    );
    dy = balances[tokenIndexTo] - y - 1;
    dyFee = (dy * self.swapFee) / (PERCENTAGE_DENOMINATOR);
    dy = dy - dyFee;
  }

  /**
   * @notice Uses _calculateRemoveLiquidity with Effective Balances,
   * then projects the prices to the token amounts
   * to get Real Balances, before removing them from pool.
   */
  function calculateRemoveLiquidity(
    Swap storage self,
    uint256 amount
  ) external view returns (uint256[2] memory) {
    return
      _pricedOutBatch(
        self,
        _calculateRemoveLiquidity(
          _pricedInBatch(self, self.balances),
          amount,
          self.lpToken.totalSupply()
        )
      );
  }

  /**
   * @notice A simple method to calculate amount of each underlying
   * tokens that is returned upon burning given amount of
   * LP tokens
   *
   * @param amount the amount of LP tokens that would to be burned on
   * withdrawal
   * @return amounts of tokens user will receive as an array [ETH, gETH]
   */
  function _calculateRemoveLiquidity(
    uint256[2] memory balances,
    uint256 amount,
    uint256 totalSupply
  ) internal pure returns (uint256[2] memory amounts) {
    require(amount <= totalSupply, "Cannot exceed total supply");

    amounts[0] = (balances[0] * amount) / totalSupply;
    amounts[1] = (balances[1] * amount) / totalSupply;

    return amounts;
  }

  /**
   * @notice A simple method to calculate prices from deposits or
   * withdrawals, excluding fees but including slippage. This is
   * helpful as an input into the various "min" parameters on calls
   * to fight front-running
   *
   * @dev This shouldn't be used outside frontends for user estimates.
   *
   * @param self Swap struct to read from
   * @param amounts an array of token amounts to deposit or withdrawal,
   * corresponding to pooledTokens. The amount should be in each
   * pooled token's native precision. If a token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @param deposit whether this is a deposit or a withdrawal
   * @return if deposit was true, total amount of lp token that will be minted and if
   * deposit was false, total amount of lp token that will be burned
   */
  function calculateTokenAmount(
    Swap storage self,
    uint256[2] calldata amounts,
    bool deposit
  ) external view returns (uint256) {
    uint256 a = _getAPrecise(self);
    uint256[2] memory balances = self.balances;

    uint256 d0 = getD(_pricedInBatch(self, balances), a);
    for (uint256 i = 0; i < balances.length; ++i) {
      if (deposit) {
        balances[i] = balances[i] + amounts[i];
      } else {
        require(
          amounts[i] <= balances[i],
          "Cannot withdraw more than available"
        );
        balances[i] = balances[i] - amounts[i];
      }
    }
    uint256 d1 = getD(_pricedInBatch(self, balances), a);
    uint256 totalSupply = self.lpToken.totalSupply();

    if (deposit) {
      return ((d1 - d0) * totalSupply) / d0;
    } else {
      return ((d0 - d1) * totalSupply) / d0;
    }
  }

  /**
   * @notice return accumulated amount of admin fees of the token with given index
   * @param self Swap struct to read from
   * @param index Index of the pooled token
   * @return admin balance in the token's precision
   */
  function getAdminBalance(
    Swap storage self,
    uint256 index
  ) external view returns (uint256) {
    require(index < 2, "Token index out of range");
    if (index == 0) return address(this).balance - (self.balances[index]);

    if (index == 1)
      return
        self.gETH.balanceOf(address(this), self.pooledTokenId) -
        (self.balances[index]);
    return 0;
  }

  /*** STATE MODIFYING FUNCTIONS ***/

  /**
   * @notice swap two tokens in the pool
   * @param self Swap struct to read from and write to
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell
   * @param minDy the min amount the user would like to receive, or revert.
   * @return amount of token user received on swap
   */
  function swap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy
  ) external returns (uint256) {
    IgETH gETHReference = self.gETH;
    if (tokenIndexFrom == 0) {
      // Means user is selling some ETH to the pool to get some gETH.
      // In which case, we need to send exactly that amount of ETH.
      require(dx == msg.value, "Cannot swap more/less than you sent");
    }
    if (tokenIndexFrom == 1) {
      // Means user is selling some gETH to the pool to get some ETH.

      require(
        dx <= gETHReference.balanceOf(msg.sender, self.pooledTokenId),
        "Cannot swap more than you own"
      );

      // Transfer tokens first
      uint256 beforeBalance = gETHReference.balanceOf(
        address(this),
        self.pooledTokenId
      );
      gETHReference.safeTransferFrom(
        msg.sender,
        address(this),
        self.pooledTokenId,
        dx,
        ""
      );

      // Use the actual transferred amount for AMM math
      dx =
        gETHReference.balanceOf(address(this), self.pooledTokenId) -
        beforeBalance;
    }

    uint256 dy;
    uint256 dyFee;
    // Meaning the real balances *without* any effect of underlying price
    // However, when we call _calculateSwap, it uses pricedIn function before calculation,
    // and pricedOut function after the calculation. So, we don't need to use priceOut here.
    uint256[2] memory balances = self.balances;
    (dy, dyFee) = _calculateSwap(
      self,
      tokenIndexFrom,
      tokenIndexTo,
      dx,
      balances
    );

    require(dy >= minDy, "Swap didn't result in min tokens");
    uint256 dyAdminFee = (dyFee * self.adminFee) / PERCENTAGE_DENOMINATOR;

    // To prevent any Reentrancy, balances are updated before transfering the tokens.
    self.balances[tokenIndexFrom] = balances[tokenIndexFrom] + dx;
    self.balances[tokenIndexTo] = balances[tokenIndexTo] - dy - dyAdminFee;

    if (tokenIndexTo == 0) {
      // Means contract is going to send Idle Ether (ETH)
      (bool sent, ) = payable(msg.sender).call{value: dy}("");
      require(sent, "SwapUtils: Failed to send Ether");
    }
    if (tokenIndexTo == 1) {
      // Means contract is going to send staked ETH (gETH)
      gETHReference.safeTransferFrom(
        address(this),
        msg.sender,
        self.pooledTokenId,
        dy,
        ""
      );
    }

    emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

    return dy;
  }

  /**
   * @notice Add liquidity to the pool
   * @param self Swap struct to read from and write to
   * @param amounts the amounts of each token to add, in their native precision
   * @param minToMint the minimum LP tokens adding this amount of liquidity
   * should mint, otherwise revert. Handy for front-running mitigation
   * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
   * @return amount of LP token user received
   */
  function addLiquidity(
    Swap storage self,
    uint256[2] memory amounts,
    uint256 minToMint
  ) external returns (uint256) {
    require(
      amounts[0] == msg.value,
      "SwapUtils: received less or more ETH than expected"
    );
    IgETH gETHReference = self.gETH;
    // current state
    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      self.lpToken,
      0,
      0,
      0,
      _getAPrecise(self),
      0,
      self.balances
    );
    v.totalSupply = v.lpToken.totalSupply();
    if (v.totalSupply != 0) {
      v.d0 = getD(_pricedInBatch(self, v.balances), v.preciseA);
    }

    uint256[2] memory newBalances;
    newBalances[0] = v.balances[0] + msg.value;

    for (uint256 i = 0; i < 2; ++i) {
      require(
        v.totalSupply != 0 || amounts[i] > 0,
        "Must supply all tokens in pool"
      );
    }

    {
      // Transfer tokens first
      uint256 beforeBalance = gETHReference.balanceOf(
        address(this),
        self.pooledTokenId
      );
      gETHReference.safeTransferFrom(
        msg.sender,
        address(this),
        self.pooledTokenId,
        amounts[1],
        ""
      );

      // Update the amounts[] with actual transfer amount
      amounts[1] =
        gETHReference.balanceOf(address(this), self.pooledTokenId) -
        beforeBalance;

      newBalances[1] = v.balances[1] + amounts[1];
    }

    // invariant after change
    v.d1 = getD(_pricedInBatch(self, newBalances), v.preciseA);
    require(v.d1 > v.d0, "D should increase");

    // updated to reflect fees and calculate the user's LP tokens
    v.d2 = v.d1;
    uint256[2] memory fees;

    if (v.totalSupply != 0) {
      uint256 feePerToken = self.swapFee / 2;
      for (uint256 i = 0; i < 2; ++i) {
        uint256 idealBalance = (v.d1 * v.balances[i]) / v.d0;
        fees[i] =
          (feePerToken * (idealBalance.difference(newBalances[i]))) /
          (PERCENTAGE_DENOMINATOR);
        self.balances[i] =
          newBalances[i] -
          ((fees[i] * (self.adminFee)) / (PERCENTAGE_DENOMINATOR));
        newBalances[i] = newBalances[i] - (fees[i]);
      }
      v.d2 = getD(_pricedInBatch(self, newBalances), v.preciseA);
    } else {
      // the initial depositor doesn't pay fees
      self.balances = newBalances;
    }

    uint256 toMint;
    if (v.totalSupply == 0) {
      toMint = v.d1;
    } else {
      toMint = ((v.d2 - v.d0) * v.totalSupply) / v.d0;
    }

    require(toMint >= minToMint, "Couldn't mint min requested");

    // mint the user's LP tokens
    v.lpToken.mint(msg.sender, toMint);

    emit AddLiquidity(msg.sender, amounts, fees, v.d1, v.totalSupply + toMint);
    return toMint;
  }

  /**
   * @notice Burn LP tokens to remove liquidity from the pool.
   * @dev Liquidity can always be removed, even when the pool is paused.
   * @param self Swap struct to read from and write to
   * @param amount the amount of LP tokens to burn
   * @param minAmounts the minimum amounts of each token in the pool
   * acceptable for this burn. Useful as a front-running mitigation
   * @return amounts of tokens the user received
   */
  function removeLiquidity(
    Swap storage self,
    uint256 amount,
    uint256[2] calldata minAmounts
  ) external returns (uint256[2] memory) {
    ILPToken lpToken = self.lpToken;
    IgETH gETHReference = self.gETH;
    require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");

    uint256[2] memory balances = self.balances;
    uint256 totalSupply = lpToken.totalSupply();

    uint256[2] memory amounts = _pricedOutBatch(
      self,
      _calculateRemoveLiquidity(
        _pricedInBatch(self, balances),
        amount,
        totalSupply
      )
    );

    for (uint256 i = 0; i < amounts.length; ++i) {
      require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
      self.balances[i] = balances[i] - amounts[i];
    }

    // To prevent any Reentrancy, LP tokens are burned before transfering the tokens.
    lpToken.burnFrom(msg.sender, amount);

    (bool sent, ) = payable(msg.sender).call{value: amounts[0]}("");
    require(sent, "SwapUtils: Failed to send Ether");

    gETHReference.safeTransferFrom(
      address(this),
      msg.sender,
      self.pooledTokenId,
      amounts[1],
      ""
    );

    emit RemoveLiquidity(msg.sender, amounts, totalSupply - amount);
    return amounts;
  }

  /**
   * @notice Remove liquidity from the pool all in one token.
   * @param self Swap struct to read from and write to
   * @param tokenAmount the amount of the lp tokens to burn
   * @param tokenIndex the index of the token you want to receive
   * @param minAmount the minimum amount to withdraw, otherwise revert
   * @return amount chosen token that user received
   */
  function removeLiquidityOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount
  ) external returns (uint256) {
    ILPToken lpToken = self.lpToken;
    IgETH gETHReference = self.gETH;

    require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    require(tokenIndex < 2, "Token not found");

    uint256 totalSupply = lpToken.totalSupply();

    (uint256 dy, uint256 dyFee) = _calculateWithdrawOneToken(
      self,
      tokenAmount,
      tokenIndex,
      totalSupply
    );

    require(dy >= minAmount, "dy < minAmount");

    // To prevent any Reentrancy, LP tokens are burned before transfering the tokens.
    self.balances[tokenIndex] =
      self.balances[tokenIndex] -
      (dy + ((dyFee * (self.adminFee)) / (PERCENTAGE_DENOMINATOR)));
    lpToken.burnFrom(msg.sender, tokenAmount);

    if (tokenIndex == 0) {
      (bool sent, ) = payable(msg.sender).call{value: dy}("");
      require(sent, "SwapUtils: Failed to send Ether");
    }
    if (tokenIndex == 1) {
      gETHReference.safeTransferFrom(
        address(this),
        msg.sender,
        self.pooledTokenId,
        dy,
        ""
      );
    }

    emit RemoveLiquidityOne(
      msg.sender,
      tokenAmount,
      totalSupply,
      tokenIndex,
      dy
    );

    return dy;
  }

  /**
   * @notice Remove liquidity from the pool, weighted differently than the
   * pool's current balances.
   *
   * @param self Swap struct to read from and write to
   * @param amounts how much of each token to withdraw
   * @param maxBurnAmount the max LP token provider is willing to pay to
   * remove liquidity. Useful as a front-running mitigation.
   * @return actual amount of LP tokens burned in the withdrawal
   */
  function removeLiquidityImbalance(
    Swap storage self,
    uint256[2] memory amounts,
    uint256 maxBurnAmount
  ) public returns (uint256) {
    IgETH gETHReference = self.gETH;

    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      self.lpToken,
      0,
      0,
      0,
      _getAPrecise(self),
      0,
      self.balances
    );
    v.totalSupply = v.lpToken.totalSupply();

    require(
      maxBurnAmount <= v.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0,
      ">LP.balanceOf"
    );

    uint256 feePerToken = self.swapFee / 2;
    uint256[2] memory fees;

    {
      uint256[2] memory balances1;

      v.d0 = getD(_pricedInBatch(self, v.balances), v.preciseA);
      for (uint256 i = 0; i < 2; ++i) {
        require(
          amounts[i] <= v.balances[i],
          "Cannot withdraw more than available"
        );
        balances1[i] = v.balances[i] - amounts[i];
      }
      v.d1 = getD(_pricedInBatch(self, balances1), v.preciseA);

      for (uint256 i = 0; i < 2; ++i) {
        uint256 idealBalance = (v.d1 * v.balances[i]) / v.d0;
        uint256 difference = idealBalance.difference(balances1[i]);
        fees[i] = (feePerToken * difference) / PERCENTAGE_DENOMINATOR;
        uint256 adminFee = self.adminFee;
        {
          self.balances[i] =
            balances1[i] -
            ((fees[i] * adminFee) / PERCENTAGE_DENOMINATOR);
        }
        balances1[i] = balances1[i] - fees[i];
      }

      v.d2 = getD(_pricedInBatch(self, balances1), v.preciseA);
    }

    uint256 tokenAmount = ((v.d0 - v.d2) * (v.totalSupply)) / v.d0;
    require(tokenAmount != 0, "Burnt amount cannot be zero");
    tokenAmount = tokenAmount + 1;

    require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

    // To prevent any Reentrancy, LP tokens are burned before transfering the tokens.
    v.lpToken.burnFrom(msg.sender, tokenAmount);

    (bool sent, ) = payable(msg.sender).call{value: amounts[0]}("");
    require(sent, "SwapUtils: Failed to send Ether");

    gETHReference.safeTransferFrom(
      address(this),
      msg.sender,
      self.pooledTokenId,
      amounts[1],
      ""
    );

    emit RemoveLiquidityImbalance(
      msg.sender,
      amounts,
      fees,
      v.d1,
      v.totalSupply - tokenAmount
    );

    return tokenAmount;
  }

  /**
   * @notice withdraw all admin fees to a given address
   * @param self Swap struct to withdraw fees from
   * @param to Address to send the fees to
   */
  function withdrawAdminFees(Swap storage self, address to) external {
    IgETH gETHReference = self.gETH;
    uint256 tokenBalance = gETHReference.balanceOf(
      address(this),
      self.pooledTokenId
    ) - self.balances[1];
    if (tokenBalance != 0) {
      gETHReference.safeTransferFrom(
        address(this),
        to,
        self.pooledTokenId,
        tokenBalance,
        ""
      );
    }

    uint256 etherBalance = address(this).balance - self.balances[0];
    if (etherBalance != 0) {
      (bool sent, ) = payable(msg.sender).call{value: etherBalance}("");
      require(sent, "SwapUtils: Failed to send Ether");
    }
  }

  /**
   * @notice Sets the admin fee
   * @dev adminFee cannot be higher than 100% of the swap fee
   * @param self Swap struct to update
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setAdminFee(Swap storage self, uint256 newAdminFee) external {
    require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
    self.adminFee = newAdminFee;

    emit NewAdminFee(newAdminFee);
  }

  /**
   * @notice update the swap fee
   * @dev fee cannot be higher than 1% of each swap
   * @param self Swap struct to update
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(Swap storage self, uint256 newSwapFee) external {
    require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
    self.swapFee = newSwapFee;

    emit NewSwapFee(newSwapFee);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

// PERCENTAGE_DENOMINATOR represents 100%
uint256 constant PERCENTAGE_DENOMINATOR = 10 ** 10;

/**
 * @notice ID_TYPE is like an ENUM, widely used within Portal and Modules like Withdrawal Contract
 * @dev Why not use enums, they basically do the same thing?
 * * We like using a explicit defined uints than linearly increasing ones.
 */
library ID_TYPE {
  /// @notice TYPE 0: *invalid*
  uint256 internal constant NONE = 0;

  /// @notice TYPE 1: Senate and Senate Election Proposals
  uint256 internal constant SENATE = 1;

  /// @notice TYPE 2: Contract Upgrade
  uint256 internal constant CONTRACT_UPGRADE = 2;

  /// @notice TYPE 3: *gap*: formally represented the admin contract, now reserved to be never used
  uint256 internal constant __GAP__ = 3;

  /// @notice TYPE 4: Node Operators
  uint256 internal constant OPERATOR = 4;

  /// @notice TYPE 5: Staking Pools
  uint256 internal constant POOL = 5;

  /// @notice TYPE 21: Module: Withdrawal Contract
  uint256 internal constant MODULE_WITHDRAWAL_CONTRACT = 21;

  /// @notice TYPE 31: Module: A new gETH interface
  uint256 internal constant MODULE_GETH_INTERFACE = 31;

  /// @notice TYPE 41: Module: A new Liquidity Pool
  uint256 internal constant MODULE_LIQUDITY_POOL = 41;

  /// @notice TYPE 42: Module: A new Liquidity Pool token
  uint256 internal constant MODULE_LIQUDITY_POOL_TOKEN = 42;
}

/**
 * @notice VALIDATOR_STATE keeping track of validators within The Staking Library
 */
library VALIDATOR_STATE {
  /// @notice STATE 0: *invalid*
  uint8 internal constant NONE = 0;

  /// @notice STATE 1: validator is proposed, 1 ETH is sent from Operator to Deposit Contract
  uint8 internal constant PROPOSED = 1;

  /// @notice STATE 2: proposal was approved, operator used pooled funds, 1 ETH is released back to Operator
  uint8 internal constant ACTIVE = 2;

  /// @notice STATE 3: validator is exited, not currently used much
  uint8 internal constant EXITED = 3;

  /// @notice STATE 69: proposal was malicious(alien), maybe faulty signatures or probably: (https://bit.ly/3Tkc6UC)
  uint8 internal constant ALIENATED = 69;
}