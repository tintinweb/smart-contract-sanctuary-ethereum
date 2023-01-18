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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
library Counters {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/TokenActions.sol";
import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./structs/MemberStruct.sol";
import "./structs/TokenStruct.sol";
import "./structs/ApprovalsStruct.sol";

// Errors Definition
error OnlyRelayer(); //  "Only relayer contract can call this"
error DifferentLengthOfArrays(); // "Lengths of parameters need to be equal"
error InvalidTokenRange(); // "tokenAmount can only range from 0-100 percentage"
error OnlyBeneficiary(); // "Only the designated beneficiary can claim assets"
error NoApprovalExists(); // "No Approvals found"
error NotCharity(); // "is not charity"
error InsufficientTopups(); // "User does not have sufficient topUp Updates in order to store approvals"
error StoringBackupFailed(); // "Storing Backup Failed"

/**
 * @title AssetsStore
 * @notice This contract is deployed by the AssetsStoreFactory.sol
 * and is the contract that holds the approvals for a user's directives
 *
 * @dev The ownership of this contract is held by the deployer factory
 *
 */

contract AssetsStore is IAssetStore, Initializable, OwnableUpgradeable {
    // Returns token Approvals for specific UID
    mapping(string => Approvals[]) private MemberApprovals;

    // Mapping Beneficiaries to a specific Approval for Claiming
    mapping(address => Approvals[]) private BeneficiaryClaimableAsset;

    // Storing ApprovalId for different approvals stored
    uint88 private _approvalId;

    // address for the protocol directory contract
    address private directoryContract;

    /**
     * @notice Event used for querying approvals stored
     * by this contract
     *
     * @param uid string of the central identifier within the dApp
     * @param approvedWallet address for original holder of the asset
     * @param beneficiaryName string associated with beneficiaryAddress wallet
     * @param beneficiaryAddress address for the wallet receiving the assets
     * @param tokenId uint256 of the ID of the token being transferred
     * @param tokenAddress address for the contract of the asset
     * @param tokenType string representing what ERC the token is
     * @param tokensAllocated uint256 representing the % allocation of an asset
     * @param dateApproved uint256 for the block number when the approval is acted on
     * @param claimed bool for showing if the approval has been claimed by a beneficiary
     * @param active bool for if the claiming period is currently active
     * @param approvalId uint256 representing which approval the event is tied to
     * @param claimExpiryTime uint256 of a block number when claiming can no longer happen
     * @param approvedTokenAmount uint256 representing the magnitude of tokens to be transferred
     * at the time of claiming.
     *
     */
    event ApprovalsEvent(
        string uid,
        string beneficiaryName,
        uint256 tokenId,
        string tokenType,
        uint256 tokensAllocated,
        uint256 dateApproved,
        uint256 approvalId,
        uint256 claimExpiryTime,
        uint256 approvedTokenAmount,
        address approvedWallet,
        address beneficiaryAddress,
        address tokenAddress,
        bool claimed,
        bool active
    );

    /**
     * @dev Modifier checking that only the RelayerContract can invoke certain functions
     *
     */
    modifier onlyRelayerContract() {
        address relayerAddress = IProtocolDirectory(directoryContract).getRelayerContract();
        if (msg.sender != relayerAddress) {
            revert OnlyRelayer();
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the ProtocolDirectory Contract
     * user's membership
     */
    function initialize(address _directoryContract) public initializer {
        directoryContract = _directoryContract;
        _approvalId = 0;
    }

    /**
     * @notice Function to store All Types of Approvals and Backups by the user in one function
     * @dev storeAssetsAndBackUpApprovals calls
     *  storeBackupAssetsApprovals & storeAssetsApprovals
     *
     * sent to storeAssetsApprovals:
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     *
     * sent to storeBackupAssetsApprovals:
     * @param _backUpTokenIds uint256[] Ordered list of tokenIds to be in a backup plan
     * @param _backupTokenAmount uint256[] Ordered list representing a magnitube of tokens to be in a backupPlan
     * @param _backUpWallets address[] Ordered list of destination wallets for the backupPlan
     * @param _backUpAddresses address[] Ordered list of contract addresses of assets for the backupPlan
     * @param _backupTokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param uid string of the dApp identifier for the user
     *
     *
     */
    function storeAssetsAndBackUpApprovals(
        address[] calldata _contractAddress,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] calldata _backUpWallets,
        address[] calldata _backUpAddresses,
        string[] memory _backupTokenTypes,
        string memory uid
    ) external {
        IMember(IProtocolDirectory(directoryContract).getMemberContract()).storeBackupAssetsApprovals(
            _backUpAddresses, _backUpTokenIds, _backUpWallets, _backupTokenAmount, _backupTokenTypes, uid
        );
        storeAssetsApprovals(
            _contractAddress,
            _tokenIds,
            _beneficiaries,
            _beneficiaryNames,
            _beneficiaryIsCharity,
            _tokenAmount,
            _tokenTypes,
            uid
        );
    }

    /**
     * @notice storeAssetsApprovals - Function to store All Types Approvals by the user
     * @dev All of the arrays passed in need to be IN ORDER
     * they will be accessed in a loop together
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _memberUID string of the dApp identifier for the user
     *
     */
    function storeAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] memory _tokenIds,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) public {
        if (
            _tokenIds.length != _contractAddress.length || _beneficiaryNames.length != _beneficiaries.length
                || _tokenAmount.length != _tokenTypes.length || _beneficiaryIsCharity.length != _tokenIds.length
        ) {
            revert DifferentLengthOfArrays();
        }

        address IMemberAddress = IProtocolDirectory(directoryContract).getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(tx.origin) == false)) {
            IMember(IMemberAddress).createMember(_memberUID, tx.origin);
        }
        IMember(IMemberAddress).checkUIDofSender(_memberUID, tx.origin);

        uint256 _approvalLength = _tokenIds.length;

        for (uint256 i; i < _approvalLength; i++) {
            address contractAddress = _contractAddress[i];
            bool isCharity = _beneficiaryIsCharity[i];
            address beneficiary_ = _beneficiaries[i];
            string memory beneficiaryName_ = _beneficiaryNames[i];
            string memory tokenType = _tokenTypes[i];
            uint256 tokenAmount = _tokenAmount[i];
            uint256 tokenId_ = _tokenIds[i];
            uint256 _dateApproved = block.timestamp;

            TokenActions.checkAssetContract(contractAddress, tokenType, tokenId_, tx.origin, tokenAmount);
            if (tokenAmount > 100 || tokenAmount < 0) {
                revert InvalidTokenRange();
            }

            Approvals memory approval = Approvals(
                Beneficiary(beneficiary_, isCharity, beneficiaryName_),
                Token(contractAddress, tokenId_, tokenAmount, tokenType),
                _dateApproved,
                tx.origin,
                false,
                false,
                ++_approvalId,
                0,
                0,
                _memberUID
            );

            BeneficiaryClaimableAsset[beneficiary_].push(approval);
            MemberApprovals[_memberUID].push(approval);

            emit ApprovalsEvent(
                _memberUID,
                beneficiaryName_,
                tokenId_,
                tokenType,
                tokenAmount,
                _dateApproved,
                _approvalId,
                0,
                0,
                tx.origin,
                beneficiary_,
                contractAddress,
                false,
                false
                );
        }
    }

    /**
     * @notice getApproval - Function to get a specific token Approval for the user passing in UID and ApprovalID
     * @dev searches state for a match by uid and approvalId for a given user
     *
     * @param uid string of the dApp identifier for the user
     * @param approvalId number of the individual approval to lookup
     *
     * @return approval_ struct storing information for an Approval
     */
    function getApproval(string memory uid, uint256 approvalId) external view returns (Approvals memory approval_) {
        Approvals[] memory _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == approvalId) {
                approval_ = _approvals[i];
            }
        }
    }

    /**
     * @notice getBeneficiaryApproval - Function to get a token Approval for the beneficiaries - Admin function
     * @param _benAddress address to lookup a specific list of approvals for given beneficiary address
     * @return approval_ a list of approval structs for a specific address
     */
    function getBeneficiaryApproval(address _benAddress) external view returns (Approvals[] memory approval_) {
        approval_ = BeneficiaryClaimableAsset[_benAddress];
    }

    /**
     * @notice getApprovals - Function to get all token Approvals for the user
     * @param uid string of the dApp identifier for the user
     * @return Approvals[] a list of all the approval structs associated with a user
     */
    function getApprovals(string memory uid) external view returns (Approvals[] memory) {
        return MemberApprovals[uid];
    }

    /**
     * @notice setApprovalClaimed - Function to set approval claimed for a specific apprival id
     * @param uid string of the dApp identifier for the user
     * @param _id uint256 the id of the approval claimed
     *
     * emits an event to indicate state change of an approval as well
     * as changing the state inside of the MemberApprovals list
     */
    function setApprovalClaimed(string calldata uid, uint256 _id) internal {
        Approvals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == _id) {
                Approvals storage _userApproval = _approvals[i];
                _userApproval.claimed = true;
                _userApproval.active = false;
                emit ApprovalsEvent(
                    _userApproval._uid,
                    _userApproval.beneficiary.beneficiaryName,
                    _userApproval.token.tokenId,
                    _userApproval.token.tokenType,
                    _userApproval.token.tokensAllocated,
                    _userApproval.dateApproved,
                    _userApproval.approvalId,
                    _userApproval.claimExpiryTime,
                    _userApproval.approvedTokenAmount,
                    _userApproval.approvedWallet,
                    _userApproval.beneficiary.beneficiaryAddress,
                    _userApproval.token.tokenAddress,
                    _userApproval.claimed,
                    _userApproval.active
                    );
            }
        }
    }

    /**
     * @dev setBenApprovalClaimed - Function to set approval claimed for a specific apprival id for ben
     * @param _user address of the dApp identifier for the user
     * @param _id uint256 the id of the approval claimed
     *
     * emits an event to indicate state change of an approval as well
     * as changing the state inside of the BeneficiaryClaimableAsset list
     */
    function setBenApprovalClaimed(address _user, uint256 _id) internal {
        Approvals[] storage _approvals = BeneficiaryClaimableAsset[_user];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == _id) {
                Approvals storage userApproval = _approvals[i];
                userApproval.claimed = true;
                userApproval.active = false;
                emit ApprovalsEvent(
                    userApproval._uid,
                    userApproval.beneficiary.beneficiaryName,
                    userApproval.token.tokenId,
                    userApproval.token.tokenType,
                    userApproval.token.tokensAllocated,
                    userApproval.dateApproved,
                    userApproval.approvalId,
                    userApproval.claimExpiryTime,
                    userApproval.approvedTokenAmount,
                    userApproval.approvedWallet,
                    userApproval.beneficiary.beneficiaryAddress,
                    userApproval.token.tokenAddress,
                    userApproval.claimed,
                    userApproval.active
                    );
            }
        }
    }

    /**
     * @notice transferUnclaimedAsset - Function to claim Unclaimed Assets passed the claimable expiry time
     * @param uid string of the dApp identifier for the user
     */
    function transferUnclaimedAssets(string calldata uid) external onlyRelayerContract {
        address TransferPool = IProtocolDirectory(directoryContract).getTransferPool();
        Approvals[] memory _approval = MemberApprovals[uid];
        for (uint256 i = 0; i < _approval.length; i++) {
            if (
                block.timestamp >= _approval[i].claimExpiryTime && _approval[i].active == true
                    && _approval[i].claimed == false
            ) {
                if (
                    keccak256(abi.encodePacked((_approval[i].token.tokenType)))
                        == keccak256(abi.encodePacked(("ERC20")))
                ) {
                    IERC20 ERC20 = IERC20(_approval[i].token.tokenAddress);

                    // Percentage approach for storing erc20
                    uint256 _tokenAmount =
                        (_approval[i].token.tokensAllocated * ERC20.balanceOf(_approval[i].approvedWallet)) / 100;

                    ERC20.transferFrom(_approval[i].approvedWallet, TransferPool, _tokenAmount);

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(_approval[i].beneficiary.beneficiaryAddress, _approval[i].approvalId);
                }

                // transfer erc721
                if (
                    keccak256(abi.encodePacked((_approval[i].token.tokenType)))
                        == keccak256(abi.encodePacked(("ERC721")))
                ) {
                    IERC721 ERC721 = IERC721(_approval[i].token.tokenAddress);

                    ERC721.safeTransferFrom(_approval[i].approvedWallet, TransferPool, _approval[i].token.tokenId);
                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(_approval[i].beneficiary.beneficiaryAddress, _approval[i].approvalId);
                }

                // transfer erc1155
                if (
                    keccak256(abi.encodePacked((_approval[i].token.tokenType)))
                        == keccak256(abi.encodePacked(("ERC1155")))
                ) {
                    IERC1155 ERC1155 = IERC1155(_approval[i].token.tokenAddress);
                    uint256 _tokenAmount = (
                        _approval[i].token.tokensAllocated
                            * ERC1155.balanceOf(_approval[i].approvedWallet, _approval[i].token.tokenId)
                    ) / 100;

                    bytes memory data;
                    ERC1155.safeTransferFrom(
                        _approval[i].approvedWallet, TransferPool, _approval[i].token.tokenId, _tokenAmount, data
                    );

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(_approval[i].beneficiary.beneficiaryAddress, _approval[i].approvalId);
                }
            }
        }
    }

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     *
     */
    function claimAsset(string calldata uid, uint256 approvalId_) external {
        IMember(IProtocolDirectory(directoryContract).getMemberContract()).checkIfAddressIsBlacklisted(msg.sender);
        Approvals[] storage _approval = BeneficiaryClaimableAsset[msg.sender];
        for (uint256 i = 0; i < _approval.length; i++) {
            Approvals storage _userApproval = _approval[i];
            if (keccak256(abi.encodePacked((_userApproval._uid))) == keccak256(abi.encodePacked((uid)))) {
                if (_userApproval.beneficiary.beneficiaryAddress != msg.sender) {
                    revert OnlyBeneficiary();
                }
                if (_userApproval.active == true && _userApproval.claimed == false) {
                    if (_userApproval.approvalId == approvalId_) {
                        // transfer erc20
                        if (
                            keccak256(abi.encodePacked((_userApproval.token.tokenType)))
                                == keccak256(abi.encodePacked(("ERC20")))
                        ) {
                            setApprovalClaimed(uid, _userApproval.approvalId);
                            IERC20 ERC20 = IERC20(_userApproval.token.tokenAddress);

                            /// @notice gather the preset approved token amount for this beneficiary
                            uint256 _tokenAmount = (_userApproval.approvedTokenAmount);

                            /// @notice If the allowance for the member by claimer is greater than the _tokenAmount
                            if (ERC20.allowance(_userApproval.approvedWallet, msg.sender) > _tokenAmount) {
                                _tokenAmount = ERC20.allowance(_userApproval.approvedWallet, msg.sender);
                            }
                            uint256 webacyFees = _tokenAmount / 100 * 1;
                            ERC20.transferFrom(
                                _userApproval.approvedWallet,
                                IProtocolDirectory(directoryContract).getTransferPool(),
                                webacyFees
                            );
                            ERC20.transferFrom(
                                _userApproval.approvedWallet,
                                _userApproval.beneficiary.beneficiaryAddress,
                                _tokenAmount - webacyFees
                            );

                            _userApproval.claimed = true;
                        }

                        // transfer erc721
                        if (
                            keccak256(abi.encodePacked((_userApproval.token.tokenType)))
                                == keccak256(abi.encodePacked(("ERC721")))
                        ) {
                            IERC721 ERC721 = IERC721(_userApproval.token.tokenAddress);

                            _userApproval.claimed = true;
                            setApprovalClaimed(uid, _userApproval.approvalId);
                            ERC721.safeTransferFrom(
                                _userApproval.approvedWallet,
                                _userApproval.beneficiary.beneficiaryAddress,
                                _userApproval.token.tokenId
                            );
                        }

                        // transfer erc1155
                        if (
                            keccak256(abi.encodePacked((_userApproval.token.tokenType)))
                                == keccak256(abi.encodePacked(("ERC1155")))
                        ) {
                            IERC1155 ERC1155 = IERC1155(_userApproval.token.tokenAddress);
                            uint256 _tokenAmount = (_userApproval.approvedTokenAmount);

                            bytes memory data;
                            _userApproval.claimed = true;
                            setApprovalClaimed(uid, _userApproval.approvalId);
                            ERC1155.safeTransferFrom(
                                _userApproval.approvedWallet,
                                _userApproval.beneficiary.beneficiaryAddress,
                                _userApproval.token.tokenId,
                                _tokenAmount,
                                data
                            );
                        }

                        break;
                    }
                }
            }
        }
    }

    /**
     * @dev sendAssetsToCharity
     * @param _charityBeneficiaryAddress address of the charity beneficiary
     * @param _uid the uid stored for the user
     *
     * Send assets to the charity beneficiary if they exist;
     *
     */
    function sendAssetsToCharity(address _charityBeneficiaryAddress, string calldata _uid)
        external
        onlyRelayerContract
    {
        // look to see if this address is a charity
        Approvals[] storage charityBeneficiaryApprovals = BeneficiaryClaimableAsset[_charityBeneficiaryAddress];
        if (charityBeneficiaryApprovals.length == 0) {
            revert NoApprovalExists();
        }
        for (uint256 i; i < charityBeneficiaryApprovals.length; i++) {
            Approvals memory _beneficiaryApproval = charityBeneficiaryApprovals[i];
            if (!_beneficiaryApproval.beneficiary.isCharity) {
                revert NotCharity();
            }
            if (
                _beneficiaryApproval.active == true && _beneficiaryApproval.claimed == false
                    && (
                        keccak256(abi.encodePacked((_beneficiaryApproval.token.tokenType)))
                            == keccak256(abi.encodePacked(("ERC20")))
                    )
            ) {
                setApprovalClaimed(_uid, _beneficiaryApproval.approvalId);
                setBenApprovalClaimed(_charityBeneficiaryAddress, _beneficiaryApproval.approvalId);

                IERC20 ERC20 = IERC20(_beneficiaryApproval.token.tokenAddress);
                /// @notice gather the preset approved token amount for this beneficiary
                uint256 _tokenAmount = (_beneficiaryApproval.approvedTokenAmount);

                /// @notice If the allowance for the member by claimer is greater than the _tokenAmount
                if (ERC20.allowance(_beneficiaryApproval.approvedWallet, msg.sender) > _tokenAmount) {
                    _tokenAmount = ERC20.allowance(_beneficiaryApproval.approvedWallet, msg.sender);
                }
                uint256 webacyFees = _tokenAmount / 100 * 1;
                ERC20.transferFrom(
                    _beneficiaryApproval.approvedWallet,
                    IProtocolDirectory(directoryContract).getTransferPool(),
                    webacyFees
                );
                ERC20.transferFrom(
                    _beneficiaryApproval.approvedWallet,
                    _beneficiaryApproval.beneficiary.beneficiaryAddress,
                    _tokenAmount - webacyFees
                );

                _beneficiaryApproval.claimed = true;
            }
        }
    }

    /**
     * @dev getClaimableAssets allows users to get all claimable assets for a specific user.
     * @return return a list of assets being protected by this contract
     */
    function getClaimableAssets() external view returns (Token[] memory) {
        Approvals[] memory _approval = BeneficiaryClaimableAsset[msg.sender];
        uint256 _tokensCount;
        uint256 _index;

        for (uint256 k = 0; k < _approval.length; k++) {
            if (_approval[k].claimed == false && _approval[k].active == true) {
                _tokensCount++;
            }
        }
        Token[] memory _tokens = new Token[](_tokensCount);
        for (uint256 i = 0; i < _approval.length; i++) {
            if (_approval[i].claimed == false && _approval[i].active == true) {
                _tokens[_index] = _approval[i].token;
                _index++;
            }
        }
        return _tokens;
    }

    /**
     *  @notice setApprovalActive called by external actor to mark claiming period
     *  is active and ready
     *  @param uid string of the dApp identifier for the user
     *
     */
    function setApprovalActive(string memory uid) external onlyRelayerContract {
        Approvals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            _approvals[i].active = true;
            _approvals[i].claimExpiryTime = block.timestamp + 31536000;
            Approvals[] storage approvals = BeneficiaryClaimableAsset[_approvals[i].beneficiary.beneficiaryAddress];
            for (uint256 j = 0; j < approvals.length; j++) {
                if (keccak256(abi.encodePacked((approvals[j]._uid))) == keccak256(abi.encodePacked((uid)))) {
                    Approvals storage _userApprovals = approvals[j];
                    /// @notice check if is ERC20 for preAllocating then claiming
                    if (
                        keccak256(abi.encodePacked((_userApprovals.token.tokenType)))
                            == keccak256(abi.encodePacked(("ERC20")))
                    ) {
                        /// @notice setting fixed tokenAmount to claim later
                        _userApprovals.approvedTokenAmount = (
                            _userApprovals.token.tokensAllocated
                                * IERC20(_userApprovals.token.tokenAddress).balanceOf(_userApprovals.approvedWallet)
                        ) / 100;
                    }

                    if (
                        keccak256(abi.encodePacked((_userApprovals.token.tokenType)))
                            == keccak256(abi.encodePacked(("ERC1155")))
                    ) {
                        _userApprovals.approvedTokenAmount = (
                            _userApprovals.token.tokensAllocated
                                * IERC1155(_userApprovals.token.tokenAddress).balanceOf(
                                    _userApprovals.approvedWallet, _userApprovals.token.tokenId
                                )
                        ) / 100;
                    }

                    _userApprovals.active = true;
                    _userApprovals.claimExpiryTime = block.timestamp + 31536000;

                    emit ApprovalsEvent(
                        _userApprovals._uid,
                        _userApprovals.beneficiary.beneficiaryName,
                        _userApprovals.token.tokenId,
                        _userApprovals.token.tokenType,
                        _userApprovals.token.tokensAllocated,
                        _userApprovals.dateApproved,
                        _userApprovals.approvalId,
                        _userApprovals.claimExpiryTime,
                        _userApprovals.approvedTokenAmount,
                        _userApprovals.approvedWallet,
                        _userApprovals.beneficiary.beneficiaryAddress,
                        _userApprovals.token.tokenAddress,
                        _userApprovals.claimed,
                        _userApprovals.active
                        );
                }
            }
        }
    }

    /**
     * @dev deleteApprooval - Deletes the approval of the specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 id of the approval struct to be deleted
     *
     */
    function deleteApproval(string calldata uid, uint256 approvalId) external {
        Approvals[] memory approval_ = MemberApprovals[uid];
        IMember(IProtocolDirectory(directoryContract).getMemberContract()).checkUIDofSender(uid, msg.sender);
        for (uint256 i; i < approval_.length; i++) {
            Approvals memory _userApproval = approval_[i];
            if (_userApproval.approvalId == approvalId) {
                Approvals[] storage _approval_ = MemberApprovals[uid];
                for (uint256 j = i; j < _approval_.length - 1; j++) {
                    _approval_[j] = _approval_[j + 1];
                }
                _approval_.pop();
                approval_ = _approval_;

                Approvals[] storage _benApproval =
                    BeneficiaryClaimableAsset[_userApproval.beneficiary.beneficiaryAddress];
                for (uint256 k; k < _benApproval.length; k++) {
                    if (_benApproval[k].approvalId == approvalId) {
                        Approvals[] storage _benapproval_ =
                            BeneficiaryClaimableAsset[_benApproval[k].beneficiary.beneficiaryAddress];
                        for (uint256 l = k; l < _benapproval_.length - 1; l++) {
                            _benapproval_[l] = _benapproval_[l + 1];
                        }
                        _benapproval_.pop();
                        _benApproval = _benapproval_;
                        break;
                    }
                }
                break;
            }
        }
    }

    /**
     * @dev editApproval - Edits the token information of the approval
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 ID of the approval struct to modify
     * @param _contractAddress address being set for the approval
     * @param _tokenId uint256 tokenId being set of the approval
     * @param _tokenAmount uint256 amount of tokens in the approval
     * @param _tokenType string (ERC20 | ERC1155 | ERC721)
     *
     */
    function editApproval(
        string calldata uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string calldata _tokenType
    ) external {
        IMember(IProtocolDirectory(directoryContract).getMemberContract()).checkUIDofSender(uid, msg.sender);
        Approvals[] storage approval_ = MemberApprovals[uid];
        for (uint256 i; i < approval_.length; i++) {
            Approvals storage _userApproval = approval_[i];
            if (_userApproval.approvalId == approvalId) {
                if (_userApproval.active || _userApproval.claimed) {
                    revert NoApprovalExists();
                }

                TokenActions.checkAssetContract(_contractAddress, _tokenType, _tokenId, msg.sender, _tokenAmount);

                if (_tokenAmount > 100 || _tokenAmount < 0) {
                    revert InvalidTokenRange();
                }
                _userApproval.token.tokenAddress = _contractAddress;
                _userApproval.token.tokenId = _tokenId;
                _userApproval.token.tokensAllocated = _tokenAmount;
                _userApproval.token.tokenType = _tokenType;

                emit ApprovalsEvent(
                    _userApproval._uid,
                    _userApproval.beneficiary.beneficiaryName,
                    _tokenId,
                    _tokenType,
                    _tokenAmount,
                    _userApproval.dateApproved,
                    approvalId,
                    _userApproval.claimExpiryTime,
                    0,
                    _userApproval.approvedWallet,
                    _userApproval.beneficiary.beneficiaryAddress,
                    _contractAddress,
                    _userApproval.claimed,
                    _userApproval.active
                    );

                Approvals[] storage _beneficiaryApproval =
                    BeneficiaryClaimableAsset[_userApproval.beneficiary.beneficiaryAddress];
                for (uint256 j; j < _beneficiaryApproval.length; j++) {
                    Approvals storage _benApproval = _beneficiaryApproval[j];
                    if (_benApproval.approvalId == approvalId) {
                        if (_benApproval.active || _benApproval.claimed) {
                            revert NoApprovalExists();
                        }
                        _benApproval.token.tokenAddress = _contractAddress;
                        _benApproval.token.tokenId = _tokenId;
                        _benApproval.token.tokensAllocated = _tokenAmount;
                        _benApproval.token.tokenType = _tokenType;
                        break;
                    }
                }
                break;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IProtocolDirectory.sol";
import "../AssetsStore.sol";

// Errors
error UserHasAssetStore();

/**
 * @title AssetStoreFactory
 * This contract will deploy AssetStore contracts for users.
 * Users will pass approvals to that contract and this
 * contract will update state with details and track who has
 * which contracts
 *
 *
 */
contract AssetStoreFactory is
    IAssetStoreFactory,
    Initializable,
    OwnableUpgradeable
{
    /// @dev Storing all AssetStore Contract Addresses
    address[] private AssetStoreContractAddresses;

    /// @dev ProtocolDirectory location
    address private directoryContract;

    /// @dev Mapping User to a Specific Contract Address
    mapping(string => address) private UserToAssetStoreContract;

    /**
     * @dev event AssetStoreCreated
     * @param user address the AssetStore was deployed on behalf of
     * @param assetStoreAddress address of the dpeloyed contract
     * @param uid string identifier for the user across the dApp
     *
     */
    event AssetStoreCreated(
        address user,
        address assetStoreAddress,
        string uid
    );

    address private assetStoreImplementation;

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract - to the protocol directory contract
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        directoryContract = _directoryContract;
        assetStoreImplementation = address(new AssetsStore());
    }

    /**
     * @dev Function to deployAssetStore for each user
     * @param _uid string identifier of the user across the dApp
     *
     */
    function deployAssetStore(string memory _uid) external {
        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkIfAddressIsBlacklisted(tx.origin);
        address _userAddress = UserToAssetStoreContract[_uid];
        if (_userAddress != address(0)) {
            revert UserHasAssetStore();
        }

        if (
            (IMember(IProtocolDirectory(directoryContract).getMemberContract())
                .checkIfUIDExists(tx.origin) == false)
        ) {
            IMember(IProtocolDirectory(directoryContract).getMemberContract())
                .createMember(_uid, tx.origin);
        }

        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkUIDofSender(_uid, tx.origin);

        address assetStoreClone = Clones.clone(assetStoreImplementation);
        AssetsStore(assetStoreClone).initialize(directoryContract);
        AssetStoreContractAddresses.push(assetStoreClone);
        UserToAssetStoreContract[_uid] = assetStoreClone;

        emit AssetStoreCreated(tx.origin, assetStoreClone, _uid);
    }

    /**
     * @dev Function to return assetStore Address of a specific user
     * @param _uid string identifier for the user across the dApp
     * @return address of the AssetStore for given user
     */
    function getAssetStoreAddress(
        string memory _uid
    ) external view returns (address) {
        return UserToAssetStoreContract[_uid];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/ApprovalsStruct.sol";

/**
 *  @title IAssetStore
 *  @dev Interface for IAssetStore to interact with AssetStore Contracts
 *
 */
interface IAssetStore {
    /**
     * @notice storeAssetsApprovals - Function to store All Types Approvals by the user
     * @dev All of the arrays passed in need to be IN ORDER
     * they will be accessed in a loop together
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _memberUID string of the dApp identifier for the user
     *
     */
    function storeAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] memory _tokenIds,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) external;

    /**
     * @notice getApproval - Function to get a specific token Approval for the user passing in UID and ApprovalID
     * @dev searches state for a match by uid and approvalId for a given user
     *
     * @param uid string of the dApp identifier for the user
     * @param approvalId number of the individual approval to lookup
     *
     * @return approval_ struct storing information for an Approval
     */
    function getApproval(
        string calldata uid,
        uint256 approvalId
    ) external view returns (Approvals memory approval_);

    /**
     * @notice getBeneficiaryApproval - Function to get a token Approval for the beneficiaries - Admin function
     * @param _benAddress address to lookup a specific list of approvals for given beneficiary address
     * @return approval_ a list of approval structs for a specific address
     */
    function getBeneficiaryApproval(
        address _benAddress
    ) external view returns (Approvals[] memory approval_);

    /**
     * @notice getApprovals - Function to get all token Approvals for the user
     * @param uid string of the dApp identifier for the user
     * @return Approvals[] a list of all the approval structs associated with a user
     */
    function getApprovals(
        string calldata uid
    ) external view returns (Approvals[] memory);

    /**
     *  @notice setApprovalActive called by external actor to mark claiming period
     *  is active and ready
     *  @param uid string of the dApp identifier for the user
     *
     */
    function setApprovalActive(string calldata uid) external;

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     *
     */
    function claimAsset(string calldata uid, uint256 approvalId_) external;

    /**
     * @dev getClaimableAssets allows users to get all claimable assets for a specific user.
     * @return return a list of assets being protected by this contract
     */
    function getClaimableAssets() external view returns (Token[] memory);

    /**
     * @dev deleteApprooval - Deletes the approval of the specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 id of the approval struct to be deleted
     *
     */
    function deleteApproval(string calldata uid, uint256 approvalId) external;

    /**
     * @dev editApproval - Edits the token information of the approval
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 ID of the approval struct to modify
     * @param _contractAddress address being set for the approval
     * @param _tokenId uint256 tokenId being set of the approval
     * @param _tokenAmount uint256 amount of tokens in the approval
     * @param _tokenType string (ERC20 | ERC1155 | ERC721)
     *
     */
    function editApproval(
        string memory uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string memory _tokenType
    ) external;

    /**
     * @notice Function to store All Types of Approvals and Backups by the user in one function
     * @dev storeAssetsAndBackUpApprovals calls
     *  storeBackupAssetsApprovals & storeAssetsApprovals
     * 
     * sent to storeAssetsApprovals:
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     
     * sent to storeBackupAssetsApprovals:
     * @param _backUpTokenIds uint256[] Ordered list of tokenIds to be in a backup plan
     * @param _backupTokenAmount uint256[] Ordered list representing a magnitube of tokens to be in a backupPlan
     * @param _backUpWallets address[] Ordered list of destination wallets for the backupPlan
     * @param _backUpAddresses address[] Ordered list of contract addresses of assets for the backupPlan
     * @param _backupTokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param uid string of the dApp identifier for the user
     * 
     * 
     */
    function storeAssetsAndBackUpApprovals(
        address[] calldata _contractAddress,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] calldata _backUpWallets,
        address[] calldata _backUpAddresses,
        string[] memory _backupTokenTypes,
        string memory uid
    ) external;

    /**
     * @notice transferUnclaimedAsset - Function to claim Unclaimed Assets passed the claimable expiry time
     * @param uid string of the dApp identifier for the user
     */
    function transferUnclaimedAssets(string calldata uid) external;

    /**
     * @dev sendAssetsToCharity
     * @param _charityBeneficiaryAddress address of the charity beneficiary
     * @param _uid the uid stored for the user
     *
     * Send assets to the charity beneficiary if they exist;
     *
     */
    function sendAssetsToCharity(
        address _charityBeneficiaryAddress,
        string memory _uid
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAssetStoreFactory
 * @dev Interface to interact with AssetStore Factory
 *
 */
interface IAssetStoreFactory {
    /**
     * @dev Function to deployAssetStore for each user
     * @param _uid string identifier of the user across the dApp
     *
     */
    function deployAssetStore(string memory _uid) external;

    /**
     * @dev Function to return assetStore Address of a specific user
     * @param _uid string identifier for the user across the dApp
     * @return address of the AssetStore for given user
     *
     */
    function getAssetStoreAddress(
        string memory _uid
    ) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/MemberStruct.sol";
import "../structs/BackupApprovalStruct.sol";

/**
 * @title Interface for IMember
 * @dev to interact with Member Contracts
 *
 */
interface IMember {
    /**
     * @dev createMember
     * @param  uid centrally stored id for user
     * @param _walletAddress walletAddress to add wallet and check blacklist
     *
     * Allows to create a member onChain with a unique UID passed.
     * Will revert if the _walletAddress passed in is blacklisted
     *
     */
    function createMember(string calldata uid, address _walletAddress) external;

    /**
     * @dev getMember
     * @param uid string for centrally located identifier
     * Allows to get member information stored onChain with a unique UID passed.
     * @return member struct for a given uid
     *
     */
    function getMember(string memory uid) external view returns (member memory);

    /**
     * @dev getAllMembers
     * Allows to get all member information stored onChain
     * @return allMembers a list of member structs
     *
     */
    function getAllMembers() external view returns (member[] memory);

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function addWallet(
        string calldata uid,
        address _wallet,
        bool _primary
    ) external;

    /**
     * @dev getWallets
     * Allows to get all wallets of the user
     * @param uid string for dApp user identifier
     * @return address[] list of wallets
     *
     */
    function getWallets(
        string calldata uid
    ) external view returns (address[] memory);

    /**
     * @dev deleteWallet - Allows to delete  wallets of a specific user
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function deleteWallet(string calldata uid, uint256 _walletIndex) external;

    /**
     * @dev getPrimaryWallets
     * Allows to get primary wallet of the user
     * @param uid string for dApp user identifier
     * @return address of the primary wallet per user
     *
     */
    function getPrimaryWallet(
        string memory uid
    ) external view returns (address);

    /**
     * @dev setPrimaryWallet
     * Allows to set a specific wallet as the primary wallet
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function setPrimaryWallet(
        string calldata uid,
        uint256 _walletIndex
    ) external;

    /**
     * @notice Function to check if wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _user address of the user checking exists
     * Fails if not owner uid and user address do not return a wallet
     *
     */
    function checkUIDofSender(string memory _uid, address _user) external view;

    /**
     * @dev checkIfUIDExists
     * Check if user exists for specific wallet address already internal function
     * @param _walletAddress wallet address of the user
     * @return _exists - A boolean if user exists or not
     *
     */
    function checkIfUIDExists(
        address _walletAddress
    ) external view returns (bool _exists);

    /**
     * @dev getUID
     * Allows user to pass walletAddress and return UID
     * @param _walletAddress get the UID of the user's if their wallet address is present
     * @return string of the ID used in the dApp to identify they user
     *
     */
    function getUID(
        address _walletAddress
    ) external view returns (string memory);

    /**
     * @dev getBackupApprovals - function to return all backupapprovals for a specific UID
     * @param uid string of identifier for user in dApp
     * @return BackUpApprovals[] list of BackUpApprovals struct
     *
     */
    function getBackupApprovals(
        string memory uid
    ) external view returns (BackUpApprovals[] memory);

    /**
     * @dev storeBackupAssetsApprovals - Function to store All Types Approvals by the user for backup
     *
     * @param _contractAddress address[] Ordered list of contract addresses for assets
     * @param _tokenIds uint256[] Ordered list of tokenIds associated with contract addresses
     * @param _backUpWallets address[] Ordered list of wallet addresses to backup assets
     * @param _tokenAmount uint256[] Ordered list of amounts per asset contract and token id to protext
     * @param _tokenTypes string[] Ordered list of strings i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string for dApp user identifier
     *
     */
    function storeBackupAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) external;

    /**
     * @dev executePanic - Public function to transfer assets from one user to another
     * @param _backUpWallet wallet to panic send assets to
     * @param _memberUID uid of the user's assets being moved
     *
     */
    function executePanic(
        address _backUpWallet,
        string memory _memberUID
    ) external;

    /**
     * @dev editBackup - Function to edit individual backup approvals
     * @param approvalId_ uint256 id to lookup Approval and edit
     * @param _contractAddress address contractAddress of asset to save
     * @param _tokenIds uint256 tokenId of asset
     * @param _tokenAmount uint256 amount of specific token
     * @param _tokenType string type of the token i.e. ERC20 | ERC721 | ERC1155
     * @param _uid string of identifier for user in dApp
     *
     */
    function editBackUp(
        uint256 approvalId_,
        address _contractAddress,
        uint256 _tokenIds,
        uint256 _tokenAmount,
        string calldata _tokenType,
        string memory _uid
    ) external;

    /**
     * @dev editAllBackUp - Function to delete and add new approvals for backup
     * @param _contractAddress address[] Ordered list of addresses for asset contracts
     * @param _tokenIds uint256[] Ordered list of tokenIds to backup
     * @param _backUpWallets address[] Ordered list of wallets that can be backups
     * @param _tokenAmount uint256[] Ordered list of amounts of tokens to backup
     * @param _tokenTypes string[] Ordered list of string tokenTypes i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string of identifier for user in dApp
     *
     *
     */
    function editAllBackUp(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) external;

    /**
     * @dev deleteAllBackUp - Function to delete all backup approvals
     * @param _uid string of identifier for user in dApp
     *
     */
    function deleteAllBackUp(string memory _uid) external;

    /**
     * @notice checkIfWalletHasNFT
     * verify if the user has specific nft 1155 or 721
     * @param _contractAddress address of asset contract
     * @param _NFTType string i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId checking for ownership
     * @param userAddress address address to verify ownership of
     * Fails if not owner
     */
    function checkIfWalletHasNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address userAddress
    ) external view;

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function addBackupWallet(
        string calldata uid,
        address[] memory _wallets
    ) external;

    /**
     * @dev getBackupWallets - Returns backup Wallets for the specific UID
     * @param uid string for dApp user identifier
     *
     */
    function getBackupWallets(
        string calldata uid
    ) external view returns (address[] memory);

    /**
     * @dev checkIfAddressIsBlacklisted
     * @param _user address of wallet to check is blacklisted
     *
     */
    function checkIfAddressIsBlacklisted(address _user) external view;

    /**
     * @dev Function to get blacklisted addresses
     * @return blackListAddresses address[]
     *
     */
    function getBlacklistedAddresses() external view returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Protocol Directory interface
 *
 * Use this interface in any contract that needs to find
 * the contract location for commonly used Webacy contracts
 *
 */

interface IProtocolDirectory {
    /**
     * @notice event for recording changes of contracts
     *
     */
    event AddressSet(bytes32 contractName, address indexed newContractAddress);

    /**
     * @notice get the address by a bytes32 location id
     * @param _contractName a bytes32 string
     *
     */
    function getAddress(bytes32 _contractName) external returns (address);

    /**
     * @notice setAddress
     * @param _contractName a bytes32 string
     * @param _contractLocation an address of to entrypoint of protocol contract
     *
     */
    function setAddress(
        bytes32 _contractName,
        address _contractLocation
    ) external returns (address);

    /**
     * @notice ssetStoreFactory
     * @return address of protocol contract matching ASSET_STORE_FACTORY value
     *
     */
    function getAssetStoreFactory() external view returns (address);

    /**
     * @notice getRelayerContract
     * @return address of protocol contract matching RELAYER_CONTRACT value
     *
     */
    function getRelayerContract() external view returns (address);

    /**
     * @notice getMemberContract
     * @return address of protocol contract matching MEMBER_CONTRACT value
     *
     */
    function getMemberContract() external view returns (address);

    /**
     * @notice getTransferPool
     * @return address of protocol contract matching TRANSFER_POOL value
     *
     */
    function getTransferPool() external view returns (address);

    /**
     * @dev setAssetStoreFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setAssetStoreFactory(
        address _contractLocation
    ) external returns (address);

    /**
     * @dev setRelayerContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setRelayerContract(
        address _contractLocation
    ) external returns (address);

    /**
     * @dev setMemberContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setMemberContract(
        address _contractLocation
    ) external returns (address);

    /**
     * @dev setTransferPool
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setTransferPool(
        address _contractLocation
    ) external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../structs/ApprovalsStruct.sol";

/**
 * @title TokenActions Library
 *
 * Here contains the common functions for interacting with
 * tokens for importing in different parts of the ecosystem
 * to save space hopefully in other places
 */
library TokenActions {
    /**
     *
     * @dev checkAssetContract
     * @param _contractAddress contract of the token we are checking
     * @param _tokenType the given tokentype as a string ERC721 etc...
     *
     * Checks if the assets passed through are assets of the determined type or not.
     * it can handle upgradable versions as well if needed
     *
     */
    function checkAssetContract(
        address _contractAddress,
        string memory _tokenType,
        uint256 _tokenId,
        address _user,
        uint256 tokenAmount
    ) public view {
        if ((keccak256(abi.encodePacked((_tokenType))) == keccak256(abi.encodePacked(("ERC721"))))) {
            require(
                (
                    IERC721Upgradeable(_contractAddress).supportsInterface(type(IERC721Upgradeable).interfaceId)
                        || IERC721(_contractAddress).supportsInterface(type(IERC721).interfaceId)
                ),
                "LIB: Does not support a Supported ERC721 Interface"
            );
            require(IERC721(_contractAddress).ownerOf(_tokenId) == _user, "LIB: Token not Owned by User");
        } else if (keccak256(abi.encodePacked((_tokenType))) == keccak256(abi.encodePacked(("ERC20")))) {
            require(
                (IERC20(_contractAddress).totalSupply() >= 0 || IERC20Upgradeable(_contractAddress).totalSupply() >= 0),
                "LIB: Is not an ERC20 Contract Address"
            );
            require(
                IERC20(_contractAddress).balanceOf(_user) >= tokenAmount,
                "LIB: User does not have sufficient ERC20 balance for approving token"
            );
        } else if (keccak256(abi.encodePacked((_tokenType))) == keccak256(abi.encodePacked(("ERC1155")))) {
            require(
                (
                    IERC1155Upgradeable(_contractAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId)
                        || IERC1155(_contractAddress).supportsInterface(type(IERC1155).interfaceId)
                ),
                "LIB: Does not support a Supported ERC1155 Interface"
            );
            require(
                IERC1155(_contractAddress).balanceOf(_user, _tokenId) >= tokenAmount,
                "LIB: User does not have sufficient balance for ERC1155 tokens to approve"
            );
        } else {
            revert("Invalid token type");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IMember.sol";
import "./libraries/TokenActions.sol";
import "./structs/MemberStruct.sol";
import "./structs/BackupApprovalStruct.sol";

// Errors definition
error OnlyWalletOfUser();
error UserNotTokenOwner();
error NotValidUID();
error UserExists();
error OnlyRelayer();
error UserDoesNotExist();
error UserMustHaveWallet();
error TokensDifferentLength();
error RequireBackupApproval();
error RequireBackupWallet();
error MemberRequireTopup();
error NotFactoryAddress();
error StoringBackupFailed();
error UserBlacklisted(); // user has been blacklisted

/**
 * @title Member Contract
 * @notice This contract contains logic for interacting with the
 * ecosystem and verifying ownership as well as the panic button
 * functionality and backup information (BackupPlan)
 *
 */

contract Member is IMember, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Mapping to return member when uid is passed
    mapping(string => member) public members;

    /// @notice mapping for token backup Approvals for specific UID
    mapping(string => BackUpApprovals[]) private MemberApprovals;

    /// @notice Storing ApprovalId for different approvals stored
    uint88 private _approvalId;

    /// @dev address of the ProtocolDirectory
    address public directoryContract;

    /// @dev blacklisted addresses list
    address[] private blackListAddresses;

    /// @notice Variable to store all member information
    member[] public allMembers;

    /**
     * @notice memberCreated Event when creating member
     * @param uid string of dApp identifier for a user
     * @param dateCreated timestamp of event occurence
     *
     */
    event memberCreated(string uid, uint256 dateCreated);

    /**
     * @notice Event when updating primary wallet
     * @param uid string string of dApp identifier for a user
     * @param dateCreated uint256 timestamap of event occuring
     * @param wallets address[] list of wallets for the user
     * @param primaryWallet uint256 primary wallet for assets
     *
     */
    event memberUpdated(
        string uid, uint256 dateCreated, address[] backUpWallets, address[] wallets, uint256 primaryWallet
    );

    /**
     * @notice Event for Querying Approvals
     *
     * @param uid string of dApp identifier for a user
     * @param approvedWallet address of the wallet owning the asset
     * @param backupaddress address[] list of addresses containing assets
     * @param tokenId uint256 tokenId of asset being backed up
     * @param tokenAddress address contract of the asset being protectd
     * @param tokenType string i.e. ERC20 | ERC1155 | ERC721
     * @param tokensAllocated uint256 number of tokens to be protected
     * @param dateApproved uint256 timestamp of event happening
     * @param claimed bool status of the backupApproval
     * @param approvalId uint256 id of the approval being acted on
     * @param claimedWallet address of receipient of assets
     *
     *
     */
    event BackUpApprovalsEvent(
        string uid,
        address approvedWallet,
        address[] backupaddress,
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        uint256 dateApproved,
        bool claimed,
        uint256 approvalId,
        address claimedWallet
    );

    /**
     * @dev Modifier checking that only the RelayerContract can invoke certain functions
     *
     */
    modifier onlyRelayerContract() {
        address relayerAddress = IProtocolDirectory(directoryContract).getRelayerContract();
        if (msg.sender != relayerAddress) {
            revert OnlyRelayer();
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of protocol directory contract
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        _approvalId = 0;
        directoryContract = _directoryContract;
    }

    /**
     * @notice Function to check if wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _user address of the user checking exists
     * Fails if not owner uid and user address do not return a wallet
     *
     */
    function checkUIDofSender(string calldata _uid, address _user) public view {
        address[] memory wallets = members[_uid].wallets;
        bool walletExists = false;
        for (uint256 i; i < wallets.length; i++) {
            if (wallets[i] == _user) {
                walletExists = true;
            }
        }
        if (walletExists == false) {
            revert OnlyWalletOfUser();
        }
    }

    /**
     * @dev checkIfUIDExists
     * Check if user exists for specific wallet address already internal function
     * @param _walletAddress wallet address of the user
     * @return _exists - A boolean if user exists or not
     *
     */
    function checkIfUIDExists(address _walletAddress) public view returns (bool _exists) {
        checkIfAddressIsBlacklisted(msg.sender);
        uint256 _memberLength = allMembers.length;
        for (uint256 i; i < _memberLength; i++) {
            address[] memory _wallets = allMembers[i].wallets;
            if (_wallets.length != 0) {
                uint256 _walletLength = _wallets.length;
                for (uint256 j; j < _walletLength; j++) {
                    if (_wallets[j] == _walletAddress) {
                        _exists = true;
                    }
                }
            }
        }
    }

    /**
     * @notice checkIfWalletHasNFT
     * verify if the user has specific nft 1155 or 721
     * @param _contractAddress address of asset contract
     * @param _NFTType string i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId checking for ownership
     * @param userAddress address address to verify ownership of
     * Fails if not owner
     */
    function checkIfWalletHasNFT(
        address _contractAddress,
        string calldata _NFTType,
        uint256 tokenId,
        address userAddress
    ) public view {
        // check if wallet has nft
        bool status = false;
        if (keccak256(abi.encodePacked((_NFTType))) == keccak256(abi.encodePacked(("ERC721")))) {
            if (IERC721(_contractAddress).ownerOf(tokenId) == userAddress) {
                status = true;
            } else if (IERC721Upgradeable(_contractAddress).ownerOf(tokenId) == userAddress) {
                status = true;
            }
        }

        if (keccak256(abi.encodePacked((_NFTType))) == keccak256(abi.encodePacked(("ERC1155")))) {
            if (IERC1155(_contractAddress).balanceOf(userAddress, tokenId) != 0) {
                status = true;
            } else if (IERC1155Upgradeable(_contractAddress).balanceOf(userAddress, tokenId) != 0) {
                status = true;
            }
        }

        if (status == false) {
            revert UserNotTokenOwner();
        }
    }

    /**
     * @dev createMember
     * @param  uid centrally stored id for user
     * @param _walletAddress walletAddress to add wallet and check blacklist
     *
     * Allows to create a member onChain with a unique UID passed.
     * Will revert if the _walletAddress passed in is blacklisted
     *
     */
    function createMember(string calldata uid, address _walletAddress) public {
        checkIfAddressIsBlacklisted(msg.sender);
        if (
            (
                keccak256(abi.encodePacked((members[uid].uid))) != keccak256(abi.encodePacked((uid)))
                    && (checkIfUIDExists(_walletAddress) == false)
            )
        ) {
            if (bytes(uid).length == 0) {
                revert NotValidUID();
            }
            address[] memory _wallets;
            member memory _member = member(block.timestamp, _wallets, _wallets, 0, uid);
            members[uid] = _member;
            allMembers.push(_member);
            _addWallet(uid, _walletAddress, true);
            emit memberCreated(_member.uid, _member.dateCreated);
        } else {
            revert UserExists();
        }
    }

    /**
     * @dev getMember
     * @param uid string for centrally located identifier
     * Allows to get member information stored onChain with a unique UID passed.
     * @return member struct for a given uid
     *
     */
    function getMember(string calldata uid) public view returns (member memory) {
        member memory currentMember = members[uid];
        if (currentMember.dateCreated == 0) {
            revert UserDoesNotExist();
        }
        return currentMember;
    }

    /**
     * @dev getAllMembers
     * Allows to get all member information stored onChain
     * @return allMembers a list of member structs
     *
     */
    function getAllMembers() external view returns (member[] memory) {
        return allMembers;
    }

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function addWallet(string calldata uid, address _wallet, bool _primary) public {
        checkUIDofSender(uid, msg.sender);
        _addWallet(uid, _wallet, _primary);
    }

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function _addWallet(string calldata uid, address _wallet, bool _primary) internal {
        member storage _member = members[uid];
        _member.wallets.push(_wallet);
        if (_primary) {
            _member.primaryWallet = _member.wallets.length - 1;
        }

        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (keccak256(abi.encodePacked((member_.uid))) == keccak256(abi.encodePacked((uid)))) {
                member_.wallets.push(_wallet);
                if (_primary) {
                    member_.primaryWallet = member_.wallets.length - 1;
                }
            }
        }

        emit memberUpdated(
            _member.uid, _member.dateCreated, _member.backUpWallets, _member.wallets, _member.primaryWallet
            );
    }

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function addBackupWallet(string calldata uid, address[] calldata _wallets) public {
        checkUIDofSender(uid, msg.sender);
        _addBackupWallet(uid, _wallets, msg.sender);
    }

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function _addBackupWallet(string calldata uid, address[] calldata _wallets, address _user) internal {
        if ((checkIfUIDExists(_user) == false)) {
            createMember(uid, _user);
        }
        member storage _member = members[uid];
        if (_member.wallets.length == 0) {
            revert UserMustHaveWallet();
        }
        for (uint256 i; i < _wallets.length; i++) {
            _member.backUpWallets.push(_wallets[i]);
        }

        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (keccak256(abi.encodePacked((member_.uid))) == keccak256(abi.encodePacked((uid)))) {
                for (uint256 j; j < _wallets.length; j++) {
                    member_.backUpWallets.push(_wallets[j]);
                }
            }
        }
        emit memberUpdated(
            _member.uid, _member.dateCreated, _member.backUpWallets, _member.wallets, _member.primaryWallet
            );
    }

    /**
     * @dev getBackupWallets - Returns backup Wallets for the specific UID
     * @param uid string for dApp user identifier
     *
     */
    function getBackupWallets(string calldata uid) external view returns (address[] memory) {
        return members[uid].backUpWallets;
    }

    /**
     * @dev deleteWallet - Allows to delete  wallets of a specific user
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function deleteWallet(string calldata uid, uint256 _walletIndex) external {
        checkUIDofSender(uid, msg.sender);
        member storage _member = members[uid];
        delete _member.wallets[_walletIndex];
        address[] storage wallets = _member.wallets;
        for (uint256 i = _walletIndex; i < wallets.length - 1; i++) {
            wallets[i] = wallets[i + 1];
        }

        if (_member.primaryWallet >= _walletIndex) {
            _member.primaryWallet--;
        }
        wallets.pop();

        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (keccak256(abi.encodePacked((member_.uid))) == keccak256(abi.encodePacked((uid)))) {
                address[] storage wallets_ = member_.wallets;
                for (uint256 j = _walletIndex; j < wallets_.length - 1; j++) {
                    wallets_[j] = wallets_[j + 1];
                }
                wallets_.pop();
                if (member_.primaryWallet >= _walletIndex) {
                    member_.primaryWallet--;
                }
            }
        }
    }

    /**
     * @dev setPrimaryWallet
     * Allows to set a specific wallet as the primary wallet
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function setPrimaryWallet(string calldata uid, uint256 _walletIndex) external {
        checkUIDofSender(uid, msg.sender);
        members[uid].primaryWallet = _walletIndex;
        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (keccak256(abi.encodePacked((member_.uid))) == keccak256(abi.encodePacked((uid)))) {
                member_.primaryWallet = _walletIndex;
            }
        }
    }

    /**
     * @dev getWallets
     * Allows to get all wallets of the user
     * @param uid string for dApp user identifier
     * @return address[] list of wallets
     *
     */
    function getWallets(string calldata uid) external view returns (address[] memory) {
        return members[uid].wallets;
    }

    /**
     * @dev getPrimaryWallets
     * Allows to get primary wallet of the user
     * @param uid string for dApp user identifier
     * @return address of the primary wallet per user
     *
     */
    function getPrimaryWallet(string memory uid) public view returns (address) {
        return members[uid].wallets[members[uid].primaryWallet];
    }

    /**
     * @dev checkWallet
     * Allows to check if a wallet is a Backup wallets of the user
     * @param _Wallets list of addresses to check if wallet is present
     * @param uid string for dApp user identifier
     * @return boolean if the wallet exists
     *
     */
    function checkWallet(address[] calldata _Wallets, string memory uid) internal view returns (bool) {
        address[] memory wallets = members[uid].wallets;
        bool walletExists = false;
        for (uint256 i; i < wallets.length; i++) {
            for (uint256 j = 0; j < _Wallets.length; j++) {
                if (wallets[i] == _Wallets[j]) {
                    walletExists = true;
                }
            }
        }
        return walletExists;
    }

    /**
     * @dev getUID
     * Allows user to pass walletAddress and return UID
     * @param _walletAddress get the UID of the user's if their wallet address is present
     * @return string of the ID used in the dApp to identify they user
     *
     */
    function getUID(address _walletAddress) public view override returns (string memory) {
        string memory memberuid;
        for (uint256 i; i < allMembers.length; i++) {
            address[] memory _wallets = allMembers[i].wallets;
            if (_wallets.length != 0) {
                for (uint256 j = 0; j < _wallets.length; j++) {
                    if (_wallets[j] == _walletAddress) {
                        memberuid = allMembers[i].uid;
                    }
                }
            }
        }
        if (bytes(memberuid).length == 0) {
            revert UserDoesNotExist();
        }
        return memberuid;
    }

    /**
     * @dev storeBackupAssetsApprovals - Function to store All Types Approvals by the user for backup
     *
     * @param _contractAddress address[] Ordered list of contract addresses for assets
     * @param _tokenIds uint256[] Ordered list of tokenIds associated with contract addresses
     * @param _backUpWallets address[] Ordered list of wallet addresses to backup assets
     * @param _tokenAmount uint256[] Ordered list of amounts per asset contract and token id to protext
     * @param _tokenTypes string[] Ordered list of strings i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string for dApp user identifier
     *
     */
    function storeBackupAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) public {
        if (
            _tokenIds.length != _contractAddress.length || _tokenAmount.length != _tokenTypes.length
                || _backUpWallets.length != _tokenIds.length
        ) {
            revert TokensDifferentLength();
        }

        if ((checkIfUIDExists(tx.origin) == false)) {
            createMember(_memberUID, tx.origin);
        }

        checkUIDofSender(_memberUID, tx.origin);

        _addBackupWallet(_memberUID, _backUpWallets, tx.origin);
        for (uint256 i; i < _tokenIds.length; i++) {
            address contractAddress = _contractAddress[i];
            string memory tokenType = _tokenTypes[i];
            uint256 tokenId = _tokenIds[i];
            uint256 tokenAllocated = _tokenAmount[i];

            TokenActions.checkAssetContract(contractAddress, tokenType, tokenId, tx.origin, tokenAllocated);

            _storeAssets(
                _memberUID, tx.origin, _backUpWallets, Token(contractAddress, tokenId, tokenAllocated, tokenType)
            );
        }
    }

    /**
     * @dev _storeAssets - Internal function to store assets approvals for backup
     * @param uid string identifier of user across dApp
     * @param user address of the user of the dApp
     * @param _backUpWallet address[] list of wallets protected
     * @param _token Token struct containing token information
     *
     */
    function _storeAssets(string calldata uid, address user, address[] calldata _backUpWallet, Token memory _token)
        internal
    {
        uint256 _dateApproved = block.timestamp;

        BackUpApprovals memory approval =
            BackUpApprovals(_backUpWallet, user, false, ++_approvalId, _token, _dateApproved, uid);

        MemberApprovals[uid].push(approval);
        emit BackUpApprovalsEvent(
            uid,
            user,
            _backUpWallet,
            _token.tokenId,
            _token.tokenAddress,
            _token.tokenType,
            _token.tokensAllocated,
            _dateApproved,
            false,
            _approvalId,
            address(0)
            );
    }

    /**
     * @dev executePanic - Public function to transfer assets from one user to another
     * @param _backUpWallet wallet to panic send assets to
     * @param _memberUID uid of the user's assets being moved
     *
     */
    function executePanic(address _backUpWallet, string calldata _memberUID) external {
        checkBackupandSenderofUID(_memberUID, msg.sender);
        checkIfAddressIsBlacklisted(_backUpWallet);
        if (MemberApprovals[_memberUID].length <= 0) {
            revert RequireBackupApproval();
        }
        _panic(_memberUID, _backUpWallet);
    }

    /**
     * @dev _checkBackUpExists - Internal function that checks backup approvals if the backup Wallet Exists
     * @param _approvals BackUpApprovals struct with backup information
     * @param _backUpWallet wallet to verify is inside of approval
     *
     */
    function _checkBackUpExists(BackUpApprovals memory _approvals, address _backUpWallet) internal pure {
        bool backUpExists = false;
        for (uint256 j; j < _approvals.backUpWallet.length; j++) {
            if (_approvals.backUpWallet[j] == _backUpWallet) {
                backUpExists = true;
            }
        }
        if (!backUpExists) {
            revert RequireBackupWallet();
        }
    }

    /**
     * @dev _panic - Private Function to test panic functionality in order to execute and transfer all assets from one user to another
     * @param uid string of identifier for user in dApp
     * @param _backUpWallet address where to send assets to
     *
     */
    function _panic(string calldata uid, address _backUpWallet) internal {
        BackUpApprovals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i; i < _approvals.length; i++) {
            BackUpApprovals storage _userApproval = _approvals[i];
            if (_userApproval.claimed == false) {
                _checkBackUpExists(_userApproval, _backUpWallet);
                if (
                    keccak256(abi.encodePacked((_userApproval.token.tokenType)))
                        == keccak256(abi.encodePacked(("ERC20")))
                ) {
                    IERC20 ERC20 = IERC20(_userApproval.token.tokenAddress);

                    uint256 tokenAllowance = ERC20.allowance(_userApproval.approvedWallet, address(this));
                    uint256 tokenBalance = ERC20.balanceOf(_userApproval.approvedWallet);

                    if (tokenBalance <= tokenAllowance) {
                        uint256 webacyFees = tokenBalance / 100 * 1;

                        ERC20.transferFrom(
                            _userApproval.approvedWallet,
                            IProtocolDirectory(directoryContract).getTransferPool(),
                            webacyFees
                        );
                        ERC20.transferFrom(_userApproval.approvedWallet, _backUpWallet, tokenBalance - webacyFees);
                    } else {
                        uint256 webacyFees = tokenAllowance / 100 * 1;
                        ERC20.transferFrom(_userApproval.approvedWallet, _backUpWallet, webacyFees);
                        ERC20.transferFrom(_userApproval.approvedWallet, _backUpWallet, tokenAllowance - webacyFees);
                    }

                    _userApproval.claimed = true;
                    emit BackUpApprovalsEvent(
                        _userApproval._uid,
                        _userApproval.approvedWallet,
                        _userApproval.backUpWallet,
                        _userApproval.token.tokenId,
                        _userApproval.token.tokenAddress,
                        _userApproval.token.tokenType,
                        _userApproval.token.tokensAllocated,
                        _userApproval.dateApproved,
                        _userApproval.claimed,
                        _userApproval.approvalId,
                        _backUpWallet
                        );
                }
                if (
                    keccak256(abi.encodePacked((_userApproval.token.tokenType)))
                        == keccak256(abi.encodePacked(("ERC721")))
                ) {
                    IERC721 ERC721 = IERC721(_userApproval.token.tokenAddress);

                    address _tokenAddress = ERC721.ownerOf(_userApproval.token.tokenId);

                    if (_tokenAddress == _userApproval.approvedWallet) {
                        ERC721.safeTransferFrom(
                            _userApproval.approvedWallet, _backUpWallet, _userApproval.token.tokenId
                        );
                    }

                    _userApproval.claimed = true;
                    emit BackUpApprovalsEvent(
                        _userApproval._uid,
                        _userApproval.approvedWallet,
                        _userApproval.backUpWallet,
                        _userApproval.token.tokenId,
                        _userApproval.token.tokenAddress,
                        _userApproval.token.tokenType,
                        _userApproval.token.tokensAllocated,
                        _userApproval.dateApproved,
                        _userApproval.claimed,
                        _userApproval.approvalId,
                        _backUpWallet
                        );
                }
                if (
                    keccak256(abi.encodePacked((_userApproval.token.tokenType)))
                        == keccak256(abi.encodePacked(("ERC1155")))
                ) {
                    IERC1155 ERC1155 = IERC1155(_userApproval.token.tokenAddress);

                    uint256 _balance = ERC1155.balanceOf(_userApproval.approvedWallet, _userApproval.token.tokenId);
                    bytes memory data;

                    if (_balance < _userApproval.token.tokensAllocated) {
                        ERC1155.safeTransferFrom(
                            _userApproval.approvedWallet, _backUpWallet, _userApproval.token.tokenId, _balance, data
                        );
                    } else {
                        ERC1155.safeTransferFrom(
                            _userApproval.approvedWallet,
                            _backUpWallet,
                            _userApproval.token.tokenId,
                            _userApproval.token.tokensAllocated,
                            data
                        );
                    }

                    _userApproval.claimed = true;
                    emit BackUpApprovalsEvent(
                        _userApproval._uid,
                        _userApproval.approvedWallet,
                        _userApproval.backUpWallet,
                        _userApproval.token.tokenId,
                        _userApproval.token.tokenAddress,
                        _userApproval.token.tokenType,
                        _userApproval.token.tokensAllocated,
                        _userApproval.dateApproved,
                        _userApproval.claimed,
                        _userApproval.approvalId,
                        _backUpWallet
                        );
                }
            }
        }
    }

    /**
     * @dev getBackupApprovals - function to return all backupapprovals for a specific UID
     * @param uid string of identifier for user in dApp
     * @return BackUpApprovals[] list of BackUpApprovals struct
     *
     */
    function getBackupApprovals(string calldata uid) external view returns (BackUpApprovals[] memory) {
        return MemberApprovals[uid];
    }

    /**
     * @dev editBackup - Function to edit individual backup approvals
     * @param approvalId_ uint256 id to lookup Approval and edit
     * @param _contractAddress address contractAddress of asset to save
     * @param _tokenIds uint256 tokenId of asset
     * @param _tokenAmount uint256 amount of specific token
     * @param _tokenType string type of the token i.e. ERC20 | ERC721 | ERC1155
     * @param _uid string of identifier for user in dApp
     *
     */
    function editBackUp(
        uint256 approvalId_,
        address _contractAddress,
        uint256 _tokenIds,
        uint256 _tokenAmount,
        string calldata _tokenType,
        string calldata _uid
    ) external {
        member memory _member = getMember(_uid);
        checkUIDofSender(_uid, msg.sender);

        BackUpApprovals[] storage _approvals = MemberApprovals[_member.uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            BackUpApprovals storage _userApprovals = _approvals[i];
            if (_userApprovals.approvalId == approvalId_) {
                _userApprovals.token.tokenAddress = _contractAddress;
                _userApprovals.token.tokenId = _tokenIds;
                _userApprovals.token.tokensAllocated = _tokenAmount;
                _userApprovals.token.tokenType = _tokenType;
            }
        }
    }

    /**
     * @dev editAllBackUp - Function to delete and add new approvals for backup
     * @param _contractAddress address[] Ordered list of addresses for asset contracts
     * @param _tokenIds uint256[] Ordered list of tokenIds to backup
     * @param _backUpWallets address[] Ordered list of wallets that can be backups
     * @param _tokenAmount uint256[] Ordered list of amounts of tokens to backup
     * @param _tokenTypes string[] Ordered list of string tokenTypes i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string of identifier for user in dApp
     *
     *
     */
    function editAllBackUp(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) external {
        checkUIDofSender(_memberUID, msg.sender);
        deleteAllBackUp(_memberUID);

        storeBackupAssetsApprovals(_contractAddress, _tokenIds, _backUpWallets, _tokenAmount, _tokenTypes, _memberUID);
    }

    /**
     * @dev deleteAllBackUp - Function to delete all backup approvals
     * @param _uid string of identifier for user in dApp
     *
     */
    function deleteAllBackUp(string calldata _uid) public {
        checkUIDofSender(_uid, tx.origin);
        member memory _member = getMember(_uid);
        delete MemberApprovals[_member.uid];
    }

    /**
     * @notice Function to check if backup wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _backup address of the wallet checking exists
     * Fails if not owner uid and backup address do not return a wallet
     *
     */
    function checkBackupandSenderofUID(string memory _uid, address _backup) public view {
        address[] memory wallets = members[_uid].wallets;
        bool walletExists = false;
        for (uint256 i; i < wallets.length; i++) {
            if (wallets[i] == _backup) {
                walletExists = true;
            }
        }
        address[] memory backupwallets = members[_uid].backUpWallets;
        for (uint256 i; i < backupwallets.length; i++) {
            if (backupwallets[i] == _backup) {
                walletExists = true;
            }
        }

        if (walletExists == false) {
            revert UserDoesNotExist();
        }
    }

    /**
     * @dev Function to get blacklisted addresses
     * @return blackListAddresses address[]
     *
     */
    function getBlacklistedAddresses() external view returns (address[] memory) {
        return blackListAddresses;
    }

    /**
     * @dev checkIfAddressIsBlacklisted
     * @param _user address of wallet to check is blacklisted
     *
     */
    function checkIfAddressIsBlacklisted(address _user) public view {
        for (uint256 i = 0; i < blackListAddresses.length; i++) {
            if (blackListAddresses[i] == _user) {
                revert UserBlacklisted();
            }
        }
    }

    /**
     * @dev Function to add new wallet to blacklist
     * @param _user address of new blacklisted wallet
     *
     */
    function addBlacklist(address _user) external onlyOwner {
        blackListAddresses.push(_user);
    }

    /**
     * @dev Function to remove blacklist
     * @param _user address of user to remove from the list
     *
     */
    function removeBlacklist(address _user) external onlyOwner {
        for (uint256 i; i < blackListAddresses.length; i++) {
            if (blackListAddresses[i] == _user) {
                blackListAddresses[i] = blackListAddresses[blackListAddresses.length - 1];
                blackListAddresses.pop();
                break;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IProtocolDirectory.sol";

/**
 * @title ProtocolDirectory
 *
 * This contract will serve as the global store of
 * addresses related to the Webacy smart contract suite.
 * With this Directory we can upgrade/change references to contracts
 * and ensure the rest of the suite will be upgraded at the same time.
 *
 *
 */

contract ProtocolDirectory is
    Initializable,
    OwnableUpgradeable,
    IProtocolDirectory
{
    mapping(bytes32 => address) private _addresses;

    bytes32 private constant ASSET_STORE_FACTORY = "ASSET_STORE_FACTORY";
    bytes32 private constant RELAYER_CONTRACT = "RELAYER_CONTRACT";
    bytes32 private constant MEMBER_CONTRACT = "MEMBER_CONTRACT";
    bytes32 private constant TRANSFER_POOL = "TRANSFER_POOL";

    /**
     * @notice initialize function
     *
     * Keeping within the design pattern of the rest of the protocol
     * this contract will also be upgradable and initializable
     *
     */
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init();
    }

    /**
     * @notice getAddress
     * @param _contractName string representing the contract you are looking for
     *
     * Use this function to get the locations of the deployed addresses;
     */
    function getAddress(bytes32 _contractName) public view returns (address) {
        return _addresses[_contractName];
    }

    /**
     * @notice setAddress
     * @param _contractName bytes32 name to lookup the contract
     * @param _contractLocation address of the deployment being referenced
     *
     *
     */
    function setAddress(
        bytes32 _contractName,
        address _contractLocation
    ) public onlyOwner returns (address) {
        _addresses[_contractName] = _contractLocation;
        return _contractLocation;
    }

    //////////////////////////
    //////Get Functions//////
    /////////////////////////

    /**
     * @notice AssetStoreFactory
     * @return address of protocol contract matching ASSET_STORE_FACTORY value
     *
     */
    function getAssetStoreFactory() external view returns (address) {
        return getAddress(ASSET_STORE_FACTORY);
    }

    /**
     * @notice getRelayerContract
     * @return address of protocol contract matching RELAYER_CONTRACT value
     *
     */
    function getRelayerContract() external view returns (address) {
        return getAddress(RELAYER_CONTRACT);
    }

    /**
     * @notice getMemberContract
     * @return address of protocol contract matching MEMBER_CONTRACT value
     *
     */
    function getMemberContract() external view returns (address) {
        return getAddress(MEMBER_CONTRACT);
    }

    /**
     * @notice getTransferPool
     * @return address of protocol contract matching TRANSFER_POOL value
     *
     */
    function getTransferPool() external view returns (address) {
        return getAddress(TRANSFER_POOL);
    }

    //////////////////////////
    //////Set Functions//////
    /////////////////////////

    /**
     * @dev setAssetStoreFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setAssetStoreFactory(
        address _contractLocation
    ) external onlyOwner returns (address) {
        return setAddress(ASSET_STORE_FACTORY, _contractLocation);
    }

    /**
     * @dev setRelayerContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setRelayerContract(
        address _contractLocation
    ) external onlyOwner returns (address) {
        return setAddress(RELAYER_CONTRACT, _contractLocation);
    }

    /**
     * @dev setMemberContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setMemberContract(
        address _contractLocation
    ) external onlyOwner returns (address) {
        return setAddress(MEMBER_CONTRACT, _contractLocation);
    }

    /**
     * @dev setTransferPool
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setTransferPool(
        address _contractLocation
    ) external onlyOwner returns (address) {
        return setAddress(TRANSFER_POOL, _contractLocation);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./structs/ApprovalsStruct.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IProtocolDirectory.sol";

// Errors
error RelayerOnly(); // Only Relayer is authorized to perform this function

/**
 * @title RelayerContract
 *
 * Logic for communicatiing with the relayer and contract state
 *
 */

contract RelayerContract is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev address of the relayer account
    address public relayerAddress;

    /// @dev address ProtocolDirectory location
    address public directoryContract;

    /**
     * @notice onlyRelayer
     * modifier to ensure only the relayer account can make changes
     *
     */
    modifier onlyRelayer() {
        if (msg.sender != relayerAddress) {
            revert RelayerOnly();
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the directory contract
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();

        directoryContract = _directoryContract;
    }

    /**
     * @dev Set Approval Active for a Specific UID
     * @param _uid string identifier of a user on the dApp
     * This function is called by the predetermined relayer account
     * to trigger that a user's will claim period is now active
     *
     */
    function setApprovalActiveForUID(string memory _uid) external onlyRelayer {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_uid);
        IAssetStore(usersAssetStoreAddress).setApprovalActive(_uid);
    }

    /**
     * @dev transferUnclaimedAssets
     * @param _userUID string identifier of a user across the dApp
     * Triggered by the relayer once it is too late for the beneficiaries to claim
     *
     */
    function transferUnclaimedAssets(
        string memory _userUID
    ) external onlyRelayer {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        IAssetStore(usersAssetStoreAddress).transferUnclaimedAssets(_userUID);
    }

    /**
     * @dev setRelayerAddress
     * @param _relayerAddress the new address of the relayerAccount
     * Update the relayerAccount by the owner as needed
     *
     */
    function setRelayerAddress(address _relayerAddress) external onlyOwner {
        relayerAddress = _relayerAddress;
    }

    /**
     * @dev triggerAssetsForCharity
     * since charities cannot claim assets, the relayer will
     * call this function which will allocate assets per the user's
     * will
     * @param _userUID of the user on the dApp
     *
     */
    function triggerAssetsForCharity(
        string memory _userUID
    ) external onlyRelayer {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        Approvals[] memory userApprovals = IAssetStore(usersAssetStoreAddress)
            .getApprovals(_userUID);

        for (uint256 i = 0; i < userApprovals.length; i++) {
            if (userApprovals[i].beneficiary.isCharity) {
                IAssetStore(usersAssetStoreAddress).sendAssetsToCharity(
                    userApprovals[i].beneficiary.beneficiaryAddress,
                    _userUID
                );
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MemberStruct.sol";
import "./TokenStruct.sol";
import "./BeneficiaryStruct.sol";

/**
 * @dev Approvals Struct
 * @param Member member struct with information on the user
 * @param approvedWallet address of wallet approved
 * @param beneficiary Beneficiary struct holding recipient info
 * @param token Token struct holding specific info on the asset
 * @param dateApproved uint256 timestamp of the approval creation
 * @param claimed bool representing status if asset was claimed
 * @param active bool representing if the claim period has begun
 * @param approvalId uint256 id of the specific approval in the assetstore
 * @param claimExpiryTime uint256 timestamp of when claim period ends
 * @param approvedTokenAmount uint256 magnitude of tokens to claim by this approval
 *
 */
struct Approvals {
    Beneficiary beneficiary;
    Token token;
    uint256 dateApproved;
    address approvedWallet;
    bool claimed;
    bool active;
    uint88 approvalId;
    uint256 claimExpiryTime;
    uint256 approvedTokenAmount;
    string _uid;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MemberStruct.sol";
import "./TokenStruct.sol";
import "./BeneficiaryStruct.sol";

/**
 * @dev BackUpApprovals struct
 *
 * @param Member member struct of information for the user
 * @param approvedWallet address wallet approving the assets
 * @param backUpWallet address[] wallet approved to recieve assets
 * @param token Token struct with information about the asset backed up
 * @param dateApproved uint256 timestamp of when the approval came in
 * @param claimed bool status of the approval if it was claimed
 * @param approvalId uint256 id of the specific approval for this asset
 */
struct BackUpApprovals {
    address[] backUpWallet;
    address approvedWallet;
    bool claimed;
    uint88 approvalId;
    Token token;
    uint256 dateApproved;
    string _uid;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Structure to store different types of Beneficiary
 * (ERC721, ERC1155, ERC20)
 * @param beneficiaryAddress address for assets to go to
 * @param beneficiaryName name of entity recieveing the assets
 * @param isCharity boolean representing if Beneficiary is a charity
 * because charities will be a recieve only address and cannot be
 * expected to call a function to claim assets
 *
 */
struct Beneficiary {
    address beneficiaryAddress;
    bool isCharity;
    string beneficiaryName;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Member Structure stores all member information
 * @param uid string For storing UID that cross references UID from DB for loading off-chain data
 * @param dateCreated uint256 timestamp of creation of User
 * @param wallets address[] Maintains an array of backUpWallets of the User
 * @param primaryWallet uint256 index of where in the wallets array the primary wallet exists
 */
struct member {
    uint256 dateCreated;
    address[] wallets;
    address[] backUpWallets;
    uint256 primaryWallet;
    string uid;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Token struct
 *
 * @param tokenId uint256 specific tokenId for the asset
 * @param tokenAddress address of the contract for this asset
 * @param tokenType string representing asset type i.e. ERC721 | ERC20 | ERC1155
 * @param tokensAllocated uint256 number representing how many tokens as a %'s to
 * attach to a given approval or other directive
 */
struct Token {
    address tokenAddress;
    uint256 tokenId;
    uint256 tokensAllocated;
    string tokenType;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title WebacyToken
 * Reference ERC1155 token for testing purposes
 * with easy method for creating many tokenIds
 * 
 */
contract Webacy1155 is ERC1155 {
    uint256 public tokenID = 0;
    mapping(uint256 => uint256) public existence;
    string public symbol;

    constructor(string memory _symbol)
        ERC1155("https://webacy.example/api/item/{id}.json")
    {
        symbol = _symbol;
    }

    function selfMint(uint256 _amount) external {
        privateMint(_amount, msg.sender);
    }

    function publicMint(uint256 _amount, address _address) external {
        privateMint(_amount, _address);
    }

    function privateMint(uint256 _amount, address _address) private {
        _mint(_address, tokenID, _amount, "");
        existence[tokenID] = _amount;
        tokenID++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title WebacyToken
 * Reference erc20 token for testing purposes
 */
contract WebacyToken is ERC20 {
    constructor(
        uint256 initialSupply,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title WebacyToken
 * Reference ERC721 token for testing purposes
 */
contract WebacyNFT is ERC721 {
    mapping(string => uint8) public hashes;
    uint256 _tokenIds = 0;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(address recipient, string memory hash)
        public
        returns (uint256)
    {
        require(hashes[hash] != 1, "Hash already minted");

        hashes[hash] = 1;

        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);

        _tokenIds++;

        return newItemId;
    }
}

contract Webacy2NFT is ERC721 {
    mapping(string => uint8) public hashes;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(address recipient, uint256 _tokenId)
        public
        returns (uint256)
    {
        uint256 newItemId = _tokenId;
        _mint(recipient, newItemId);

        return newItemId;
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/utils/Strings.sol
/**
 * @dev String operations.
 */
library Strings {
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






// File: @openzeppelin/contracts/utils/Context.sol
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





// File: @openzeppelin/contracts/utils/Address.sol
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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





// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}





// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
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





// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
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





// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}





// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}





// File: @openzeppelin/contracts/token/ERC721/ERC721.sol
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}





// File: contracts/interfaces/IERC20.sol
interface IERC20 {
  /// @notice ERC0 transfer tokens
  function transfer(address recipient, uint256 amount) external returns (bool);
  /// @notice ERC20 balance of address
  function balanceOf(address account) external view returns (uint256);
}





// File: contracts/MultiFaucet.sol
/// @title MultiFaucet
/// @author Anish Agnihotri
/// @notice Drips ETH, DAI, wETH, and mints NFTs
contract MultiFaucet is ERC721 {

    /// ============ Immutable storage ============

    /// @notice DAI ERC20 token
    IERC20 public immutable DAI;
    /// @notice wETH ERC20 token
    IERC20 public immutable WETH;

    /// ============ Mutable storage ============

    /// @notice Default NFT uri
    string public URI;
    /// @notice Count of minted NFTs
    uint256 public nftsMinted;
    /// @notice Number of ERC721 NFTs to mint
    uint256 public NFT_COUNT = 5;
    /// @notice ETH to disperse
    uint256 public ETH_AMOUNT = 5e18;
    /// @notice DAI to disperse
    uint256 public DAI_AMOUNT = 5_000e18;
    /// @notice wETH to disperse
    uint256 public WETH_AMOUNT = 5e18;
    /// @notice Addresses of approved operators
    mapping(address => bool) public approvedOperators;
    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    /// ============ Modifiers ============

    /// @notice Requires sender to be contract super operator
    modifier isSuperOperator() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }

    /// @notice Requires sender to be contract approved operator
    modifier isApprovedOperator() {
        // Ensure sender is in approved operators or is super operator
        require(
            approvedOperators[msg.sender] || superOperators[msg.sender], 
            "Not approved operator"
        );
        _;
    }

    /// ============ Events ============

    /// @notice Emitted after faucet drips to a recipient
    /// @param recipient address dripped to
    event FaucetDripped(address indexed recipient);

    /// @notice Emitted after faucet drained to a recipient
    /// @param recipient address drained to
    event FaucetDrained(address indexed recipient);

    /// @notice Emitted after operator status is updated
    /// @param operator address being updated
    /// @param status new operator status
    event OperatorUpdated(address indexed operator, bool status);

    /// @notice Emitted after super operator is updated
    /// @param operator address being updated
    /// @param status new operator status
    event SuperOperatorUpdated(address indexed operator, bool status);

    /// ============ Constructor ============

    /// @notice Creates a new MultiFaucet contract
    /// @param _DAI address of DAI contract
    /// @param _WETH address of wETH contract
    /// @param _URI string of token URI
    constructor(address _DAI, address _WETH, string memory _URI) 
        ERC721("MultiFaucet NFT", "MFNFT") 
    {
        DAI = IERC20(_DAI);
        WETH = IERC20(_WETH);
        URI = _URI;
        superOperators[msg.sender] = true;
    }

    /// ============ Functions ============

    /// @notice Drips and mints tokens to recipient
    /// @param _recipient to drip tokens to
    function drip(address _recipient) external isApprovedOperator {
        // Drip Ether
        (bool sent,) = _recipient.call{value: ETH_AMOUNT}("");
        require(sent, "Failed dripping ETH");

        // Drip DAI
        require(DAI.transfer(_recipient, DAI_AMOUNT), "Failed dripping DAI");

        // Drip wETH
        require(WETH.transfer(_recipient, WETH_AMOUNT), "Failed dripping wETH");

        // Mint NFTs
        for (uint256 i = 1; i <= NFT_COUNT; i++) {
            _mint(_recipient, nftsMinted + i);
        }
        nftsMinted += NFT_COUNT;

        emit FaucetDripped(_recipient);
    }

    /// @notice Returns number of available drips by token
    /// @return ethDrips — available Ether drips
    /// @return daiDrips — available DAI drips
    /// @return wethDrips — available wETH drips
    function availableDrips() public view 
        returns (uint256 ethDrips, uint256 daiDrips, uint256 wethDrips) 
    {
        ethDrips = address(this).balance / ETH_AMOUNT;
        daiDrips = DAI.balanceOf(address(this)) / DAI_AMOUNT;
        wethDrips = WETH.balanceOf(address(this)) / WETH_AMOUNT;
    }

    /// @notice Allows super operator to drain contract of tokens
    /// @param _recipient to send drained tokens to
    function drain(address _recipient) external isSuperOperator {
        // Drain all Ether
        (bool sent,) = _recipient.call{value: address(this).balance}("");
        require(sent, "Failed draining ETH");

        // Drain all DAI
        uint256 daiBalance = DAI.balanceOf(address(this));
        require(DAI.transfer(_recipient, daiBalance), "Failed draining DAI");

        // Drain all wETH
        uint256 wethBalance = WETH.balanceOf(address(this));
        require(WETH.transfer(_recipient, wethBalance), "Failed dripping wETH");

        emit FaucetDrained(_recipient);
    }

    /// @notice Allows super operator to update approved drip operator status
    /// @param _operator address to update
    /// @param _status of operator to toggle (true == allowed to drip)
    function updateApprovedOperator(address _operator, bool _status) 
        external 
        isSuperOperator 
    {
        approvedOperators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    /// @notice Allows super operator to update super operator
    /// @param _operator address to update
    /// @param _status of operator to toggle (true === is super operator)
    function updateSuperOperator(address _operator, bool _status) 
        external
        isSuperOperator
    {
        superOperators[_operator] = _status;
        emit SuperOperatorUpdated(_operator, _status);
    }

    /// @notice Override internal ERC721 function to return single image per NFT
    /// @param tokenId of ERC721 NFT
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // OpenZeppelin check: ensure token exists
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return URI;
    }

    /// @notice Allows super operator to update NFT uri
    /// @param _URI of collection
    function updateTokenURI(string memory _URI) external isSuperOperator {
        URI = _URI;
    }

    /// @notice Allows super operator to update drip amounts
    /// @param _nftCount number of NFTs to mint per drip
    /// @param _ethAmount ETH to drip
    /// @param _daiAmount DAI to drip
    /// @param _wethAmount wETH to drip
    function updateDripAmounts(
        uint256 _nftCount, 
        uint256 _ethAmount,
        uint256 _daiAmount,
        uint256 _wethAmount
    ) external isSuperOperator {
        NFT_COUNT = _nftCount;
        ETH_AMOUNT = _ethAmount;
        DAI_AMOUNT = _daiAmount;
        WETH_AMOUNT = _wethAmount;
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}