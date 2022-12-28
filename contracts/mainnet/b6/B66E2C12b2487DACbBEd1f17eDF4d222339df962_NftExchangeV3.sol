/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// File: @openzeppelin\contracts-upgradeable\utils\AddressUpgradeable.sol
// SPDX-License-Identifier: UNLICENSED
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin\contracts-upgradeable\proxy\utils\Initializable.sol

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// File: @openzeppelin\contracts-upgradeable\utils\introspection\IERC165Upgradeable.sol

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

// File: @openzeppelin\contracts-upgradeable\token\ERC1155\IERC1155Upgradeable.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin\contracts-upgradeable\token\ERC1155\IERC1155ReceiverUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts-upgradeable\token\ERC1155\extensions\IERC1155MetadataURIUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin\contracts-upgradeable\utils\ContextUpgradeable.sol

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

// File: @openzeppelin\contracts-upgradeable\utils\introspection\ERC165Upgradeable.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin\contracts-upgradeable\token\ERC1155\ERC1155Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// File: @openzeppelin\contracts-upgradeable\token\ERC1155\extensions\ERC1155SupplyUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin\contracts-upgradeable\utils\StringsUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: @openzeppelin\contracts-upgradeable\utils\cryptography\ECDSAUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin\contracts-upgradeable\utils\cryptography\draft-EIP712Upgradeable.sol

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;


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
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin\contracts-upgradeable\security\ReentrancyGuardUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts-upgradeable\access\OwnableUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts\IWETH9.sol

// Interface for WETH9 smart contract.
// solium-disable-next-line linebreak-style
pragma solidity 0.8.13;

interface IWETH9 {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// File: contracts\IERC165.sol

// Interface for ERC165.
// solium-disable-next-line linebreak-style
pragma solidity 0.8.13;

interface IERC165Upside {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts\IERC721.sol

// Interface for ERC721.
// solium-disable-next-line linebreak-style
pragma solidity 0.8.13;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface IERC721Upside {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: contracts\IERC1155.sol

// Interface for ERC1155.
// solium-disable-next-line linebreak-style
pragma solidity 0.8.13;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155Upside {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: contracts\NftExchangeV3.sol

// solium-disable-next-line linebreak-style
pragma solidity 0.8.13;
contract NftExchangeV3 is
    Initializable,
    ERC1155SupplyUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    mapping(uint256 => string) tokenUri;
    mapping(address => mapping(uint256 => bool)) redeemedVouchers;
    // Creator fee is a percent in range [0, 10] represented in tenths of a
    // percent.
    mapping(uint256 => uint8) tokenCreatorFee;
    // This variable represents the payout address for creator fees.
    mapping(uint256 => address) tokenCreatorFeePayoutAddress;
    // This variable represents the exchange fee in tenths of a percent.
    uint16 public exchangeRateNumerator;
    // Mapping from seller address to voucher ID to token ID to quantity.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) sellerVoucherRemainingTokenQuantity;

    string private constant SIGNING_DOMAIN = 'AX NFT Exchange';
    string private constant SIGNATURE_VERSION = '2';
    string private constant CURRENCY_ETH = 'ETH';
    string private constant CURRENCY_WETH = 'WETH';
    string private constant CURRENCY_USD = 'USD';
    uint16 private constant DEFAULT_EXCHANGE_RATE_NUMERATOR = 25;
    uint16 private constant EXCHANGE_RATE_DENOMINATOR = 1000;

    // Error messages.
    string private constant SELLER_ADDRESS_CANNOT_BE_ZERO = '0';
    string private constant ONLY_CONTRACT_OWNER_CAN_REGISTER_DIFFERENT_ADDRESS = '1';
    string private constant SIGNATURE_INVALID_OR_UNAUTHORIZED = '2';
    string private constant TOKEN_ALREADY_EXISTS = '3';
    string private constant CREATOR_FEE_OVER_TEN_PERCENT = '4';
    string private constant TOKEN_DOES_NOT_EXIST = '5';
    string private constant SELLER_MUST_BE_NFT_OWNER = '6';
    string private constant BUY_VOUCHER_ALREADY_REDEEMED = '7';
    string private constant BUY_VOUCHER_END_DATE_IN_PAST = '8';
    string private constant SELL_VOUCHER_ALREADY_REDEEMED = '9';
    string private constant SELL_VOUCHER_END_DATE_IN_PAST = '10';
    string private constant SELL_VOUCHER_START_DATE_IN_FUTURE = '11';
    string private constant BUY_AND_SELL_VOUCHER_ID_MISMATCH = '12';
    string private constant BUY_AND_SELL_VOUCHER_TOKEN_ID_MISMATCH = '13';
    string private constant BUY_AND_SELL_VOUCHER_WETH_CONTRACT_MISMATCH = '14';
    string private constant ONLY_CONTRACT_OWNER_OR_NFT_OWNER_CAN_ACCEPT_OFFER = '15';
    string private constant INSUFFICIENT_ETH_BALANCE = '16';
    string private constant INSUFFICIENT_WETH_BALANCE = '17';
    string private constant INSUFFICIENT_WETH_CONTRACT_ALLOWANCE = '18';
    string private constant VOUCHER_SELLER_ADDRESS_MISMATCH = '19';
    string private constant VOUCHER_BUYER_ADDRESS_MISMATCH = '20';
    string private constant ONLY_CONTRACT_OWNER_CAN_SET_EXCHANGE_FEE = '21';
    string private constant EXCHANGE_FEE_TOO_LARGE = '22';
    string private constant REFERRAL_FEE_OVER_LIMIT = '23';
    string private constant MUST_BE_SALE_MARKET_TYPE_PRIMARY = '24';
    string private constant SELL_VOUCHER_TOTAL_TOKEN_SUPPLY_MUST_BE_GREATER_THAN_ZERO = '25';
    string private constant SELLER_VOUCHER_TOKENS_INSUFFICIENT = '26';
    string private constant SELLER_TOKEN_SUPPLY_INSUFFICIENT = '27';
    string private constant ORDER_MUST_BE_PLACED_BY_BUYER = '28';
    string private constant ORDER_MUST_BE_PLACED_BY_SELLER = '29';
    string private constant ORDER_MUST_BE_PLACED_BY_EXCHANGE = '30';
    string private constant ORDER_MUST_BE_PLACED_BY_SELLER_OR_EXCHANGE = '31';
    string private constant MUST_BE_SALE_MARKET_TYPE_SECONDARY = '32';
    string private constant EXTERNAL_CONTRACT_DOES_NOT_SUPPORT_1155_INTERFACE = '33';
    string private constant EXTERNAL_CONTRACT_DOES_NOT_SUPPORT_721_INTERFACE = '34';
    string private constant EXTERNAL_CONTRACT_TYPE_UNRECOGNIZED = '35';
    string private constant EXTERNAL_CONTRACT_APPROVAL_MISSING = '36';
    string private constant EXCHANGE_VOUCHER_SIGNATURE_INVALID = '37';
    string private constant EXCHANGE_AND_SELL_VOUCHER_TOKEN_CONTRACT_ADDRESS_MISMATCH = '38';
    string private constant EXCHANGE_AND_SELL_VOUCHER_TOKEN_ID_MISMATCH = '39';
    string private constant EXCHANGE_VOUCHER_CREATOR_FEE_LENGTH_MISMATCH = '40';

    bytes4 private constant IERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant IERC1155_INTERFACE_ID = 0xd9b67a26;

    event OrderPlaced(
        address seller,
        address buyer,
        NftContractLocation nftContractLocation,
        address nftContractAddress,
        uint256 tokenId,
        uint256 unitPrice,
        uint256 quantity,
        string currency,
        uint256 eventId
    );
    event VoucherBurned(address voucherCreator, uint256 voucherId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __ERC1155Supply_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __ReentrancyGuard_init();
        __Ownable_init();

        exchangeRateNumerator = DEFAULT_EXCHANGE_RATE_NUMERATOR;
    }

    /**
     * @dev Updates the exchange fee charged per transaction, with the fee
     * specified in tenths of a percent. Only the contract owner can call this
     * method.
     */
    function setExchangeFee(uint16 newExchangeFee) external {
        require(msg.sender == owner(), ONLY_CONTRACT_OWNER_CAN_SET_EXCHANGE_FEE);
        require(newExchangeFee <= EXCHANGE_RATE_DENOMINATOR, EXCHANGE_FEE_TOO_LARGE);

        exchangeRateNumerator = newExchangeFee;
    }

    /**
     * @dev Returns whether a voucher ID has already been redeemed.
     */
    function getIsVoucherRedeemed(address voucherCreator, uint256 voucherId)
        external
        view
        returns (bool)
    {
        return redeemedVouchers[voucherCreator][voucherId];
    }

    /**
     * @dev Returns the creator fee (in tenths of a percent) associated with an
     * NFT.
     */
    function getCreatorFee(uint256 tokenId) external view returns (uint8) {
        return tokenCreatorFee[tokenId];
    }

    /**
     * @dev Returns the creator fee payout wallet address associated with an
     * NFT.
     */
    function getCreatorFeePayoutWalletAddress(uint256 tokenId) external view returns (address) {
        return tokenCreatorFeePayoutAddress[tokenId];
    }

    /**
     * @dev Withdraws all contract ETH to a specified address. Only the
     * contract owner can call this method.
     */
    function withdrawEth(address recipientAddress) external onlyOwner {
        require(recipientAddress != address(0));

        payable(recipientAddress).transfer(address(this).balance);
    }

    /**
     * @dev Withdraws all contract WETH to a specified address. Only the
     * contract owner can call this method.
     */
    function withdrawWeth(address recipientAddress, address wethSmartContractAddress)
        external
        onlyOwner
    {
        require(recipientAddress != address(0));
        require(wethSmartContractAddress != address(0));

        IWETH9(payable(wethSmartContractAddress)).transferFrom(
            address(this),
            recipientAddress,
            IWETH9(payable(wethSmartContractAddress)).balanceOf(address(this))
        );
    }

    /**
     * @dev Places an order for a buyer to purchase an NFT from a seller.
     *
     * @param buyer is the public address of the buyer.
     * @param seller is the public address of the seller.
     * @param orderType is a member of OrderType, specifying the type of order
     * to be placed.
     * @param partyInitiatingOrder is a member of PartyInitiatingOrder that
     * identifies who is calling placeOrder.
     * @param buyerVoucher is a voucher signed by the buyer. BuyerVoucher is
     * not needed if orderType is OrderType.BUY_NOW and can be passed with
     * default values.
     * @param sellerVoucher is a voucher signed by the seller.
     * @param exchangeVoucher is a voucher signed by the contract owner.
     * @param eventId is an integer that is added to any emitted events and
     * can be used for identifying these events.
     */
    function placeOrderV3(
        address buyer,
        address seller,
        OrderType orderType,
        PartyInitiatingOrder partyInitiatingOrder,
        BuyerVoucherV3 calldata buyerVoucher,
        SellerVoucherV3 calldata sellerVoucher,
        ExchangeVoucherV3 calldata exchangeVoucher,
        uint256 eventId
    ) external payable nonReentrant {
        NftContractLocation nftContractLocation = sellerVoucher.tokenContractAddress ==
            address(this)
            ? NftContractLocation.INTERNAL
            : NftContractLocation.EXTERNAL;

        // Verify the exchange voucher.
        address extractedExchangeAddress = _verify(exchangeVoucher);
        require(extractedExchangeAddress == owner(), EXCHANGE_VOUCHER_SIGNATURE_INVALID);
        require(
            exchangeVoucher.payoutAddresses.length == exchangeVoucher.payoutFeesBasisPoints.length,
            EXCHANGE_VOUCHER_CREATOR_FEE_LENGTH_MISMATCH
        );

        if (
            orderType == OrderType.BUY_NOW &&
            (sellerVoucher.sellVoucherType == SellVoucherType.FIXED_PRICE ||
                sellerVoucher.sellVoucherType == SellVoucherType.AUCTION_WITH_FIXED_PRICE)
        ) {
            // Verify seller voucher.
            address extractedSellerAddress = _verify(sellerVoucher);
            require(seller == extractedSellerAddress, VOUCHER_SELLER_ADDRESS_MISMATCH);

            // Verify that buyer is initiating the transaction. In this case,
            // a signature on the buyer voucher is not needed.
            require(
                partyInitiatingOrder == PartyInitiatingOrder.BUYER,
                ORDER_MUST_BE_PLACED_BY_BUYER
            );
            require(msg.sender == buyer, ORDER_MUST_BE_PLACED_BY_BUYER);

            _redeemVoucherForNftFixedPrice(
                sellerVoucher.saleMarketType,
                RedeemVoucherForNftFixedPriceParams(
                    buyer,
                    seller,
                    sellerVoucher.voucherId,
                    sellerVoucher.tokenContractAddress,
                    sellerVoucher.tokenContractType,
                    sellerVoucher.tokenId,
                    sellerVoucher.totalTokenSupply,
                    sellerVoucher.quantityForSale,
                    buyerVoucher.quantityToPurchase,
                    sellerVoucher.unitPriceWei,
                    sellerVoucher.uri,
                    sellerVoucher.hasStartDate,
                    sellerVoucher.startDate,
                    sellerVoucher.hasEndDate,
                    sellerVoucher.endDate,
                    sellerVoucher.creatorFee,
                    sellerVoucher.creatorFeePayoutWalletAddress,
                    sellerVoucher.isReferralEnabledByCreator,
                    sellerVoucher.referralFee,
                    buyerVoucher.isBuyerReferred,
                    buyerVoucher.referrerWalletAddress,
                    exchangeVoucher.tokenContractAddress,
                    exchangeVoucher.tokenId,
                    exchangeVoucher.payoutAddresses,
                    exchangeVoucher.payoutFeesBasisPoints
                )
            );

            emit OrderPlaced(
                seller,
                buyer,
                nftContractLocation,
                sellerVoucher.tokenContractAddress,
                sellerVoucher.tokenId,
                sellerVoucher.unitPriceWei,
                buyerVoucher.quantityToPurchase,
                CURRENCY_ETH,
                eventId
            );
        } else if (
            orderType == OrderType.ACCEPT_BUY_NOW_OFFER &&
            sellerVoucher.sellVoucherType == SellVoucherType.FIXED_PRICE
        ) {
            // Verify buyer voucher.
            address extractedBuyerAddress = _verify(buyerVoucher);
            require(buyer == extractedBuyerAddress, VOUCHER_BUYER_ADDRESS_MISMATCH);

            // Verify that seller is initiating the transaction. In this case,
            // a signature on the seller voucher is not needed.
            require(
                partyInitiatingOrder == PartyInitiatingOrder.SELLER,
                ORDER_MUST_BE_PLACED_BY_SELLER
            );
            require(msg.sender == seller, ORDER_MUST_BE_PLACED_BY_SELLER);

            _acceptOfferForSale(
                sellerVoucher.saleMarketType,
                AcceptOfferForSaleParams(
                    buyer,
                    buyerVoucher.voucherId,
                    buyerVoucher.tokenContractAddress,
                    buyerVoucher.tokenContractType,
                    buyerVoucher.tokenId,
                    buyerVoucher.wethSmartContractAddress,
                    buyerVoucher.quantityToPurchase,
                    buyerVoucher.unitPriceWei,
                    buyerVoucher.hasEndDate,
                    buyerVoucher.endDate,
                    seller,
                    sellerVoucher.voucherId,
                    sellerVoucher.tokenContractAddress,
                    sellerVoucher.tokenContractType,
                    sellerVoucher.tokenId,
                    sellerVoucher.totalTokenSupply,
                    sellerVoucher.quantityForSale,
                    sellerVoucher.wethSmartContractAddress,
                    sellerVoucher.hasStartDate,
                    sellerVoucher.startDate,
                    sellerVoucher.hasEndDate,
                    sellerVoucher.endDate,
                    sellerVoucher.uri,
                    sellerVoucher.creatorFee,
                    sellerVoucher.creatorFeePayoutWalletAddress,
                    exchangeVoucher.tokenContractAddress,
                    exchangeVoucher.tokenId,
                    exchangeVoucher.payoutAddresses,
                    exchangeVoucher.payoutFeesBasisPoints
                )
            );
            emit OrderPlaced(
                seller,
                buyer,
                nftContractLocation,
                sellerVoucher.tokenContractAddress,
                sellerVoucher.tokenId,
                buyerVoucher.unitPriceWei,
                buyerVoucher.quantityToPurchase,
                CURRENCY_WETH,
                eventId
            );
        } else if (
            orderType == OrderType.CONCLUDE_AUCTION &&
            (sellerVoucher.sellVoucherType == SellVoucherType.AUCTION ||
                sellerVoucher.sellVoucherType == SellVoucherType.AUCTION_WITH_FIXED_PRICE)
        ) {
            // Verify buyer voucher.
            address extractedBuyerAddress = _verify(buyerVoucher);
            require(buyer == extractedBuyerAddress, VOUCHER_BUYER_ADDRESS_MISMATCH);

            // Verify that either seller or exchange is executing transaction.
            require(
                partyInitiatingOrder == PartyInitiatingOrder.SELLER ||
                    partyInitiatingOrder == PartyInitiatingOrder.EXCHANGE,
                ORDER_MUST_BE_PLACED_BY_SELLER_OR_EXCHANGE
            );
            if (partyInitiatingOrder == PartyInitiatingOrder.SELLER) {
                require(msg.sender == seller, ORDER_MUST_BE_PLACED_BY_SELLER);
            } else if (partyInitiatingOrder == PartyInitiatingOrder.EXCHANGE) {
                require(msg.sender == owner(), ORDER_MUST_BE_PLACED_BY_EXCHANGE);
                // Verify seller voucher.
                address extractedSellerAddress = _verify(sellerVoucher);
                require(seller == extractedSellerAddress, VOUCHER_SELLER_ADDRESS_MISMATCH);
            }

            _acceptOfferForSale(
                sellerVoucher.saleMarketType,
                AcceptOfferForSaleParams(
                    buyer,
                    buyerVoucher.voucherId,
                    buyerVoucher.tokenContractAddress,
                    buyerVoucher.tokenContractType,
                    buyerVoucher.tokenId,
                    buyerVoucher.wethSmartContractAddress,
                    buyerVoucher.quantityToPurchase,
                    buyerVoucher.unitPriceWei,
                    buyerVoucher.hasEndDate,
                    buyerVoucher.endDate,
                    seller,
                    sellerVoucher.voucherId,
                    sellerVoucher.tokenContractAddress,
                    sellerVoucher.tokenContractType,
                    sellerVoucher.tokenId,
                    sellerVoucher.totalTokenSupply,
                    sellerVoucher.quantityForSale,
                    sellerVoucher.wethSmartContractAddress,
                    sellerVoucher.hasStartDate,
                    sellerVoucher.startDate,
                    sellerVoucher.hasEndDate,
                    sellerVoucher.endDate,
                    sellerVoucher.uri,
                    sellerVoucher.creatorFee,
                    sellerVoucher.creatorFeePayoutWalletAddress,
                    exchangeVoucher.tokenContractAddress,
                    exchangeVoucher.tokenId,
                    exchangeVoucher.payoutAddresses,
                    exchangeVoucher.payoutFeesBasisPoints
                )
            );

            emit OrderPlaced(
                seller,
                buyer,
                nftContractLocation,
                sellerVoucher.tokenContractAddress,
                sellerVoucher.tokenId,
                buyerVoucher.unitPriceWei,
                buyerVoucher.quantityToPurchase,
                CURRENCY_WETH,
                eventId
            );
        }
    }

    /* solium-disable */
    fallback() external payable {}

    receive() external payable {}

    /* solium-enable */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable)
        returns (bool)
    {
        return ERC1155Upgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {}

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {}

    /**
     * @dev Returns the URI of a token.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenUri[tokenId];
    }

    /**
     * @dev Verifies the signature for a given BuyerVoucherV3, returning the
     * address of the signer.
     *
     * Will revert if the signature is invalid.
     *
     * @param voucher A BuyerVoucherV3 describing an offer made by a buyer.
     */
    function _verify(BuyerVoucherV3 calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
     * @dev Verifies the signature for a given SellerVoucherV3, returning the
     * address of the signer.
     *
     * Will revert if the signature is invalid.
     *
     * @param voucher A SellerVoucherV3 describing an NFT for sale.
     */
    function _verify(SellerVoucherV3 calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
     * @dev Verifies the signature for a given ExchangeVoucherV3, returning the
     * address of the signer.
     *
     * Will revert if the signature is invalid.
     *
     * @param voucher A ExchangeVoucherV3 describing an NFT for sale.
     */
    function _verify(ExchangeVoucherV3 calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
     * @dev Returns a hash of the given BuyerVoucherV3, prepared using
     * EIP712 typed data hashing rules.
     *
     * @param voucher A BuyerVoucherV3 to hash.
     */
    function _hash(BuyerVoucherV3 calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            'BuyerVoucherV3(uint8 buyVoucherType,uint256 voucherId,address tokenContractAddress,uint8 tokenContractType,uint256 tokenId,uint256 quantityToPurchase,uint256 unitPriceWei,address wethSmartContractAddress,bool hasEndDate,uint256 endDate,bool isBuyerReferred,address referrerWalletAddress)'
                        ),
                        voucher.buyVoucherType,
                        voucher.voucherId,
                        voucher.tokenContractAddress,
                        voucher.tokenContractType,
                        voucher.tokenId,
                        voucher.quantityToPurchase,
                        voucher.unitPriceWei,
                        voucher.wethSmartContractAddress,
                        voucher.hasEndDate,
                        voucher.endDate,
                        voucher.isBuyerReferred,
                        voucher.referrerWalletAddress
                    )
                )
            );
    }

    /**
     * @dev Returns a hash of the given SellerVoucherV3, prepared using
     * EIP712 typed data hashing rules.
     *
     * @param voucher A SellerVoucherV3 to hash.
     */
    function _hash(SellerVoucherV3 calldata voucher) internal view returns (bytes32) {
        bytes memory a = abi.encode(
            keccak256(
                'SellerVoucherV3(uint8 sellVoucherType,uint8 saleMarketType,uint256 voucherId,address tokenContractAddress,uint8 tokenContractType,uint256 tokenId,uint256 totalTokenSupply,uint256 quantityForSale,bool hasStartDate,uint256 startDate,bool hasEndDate,uint256 endDate,address wethSmartContractAddress,uint256 unitPriceWei,string uri,uint8 creatorFee,address creatorFeePayoutWalletAddress,bool isReferralEnabledByCreator,uint8 referralFee)'
            ),
            voucher.sellVoucherType,
            voucher.saleMarketType,
            voucher.voucherId,
            voucher.tokenContractAddress,
            voucher.tokenContractType,
            voucher.tokenId,
            voucher.totalTokenSupply,
            voucher.quantityForSale,
            voucher.hasStartDate,
            voucher.startDate,
            voucher.hasEndDate
        );
        bytes memory b = abi.encode(
            voucher.endDate,
            voucher.wethSmartContractAddress,
            voucher.unitPriceWei,
            keccak256(bytes(voucher.uri)),
            voucher.creatorFee,
            voucher.creatorFeePayoutWalletAddress,
            voucher.isReferralEnabledByCreator,
            voucher.referralFee
        );
        bytes memory concat = bytes.concat(a, b);
        bytes32 hashed = keccak256(concat);
        return _hashTypedDataV4(hashed);
    }

    /**
     * @dev Returns a hash of the given ExchangeVoucherV3, prepared using
     * EIP712 typed data hashing rules.
     *
     * @param voucher A ExchangeVoucherV3 to hash.
     */
    function _hash(ExchangeVoucherV3 calldata voucher) internal view returns (bytes32) {
        bytes memory a = abi.encode(
            keccak256(
                'ExchangeVoucherV3(address tokenContractAddress,uint256 tokenId,address[] payoutAddresses,uint256[] payoutFeesBasisPoints)'
            ),
            voucher.tokenContractAddress,
            voucher.tokenId,
            keccak256(abi.encodePacked(voucher.payoutAddresses)),
            keccak256(abi.encodePacked(voucher.payoutFeesBasisPoints))
        );
        bytes32 hashed = keccak256(a);
        return _hashTypedDataV4(hashed);
    }

    /**
     * @dev Overrides _EIP712VersionHash to return a hash of the latest
     * EIP712 signature version.
     */
    // solium-disable-next-line mixedcase
    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes(SIGNATURE_VERSION));
    }

    /**
     * @dev Redeems a voucher for buyer to purchase NFT from seller at a
     * fixed price. metadataUri, creatorFee, and totalTokenSupply are only used
     * for primary market sales.
     */
    function _redeemVoucherForNftFixedPrice(
        SaleMarketType saleMarketType,
        RedeemVoucherForNftFixedPriceParams memory params
    ) private {
        require(
            params.exchangeVoucherTokenContractAddress == params.tokenContractAddress,
            EXCHANGE_AND_SELL_VOUCHER_TOKEN_CONTRACT_ADDRESS_MISMATCH
        );
        require(
            params.exchangeVoucherTokenId == params.tokenId,
            EXCHANGE_AND_SELL_VOUCHER_TOKEN_ID_MISMATCH
        );

        NftContractLocation nftContractLocation = params.tokenContractAddress == address(this)
            ? NftContractLocation.INTERNAL
            : NftContractLocation.EXTERNAL;

        NftContractType nftContractType = NftContractType.ERC1155;
        // If the total token supply is 0, the token has not been minted yet.
        // Ensure that the token will be minted with a total supply > 0.
        if (
            nftContractLocation == NftContractLocation.INTERNAL && totalSupply(params.tokenId) == 0
        ) {
            require(saleMarketType == SaleMarketType.PRIMARY, MUST_BE_SALE_MARKET_TYPE_PRIMARY);
            require(
                params.totalTokenSupply > 0,
                SELL_VOUCHER_TOTAL_TOKEN_SUPPLY_MUST_BE_GREATER_THAN_ZERO
            );
            require(params.creatorFee <= 100, CREATOR_FEE_OVER_TEN_PERCENT);
            require(params.referralFee <= 200, REFERRAL_FEE_OVER_LIMIT);
        } else if (nftContractLocation == NftContractLocation.EXTERNAL) {
            require(saleMarketType == SaleMarketType.SECONDARY, MUST_BE_SALE_MARKET_TYPE_SECONDARY);

            if (params.tokenContractType == NftContractType.ERC1155) {
                require(
                    IERC165Upside(params.tokenContractAddress).supportsInterface(
                        IERC1155_INTERFACE_ID
                    ),
                    EXTERNAL_CONTRACT_DOES_NOT_SUPPORT_1155_INTERFACE
                );
            } else if (params.tokenContractType == NftContractType.ERC721) {
                require(
                    IERC165Upside(params.tokenContractAddress).supportsInterface(
                        IERC721_INTERFACE_ID
                    ),
                    EXTERNAL_CONTRACT_DOES_NOT_SUPPORT_721_INTERFACE
                );
                nftContractType = NftContractType.ERC721;
            } else {
                revert(EXTERNAL_CONTRACT_TYPE_UNRECOGNIZED);
            }
        }

        // Make sure that voucher has enough tokens to satisfy purchase
        // quantity.
        bool isSellerVoucherAlreadyRedeemed = redeemedVouchers[params.seller][params.voucherId];
        if (isSellerVoucherAlreadyRedeemed) {
            require(
                sellerVoucherRemainingTokenQuantity[params.seller][params.voucherId][
                    params.tokenId
                ] >= params.quantityToPurchase,
                SELLER_VOUCHER_TOKENS_INSUFFICIENT
            );
        } else {
            require(
                params.quantityForSale >= params.quantityToPurchase,
                SELLER_VOUCHER_TOKENS_INSUFFICIENT
            );
            sellerVoucherRemainingTokenQuantity[params.seller][params.voucherId][
                params.tokenId
            ] = params.quantityForSale;
        }

        // Make sure that start date is either unspecified or has already
        // passed.
        require(
            !params.hasStartDate || (params.hasStartDate && block.timestamp >= params.startDate),
            SELL_VOUCHER_START_DATE_IN_FUTURE
        );

        // Make sure that end date is either unspecified or has not yet
        // passed.
        require(
            !params.hasEndDate || (params.hasEndDate && block.timestamp <= params.endDate),
            SELL_VOUCHER_END_DATE_IN_PAST
        );

        // Make sure that the redeemer is paying enough to cover the buyer's
        // cost.
        uint256 totalPriceWei = params.unitPriceWei * params.quantityToPurchase;
        require(msg.value >= totalPriceWei, INSUFFICIENT_ETH_BALANCE);

        bool isTokenMinted = nftContractLocation == NftContractLocation.EXTERNAL ||
            totalSupply(params.tokenId) > 0;
        if (saleMarketType == SaleMarketType.PRIMARY && !isTokenMinted) {
            // Assign the token to the signer, to establish provenance on-chain
            _mint(
                params.seller,
                params.tokenId,
                params.totalTokenSupply,
                /* data= */
                ''
            );
            tokenUri[params.tokenId] = params.metadataUri;
            // Record the creator fee.
            tokenCreatorFee[params.tokenId] = params.creatorFee;
            tokenCreatorFeePayoutAddress[params.tokenId] = params.creatorFeePayoutWalletAddress;
        }

        // Transfer the token to the redeemer.
        if (nftContractLocation == NftContractLocation.INTERNAL) {
            require(
                balanceOf(params.seller, params.tokenId) >= params.quantityToPurchase,
                SELLER_TOKEN_SUPPLY_INSUFFICIENT
            );

            // Use ERC1155Upgradeable's internal method to avoid checking that the
            // redeemer is approved for the transfer.
            _safeTransferFrom(
                params.seller,
                params.buyer,
                params.tokenId,
                params.quantityToPurchase,
                /* data= */
                ''
            );
        } else if (nftContractLocation == NftContractLocation.EXTERNAL) {
            if (nftContractType == NftContractType.ERC721) {
                require(
                    IERC721Upside(params.tokenContractAddress).ownerOf(params.tokenId) ==
                        params.seller,
                    SELLER_TOKEN_SUPPLY_INSUFFICIENT
                );
                require(
                    IERC721Upside(params.tokenContractAddress).isApprovedForAll(
                        params.seller,
                        address(this)
                    ),
                    EXTERNAL_CONTRACT_APPROVAL_MISSING
                );

                IERC721Upside(params.tokenContractAddress).safeTransferFrom(
                    params.seller,
                    params.buyer,
                    params.tokenId
                );
            } else if (nftContractType == NftContractType.ERC1155) {
                require(
                    IERC1155Upside(params.tokenContractAddress).balanceOf(
                        params.seller,
                        params.tokenId
                    ) >= params.quantityToPurchase,
                    SELLER_TOKEN_SUPPLY_INSUFFICIENT
                );
                require(
                    IERC1155Upside(params.tokenContractAddress).isApprovedForAll(
                        params.seller,
                        address(this)
                    ),
                    EXTERNAL_CONTRACT_APPROVAL_MISSING
                );

                IERC1155Upside(params.tokenContractAddress).safeTransferFrom(
                    params.seller,
                    params.buyer,
                    params.tokenId,
                    params.quantityToPurchase,
                    /* data= */
                    ''
                );
            }
        }

        // Record that this voucher has been redeemed.
        redeemedVouchers[params.seller][params.voucherId] = true;
        sellerVoucherRemainingTokenQuantity[params.seller][params.voucherId][
            params.tokenId
        ] -= params.quantityToPurchase;

        // Transfer Ether for the purchase.
        // Perform ETH transfer after all state variables have been updated to
        // avoid the possibility of a reentrancy attack.
        uint256 weiToExchange = (totalPriceWei * exchangeRateNumerator) / EXCHANGE_RATE_DENOMINATOR;
        uint256 weiToCreator;
        if (
            nftContractLocation == NftContractLocation.INTERNAL &&
            saleMarketType == SaleMarketType.SECONDARY
        ) {
            weiToCreator = (totalPriceWei * tokenCreatorFee[params.tokenId]) / 1000;
        }
        uint256 totalWeiToAdditionalCreators;
        uint256[] memory weiToAdditionalCreators = new uint256[](
            params.exchangeVoucherPayoutAddresses.length
        );
        for (uint256 i = 0; i < params.exchangeVoucherPayoutAddresses.length; i++) {
            uint256 weiToAdditionalCreator = (totalPriceWei *
                params.exchangeVoucherPayoutCreatorFeesBasisPoints[i]) / 10000;
            totalWeiToAdditionalCreators += weiToAdditionalCreator;
            weiToAdditionalCreators[i] = weiToAdditionalCreator;
        }
        uint256 weiToReferrer;
        if (
            saleMarketType == SaleMarketType.PRIMARY &&
            params.isReferralEnabledByCreator &&
            params.isBuyerReferred
        ) {
            weiToReferrer = (totalPriceWei * params.referralFee) / 1000;
        }
        uint256 weiToSeller = totalPriceWei -
            weiToExchange -
            weiToCreator -
            totalWeiToAdditionalCreators -
            weiToReferrer;
        if (weiToSeller > 0) {
            payable(params.seller).transfer(weiToSeller);
        }
        if (weiToExchange > 0) {
            payable(owner()).transfer(weiToExchange);
        }
        if (nftContractLocation == NftContractLocation.INTERNAL && weiToCreator > 0) {
            payable(tokenCreatorFeePayoutAddress[params.tokenId]).transfer(weiToCreator);
        }
        if (totalWeiToAdditionalCreators > 0) {
            for (uint256 i = 0; i < params.exchangeVoucherPayoutAddresses.length; i++) {
                payable(params.exchangeVoucherPayoutAddresses[i]).transfer(
                    weiToAdditionalCreators[i]
                );
            }
        }
        if (weiToReferrer > 0) {
            payable(params.referrerWalletAddress).transfer(weiToReferrer);
        }
    }

    /**
     * @dev Redeems an offer made by a buyer on an NFT that was listed for
     * sale. Payment is conducted using WETH.
     */
    function _acceptOfferForSale(
        SaleMarketType saleMarketType,
        AcceptOfferForSaleParams memory params
    ) private {
        require(
            params.exchangeVoucherTokenContractAddress == params.sellVoucherTokenContractAddress,
            EXCHANGE_AND_SELL_VOUCHER_TOKEN_CONTRACT_ADDRESS_MISMATCH
        );
        require(
            params.exchangeVoucherTokenId == params.sellVoucherTokenId,
            EXCHANGE_AND_SELL_VOUCHER_TOKEN_ID_MISMATCH
        );
        require(params.buyVoucherTokenContractAddress == params.sellVoucherTokenContractAddress);
        require(params.buyVoucherTokenContractType == params.sellVoucherTokenContractType);

        NftContractLocation nftContractLocation = params.buyVoucherTokenContractAddress ==
            address(this)
            ? NftContractLocation.INTERNAL
            : NftContractLocation.EXTERNAL;

        NftContractType nftContractType = NftContractType.ERC1155;
        // If the total token supply is 0, the token has not been minted yet.
        // Ensure that the token will be minted with a total supply > 0.
        if (
            nftContractLocation == NftContractLocation.INTERNAL &&
            totalSupply(params.buyVoucherTokenId) == 0
        ) {
            require(saleMarketType == SaleMarketType.PRIMARY, MUST_BE_SALE_MARKET_TYPE_PRIMARY);
            require(
                params.sellVoucherTotalTokenSupply > 0,
                SELL_VOUCHER_TOTAL_TOKEN_SUPPLY_MUST_BE_GREATER_THAN_ZERO
            );
            require(params.creatorFee <= 100, CREATOR_FEE_OVER_TEN_PERCENT);
        } else if (nftContractLocation == NftContractLocation.EXTERNAL) {
            require(saleMarketType == SaleMarketType.SECONDARY, MUST_BE_SALE_MARKET_TYPE_SECONDARY);

            if (params.buyVoucherTokenContractType == NftContractType.ERC1155) {
                require(
                    IERC165Upside(params.buyVoucherTokenContractAddress).supportsInterface(
                        IERC1155_INTERFACE_ID
                    ),
                    EXTERNAL_CONTRACT_DOES_NOT_SUPPORT_1155_INTERFACE
                );
            } else if (params.buyVoucherTokenContractType == NftContractType.ERC721) {
                require(
                    IERC165Upside(params.buyVoucherTokenContractAddress).supportsInterface(
                        IERC721_INTERFACE_ID
                    ),
                    EXTERNAL_CONTRACT_DOES_NOT_SUPPORT_721_INTERFACE
                );
                nftContractType = NftContractType.ERC721;
            } else {
                revert(EXTERNAL_CONTRACT_TYPE_UNRECOGNIZED);
            }
        }

        // Make sure that the buy voucher has not been redeemed yet.
        require(!redeemedVouchers[params.buyer][params.buyVoucherId], BUY_VOUCHER_ALREADY_REDEEMED);
        // Make sure that sell voucher has enough tokens to satisfy purchase
        // quantity.
        bool isSellerVoucherAlreadyRedeemed = redeemedVouchers[params.seller][params.sellVoucherId];
        if (isSellerVoucherAlreadyRedeemed) {
            require(
                sellerVoucherRemainingTokenQuantity[params.seller][params.sellVoucherId][
                    params.sellVoucherTokenId
                ] >= params.buyVoucherQuantityToPurchase,
                SELLER_VOUCHER_TOKENS_INSUFFICIENT
            );
        } else {
            require(
                params.sellVoucherQuantityForSale >= params.buyVoucherQuantityToPurchase,
                SELLER_VOUCHER_TOKENS_INSUFFICIENT
            );
            sellerVoucherRemainingTokenQuantity[params.seller][params.sellVoucherId][
                params.sellVoucherTokenId
            ] = params.sellVoucherQuantityForSale;
        }

        // Make sure that buy voucher end date is either unspecified or has not
        // yet passed.
        require(
            !params.buyVoucherHasEndDate ||
                (params.buyVoucherHasEndDate && block.timestamp <= params.buyVoucherEndDate),
            BUY_VOUCHER_END_DATE_IN_PAST
        );

        // Make sure that start date is either unspecified or has already
        // passed.
        require(
            !params.sellVoucherHasStartDate ||
                (params.sellVoucherHasStartDate && block.timestamp >= params.sellVoucherStartDate),
            SELL_VOUCHER_START_DATE_IN_FUTURE
        );

        // Make sure that end date is either unspecified or has not yet
        // passed.
        require(
            !params.sellVoucherHasEndDate ||
                (params.sellVoucherHasEndDate && block.timestamp <= params.sellVoucherEndDate),
            SELL_VOUCHER_END_DATE_IN_PAST
        );

        // Make sure that the tokenId specified by the buy voucher matches the
        // tokenId of the sell voucher.
        require(
            params.buyVoucherTokenId == params.sellVoucherTokenId,
            BUY_AND_SELL_VOUCHER_TOKEN_ID_MISMATCH
        );

        // Make sure that buyer and seller agree on the WETH smart contract
        // to exchange funds.
        require(
            params.buyVoucherWethSmartContractAddress == params.sellVoucherWethSmartContractAddress,
            BUY_AND_SELL_VOUCHER_WETH_CONTRACT_MISMATCH
        );

        // Make sure that buyer's WETH balance is large enough to fulfill the
        // purchase.
        uint256 totalPriceWei = params.buyVoucherUnitPriceWei * params.buyVoucherQuantityToPurchase;
        require(
            IWETH9(payable(params.sellVoucherWethSmartContractAddress)).balanceOf(params.buyer) >=
                totalPriceWei,
            INSUFFICIENT_WETH_BALANCE
        );

        // Make sure that contract is approved with sufficient allowance.
        require(
            IWETH9(payable(params.sellVoucherWethSmartContractAddress)).allowance(
                params.buyer,
                address(this)
            ) >= totalPriceWei,
            INSUFFICIENT_WETH_CONTRACT_ALLOWANCE
        );

        // Make sure that the caller is either the smart contract owner or the
        // owner of the NFT.
        require(
            msg.sender == params.seller || msg.sender == owner(),
            ONLY_CONTRACT_OWNER_OR_NFT_OWNER_CAN_ACCEPT_OFFER
        );

        bool isTokenMinted = nftContractLocation == NftContractLocation.EXTERNAL ||
            totalSupply(params.buyVoucherTokenId) > 0;
        if (saleMarketType == SaleMarketType.PRIMARY && !isTokenMinted) {
            // Assign the token to the seller, to establish provenance on-chain
            _mint(
                params.seller,
                params.sellVoucherTokenId,
                params.sellVoucherTotalTokenSupply,
                /* data= */
                ''
            );
            tokenUri[params.sellVoucherTokenId] = params.metadataUri;
            // Record the creator fee.
            tokenCreatorFee[params.sellVoucherTokenId] = params.creatorFee;
            tokenCreatorFeePayoutAddress[params.sellVoucherTokenId] = params
                .creatorFeePayoutWalletAddress;
        }

        // Transfer the token to the buyer.
        if (nftContractLocation == NftContractLocation.INTERNAL) {
            require(
                balanceOf(params.seller, params.buyVoucherTokenId) >=
                    params.buyVoucherQuantityToPurchase,
                SELLER_TOKEN_SUPPLY_INSUFFICIENT
            );

            // Use ERC1155Upgradeable's internal method to avoid checking that the
            // redeemer is approved for the transfer.
            _safeTransferFrom(
                params.seller,
                params.buyer,
                params.buyVoucherTokenId,
                params.buyVoucherQuantityToPurchase,
                /* data= */
                ''
            );
        } else if (nftContractLocation == NftContractLocation.EXTERNAL) {
            if (nftContractType == NftContractType.ERC721) {
                require(
                    IERC721Upside(params.buyVoucherTokenContractAddress).ownerOf(
                        params.buyVoucherTokenId
                    ) == params.seller,
                    SELLER_TOKEN_SUPPLY_INSUFFICIENT
                );
                require(
                    IERC721Upside(params.buyVoucherTokenContractAddress).isApprovedForAll(
                        params.seller,
                        address(this)
                    ),
                    EXTERNAL_CONTRACT_APPROVAL_MISSING
                );

                IERC721Upside(params.buyVoucherTokenContractAddress).safeTransferFrom(
                    params.seller,
                    params.buyer,
                    params.buyVoucherTokenId
                );
            } else if (nftContractType == NftContractType.ERC1155) {
                require(
                    IERC1155Upside(params.buyVoucherTokenContractAddress).balanceOf(
                        params.seller,
                        params.buyVoucherTokenId
                    ) >= params.buyVoucherQuantityToPurchase,
                    SELLER_TOKEN_SUPPLY_INSUFFICIENT
                );
                require(
                    IERC1155Upside(params.buyVoucherTokenContractAddress).isApprovedForAll(
                        params.seller,
                        address(this)
                    ),
                    EXTERNAL_CONTRACT_APPROVAL_MISSING
                );

                IERC1155Upside(params.buyVoucherTokenContractAddress).safeTransferFrom(
                    params.seller,
                    params.buyer,
                    params.buyVoucherTokenId,
                    params.buyVoucherQuantityToPurchase,
                    /* data= */
                    ''
                );
            }
        }

        // Record that buy and sell vouchers have been redeemed.
        redeemedVouchers[params.buyer][params.buyVoucherId] = true;
        redeemedVouchers[params.seller][params.sellVoucherId] = true;
        sellerVoucherRemainingTokenQuantity[params.seller][params.sellVoucherId][
            params.sellVoucherTokenId
        ] -= params.buyVoucherQuantityToPurchase;

        // Transfer WETH for the purchase.
        // Perform WETH transfer after all state variables have been updated to
        // avoid the possibility of a reentrancy attack.
        uint256 weiToExchange = (totalPriceWei * exchangeRateNumerator) / EXCHANGE_RATE_DENOMINATOR;
        uint256 weiToCreator;
        if (
            nftContractLocation == NftContractLocation.INTERNAL &&
            saleMarketType == SaleMarketType.SECONDARY
        ) {
            // solium-disable-next-line operator-whitespace
            weiToCreator = (totalPriceWei * tokenCreatorFee[params.buyVoucherTokenId]) / 1000;
        }
        uint256 totalWeiToAdditionalCreators;
        uint256[] memory weiToAdditionalCreators = new uint256[](
            params.exchangeVoucherPayoutAddresses.length
        );
        for (uint256 i = 0; i < params.exchangeVoucherPayoutAddresses.length; i++) {
            uint256 weiToAdditionalCreator = (totalPriceWei *
                params.exchangeVoucherPayoutCreatorFeesBasisPoints[i]) / 10000;
            totalWeiToAdditionalCreators += weiToAdditionalCreator;
            weiToAdditionalCreators[i] = weiToAdditionalCreator;
        }
        uint256 weiToSeller = totalPriceWei -
            weiToExchange -
            weiToCreator -
            totalWeiToAdditionalCreators;
        if (weiToSeller > 0) {
            IWETH9(payable(params.sellVoucherWethSmartContractAddress)).transferFrom(
                params.buyer,
                params.seller,
                weiToSeller
            );
        }
        if (weiToExchange > 0) {
            IWETH9(payable(params.sellVoucherWethSmartContractAddress)).transferFrom(
                params.buyer,
                owner(),
                weiToExchange
            );
        }
        if (nftContractLocation == NftContractLocation.INTERNAL && weiToCreator > 0) {
            IWETH9(payable(params.sellVoucherWethSmartContractAddress)).transferFrom(
                params.buyer,
                tokenCreatorFeePayoutAddress[params.buyVoucherTokenId],
                weiToCreator
            );
        }
        if (totalWeiToAdditionalCreators > 0) {
            for (uint256 i = 0; i < params.exchangeVoucherPayoutAddresses.length; i++) {
                IWETH9(payable(params.sellVoucherWethSmartContractAddress)).transferFrom(
                    params.buyer,
                    params.exchangeVoucherPayoutAddresses[i],
                    weiToAdditionalCreators[i]
                );
            }
        }
    }

    /**
     * @dev Represents an offer made by a buyer for an NFT that is for sale.
     * BuyerVoucherV3 is applicable for OrderType.ACCEPT_BUY_NOW_OFFER when the
     * buyer makes an offer on a fixed price item. BuyVoucherV3 is also
     * applicable for OrderType.CONCLUDE_AUCTION when the buyer places a bid
     * on an NFT that is for sale via an auction.
     */
    struct BuyerVoucherV3 {
        BuyVoucherType buyVoucherType;
        // @dev A unique ID associated with this voucher.
        uint256 voucherId;
        // @dev The address of the smart contract containing the NFT.
        address tokenContractAddress;
        // @dev The standard of the token's smart contract.
        NftContractType tokenContractType;
        // @dev The id of the token to be transacted.
        uint256 tokenId;
        // @dev The token quantity that the buyer is offering to purchase.
        uint256 quantityToPurchase;
        // @dev The offer unit price in Wei.
        uint256 unitPriceWei;
        // @dev The address of the WETH smart contract that will be used to
        // send payment for the NFT.
        address wethSmartContractAddress;
        // @dev whether this voucher can only be redeemed before a certain
        // time.
        bool hasEndDate;
        // @dev The end date of the voucher, represented as a unix timestamp
        // of the number of seconds that have passed since January 1st 1970
        // UTC.
        uint256 endDate;
        // @dev whether the buyer for this order was referred.
        bool isBuyerReferred;
        // @dev the address to credit with the referral fee if the buyer was
        // referred.
        address referrerWalletAddress;
        // @dev the EIP-712 signature of all other fields in the BuyerVoucher
        // struct.
        bytes signature;
    }

    /**
     * @dev Represents an NFT that is listed for sale. This struct corresponds
     * to placeOrderV3.
     */
    struct SellerVoucherV3 {
        // @dev The selling format. If the token supply is greater than 1,
        // SellVoucherType.FIXED_PRICE is the only supported selling format.
        SellVoucherType sellVoucherType;
        SaleMarketType saleMarketType;
        // @dev A unique ID associated with this voucher.
        uint256 voucherId;
        // @dev The address of the smart contract containing the NFT.
        address tokenContractAddress;
        // @dev The standard of the token's smart contract.
        NftContractType tokenContractType;
        // @dev The id of the token to be redeemed.
        uint256 tokenId;
        // @dev The total number of tokens that can be placed into circulation
        // for this token. This field is only used when minting a new NFT
        // (when saleMarketType is SaleMarketType.PRIMARY).
        uint256 totalTokenSupply;
        // @dev The number of tokens that can be purchased with this voucher.
        // The buyer can purchase anywhere from 1 to quantityForSale tokens.
        uint256 quantityForSale;
        // @dev whether this voucher can only be redeemed after a certain
        // time.
        bool hasStartDate;
        // @dev The start date of the voucher, represented as a unix timestamp
        // of the number of seconds that have passed since January 1st 1970
        // UTC.
        uint256 startDate;
        // @dev whether this voucher can only be redeemed before a certain
        // time.
        bool hasEndDate;
        // @dev The end date of the voucher, represented as a unix timestamp
        // of the number of seconds that have passed since January 1st 1970
        // UTC.
        uint256 endDate;
        // @dev The address of the WETH smart contract that will be used to
        // accept payment for the NFT.
        address wethSmartContractAddress;
        // @dev The price (in wei) of each unit token. This field is used if
        // sellVoucherType is one of SellVoucherType.FIXED_PRICE or
        // SellVoucherType.AUCTION_WITH_FIXED_PRICE. Otherwise, it is unused
        // and a default value can be provided.
        uint256 unitPriceWei;
        // @dev The metadata URI to associate with this token. This field is
        // only used when minting a new NFT (when saleMarketType is
        // SaleMarketType.PRIMARY).
        string uri;
        // @dev The percentage of secondary sales that are collected by the NFT
        // creator. This value must be in the range [0, 10]. This field is only
        // used when minting a new NFT (when saleMarketType is
        // SaleMarketType.PRIMARY).
        uint8 creatorFee;
        // @dev The desination wallet address of creator fees. This field is
        // only used when minting a new NFT (when saleMarketType is
        // SaleMarketType.PRIMARY).
        address creatorFeePayoutWalletAddress;
        // @dev Whether the creator has allowed a referral fee for this NFT.
        bool isReferralEnabledByCreator;
        // @dev The percentage of a primary market sale that can be awarded to
        // a referrer. This value must be in the range [0, 20].
        uint8 referralFee;
        // @dev the EIP-712 signature of all other fields in the
        // SellerVoucher struct.
        bytes signature;
    }

    /**
     * @dev A voucher created to store exchange parameters such as creator fees
     * for an order. This struct corresponds to placeOrderV3.
     */
    struct ExchangeVoucherV3 {
        // @dev The address of the smart contract containing the NFT.
        address tokenContractAddress;
        // @dev The token ID of the NFT.
        uint256 tokenId;
        // @dev The wallet addresses to pay out creator fees.
        address[] payoutAddresses;
        // @dev The payout fees in basis points (one hundredth of one percent).
        uint256[] payoutFeesBasisPoints;
        // @dev the EIP-712 signature of all other fields in the
        // ExchangeVoucherV3 struct.
        bytes signature;
    }

    /**
     * @dev Stores parameters to pass to _redeemVoucherForNftFixedPrice.
     */
    struct RedeemVoucherForNftFixedPriceParams {
        address buyer;
        address seller;
        uint256 voucherId;
        address tokenContractAddress;
        NftContractType tokenContractType;
        uint256 tokenId;
        uint256 totalTokenSupply;
        uint256 quantityForSale;
        uint256 quantityToPurchase;
        uint256 unitPriceWei;
        string metadataUri;
        bool hasStartDate;
        uint256 startDate;
        bool hasEndDate;
        uint256 endDate;
        uint8 creatorFee;
        address creatorFeePayoutWalletAddress;
        // Referral is only used for primary market sales.
        bool isReferralEnabledByCreator;
        uint8 referralFee;
        bool isBuyerReferred;
        address referrerWalletAddress;
        address exchangeVoucherTokenContractAddress;
        uint256 exchangeVoucherTokenId;
        address[] exchangeVoucherPayoutAddresses;
        uint256[] exchangeVoucherPayoutCreatorFeesBasisPoints;
    }

    /**
     * @dev Stores parameters to pass to _acceptOfferForSale.
     */
    struct AcceptOfferForSaleParams {
        address buyer;
        uint256 buyVoucherId;
        address buyVoucherTokenContractAddress;
        NftContractType buyVoucherTokenContractType;
        uint256 buyVoucherTokenId;
        address buyVoucherWethSmartContractAddress;
        uint256 buyVoucherQuantityToPurchase;
        uint256 buyVoucherUnitPriceWei;
        bool buyVoucherHasEndDate;
        uint256 buyVoucherEndDate;
        address seller;
        uint256 sellVoucherId;
        address sellVoucherTokenContractAddress;
        NftContractType sellVoucherTokenContractType;
        uint256 sellVoucherTokenId;
        uint256 sellVoucherTotalTokenSupply;
        uint256 sellVoucherQuantityForSale;
        address sellVoucherWethSmartContractAddress;
        bool sellVoucherHasStartDate;
        uint256 sellVoucherStartDate;
        bool sellVoucherHasEndDate;
        uint256 sellVoucherEndDate;
        // Only used for primary market sales.
        string metadataUri;
        // Only used for primary market sales.
        uint8 creatorFee;
        // Only used for primary market sales.
        address creatorFeePayoutWalletAddress;
        address exchangeVoucherTokenContractAddress;
        uint256 exchangeVoucherTokenId;
        address[] exchangeVoucherPayoutAddresses;
        uint256[] exchangeVoucherPayoutCreatorFeesBasisPoints;
    }

    /**
     * @dev The different listing formats that can be used to sell an NFT.
     */
    enum SellVoucherType {
        FIXED_PRICE,
        AUCTION,
        AUCTION_WITH_FIXED_PRICE
    }

    /**
     * @dev Whether an NFT is for sale on primary or secondary market.
     */
    enum SaleMarketType {
        PRIMARY,
        SECONDARY
    }

    /**
     * @dev The type of offer that a buyer is making.
     */
    enum BuyVoucherType {
        FIXED_PRICE_OFFER,
        AUCTION_BID
    }

    /**
     * @dev The type of order executed to conclude the sale of an NFT.
     */
    enum OrderType {
        BUY_NOW,
        ACCEPT_BUY_NOW_OFFER,
        CONCLUDE_AUCTION
    }

    /**
     * @dev Identifies whether an NFT is stored within this smart contract or
     * an external contract.
     */
    enum NftContractLocation {
        INTERNAL,
        EXTERNAL
    }

    /**
     * @dev Identifies the party that is calling the placeOrder function to
     * execute an order.
     */
    enum PartyInitiatingOrder {
        BUYER,
        SELLER,
        EXCHANGE
    }

    /**
     * @dev Identifies the standard that an NFT smart contract adheres to.
     */
    enum NftContractType {
        ERC721,
        ERC1155
    }
}