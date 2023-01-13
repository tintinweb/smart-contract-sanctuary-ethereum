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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// @author st4rgard3n, bitbeckers, MrDeadce11, huntrr / Raid Guild
pragma solidity ^0.8.13;

contract InitializationData {
    // object is used to initialize new cohorts

    // PARAMS:
    // membershipCriteria_ (Moloch DAO address) the contract address read from in order to ascertain cohort completion
    // stakingAsset_ (tokenAddress) the contract address for the asset which is staked into the cohort contract
    // treasury_ the address which receives tokens when initiates are slashed (e.g. Gnosis safe, smart contract, etc.)
    // topHatWearer_ [OPTIONAL] address of topHat (DAO address that wears topHat)
    // admin1_ [OPTIONAL] address of cohort admin
    // admin2_ [OPTIONAL] address of cohort admin
    // cohortSize_ the limit of cohort attendees that can join/stake
    // joinDuration_ the time limit for cohort attendees to join/stake
    // threshold_ (shares in DAO) the minimum amount of criteria which constitutes membership
    // assetAmount_ (staking amount) the minimum amount of staking asset required to join the cohort
    // stakeDuration_ the time limit beginning from time of stake for cohort attendee to achieve DAO membership
    // topHatId_ [OPTIONAL] topHat ID of topHatWearer
    // cohortName_ name of cohort
    // stbName_ the name for the cohort's soul bound tokens (SBT)
    // sbtSymbol_ the ticker symbol for cohort's SBT
    // baseURI_ the uniform resource identifier for accessing SBT metadata

    struct InitData {
        address membershipCriteria;
        address stakingAsset;
        address treasury;
        address topHatWearer;
        address admin1;
        address admin2;
        uint256 cohortSize;
        uint256 joinDuration;
        uint256 threshold;
        uint256 assetAmount;
        uint256 stakeDuration;
        uint256 topHatId;
        string cohortName;
        string sbtName;
        string sbtSymbol;
        string baseUri;
    }
}

// SPDX-License-Identifier: MIT
// @author st4rgard3n, bitbeckers, MrDeadce11, huntrr / Raid Guild
pragma solidity ^0.8.4;

import "lib/openzeppelin-contracts-upgradeable/contracts/utils/CountersUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "./InitializationData.sol";
import "src/hats/HatsAccessControl.sol";
import {IHats} from "src/hats/IHats.sol";

interface MolochDAO {
    struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated
        uint256 shares; // the # of voting shares assigned to this member
        uint256 loot; // the loot amount available to this member (combined with shares on ragequit)
        bool exists; // always true once a member has been created
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES
        uint256 jailed; // set to proposalIndex of a passing guild kick proposal for this member, prevents voting on and sponsoring proposals
    }

    function members(address memberAddress)
        external
        view
        returns (Member calldata member);
}

interface Token {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract RiteOfMoloch is
    InitializationData,
    ERC721Upgradeable,
    HatsAccessControl
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(bytes32 => RoleData) public _roles;

    // role constants
    bytes32 public constant SUPER_ADMIN = keccak256("SUPER_ADMIN");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /*************************
     MAPPING STRUCTS EVENTS
     *************************/

    // logs new initiation data
    event Initiation(
        address newInitiate,
        address benefactor,
        uint256 tokenId,
        uint256 stake,
        uint256 deadline
    );

    // logs data when failed initiates get slashed
    event Sacrifice(address sacrifice, uint256 slashedAmount, address slasher);

    // logs data when a user successfully claims back their stake
    event Claim(address newMember, uint256 claimAmount);

    // log the new staking requirement
    event ChangedStake(uint256 newStake);

    // log the new minimum shares for DAO membership
    event ChangedShares(uint256 newShare);

    // log the new duration before an initiate can be slashed
    event ChangedTime(uint256 newTime);

    // log feedback data on chain for aggregation and graph
    event Feedback(address user, address treasury, string feedback);

    // initiation participant token balances
    mapping(address => uint256) internal _staked;

    // the time a participant joined the initiation
    mapping(address => uint256) public deadlines;

    // the number of user's a member has sacrificed
    mapping(address => uint256) public totalSlash;

    /*************************
     STATE VARIABLES
     *************************/

    CountersUpgradeable.Counter internal _tokenIdCounter;

    MolochDAO public dao;

    Token private _token;

    // cohort's base URI for accessing token metadata
    string internal __baseURI;

    // cohort name
    string public cohortName;

    // cohort join count
    uint256 public cohortCount;

    // cohort size limit
    uint256 public cohortSize;

    // cohort join time limit
    uint256 public joinEndTime;

    // minimum amount of dao shares required to be considered a member
    uint256 public minimumShare;

    // minimum amount of staked tokens required to join the initiation
    uint256 public minimumStake;

    // maximum length of time for initiates to succeed at joining
    uint256 public maximumTime;

    // DAO treasury address
    address public treasury;

    // Hats protocol:
    IHats public HATS;

    // Hats
    uint256 public topHat;
    uint256 public superAdminHat;
    uint256 public adminHat;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Deploys a new clone proxy instance for cohort staking
     * @param initData the complete initialization data
     * @param caller_ the deployer of the new cohort clone
     */
    function initialize(
        InitData calldata initData,
        address hatsProtocol,
        address caller_
    ) external initializer {
        // increment the counter so our first sbt has token id of one
        _tokenIdCounter.increment();

        // set cohort name
        cohortName = initData.cohortName;

        // set size limit on cohort
        cohortSize = initData.cohortSize;

        // set join time limit
        joinEndTime = block.timestamp + initData.joinDuration;

        // initialize the SBT
        __ERC721_init(initData.sbtName, initData.sbtSymbol);

        // set the interface for accessing the DAO's public members mapping
        dao = MolochDAO(initData.membershipCriteria);

        // store the treasury daoAddress
        treasury = initData.treasury;

        // set the interface for accessing the required staking token
        _token = Token(initData.stakingAsset);

        // set the minimum shares
        minimumShare = initData.threshold;

        // point to Hats Protocol
        HATS = IHats(hatsProtocol);

        // point access control functionality to Hats protocol
        _changeHatsContract(hatsProtocol);

        // create/mint Hats
        if (
            initData.topHatWearer != address(0) &&
            initData.topHatId != 0 &&
            HATS.isWearerOfHat(initData.topHatWearer, initData.topHatId)
        ) {
            // todo: add logic for existing topHat

            return;
        } else {
            _buildNewHatTree(caller_, initData.admin1, initData.admin2);
        }

        // set the minimum stake requirement
        _setMinimumStake(initData.assetAmount);

        // set the cohort staking duration
        _setMaxDuration(initData.stakeDuration);

        // set the cohort token's base uri
        _setBaseUri(initData.baseUri);
    }

    /*************************
     MODIFIERS
     *************************/

    /**
     * @dev Modifier for preventing calls from contracts
     * Safety feature for preventing malicious contract call backs
     */
    modifier callerIsUser() {
        // for testing in Forge: disable
        require(tx.origin == msg.sender, "The caller is another contract!");
        _;
    }

    /**
     * @dev Modifier for enforcing function callable from DAO members only
     * Allows decentralized control by DAO members
     */
    modifier onlyMember() {
        _checkMember();
        _;
    }

    /*************************
     USER FUNCTIONS
     *************************/

    /**
     * @dev Allows users to join the DAO initiation
     * @param user the address which will be activated for the cohort
     * Stakes required tokens and mints soul bound token
     */
    function joinInitiation(address user) public callerIsUser {
        // enforce time and size contraints
        require(block.timestamp <= joinEndTime, "This cohort is now closed");
        require(cohortCount <= cohortSize, "This cohort is already full");

        // enforce the initiate or sponsor transfers correct tokens to the contract
        require(_stake(user), "Staking failed!");

        // account for new cohort attendee
        cohortCount++;

        // issue a soul bound token
        _soulBind(user);
    }

    /**
     * @dev Allows DAO members to claim their initiation stake
     */
    function claimStake() external onlyMember {
        require(_claim(), "Claim failed!");
    }

    /**
     * @dev Allows initiates to log permanent feedback data on-chain
     * @param feedback "Developers do something!"
     * Doesn't change contract state; simply passes call-data through an event
     */
    function cryForHelp(string calldata feedback) public {
        require(balanceOf(msg.sender) == 1, "Only cohort participants!");

        emit Feedback(msg.sender, treasury, feedback);
    }

    /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

    /**
     * @dev Claims the life force of failed initiates for the dao
     * @param failedInitiates an array of user's who have failed to join the DAO
     */
    function sacrifice(address[] calldata failedInitiates)
        public
        onlyRole(ADMIN)
    {
        _darkRitual(failedInitiates);
    }

    /**
     * @dev Allows DAO members to change the staking requirement
     * @param newMinimumStake the minimum quantity of tokens a user must stake to join the cohort
     */
    function setMinimumStake(uint256 newMinimumStake) external onlyRole(ADMIN) {
        _setMinimumStake(newMinimumStake);
    }

    /**
     * @dev Allows changing the DAO member share threshold
     * @param newShareThreshold the number of shares required to be considered a DAO member
     */
    function setShareThreshold(uint256 newShareThreshold)
        external
        onlyRole(ADMIN)
    {
        // enforce that the minimum share threshold isn't zero
        require(
            newShareThreshold > 0,
            "Minimum shares must be greater than zero!"
        );

        // set the minimum number of DAO shares required to graduate
        minimumShare = newShareThreshold;

        // log data for the new minimum share threshold
        emit ChangedShares(newShareThreshold);
    }

    /**
     * @dev Allows changing the maximum initiation duration
     * @param newMaxTime the length in seconds until an initiate's stake is forfeit
     */
    function setMaxDuration(uint256 newMaxTime) external onlyRole(SUPER_ADMIN) {
        _setMaxDuration(newMaxTime);
    }

    function changeJoinSizeLimit(uint256 _cohortSize)
        external
        onlyRole(SUPER_ADMIN)
    {
        cohortSize = _cohortSize;
    }

    function extendJoinTimeLimit(uint256 _extension)
        external
        onlyRole(SUPER_ADMIN)
    {
        joinEndTime = joinEndTime + _extension;
    }

    /*************************
     PRIVATE OR INTERNAL
     *************************/

    function _setMinimumStake(uint256 newMinimumStake) internal {
        // enforce that the minimum stake isn't zero
        require(
            newMinimumStake > 0,
            "Minimum stake must be greater than zero!"
        );

        // set the minimum staking requirement
        minimumStake = newMinimumStake;

        //  new staking requirement data
        emit ChangedStake(newMinimumStake);
    }

    function _setMaxDuration(uint256 newMaxTime) internal virtual {
        // enforce that the minimum time is greater than 1 week
        require(newMaxTime > 0, "Minimum duration must be greater than 0!");

        // set the maximum length of time for initiations
        maximumTime = newMaxTime;

        // log the new duration before stakes can be slashed
        emit ChangedTime(newMaxTime);
    }

    /**
     * @dev Sets base URI during initialization
     * @param baseURI the base uri for accessing token metadata
     */
    function _setBaseUri(string calldata baseURI) internal virtual {
        __baseURI = baseURI;
    }

    /**
     * @dev Stakes the user's tokens
     * @param _user the address to activate for the cohort
     */
    function _stake(address _user) internal virtual returns (bool) {
        // enforce that the initiate hasn't previously staked
        require(balanceOf(_user) == 0, "Already joined the initiation!");

        // change the initiate's stake total
        _staked[_user] = minimumStake;

        // set the initiate's deadline
        deadlines[_user] = block.timestamp + maximumTime;

        return _token.transferFrom(msg.sender, address(this), minimumStake);
    }

    /**
     * @dev Claims the successful new members stake
     */
    function _claim() internal virtual returns (bool) {
        address msgSender = msg.sender;
        // enforce that the initiate has stake
        require(_staked[msgSender] > 0, "User has no stake!!");

        // store the user's balance
        uint256 balance = _staked[msgSender];

        // delete the balance
        delete _staked[msgSender];

        // delete the deadline timestamp
        delete deadlines[msgSender];

        // log data for this successful claim
        emit Claim(msgSender, balance);

        // return the new member's original stake
        return _token.transfer(msgSender, balance);
    }

    /**
     * @dev Mints soul bound tokens to the initiate
     * @param _user the recipient of the cohort SBT
     */
    function _soulBind(address _user) internal virtual {
        // store the current token counter
        uint256 tokenId = _tokenIdCounter.current();

        // log the initiation data
        emit Initiation(
            _user,
            msg.sender,
            tokenId,
            minimumStake,
            deadlines[_user]
        );

        // increment the token counter
        _tokenIdCounter.increment();

        // mint the user's soul bound initiation token
        _mint(_user, tokenId);
    }

    /**
     * @dev Claims failed initiate tokens for the DAO
     * @param _failedInitiates an array of user's who have failed to join the DAO
     */
    function _darkRitual(address[] calldata _failedInitiates) internal virtual {
        // the total amount of blood debt
        uint256 total;

        for (uint256 i = 0; i < _failedInitiates.length; ++i) {
            // store each initiate's address
            address initiate = _failedInitiates[i];

            // access each initiate's starting time
            uint256 deadline = deadlines[initiate];

            if (block.timestamp > deadline && _staked[initiate] > 0) {
                // access each initiate's balance
                uint256 balance = _staked[initiate];

                // calculate the total blood debt
                total += balance;

                // log sacrifice data
                emit Sacrifice(initiate, balance, msg.sender);

                // remove the sacrifice's balance
                delete _staked[initiate];

                // remove the sacrifice's starting time
                delete deadlines[initiate];
            } else {
                continue;
            }
        }

        // drain the life force from the sacrifice
        require(_token.transfer(treasury, total), "Failed Sacrifice!");

        // increase the slasher's essence
        totalSlash[msg.sender] += total;
    }

    /**
     * @dev Authenticates users through the DAO contract
     */
    function _checkMember() internal virtual {
        // access membership data from the DAO
        MolochDAO.Member memory member = dao.members(msg.sender);

        // access the user's total shares
        uint256 shares = member.shares;

        // enforce that the user is a member
        require(shares >= minimumShare, "You must be a member!");
    }

    /**
     * @dev Creates a new topHat, build Access Control tree,
     * and transfers topHat to DAO
     */
    function _buildNewHatTree(
        address _deployer,
        address _admin1,
        address _admin2
    ) internal virtual {
        topHat = HATS.mintTopHat(address(this), "ROM TopHat", "");

        // super-admin privileges: grant/revoke other admin, access control
        superAdminHat = HATS.createHat(
            topHat,
            "ROM Super-Admin",
            1,
            address(dao),
            address(dao),
            true,
            ""
        );

        // admin privileges: access control
        // 1 hat for address(this) + additional hats for number of admin
        adminHat = HATS.createHat(
            superAdminHat,
            "ROM Admin",
            3,
            _deployer,
            _deployer,
            true,
            ""
        );

        /**
         * @dev Mint superAdmin & admin hats to Deployer
         * DAO can grant/revoke superAdmin (after topHat is transferred below)
         * Deployer can grant/revoke other admin
         */
        HATS.mintHat(superAdminHat, _deployer);
        HATS.mintHat(adminHat, _deployer);

        if (_admin1 != address(0)) {
            HATS.mintHat(adminHat, _admin1);
        }
        if (_admin2 != address(0)) {
            HATS.mintHat(adminHat, _admin2);
        }

        // grant Hat Access Control roles
        _grantRole(SUPER_ADMIN, superAdminHat);
        _grantRole(ADMIN, adminHat);

        HATS.transferHat(topHat, address(this), address(dao));
    }

    /*************************
     VIEW AND PURE FUNCTIONS
     *************************/

    /**
     * @dev returns the user's deadline for onboarding
     */
    function getDeadline(address user) public view returns (uint256 deadline) {
        return deadlines[user];
    }

    /**
     * @dev returns the user's member status
     */
    function isMember(address user) public view returns (bool memberStatus) {
        // access membership data from the DAO
        MolochDAO.Member memory member = dao.members(user);

        // access the user's total shares
        uint256 shares = member.shares;

        if (shares >= minimumShare) {
            return true;
        } else {
            return false;
        }
    }

    /*************************
     OVERRIDES
     *************************/

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    // Cohort NFTs cannot be transferred
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        revert();
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol";
import "./IHats.sol";

/**
 * @notice forked from OpeZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol)
 * @author Hats Protocol
 * @dev Contract module that allows children to implement role-based access
 */
abstract contract HatsAccessControl is ContextUpgradeable {
    error NotWearingRoleHat(bytes32 role, uint256 hat, address account);

    error RoleAlreadyAssigned(bytes32 role, uint256 roleHat);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleGranted(
        bytes32 indexed role,
        uint256 indexed hat,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        uint256 indexed hat,
        address indexed sender
    );

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event HatsContractChanged(
        address indexed previousHatsContract,
        address indexed newHatsContract
    );

    event RoleHatChanged(
        bytes32 indexed role,
        uint256 indexed previousRoleHat,
        uint256 indexed newRoleHat
    );

    struct RoleData {
        uint256 hat;
        bytes32 adminRole;
    }

    IHats private HATS;

    mapping(bytes32 => RoleData) private _roles;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`,
     * based on the account wearing the correct hat.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        returns (bool)
    {
        return HATS.isWearerOfHat(account, _roles[role].hat);
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     * Format of the revert message is described in {_checkRole}.
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert NotWearingRoleHat(role, _roles[role].hat, account);
        }
    }

    function hatsContract() public view virtual returns (address) {
        return address(HATS);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `hat`.
     * If `hat` had not been already granted `role`, emits a {RoleGranted} event.
     * Requirements:
     * - the caller must wear ``role``'s hat's admin hat.
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, uint256 hat)
        public
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, hat);
    }

    function changeRoleHat(bytes32 role, uint256 newRoleHat)
        public
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _changeRoleHat(role, newRoleHat);
    }

    /**
     * @dev Revokes `role` from `hat`.
     * If `hat` had been granted `role`, emits a {RoleRevoked} event.
     * Requirements:
     * - the caller must wear ``role``'s hat's admin hat.
     */
    function revokeRole(bytes32 role, uint256 hat)
        public
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, hat);
    }

    /**
     * @dev Points to a new Hats Protocol implementation
     * Emits a {RoleAdminChanged} event.
     */

    /**
     * @dev Points to a new Hats Protocol implementation
     * Only callable by the wearer of the default admin role's hat
     * Emits a {RoleAdminChanged} event.
     */

    function changeHatsContract(address newHatsContract)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _changeHatsContract(newHatsContract);
    }

    function _changeHatsContract(address newHatsContract) internal virtual {
        address previousHatsContract = address(HATS);
        HATS = IHats(newHatsContract);

        emit HatsContractChanged(previousHatsContract, newHatsContract);
    }

    function _changeRoleHat(bytes32 role, uint256 newRoleHat) internal virtual {
        uint256 roleHat = _roles[role].hat;
        if (roleHat == 0) {
            _grantRole(role, newRoleHat);
        }
        if (roleHat != newRoleHat) {
            _roles[role].hat = newRoleHat;
            emit RoleHatChanged(role, roleHat, newRoleHat);
        }
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `hat`.
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, uint256 hat) internal virtual {
        uint256 roleHat = _roles[role].hat;
        if (roleHat > 0) {
            revert RoleAlreadyAssigned(role, roleHat);
        }
        if (roleHat != hat) {
            _roles[role].hat = hat;
            emit RoleGranted(role, hat, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, uint256 hat) internal virtual {
        if (_roles[role].hat == hat) {
            _roles[role].hat = 0;
            emit RoleRevoked(role, hat, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// Interfaces (3)
interface HatsErrors {
    error NotAdmin(address _user, uint256 _hatId);
    error AllHatsWorn(uint256 _hatId);
    error AlreadyWearingHat(address _wearer, uint256 _hatId);
    error HatDoesNotExist(uint256 _hatId);
    error NotEligible(address _wearer, uint256 _hatId);
    error NotHatWearer();
    error NotHatsToggle();
    error NotHatsEligibility();
    error BatchArrayLengthMismatch();
    error MaxLevelsReached();
    error Immutable();
    error NewMaxSupplyTooLow();
}

interface HatsEvents {
    event HatCreated(
        uint256 id,
        string details,
        uint32 maxSupply,
        address eligibility,
        address toggle,
        bool mutable_,
        string imageURI
    );
    event HatStatusChanged(uint256 hatId, bool newStatus);
    event HatDetailsChanged(uint256 hatId, string newDetails);
    event HatEligibilityChanged(uint256 hatId, address newEligibility);
    event HatToggleChanged(uint256 hatId, address newToggle);
    event HatMutabilityChanged(uint256 hatId);
    event HatMaxSupplyChanged(uint256 hatId, uint32 newMaxSupply);
    event HatImageURIChanged(uint256 hatId, string newImageURI);
}

interface IHatsIdUtilities {
    function buildHatId(uint256 _admin, uint8 _newHat)
        external
        pure
        returns (uint256 id);
    function getHatLevel(uint256 _hatId) external pure returns (uint8);
    function isTopHat(uint256 _hatId) external pure returns (bool);
    function getAdminAtLevel(uint256 _hatId, uint8 _level)
        external
        pure
        returns (uint256);
    function getTophatDomain(uint256 _hatId) external pure returns (uint256);
}

/// IHat Contract
interface IHats is IHatsIdUtilities, HatsErrors, HatsEvents {
    function mintTopHat(
        address _target,
        string memory _details,
        string memory _imageURI
    ) external returns (uint256 topHatId);

    function createHat(
        uint256 _admin,
        string memory _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string memory _imageURI
    ) external returns (uint256 newHatId);

    function batchCreateHats(
        uint256[] memory _admins,
        string[] memory _details,
        uint32[] memory _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] memory _mutables,
        string[] memory _imageURIs
    ) external returns (bool);

    function getNextId(uint256 _admin) external view returns (uint256);

    function mintHat(uint256 _hatId, address _wearer) external returns (bool);

    function batchMintHats(uint256[] memory _hatIds, address[] memory _wearers)
        external
        returns (bool);

    function setHatStatus(uint256 _hatId, bool _newStatus)
        external
        returns (bool);

    function checkHatStatus(uint256 _hatId) external returns (bool);

    function setHatWearerStatus(
        uint256 _hatId,
        address _wearer,
        bool _eligible,
        bool _standing
    ) external returns (bool);

    function checkHatWearerStatus(uint256 _hatId, address _wearer)
        external
        returns (bool);

    function renounceHat(uint256 _hatId) external;

    function transferHat(
        uint256 _hatId,
        address _from,
        address _to
    ) external;

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeHatImmutable(uint256 _hatId) external;

    function changeHatDetails(uint256 _hatId, string memory _newDetails)
        external;

    function changeHatEligibility(uint256 _hatId, address _newEligibility)
        external;

    function changeHatToggle(uint256 _hatId, address _newToggle) external;

    function changeHatImageURI(uint256 _hatId, string memory _newImageURI)
        external;

    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external;

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function viewHat(uint256 _hatId)
        external
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint8 lastHatId,
            bool mutable_,
            bool active
        );

    function isWearerOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    function isAdminOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    function isInGoodStanding(address _wearer, uint256 _hatId)
        external
        view
        returns (bool);

    function isEligible(address _wearer, uint256 _hatId)
        external
        view
        returns (bool);

    function getImageURIForHat(uint256 _hatId)
        external
        view
        returns (string memory);

    function balanceOf(address wearer, uint256 hatId)
        external
        view
        returns (uint256 balance);

    function uri(uint256 id) external view returns (string memory);
}