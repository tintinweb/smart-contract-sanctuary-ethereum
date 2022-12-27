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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @notice ERC-20 for working with forward commodity tokens
/// @author Solid World DAO
contract CollateralizedBasketToken is ERC20Burnable, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint amount) public onlyOwner {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./CollateralizedBasketToken.sol";

contract CollateralizedBasketTokenDeployer {
    function deploy(string calldata tokenName, string calldata tokenSymbol)
        external
        returns (CollateralizedBasketToken token)
    {
        token = new CollateralizedBasketToken(tokenName, tokenSymbol);
        token.transferOwnership(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice ERC-1155 for working with forward contract batch tokens
/// @author Solid World DAO
contract ForwardContractBatchToken is ERC1155, Ownable {
    constructor(string memory uri) ERC1155(uri) {}

    /// @dev only owner
    /// @param to address of the owner of new token
    /// @param id id of new token
    /// @param amount amount of new token
    /// @param data external data
    function mint(
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public onlyOwner {
        _mint(to, id, amount, data);
    }

    /// @dev only owner
    /// @param account address of the owner of token what is burned
    /// @param id id of token what is burned
    /// @param amount amount of token what is burned
    function burn(
        address account,
        uint id,
        uint amount
    ) public onlyOwner {
        _burn(account, id, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./ForwardContractBatchToken.sol";
import "./CollateralizedBasketToken.sol";
import "./libraries/SolidMath.sol";
import "./libraries/GPv2SafeERC20.sol";
import "./interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "./interfaces/manager/ISolidWorldManagerErrors.sol";
import "./libraries/DomainDataTypes.sol";
import "./CollateralizedBasketTokenDeployer.sol";

contract SolidWorldManager is
    Initializable,
    OwnableUpgradeable,
    IERC1155ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    IWeeklyCarbonRewardsManager,
    ISolidWorldManagerErrors
{
    /// @notice Constant used as input for decollateralization simulation for ordering batches with the same category and vintage
    uint public constant DECOLLATERALIZATION_SIMULATION_INPUT = 1000e18;

    /// @notice Mapping is used for checking if Category ID is already added
    /// @dev CategoryId => isAdded
    mapping(uint => bool) public categoryIds;

    /// @notice Stores the state of categories
    /// @dev CategoryId => DomainDataTypes.Category
    mapping(uint => DomainDataTypes.Category) public categories;

    /// @notice Property is used for checking if Project ID is already added
    /// @dev ProjectId => isAdded
    mapping(uint => bool) public projectIds;

    /// @notice Property is used for checking if Batch ID is already added
    /// @dev BatchId => isAdded
    mapping(uint => bool) public batchCreated;

    /// @notice Stores all batch ids ever created
    uint[] public batchIds;

    /// @notice Property stores info about a batch
    /// @dev BatchId => DomainDataTypes.Batch
    mapping(uint => DomainDataTypes.Batch) public batches;

    /// @notice Mapping determines a respective CollateralizedBasketToken (ERC-20) of a category
    /// @dev CategoryId => CollateralizedBasketToken address (ERC-20)
    mapping(uint => CollateralizedBasketToken) public categoryToken;

    /// @notice Mapping determines what projects a category has
    /// @dev CategoryId => ProjectId[]
    mapping(uint => uint[]) public categoryProjects;

    /// @notice Mapping determines what category a project belongs to
    /// @dev ProjectId => CategoryId
    mapping(uint => uint) public projectCategory;

    /// @notice Mapping determines what batches a project has
    /// @dev ProjectId => BatchId[]
    mapping(uint => uint[]) public projectBatches;

    /// @notice Contract that operates forward contract batch tokens (ERC-1155). Allows this contract to mint tokens.
    ForwardContractBatchToken public forwardContractBatch;

    /// @notice The account where all protocol fees are captured.
    address public feeReceiver;

    /// @notice The only account that is allowed to mint weekly carbon rewards
    address public weeklyRewardsMinter;

    /// @notice Contract that deploys new collateralized basket tokens. Allows this contract to mint tokens.
    CollateralizedBasketTokenDeployer public collateralizedBasketTokenDeployer;

    /// @notice Fee charged by DAO when collateralizing forward contract batch tokens.
    uint16 public collateralizationFee;

    /// @notice Fee charged by DAO when decollateralizing collateralized basket tokens.
    uint16 public decollateralizationFee;

    event BatchCollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed batchOwner
    );
    event TokensDecollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed tokensOwner
    );
    event CategoryCreated(uint indexed categoryId);
    event CategoryUpdated(
        uint indexed categoryId,
        uint indexed volumeCoefficient,
        uint indexed decayPerSecond,
        uint maxDepreciation
    );
    event CategoryRebalanced(
        uint indexed categoryId,
        uint indexed averageTA,
        uint indexed totalCollateralized
    );
    event ProjectCreated(uint indexed projectId);
    event BatchCreated(uint indexed batchId);

    modifier validBatch(uint batchId) {
        if (!batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }
        _;
    }

    modifier batchUnderway(uint batchId) {
        if (_isBatchCertified(batchId)) {
            revert BatchCertified(batchId);
        }
        _;
    }

    function initialize(
        CollateralizedBasketTokenDeployer _collateralizedBasketTokenDeployer,
        ForwardContractBatchToken _forwardContractBatch,
        uint16 _collateralizationFee,
        uint16 _decollateralizationFee,
        address _feeReceiver,
        address _weeklyRewardsMinter
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        collateralizedBasketTokenDeployer = _collateralizedBasketTokenDeployer;
        forwardContractBatch = _forwardContractBatch;
        collateralizationFee = _collateralizationFee;
        decollateralizationFee = _decollateralizationFee;
        feeReceiver = _feeReceiver;
        weeklyRewardsMinter = _weeklyRewardsMinter;
    }

    // todo #121: add authorization
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint24 initialTA
    ) external {
        if (categoryIds[categoryId]) {
            revert CategoryAlreadyExists(categoryId);
        }

        categoryIds[categoryId] = true;
        categoryToken[categoryId] = collateralizedBasketTokenDeployer.deploy(
            tokenName,
            tokenSymbol
        );

        categories[categoryId].averageTA = initialTA;

        emit CategoryCreated(categoryId);
    }

    // todo #121: add authorization
    function updateCategory(
        uint categoryId,
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint24 maxDepreciation
    ) external {
        if (!categoryIds[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        categories[categoryId].volumeCoefficient = volumeCoefficient;
        categories[categoryId].decayPerSecond = decayPerSecond;
        categories[categoryId].maxDepreciation = maxDepreciation;

        // todo #204: implement logic for updating the other fields of the category based on the new values

        emit CategoryUpdated(categoryId, volumeCoefficient, decayPerSecond, maxDepreciation);
    }

    // todo #121: add authorization
    function addProject(uint categoryId, uint projectId) external {
        if (!categoryIds[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        if (projectIds[projectId]) {
            revert ProjectAlreadyExists(projectId);
        }

        categoryProjects[categoryId].push(projectId);
        projectCategory[projectId] = categoryId;
        projectIds[projectId] = true;

        emit ProjectCreated(projectId);
    }

    // todo #121: add authorization
    function addBatch(DomainDataTypes.Batch calldata batch) external {
        if (!projectIds[batch.projectId]) {
            revert InvalidProjectId(batch.projectId);
        }

        if (batchCreated[batch.id]) {
            revert BatchAlreadyExists(batch.id);
        }

        if (batch.owner == address(0)) {
            revert InvalidBatchOwner();
        }

        if (batch.expectedDueDate <= block.timestamp) {
            revert BatchDueDateInThePast(batch.expectedDueDate);
        }

        batchCreated[batch.id] = true;
        batches[batch.id] = batch;
        batchIds.push(batch.id);
        projectBatches[batch.projectId].push(batch.id);
        forwardContractBatch.mint(batch.owner, batch.id, batch.totalAmount, "");

        emit BatchCreated(batch.id);
    }

    // todo #121: add authorization
    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setWeeklyRewardsMinter(address _weeklyRewardsMinter) external {
        weeklyRewardsMinter = _weeklyRewardsMinter;
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function computeWeeklyCarbonRewards(address[] calldata assets, uint[] calldata _categoryIds)
        external
        view
        override
        returns (address[] memory carbonRewards, uint[] memory rewardAmounts)
    {
        if (assets.length != _categoryIds.length) {
            revert InvalidInput();
        }

        carbonRewards = new address[](assets.length);
        rewardAmounts = new uint[](assets.length);

        for (uint i; i < assets.length; i++) {
            uint categoryId = _categoryIds[i];
            if (!categoryIds[categoryId]) {
                revert InvalidCategoryId(categoryId);
            }

            CollateralizedBasketToken rewardToken = categoryToken[categoryId];
            uint rewardAmount = _computeWeeklyCategoryReward(categoryId, rewardToken.decimals());

            carbonRewards[i] = address(rewardToken);
            rewardAmounts[i] = rewardAmount;
        }
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function mintWeeklyCarbonRewards(
        uint[] calldata _categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        address rewardsVault
    ) external override {
        if (
            _categoryIds.length != carbonRewards.length ||
            carbonRewards.length != rewardAmounts.length
        ) {
            revert InvalidInput();
        }

        if (msg.sender != weeklyRewardsMinter) {
            revert UnauthorizedRewardMinting(msg.sender);
        }

        for (uint i; i < carbonRewards.length; i++) {
            address carbonReward = carbonRewards[i];
            CollateralizedBasketToken rewardToken = CollateralizedBasketToken(carbonReward);
            uint rewardAmount = rewardAmounts[i];

            rewardToken.mint(rewardsVault, rewardAmount);
            emit WeeklyRewardMinted(carbonReward, rewardAmount);

            _rebalanceCategory(_categoryIds[i]);
        }
    }

    /// @dev Collateralizes `amountIn` of ERC1155 tokens with id `batchId` for msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend its ERC1155 tokens with id `batchId`
    /// @dev nonReentrant, to avoid possible reentrancy after calling safeTransferFrom
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @param amountOutMin minimum output amount of ERC20 tokens for transaction to succeed
    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external nonReentrant validBatch(batchId) batchUnderway(batchId) {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint cbtUserCut, uint cbtDaoCut, ) = SolidMath.computeCollateralizationOutcome(
            batches[batchId].expectedDueDate,
            amountIn,
            batches[batchId].discountRate,
            collateralizationFee,
            collateralizedToken.decimals()
        );

        if (cbtUserCut < amountOutMin) {
            revert AmountOutLessThanMinimum(cbtUserCut, amountOutMin);
        }

        collateralizedToken.mint(msg.sender, cbtUserCut);
        collateralizedToken.mint(feeReceiver, cbtDaoCut);

        forwardContractBatch.safeTransferFrom(msg.sender, address(this), batchId, amountIn, "");

        emit BatchCollateralized(batchId, amountIn, cbtUserCut, msg.sender);
    }

    /// @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` to msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `amountIn` ERC20 tokens
    /// @dev nonReentrant, to avoid possible reentrancy after calling safeTransferFrom
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @param amountOutMin minimum output amount of ERC1155 tokens for transaction to succeed
    function decollateralizeTokens(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) public nonReentrant validBatch(batchId) {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath
            .computeDecollateralizationOutcome(
                batches[batchId].expectedDueDate,
                amountIn,
                batches[batchId].discountRate,
                decollateralizationFee,
                collateralizedToken.decimals()
            );

        if (amountOut <= 0) {
            revert AmountOutTooLow(amountOut);
        }

        if (amountOut < amountOutMin) {
            revert AmountOutLessThanMinimum(amountOut, amountOutMin);
        }

        collateralizedToken.burnFrom(msg.sender, cbtToBurn);
        GPv2SafeERC20.safeTransferFrom(collateralizedToken, msg.sender, feeReceiver, cbtDaoCut);

        forwardContractBatch.safeTransferFrom(address(this), msg.sender, batchId, amountOut, "");

        emit TokensDecollateralized(batchId, amountIn, amountOut, msg.sender);
    }

    /// @dev Bulk-decollateralizes ERC20 tokens into multiple ERC1155 tokens with specified amounts
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `sum(amountsIn)` ERC20 tokens
    /// @param _batchIds ids of the batches
    /// @param amountsIn ERC20 tokens to decollateralize
    /// @param amountsOutMin minimum output amounts of ERC1155 tokens for transaction to succeed
    function bulkDecollateralizeTokens(
        uint[] calldata _batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external {
        if (_batchIds.length != amountsIn.length || _batchIds.length != amountsOutMin.length) {
            revert InvalidInput();
        }

        for (uint i; i < _batchIds.length; i++) {
            decollateralizeTokens(_batchIds[i], amountsIn[i], amountsOutMin[i]);
        }
    }

    /// @dev Simulates collateralization of `amountIn` ERC1155 tokens with id `batchId` for msg.sender
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @return cbtUserCut ERC20 tokens to be received by msg.sender
    /// @return cbtDaoCut ERC20 tokens to be received by feeReceiver
    /// @return cbtForfeited ERC20 tokens forfeited for collateralizing the ERC1155 tokens
    function simulateBatchCollateralization(uint batchId, uint amountIn)
        external
        view
        validBatch(batchId)
        batchUnderway(batchId)
        returns (
            uint cbtUserCut,
            uint cbtDaoCut,
            uint cbtForfeited
        )
    {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (cbtUserCut, cbtDaoCut, cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            batches[batchId].expectedDueDate,
            amountIn,
            batches[batchId].discountRate,
            collateralizationFee,
            collateralizedToken.decimals()
        );
    }

    /// @dev Simulates decollateralization of `amountIn` ERC20 tokens for ERC1155 tokens with id `batchId`
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @return amountOut ERC1155 tokens to be received by msg.sender
    /// @return minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
    /// @return minCbtDaoCut ERC20 tokens to be received by feeReceiver for decollateralizing minAmountIn ERC20 tokens
    function simulateDecollateralization(uint batchId, uint amountIn)
        public
        view
        validBatch(batchId)
        returns (
            uint amountOut,
            uint minAmountIn,
            uint minCbtDaoCut
        )
    {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (amountOut, , ) = SolidMath.computeDecollateralizationOutcome(
            batches[batchId].expectedDueDate,
            amountIn,
            batches[batchId].discountRate,
            decollateralizationFee,
            collateralizedToken.decimals()
        );

        (minAmountIn, minCbtDaoCut) = SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
            batches[batchId].expectedDueDate,
            amountOut,
            batches[batchId].discountRate,
            decollateralizationFee,
            collateralizedToken.decimals()
        );
    }

    /// @dev Computes relevant info for the decollateralization process involving batches
    /// that match the specified `projectId` and `vintage`
    /// @param projectId id of the project the batch belongs to
    /// @param vintage vintage of the batch
    /// @return result array of relevant info about matching batches
    function getBatchesDecollateralizationInfo(uint projectId, uint vintage)
        external
        view
        returns (DomainDataTypes.TokenDecollateralizationInfo[] memory result)
    {
        DomainDataTypes.TokenDecollateralizationInfo[]
            memory allInfos = new DomainDataTypes.TokenDecollateralizationInfo[](batchIds.length);
        uint infoCount;

        for (uint i; i < batchIds.length; i++) {
            uint batchId = batchIds[i];
            if (batches[batchId].vintage != vintage || batches[batchId].projectId != projectId) {
                continue;
            }

            uint availableCredits = forwardContractBatch.balanceOf(address(this), batchId);

            (uint amountOut, uint minAmountIn, uint minCbtDaoCut) = simulateDecollateralization(
                batchId,
                DECOLLATERALIZATION_SIMULATION_INPUT
            );

            allInfos[infoCount] = DomainDataTypes.TokenDecollateralizationInfo(
                batchId,
                availableCredits,
                amountOut,
                minAmountIn,
                minCbtDaoCut
            );
            infoCount = infoCount + 1;
        }

        result = new DomainDataTypes.TokenDecollateralizationInfo[](infoCount);
        for (uint i; i < infoCount; i++) {
            result[i] = allInfos[i];
        }
    }

    // todo #121: add authorization
    function setCollateralizationFee(uint16 _collateralizationFee) public {
        collateralizationFee = _collateralizationFee;
    }

    // todo #121: add authorization
    function setDecollateralizationFee(uint16 _decollateralizationFee) public {
        decollateralizationFee = _decollateralizationFee;
    }

    // todo #121: add authorization
    function setFeeReceiver(address _feeReceiver) public {
        feeReceiver = _feeReceiver;
    }

    function getProjectIdsByCategory(uint categoryId) public view returns (uint[] memory) {
        return categoryProjects[categoryId];
    }

    function getBatchIdsByProject(uint projectId) public view returns (uint[] memory) {
        return projectBatches[projectId];
    }

    function onERC1155Received(
        address,
        address,
        uint,
        uint,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0xd9b67a26; // The ERC-165 identifier for ERC-1155
    }

    /// @dev Computes the amount of ERC20 tokens to be rewarded over the next 7 days
    /// @param categoryId The source category for the ERC20 rewards
    function _computeWeeklyCategoryReward(uint categoryId, uint rewardDecimals)
        internal
        view
        returns (uint)
    {
        uint rewardAmount;

        uint[] storage projects = categoryProjects[categoryId];
        for (uint i; i < projects.length; i++) {
            uint projectId = projects[i];
            uint[] storage _batches = projectBatches[projectId];
            for (uint j; j < _batches.length; j++) {
                uint batchId = _batches[j];
                uint availableCredits = forwardContractBatch.balanceOf(address(this), batchId);
                if (availableCredits == 0 || _isBatchCertified(batchId)) {
                    continue;
                }

                DomainDataTypes.Batch storage batch = batches[batchId];
                rewardAmount += SolidMath.computeWeeklyBatchReward(
                    batch.expectedDueDate,
                    availableCredits,
                    batch.discountRate,
                    rewardDecimals
                );
            }
        }

        return rewardAmount;
    }

    function _rebalanceCategory(uint categoryId) internal {
        uint totalQuantifiedForwardCredits;
        uint totalCollateralizedForwardCredits;

        uint[] storage projects = categoryProjects[categoryId];
        for (uint i; i < projects.length; i++) {
            uint projectId = projects[i];
            uint[] storage _batches = projectBatches[projectId];
            for (uint j; j < _batches.length; j++) {
                uint batchId = _batches[j];
                uint collateralizedForwardCredits = forwardContractBatch.balanceOf(
                    address(this),
                    batchId
                );
                if (collateralizedForwardCredits == 0 || _isBatchCertified(batchId)) {
                    continue;
                }

                totalQuantifiedForwardCredits +=
                    batches[batchId].discountRate *
                    collateralizedForwardCredits;
                totalCollateralizedForwardCredits += collateralizedForwardCredits;
            }
        }

        if (totalCollateralizedForwardCredits == 0) {
            categories[categoryId].totalCollateralized = 0;
            emit CategoryRebalanced(categoryId, categories[categoryId].averageTA, 0);
            return;
        }

        uint latestAverageTA = totalQuantifiedForwardCredits / totalCollateralizedForwardCredits;
        categories[categoryId].averageTA = uint24(latestAverageTA);
        categories[categoryId].totalCollateralized = totalCollateralizedForwardCredits;

        emit CategoryRebalanced(categoryId, latestAverageTA, totalCollateralizedForwardCredits);
    }

    function _getCollateralizedTokenForBatchId(uint batchId)
        internal
        view
        returns (CollateralizedBasketToken)
    {
        uint projectId = batches[batchId].projectId;
        uint categoryId = projectCategory[projectId];

        return categoryToken[categoryId];
    }

    function _isBatchCertified(uint batchId) internal view returns (bool) {
        return batches[batchId].expectedDueDate <= block.timestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Errors thrown by the manager contract
/// @author Solid World DAO
interface ISolidWorldManagerErrors {
    error BatchAlreadyExists(uint batchId);
    error InvalidBatchId(uint batchId);
    error InvalidBatchOwner();
    error BatchDueDateInThePast(uint32 dueDate);

    error CategoryAlreadyExists(uint categoryId);
    error InvalidCategoryId(uint categoryId);

    error ProjectAlreadyExists(uint projectId);
    error InvalidProjectId(uint projectId);

    error InvalidInput();

    error AmountOutLessThanMinimum(uint amountOut, uint minAmountOut);
    error AmountOutTooLow(uint amountOut);

    error BatchCertified(uint batchId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title The interface weekly carbon rewards processing
/// @notice Computes and mints weekly carbon rewards
/// @author Solid World DAO
interface IWeeklyCarbonRewardsManager {
    event WeeklyRewardMinted(address indexed rewardToken, uint indexed rewardAmount);

    /// @dev Thrown if minting weekly rewards is called by an unauthorized account
    error UnauthorizedRewardMinting(address account);

    /// @param _weeklyRewardsMinter The only account allowed to mint weekly carbon rewards
    function setWeeklyRewardsMinter(address _weeklyRewardsMinter) external;

    /// @param assets The incentivized assets (LP tokens)
    /// @param _categoryIds The categories to which the incentivized assets belong
    /// @return carbonRewards List of carbon rewards getting distributed.
    /// @return rewardAmounts List of carbon reward amounts getting distributed
    function computeWeeklyCarbonRewards(address[] calldata assets, uint[] calldata _categoryIds)
        external
        view
        returns (address[] memory carbonRewards, uint[] memory rewardAmounts);

    /// @param _categoryIds The categories to which the incentivized assets belong
    /// @param carbonRewards List of carbon rewards to mint
    /// @param rewardAmounts List of carbon reward amounts to mint
    /// @param rewardsVault Account that secures ERC20 rewards
    function mintWeeklyCarbonRewards(
        uint[] calldata _categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        address rewardsVault
    ) external;
}

// SPDX-License-Identifier: BSD-4-Clause

/// ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
/// Author: Mikhail Vladimirov <[email protected]>
pragma solidity ^0.8.16;

/// Smart contract library of mathematical functions operating with signed
/// 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
/// basically a simple fraction whose numerator is signed 128-bit integer and
/// denominator is 2^64.  As long as denominator is always the same, there is no
/// need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
/// represented by int128 type holding only the numerator.
library ABDKMath64x64 {
    /// Minimum value signed 64.64-bit fixed point number may have.
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /// Maximum value signed 64.64-bit fixed point number may have.
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
    /// number.  Revert on overflow.
    /// @param x unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /// Convert signed 64.64 fixed point number into unsigned 64-bit integer
    /// number rounding down.  Revert on underflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return unsigned 64-bit integer number
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /// Calculate x * y rounding down. Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// Calculate x * y rounding down, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 256-bit integer number
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /// Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y uint256 value
    /// @return signed 64.64-bit fixed point number
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function div(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /// Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 64.64-bit fixed point number
    function divu(uint256 x, uint256 y) internal pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /// Calculate natural exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /// Calculate binary exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0)
                result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0)
                result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0)
                result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0)
                result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0)
                result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0)
                result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0)
                result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0)
                result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0)
                result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0)
                result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0)
                result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0)
                result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0)
                result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0)
                result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0)
                result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0)
                result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0)
                result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0)
                result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0)
                result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0)
                result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0)
                result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0)
                result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0)
                result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0)
                result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0)
                result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0)
                result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0)
                result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /// Calculate natural logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128)
                );
        }
    }

    /// Calculate binary logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /// Calculate 1 / x rounding towards zero.  Revert on overflow or when x is zero.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library DomainDataTypes {
    /// @notice Structure that holds necessary information for minting collateralized basket tokens (ERC-20).
    /// @param id ID of the batch in the database
    /// @param projectId Project ID this batch belongs to
    /// @param totalAmount Amount of carbon tons in the batch, this amount will be minted as forward contract batch tokens (ERC-1155)
    /// @param owner Address who receives forward contract batch tokens (ERC-1155)
    /// @param expectedDueDate When the batch is about to be delivered; affects on how many collateralized basket tokens (ERC-20) may be minted
    /// @param vintage The year an emission reduction occurred or the offset was issued. The older the vintage, the cheaper the price per credit.
    /// @param status Status for the batch (ex. CAN_BE_DEPOSITED | IS_ACCUMULATING | READY_FOR_DELIVERY etc.)
    /// @param discountRate Coefficient that affects on how many collateralized basket tokens (ERC-20) may be minted / ton. Forward is worth less than spot.
    struct Batch {
        uint id;
        uint projectId;
        uint totalAmount;
        address owner;
        uint32 expectedDueDate;
        uint16 vintage;
        uint8 status;
        uint24 discountRate;
    }

    /// @notice Structure that holds state of a category of forward carbon credits. Used for computing collateralization.
    /// @param volumeCoefficient controls how much impact does erc1155 input size have on the TA being offered.
    /// The higher, the more you have to input to raise the TA.
    /// @param decayPerSecond controls how fast the built momentum drops over time.
    /// The bigger, the faster the momentum drops.
    /// @param maxDepreciation controls how much the reactive TA can drop from the averageTA value.
    /// @param averageTA is the average time appreciation of the category.
    /// @param totalCollateralized is the total amount of collateralized tokens for this category.
    /// @param lastCollateralizationTimestamp the timestamp of the last collateralization.
    /// @param lastCollateralizationMomentum the value of the momentum at the last collateralization.
    struct Category {
        uint volumeCoefficient;
        uint40 decayPerSecond;
        uint24 maxDepreciation;
        uint24 averageTA;
        uint totalCollateralized;
        uint32 lastCollateralizationTimestamp;
        uint lastCollateralizationMomentum;
    }

    /// @notice Structure that holds necessary information for decollateralizing ERC20 tokens to ERC1155 tokens with id `batchId`
    /// @param batchId id of the batch
    /// @param availableBatchTokens Amount of ERC1155 tokens with id `batchId` that are available to be redeemed
    /// @param amountOut ERC1155 tokens with id `batchId` to be received by msg.sender
    /// @param minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
    /// @param minCbtDaoCut ERC20 tokens to be received by feeReceiver for decollateralizing minAmountIn ERC20 tokens
    struct TokenDecollateralizationInfo {
        uint batchId;
        uint availableBatchTokens;
        uint amountOut;
        uint minAmountIn;
        uint minCbtDaoCut;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token) private view returns (bool success) {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice Solid World DAO Math Operations and Constants.
/// @author Solid World DAO
library SolidMath {
    /// @dev Basis points in which the `time appreciation` must be expressed
    /// @dev 100% = 1_000_000; 1% = 10_000; 0.0984% = 984
    uint constant TIME_APPRECIATION_BASIS_POINTS = 1_000_000;

    /// @dev Basis points used to express various DAO fees
    /// @dev 100% = 10_000; 0.01% = 1
    uint constant FEE_BASIS_POINTS = 10_000;

    error IncorrectDates(uint startDate, uint endDate);

    /// @dev Computes the number of weeks between two dates
    /// @param startDate start date expressed in seconds
    /// @param endDate end date expressed in seconds
    /// @return number of weeks between the two dates. Returns 0 if result is negative
    function weeksBetween(uint startDate, uint endDate) internal pure returns (uint) {
        if (startDate == 0 || endDate == 0) {
            revert IncorrectDates(startDate, endDate);
        }

        if (endDate <= startDate) {
            return 0;
        }

        return (endDate - startDate) / 1 weeks;
    }

    /// @dev Computes discount for given `timeAppreciation` and project `expectedCertificationDate`
    /// @dev (1 - timeAppreciation) ** weeksUntilCertification
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param expectedCertificationDate expected date for project certification
    /// @return discount in basis points
    function computeTimeAppreciationDiscount(uint timeAppreciation, uint expectedCertificationDate)
        internal
        view
        returns (uint)
    {
        uint weeksUntilCertification = weeksBetween(block.timestamp, expectedCertificationDate);
        if (weeksUntilCertification == 0) {
            return TIME_APPRECIATION_BASIS_POINTS;
        }

        if (weeksUntilCertification == 1) {
            return TIME_APPRECIATION_BASIS_POINTS - timeAppreciation;
        }

        uint discountRatePoints = TIME_APPRECIATION_BASIS_POINTS - timeAppreciation;
        int128 discountRate = ABDKMath64x64.div(discountRatePoints, TIME_APPRECIATION_BASIS_POINTS);
        int128 totalDiscount = ABDKMath64x64.pow(discountRate, (weeksUntilCertification - 1));

        return ABDKMath64x64.mulu(totalDiscount, discountRatePoints);
    }

    /// @dev Computes the amount of ERC20 tokens to be minted to the stakeholder and DAO,
    /// @dev and the amount forfeited when collateralizing `fcbtAmount` of ERC1155 tokens
    /// @dev cbtUserCut = erc1155 * 10e18 * (1 - fee) * (1 - timeAppreciation) ** weeksUntilCertification
    /// @param expectedCertificationDate expected date for project certification. Must not be in the past.
    /// @param fcbtAmount amount of ERC1155 tokens to be collateralized
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param collateralizationFee 0.01% = 1
    /// @param cbtDecimals collateralized basket token number of decimals
    /// @return amount of ERC20 tokens to be minted to the stakeholder
    /// @return amount of ERC20 tokens to be minted to the DAO
    /// @return amount of ERC20 tokens forfeited for collateralizing the ERC1155 tokens
    function computeCollateralizationOutcome(
        uint expectedCertificationDate,
        uint fcbtAmount,
        uint timeAppreciation,
        uint collateralizationFee,
        uint cbtDecimals
    )
        internal
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        assert(expectedCertificationDate > block.timestamp);

        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );
        uint mintableCbtAmount = Math.mulDiv(
            fcbtAmount * timeAppreciationDiscount,
            10**cbtDecimals,
            TIME_APPRECIATION_BASIS_POINTS
        );

        uint cbtDaoCut = Math.mulDiv(mintableCbtAmount, collateralizationFee, FEE_BASIS_POINTS);
        uint cbtUserCut = mintableCbtAmount - cbtDaoCut;
        uint cbtForfeited = fcbtAmount * 10**cbtDecimals - mintableCbtAmount;

        return (cbtUserCut, cbtDaoCut, cbtForfeited);
    }

    /// @dev Computes the amount of ERC1155 tokens redeemable by the stakeholder, amount of ERC20 tokens
    /// @dev charged by the DAO and to be burned when decollateralizing `cbtAmount` of ERC20 tokens
    /// @dev erc1155 = erc20 / 10e18 * (1 - fee) / (1 - timeAppreciation) ** weeksUntilCertification
    /// @param expectedCertificationDate expected date for project certification
    /// @param cbtAmount amount of ERC20 tokens to be decollateralized
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param decollateralizationFee 0.01% = 1
    /// @param cbtDecimals collateralized basket token number of decimals
    /// @return amount of ERC1155 tokens redeemable by the stakeholder
    /// @return amount of ERC20 tokens charged by the DAO
    /// @return amount of ERC20 tokens to be burned from the stakeholder
    function computeDecollateralizationOutcome(
        uint expectedCertificationDate,
        uint cbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    )
        internal
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        uint cbtDaoCut = Math.mulDiv(cbtAmount, decollateralizationFee, FEE_BASIS_POINTS);
        uint cbtToBurn = cbtAmount - cbtDaoCut;

        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );

        uint fcbtAmount = Math.mulDiv(
            cbtToBurn,
            TIME_APPRECIATION_BASIS_POINTS,
            timeAppreciationDiscount
        );

        return (fcbtAmount / 10**cbtDecimals, cbtDaoCut, cbtToBurn);
    }

    /// @dev Computes the minimum amount of ERC20 tokens to decollateralize in order to redeem `expectedFcbtAmount`
    /// @dev and the amount of ERC20 tokens charged by the DAO for decollateralizing the minimum amount of ERC20 tokens
    /// @param expectedCertificationDate expected date for project certification
    /// @param expectedFcbtAmount amount of ERC1155 tokens to be redeemed
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param decollateralizationFee 0.01% = 1
    /// @param cbtDecimals collateralized basket token number of decimals
    /// @return minAmountIn minimum amount of ERC20 tokens to decollateralize in order to redeem `expectedFcbtAmount`
    /// @return minCbtDaoCut amount of ERC20 tokens charged by the DAO for decollateralizing minAmountIn ERC20 tokens
    function computeDecollateralizationMinAmountInAndDaoCut(
        uint expectedCertificationDate,
        uint expectedFcbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    ) internal view returns (uint minAmountIn, uint minCbtDaoCut) {
        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );

        uint minAmountInAfterFee = Math.mulDiv(
            expectedFcbtAmount * timeAppreciationDiscount,
            10**cbtDecimals,
            TIME_APPRECIATION_BASIS_POINTS
        );

        minAmountIn = Math.mulDiv(
            minAmountInAfterFee,
            FEE_BASIS_POINTS,
            FEE_BASIS_POINTS - decollateralizationFee
        );

        minCbtDaoCut = Math.mulDiv(minAmountIn, decollateralizationFee, FEE_BASIS_POINTS);
    }

    /// @dev Computes the amount of ERC20 tokens to be rewarded over the next 7 days
    /// @dev erc1155 * 10e18 * timeApn * (1 - timeApn) ** weeks
    /// @param expectedCertificationDate expected date for project certification
    /// @param availableCredits amount of ERC1155 tokens backing the reward
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param decimals reward token number of decimals
    /// @return rewardAmount ERC20 reward amount. Returns 0 if `expectedCertificationDate` is in the past
    function computeWeeklyBatchReward(
        uint expectedCertificationDate,
        uint availableCredits,
        uint timeAppreciation,
        uint decimals
    ) internal view returns (uint rewardAmount) {
        if (expectedCertificationDate <= block.timestamp) {
            return 0;
        }

        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );

        rewardAmount = Math.mulDiv(
            availableCredits * timeAppreciation * timeAppreciationDiscount,
            10**decimals,
            TIME_APPRECIATION_BASIS_POINTS**2
        );
    }
}