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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
library SafeMath {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
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

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCAMinter.sol";
import "contracts/utils/auth/ImmutableALCABurner.sol";
import "contracts/interfaces/IStakingToken.sol";
import "contracts/libraries/errors/StakingTokenErrors.sol";

/**
 * @notice This is the ERC20 implementation of the staking token used by the
 * AliceNet layer2 dapp.
 *
 */
contract ALCA is IStakingToken, ERC20, ImmutableFactory, ImmutableALCAMinter, ImmutableALCABurner {
    uint256 internal constant _CONVERSION_MULTIPLIER = 15_555_555_555_555_555_555_555_555_555;
    uint256 internal constant _CONVERSION_SCALE = 10_000_000_000_000_000_000_000_000_000;
    uint256 internal constant _INITIAL_MINT_AMOUNT = 244_444_444_444444444444444444;
    address internal immutable _legacyToken;
    bool internal _hasEarlyStageEnded;

    constructor(
        address legacyToken_
    )
        ERC20("AliceNet Staking Token", "ALCA")
        ImmutableFactory(msg.sender)
        ImmutableALCAMinter()
        ImmutableALCABurner()
    {
        _legacyToken = legacyToken_;
        _mint(msg.sender, _INITIAL_MINT_AMOUNT);
    }

    /**
     * Migrates an amount of legacy token (MADToken) to ALCA tokens
     * @param amount the amount of legacy token to migrate.
     */
    function migrate(uint256 amount) public returns (uint256) {
        return _migrate(msg.sender, amount);
    }

    /**
     * Migrates an amount of legacy token (MADToken) to ALCA tokens to a certain address
     * @param to the address that will receive the alca tokens
     * @param amount the amount of legacy token to migrate.
     */
    function migrateTo(address to, uint256 amount) public returns (uint256) {
        if (to == address(0)) {
            revert StakingTokenErrors.InvalidAddress();
        }
        return _migrate(to, amount);
    }

    /**
     * Allow the factory to turns off migration multipliers
     */
    function finishEarlyStage() public onlyFactory {
        _finishEarlyStage();
    }

    /**
     * Mints a certain amount of ALCA to an address. Can only be called by the
     * ALCAMinter role.
     * @param to the address that will receive the minted tokens.
     * @param amount the amount of legacy token to migrate.
     */
    function externalMint(address to, uint256 amount) public onlyALCAMinter {
        _mint(to, amount);
    }

    /**
     * Burns an amount of ALCA from an address. Can only be called by the
     * ALCABurner role.
     * @param from the account to burn the ALCA tokens.
     * @param amount the amount to burn.
     */
    function externalBurn(address from, uint256 amount) public onlyALCABurner {
        _burn(from, amount);
    }

    /**
     * Get the address of the legacy token.
     * @return the address of the legacy token (MADToken).
     */
    function getLegacyTokenAddress() public view returns (address) {
        return _legacyToken;
    }

    /**
     * gets the expected token migration amount
     * @param amount amount of legacy tokens to migrate over
     * @return the amount converted to ALCA*/
    function convert(uint256 amount) public view returns (uint256) {
        return _convert(amount);
    }

    /**
     * returns true if the early stage multiplier is still active
     */
    function isEarlyStageMigration() public view returns (bool) {
        return !_hasEarlyStageEnded;
    }

    function _migrate(address to, uint256 amount) internal returns (uint256 convertedAmount) {
        uint256 balanceBefore = IERC20(_legacyToken).balanceOf(address(this));
        IERC20(_legacyToken).transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(_legacyToken).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) {
            revert StakingTokenErrors.InvalidConversionAmount();
        }
        uint256 balanceDiff = balanceAfter - balanceBefore;
        convertedAmount = _convert(balanceDiff);
        _mint(to, convertedAmount);
    }

    // Internal function to finish the early stage multiplier.
    function _finishEarlyStage() internal {
        _hasEarlyStageEnded = true;
    }

    // Internal function to convert an amount of MADToken to ALCA taking into
    // account the early stage multiplier.
    function _convert(uint256 amount) internal view returns (uint256) {
        if (_hasEarlyStageEnded) {
            return amount;
        } else {
            return _multiplyTokens(amount);
        }
    }

    // Internal function to compute the amount of ALCA in the early stage.
    function _multiplyTokens(uint256 amount) internal pure returns (uint256) {
        return (amount * _CONVERSION_MULTIPLIER) / _CONVERSION_SCALE;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

/// @custom:salt ALCABurner
/// @custom:deploy-type deployUpgradeable
contract ALCABurner is ImmutableALCA, IStakingTokenBurner {
    constructor() ImmutableFactory(msg.sender) ImmutableALCA() IStakingTokenBurner() {}

    /**
     * @notice Burns ALCAs using the ALCA contract. The burned tokens are removed from the
     * totalSupply.
     * @param from_ The address from where the tokens will be burned
     * @param amount_ The amount of ALCAs to be burned
     */
    function burn(address from_, uint256 amount_) public onlyFactory {
        IStakingToken(_alcaAddress()).externalBurn(from_, amount_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

/// @custom:salt ALCAMinter
/// @custom:deploy-type deployUpgradeable
contract ALCAMinter is ImmutableALCA, IStakingTokenMinter {
    constructor() ImmutableFactory(msg.sender) ImmutableALCA() IStakingTokenMinter() {}

    /**
     * @notice Mints ALCAs
     * @param to_ The address to where the tokens will be minted
     * @param amount_ The amount of ALCAs to be minted
     * */
    function mint(address to_, uint256 amount_) public onlyFactory {
        IStakingToken(_alcaAddress()).externalMint(to_, amount_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/interfaces/IBridgeRouter.sol";
import "contracts/utils/Admin.sol";
import "contracts/utils/Mutex.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableDistribution.sol";
import "contracts/interfaces/IUtilityToken.sol";
import "contracts/libraries/errors/UtilityTokenErrors.sol";
import "contracts/libraries/math/Sigmoid.sol";

/// @custom:salt ALCB
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group alcb
/// @custom:deploy-group-index 0
contract ALCB is
    IUtilityToken,
    ERC20,
    Mutex,
    MagicEthTransfer,
    EthSafeTransfer,
    Sigmoid,
    ImmutableFactory,
    ImmutableDistribution
{
    using Address for address;

    // multiply factor for the selling/minting bonding curve
    uint256 internal constant _MARKET_SPREAD = 4;

    // Address of the central bridge router contract
    address internal immutable _centralBridgeRouter;

    // Balance in ether that is hold in the contract after minting and burning
    uint256 internal _poolBalance;

    // Monotonically increasing variable to track the ALCBs deposits.
    uint256 internal _depositID;

    // Total amount of ALCBs that were deposited in the AliceNet chain. The
    // ALCBs deposited in the AliceNet are burned by this contract.
    uint256 internal _totalDeposited;

    // Tracks the amount of each deposit. Key is deposit id, value is amount
    // deposited.
    mapping(uint256 => Deposit) internal _deposits;

    // mapping to store allowed account types
    mapping(uint8 => bool) internal _accountTypes;

    /**
     * @notice Event emitted when a deposit is received
     */
    event DepositReceived(
        uint256 indexed depositID,
        uint8 indexed accountType,
        address indexed depositor,
        uint256 amount
    );

    constructor(
        address centralBridgeRouterAddress_
    ) ERC20("AliceNet Utility Token", "ALCB") ImmutableFactory(msg.sender) ImmutableDistribution() {
        if (centralBridgeRouterAddress_ == address(0)) {
            revert UtilityTokenErrors.CannotSetRouterToZeroAddress();
        }
        // initializing allowed account types: 1 for secp256k1 and 2 for BLS
        _accountTypes[1] = true;
        _accountTypes[2] = true;
        _centralBridgeRouter = centralBridgeRouterAddress_;
        _virtualDeposit(1, 0xba7809A4114eEF598132461f3202b5013e834CD5, 500000000000);
    }

    /**
     * @notice function to allow factory to add/set the allowed account types supported by AliceNet
     * blockchain.
     * @param accountType_ uint8 account type id to be added
     * @param allowed_ bool if a type should be enabled/disabled
     */
    function setAccountType(uint8 accountType_, bool allowed_) public onlyFactory {
        _accountTypes[accountType_] = allowed_;
    }

    /**
     * @notice Distributes the yields of the ALCB sale to all stakeholders
     * @return true if the method succeeded
     * */
    function distribute() public returns (bool) {
        return _distribute();
    }

    /**
     * @notice Deposits a ALCB amount into the AliceNet blockchain. The ALCBs amount is deducted
     * from the sender and it is burned by this contract. The created deposit Id is owned by the
     * `to_` address.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param amount_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function deposit(uint8 accountType_, address to_, uint256 amount_) public returns (uint256) {
        return _deposit(accountType_, to_, amount_);
    }

    /**
     * @notice Allows deposits to be minted in a virtual manner and sent to the AliceNet chain by
     * simply emitting a Deposit event without actually minting or burning any tokens, must only be
     * called by _admin.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param amount_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function virtualMintDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) public onlyFactory returns (uint256) {
        return _virtualDeposit(accountType_, to_, amount_);
    }

    /**
     * @notice Allows deposits to be minted and sent to the AliceNet chain without actually minting
     * or burning any ALCBs. This function receives ether and converts them directly into ALCB
     * and then deposit them into the AliceNet chain. This function has the same effect as calling
     * mint (creating the tokens) + deposit (burning the tokens) functions but it costs less gas.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param minBTK_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_
    ) public payable returns (uint256) {
        return _mintDeposit(accountType_, to_, minBTK_, msg.value);
    }

    /**
     * @notice Mints ALCB. This function receives ether in the transaction and converts them into
     * ALCB using a bonding price curve.
     * @param minBTK_ Minimum amount of ALCB that you wish to mint given an amount of ether. If
     * its not possible to mint the desired amount with the current price in the bonding curve, the
     * transaction is reverted. If the minBTK_ is met, the whole amount of ether sent will be
     * converted in ALCB.
     * @return numBTK the number of ALCB minted
     */
    function mint(uint256 minBTK_) public payable returns (uint256 numBTK) {
        numBTK = _mint(msg.sender, msg.value, minBTK_);
        return numBTK;
    }

    /**
     * @notice Mints ALCB. This function receives ether in the transaction and converts them into
     * ALCB using a bonding price curve.
     * @param to_ The account to where the tokens will be minted
     * @param minBTK_ Minimum amount of ALCB that you wish to mint given an
     * amount of ether. If its not possible to mint the desired amount with the
     * current price in the bonding curve, the transaction is reverted. If the
     * minBTK_ is met, the whole amount of ether sent will be converted in ALCB.
     * @return numBTK the number of ALCB minted
     */
    function mintTo(address to_, uint256 minBTK_) public payable returns (uint256 numBTK) {
        numBTK = _mint(to_, msg.value, minBTK_);
        return numBTK;
    }

    /**
     * @notice Burn the tokens without sending ether back to user as the normal burn
     * function. The generated ether will be distributed in the distribute method. This function can
     * be used to charge ALCBs fees in other systems.
     * @param numBTK_ the number of ALCB to be burned
     * @return true if the burn succeeded
     */
    function destroyTokens(uint256 numBTK_) public returns (bool) {
        _destroyTokens(msg.sender, numBTK_);
        return true;
    }

    /**
     * @notice Deposits arbitrary tokens in the bridge contracts. This function is an entry
     * point to deposit tokens (ERC20, ERC721, ERC1155) in the bridges and have
     * access to them in the side chain. This function will deduce from the user's
     * balance the corresponding amount of fees to deposit the tokens. The user has
     * the option to pay the fees in ALCB or Ether. If any ether is sent, the
     * function will deduce the fee amount and refund any extra amount. If no ether
     * is sent, the function will deduce the amount of ALCB corresponding to the
     * fees directly from the user's balance.
     * @param routerVersion_ The bridge version where to deposit the tokens.
     * @param data_ Encoded data necessary to deposit the arbitrary tokens in the bridges.
     * */
    function depositTokensOnBridges(uint8 routerVersion_, bytes calldata data_) public payable {
        //forward call to router
        uint256 alcbFee = IBridgeRouter(_centralBridgeRouter).routeDeposit(
            msg.sender,
            routerVersion_,
            data_
        );
        if (msg.value > 0) {
            uint256 ethFee = _getEthToMintTokens(totalSupply(), alcbFee);
            if (ethFee > msg.value) {
                revert UtilityTokenErrors.InsufficientFee(msg.value, ethFee);
            }
            uint256 refund;
            unchecked {
                refund = msg.value - ethFee;
            }
            if (refund > 0) {
                _safeTransferEth(msg.sender, refund);
            }
            return;
        }
        _destroyTokens(msg.sender, alcbFee);
    }

    /**
     * @notice Burn ALCB. This function sends ether corresponding to the amount of ALCBs being
     * burned using a bonding price curve.
     * @param amount_ The amount of ALCB being burned
     * @param minEth_ Minimum amount ether that you expect to receive given the
     * amount of ALCB being burned. If the amount of ALCB being burned
     * worth less than this amount the transaction is reverted.
     * @return numEth The number of ether being received
     * */
    function burn(uint256 amount_, uint256 minEth_) public returns (uint256 numEth) {
        numEth = _burn(msg.sender, msg.sender, amount_, minEth_);
        return numEth;
    }

    /**
     * @notice Burn ALCBs and send the ether received to an other account. This
     * function sends ether corresponding to the amount of ALCBs being
     * burned using a bonding price curve.
     * @param to_ The account to where the ether from the burning will be send
     * @param amount_ The amount of ALCBs being burned
     * @param minEth_ Minimum amount ether that you expect to receive given the
     * amount of ALCBs being burned. If the amount of ALCBs being burned
     * worth less than this amount the transaction is reverted.
     * @return numEth the number of ether being received
     * */
    function burnTo(address to_, uint256 amount_, uint256 minEth_) public returns (uint256 numEth) {
        numEth = _burn(msg.sender, to_, amount_, minEth_);
        return numEth;
    }

    /**
     * @notice Gets the address to the central router for the bridge system
     * @return The address to the central router
     */
    function getCentralBridgeRouterAddress() public view returns (address) {
        return _centralBridgeRouter;
    }

    /**
     * @notice Gets the amount that can be distributed as profits to the stakeholders contracts.
     * @return The amount that can be distributed as yield
     */
    function getYield() public view returns (uint256) {
        return address(this).balance - _poolBalance;
    }

    /**
     * @notice Gets the latest deposit ID emitted.
     * @return The latest deposit ID emitted
     */
    function getDepositID() public view returns (uint256) {
        return _depositID;
    }

    /**
     * @notice Gets the pool balance in ether.
     * @return The pool balance in ether
     */
    function getPoolBalance() public view returns (uint256) {
        return _poolBalance;
    }

    /**
     * @notice Gets the total amount of ALCBs that were deposited in the AliceNet
     * blockchain. Since ALCBs are burned when deposited, this value will be
     * different from the total supply of ALCBs.
     * @return The total amount of ALCBs that were deposited into the AliceNet chain.
     */
    function getTotalTokensDeposited() public view returns (uint256) {
        return _totalDeposited;
    }

    /**
     * @notice Gets the deposited amount given a depositID.
     * @param depositID The Id of the deposit
     * @return the deposit info given a depositID
     */
    function getDeposit(uint256 depositID) public view returns (Deposit memory) {
        Deposit memory d = _deposits[depositID];
        if (d.account == address(0)) {
            revert UtilityTokenErrors.InvalidDepositId(depositID);
        }

        return d;
    }

    /**
     * @notice Compute how many ether will be necessary to mint an amount of ALCBs in the
     * current state of the contract. Should be used carefully if its being called
     * outside an smart contract transaction, as the bonding curve state can change
     * before a future transaction is sent.
     * @param numBTK_ Amount of ALCBs that we want to convert in ether
     * @return numEth the number of ether necessary to mint an amount of ALCB
     */
    function getLatestEthToMintTokens(uint256 numBTK_) public view returns (uint256 numEth) {
        return _getEthToMintTokens(totalSupply(), numBTK_);
    }

    /**
     * @notice Compute how many ether will be received during a ALCB burn at the current
     * bonding curve state. Should be used carefully if its being called outside an
     * smart contract transaction, as the bonding curve state can change before a
     * future transaction is sent.
     * @param numBTK_ Amount of ALCBs to convert in ether
     * @return numEth the amount of ether will be received during a ALCB burn at the current
     * bonding curve state
     */
    function getLatestEthFromTokensBurn(uint256 numBTK_) public view returns (uint256 numEth) {
        return _tokensToEth(_poolBalance, totalSupply(), numBTK_);
    }

    /**
     * @notice Gets an amount of ALCBs that will be minted at the current state of the
     * bonding curve. Should be used carefully if its being called outside an smart
     * contract transaction, as the bonding curve state can change before a future
     * transaction is sent.
     * @param numEth_ Amount of ether to convert in ALCBs
     * @return the amount of ALCBs that will be minted at the current state of the
     * bonding curve
     * */
    function getLatestMintedTokensFromEth(uint256 numEth_) public view returns (uint256) {
        return _ethToTokens(_poolBalance, numEth_ / _MARKET_SPREAD);
    }

    /**
     * @notice Gets the market spread (difference between the minting and burning bonding
     * curves).
     * @return the market spread (difference between the minting and burning bonding
     * curves).
     * */
    function getMarketSpread() public pure returns (uint256) {
        return _MARKET_SPREAD;
    }

    /**
     * @notice Compute how many ether will be necessary to mint an amount of ALCBs at a
     * certain point in the bonding curve.
     * @param totalSupply_ The total supply of ALCB at a given moment where we
     * want to compute the amount of ether necessary to mint.
     * @param numBTK_ Amount of ALCBs that we want to convert in ether
     * @return numEth the amount ether that will be necessary to mint an amount of ALCBs at a
     * certain point in the bonding curve
     * */
    function getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) public pure returns (uint256 numEth) {
        return _getEthToMintTokens(totalSupply_, numBTK_);
    }

    /**
     * @notice Compute how many ether will be received during a ALCB burn.
     * @param poolBalance_ The pool balance (in ether) at the moment
     * that of the conversion.
     * @param totalSupply_ The total supply of ALCB at the moment
     * that of the conversion.
     * @param numBTK_ Amount of ALCBs to convert in ether
     * @return numEth the ether that will be received during a ALCB burn
     * */
    function getEthFromTokensBurn(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) public pure returns (uint256 numEth) {
        return _tokensToEth(poolBalance_, totalSupply_, numBTK_);
    }

    /**
     * @notice Gets an amount of ALCBs that will be minted at given a point in the bonding
     * curve.
     * @param poolBalance_ The pool balance (in ether) at the moment
     * that of the conversion.
     * @param numEth_ Amount of ether to convert in ALCBs
     * @return the amount of ALCBs that will be minted at given a point in the bonding
     * curve.
     * */
    function getMintedTokensFromEth(
        uint256 poolBalance_,
        uint256 numEth_
    ) public pure returns (uint256) {
        return _ethToTokens(poolBalance_, numEth_ / _MARKET_SPREAD);
    }

    /// Distributes the yields from the ALCB minting to all stake holders.
    function _distribute() internal withLock returns (bool) {
        // make a local copy to save gas
        uint256 poolBalance = _poolBalance;
        // find all value in excess of what is needed in pool
        uint256 excess = address(this).balance - poolBalance;
        if (excess == 0) {
            return true;
        }
        _safeTransferEthWithMagic(IMagicEthTransfer(_distributionAddress()), excess);
        if (address(this).balance < poolBalance) {
            revert UtilityTokenErrors.InvalidBalance(address(this).balance, poolBalance);
        }
        return true;
    }

    // Burn the tokens during deposits without sending ether back to user as the
    // normal burn function. The ether will be distributed in the distribute
    // method.
    function _destroyTokens(address account, uint256 numBTK_) internal returns (bool) {
        if (numBTK_ == 0) {
            revert UtilityTokenErrors.InvalidBurnAmount(numBTK_);
        }
        _poolBalance -= _tokensToEth(_poolBalance, totalSupply(), numBTK_);
        ERC20._burn(account, numBTK_);
        return true;
    }

    // Internal function that does the deposit in the AliceNet Chain, i.e emit the
    // event DepositReceived. All the ALCBs sent to this function are burned.
    function _deposit(uint8 accountType_, address to_, uint256 amount_) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }

        if (amount_ == 0) {
            revert UtilityTokenErrors.DepositAmountZero();
        }

        if (!_destroyTokens(msg.sender, amount_)) {
            revert UtilityTokenErrors.DepositBurnFail(amount_);
        }

        // copying state to save gas
        return _doDepositCommon(accountType_, to_, amount_);
    }

    // does a virtual deposit into the AliceNet Chain without actually minting or
    // burning any token.
    function _virtualDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }

        if (amount_ == 0) {
            revert UtilityTokenErrors.DepositAmountZero();
        }

        // copying state to save gas
        return _doDepositCommon(accountType_, to_, amount_);
    }

    // Mints a virtual deposit into the AliceNet Chain without actually minting or
    // burning any token. This function converts ether sent in ALCBs.
    function _mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_,
        uint256 numEth_
    ) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }
        if (numEth_ < _MARKET_SPREAD) {
            revert UtilityTokenErrors.MinimumValueNotMet(numEth_, _MARKET_SPREAD);
        }

        numEth_ = numEth_ / _MARKET_SPREAD;
        uint256 amount_ = _ethToTokens(_poolBalance, numEth_);
        if (amount_ < minBTK_) {
            revert UtilityTokenErrors.InsufficientEth(amount_, minBTK_);
        }

        return _doDepositCommon(accountType_, to_, amount_);
    }

    function _doDepositCommon(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) internal returns (uint256) {
        if (!_accountTypes[accountType_]) {
            revert UtilityTokenErrors.AccountTypeNotSupported(accountType_);
        }
        uint256 depositID = _depositID + 1;
        _deposits[depositID] = _newDeposit(accountType_, to_, amount_);
        _totalDeposited += amount_;
        _depositID = depositID;
        emit DepositReceived(depositID, accountType_, to_, amount_);
        return depositID;
    }

    // Internal function that mints the ALCB tokens following the bounding
    // price curve.
    function _mint(
        address to_,
        uint256 numEth_,
        uint256 minBTK_
    ) internal returns (uint256 numBTK) {
        if (numEth_ < _MARKET_SPREAD) {
            revert UtilityTokenErrors.MinimumValueNotMet(numEth_, _MARKET_SPREAD);
        }

        numEth_ = numEth_ / _MARKET_SPREAD;
        uint256 poolBalance = _poolBalance;
        numBTK = _ethToTokens(poolBalance, numEth_);
        if (numBTK < minBTK_) {
            revert UtilityTokenErrors.MinimumMintNotMet(numBTK, minBTK_);
        }

        poolBalance += numEth_;
        _poolBalance = poolBalance;
        ERC20._mint(to_, numBTK);
        return numBTK;
    }

    // Internal function that burns the ALCB tokens following the bounding
    // price curve.
    function _burn(
        address from_,
        address to_,
        uint256 numBTK_,
        uint256 minEth_
    ) internal returns (uint256 numEth) {
        if (numBTK_ == 0) {
            revert UtilityTokenErrors.InvalidBurnAmount(numBTK_);
        }

        uint256 poolBalance = _poolBalance;
        numEth = _tokensToEth(poolBalance, totalSupply(), numBTK_);

        if (numEth < minEth_) {
            revert UtilityTokenErrors.MinimumBurnNotMet(numEth, minEth_);
        }

        poolBalance -= numEth;
        _poolBalance = poolBalance;
        ERC20._burn(from_, numBTK_);
        _safeTransferEth(to_, numEth);
        return numEth;
    }

    // Internal function that converts an ether amount into ALCB tokens
    // following the bounding price curve.
    function _ethToTokens(uint256 poolBalance_, uint256 numEth_) internal pure returns (uint256) {
        return _p(poolBalance_ + numEth_) - _p(poolBalance_);
    }

    // Internal function that converts a ALCB amount into ether following the
    // bounding price curve.
    function _tokensToEth(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) internal pure returns (uint256 numEth) {
        if (totalSupply_ < numBTK_) {
            revert UtilityTokenErrors.BurnAmountExceedsSupply(numBTK_, totalSupply_);
        }
        return _min(poolBalance_, _pInverse(totalSupply_) - _pInverse(totalSupply_ - numBTK_));
    }

    // Internal function to compute the amount of ether required to mint an amount
    // of ALCBs. Inverse of the _ethToALCBs function.
    function _getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) internal pure returns (uint256 numEth) {
        return (_pInverse(totalSupply_ + numBTK_) - _pInverse(totalSupply_)) * _MARKET_SPREAD;
    }

    function _newDeposit(
        uint8 accountType_,
        address account_,
        uint256 value_
    ) internal pure returns (Deposit memory) {
        Deposit memory d = Deposit(accountType_, account_, value_);
        return d;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/DeterministicAddress.sol";
import "contracts/Proxy.sol";
import "contracts/libraries/factory/AliceNetFactoryBase.sol";
import "contracts/ALCA.sol";

contract AliceNetFactory is AliceNetFactoryBase {
    // ALCA salt = Bytes32(ALCA)
    bytes32 internal constant _ALCA_SALT =
        0x414c434100000000000000000000000000000000000000000000000000000000;

    bytes32 internal immutable _alcaCreationCodeHash;
    address internal immutable _alcaAddress;

    /**
     * @notice The constructor encodes the proxy deploy byte code with the _UNIVERSAL_DEPLOY_CODE at the
     * head and the factory address at the tail, and deploys the proxy byte code using create OpCode.
     * The result of this deployment will be a contract with the proxy contract deployment bytecode with
     * its constructor at the head, runtime code in the body and constructor args at the tail. The
     * constructor then sets proxyTemplate_ state var to the deployed proxy template address the deploy
     * account will be set as the first owner of the factory.
     */
    constructor(address legacyToken_) AliceNetFactoryBase() {
        // Deploying ALCA
        bytes memory creationCode = abi.encodePacked(
            type(ALCA).creationCode,
            bytes32(uint256(uint160(legacyToken_)))
        );
        address alcaAddress;
        assembly ("memory-safe") {
            alcaAddress := create2(0, add(creationCode, 0x20), mload(creationCode), _ALCA_SALT)
        }
        _codeSizeZeroRevert((_extCodeSize(alcaAddress) != 0));
        _alcaAddress = alcaAddress;
        _alcaCreationCodeHash = keccak256(abi.encodePacked(creationCode));
    }

    /**
     * @notice callAny allows EOA to call function impersonating the factory address
     * @param target_: the address of the contract to be called
     * @param value_: value in WEIs to send together the call
     * @param cdata_: Hex encoded state with function signature + arguments of the target function to be called
     * @return the return of the calls as a byte array
     */
    function callAny(
        address target_,
        uint256 value_,
        bytes calldata cdata_
    ) public payable onlyOwner returns (bytes memory) {
        bytes memory cdata = cdata_;
        return _callAny(target_, value_, cdata);
    }

    /**
     * @notice deployCreate allows the owner to deploy raw contracts through the factory using
     * non-deterministic address generation (create OpCode)
     * @param deployCode_ Hex encoded state with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function deployCreate(
        bytes calldata deployCode_
    ) public onlyOwner returns (address contractAddr) {
        return _deployCreate(deployCode_);
    }

    /**
     * @notice allows the owner to deploy contracts through the factory using
     * non-deterministic address generation and record the address to external contract mapping
     * @param deployCode_ Hex encoded state with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @return contractAddr the deployed contract address
     */
    function deployCreateAndRegister(
        bytes calldata deployCode_,
        bytes32 salt_
    ) public onlyOwner returns (address contractAddr) {
        address newContractAddress = _deployCreate(deployCode_);
        _addNewContract(salt_, newContractAddress);
        return newContractAddress;
    }

    /**
     * @notice Add a new address and "pseudo" salt to the externalContractRegistry
     * @param salt_: salt to be used to retrieve the contract
     * @param newContractAddress_: address of the contract to be added to registry
     */
    function addNewExternalContract(bytes32 salt_, address newContractAddress_) public onlyOwner {
        _codeSizeZeroRevert(_extCodeSize(newContractAddress_) != 0);
        _addNewContract(salt_, newContractAddress_);
    }

    /**
     * @notice deployCreate2 allows the owner to deploy contracts with deterministic address
     * through the factory
     * @param value_ endowment value in WEIS for the created contract
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @param deployCode_ Hex encoded state with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function deployCreate2(
        uint256 value_,
        bytes32 salt_,
        bytes calldata deployCode_
    ) public payable onlyOwner returns (address contractAddr) {
        contractAddr = _deployCreate2(value_, salt_, deployCode_);
    }

    /**
     * @notice deployProxy deploys a proxy contract with upgradable logic. See Proxy.sol contract.
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @return contractAddr the deployed contract address
     */
    function deployProxy(bytes32 salt_) public onlyOwner returns (address contractAddr) {
        contractAddr = _deployProxy(salt_);
    }

    /**
     * @notice initializeContract allows the owner to initialize contracts deployed via factory
     * @param contract_ address of the contract that will be initialized
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * deployed contract
     */
    function initializeContract(address contract_, bytes calldata initCallData_) public onlyOwner {
        _initializeContract(contract_, initCallData_);
    }

    /**
     * @notice multiCall allows owner to make multiple function calls within a single transaction
     * impersonating the factory
     * @param cdata_: array of hex encoded state with the function calls (function signature + arguments)
     * @return an array with all the returns of the calls
     */
    function multiCall(MultiCallArgs[] calldata cdata_) public onlyOwner returns (bytes[] memory) {
        return _multiCall(cdata_);
    }

    /**
     * @notice upgradeProxy updates the implementation/logic address of an already deployed proxy contract.
     * @param salt_ salt used to determine the final determinist address for the deployed proxy contract
     * @param newImpl_ address of the new contract that contains the new implementation logic
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * new implementation contract
     */
    function upgradeProxy(
        bytes32 salt_,
        address newImpl_,
        bytes calldata initCallData_
    ) public onlyOwner {
        _upgradeProxy(salt_, newImpl_, initCallData_);
    }

    /**
     * @notice lookup allows anyone interacting with the contract to get the address of contract
     * specified by its salt_.
     * @param salt_: Custom NatSpec tag @custom:salt at the top of the contract solidity file
     * @return the address of the contract specified by the salt. Returns address(0) in case no
     * contract was deployed for that salt.
     */
    function lookup(bytes32 salt_) public view override returns (address) {
        // check if the salt belongs to one of the pre-defined contracts deployed during the factory
        // deployment
        if (salt_ == _ALCA_SALT) {
            return _alcaAddress;
        }
        return AliceNetFactoryBase._lookup(salt_);
    }

    /**
     * @notice getter function for retrieving the hash of the ALCA creation code.
     * @return the hash of the ALCA creation code.
     */
    function getALCACreationCodeHash() public view returns (bytes32) {
        return _alcaCreationCodeHash;
    }

    /**
     * @notice getter function for retrieving the address of the ALCA contract.
     * @return ALCA address.
     */
    function getALCAAddress() public view returns (address) {
        return _alcaAddress;
    }

    /**
     * @notice getter function for retrieving the implementation address of an AliceNet proxy.
     * @param proxyAddress_ the address of the proxy
     * @return the address of implementation/logic contract used by the proxy
     */
    function getProxyImplementation(address proxyAddress_) public view returns (address) {
        return __getProxyImplementation(proxyAddress_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/RewardPool.sol";
import "contracts/Lockup.sol";

/**
 * @notice This contract holds all ALCA that is held in escrow for lockup
 * bonuses. All ALCA is hold into a single staked position that is owned
 * locally.
 * @dev deployed by the RewardPool contract
 */
contract BonusPool is
    ImmutableALCA,
    ImmutablePublicStaking,
    ImmutableFoundation,
    ERC20SafeTransfer,
    EthSafeTransfer,
    ERC721Holder,
    AccessControlled,
    MagicEthTransfer
{
    uint256 internal immutable _totalBonusAmount;
    address internal immutable _lockupContract;
    address internal immutable _rewardPool;
    // tokenID of the position created to hold the amount that will be redistributed as bonus
    uint256 internal _tokenID;

    event BonusPositionCreated(uint256 tokenID);

    constructor(
        address aliceNetFactory_,
        address lockupContract_,
        address rewardPool_,
        uint256 totalBonusAmount_
    )
        ImmutableFactory(aliceNetFactory_)
        ImmutableALCA()
        ImmutablePublicStaking()
        ImmutableFoundation()
    {
        _totalBonusAmount = totalBonusAmount_;
        _lockupContract = lockupContract_;
        _rewardPool = rewardPool_;
    }

    receive() external payable {
        if (msg.sender != _publicStakingAddress()) {
            revert LockupErrors.AddressNotAllowedToSendEther();
        }
    }

    /// @notice function that creates/mint a publicStaking position with an amount that will be
    /// redistributed as bonus at the end of the lockup period. The amount of ALCA has to be
    /// transferred before calling this function.
    /// @dev can be only called by the AliceNet factory
    function createBonusStakedPosition() public onlyFactory {
        if (_tokenID != 0) {
            revert LockupErrors.BonusTokenAlreadyCreated();
        }
        IERC20 alca = IERC20(_alcaAddress());
        //get the total balance of ALCA owned by bonus pool as stake amount
        uint256 _stakeAmount = alca.balanceOf(address(this));
        if (_stakeAmount < _totalBonusAmount) {
            revert LockupErrors.NotEnoughALCAToStake(_stakeAmount, _totalBonusAmount);
        }
        // approve the staking contract to transfer the ALCA
        alca.approve(_publicStakingAddress(), _totalBonusAmount);
        uint256 tokenID = IStakingNFT(_publicStakingAddress()).mint(_totalBonusAmount);
        _tokenID = tokenID;
        emit BonusPositionCreated(_tokenID);
    }

    /// @notice Burns that bonus staked position, and send the bonus amount of shares + profits to
    /// the rewardPool contract, so users can collect.
    function terminate() public onlyLockup {
        if (_tokenID == 0) {
            revert LockupErrors.BonusTokenNotCreated();
        }
        // burn the nft to collect all profits.
        IStakingNFT(_publicStakingAddress()).burn(_tokenID);
        // restarting the _tokenID
        _tokenID = 0;
        // send the total balance of ALCA to the rewardPool contract
        uint256 alcaBalance = IERC20(_alcaAddress()).balanceOf(address(this));
        _safeTransferERC20(
            IERC20Transferable(_alcaAddress()),
            _getRewardPoolAddress(),
            alcaBalance
        );
        // send also all the balance of ether
        uint256 ethBalance = address(this).balance;
        RewardPool(_getRewardPoolAddress()).deposit{value: ethBalance}(alcaBalance);
    }

    /// @notice gets the lockup contract address
    /// @return the lockup contract address
    function getLockupContractAddress() public view returns (address) {
        return _getLockupContractAddress();
    }

    /// @notice gets the rewardPool contract address
    /// @return the rewardPool contract address
    function getRewardPoolAddress() public view returns (address) {
        return _getRewardPoolAddress();
    }

    /// @notice gets the tokenID of the publicStaking position that has the whole bonus amount
    /// @return the tokenID of the publicStaking position that has the whole bonus amount
    function getBonusStakedPosition() public view returns (uint256) {
        return _tokenID;
    }

    /// @notice gets the total amount of ALCA that was staked initially in the publicStaking position
    /// @return the total amount of ALCA that was staked initially in the publicStaking position
    function getTotalBonusAmount() public view returns (uint256) {
        return _totalBonusAmount;
    }

    /// @notice estimates a user's bonus amount + bonus position profits.
    /// @param currentSharesLocked_ The current number of shares locked in the lockup contract
    /// @param userShares_ The amount of shares that a user locked-up.
    /// @return bonusRewardEth the estimated amount ether profits for a user
    /// @return bonusRewardToken the estimated amount ALCA profits for a user
    function estimateBonusAmountWithReward(
        uint256 currentSharesLocked_,
        uint256 userShares_
    ) public view returns (uint256 bonusRewardEth, uint256 bonusRewardToken) {
        if (_tokenID == 0) {
            return (0, 0);
        }

        (uint256 estimatedPayoutEth, uint256 estimatedPayoutToken) = IStakingNFT(
            _publicStakingAddress()
        ).estimateAllProfits(_tokenID);

        (uint256 shares, , , , ) = IStakingNFT(_publicStakingAddress()).getPosition(_tokenID);
        estimatedPayoutToken += shares;

        // compute what will be the amount that a user will receive from the amount that will be
        // sent to the reward contract.
        bonusRewardEth = (estimatedPayoutEth * userShares_) / currentSharesLocked_;
        bonusRewardToken = (estimatedPayoutToken * userShares_) / currentSharesLocked_;
    }

    function _getLockupContractAddress() internal view override returns (address) {
        return _lockupContract;
    }

    function _getBonusPoolAddress() internal view override returns (address) {
        return address(this);
    }

    function _getRewardPoolAddress() internal view override returns (address) {
        return _rewardPool;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/BridgePoolFactoryErrors.sol";
import "contracts/libraries/factory/BridgePoolFactoryBase.sol";

/// @custom:salt BridgePoolFactory
/// @custom:deploy-type deployUpgradeable
contract BridgePoolFactory is BridgePoolFactoryBase {
    constructor() BridgePoolFactoryBase() {}

    /**
     * @notice Deploys a new bridge to pass tokens to our chain from the specified ERC contract.
     * The pools are created as thin proxies (EIP1167) routing to versioned implementations identified by corresponding salt.
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param ercContract_ address of ERC20 source token contract
     * @param implementationVersion_ version of BridgePool implementation to use
     */
    function deployNewNativePool(
        uint8 tokenType_,
        address ercContract_,
        uint16 implementationVersion_
    ) public onlyFactoryOrPublicEnabled {
        _deployNewNativePool(tokenType_, ercContract_, implementationVersion_);
    }

    /**
     * @notice deploys logic for bridge pools and stores it in a logicAddresses mapping
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param chainId_ address of ERC20 source token contract
     * @param value_ amount of eth to send to the contract on creation
     * @param deployCode_ logic contract deployment bytecode
     */
    function deployPoolLogic(
        uint8 tokenType_,
        uint256 chainId_,
        uint256 value_,
        bytes calldata deployCode_
    ) public onlyFactory returns (address) {
        return _deployPoolLogic(tokenType_, chainId_, value_, deployCode_);
    }

    /**
     * @dev enables or disables public pool deployment
     **/
    function togglePublicPoolDeployment() public onlyFactory {
        _togglePublicPoolDeployment();
    }

    /**
     * @notice calculates bridge pool address with associated bytes32 salt
     * @param bridgePoolSalt_ bytes32 salt associated with the pool, calculated with getBridgePoolSalt
     * @return poolAddress calculated calculated bridgePool Address
     */
    function lookupBridgePoolAddress(
        bytes32 bridgePoolSalt_
    ) public view returns (address poolAddress) {
        poolAddress = BridgePoolAddressUtil.getBridgePoolAddress(bridgePoolSalt_, address(this));
    }

    /**
     * @notice calculates salt for a BridgePool contract based on ERC contract's address, tokenType, chainID and version_
     * @param tokenContractAddr_ address of ERC Token contract
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param version_ version of the implementation
     * @param chainID_ chain ID
     * @return calculated calculated salt
     */
    function getBridgePoolSalt(
        address tokenContractAddr_,
        uint8 tokenType_,
        uint256 chainID_,
        uint16 version_
    ) public pure returns (bytes32) {
        return
            BridgePoolAddressUtil.getBridgePoolSalt(
                tokenContractAddr_,
                tokenType_,
                chainID_,
                version_
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCB.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableLiquidityProviderStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/interfaces/IDistribution.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/libraries/errors/DistributionErrors.sol";

/// @custom:salt Distribution
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group alcb
/// @custom:deploy-group-index 1
contract Distribution is
    IDistribution,
    MagicEthTransfer,
    EthSafeTransfer,
    ImmutableFactory,
    ImmutableALCB,
    ImmutablePublicStaking,
    ImmutableValidatorStaking,
    ImmutableLiquidityProviderStaking,
    ImmutableFoundation
{
    // Scaling factor to get the staking percentages
    uint256 public constant PERCENTAGE_SCALE = 1000;

    // Value of the percentages that will send to each staking contract. Divide
    // this value by PERCENTAGE_SCALE = 1000 to get the corresponding percentages.
    // These values must sum to 1000.
    uint256 internal immutable _protocolFeeSplit;
    uint256 internal immutable _publicStakingSplit;
    uint256 internal immutable _liquidityProviderStakingSplit;
    uint256 internal immutable _validatorStakingSplit;

    constructor(
        uint256 validatorStakingSplit_,
        uint256 publicStakingSplit_,
        uint256 liquidityProviderStakingSplit_,
        uint256 protocolFeeSplit_
    )
        ImmutableFactory(msg.sender)
        ImmutableALCB()
        ImmutablePublicStaking()
        ImmutableValidatorStaking()
        ImmutableLiquidityProviderStaking()
        ImmutableFoundation()
    {
        if (
            validatorStakingSplit_ +
                publicStakingSplit_ +
                liquidityProviderStakingSplit_ +
                protocolFeeSplit_ !=
            PERCENTAGE_SCALE
        ) {
            revert DistributionErrors.SplitValueSumError();
        }
        _validatorStakingSplit = validatorStakingSplit_;
        _publicStakingSplit = publicStakingSplit_;
        _liquidityProviderStakingSplit = liquidityProviderStakingSplit_;
        _protocolFeeSplit = protocolFeeSplit_;
    }

    function depositEth(uint8 magic_) public payable checkMagic(magic_) onlyALCB {
        _distribute();
    }

    /// Gets the value of the percentages that will send to each staking contract.
    /// Divide this value by PERCENTAGE_SCALE = 1000 to get the corresponding
    /// percentages.
    function getSplits() public view returns (uint256, uint256, uint256, uint256) {
        return (
            _validatorStakingSplit,
            _publicStakingSplit,
            _liquidityProviderStakingSplit,
            _protocolFeeSplit
        );
    }

    /// Distributes the yields from the ALCB minting to all stake holders.
    function _distribute() internal returns (bool) {
        uint256 excess = address(this).balance;
        // take out protocolFeeShare from excess and decrement excess
        uint256 protocolFeeShare = (excess * _protocolFeeSplit) / PERCENTAGE_SCALE;
        // split remaining between validators, stakers and lp stakers
        uint256 publicStakingShare = (excess * _publicStakingSplit) / PERCENTAGE_SCALE;
        uint256 lpStakingShare = (excess * _liquidityProviderStakingSplit) / PERCENTAGE_SCALE;
        // then give validators the rest
        uint256 validatorStakingShare = excess -
            (protocolFeeShare + publicStakingShare + lpStakingShare);

        if (protocolFeeShare != 0) {
            _safeTransferEthWithMagic(IMagicEthTransfer(_foundationAddress()), protocolFeeShare);
        }
        if (publicStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_publicStakingAddress()),
                publicStakingShare
            );
        }
        if (lpStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_liquidityProviderStakingAddress()),
                lpStakingShare
            );
        }
        if (validatorStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_validatorStakingAddress()),
                validatorStakingShare
            );
        }
        // invariants hold
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/interfaces/IValidatorPool.sol";

contract DutchAuction is Initializable, ImmutableFactory, ImmutableValidatorPool {
    uint256 private constant _START_PRICE = 1000000 * 10 ** 18;
    uint256 private constant _ETHDKG_VALIDATOR_COST = 1200000 * 2 * 100 * 10 ** 9; // Exit and enter ETHDKG aprox 1.2 M gas units at an estimated price of 100 gwei
    uint8 private constant _DECAY = 16;
    uint16 private constant _SCALE_PARAMETER = 100;
    uint256 private _startBlock;
    uint256 private _finalPrice;

    constructor() ImmutableFactory(msg.sender) {}

    //TODO add state checks and/or initializer guards
    function initialize() public {
        resetAuction();
    }

    /// @dev Re-starts auction defining auction's start block
    function resetAuction() public onlyFactory {
        _finalPrice =
            _ETHDKG_VALIDATOR_COST *
            IValidatorPool(_validatorPoolAddress()).getValidatorsCount();
        _startBlock = block.number;
    }

    /// @dev Returns dutch auction price for current block
    function getPrice() public view returns (uint256) {
        return _dutchAuctionPrice(block.number - _startBlock);
    }

    /// @notice Calculates dutch auction price for the specified period (number of blocks since auction initialization)
    /// @dev
    /// @param blocks blocks since the auction started
    function _dutchAuctionPrice(uint256 blocks) internal view returns (uint256 result) {
        uint256 _alfa = _START_PRICE - _finalPrice;
        uint256 t1 = _alfa * _SCALE_PARAMETER;
        uint256 t2 = _DECAY * blocks + _SCALE_PARAMETER ** 2;
        uint256 ratio = t1 / t2;
        return _finalPrice + ratio;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/libraries/dynamics/DoublyLinkedList.sol";
import "contracts/libraries/errors/DynamicsErrors.sol";
import "contracts/interfaces/IDynamics.sol";

/// @custom:salt Dynamics
/// @custom:deploy-type deployUpgradeable
contract Dynamics is Initializable, IDynamics, ImmutableSnapshots {
    using DoublyLinkedListLogic for DoublyLinkedList;

    bytes8 internal constant _UNIVERSAL_DEPLOY_CODE = 0x38585839386009f3;
    Version internal constant _CURRENT_VERSION = Version.V1;

    DoublyLinkedList internal _dynamicValues;
    Configuration internal _configuration;
    CanonicalVersion internal _aliceNetCanonicalVersion;

    constructor() ImmutableFactory(msg.sender) ImmutableSnapshots() {}

    /// Initializes the dynamic value linked list and configurations.
    function initialize(uint24 initialProposalTimeout_) public onlyFactory initializer {
        DynamicValues memory initialValues = DynamicValues(
            Version.V1,
            initialProposalTimeout_,
            3000,
            3000,
            3000000,
            0,
            0,
            0
        );
        // minimum 2 epochs,
        uint128 minEpochsBetweenUpdates = 2;
        // max 336 epochs (approx 1 month considering a snapshot every 2h)
        uint128 maxEpochsBetweenUpdates = 336;
        _configuration = Configuration(minEpochsBetweenUpdates, maxEpochsBetweenUpdates);
        _addNode(1, initialValues);
    }

    /// Change the dynamic values in a epoch in the future.
    /// @param relativeExecutionEpoch the relative execution epoch in which the new
    /// changes will become active.
    /// @param newValue DynamicValue struct with the new values.
    function changeDynamicValues(
        uint32 relativeExecutionEpoch,
        DynamicValues memory newValue
    ) public onlyFactory {
        _changeDynamicValues(relativeExecutionEpoch, newValue);
    }

    /// Updates the current head of the dynamic values linked list. The head always
    /// contain the values that is execution at a moment.
    /// @param currentEpoch the current execution epoch to check if head should be
    /// updated or not.
    function updateHead(uint32 currentEpoch) public onlySnapshots {
        uint32 nextEpoch = _dynamicValues.getNextEpoch(_dynamicValues.getHead());
        if (nextEpoch != 0 && currentEpoch >= nextEpoch) {
            _dynamicValues.setHead(nextEpoch);
        }
        CanonicalVersion memory currentVersion = _aliceNetCanonicalVersion;
        if (currentVersion.executionEpoch != 0 && currentVersion.executionEpoch == currentEpoch) {
            emit NewCanonicalAliceNetNodeVersion(currentVersion);
        }
    }

    /// Updates the aliceNet node version. The new version should always be greater
    /// than the old version. The new major version cannot be greater than 1 unit
    /// comparing with the previous version.
    /// @param relativeUpdateEpoch how many epochs from current epoch that the new
    /// version will become canonical (and maybe mandatory if its a major update).
    /// @param majorVersion major version of the aliceNet Node.
    /// @param minorVersion minor version of the aliceNet Node.
    /// @param patch patch version of the aliceNet Node.
    /// @param binaryHash hash of the aliceNet Node.
    function updateAliceNetNodeVersion(
        uint32 relativeUpdateEpoch,
        uint32 majorVersion,
        uint32 minorVersion,
        uint32 patch,
        bytes32 binaryHash
    ) public onlyFactory {
        _updateAliceNetNodeVersion(
            relativeUpdateEpoch,
            majorVersion,
            minorVersion,
            patch,
            binaryHash
        );
    }

    /// Sets the configuration for the dynamic system.
    /// @param newConfig the struct with the new configuration.
    function setConfiguration(Configuration calldata newConfig) public onlyFactory {
        _configuration = newConfig;
    }

    /// Deploys a new storage contract. A storage contract contains arbitrary data
    /// sent in the `data` parameter as its runtime byte code. I.e, it is a basic a
    /// blob of data with an address.
    /// @param data the data to be stored in the storage contract runtime byte code.
    /// @return contractAddr the address of the storage contract.
    function deployStorage(bytes calldata data) public returns (address contractAddr) {
        return _deployStorage(data);
    }

    /// Gets the latest configuration.
    function getConfiguration() public view returns (Configuration memory) {
        return _configuration;
    }

    /// Get the latest dynamic values that are currently in execution in the side chain.
    function getLatestDynamicValues() public view returns (DynamicValues memory) {
        return _decodeDynamicValues(_dynamicValues.getValue(_dynamicValues.getHead()));
    }

    /// Get the furthest dynamic values that will be in execution in the future.
    function getFurthestDynamicValues() public view returns (DynamicValues memory) {
        return _decodeDynamicValues(_dynamicValues.getValue(_dynamicValues.getTail()));
    }

    /// Get the latest version of the aliceNet node and when it becomes canonical.
    function getLatestAliceNetVersion() public view returns (CanonicalVersion memory) {
        return _aliceNetCanonicalVersion;
    }

    /// Get the dynamic value in execution from an epoch in the past. The value has
    /// to be greater than the previous head execution epoch.
    /// @param epoch The epoch in the past to get the dynamic value.
    function getPreviousDynamicValues(uint256 epoch) public view returns (DynamicValues memory) {
        uint256 head = _dynamicValues.getHead();
        if (head <= epoch) {
            return _decodeDynamicValues(_dynamicValues.getValue(head));
        }
        uint256 previous = _dynamicValues.getPreviousEpoch(head);
        if (previous != 0 && previous <= epoch) {
            return _decodeDynamicValues(_dynamicValues.getValue(previous));
        }
        revert DynamicsErrors.DynamicValueNotFound(epoch);
    }

    /// Get all the dynamic values in the doubly linked list
    function getAllDynamicValues() public view returns (DynamicValues[] memory) {
        DynamicValues[] memory dynamicValuesArray = new DynamicValues[](_dynamicValues.totalNodes);
        uint256 position = 0;
        for (uint256 epoch = 1; epoch != 0; epoch = _dynamicValues.getNextEpoch(epoch)) {
            address data = _dynamicValues.getValue(epoch);
            dynamicValuesArray[position] = _decodeDynamicValues(data);
            position++;
        }
        return dynamicValuesArray;
    }

    /// Decodes a dynamic struct from a storage contract.
    /// @param addr The address of the storage contract that contains the dynamic
    /// values as its runtime byte code.
    function decodeDynamicValues(address addr) public view returns (DynamicValues memory) {
        return _decodeDynamicValues(addr);
    }

    /// Encode a dynamic value struct to be stored in a storage contract.
    /// @param value the dynamic value struct to be encoded.
    function encodeDynamicValues(DynamicValues memory value) public pure returns (bytes memory) {
        return _encodeDynamicValues(value);
    }

    /// Get the latest encoding version that its being used to encode and decode the
    /// dynamic values from the storage contracts.
    function getEncodingVersion() public pure returns (Version) {
        return _CURRENT_VERSION;
    }

    // Internal function to deploy a new storage contract with the `data` as its
    // runtime byte code.
    // @param data the data that will be used to deploy the new storage contract.
    // @return the new storage contract address.
    function _deployStorage(bytes memory data) internal returns (address) {
        bytes memory deployCode = abi.encodePacked(_UNIVERSAL_DEPLOY_CODE, data);
        address addr;
        assembly ("memory-safe") {
            addr := create(0, add(deployCode, 0x20), mload(deployCode))
            if iszero(addr) {
                //if contract creation fails, we want to return any err messages
                let ptr := mload(0x40)
                mstore(0x40, add(ptr, returndatasize()))
                returndatacopy(ptr, 0x00, returndatasize())
                revert(ptr, returndatasize())
            }
        }
        emit DeployedStorageContract(addr);
        return addr;
    }

    // Internal function to update the aliceNet Node version. The new version should
    // always be greater than the old version. The new major version cannot be
    // greater than 1 unit comparing with the previous version.
    // @param relativeUpdateEpoch how many epochs from current epoch that the new
    // version will become canonical (and maybe mandatory if its a major update).
    // @param majorVersion major version of the aliceNet Node.
    // @param minorVersion minor version of the aliceNet Node.
    // @param patch patch version of the aliceNet Node.
    // @param binaryHash hash of the aliceNet Node.
    function _updateAliceNetNodeVersion(
        uint32 relativeUpdateEpoch,
        uint32 majorVersion,
        uint32 minorVersion,
        uint32 patch,
        bytes32 binaryHash
    ) internal {
        CanonicalVersion memory currentVersion = _aliceNetCanonicalVersion;
        uint256 currentCompactedVersion = _computeCompactedVersion(
            currentVersion.major,
            currentVersion.minor,
            currentVersion.patch
        );
        CanonicalVersion memory newVersion = CanonicalVersion(
            majorVersion,
            minorVersion,
            patch,
            _computeExecutionEpoch(relativeUpdateEpoch),
            binaryHash
        );
        uint256 newCompactedVersion = _computeCompactedVersion(majorVersion, minorVersion, patch);
        if (
            newCompactedVersion <= currentCompactedVersion ||
            majorVersion > currentVersion.major + 1
        ) {
            revert DynamicsErrors.InvalidAliceNetNodeVersion(newVersion, currentVersion);
        }
        if (binaryHash == 0 || binaryHash == currentVersion.binaryHash) {
            revert DynamicsErrors.InvalidAliceNetNodeHash(binaryHash, currentVersion.binaryHash);
        }
        _aliceNetCanonicalVersion = newVersion;
        emit NewAliceNetNodeVersionAvailable(newVersion);
    }

    // Internal function to change the dynamic values in a epoch in the future.
    // @param relativeExecutionEpoch the relative execution epoch in which the new
    // changes will become active.
    // @param newValue DynamicValue struct with the new values.
    function _changeDynamicValues(
        uint32 relativeExecutionEpoch,
        DynamicValues memory newValue
    ) internal {
        _addNode(_computeExecutionEpoch(relativeExecutionEpoch), newValue);
    }

    // Add a new node (in the future) to dynamic linked list and emit the event that
    // will be listened by the side chain.
    // @param executionEpoch the epoch where the new values will become active in
    // the side chain.
    // @param value the new dynamic values.
    function _addNode(uint32 executionEpoch, DynamicValues memory value) internal {
        // The new value is encoded and a new storage contract is deployed with its data
        // before adding the new node.
        bytes memory encodedData = _encodeDynamicValues(value);
        address dataAddress = _deployStorage(encodedData);
        _dynamicValues.addNode(executionEpoch, dataAddress);
        emit DynamicValueChanged(executionEpoch, encodedData);
    }

    // Internal function to compute the execution epoch. This function gets the
    // latest epoch from the snapshots contract and sums the
    // `relativeExecutionEpoch`. The `relativeExecutionEpoch` should respect the
    // configuration requirements.
    // @param relativeExecutionEpoch the relative execution epoch
    // @return the absolute execution epoch
    function _computeExecutionEpoch(uint32 relativeExecutionEpoch) internal view returns (uint32) {
        Configuration memory config = _configuration;
        if (
            relativeExecutionEpoch < config.minEpochsBetweenUpdates ||
            relativeExecutionEpoch > config.maxEpochsBetweenUpdates
        ) {
            revert DynamicsErrors.InvalidScheduledDate(
                relativeExecutionEpoch,
                config.minEpochsBetweenUpdates,
                config.maxEpochsBetweenUpdates
            );
        }
        uint32 currentEpoch = uint32(ISnapshots(_snapshotsAddress()).getEpoch());
        uint32 executionEpoch = relativeExecutionEpoch + currentEpoch;
        return executionEpoch;
    }

    // Internal function to decode a dynamic value struct from a storage contract.
    // @param addr the address of the storage contract.
    // @return the decoded Dynamic value struct.
    function _decodeDynamicValues(
        address addr
    ) internal view returns (DynamicValues memory values) {
        uint256 ptr;
        uint256 retPtr;
        uint8[8] memory sizes = [8, 24, 32, 32, 32, 64, 64, 128];
        uint256 dynamicValuesTotalSize = 48;
        uint256 extCodeSize;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            retPtr := values
            extCodeSize := extcodesize(addr)
            extcodecopy(addr, ptr, 0, extCodeSize)
        }
        if (extCodeSize == 0 || extCodeSize < dynamicValuesTotalSize) {
            revert DynamicsErrors.InvalidExtCodeSize(addr, extCodeSize);
        }

        for (uint8 i = 0; i < sizes.length; i++) {
            uint8 size = sizes[i];
            assembly ("memory-safe") {
                mstore(retPtr, shr(sub(256, size), mload(ptr)))
                ptr := add(ptr, div(size, 8))
                retPtr := add(retPtr, 0x20)
            }
        }
    }

    // Internal function to encode a dynamic value struct in a bytes array.
    // @param newValue the dynamic struct to be encoded.
    // @return the encoded Dynamic value struct.
    function _encodeDynamicValues(
        DynamicValues memory newValue
    ) internal pure returns (bytes memory) {
        bytes memory data = abi.encodePacked(
            newValue.encoderVersion,
            newValue.proposalTimeout,
            newValue.preVoteTimeout,
            newValue.preCommitTimeout,
            newValue.maxBlockSize,
            newValue.dataStoreFee,
            newValue.valueStoreFee,
            newValue.minScaledTransactionFee
        );
        return data;
    }

    // Internal function to compute the compacted version of the aliceNet node. The
    // compacted version basically the sum of the major, minor and patch versions
    // shifted to corresponding places to avoid collisions.
    // @param majorVersion major version of the aliceNet Node.
    // @param minorVersion minor version of the aliceNet Node.
    // @param patch patch version of the aliceNet Node.
    function _computeCompactedVersion(
        uint256 majorVersion,
        uint256 minorVersion,
        uint256 patch
    ) internal pure returns (uint256 fullVersion) {
        assembly ("memory-safe") {
            fullVersion := or(or(shl(64, majorVersion), shl(32, minorVersion)), patch)
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/utils/AtomicCounter.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IETHDKGEvents.sol";
import "contracts/libraries/ethdkg/ETHDKGStorage.sol";
import "contracts/utils/ETHDKGUtils.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableETHDKGAccusations.sol";
import "contracts/utils/auth/ImmutableETHDKGPhases.sol";
import "contracts/libraries/errors/ETHDKGErrors.sol";
import "contracts/libraries/proxy/ProxyImplementationGetter.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @custom:salt ETHDKG
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group ethdkg
/// @custom:deploy-group-index 2
contract ETHDKG is
    ETHDKGStorage,
    IETHDKG,
    IETHDKGEvents,
    ETHDKGUtils,
    ImmutableETHDKGAccusations,
    ImmutableETHDKGPhases,
    ProxyImplementationGetter
{
    using Address for address;

    modifier onlyValidator() {
        if (!IValidatorPool(_validatorPoolAddress()).isValidator(msg.sender)) {
            revert ETHDKGErrors.OnlyValidatorsAllowed(msg.sender);
        }
        _;
    }

    constructor() ETHDKGStorage() ImmutableETHDKGAccusations() ImmutableETHDKGPhases() {}

    function initialize(
        uint256 phaseLength_,
        uint256 confirmationLength_
    ) public initializer onlyFactory {
        _phaseLength = uint16(phaseLength_);
        _confirmationLength = uint16(confirmationLength_);
    }

    function setPhaseLength(uint16 phaseLength_) public onlyFactory {
        if (_isETHDKGRunning()) {
            revert ETHDKGErrors.VariableNotSettableWhileETHDKGRunning();
        }

        _phaseLength = phaseLength_;
    }

    function setConfirmationLength(uint16 confirmationLength_) public onlyFactory {
        if (_isETHDKGRunning()) {
            revert ETHDKGErrors.VariableNotSettableWhileETHDKGRunning();
        }
        _confirmationLength = confirmationLength_;
    }

    function setCustomAliceNetHeight(uint256 aliceNetHeight) public onlyValidatorPool {
        _customAliceNetHeight = aliceNetHeight;
        emit ValidatorSetCompleted(
            0,
            _nonce,
            ISnapshots(_snapshotsAddress()).getEpoch(),
            ISnapshots(_snapshotsAddress()).getCommittedHeightFromLatestSnapshot(),
            aliceNetHeight,
            0x0,
            0x0,
            0x0,
            0x0
        );
    }

    function initializeETHDKG() public onlyValidatorPool {
        _initializeETHDKG();
    }

    function register(uint256[2] memory publicKey) public onlyValidator {
        _callPhaseContract(abi.encodeWithSignature("register(uint256[2])", publicKey));
    }

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature("accuseParticipantNotRegistered(address[])", dishonestAddresses)
        );
    }

    function distributeShares(
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments
    ) public onlyValidator {
        _callPhaseContract(
            abi.encodeWithSignature(
                "distributeShares(uint256[],uint256[2][])",
                encryptedShares,
                commitments
            )
        );
    }

    ///
    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotDistributeShares(address[])",
                dishonestAddresses
            )
        );
    }

    // Someone sent bad shares
    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) public onlyValidator {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDistributedBadShares(address,uint256[],uint256[2][],uint256[2],uint256[2])",
                dishonestAddress,
                encryptedShares,
                commitments,
                sharedKey,
                sharedKeyCorrectnessProof
            )
        );
    }

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) public onlyValidator {
        _callPhaseContract(
            abi.encodeWithSignature(
                "submitKeyShare(uint256[2],uint256[2],uint256[4])",
                keyShareG1,
                keyShareG1CorrectnessProof,
                keyShareG2
            )
        );
    }

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotSubmitKeyShares(address[])",
                dishonestAddresses
            )
        );
    }

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) public {
        _callPhaseContract(
            abi.encodeWithSignature("submitMasterPublicKey(uint256[4])", masterPublicKey_)
        );
    }

    function submitGPKJ(uint256[4] memory gpkj) public onlyValidator {
        _callPhaseContract(abi.encodeWithSignature("submitGPKJ(uint256[4])", gpkj));
    }

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotSubmitGPKJ(address[])",
                dishonestAddresses
            )
        );
    }

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) public onlyValidator {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantSubmittedBadGPKJ(address[],bytes32[],uint256[2][][],address)",
                validators,
                encryptedSharesHash,
                commitments,
                dishonestAddress
            )
        );
    }

    // Successful_Completion should be called at the completion of the DKG algorithm.
    function complete() public onlyValidator {
        _callPhaseContract(abi.encodeWithSignature("complete()"));
    }

    function migrateValidators(
        address[] memory validatorsAccounts_,
        uint256[] memory validatorIndexes_,
        uint256[4][] memory validatorShares_,
        uint8 validatorCount_,
        uint256 epoch_,
        uint256 sideChainHeight_,
        uint256 ethHeight_,
        uint256[4] memory masterPublicKey_
    ) public onlyFactory {
        uint256 nonce = _nonce;
        if (nonce != 0) {
            revert ETHDKGErrors.MigrationRequiresZeroNonce(nonce);
        }

        if (
            validatorsAccounts_.length != validatorIndexes_.length ||
            validatorsAccounts_.length != validatorShares_.length
        ) {
            revert ETHDKGErrors.MigrationInputDataMismatch(
                validatorsAccounts_.length,
                validatorIndexes_.length,
                validatorShares_.length
            );
        }

        nonce++;

        emit RegistrationOpened(block.number, validatorCount_, nonce, 0, 0);

        for (uint256 i = 0; i < validatorsAccounts_.length; i++) {
            emit AddressRegistered(
                validatorsAccounts_[i],
                validatorIndexes_[i],
                nonce,
                [uint256(0), uint256(0)]
            );
        }

        for (uint256 i = 0; i < validatorsAccounts_.length; i++) {
            _participants[validatorsAccounts_[i]].index = uint64(validatorIndexes_[i]);
            _participants[validatorsAccounts_[i]].nonce = uint64(nonce);
            _participants[validatorsAccounts_[i]].phase = Phase.Completion;
            _participants[validatorsAccounts_[i]].gpkj = validatorShares_[i];
            emit ValidatorMemberAdded(
                validatorsAccounts_[i],
                validatorIndexes_[i],
                nonce,
                epoch_,
                validatorShares_[i][0],
                validatorShares_[i][1],
                validatorShares_[i][2],
                validatorShares_[i][3]
            );
        }

        _masterPublicKey = masterPublicKey_;
        _masterPublicKeyHash = keccak256(abi.encodePacked(masterPublicKey_));
        _masterPublicKeyRegistry[_masterPublicKeyHash] = true;
        _nonce = uint64(nonce);
        _numParticipants = validatorCount_;

        emit ValidatorSetCompleted(
            validatorCount_,
            nonce,
            epoch_,
            ethHeight_,
            sideChainHeight_,
            masterPublicKey_[0],
            masterPublicKey_[1],
            masterPublicKey_[2],
            masterPublicKey_[3]
        );
        IValidatorPool(_validatorPoolAddress()).completeETHDKG();
    }

    function isETHDKGRunning() public view returns (bool) {
        return _isETHDKGRunning();
    }

    function isETHDKGCompleted() public view returns (bool) {
        return _isETHDKGCompleted();
    }

    function isETHDKGHalted() public view returns (bool) {
        return _isETHDKGHalted();
    }

    function isMasterPublicKeySet() public view returns (bool) {
        return ((_masterPublicKey[0] != 0) ||
            (_masterPublicKey[1] != 0) ||
            (_masterPublicKey[2] != 0) ||
            (_masterPublicKey[3] != 0));
    }

    function getNonce() public view returns (uint256) {
        return _nonce;
    }

    function getPhaseStartBlock() public view returns (uint256) {
        return _phaseStartBlock;
    }

    function getPhaseLength() public view returns (uint256) {
        return _phaseLength;
    }

    function getConfirmationLength() public view returns (uint256) {
        return _confirmationLength;
    }

    function getETHDKGPhase() public view returns (Phase) {
        return _ethdkgPhase;
    }

    function getNumParticipants() public view returns (uint256) {
        return _numParticipants;
    }

    function getBadParticipants() public view returns (uint256) {
        return _badParticipants;
    }

    function getParticipantInternalState(
        address participant
    ) public view returns (Participant memory) {
        return _participants[participant];
    }

    function getParticipantsInternalState(
        address[] calldata participantAddresses
    ) public view returns (Participant[] memory) {
        Participant[] memory participants = new Participant[](participantAddresses.length);

        for (uint256 i = 0; i < participantAddresses.length; i++) {
            participants[i] = _participants[participantAddresses[i]];
        }

        return participants;
    }

    function getLastRoundParticipantIndex(address participant) public view returns (uint256) {
        uint256 participantDataIndex = _participants[participant].index;
        uint256 participantDataNonce = _participants[participant].nonce;
        uint256 nonce = _nonce;
        if (nonce == 0 || participantDataNonce != nonce) {
            revert ETHDKGErrors.ParticipantNotFoundInLastRound(participant);
        }
        return participantDataIndex;
    }

    function getMasterPublicKey() public view returns (uint256[4] memory) {
        return _masterPublicKey;
    }

    function isValidMasterPublicKey(bytes32 masterPublicKeyHash) public view returns (bool) {
        return _masterPublicKeyRegistry[masterPublicKeyHash];
    }

    function getMasterPublicKeyHash() public view returns (bytes32) {
        return _masterPublicKeyHash;
    }

    function getMinValidators() public pure returns (uint256) {
        return _MIN_VALIDATORS;
    }

    function _callAccusationContract(bytes memory callData) internal returns (bytes memory) {
        return _getETHDKGAccusationsAddress().functionDelegateCall(callData);
    }

    function _callPhaseContract(bytes memory callData) internal returns (bytes memory) {
        return _getETHDKGPhasesAddress().functionDelegateCall(callData);
    }

    function _initializeETHDKG() internal {
        //todo: should we reward ppl here?
        uint256 numberValidators = IValidatorPool(_validatorPoolAddress()).getValidatorsCount();

        if (numberValidators < _MIN_VALIDATORS) {
            revert ETHDKGErrors.MinimumValidatorsNotMet(numberValidators);
        }

        _phaseStartBlock = uint64(block.number);
        _nonce++;
        _numParticipants = 0;
        _badParticipants = 0;
        _ethdkgPhase = Phase.RegistrationOpen;

        emit RegistrationOpened(
            block.number,
            numberValidators,
            _nonce,
            _phaseLength,
            _confirmationLength
        );
    }

    function _getETHDKGPhasesAddress() internal view returns (address ethdkgPhases) {
        ethdkgPhases = __getProxyImplementation(_ethdkgPhasesAddress());
        if (!ethdkgPhases.isContract()) {
            revert ETHDKGErrors.ETHDKGSubContractNotSet();
        }
    }

    function _getETHDKGAccusationsAddress() internal view returns (address ethdkgAccusations) {
        ethdkgAccusations = __getProxyImplementation(_ethdkgAccusationsAddress());
        if (!ethdkgAccusations.isContract()) {
            revert ETHDKGErrors.ETHDKGSubContractNotSet();
        }
    }

    function _isETHDKGCompleted() internal view returns (bool) {
        return _ethdkgPhase == Phase.Completion;
    }

    function _isETHDKGRunning() internal view returns (bool) {
        // Handling initial case
        if (_phaseStartBlock == 0) {
            return false;
        }
        return !_isETHDKGCompleted() && !_isETHDKGHalted();
    }

    // todo: generate truth table
    function _isETHDKGHalted() internal view returns (bool) {
        bool ethdkgFailedInDisputePhase = (_ethdkgPhase == Phase.DisputeShareDistribution ||
            _ethdkgPhase == Phase.DisputeGPKJSubmission) &&
            block.number >= _phaseStartBlock + _phaseLength &&
            _badParticipants != 0;
        bool ethdkgFailedInNormalPhase = block.number >= _phaseStartBlock + 2 * _phaseLength;
        return ethdkgFailedInNormalPhase || ethdkgFailedInDisputePhase;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicValue.sol";

/// @custom:salt Foundation
/// @custom:deploy-type deployUpgradeable
contract Foundation is
    Initializable,
    MagicValue,
    EthSafeTransfer,
    ERC20SafeTransfer,
    ImmutableFactory,
    ImmutableALCA
{
    using Address for address;

    constructor() ImmutableFactory(msg.sender) ImmutableALCA() {}

    function initialize() public initializer onlyFactory {}

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION AS ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY. depositToken distributes ALCAs
    /// to all stakers evenly should only be called during a slashing event. Any
    /// ALCA sent to this method in error will be lost. This function will
    /// fail if the circuit breaker is tripped. The magic_ parameter is intended
    /// to stop some one from successfully interacting with this method without
    /// first reading the source code and hopefully this comment
    /// @notice deposits alcas that will be distributed to the foundation
    /// @param magic_ The required control number to allow operation
    /// @param amount_ The amount of ALCA to be deposited
    function depositToken(uint8 magic_, uint256 amount_) public checkMagic(magic_) {
        // collect tokens
        _safeTransferFromERC20(IERC20Transferable(_alcaAddress()), msg.sender, amount_);
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY depositEth distributes Eth to all
    /// stakers evenly should only be called by ALCB contract any Eth sent to
    /// this method in error will be lost this function will fail if the circuit
    /// breaker is tripped the magic_ parameter is intended to stop some one from
    /// successfully interacting with this method without first reading the
    /// source code and hopefully this comment
    /// @notice deposits eths that will be distributed to the foundation
    /// @param magic_ The required control number to allow operation
    function depositEth(uint8 magic_) public payable checkMagic(magic_) {}

    /// Delegates a call to the specified contract with any set of parameters encoded
    /// @param target_ The address of the contract to be delagated to
    /// @param cdata_ The encoded parameters of the delegate call encoded
    function delegateCallAny(
        address target_,
        bytes memory cdata_
    ) public payable onlyFactory returns (bytes memory) {
        return target_.functionDelegateCall(cdata_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IGovernor.sol";
import "contracts/libraries/errors/GovernanceErrors.sol";

/// @custom:salt Governance
/// @custom:deploy-type deployUpgradeable
contract Governance is IGovernor {
    // dummy contract
    address internal immutable _factory;

    constructor() {
        _factory = msg.sender;
    }

    function updateValue(uint256 epoch, uint256 key, bytes32 value) external {
        if (msg.sender != _factory) {
            revert GovernanceErrors.OnlyFactoryAllowed(msg.sender);
        }
        emit ValueUpdated(epoch, key, value, msg.sender);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IAliceNetFactory {
    function lookup(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.11;

interface IBridgePool {
    function initialize(address ercContract_) external;

    function deposit(address msgSender, bytes calldata depositParameters) external;

    function withdraw(bytes memory _txInPreImage, bytes[4] memory _proofs) external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IBridgeRouter {
    function routeDeposit(
        address account_,
        uint8 routerVersion_,
        bytes calldata data_
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface ICBCloser {
    function resetCB() external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface ICBOpener {
    function tripCB() external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IDistribution {
    function getSplits() external view returns (uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

// enum to keep track of versions of the dynamic struct for the encoding and
// decoding algorithms
enum Version {
    V1
}
struct DynamicValues {
    // first slot
    Version encoderVersion;
    uint24 proposalTimeout;
    uint32 preVoteTimeout;
    uint32 preCommitTimeout;
    uint32 maxBlockSize;
    uint64 dataStoreFee;
    uint64 valueStoreFee;
    // Second slot
    uint128 minScaledTransactionFee;
}

struct Configuration {
    uint128 minEpochsBetweenUpdates;
    uint128 maxEpochsBetweenUpdates;
}

struct CanonicalVersion {
    uint32 major;
    uint32 minor;
    uint32 patch;
    uint32 executionEpoch;
    bytes32 binaryHash;
}

interface IDynamics {
    event DeployedStorageContract(address contractAddr);
    event DynamicValueChanged(uint256 epoch, bytes rawDynamicValues);
    event NewAliceNetNodeVersionAvailable(CanonicalVersion version);
    event NewCanonicalAliceNetNodeVersion(CanonicalVersion version);

    function changeDynamicValues(
        uint32 relativeExecutionEpoch,
        DynamicValues memory newValue
    ) external;

    function updateHead(uint32 currentEpoch) external;

    function updateAliceNetNodeVersion(
        uint32 relativeUpdateEpoch,
        uint32 majorVersion,
        uint32 minorVersion,
        uint32 patch,
        bytes32 binaryHash
    ) external;

    function setConfiguration(Configuration calldata newConfig) external;

    function deployStorage(bytes calldata data) external returns (address contractAddr);

    function getConfiguration() external view returns (Configuration memory);

    function getLatestAliceNetVersion() external view returns (CanonicalVersion memory);

    function getLatestDynamicValues() external view returns (DynamicValues memory);

    function getFurthestDynamicValues() external view returns (DynamicValues memory);

    function getPreviousDynamicValues(uint256 epoch) external view returns (DynamicValues memory);

    function getAllDynamicValues() external view returns (DynamicValues[] memory);

    function decodeDynamicValues(address addr) external view returns (DynamicValues memory);

    function encodeDynamicValues(DynamicValues memory value) external pure returns (bytes memory);

    function getEncodingVersion() external pure returns (Version);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IERC20Transferable {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IERC721Transferable {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/ethdkg/ETHDKGStorage.sol";

interface IETHDKG {
    function setPhaseLength(uint16 phaseLength_) external;

    function setConfirmationLength(uint16 confirmationLength_) external;

    function setCustomAliceNetHeight(uint256 aliceNetHeight) external;

    function initializeETHDKG() external;

    function register(uint256[2] memory publicKey) external;

    function distributeShares(
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments
    ) external;

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) external;

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) external;

    function submitGPKJ(uint256[4] memory gpkj) external;

    function complete() external;

    function migrateValidators(
        address[] memory validatorsAccounts_,
        uint256[] memory validatorIndexes_,
        uint256[4][] memory validatorShares_,
        uint8 validatorCount_,
        uint256 epoch_,
        uint256 sideChainHeight_,
        uint256 ethHeight_,
        uint256[4] memory masterPublicKey_
    ) external;

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) external;

    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) external;

    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) external;

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) external;

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) external;

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) external;

    function isETHDKGRunning() external view returns (bool);

    function isMasterPublicKeySet() external view returns (bool);

    function isValidMasterPublicKey(bytes32 masterPublicKeyHash) external view returns (bool);

    function getNonce() external view returns (uint256);

    function getPhaseStartBlock() external view returns (uint256);

    function getPhaseLength() external view returns (uint256);

    function getConfirmationLength() external view returns (uint256);

    function getETHDKGPhase() external view returns (Phase);

    function getNumParticipants() external view returns (uint256);

    function getBadParticipants() external view returns (uint256);

    function getMinValidators() external view returns (uint256);

    function getParticipantInternalState(
        address participant
    ) external view returns (Participant memory);

    function getMasterPublicKey() external view returns (uint256[4] memory);

    function getMasterPublicKeyHash() external view returns (bytes32);

    function getLastRoundParticipantIndex(address participant) external view returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IETHDKGEvents {
    event RegistrationOpened(
        uint256 startBlock,
        uint256 numberValidators,
        uint256 nonce,
        uint256 phaseLength,
        uint256 confirmationLength
    );

    event AddressRegistered(address account, uint256 index, uint256 nonce, uint256[2] publicKey);

    event RegistrationComplete(uint256 blockNumber);

    event SharesDistributed(
        address account,
        uint256 index,
        uint256 nonce,
        uint256[] encryptedShares,
        uint256[2][] commitments
    );

    event ShareDistributionComplete(uint256 blockNumber);

    event KeyShareSubmitted(
        address account,
        uint256 index,
        uint256 nonce,
        uint256[2] keyShareG1,
        uint256[2] keyShareG1CorrectnessProof,
        uint256[4] keyShareG2
    );

    event KeyShareSubmissionComplete(uint256 blockNumber);

    event MPKSet(uint256 blockNumber, uint256 nonce, uint256[4] mpk);

    event GPKJSubmissionComplete(uint256 blockNumber);

    event ValidatorMemberAdded(
        address account,
        uint256 index,
        uint256 nonce,
        uint256 epoch,
        uint256 share0,
        uint256 share1,
        uint256 share2,
        uint256 share3
    );

    event ValidatorSetCompleted(
        uint256 validatorCount,
        uint256 nonce,
        uint256 epoch,
        uint256 ethHeight,
        uint256 aliceNetHeight,
        uint256 groupKey0,
        uint256 groupKey1,
        uint256 groupKey2,
        uint256 groupKey3
    );
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IGovernor {
    event ValueUpdated(
        uint256 indexed epoch,
        uint256 indexed key,
        bytes32 indexed value,
        address who
    );

    event SnapshotTaken(
        uint256 chainId,
        uint256 indexed epoch,
        uint256 height,
        address indexed validator,
        bool isSafeToProceedConsensus,
        bytes signatureRaw
    );

    function updateValue(uint256 epoch, uint256 key, bytes32 value) external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMagicEthTransfer {
    function depositEth(uint8 magic_) external payable;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMagicTokenTransfer {
    function depositToken(uint8 magic_, uint256 amount_) external payable;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/parsers/BClaimsParserLibrary.sol";

struct Snapshot {
    uint256 committedAt;
    BClaimsParserLibrary.BClaims blockClaims;
}

interface ISnapshots {
    event SnapshotTaken(
        uint256 chainId,
        uint256 indexed epoch,
        uint256 height,
        address indexed validator,
        bool isSafeToProceedConsensus,
        uint256[4] masterPublicKey,
        uint256[2] signature,
        BClaimsParserLibrary.BClaims bClaims
    );

    function setSnapshotDesperationDelay(uint32 desperationDelay_) external;

    function setSnapshotDesperationFactor(uint32 desperationFactor_) external;

    function setMinimumIntervalBetweenSnapshots(uint32 minimumIntervalBetweenSnapshots_) external;

    function snapshot(
        bytes calldata signatureGroup_,
        bytes calldata bClaims_
    ) external returns (bool);

    function migrateSnapshots(
        bytes[] memory groupSignature_,
        bytes[] memory bClaims_
    ) external returns (bool);

    function getSnapshotDesperationDelay() external view returns (uint256);

    function getSnapshotDesperationFactor() external view returns (uint256);

    function getMinimumIntervalBetweenSnapshots() external view returns (uint256);

    function getChainId() external view returns (uint256);

    function getEpoch() external view returns (uint256);

    function getEpochLength() external view returns (uint256);

    function getChainIdFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getChainIdFromLatestSnapshot() external view returns (uint256);

    function getBlockClaimsFromSnapshot(
        uint256 epoch_
    ) external view returns (BClaimsParserLibrary.BClaims memory);

    function getBlockClaimsFromLatestSnapshot()
        external
        view
        returns (BClaimsParserLibrary.BClaims memory);

    function getCommittedHeightFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getCommittedHeightFromLatestSnapshot() external view returns (uint256);

    function getAliceNetHeightFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getAliceNetHeightFromLatestSnapshot() external view returns (uint256);

    function getSnapshot(uint256 epoch_) external view returns (Snapshot memory);

    function getLatestSnapshot() external view returns (Snapshot memory);

    function getEpochFromHeight(uint256 height) external view returns (uint256);

    function checkBClaimsSignature(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) external view returns (bool);

    function isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) external view returns (bool);

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 blsig,
        uint256 desperationFactor
    ) external pure returns (bool);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingNFT {
    function skimExcessEth(address to_) external returns (uint256 excess);

    function skimExcessToken(address to_) external returns (uint256 excess);

    function depositToken(uint8 magic_, uint256 amount_) external;

    function depositEth(uint8 magic_) external payable;

    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) external returns (uint256);

    function lockOwnPosition(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function lockWithdraw(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function mint(uint256 amount_) external returns (uint256 tokenID);

    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) external returns (uint256 tokenID);

    function burn(uint256 tokenID_) external returns (uint256 payoutEth, uint256 payoutALCA);

    function burnTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutEth, uint256 payoutALCA);

    function collectEth(uint256 tokenID_) external returns (uint256 payout);

    function collectToken(uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfits(
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function collectEthTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectTokenTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfitsTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function getPosition(
        uint256 tokenID_
    )
        external
        view
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        );

    function getTotalShares() external view returns (uint256);

    function getTotalReserveEth() external view returns (uint256);

    function getTotalReserveALCA() external view returns (uint256);

    function estimateEthCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateTokenCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateAllProfits(
        uint256 tokenID_
    ) external view returns (uint256 payoutEth, uint256 payoutToken);

    function estimateExcessToken() external view returns (uint256 excess);

    function estimateExcessEth() external view returns (uint256 excess);

    function getEthAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getTokenAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getLatestMintedPositionID() external view returns (uint256);

    function getAccumulatorScaleFactor() external pure returns (uint256);

    function getMaxMintLock() external pure returns (uint256);

    function getMaxGovernanceLock() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingNFT.sol";

/// @title Describes a staked position NFT tokens via URI
interface IStakingNFTDescriptor {
    /// @notice Produces the URI describing a particular token ID for a staked position
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @param _stakingNFT The stake NFT for which to describe the token
    /// @param tokenId The ID of the token for which to produce a description, which may not be valid
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(
        IStakingNFT _stakingNFT,
        uint256 tokenId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingToken {
    function migrate(uint256 amount) external returns (uint256);

    function migrateTo(address to, uint256 amount) external returns (uint256);

    function finishEarlyStage() external;

    function externalMint(address to, uint256 amount) external;

    function externalBurn(address from, uint256 amount) external;

    function getLegacyTokenAddress() external view returns (address);

    function convert(uint256 amount) external view returns (uint256);
}

interface IStakingTokenMinter {
    function mint(address to, uint256 amount) external;
}

interface IStakingTokenBurner {
    function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

struct Deposit {
    uint8 accountType;
    address account;
    uint256 value;
}

interface IUtilityToken {
    function distribute() external returns (bool);

    function deposit(uint8 accountType_, address to_, uint256 amount_) external returns (uint256);

    function virtualMintDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) external returns (uint256);

    function mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_
    ) external payable returns (uint256);

    function mint(uint256 minBTK_) external payable returns (uint256 numBTK);

    function mintTo(address to_, uint256 minBTK_) external payable returns (uint256 numBTK);

    function destroyTokens(uint256 numBTK_) external returns (bool);

    function depositTokensOnBridges(uint8 routerVersion_, bytes calldata data_) external payable;

    function burn(uint256 amount_, uint256 minEth_) external returns (uint256 numEth);

    function burnTo(
        address to_,
        uint256 amount_,
        uint256 minEth_
    ) external returns (uint256 numEth);

    function getYield() external view returns (uint256);

    function getDepositID() external view returns (uint256);

    function getPoolBalance() external view returns (uint256);

    function getTotalTokensDeposited() external view returns (uint256);

    function getDeposit(uint256 depositID) external view returns (Deposit memory);

    function getLatestEthToMintTokens(uint256 numBTK_) external view returns (uint256 numEth);

    function getLatestEthFromTokensBurn(uint256 numBTK_) external view returns (uint256 numEth);

    function getLatestMintedTokensFromEth(uint256 numEth_) external view returns (uint256);

    function getMarketSpread() external pure returns (uint256);

    function getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) external pure returns (uint256 numEth);

    function getEthFromTokensBurn(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) external pure returns (uint256 numEth);

    function getMintedTokensFromEth(
        uint256 poolBalance_,
        uint256 numEth_
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/CustomEnumerableMaps.sol";

interface IValidatorPool {
    event ValidatorJoined(address indexed account, uint256 validatorStakingTokenID);
    event ValidatorLeft(address indexed account, uint256 publicStakingTokenID);
    event ValidatorMinorSlashed(address indexed account, uint256 publicStakingTokenID);
    event ValidatorMajorSlashed(address indexed account);
    event MaintenanceScheduled();

    function setStakeAmount(uint256 stakeAmount_) external;

    function setMaxIntervalWithoutSnapshots(uint256 maxIntervalWithoutSnapshots) external;

    function setMaxNumValidators(uint256 maxNumValidators_) external;

    function setDisputerReward(uint256 disputerReward_) external;

    function setLocation(string calldata ip) external;

    function scheduleMaintenance() external;

    function initializeETHDKG() external;

    function completeETHDKG() external;

    function pauseConsensus() external;

    function pauseConsensusOnArbitraryHeight(uint256 aliceNetHeight) external;

    function registerValidators(
        address[] calldata validators,
        uint256[] calldata publicStakingTokenIDs
    ) external;

    function unregisterValidators(address[] calldata validators) external;

    function unregisterAllValidators() external;

    function collectProfits() external returns (uint256 payoutEth, uint256 payoutToken);

    function claimExitingNFTPosition() external returns (uint256);

    function majorSlash(address dishonestValidator_, address disputer_) external;

    function minorSlash(address dishonestValidator_, address disputer_) external;

    function getMaxIntervalWithoutSnapshots()
        external
        view
        returns (uint256 maxIntervalWithoutSnapshots);

    function getValidatorsCount() external view returns (uint256);

    function getValidatorsAddresses() external view returns (address[] memory);

    function getValidator(uint256 index) external view returns (address);

    function getValidatorData(uint256 index) external view returns (ValidatorData memory);

    function getLocation(address validator) external view returns (string memory);

    function getLocations(address[] calldata validators_) external view returns (string[] memory);

    function getStakeAmount() external view returns (uint256);

    function getMaxNumValidators() external view returns (uint256);

    function getDisputerReward() external view returns (uint256);

    function tryGetTokenID(address account_) external view returns (bool, address, uint256);

    function isValidator(address participant) external view returns (bool);

    function isInExitingQueue(address participant) external view returns (bool);

    function isAccusable(address participant) external view returns (bool);

    function isMaintenanceScheduled() external view returns (bool);

    function isConsensusRunning() external view returns (bool);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MerkleProofLibrary.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/libraries/parsers/PClaimsParserLibrary.sol";
import "contracts/libraries/parsers/RCertParserLibrary.sol";
import "contracts/libraries/parsers/MerkleProofParserLibrary.sol";
import "contracts/libraries/parsers/TXInPreImageParserLibrary.sol";
import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/AccusationsLibrary.sol";
import "contracts/libraries/errors/AccusationsErrors.sol";

/// @custom:salt-type Accusation
/// @custom:salt InvalidTxConsumptionAccusation
/// @custom:deploy-type deployUpgradeable
contract InvalidTxConsumptionAccusation is
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutableValidatorPool
{
    mapping(bytes32 => bool) internal _accusations;

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutableValidatorPool()
    {}

    /**
     * @notice This function validates an accusation of non-existent utxo consumption, as well as invalid deposit consumption.
     * @param pClaims_ the PClaims of the accusation
     * @param pClaimsSig_ the signature of PClaims
     * @param bClaims_ the BClaims of the accusation
     * @param bClaimsSigGroup_ the signature group of BClaims
     * @param txInPreImage_ the TXInPreImage consuming the invalid transaction
     * @param proofs_ an array of merkle proof structs in the following order:
     * proof against StateRoot: Proof of inclusion or exclusion of the deposit or UTXO in the stateTrie
     * proof of inclusion in TXRoot: Proof of inclusion of the transaction that included the invalid input in the txRoot trie.
     * proof of inclusion in TXHash: Proof of inclusion of the invalid input (txIn) in the txHash trie (transaction tested against the TxRoot).
     * @return the address of the signer
     */
    function accuseInvalidTransactionConsumption(
        bytes memory pClaims_,
        bytes memory pClaimsSig_,
        bytes memory bClaims_,
        bytes memory bClaimsSigGroup_,
        bytes memory txInPreImage_,
        bytes[3] memory proofs_
    ) public view returns (address) {
        // Require that the previous block is signed by correct group key for validator set.
        _verifySignatureGroup(bClaims_, bClaimsSigGroup_);

        // Require that height delta is 1.
        BClaimsParserLibrary.BClaims memory bClaims = BClaimsParserLibrary.extractBClaims(bClaims_);
        PClaimsParserLibrary.PClaims memory pClaims = PClaimsParserLibrary.extractPClaims(pClaims_);

        if (pClaims.bClaims.txCount == 0) {
            revert AccusationsErrors.NoTransactionInAccusedProposal();
        }

        if (bClaims.height + 1 != pClaims.bClaims.height) {
            revert AccusationsErrors.HeightDeltaShouldBeOne(bClaims.height, pClaims.bClaims.height);
        }

        Snapshot memory latestSnapshot = ISnapshots(_snapshotsAddress()).getLatestSnapshot();
        uint256 epochLength = ISnapshots(_snapshotsAddress()).getEpochLength();

        // if the current PClaims height is greater than 1 epoch from the latest snapshot or it's is
        // older than 2 epochs in the past, the accusation is invalid
        if (
            pClaims.bClaims.height > latestSnapshot.blockClaims.height + epochLength ||
            pClaims.bClaims.height + 2 * epochLength < latestSnapshot.blockClaims.height
        ) {
            revert AccusationsErrors.ExpiredAccusation(
                pClaims.bClaims.height,
                latestSnapshot.blockClaims.height,
                epochLength
            );
        }

        // Require that chainID is equal.
        if (
            bClaims.chainId != pClaims.bClaims.chainId ||
            bClaims.chainId != latestSnapshot.blockClaims.chainId
        ) {
            revert AccusationsErrors.ChainIdDoesNotMatch(
                bClaims.chainId,
                pClaims.bClaims.chainId,
                latestSnapshot.blockClaims.chainId
            );
        }

        // Require that Proposal was signed by active validator.
        address signerAccount = AccusationsLibrary.recoverMadNetSigner(pClaimsSig_, pClaims_);

        if (!IValidatorPool(_validatorPoolAddress()).isAccusable(signerAccount)) {
            revert AccusationsErrors.SignerNotValidValidator(signerAccount);
        }

        // Validate ProofInclusionTxRoot against PClaims.BClaims.TxRoot.
        MerkleProofParserLibrary.MerkleProof memory proofInclusionTxRoot = MerkleProofParserLibrary
            .extractMerkleProof(proofs_[1]);
        MerkleProofLibrary.verifyInclusion(proofInclusionTxRoot, pClaims.bClaims.txRoot);

        // Validate ProofOfInclusionTxHash against the target hash from ProofInclusionTxRoot.
        MerkleProofParserLibrary.MerkleProof
            memory proofOfInclusionTxHash = MerkleProofParserLibrary.extractMerkleProof(proofs_[2]);
        MerkleProofLibrary.verifyInclusion(proofOfInclusionTxHash, proofInclusionTxRoot.key);

        MerkleProofParserLibrary.MerkleProof memory proofAgainstStateRoot = MerkleProofParserLibrary
            .extractMerkleProof(proofs_[0]);
        if (proofAgainstStateRoot.key != proofOfInclusionTxHash.key) {
            revert AccusationsErrors.UTXODoesnotMatch(
                proofAgainstStateRoot.key,
                proofOfInclusionTxHash.key
            );
        }

        TXInPreImageParserLibrary.TXInPreImage memory txInPreImage = TXInPreImageParserLibrary
            .extractTXInPreImage(txInPreImage_);

        // checking if we are consuming a deposit or an UTXO
        if (txInPreImage.consumedTxIdx == 0xFFFFFFFF) {
            // Double spending problem, i.e, consuming a deposit that was already consumed
            if (txInPreImage.consumedTxHash != proofAgainstStateRoot.key) {
                revert AccusationsErrors.MerkleProofKeyDoesNotMatchConsumedDepositKey(
                    txInPreImage.consumedTxHash,
                    proofAgainstStateRoot.key
                );
            }
            MerkleProofLibrary.verifyInclusion(proofAgainstStateRoot, bClaims.stateRoot);
            // todo: deposit that doesn't exist in the chain. Maybe split this in separate functions?
        } else {
            // Consuming a non existing UTXO
            {
                bytes32 computedUTXOID = AccusationsLibrary.computeUTXOID(
                    txInPreImage.consumedTxHash,
                    txInPreImage.consumedTxIdx
                );
                if (computedUTXOID != proofAgainstStateRoot.key) {
                    revert AccusationsErrors.MerkleProofKeyDoesNotMatchUTXOIDBeingSpent(
                        computedUTXOID,
                        proofAgainstStateRoot.key
                    );
                }
            }
            MerkleProofLibrary.verifyNonInclusion(proofAgainstStateRoot, bClaims.stateRoot);
        }

        //todo burn the validator's tokens
        return signerAccount;
    }

    /**
     * @notice This function verifies the signature group of a BClaims.
     * @param bClaims_ the BClaims of the accusation
     * @param bClaimsSigGroup_ the signature group of Pclaims
     */
    function _verifySignatureGroup(
        bytes memory bClaims_,
        bytes memory bClaimsSigGroup_
    ) internal view {
        uint256[4] memory publicKey;
        uint256[2] memory signature;
        (publicKey, signature) = RCertParserLibrary.extractSigGroup(bClaimsSigGroup_, 0);

        bytes32 mpkHash = keccak256(abi.encodePacked(publicKey));
        if (!IETHDKG(_ethdkgAddress()).isValidMasterPublicKey(mpkHash)) {
            revert AccusationsErrors.InvalidMasterPublicKey(mpkHash);
        }

        if (
            !CryptoLibrary.verifySignatureASM(
                abi.encodePacked(keccak256(bClaims_)),
                signature,
                publicKey
            )
        ) {
            revert AccusationsErrors.SignatureVerificationFailed();
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import {DoublyLinkedListErrors} from "contracts/libraries/errors/DoublyLinkedListErrors.sol";

struct Node {
    uint32 epoch;
    uint32 next;
    uint32 prev;
    address data;
}

struct DoublyLinkedList {
    uint128 head;
    uint128 tail;
    mapping(uint256 => Node) nodes;
    uint256 totalNodes;
}

library NodeUpdate {
    /***
     * @dev Update a Node previous and next nodes epochs.
     * @param prevEpoch: the previous epoch to link into the node
     * @param nextEpoch: the next epoch to link into the node
     */
    function update(
        Node memory node,
        uint32 prevEpoch,
        uint32 nextEpoch
    ) internal pure returns (Node memory) {
        node.prev = prevEpoch;
        node.next = nextEpoch;
        return node;
    }

    /**
     * @dev Update a Node previous epoch.
     * @param prevEpoch: the previous epoch to link into the node
     */
    function updatePrevious(
        Node memory node,
        uint32 prevEpoch
    ) internal pure returns (Node memory) {
        node.prev = prevEpoch;
        return node;
    }

    /**
     * @dev Update a Node next epoch.
     * @param nextEpoch: the next epoch to link into the node
     */
    function updateNext(Node memory node, uint32 nextEpoch) internal pure returns (Node memory) {
        node.next = nextEpoch;
        return node;
    }
}

library DoublyLinkedListLogic {
    using NodeUpdate for Node;

    /**
     * @dev Insert a new Node in the `epoch` position with `data` address in the data field.
            This function fails if epoch is smaller or equal than the current tail, if
            the data field is the zero address or if a node already exists at `epoch`.
     * @param epoch: The epoch to insert the new node
     * @param data: The data to insert into the new node
     */
    function addNode(DoublyLinkedList storage list, uint32 epoch, address data) internal {
        uint32 head = uint32(list.head);
        uint32 tail = uint32(list.tail);
        // at this moment, we are only appending after the tail. This requirement can be
        // removed in future versions.
        if (epoch <= tail) {
            revert DoublyLinkedListErrors.InvalidNodeId(head, tail, epoch);
        }
        if (exists(list, epoch)) {
            revert DoublyLinkedListErrors.ExistentNodeAtPosition(epoch);
        }
        if (data == address(0)) {
            revert DoublyLinkedListErrors.InvalidData();
        }
        Node memory node = createNode(epoch, data);
        // initialization case
        if (head == 0) {
            list.nodes[epoch] = node;
            setHead(list, epoch);
            // if head is 0, then the tail is also 0 and should be also initialized
            setTail(list, epoch);
            list.totalNodes++;
            return;
        }
        list.nodes[epoch] = node.updatePrevious(tail);
        linkNext(list, tail, epoch);
        setTail(list, epoch);
        list.totalNodes++;
    }

    /***
     * @dev Function to update the Head pointer.
     * @param epoch The epoch value to set as the head pointer
     */
    function setHead(DoublyLinkedList storage list, uint128 epoch) internal {
        if (!exists(list, epoch)) {
            revert DoublyLinkedListErrors.InexistentNodeAtPosition(epoch);
        }
        list.head = epoch;
    }

    /***
     * @dev Function to update the Tail pointer.
     * @param epoch The epoch value to set as the tail pointer
     */
    function setTail(DoublyLinkedList storage list, uint128 epoch) internal {
        if (!exists(list, epoch)) {
            revert DoublyLinkedListErrors.InexistentNodeAtPosition(epoch);
        }
        list.tail = epoch;
    }

    /***
     * @dev Internal function to link an Node to its next node.
     * @param prevEpoch: The node's epoch to link the next epoch.
     * @param nextEpoch: The epoch that will be assigned to the linked node.
     */
    function linkNext(DoublyLinkedList storage list, uint32 prevEpoch, uint32 nextEpoch) internal {
        list.nodes[prevEpoch].next = nextEpoch;
    }

    /***
     * @dev Internal function to link an Node to its previous node.
     * @param nextEpoch: The node's epoch to link the previous epoch.
     * @param prevEpoch: The epoch that will be assigned to the linked node.
     */
    function linkPrevious(
        DoublyLinkedList storage list,
        uint32 nextEpoch,
        uint32 prevEpoch
    ) internal {
        list.nodes[nextEpoch].prev = prevEpoch;
    }

    /**
     * @dev Retrieves the head.
     */
    function getHead(DoublyLinkedList storage list) internal view returns (uint256) {
        return list.head;
    }

    /**
     * @dev Retrieves the tail.
     */
    function getTail(DoublyLinkedList storage list) internal view returns (uint256) {
        return list.tail;
    }

    /**
     * @dev Retrieves the Node denoted by `epoch`.
     * @param epoch: The epoch to get the node.
     */
    function getNode(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (Node memory) {
        return list.nodes[epoch];
    }

    /**
     * @dev Retrieves the Node value denoted by `epoch`.
     * @param epoch: The epoch to get the node's value.
     */
    function getValue(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (address) {
        return list.nodes[epoch].data;
    }

    /**
     * @dev Retrieves the next epoch of a Node denoted by `epoch`.
     * @param epoch: The epoch to get the next node epoch.
     */
    function getNextEpoch(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (uint32) {
        return list.nodes[epoch].next;
    }

    /**
     * @dev Retrieves the previous epoch of a Node denoted by `epoch`.
     * @param epoch: The epoch to get the previous node epoch.
     */
    function getPreviousEpoch(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (uint32) {
        return list.nodes[epoch].prev;
    }

    /**
     * @dev Checks if a node is inserted into the list at the specified `epoch`.
     * @param epoch: The epoch to check for existence
     */
    function exists(DoublyLinkedList storage list, uint256 epoch) internal view returns (bool) {
        return list.nodes[epoch].data != address(0);
    }

    /**
     * @dev function to create a new node Object.
     */
    function createNode(uint32 epoch, address data) internal pure returns (Node memory) {
        return Node(epoch, 0, 0, data);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library AccusationsErrors {
    error NoTransactionInAccusedProposal();
    error HeightDeltaShouldBeOne(uint256 bClaimsHeight, uint256 pClaimsHeight);
    error PClaimsHeightsDoNotMatch(uint256 pClaims0Height, uint256 pClaims1Height);
    error ChainIdDoesNotMatch(
        uint256 bClaimsChainId,
        uint256 pClaimsChainId,
        uint256 snapshotsChainId
    );
    error SignersDoNotMatch(address signer1, address signer2);
    error SignerNotValidValidator(address signer);
    error UTXODoesnotMatch(bytes32 proofAgainstStateRootKey, bytes32 proofOfInclusionTxHashKey);
    error PClaimsRoundsDoNotMatch(uint32 pClaims0Round, uint32 pClaims1Round);
    error PClaimsChainIdsDoNotMatch(uint256 pClaims0ChainId, uint256 pClaims1ChainId);
    error InvalidChainId(uint256 pClaimsChainId, uint256 expectedChainId);
    error MerkleProofKeyDoesNotMatchConsumedDepositKey(
        bytes32 proofOfInclusionTxHashKey,
        bytes32 proofAgainstStateRootKey
    );
    error MerkleProofKeyDoesNotMatchUTXOIDBeingSpent(
        bytes32 utxoId,
        bytes32 proofAgainstStateRootKey
    );
    error SignatureVerificationFailed();
    error PClaimsAreEqual();
    error SignatureLengthMustBe65Bytes(uint256 signatureLength);
    error InvalidSignatureVersion(uint8 signatureVersion);
    error ExpiredAccusation(uint256 accusationHeight, uint256 latestSnapshotHeight, uint256 epoch);
    error InvalidMasterPublicKey(bytes32 signature);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library AdminErrors {
    error SenderNotAdmin(address sender);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library AliceNetFactoryBaseErrors {
    error Unauthorized();
    error CodeSizeZero();
    error SaltAlreadyInUse(bytes32 salt);
    error IncorrectProxyImplementation(address current, address expected);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library Base64Errors {
    error InvalidDecoderInput(uint256 inputLength);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BaseParserLibraryErrors {
    error OffsetParameterOverflow(uint256 offset);
    error OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error LEUint16OffsetParameterOverflow(uint256 offset);
    error LEUint16OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BEUint16OffsetParameterOverflow(uint256 offset);
    error BEUint16OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BooleanOffsetParameterOverflow(uint256 offset);
    error BooleanOffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error LEUint256OffsetParameterOverflow(uint256 offset);
    error LEUint256OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BEUint256OffsetParameterOverflow(uint256 offset);
    error BEUint256OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BytesOffsetParameterOverflow(uint256 offset);
    error BytesOffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error Bytes32OffsetParameterOverflow(uint256 offset);
    error Bytes32OffsetOutOfBounds(uint256 offset, uint256 srcLength);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BClaimsParserLibraryErrors {
    error SizeThresholdExceeded(uint16 dataSectionSize);
    error DataOffsetOverflow(uint256 dataOffset);
    error NotEnoughBytes(uint256 dataOffset, uint256 srcLength);
    error ChainIdZero();
    error HeightZero();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BridgePoolFactoryErrors {
    error FailedToDeployLogic();
    error PoolVersionNotSupported(uint16 version);
    error StaticPoolDeploymentFailed(bytes32 salt_);
    error UnexistentBridgePoolImplementationVersion(uint16 version);
    error UnableToDeployBridgePool(bytes32 salt_);
    error InsufficientFunds();
    error PublicPoolDeploymentTemporallyDisabled();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library CircuitBreakerErrors {
    error CircuitBreakerOpened();
    error CircuitBreakerClosed();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library CryptoLibraryErrors {
    error EllipticCurveAdditionFailed();
    error EllipticCurveMultiplicationFailed();
    error ModularExponentiationFailed();
    error EllipticCurvePairingFailed();
    error HashPointNotOnCurve();
    error HashPointUnsafeForSigning();
    error PointNotOnCurve();
    error SignatureIndicesLengthMismatch(uint256 signaturesLength, uint256 indicesLength);
    error SignaturesLengthThresholdNotMet(uint256 signaturesLength, uint256 threshold);
    error InverseArrayIncorrect();
    error InvalidInverseArrayLength();
    error KMustNotEqualJ();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library CustomEnumerableMapsErrors {
    error KeyNotInMap(address key);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library DistributionErrors {
    error SplitValueSumError();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library DoublyLinkedListErrors {
    error InvalidNodeId(uint256 head, uint256 tail, uint256 id);
    error ExistentNodeAtPosition(uint256 id);
    error InexistentNodeAtPosition(uint256 id);
    error InvalidData();
    error InvalidNodeInsertion(uint256 head, uint256 tail, uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IDynamics.sol";

library DynamicsErrors {
    error InvalidScheduledDate(
        uint256 scheduledDate,
        uint256 minScheduledDate,
        uint256 maxScheduledDate
    );
    error InvalidExtCodeSize(address addr, uint256 codeSize);
    error DynamicValueNotFound(uint256 epoch);
    error InvalidAliceNetNodeHash(bytes32 sentHash, bytes32 currentHash);
    error InvalidAliceNetNodeVersion(CanonicalVersion newVersion, CanonicalVersion current);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ERC20SafeTransferErrors {
    error CannotCallContractMethodsOnZeroAddress();
    error Erc20TransferFailed(address erc20Address, address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/ethdkg/ETHDKGStorage.sol";

library ETHDKGErrors {
    error OnlyValidatorsAllowed(address sender);
    error VariableNotSettableWhileETHDKGRunning();
    error MinimumValidatorsNotMet(uint256 currentValidatorsLength);
    error IncorrectPhase(
        Phase currentPhase,
        uint256 currentBlockNumber,
        PhaseInformation[] expectedPhases
    );
    error AccusedNotValidator(address accused);
    error AccusedParticipatingInRound(address accused);
    error AccusedNotParticipatingInRound(address accused);
    error AccusedDistributedSharesInRound(address accused);
    error AccusedHasCommitments(address accused);
    error DisputerNotParticipatingInRound(address disputer);
    error AccusedDidNotDistributeSharesInRound(address accused);
    error DisputerDidNotDistributeSharesInRound(address disputer);
    error SharesAndCommitmentsMismatch(bytes32 expected, bytes32 actual);
    error InvalidKeyOrProof();
    error AccusedSubmittedSharesInRound(address accused);
    error AccusedDidNotParticipateInGPKJSubmission(address accused);
    error AccusedDistributedGPKJ(address accused);
    error AccusedDidNotSubmitGPKJInRound(address accused);
    error DisputerDidNotSubmitGPKJInRound(address disputer);
    error ArgumentsLengthDoesNotEqualNumberOfParticipants(
        uint256 validatorsLength,
        uint256 encryptedSharesHashLength,
        uint256 commitmentsLength,
        uint256 numParticipants
    );
    error InvalidCommitments(uint256 commitmentsLength, uint256 expectedCommitmentsLength);
    error InvalidOrDuplicatedParticipant(address participant);
    error InvalidSharesOrCommitments(bytes32 expectedHash, bytes32 actualHash);
    error PublicKeyZero();
    error PublicKeyNotOnCurve();
    error ParticipantParticipatingInRound(
        address participant,
        uint256 participantNonce,
        uint256 maxExpectedNonce
    );
    error InvalidNonce(uint256 participantNonce, uint256 nonce);
    error ParticipantDistributedSharesInRound(address participant);
    error InvalidEncryptedSharesAmount(uint256 sharesLength, uint256 expectedSharesLength);
    error InvalidCommitmentsAmount(uint256 commitmentsLength, uint256 expectedCommitmentsLength);
    error CommitmentNotOnCurve();
    error CommitmentZero();
    error DistributedShareHashZero();
    error ParticipantSubmittedKeysharesInRound(address participant);
    error InvalidKeyshareG1();
    error InvalidKeyshareG2();
    error MasterPublicKeyPairingCheckFailure();
    error ParticipantSubmittedGPKJInRound(address participant);
    error GPKJZero();
    error ETHDKGRequisitesIncomplete();
    error MigrationRequiresZeroNonce(uint256 nonce);
    error MigrationInputDataMismatch(
        uint256 validatorsAccountsLength,
        uint256 validatorIndexesLength,
        uint256 validatorSharesLength
    );
    error ParticipantNotFoundInLastRound(address addr);
    error ETHDKGSubContractNotSet();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ETHSafeTransferErrors {
    error CannotTransferToZeroAddress();
    error EthTransferFailed(address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library GenericParserLibraryErrors {
    error DataOffsetOverflow();
    error InsufficientBytes(uint256 bytesLength, uint256 requiredBytesLength);
    error ChainIdZero();
    error HeightZero();
    error RoundZero();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library GovernanceErrors {
    error OnlyFactoryAllowed(address sender);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library LockupErrors {
    error AddressNotAllowedToSendEther();
    error OnlyStakingNFTAllowed();
    error ContractDoesNotOwnTokenID(uint256 tokenID_);
    error AddressAlreadyLockedUp();
    error TokenIDAlreadyClaimed(uint256 tokenID_);
    error InsufficientBalanceForEarlyExit(uint256 exitValue, uint256 currentBalance);
    error UserHasNoPosition();
    error PreLockStateRequired();
    error PreLockStateNotAllowed();
    error PostLockStateNotAllowed();
    error PostLockStateRequired();
    error PayoutUnsafe();
    error PayoutSafe();
    error TokenIDNotLocked(uint256 tokenID_);
    error InvalidPositionWithdrawPeriod(uint256 withdrawFreeAfter, uint256 endBlock);
    error InLockStateRequired();

    error BonusTokenNotCreated();
    error BonusTokenAlreadyCreated();
    error NotEnoughALCAToStake(uint256 currentBalance, uint256 expectedAmount);

    error InvalidTotalSharesValue();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicTokenTransferErrors {
    error TransferFailed(address token, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicValueErrors {
    error BadMagic(uint256 magic);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MerkleProofLibraryErrors {
    error InvalidProofHeight(uint256 proofHeight);
    error InclusionZero();
    error ProofDoesNotMatchTrieRoot();
    error DefaultLeafNotFoundInKeyPath();
    error ProvidedLeafNotFoundInKeyPath();
    error InvalidNonInclusionMerkleProof();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MerkleProofParserLibraryErrors {
    error InvalidProofMinimumSize(uint256 proofSize);
    error InvalidProofSize(uint256 proofSize);
    error InvalidKeyHeight(uint256 keyHeight);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MutexErrors {
    error MutexLocked();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library RegisterValidatorErrors {
    error InvalidNumberOfValidators(
        uint256 validatorsAccountLength,
        uint256 expectedValidatorsAccountLength
    );
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library SnapshotsErrors {
    error OnlyValidatorsAllowed(address caller);
    error ConsensusNotRunning();
    error MinimumBlocksIntervalNotPassed(
        uint256 currentBlocksInterval,
        uint256 minimumBlocksInterval
    );
    error InvalidMasterPublicKey(bytes32 calculatedMasterKeyHash, bytes32 expectedMasterKeyHash);
    error SignatureVerificationFailed();
    error UnexpectedBlockHeight(uint256 givenBlockHeight, uint256 expectedBlockHeight);
    error BlockHeightNotMultipleOfEpochLength(uint256 blockHeight, uint256 epochLength);
    error InvalidChainId(uint256 chainId);
    error MigrationNotAllowedAtCurrentEpoch();
    error MigrationInputDataMismatch(uint256 groupSignatureLength, uint256 bClaimsLength);
    error SnapshotsNotInBuffer(uint256 epoch);
    error ValidatorNotElected(
        uint256 validatorIndex,
        uint256 startIndex,
        uint256 endIndex,
        bytes32 groupSignatureHash
    );
    error InvalidRingBufferBlockHeight(uint256 newBlockHeight, uint256 oldBlockHeight);
    error EpochMustBeNonZero();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library StakingNFTErrors {
    error CallerNotTokenOwner(address caller);
    error LockDurationGreaterThanGovernanceLock();
    error LockDurationGreaterThanMintLock();
    error LockDurationWithdrawTimeNotReached();
    error InvalidTokenId(uint256 tokenId);
    error MintAmountExceedsMaximumSupply();
    error FreeAfterTimeNotReached();
    error BalanceLessThanReserve(uint256 balance, uint256 reserve);
    error SlushTooLarge(uint256 slush);
    error MintAmountZero();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library StakingTokenErrors {
    error InvalidConversionAmount();
    error InvalidAddress();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library UtilityTokenErrors {
    error InvalidDepositId(uint256 depositID);
    error InvalidBalance(uint256 contractBalance, uint256 poolBalance);
    error InvalidBurnAmount(uint256 amount);
    error ContractsDisallowedDeposits(address toAddress);
    error DepositAmountZero();
    error DepositBurnFail(uint256 amount);
    error MinimumValueNotMet(uint256 amount, uint256 minimumValue);
    error InsufficientEth(uint256 amount, uint256 minimum);
    error MinimumMintNotMet(uint256 amount, uint256 minimum);
    error MinimumBurnNotMet(uint256 amount, uint256 minimum);
    error BurnAmountExceedsSupply(uint256 amount, uint256 supply);
    error InexistentRouterContract(address contractAddr);
    error InsufficientFee(uint256 amount, uint256 fee);
    error CannotSetRouterToZeroAddress();
    error AccountTypeNotSupported(uint8 accountType);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ValidatorPoolErrors {
    error CallerNotValidator(address caller);
    error ConsensusRunning();
    error ETHDKGRoundRunning();
    error OnlyStakingContractsAllowed();
    error MaxIntervalWithoutSnapshotsMustBeNonZero();
    error MaxNumValidatorsIsTooLow(uint256 current, uint256 minMaxValidatorsAllowed);
    error MinimumBlockIntervalNotMet(uint256 currentBlockNumber, uint256 targetBlockNumber);
    error NotEnoughValidatorSlotsAvailable(uint256 requiredSlots, uint256 availableSlots);
    error RegistrationParameterLengthMismatch(
        uint256 validatorsLength,
        uint256 stakerTokenIDsLength
    );
    error SenderShouldOwnPosition(uint256 positionId);
    error LengthGreaterThanAvailableValidators(uint256 length, uint256 availableValidators);
    error ProfitsOnlyClaimableWhileConsensusRunning();
    error TokenBalanceChangedDuringOperation();
    error EthBalanceChangedDuringOperation();
    error SenderNotInExitingQueue(address sender);
    error WaitingPeriodNotMet();
    error AddressNotAccusable(address addr);
    error InvalidIndex(uint256 index);
    error AddressAlreadyValidator(address addr);
    error AddressNotValidator(address addr);
    error PayoutTooLow();
    error InsufficientFundsInStakePosition(uint256 stakeAmount, uint256 minimumRequiredAmount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IValidatorPool.sol";
import "contracts/libraries/ethdkg/ETHDKGStorage.sol";
import "contracts/interfaces/IETHDKGEvents.sol";
import "contracts/utils/ETHDKGUtils.sol";
import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/libraries/errors/ETHDKGErrors.sol";

/// @custom:salt ETHDKGAccusations
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group ethdkg
/// @custom:deploy-group-index 0
contract ETHDKGAccusations is ETHDKGStorage, IETHDKGEvents, ETHDKGUtils {
    constructor() ETHDKGStorage() {}

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.RegistrationOpen ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.RegistrationOpen,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;
        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }

            // check if the dishonestParticipant didn't participate in the registration phase,
            // so it doesn't have a Participant object with the latest nonce
            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];
            if (dishonestParticipant.nonce == _nonce) {
                revert ETHDKGErrors.AccusedParticipatingInRound(dishonestAddresses[i]);
            }

            // this makes sure we cannot accuse someone twice because a minor fine will be enough to
            // evict the validator from the pool
            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }
        _badParticipants = badParticipants;
    }

    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.ShareDistribution ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.ShareDistribution,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;

        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }
            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];

            if (dishonestParticipant.nonce != _nonce) {
                revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.phase == Phase.ShareDistribution) {
                revert ETHDKGErrors.AccusedDistributedSharesInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.distributedSharesHash != 0x0) {
                revert ETHDKGErrors.AccusedDistributedSharesInRound(dishonestAddresses[i]);
            }
            if (
                dishonestParticipant.commitmentsFirstCoefficient[0] != 0 ||
                dishonestParticipant.commitmentsFirstCoefficient[1] != 0
            ) {
                revert ETHDKGErrors.AccusedHasCommitments(dishonestAddresses[i]);
            }

            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }

        _badParticipants = badParticipants;
    }

    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) external {
        // We should allow accusation, even if some of the participants didn't participate
        {
            bool isInDisputeShareDistribution = _ethdkgPhase == Phase.DisputeShareDistribution &&
                block.number >= _phaseStartBlock &&
                block.number < _phaseStartBlock + _phaseLength;
            bool isInShareDistribution = _ethdkgPhase == Phase.ShareDistribution &&
                block.number >= _phaseStartBlock + _phaseLength &&
                block.number < _phaseStartBlock + 2 * _phaseLength;
            if (!isInDisputeShareDistribution && !isInShareDistribution) {
                PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](2);
                expectedPhaseInfos[0] = PhaseInformation(
                    Phase.DisputeShareDistribution,
                    _phaseStartBlock,
                    _phaseStartBlock + _phaseLength
                );
                expectedPhaseInfos[1] = PhaseInformation(
                    Phase.ShareDistribution,
                    _phaseStartBlock + _phaseLength,
                    _phaseStartBlock + 2 * _phaseLength
                );
                revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
            }
        }

        if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddress)) {
            revert ETHDKGErrors.AccusedNotValidator(dishonestAddress);
        }

        Participant memory dishonestParticipant = _participants[dishonestAddress];
        Participant memory disputer = _participants[msg.sender];

        if (disputer.nonce != _nonce) {
            revert ETHDKGErrors.DisputerNotParticipatingInRound(msg.sender);
        }

        if (dishonestParticipant.nonce != _nonce) {
            revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddress);
        }

        if (dishonestParticipant.phase != Phase.ShareDistribution) {
            revert ETHDKGErrors.AccusedDidNotDistributeSharesInRound(dishonestAddress);
        }

        if (disputer.phase != Phase.ShareDistribution) {
            revert ETHDKGErrors.DisputerDidNotDistributeSharesInRound(msg.sender);
        }

        if (
            dishonestParticipant.distributedSharesHash !=
            keccak256(
                abi.encodePacked(
                    keccak256(abi.encodePacked(encryptedShares)),
                    keccak256(abi.encodePacked(commitments))
                )
            )
        ) {
            revert ETHDKGErrors.SharesAndCommitmentsMismatch(
                dishonestParticipant.distributedSharesHash,
                keccak256(
                    abi.encodePacked(
                        keccak256(abi.encodePacked(encryptedShares)),
                        keccak256(abi.encodePacked(commitments))
                    )
                )
            );
        }

        if (
            !CryptoLibrary.discreteLogEquality(
                [CryptoLibrary.G1_X, CryptoLibrary.G1_Y],
                disputer.publicKey,
                dishonestParticipant.publicKey,
                sharedKey,
                sharedKeyCorrectnessProof
            )
        ) {
            revert ETHDKGErrors.InvalidKeyOrProof();
        }

        // Since all provided data is valid so far, we load the share and use the verified shared
        // key to decrypt the share for the disputer.
        uint256 share;
        if (disputer.index < dishonestParticipant.index) {
            share = encryptedShares[disputer.index - 1];
        } else {
            share = encryptedShares[disputer.index - 2];
        }
        share ^= uint256(keccak256(abi.encodePacked(sharedKey[0], disputer.index)));

        // Verify the share for it's correctness using the polynomial defined by the commitments.
        // First, the polynomial (in group G1) is evaluated at the disputer's idx.
        uint256 x = disputer.index;
        uint256[2] memory result = commitments[0];
        uint256[2] memory tmp = CryptoLibrary.bn128Multiply(
            [commitments[1][0], commitments[1][1], x]
        );
        result = CryptoLibrary.bn128Add([result[0], result[1], tmp[0], tmp[1]]);
        for (uint256 j = 2; j < commitments.length; j++) {
            x = mulmod(x, disputer.index, CryptoLibrary.GROUP_ORDER);
            tmp = CryptoLibrary.bn128Multiply([commitments[j][0], commitments[j][1], x]);
            result = CryptoLibrary.bn128Add([result[0], result[1], tmp[0], tmp[1]]);
        }
        // Then the result is compared to the point in G1 corresponding to the decrypted share.
        // In this case, either the shared value is invalid, so the dishonestAddress
        // should be burned; otherwise, the share is valid, and whoever
        // submitted this accusation should be burned. In any case, someone
        // will have his stake burned.
        tmp = CryptoLibrary.bn128Multiply([CryptoLibrary.G1_X, CryptoLibrary.G1_Y, share]);
        if (result[0] != tmp[0] || result[1] != tmp[1]) {
            IValidatorPool(_validatorPoolAddress()).majorSlash(dishonestAddress, msg.sender);
        } else {
            IValidatorPool(_validatorPoolAddress()).majorSlash(msg.sender, dishonestAddress);
        }
        _badParticipants++;
    }

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.KeyShareSubmission ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.KeyShareSubmission,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;

        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }

            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];

            if (dishonestParticipant.nonce != _nonce) {
                revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.phase == Phase.KeyShareSubmission) {
                revert ETHDKGErrors.AccusedSubmittedSharesInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.keyShares[0] != 0 || dishonestParticipant.keyShares[1] != 0) {
                revert ETHDKGErrors.AccusedSubmittedSharesInRound(dishonestAddresses[i]);
            }

            // evict the validator that didn't submit his shares
            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }
        _badParticipants = badParticipants;
    }

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.GPKJSubmission ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.GPKJSubmission,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;

        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }
            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];

            if (dishonestParticipant.nonce != _nonce) {
                revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.phase == Phase.GPKJSubmission) {
                revert ETHDKGErrors.AccusedDidNotParticipateInGPKJSubmission(dishonestAddresses[i]);
            }

            // todo: being paranoic, check if we need this or if it's expensive
            if (
                dishonestParticipant.gpkj[0] != 0 ||
                dishonestParticipant.gpkj[1] != 0 ||
                dishonestParticipant.gpkj[2] != 0 ||
                dishonestParticipant.gpkj[3] != 0
            ) {
                revert ETHDKGErrors.AccusedDistributedGPKJ(dishonestAddresses[i]);
            }

            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }

        _badParticipants = badParticipants;
    }

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) external {
        // We should allow accusation, even if some of the participants didn't participate
        {
            bool isInDisputeGPKJSubmission = _ethdkgPhase == Phase.DisputeGPKJSubmission &&
                block.number >= _phaseStartBlock &&
                block.number < _phaseStartBlock + _phaseLength;
            bool isInGPKJSubmission = _ethdkgPhase == Phase.GPKJSubmission &&
                block.number >= _phaseStartBlock + _phaseLength &&
                block.number < _phaseStartBlock + 2 * _phaseLength;
            if (!isInDisputeGPKJSubmission && !isInGPKJSubmission) {
                PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](2);
                expectedPhaseInfos[0] = PhaseInformation(
                    Phase.DisputeGPKJSubmission,
                    _phaseStartBlock,
                    _phaseStartBlock + _phaseLength
                );
                expectedPhaseInfos[1] = PhaseInformation(
                    Phase.GPKJSubmission,
                    _phaseStartBlock + _phaseLength,
                    _phaseStartBlock + 2 * _phaseLength
                );
                revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
            }
        }

        if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddress)) {
            revert ETHDKGErrors.AccusedNotValidator(dishonestAddress);
        }

        Participant memory dishonestParticipant = _participants[dishonestAddress];
        Participant memory disputer = _participants[msg.sender];

        if (
            dishonestParticipant.nonce != _nonce ||
            dishonestParticipant.phase != Phase.GPKJSubmission
        ) {
            revert ETHDKGErrors.AccusedDidNotSubmitGPKJInRound(dishonestAddress);
        }

        if (disputer.nonce != _nonce || disputer.phase != Phase.GPKJSubmission) {
            revert ETHDKGErrors.DisputerDidNotSubmitGPKJInRound(msg.sender);
        }

        uint16 badParticipants = _badParticipants;
        // n is total _participants;
        // t is threshold, so that t+1 is BFT majority.
        uint256 numParticipants = IValidatorPool(_validatorPoolAddress()).getValidatorsCount() +
            badParticipants;
        uint256 threshold = _getThreshold(numParticipants);

        // Begin initial check
        ////////////////////////////////////////////////////////////////////////
        // First, check length of things
        if (
            validators.length != numParticipants ||
            encryptedSharesHash.length != numParticipants ||
            commitments.length != numParticipants
        ) {
            revert ETHDKGErrors.ArgumentsLengthDoesNotEqualNumberOfParticipants(
                validators.length,
                encryptedSharesHash.length,
                commitments.length,
                numParticipants
            );
        }
        {
            uint256 bitMap = 0;
            uint256 nonce = _nonce;
            // Now, ensure sub-arrays are the correct length as well
            for (uint256 k = 0; k < numParticipants; k++) {
                if (commitments[k].length != threshold + 1) {
                    revert ETHDKGErrors.InvalidCommitments(commitments[k].length, threshold + 1);
                }

                bytes32 commitmentsHash = keccak256(abi.encodePacked(commitments[k]));
                Participant memory participant = _participants[validators[k]];
                if (
                    participant.nonce != nonce ||
                    participant.index > type(uint8).max ||
                    _isBitSet(bitMap, uint8(participant.index))
                ) {
                    revert ETHDKGErrors.InvalidOrDuplicatedParticipant(validators[k]);
                }

                if (
                    participant.distributedSharesHash !=
                    keccak256(abi.encodePacked(encryptedSharesHash[k], commitmentsHash))
                ) {
                    revert ETHDKGErrors.InvalidSharesOrCommitments(
                        participant.distributedSharesHash,
                        keccak256(abi.encodePacked(encryptedSharesHash[k], commitmentsHash))
                    );
                }
                bitMap = _setBit(bitMap, uint8(participant.index));
            }
        }

        ////////////////////////////////////////////////////////////////////////
        // End initial check

        // Info for looping computation
        uint256 pow;
        uint256[2] memory gpkjStar;
        uint256[2] memory tmp;
        uint256 idx;

        // Begin computation loop
        //
        // We remember
        //
        //      F_i(x) = C_i0 * C_i1^x * C_i2^(x^2) * ... * C_it^(x^t)
        //             = Prod(C_ik^(x^k), k = 0, 1, ..., t)
        //
        // We now compute gpkj*. We have
        //
        //      gpkj* = Prod(F_i(j), i)
        //            = Prod( Prod(C_ik^(j^k), k = 0, 1, ..., t), i)
        //            = Prod( Prod(C_ik^(j^k), i), k = 0, 1, ..., t)    // Switch order
        //            = Prod( [Prod(C_ik, i)]^(j^k), k = 0, 1, ..., t)  // Move exponentiation outside
        //
        // More explicitly, we have
        //
        //      gpkj* =  Prod(C_i0, i)        *
        //              [Prod(C_i1, i)]^j     *
        //              [Prod(C_i2, i)]^(j^2) *
        //                  ...
        //              [Prod(C_it, i)]^(j^t) *
        //
        ////////////////////////////////////////////////////////////////////////
        // Add constant terms
        gpkjStar = commitments[0][0]; // Store initial constant term
        for (idx = 1; idx < numParticipants; idx++) {
            gpkjStar = CryptoLibrary.bn128Add(
                [gpkjStar[0], gpkjStar[1], commitments[idx][0][0], commitments[idx][0][1]]
            );
        }

        // Add linear term
        tmp = commitments[0][1]; // Store initial linear term
        pow = dishonestParticipant.index;
        for (idx = 1; idx < numParticipants; idx++) {
            tmp = CryptoLibrary.bn128Add(
                [tmp[0], tmp[1], commitments[idx][1][0], commitments[idx][1][1]]
            );
        }
        tmp = CryptoLibrary.bn128Multiply([tmp[0], tmp[1], pow]);
        gpkjStar = CryptoLibrary.bn128Add([gpkjStar[0], gpkjStar[1], tmp[0], tmp[1]]);

        // Loop through higher order terms
        for (uint256 k = 2; k <= threshold; k++) {
            tmp = commitments[0][k]; // Store initial degree k term
            // Increase pow by factor
            pow = mulmod(pow, dishonestParticipant.index, CryptoLibrary.GROUP_ORDER);
            for (idx = 1; idx < numParticipants; idx++) {
                tmp = CryptoLibrary.bn128Add(
                    [tmp[0], tmp[1], commitments[idx][k][0], commitments[idx][k][1]]
                );
            }
            tmp = CryptoLibrary.bn128Multiply([tmp[0], tmp[1], pow]);
            gpkjStar = CryptoLibrary.bn128Add([gpkjStar[0], gpkjStar[1], tmp[0], tmp[1]]);
        }
        ////////////////////////////////////////////////////////////////////////
        // End computation loop

        // We now have gpkj*; we now verify.
        uint256[4] memory gpkj = dishonestParticipant.gpkj;
        bool isValid = CryptoLibrary.bn128CheckPairing(
            [
                gpkjStar[0],
                gpkjStar[1],
                CryptoLibrary.H2_XI,
                CryptoLibrary.H2_X,
                CryptoLibrary.H2_YI,
                CryptoLibrary.H2_Y,
                CryptoLibrary.G1_X,
                CryptoLibrary.G1_Y,
                gpkj[0],
                gpkj[1],
                gpkj[2],
                gpkj[3]
            ]
        );
        if (!isValid) {
            IValidatorPool(_validatorPoolAddress()).majorSlash(dishonestAddress, msg.sender);
        } else {
            IValidatorPool(_validatorPoolAddress()).majorSlash(msg.sender, dishonestAddress);
        }
        badParticipants++;
        _badParticipants = badParticipants;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IETHDKGEvents.sol";
import "contracts/libraries/ethdkg/ETHDKGStorage.sol";
import "contracts/utils/ETHDKGUtils.sol";
import "contracts/libraries/errors/ETHDKGErrors.sol";

/// @custom:salt ETHDKGPhases
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group ethdkg
/// @custom:deploy-group-index 1
contract ETHDKGPhases is ETHDKGStorage, IETHDKGEvents, ETHDKGUtils {
    constructor() ETHDKGStorage() {}

    function register(uint256[2] memory publicKey) external {
        if (
            _ethdkgPhase != Phase.RegistrationOpen ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.RegistrationOpen,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }
        if (publicKey[0] == 0 || publicKey[1] == 0) {
            revert ETHDKGErrors.PublicKeyZero();
        }

        if (!CryptoLibrary.bn128IsOnCurve(publicKey)) {
            revert ETHDKGErrors.PublicKeyNotOnCurve();
        }

        if (_participants[msg.sender].nonce >= _nonce) {
            revert ETHDKGErrors.ParticipantParticipatingInRound(
                msg.sender,
                _participants[msg.sender].nonce,
                _nonce - 1
            );
        }

        uint32 numRegistered = uint32(_numParticipants);
        numRegistered++;
        _participants[msg.sender] = Participant({
            publicKey: publicKey,
            index: numRegistered,
            nonce: _nonce,
            phase: _ethdkgPhase,
            distributedSharesHash: 0x0,
            commitmentsFirstCoefficient: [uint256(0), uint256(0)],
            keyShares: [uint256(0), uint256(0)],
            gpkj: [uint256(0), uint256(0), uint256(0), uint256(0)]
        });

        emit AddressRegistered(msg.sender, numRegistered, _nonce, publicKey);
        if (
            _moveToNextPhase(
                Phase.ShareDistribution,
                IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
                numRegistered
            )
        ) {
            emit RegistrationComplete(block.number);
        }
    }

    function distributeShares(
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments
    ) external {
        if (
            _ethdkgPhase != Phase.ShareDistribution ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.ShareDistribution,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        Participant memory participant = _participants[msg.sender];
        if (participant.nonce != _nonce) {
            revert ETHDKGErrors.InvalidNonce(participant.nonce, _nonce);
        }

        if (participant.phase != Phase.RegistrationOpen) {
            revert ETHDKGErrors.ParticipantDistributedSharesInRound(msg.sender);
        }

        uint256 numValidators = IValidatorPool(_validatorPoolAddress()).getValidatorsCount();
        uint256 threshold = _getThreshold(numValidators);
        if (encryptedShares.length != numValidators - 1) {
            revert ETHDKGErrors.InvalidEncryptedSharesAmount(
                encryptedShares.length,
                numValidators - 1
            );
        }

        if (commitments.length != threshold + 1) {
            revert ETHDKGErrors.InvalidCommitmentsAmount(commitments.length, threshold + 1);
        }
        for (uint256 k = 0; k <= threshold; k++) {
            if (!CryptoLibrary.bn128IsOnCurve(commitments[k])) {
                revert ETHDKGErrors.CommitmentNotOnCurve();
            }
            if (commitments[k][0] == 0) {
                revert ETHDKGErrors.CommitmentZero();
            }
        }

        bytes32 encryptedSharesHash = keccak256(abi.encodePacked(encryptedShares));
        bytes32 commitmentsHash = keccak256(abi.encodePacked(commitments));
        participant.distributedSharesHash = keccak256(
            abi.encodePacked(encryptedSharesHash, commitmentsHash)
        );
        if (participant.distributedSharesHash == 0x0) {
            revert ETHDKGErrors.DistributedShareHashZero();
        }
        participant.commitmentsFirstCoefficient = commitments[0];
        participant.phase = Phase.ShareDistribution;

        _participants[msg.sender] = participant;
        uint256 numParticipants = _numParticipants + 1;

        emit SharesDistributed(
            msg.sender,
            participant.index,
            participant.nonce,
            encryptedShares,
            commitments
        );

        if (_moveToNextPhase(Phase.DisputeShareDistribution, numValidators, numParticipants)) {
            emit ShareDistributionComplete(block.number);
        }
    }

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) external {
        // Only progress if all participants distributed their shares
        // and no bad participant was found
        {
            bool isInKeyShareSubmission = _ethdkgPhase == Phase.KeyShareSubmission &&
                block.number >= _phaseStartBlock &&
                block.number < _phaseStartBlock + _phaseLength;
            bool isInDisputeShareDistribution = _ethdkgPhase == Phase.DisputeShareDistribution &&
                block.number >= _phaseStartBlock + _phaseLength &&
                block.number < _phaseStartBlock + 2 * _phaseLength &&
                _badParticipants == 0;
            if (!isInKeyShareSubmission && !isInDisputeShareDistribution) {
                PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](2);
                expectedPhaseInfos[0] = PhaseInformation(
                    Phase.KeyShareSubmission,
                    _phaseStartBlock,
                    _phaseStartBlock + _phaseLength
                );
                expectedPhaseInfos[1] = PhaseInformation(
                    Phase.DisputeShareDistribution,
                    _phaseStartBlock + _phaseLength,
                    _phaseStartBlock + 2 * _phaseLength
                );
                revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
            }
        }

        // Since we had a dispute stage prior this state we need to set global state in here
        if (_ethdkgPhase != Phase.KeyShareSubmission) {
            _setPhase(Phase.KeyShareSubmission);
        }
        Participant memory participant = _participants[msg.sender];
        if (participant.nonce != _nonce) {
            revert ETHDKGErrors.InvalidNonce(participant.nonce, _nonce);
        }
        if (participant.phase != Phase.ShareDistribution) {
            revert ETHDKGErrors.ParticipantSubmittedKeysharesInRound(msg.sender);
        }

        if (
            !CryptoLibrary.discreteLogEquality(
                [CryptoLibrary.H1_X, CryptoLibrary.H1_Y],
                keyShareG1,
                [CryptoLibrary.G1_X, CryptoLibrary.G1_Y],
                participant.commitmentsFirstCoefficient,
                keyShareG1CorrectnessProof
            )
        ) {
            revert ETHDKGErrors.InvalidKeyshareG1();
        }

        if (
            !CryptoLibrary.bn128CheckPairing(
                [
                    keyShareG1[0],
                    keyShareG1[1],
                    CryptoLibrary.H2_XI,
                    CryptoLibrary.H2_X,
                    CryptoLibrary.H2_YI,
                    CryptoLibrary.H2_Y,
                    CryptoLibrary.H1_X,
                    CryptoLibrary.H1_Y,
                    keyShareG2[0],
                    keyShareG2[1],
                    keyShareG2[2],
                    keyShareG2[3]
                ]
            )
        ) {
            revert ETHDKGErrors.InvalidKeyshareG2();
        }

        participant.keyShares = keyShareG1;
        participant.phase = Phase.KeyShareSubmission;
        _participants[msg.sender] = participant;

        uint256 numParticipants = _numParticipants + 1;
        uint256[2] memory mpkG1;
        if (numParticipants > 1) {
            mpkG1 = _mpkG1;
        }
        _mpkG1 = CryptoLibrary.bn128Add(
            [mpkG1[0], mpkG1[1], participant.keyShares[0], participant.keyShares[1]]
        );

        emit KeyShareSubmitted(
            msg.sender,
            participant.index,
            participant.nonce,
            keyShareG1,
            keyShareG1CorrectnessProof,
            keyShareG2
        );

        if (
            _moveToNextPhase(
                Phase.MPKSubmission,
                IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
                numParticipants
            )
        ) {
            emit KeyShareSubmissionComplete(block.number);
        }
    }

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) external {
        if (
            _ethdkgPhase != Phase.MPKSubmission ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.MPKSubmission,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }
        uint256[2] memory mpkG1 = _mpkG1;
        if (
            !CryptoLibrary.bn128CheckPairing(
                [
                    mpkG1[0],
                    mpkG1[1],
                    CryptoLibrary.H2_XI,
                    CryptoLibrary.H2_X,
                    CryptoLibrary.H2_YI,
                    CryptoLibrary.H2_Y,
                    CryptoLibrary.H1_X,
                    CryptoLibrary.H1_Y,
                    masterPublicKey_[0],
                    masterPublicKey_[1],
                    masterPublicKey_[2],
                    masterPublicKey_[3]
                ]
            )
        ) {
            revert ETHDKGErrors.MasterPublicKeyPairingCheckFailure();
        }

        _masterPublicKey = masterPublicKey_;
        _masterPublicKeyHash = keccak256(abi.encodePacked(masterPublicKey_));

        _setPhase(Phase.GPKJSubmission);
        emit MPKSet(block.number, _nonce, masterPublicKey_);
    }

    function submitGPKJ(uint256[4] memory gpkj) external {
        //todo: should we evict all validators if no one sent the master public key in time?
        if (
            _ethdkgPhase != Phase.GPKJSubmission ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.GPKJSubmission,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        Participant memory participant = _participants[msg.sender];

        if (participant.nonce != _nonce) {
            revert ETHDKGErrors.InvalidNonce(participant.nonce, _nonce);
        }
        if (participant.phase != Phase.KeyShareSubmission) {
            revert ETHDKGErrors.ParticipantSubmittedGPKJInRound(msg.sender);
        }

        if (gpkj[0] == 0 && gpkj[1] == 0 && gpkj[2] == 0 && gpkj[3] == 0) {
            revert ETHDKGErrors.GPKJZero();
        }

        participant.gpkj = gpkj;
        participant.phase = Phase.GPKJSubmission;
        _participants[msg.sender] = participant;

        emit ValidatorMemberAdded(
            msg.sender,
            participant.index,
            participant.nonce,
            ISnapshots(_snapshotsAddress()).getEpoch(),
            participant.gpkj[0],
            participant.gpkj[1],
            participant.gpkj[2],
            participant.gpkj[3]
        );

        uint256 numParticipants = _numParticipants + 1;
        if (
            _moveToNextPhase(
                Phase.DisputeGPKJSubmission,
                IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
                numParticipants
            )
        ) {
            emit GPKJSubmissionComplete(block.number);
        }
    }

    function complete() external {
        //todo: should we reward ppl here?
        if (
            _ethdkgPhase != Phase.DisputeGPKJSubmission ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.DisputeGPKJSubmission,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }
        if (_badParticipants != 0) {
            revert ETHDKGErrors.ETHDKGRequisitesIncomplete();
        }

        // Since we had a dispute stage prior this state we need to set global state in here
        _setPhase(Phase.Completion);

        // add the current master public key in the registry
        _masterPublicKeyRegistry[_masterPublicKeyHash] = true;

        IValidatorPool(_validatorPoolAddress()).completeETHDKG();

        uint256 epoch = ISnapshots(_snapshotsAddress()).getEpoch();
        uint256 ethHeight = ISnapshots(_snapshotsAddress()).getCommittedHeightFromLatestSnapshot();
        uint256 aliceNetHeight;
        if (_customAliceNetHeight == 0) {
            aliceNetHeight = ISnapshots(_snapshotsAddress()).getAliceNetHeightFromLatestSnapshot();
        } else {
            aliceNetHeight = _customAliceNetHeight;
            _customAliceNetHeight = 0;
        }
        emit ValidatorSetCompleted(
            uint8(IValidatorPool(_validatorPoolAddress()).getValidatorsCount()),
            _nonce,
            epoch,
            ethHeight,
            aliceNetHeight,
            _masterPublicKey[0],
            _masterPublicKey[1],
            _masterPublicKey[2],
            _masterPublicKey[3]
        );
    }

    function getMyAddress() public view returns (address) {
        return address(this);
    }

    function _setPhase(Phase phase_) internal {
        _ethdkgPhase = phase_;
        _phaseStartBlock = uint64(block.number);
        _numParticipants = 0;
    }

    function _moveToNextPhase(
        Phase phase_,
        uint256 numValidators_,
        uint256 numParticipants_
    ) internal returns (bool) {
        // if all validators have registered, we can proceed to the next phase
        if (numParticipants_ == numValidators_) {
            _setPhase(phase_);
            _phaseStartBlock += _confirmationLength;
            return true;
        } else {
            _numParticipants = uint32(numParticipants_);
            return false;
        }
    }

    function _isMasterPublicKeySet() internal view returns (bool) {
        return ((_masterPublicKey[0] != 0) ||
            (_masterPublicKey[1] != 0) ||
            (_masterPublicKey[2] != 0) ||
            (_masterPublicKey[3] != 0));
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

enum Phase {
    RegistrationOpen,
    ShareDistribution,
    DisputeShareDistribution,
    KeyShareSubmission,
    MPKSubmission,
    GPKJSubmission,
    DisputeGPKJSubmission,
    Completion
}

// State of key generation
struct Participant {
    uint256[2] publicKey;
    uint64 nonce;
    uint64 index;
    Phase phase;
    bytes32 distributedSharesHash;
    uint256[2] commitmentsFirstCoefficient;
    uint256[2] keyShares;
    uint256[4] gpkj;
}

struct PhaseInformation {
    Phase phase;
    uint64 startBlock;
    uint64 endBlock;
}

abstract contract ETHDKGStorage is
    Initializable,
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableValidatorPool
{
    uint256 internal constant _MIN_VALIDATORS = 4;

    uint64 internal _nonce;
    uint64 internal _phaseStartBlock;
    Phase internal _ethdkgPhase;
    uint32 internal _numParticipants;
    uint16 internal _badParticipants;
    uint16 internal _phaseLength;
    uint16 internal _confirmationLength;

    // AliceNet height used to start the new validator set in arbitrary height points if the AliceNet
    // Consensus is halted
    uint256 internal _customAliceNetHeight;

    uint256[4] internal _masterPublicKey;
    uint256[2] internal _mpkG1;
    bytes32 internal _masterPublicKeyHash;

    mapping(address => Participant) internal _participants;

    mapping(bytes32 => bool) internal _masterPublicKeyRegistry;

    constructor() ImmutableFactory(msg.sender) ImmutableSnapshots() ImmutableValidatorPool() {}
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/Proxy.sol";
import "contracts/utils/DeterministicAddress.sol";
import "contracts/libraries/proxy/ProxyUpgrader.sol";
import "contracts/libraries/errors/AliceNetFactoryBaseErrors.sol";
import "contracts/libraries/proxy/ProxyImplementationGetter.sol";

abstract contract AliceNetFactoryBase is
    DeterministicAddress,
    ProxyUpgrader,
    ProxyImplementationGetter
{
    using Address for address;

    struct MultiCallArgs {
        address target;
        uint256 value;
        bytes data;
    }

    /**
    @notice owner role for privileged access to functions
    */
    address private _owner;

    /**
    @notice array to store list of contract salts
    */
    bytes32[] private _contracts;

    /**
    @notice slot for storing implementation address
    */
    address private _implementation;

    address private immutable _proxyTemplate;
    /// @notice more details here https://github.com/alicenet/alicenet/wiki/Metamorphic-Proxy-Contract
    bytes8 private constant _UNIVERSAL_DEPLOY_CODE = 0x38585839386009f3;

    mapping(bytes32 => address) internal _contractRegistry;

    /**
     *@notice events that notify of contract deployment
     */
    event Deployed(bytes32 salt, address contractAddr);
    event DeployedTemplate(address contractAddr);
    event DeployedStatic(address contractAddr);
    event DeployedRaw(address contractAddr);
    event DeployedProxy(address contractAddr);
    event UpgradedProxy(bytes32 salt, address proxyAddr, address newlogicAddr);

    // modifier restricts caller to owner or self via multicall
    modifier onlyOwner() {
        _requireAuth(msg.sender == address(this) || msg.sender == owner());
        _;
    }

    /**
     * @notice The constructor encodes the proxy deploy byte code with the _UNIVERSAL_DEPLOY_CODE at the
     * head and the factory address at the tail, and deploys the proxy byte code using create OpCode.
     * The result of this deployment will be a contract with the proxy contract deployment bytecode with
     * its constructor at the head, runtime code in the body and constructor args at the tail. The
     * constructor then sets proxyTemplate_ state var to the deployed proxy template address the deploy
     * account will be set as the first owner of the factory.
     */
    constructor() {
        bytes memory proxyDeployCode = abi.encodePacked(
            //8 byte code copy constructor code
            _UNIVERSAL_DEPLOY_CODE,
            type(Proxy).creationCode,
            bytes32(uint256(uint160(address(this))))
        );
        //variable to store the address created from create(the location of the proxy template contract)
        address addr;
        assembly ("memory-safe") {
            //deploys the proxy template contract
            addr := create(0, add(proxyDeployCode, 0x20), mload(proxyDeployCode))
            if iszero(addr) {
                //if contract creation fails, we want to return any err messages
                returndatacopy(0x00, 0x00, returndatasize())
                //revert and return errors
                revert(0x00, returndatasize())
            }
        }
        //State var that stores the proxyTemplate address
        _proxyTemplate = addr;
        //State var that stores the _owner address
        _owner = msg.sender;
    }

    // solhint-disable payable-fallback
    /**
     * @notice fallback function returns the address of the most recent deployment of a template
     */
    fallback() external {
        assembly ("memory-safe") {
            mstore(0x00, sload(_implementation.slot))
            return(0x00, 0x20)
        }
    }

    /**
     * @notice Allows the owner of the factory to transfer ownership to a new address, for transitioning to decentralization
     * @param newOwner_: address of the new owner
     */
    function setOwner(address newOwner_) public onlyOwner {
        _owner = newOwner_;
    }

    /**
     * @notice lookup allows anyone interacting with the contract to get the address of contract specified
     * by its salt_
     * @param salt_: Custom NatSpec tag @custom:salt at the top of the contract solidity file
     */
    function lookup(bytes32 salt_) public view virtual returns (address) {
        return _lookup(salt_);
    }

    /**
     * @notice getImplementation is a getter function for the _owner account address
     */
    function getImplementation() public view returns (address) {
        return _implementation;
    }

    /**
     * @notice owner is a getter function for the _owner account address
     * @return owner_ address of the owner account
     */
    function owner() public view returns (address owner_) {
        owner_ = _owner;
    }

    /**
     * @notice contracts is a getter that gets the array of salts associated with all the contracts
     * deployed with this factory
     * @return contracts_ the array of salts associated with all the contracts deployed with this
     * factory
     */
    function contracts() public view returns (bytes32[] memory contracts_) {
        contracts_ = _contracts;
    }

    /**
     * @notice getNumContracts getter function for retrieving the total number of contracts
     * deployed with this factory
     * @return the length of the contract array
     */
    function getNumContracts() public view returns (uint256) {
        return _contracts.length;
    }

    /**
     * @notice _callAny allows EOA to call function impersonating the factory address
     * @param target_: the address of the contract to be called
     * @param value_: value in WEIs to send together the call
     * @param cdata_: Hex encoded data with function signature + arguments of the target function to be called
     */
    function _callAny(
        address target_,
        uint256 value_,
        bytes memory cdata_
    ) internal returns (bytes memory) {
        return target_.functionCallWithValue(cdata_, value_);
    }

    /**
     * @notice _deployCreate allows the owner to deploy raw contracts through the factory using
     * non-deterministic address generation (create OpCode)
     * @param deployCode_ Hex encoded data with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function _deployCreate(bytes calldata deployCode_) internal returns (address contractAddr) {
        assembly ("memory-safe") {
            //get the next free pointer
            let basePtr := mload(0x40)
            let ptr := basePtr

            //copies the initialization code of the implementation contract
            calldatacopy(ptr, deployCode_.offset, deployCode_.length)

            //Move the ptr to the end of the code in memory
            ptr := add(ptr, deployCode_.length)

            contractAddr := create(0, basePtr, sub(ptr, basePtr))
        }
        _codeSizeZeroRevert((_extCodeSize(contractAddr) != 0));
        emit DeployedRaw(contractAddr);
        return contractAddr;
    }

    /**
     * @notice _deployCreate2 allows the owner to deploy contracts with deterministic address through the
     * factory
     * @param value_ endowment value in WEIS for the created contract
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @param deployCode_ Hex encoded data with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function _deployCreate2(
        uint256 value_,
        bytes32 salt_,
        bytes calldata deployCode_
    ) internal returns (address contractAddr) {
        assembly ("memory-safe") {
            //get the next free pointer
            let basePtr := mload(0x40)
            let ptr := basePtr

            //copies the initialization code of the implementation contract
            calldatacopy(ptr, deployCode_.offset, deployCode_.length)

            //Move the ptr to the end of the code in memory
            ptr := add(ptr, deployCode_.length)

            contractAddr := create2(value_, basePtr, sub(ptr, basePtr), salt_)
        }
        _codeSizeZeroRevert(uint160(contractAddr) != 0);
        emit DeployedRaw(contractAddr);
    }

    /**
     * @notice _deployProxy deploys a proxy contract with upgradable logic. See Proxy.sol contract.
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     */
    function _deployProxy(bytes32 salt_) internal returns (address contractAddr) {
        address proxyTemplate = _proxyTemplate;
        assembly ("memory-safe") {
            // store proxy template address as implementation,
            sstore(_implementation.slot, proxyTemplate)
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            // put metamorphic code as initCode
            // push1 20
            mstore(ptr, shl(72, 0x6020363636335afa1536363636515af43d36363e3d36f3))
            contractAddr := create2(0, ptr, 0x17, salt_)
        }
        _codeSizeZeroRevert((_extCodeSize(contractAddr) != 0));
        _addNewContract(salt_, contractAddr);
        emit DeployedProxy(contractAddr);
        return contractAddr;
    }

    /**
     * @notice _initializeContract allows the owner/delegator to initialize contracts deployed via factory
     * @param contract_ address of the contract that will be initialized
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * deployed contract
     */
    function _initializeContract(address contract_, bytes calldata initCallData_) internal {
        assembly ("memory-safe") {
            if iszero(iszero(initCallData_.length)) {
                let ptr := mload(0x40)
                mstore(0x40, add(initCallData_.length, ptr))
                calldatacopy(ptr, initCallData_.offset, initCallData_.length)
                if iszero(call(gas(), contract_, 0, ptr, initCallData_.length, 0x00, 0x00)) {
                    ptr := mload(0x40)
                    mstore(0x40, add(returndatasize(), ptr))
                    returndatacopy(ptr, 0x00, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }
    }

    /**
     * @notice _multiCall allows EOA to make multiple function calls within a single transaction
     * impersonating the factory
     * @param cdata_: array of abi encoded data with the function calls (function signature + arguments)
     */
    function _multiCall(MultiCallArgs[] calldata cdata_) internal returns (bytes[] memory results) {
        results = new bytes[](cdata_.length);
        for (uint256 i = 0; i < cdata_.length; i++) {
            results[i] = _callAny(cdata_[i].target, cdata_[i].value, cdata_[i].data);
        }
    }

    /**
     * @notice _upgradeProxy updates the implementation/logic address of an already deployed proxy contract.
     * @param salt_ salt used to determine the final determinist address for the deployed proxy contract
     * @param newImpl_ address of the new contract that contains the new implementation logic
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * new implementation contract
     */
    function _upgradeProxy(bytes32 salt_, address newImpl_, bytes calldata initCallData_) internal {
        address proxy = DeterministicAddress.getMetamorphicContractAddress(salt_, address(this));
        __upgrade(proxy, newImpl_);
        address currentImplementation = __getProxyImplementation(proxy);
        if (currentImplementation != newImpl_) {
            revert AliceNetFactoryBaseErrors.IncorrectProxyImplementation(
                currentImplementation,
                newImpl_
            );
        }
        _initializeContract(proxy, initCallData_);
        emit UpgradedProxy(salt_, proxy, newImpl_);
    }

    /// Internal function to add a new address and "pseudo" salt to the externalContractRegistry
    function _addNewContract(bytes32 salt_, address newContractAddress_) internal {
        if (_contractRegistry[salt_] != address(0)) {
            revert AliceNetFactoryBaseErrors.SaltAlreadyInUse(salt_);
        }
        _contracts.push(salt_);
        _contractRegistry[salt_] = newContractAddress_;
    }

    /**
     * @notice Aux function to return the external code size
     */
    function _extCodeSize(address target_) internal view returns (uint256 size) {
        assembly ("memory-safe") {
            size := extcodesize(target_)
        }
        return size;
    }

    // lookup allows anyone interacting with the contract to get the address of contract specified by
    // its salt_. Returns address(0) in case a contract for that salt was not deployed.
    function _lookup(bytes32 salt_) internal view returns (address) {
        return _contractRegistry[salt_];
    }

    /**
     * @notice _requireAuth reverts if false and returns unauthorized error message
     * @param isOk_ boolean false to cause revert
     */
    function _requireAuth(bool isOk_) internal pure {
        if (!isOk_) {
            revert AliceNetFactoryBaseErrors.Unauthorized();
        }
    }

    /**
     * @notice _codeSizeZeroRevert reverts if false and returns csize0 error message
     * @param isOk_ boolean false to cause revert
     */
    function _codeSizeZeroRevert(bool isOk_) internal pure {
        if (!isOk_) {
            revert AliceNetFactoryBaseErrors.CodeSizeZero();
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/libraries/errors/BridgePoolFactoryErrors.sol";
import "contracts/interfaces/IBridgePool.sol";
import "contracts/utils/BridgePoolAddressUtil.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract BridgePoolFactoryBase is ImmutableFactory {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }
    enum PoolType {
        NATIVE,
        EXTERNAL
    }
    //chainid of layer 1 chain, 1 for ether mainnet
    uint256 internal immutable _chainID;
    bool public publicPoolDeploymentEnabled;
    address internal _implementation;
    mapping(string => address) internal _logicAddresses;
    //mapping of native and external pools to mapping of pool types to most recent version of logic
    mapping(PoolType => mapping(TokenType => uint16)) internal _logicVersionsDeployed;
    //existing pools
    mapping(address => bool) public poolExists;
    event BridgePoolCreated(address poolAddress, address token);

    modifier onlyFactoryOrPublicEnabled() {
        if (msg.sender != _factoryAddress() && !publicPoolDeploymentEnabled) {
            revert BridgePoolFactoryErrors.PublicPoolDeploymentTemporallyDisabled();
        }
        _;
    }

    constructor() ImmutableFactory(msg.sender) {
        _chainID = block.chainid;
    }

    // NativeERC20V!
    /**
     * @notice returns bytecode for a Minimal Proxy (EIP-1167) that routes to BridgePool implementation
     */
    // solhint-disable-next-line
    fallback() external {
        address implementation_ = _implementation;
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, shl(176, 0x363d3d373d3d3d363d73)) //10
            mstore(add(ptr, 10), shl(96, implementation_)) //20
            mstore(add(ptr, 30), shl(136, 0x5af43d82803e903d91602b57fd5bf3)) //15
            return(ptr, 45)
        }
    }

    /**
     * @notice returns the most recent version of the pool logic
     * @param chainId_ native chainID of the token ie 1 for ethereum erc20
     * @param tokenType_ type of token 0 for ERC20 1 for ERC721 and 2 for ERC1155
     */
    function getLatestPoolLogicVersion(
        uint256 chainId_,
        uint8 tokenType_
    ) public view returns (uint16) {
        if (chainId_ != _chainID) {
            return _logicVersionsDeployed[PoolType.EXTERNAL][TokenType(tokenType_)];
        } else {
            return _logicVersionsDeployed[PoolType.NATIVE][TokenType(tokenType_)];
        }
    }

    function _deployPoolLogic(
        uint8 tokenType_,
        uint256 chainId_,
        uint256 value_,
        bytes calldata deployCode_
    ) internal returns (address) {
        address addr;
        uint32 codeSize;
        bool native = true;
        uint16 version;
        bytes memory alicenetFactoryAddress = abi.encodePacked(
            bytes32(uint256(uint160(_factoryAddress())))
        );
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, deployCode_.offset, deployCode_.length)
            // add bytes32 alicenet factory address as parameter to constructor
            mstore(add(ptr, deployCode_.length), alicenetFactoryAddress)
            addr := create(value_, ptr, add(deployCode_.length, 32))
            codeSize := extcodesize(addr)
        }
        if (codeSize == 0) {
            revert BridgePoolFactoryErrors.FailedToDeployLogic();
        }
        if (chainId_ != _chainID) {
            native = false;
            version = _logicVersionsDeployed[PoolType.EXTERNAL][TokenType(tokenType_)] + 1;
            _logicVersionsDeployed[PoolType.EXTERNAL][TokenType(tokenType_)] = version;
        } else {
            version = _logicVersionsDeployed[PoolType.NATIVE][TokenType(tokenType_)] + 1;
            _logicVersionsDeployed[PoolType.NATIVE][TokenType(tokenType_)] = version;
        }
        _logicAddresses[_getImplementationAddressKey(tokenType_, version, native)] = addr;
        return addr;
    }

    /**
     * @dev enables or disables public pool deployment
     **/
    function _togglePublicPoolDeployment() internal {
        publicPoolDeploymentEnabled = !publicPoolDeploymentEnabled;
    }

    /**
     * @notice Deploys a new bridge to pass tokens to layer 2 chain from the specified ERC contract.
     * The pools are created as thin proxies (EIP1167) routing to versioned implementations identified by correspondent salt.
     * @param tokenType_ type of token (0=ERC20, 1=ERC721, 2=ERC1155)
     * @param ercContract_ address of ERC20 source token contract
     * @param poolVersion_ version of BridgePool implementation to use
     */
    function _deployNewNativePool(
        uint8 tokenType_,
        address ercContract_,
        uint16 poolVersion_
    ) internal {
        bool native = true;
        //calculate the unique salt for the bridge pool
        bytes32 bridgePoolSalt = BridgePoolAddressUtil.getBridgePoolSalt(
            ercContract_,
            tokenType_,
            _chainID,
            poolVersion_
        );
        //calculate the address of the pool's logic contract
        address implementation = _logicAddresses[
            _getImplementationAddressKey(tokenType_, poolVersion_, native)
        ];
        _implementation = implementation;
        //check if the logic exists for the specified pool
        uint256 implementationSize;
        assembly ("memory-safe") {
            implementationSize := extcodesize(implementation)
        }
        if (implementationSize == 0) {
            revert BridgePoolFactoryErrors.PoolVersionNotSupported(poolVersion_);
        }
        address contractAddr = _deployStaticPool(bridgePoolSalt);
        IBridgePool(contractAddr).initialize(ercContract_);
        emit BridgePoolCreated(contractAddr, ercContract_);
    }

    /**
     * @notice creates a BridgePool contract with specific salt and bytecode returned by this contract fallback
     * @param salt_ salt of the implementation contract
     * @return contractAddr the address of the BridgePool
     */
    function _deployStaticPool(bytes32 salt_) internal returns (address contractAddr) {
        uint256 contractSize;
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, shl(136, 0x5880818283335afa3d82833e3d82f3))
            contractAddr := create2(0, ptr, 15, salt_)
            contractSize := extcodesize(contractAddr)
        }
        if (contractSize == 0) {
            revert BridgePoolFactoryErrors.StaticPoolDeploymentFailed(salt_);
        }
        poolExists[contractAddr] = true;
        return contractAddr;
    }

    /**
     * @notice calculates salt for a BridgePool implementation contract based on tokenType and version
     * @param tokenType_ type of token (0=ERC20, 1=ERC721, 2=ERC1155)
     * @param version_ version of the implementation
     * @param native_ boolean flag to specifier native or external token pools
     * @return calculated key
     */
    function _getImplementationAddressKey(
        uint8 tokenType_,
        uint16 version_,
        bool native_
    ) internal pure returns (string memory) {
        string memory key;
        if (native_) {
            key = "Native";
        } else {
            key = "External";
        }
        if (tokenType_ == uint8(TokenType.ERC20)) {
            key = string.concat(key, "ERC20");
        } else if (tokenType_ == uint8(TokenType.ERC721)) {
            key = string.concat(key, "ERC721");
        } else if (tokenType_ == uint8(TokenType.ERC1155)) {
            key = string.concat(key, "ERC1155");
        }
        key = string.concat(key, "V", Strings.toString(version_));
        return key;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract GovernanceMaxLock {
    // _MAX_GOVERNANCE_LOCK describes the maximum interval
    // a position may remained locked due to a
    // governance action
    // this value is approx 30 days worth of blocks
    // prevents double spend of voting weight
    uint256 internal constant _MAX_GOVERNANCE_LOCK = 172800;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract AccessControlled {
    error CallerNotLockup();
    error CallerNotLockupOrBonus();

    modifier onlyLockup() {
        if (msg.sender != _getLockupContractAddress()) {
            revert CallerNotLockup();
        }
        _;
    }

    modifier onlyLockupOrBonus() {
        // must protect increment of token balance
        if (
            msg.sender != _getLockupContractAddress() &&
            msg.sender != address(_getBonusPoolAddress())
        ) {
            revert CallerNotLockupOrBonus();
        }
        _;
    }

    function _getLockupContractAddress() internal view virtual returns (address);

    function _getBonusPoolAddress() internal view virtual returns (address);

    function _getRewardPoolAddress() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/CryptoLibraryErrors.sol";

/*
    Author: Philipp Schindler
    Source code and documentation available on Github: https://github.com/PhilippSchindler/ethdkg

    Copyright 2019 Philipp Schindler

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// TODO: we may want to check some of the functions to ensure that they are valid.
//       some of them may not be if there are attempts they are called with
//       invalid points.
library CryptoLibrary {
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// CRYPTOGRAPHIC CONSTANTS

    ////////
    //// These constants are updated to reflect our version, not theirs.
    ////////

    // GROUP_ORDER is the are the number of group elements in the groups G1, G2, and GT.
    uint256 public constant GROUP_ORDER =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // FIELD_MODULUS is the prime number over which the elliptic curves are based.
    uint256 public constant FIELD_MODULUS =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    // CURVE_B is the constant of the elliptic curve for G1:
    //
    //      y^2 == x^3 + CURVE_B,
    //
    // with CURVE_B == 3.
    uint256 public constant CURVE_B = 3;

    // G1 == (G1_X, G1_Y) is the standard generator for group G1.
    // uint256 constant G1_X  = 1;
    // uint256 constant G1_Y  = 2;
    // H1 == (H1X, H1Y) = hashToG1([]byte("MadHive Rocks!") from golang code;
    // this is another generator for G1 and dlog_G1(H1) is unknown,
    // which is necessary for security.
    //
    // In the future, the specific value of H1 could be changed every time
    // there is a change in validator set. For right now, though, this will
    // be a fixed constant.
    uint256 public constant H1_X =
        2788159449993757418373833378244720686978228247930022635519861138679785693683;
    uint256 public constant H1_Y =
        12344898367754966892037554998108864957174899548424978619954608743682688483244;

    // H2 == ([H2_XI, H2_X], [H2_YI, H2_Y]) is the *negation* of the
    // standard generator of group G2.
    // The standard generator comes from the Ethereum bn256 Go code.
    // The negated form is required because bn128_pairing check in Solidty requires this.
    //
    // In particular, to check
    //
    //      sig = H(msg)^privK
    //
    // is a valid signature for
    //
    //      pubK = H2Gen^privK,
    //
    // we need
    //
    //      e(sig, H2Gen) == e(H(msg), pubK).
    //
    // This is equivalent to
    //
    //      e(sig, H2) * e(H(msg), pubK) == 1.
    uint256 public constant H2_XI =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 public constant H2_X =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 public constant H2_YI =
        17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 public constant H2_Y =
        13392588948715843804641432497768002650278120570034223513918757245338268106653;

    uint256 public constant G1_X = 1;
    uint256 public constant G1_Y = 2;

    // TWO_256_MOD_P == 2^256 mod FIELD_MODULUS;
    // this is used in hashToBase to obtain a more uniform hash value.
    uint256 public constant TWO_256_MOD_P =
        6350874878119819312338956282401532409788428879151445726012394534686998597021;

    // P_MINUS1 == -1 mod FIELD_MODULUS;
    // this is used in sign0 and all ``negative'' values have this sign value.
    uint256 public constant P_MINUS1 =
        21888242871839275222246405745257275088696311157297823662689037894645226208582;

    // P_MINUS2 == FIELD_MODULUS - 2;
    // this is the exponent used in finite field inversion.
    uint256 public constant P_MINUS2 =
        21888242871839275222246405745257275088696311157297823662689037894645226208581;

    // P_MINUS1_OVER2 == (FIELD_MODULUS - 1) / 2;
    // this is the exponent used in computing the Legendre symbol and is
    // also used in sign0 as the cutoff point between ``positive'' and
    // ``negative'' numbers.
    uint256 public constant P_MINUS1_OVER2 =
        10944121435919637611123202872628637544348155578648911831344518947322613104291;

    // P_PLUS1_OVER4 == (FIELD_MODULUS + 1) / 4;
    // this is the exponent used in computing finite field square roots.
    uint256 public constant P_PLUS1_OVER4 =
        5472060717959818805561601436314318772174077789324455915672259473661306552146;

    // baseToG1 constants
    //
    // These are precomputed constants which are independent of t.
    // All of these constants are computed modulo FIELD_MODULUS.
    //
    // (-1 + sqrt(-3))/2
    uint256 public constant HASH_CONST_1 =
        2203960485148121921418603742825762020974279258880205651966;
    // sqrt(-3)
    uint256 public constant HASH_CONST_2 =
        4407920970296243842837207485651524041948558517760411303933;
    // 1/3
    uint256 public constant HASH_CONST_3 =
        14592161914559516814830937163504850059130874104865215775126025263096817472389;
    // 1 + CURVE_B (CURVE_B == 3)
    uint256 public constant HASH_CONST_4 = 4;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// HELPER FUNCTIONS

    function discreteLogEquality(
        uint256[2] memory x1,
        uint256[2] memory y1,
        uint256[2] memory x2,
        uint256[2] memory y2,
        uint256[2] memory proof
    ) internal view returns (bool proofIsValid) {
        uint256[2] memory tmp1;
        uint256[2] memory tmp2;

        tmp1 = bn128Multiply([x1[0], x1[1], proof[1]]);
        tmp2 = bn128Multiply([y1[0], y1[1], proof[0]]);
        uint256[2] memory t1prime = bn128Add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        tmp1 = bn128Multiply([x2[0], x2[1], proof[1]]);
        tmp2 = bn128Multiply([y2[0], y2[1], proof[0]]);
        uint256[2] memory t2prime = bn128Add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        uint256 challenge = uint256(keccak256(abi.encodePacked(x1, y1, x2, y2, t1prime, t2prime)));
        proofIsValid = challenge == proof[0];
    }

    function bn128Add(uint256[4] memory input) internal view returns (uint256[2] memory result) {
        // computes P + Q
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        assembly ("memory-safe") {
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(not(0), 0x06, input, 128, result, 64)
        }

        if (!success) {
            revert CryptoLibraryErrors.EllipticCurveAdditionFailed();
        }
    }

    function bn128Multiply(
        uint256[3] memory input
    ) internal view returns (uint256[2] memory result) {
        // computes P*x
        // input: 3 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) scalar x

        bool success;
        assembly ("memory-safe") {
            // 0x07     id of precompiled bn256ScalarMul contract
            // 0        number of ether to transfer
            // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(not(0), 0x07, input, 96, result, 64)
        }
        if (!success) {
            revert CryptoLibraryErrors.EllipticCurveMultiplicationFailed();
        }
    }

    function bn128CheckPairing(uint256[12] memory input) internal view returns (bool) {
        uint256[1] memory result;
        bool success;
        assembly ("memory-safe") {
            // 0x08     id of precompiled bn256Pairing contract     (checking the elliptic curve pairings)
            // 0        number of ether to transfer
            // 384       size of call parameters, i.e. 12*256 bits == 384 bytes
            // 32        size of result (one 32 byte boolean!)
            success := staticcall(not(0), 0x08, input, 384, result, 32)
        }
        if (!success) {
            revert CryptoLibraryErrors.EllipticCurvePairingFailed();
        }
        return result[0] == 1;
    }

    //// Begin new helper functions added
    // expmod perform modular exponentiation with all variables uint256;
    // this is used in legendre, sqrt, and invert.
    //
    // Copied from
    //      https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    // and slightly modified
    function expmod(uint256 base, uint256 e, uint256 m) internal view returns (uint256 result) {
        bool success;
        assembly ("memory-safe") {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            // 0x05           id of precompiled modular exponentiation contract
            // 0xc0 == 192    size of call parameters
            // 0x20 ==  32    size of result
            success := staticcall(gas(), 0x05, p, 0xc0, p, 0x20)
            // data
            result := mload(p)
        }
        if (!success) {
            revert CryptoLibraryErrors.ModularExponentiationFailed();
        }
    }

    // Sign takes byte slice message and private key privK.
    // It then calls HashToG1 with message as input and performs scalar
    // multiplication to produce the resulting signature.
    function sign(
        bytes memory message,
        uint256 privK
    ) internal view returns (uint256[2] memory sig) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1(message);
        sig = bn128Multiply([hashPoint[0], hashPoint[1], privK]);
    }

    // Verify takes byte slice message, signature sig (element of G1),
    // public key pubK (element of G2), and checks that sig is a valid
    // signature for pubK for message. Also look at the definition of H2.
    function verifySignature(
        bytes memory message,
        uint256[2] memory sig,
        uint256[4] memory pubK
    ) internal view returns (bool v) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1(message);
        v = bn128CheckPairing(
            [
                sig[0],
                sig[1],
                H2_XI,
                H2_X,
                H2_YI,
                H2_Y,
                hashPoint[0],
                hashPoint[1],
                pubK[0],
                pubK[1],
                pubK[2],
                pubK[3]
            ]
        );
    }

    // Optimized version written in ASM of the Verify function. It takes byte slice message, signature
    // sig (element of G1), public key pubK (element of G2), and checks that sig is a valid signature
    // for pubK for message. Also look at the definition of H2.
    function verifySignatureASM(
        bytes memory message,
        uint256[2] memory sig,
        uint256[4] memory pubK
    ) internal view returns (bool v) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1ASM(message);
        v = bn128CheckPairing(
            [
                sig[0],
                sig[1],
                H2_XI,
                H2_X,
                H2_YI,
                H2_Y,
                hashPoint[0],
                hashPoint[1],
                pubK[0],
                pubK[1],
                pubK[2],
                pubK[3]
            ]
        );
    }

    // HashToG1 takes byte slice message and outputs an element of G1.
    // This function is based on the Fouque and Tibouchi 2012 paper
    // ``Indifferentiable Hashing to Barreto--Naehrig Curves''.
    // There are a couple improvements included from Wahby and Boneh's 2019 paper
    // ``Fast and simple constant-time hashing to the BLS12-381 elliptic curve''.
    //
    // There are two parts: hashToBase and baseToG1.
    //
    // hashToBase takes a byte slice (with additional bytes for domain
    // separation) and returns uint256 t with 0 <= t < FIELD_MODULUS; thus,
    // it is a valid element of F_p, the base field of the elliptic curve.
    // This is the ``hash'' portion of the hash function. The two byte
    // values are used for domain separation in order to obtain independent
    // hash functions.
    //
    // baseToG1 is a deterministic function which takes t in F_p and returns
    // a valid element of the elliptic curve.
    //
    // By combining hashToBase and baseToG1, we get a HashToG1. Now, we
    // perform this operation twice because without it, we would not have
    // a valid hash function. The reason is that baseToG1 only maps to
    // approximately 9/16ths of the points in the elliptic curve.
    // By doing this twice (with independent hash functions) and adding the
    // resulting points, we have an actual hash function to G1.
    // For more information relating to the hash-to-curve theory,
    // see the FT 2012 paper.
    function hashToG1(bytes memory message) internal view returns (uint256[2] memory h) {
        uint256 t0 = hashToBase(message, 0x00, 0x01);
        uint256 t1 = hashToBase(message, 0x02, 0x03);

        uint256[2] memory h0 = baseToG1(t0);
        uint256[2] memory h1 = baseToG1(t1);

        // Each BaseToG1 call involves a check that we have a valid curve point.
        // Here, we check that we have a valid curve point after the addition.
        // Again, this is to ensure that even if something strange happens, we
        // will not return an invalid curvepoint.
        h = bn128Add([h0[0], h0[1], h1[0], h1[1]]);

        if (!bn128IsOnCurve(h)) {
            revert CryptoLibraryErrors.HashPointNotOnCurve();
        }
        if (!safeSigningPoint(h)) {
            revert CryptoLibraryErrors.HashPointUnsafeForSigning();
        }
    }

    /// HashToG1 takes byte slice message and outputs an element of G1. Optimized version of `hashToG1`
    /// written in EVM assembly.
    function hashToG1ASM(bytes memory message) internal view returns (uint256[2] memory h) {
        assembly ("memory-safe") {
            function revertASM(str, len) {
                let ptr := mload(0x40)
                let startPtr := ptr
                mstore(ptr, hex"08c379a0") // keccak256('Error(string)')[0:4]
                ptr := add(ptr, 0x4)
                mstore(ptr, 0x20)
                ptr := add(ptr, 0x20)
                mstore(ptr, len) // string length
                ptr := add(ptr, 0x20)
                mstore(ptr, str)
                ptr := add(ptr, 0x20)
                revert(startPtr, sub(ptr, startPtr))
            }

            function memCopy(dest, src, len) {
                if lt(len, 32) {
                    revertASM("invalid length", 18)
                }
                // Copy word-length chunks while possible
                for {

                } gt(len, 31) {
                    len := sub(len, 32)
                } {
                    mstore(dest, mload(src))
                    src := add(src, 32)
                    dest := add(dest, 32)
                }

                if iszero(eq(len, 0)) {
                    // Copy remaining bytes
                    let mask := sub(exp(256, sub(32, len)), 1)
                    // e.g len = 4, yields
                    // mask    = 00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                    // notMask = ffffffff00000000000000000000000000000000000000000000000000000000
                    let srcpart := and(mload(src), not(mask))
                    let destpart := and(mload(dest), mask)
                    mstore(dest, or(destpart, srcpart))
                }
            }

            function bn128CheckPairing(ptr, paramPtr, x, y) -> result {
                mstore(add(ptr, 0xb0), x)
                mstore(add(ptr, 0xc0), y)
                memCopy(ptr, paramPtr, 0xb0)
                let success := staticcall(gas(), 0x08, ptr, 384, ptr, 32)
                if iszero(success) {
                    revertASM("invalid bn128 pairing", 21)
                }
                result := mload(ptr)
            }

            function bn128IsOnCurve(p0, p1) -> result {
                let o1 := mulmod(p0, p0, FIELD_MODULUS)
                o1 := mulmod(p0, o1, FIELD_MODULUS)
                o1 := addmod(o1, 3, FIELD_MODULUS)
                let o2 := mulmod(p1, p1, FIELD_MODULUS)
                result := eq(o1, o2)
            }

            function baseToG1(ptr, t, output) {
                let fp := add(ptr, 0xc0)
                let ap1 := mulmod(t, t, FIELD_MODULUS)

                let alpha := mulmod(ap1, addmod(ap1, HASH_CONST_4, FIELD_MODULUS), FIELD_MODULUS)
                // invert alpha
                mstore(add(ptr, 0x60), alpha)
                mstore(add(ptr, 0x80), P_MINUS2)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 1", 19)
                }
                alpha := mload(fp)

                ap1 := mulmod(ap1, ap1, FIELD_MODULUS)

                let x := mulmod(ap1, HASH_CONST_2, FIELD_MODULUS)
                x := mulmod(x, alpha, FIELD_MODULUS)
                // negating x
                x := sub(FIELD_MODULUS, x)
                x := addmod(x, HASH_CONST_1, FIELD_MODULUS)

                let x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x80), P_PLUS1_OVER4)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 2", 19)
                }

                let ymul := 1
                if gt(t, P_MINUS1_OVER2) {
                    ymul := P_MINUS1
                }
                let y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                let y_two := mulmod(y, y, FIELD_MODULUS)
                if eq(x_three, y_two) {
                    mstore(output, x)
                    mstore(add(output, 0x20), y)
                    leave
                }
                x := addmod(x, 1, FIELD_MODULUS)
                x := sub(FIELD_MODULUS, x)
                x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 3", 19)
                }
                y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                y_two := mulmod(y, y, FIELD_MODULUS)
                if eq(x_three, y_two) {
                    mstore(output, x)
                    mstore(add(output, 0x20), y)
                    leave
                }
                ap1 := addmod(mulmod(t, t, FIELD_MODULUS), 4, FIELD_MODULUS)
                x := mulmod(ap1, ap1, FIELD_MODULUS)
                x := mulmod(x, ap1, FIELD_MODULUS)
                x := mulmod(x, HASH_CONST_3, FIELD_MODULUS)
                x := mulmod(x, alpha, FIELD_MODULUS)
                x := sub(FIELD_MODULUS, x)
                x := addmod(x, 1, FIELD_MODULUS)
                x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 4", 19)
                }
                y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                mstore(output, x)
                mstore(add(output, 0x20), y)
            }

            function hashToG1(ptr, messageptr, messagesize, output) {
                let size := add(messagesize, 1)
                memCopy(add(ptr, 1), messageptr, messagesize)
                mstore8(ptr, 0x00)
                let h0 := keccak256(ptr, size)
                mstore8(ptr, 0x01)
                let h1 := keccak256(ptr, size)
                mstore8(ptr, 0x02)
                let h2 := keccak256(ptr, size)
                mstore8(ptr, 0x03)
                let h3 := keccak256(ptr, size)
                mstore(ptr, 0x20)
                mstore(add(ptr, 0x20), 0x20)
                mstore(add(ptr, 0x40), 0x20)
                mstore(add(ptr, 0xa0), FIELD_MODULUS)
                h1 := addmod(h1, mulmod(h0, TWO_256_MOD_P, FIELD_MODULUS), FIELD_MODULUS)
                h2 := addmod(h3, mulmod(h2, TWO_256_MOD_P, FIELD_MODULUS), FIELD_MODULUS)
                baseToG1(ptr, h1, output)
                let x1 := mload(output)
                let y1 := mload(add(output, 0x20))
                let success := bn128IsOnCurve(x1, y1)
                if iszero(success) {
                    revertASM("x1 y1 not in curve", 18)
                }
                baseToG1(ptr, h2, output)
                let x2 := mload(output)
                let y2 := mload(add(output, 0x20))
                success := bn128IsOnCurve(x2, y2)
                if iszero(success) {
                    revertASM("x2 y2 not in curve", 18)
                }
                mstore(ptr, x1)
                mstore(add(ptr, 0x20), y1)
                mstore(add(ptr, 0x40), x2)
                mstore(add(ptr, 0x60), y2)
                if iszero(staticcall(gas(), 0x06, ptr, 128, ptr, 64)) {
                    revertASM("bn256 add failed", 16)
                }
                let x := mload(ptr)
                let y := mload(add(ptr, 0x20))
                success := bn128IsOnCurve(x, y)
                if iszero(success) {
                    revertASM("x y not in curve", 16)
                }
                if or(iszero(x), eq(y, 1)) {
                    revertASM("point not safe to sign", 22)
                }
                mstore(output, x)
                mstore(add(output, 0x20), y)
            }

            let messageptr := add(message, 0x20)
            let messagesize := mload(message)
            let ptr := mload(0x40)
            hashToG1(ptr, messageptr, messagesize, h)
        }
    }

    // baseToG1 is a deterministic map from the base field F_p to the elliptic
    // curve. All values in [0, FIELD_MODULUS) are valid including 0, so we
    // do not need to worry about any exceptions.
    //
    // We remember our elliptic curve has the form
    //
    //      y^2 == x^3 + b
    //          == g(x)
    //
    // The main idea is that given t, we can produce x values x1, x2, and x3
    // such that
    //
    //      g(x1)*g(x2)*g(x3) == s^2.
    //
    // The above equation along with quadratic residues means that
    // when s != 0, at least one of g(x1), g(x2), or g(x3) is a square,
    // which implies that x1, x2, or x3 is a valid x-coordinate to a point
    // on the elliptic curve. For uniqueness, we choose the smallest coordinate.
    // In our construction, the above s value will always be nonzero, so we will
    // always have a solution. This means that baseToG1 is a deterministic
    // map from the base field to the elliptic curve.
    function baseToG1(uint256 t) internal view returns (uint256[2] memory h) {
        // ap1 and ap2 are temporary variables, originally named to represent
        // alpha part 1 and alpha part 2. Now they are somewhat general purpose
        // variables due to using too many variables on stack.
        uint256 ap1;
        uint256 ap2;

        // One of the main constants variables to form x1, x2, and x3
        // is alpha, which has the following definition:
        //
        //      alpha == (ap1*ap2)^(-1)
        //            == [t^2*(t^2 + h4)]^(-1)
        //
        //      ap1 == t^2
        //      ap2 == t^2 + h4
        //      h4  == HASH_CONST_4
        //
        // Defining alpha helps decrease the calls to expmod,
        // which is the most expensive operation we do.
        uint256 alpha;
        ap1 = mulmod(t, t, FIELD_MODULUS);
        ap2 = addmod(ap1, HASH_CONST_4, FIELD_MODULUS);
        alpha = mulmod(ap1, ap2, FIELD_MODULUS);
        alpha = invert(alpha);

        // Another important constant which is used when computing x3 is tmp,
        // which has the following definition:
        //
        //      tmp == (t^2 + h4)^3
        //          == ap2^3
        //
        //      h4  == HASH_CONST_4
        //
        // This is cheap to compute because ap2 has not changed
        uint256 tmp;
        tmp = mulmod(ap2, ap2, FIELD_MODULUS);
        tmp = mulmod(tmp, ap2, FIELD_MODULUS);

        // When computing x1, we need to compute t^4. ap1 will be the
        // temporary variable which stores this value now:
        //
        // Previous definition:
        //      ap1 == t^2
        //
        // Current definition:
        //      ap1 == t^4
        ap1 = mulmod(ap1, ap1, FIELD_MODULUS);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x1 == h1 - h2*t^4*alpha
        //         == h1 - h2*ap1*alpha
        //
        //      ap1 == t^4 (note previous assignment)
        //      h1  == HASH_CONST_1
        //      h2  == HASH_CONST_2
        //
        // When t == 0, x1 is a valid x-coordinate of a point on the elliptic
        // curve, so we need no exceptions; this is different than the original
        // Fouque and Tibouchi 2012 paper. This comes from the fact that
        // 0^(-1) == 0 mod p, as we use expmod for inversion.
        uint256 x1;
        x1 = mulmod(HASH_CONST_2, ap1, FIELD_MODULUS);
        x1 = mulmod(x1, alpha, FIELD_MODULUS);
        x1 = neg(x1);
        x1 = addmod(x1, HASH_CONST_1, FIELD_MODULUS);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x2 == -1 - x1
        uint256 x2;
        x2 = addmod(x1, 1, FIELD_MODULUS);
        x2 = neg(x2);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x3 == 1 - h3*tmp*alpha
        //
        //      h3 == HASH_CONST_3
        uint256 x3;
        x3 = mulmod(HASH_CONST_3, tmp, FIELD_MODULUS);
        x3 = mulmod(x3, alpha, FIELD_MODULUS);
        x3 = neg(x3);
        x3 = addmod(x3, 1, FIELD_MODULUS);

        // We now focus on determing residue1; if residue1 == 1,
        // then x1 is a valid x-coordinate for a point on E(F_p).
        //
        // When computing residues, the original FT 2012 paper suggests
        // blinding for security. We do not use that suggestion here
        // because of the possibility of a random integer being returned
        // which is 0, which would completely destroy the output.
        // Additionally, computing random numbers on Ethereum is difficult.
        uint256 y;
        y = mulmod(x1, x1, FIELD_MODULUS);
        y = mulmod(y, x1, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        int256 residue1 = legendre(y);

        // We now focus on determing residue2; if residue2 == 1,
        // then x2 is a valid x-coordinate for a point on E(F_p).
        y = mulmod(x2, x2, FIELD_MODULUS);
        y = mulmod(y, x2, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        int256 residue2 = legendre(y);

        // i is the index which gives us the correct x value (x1, x2, or x3)
        int256 i = ((residue1 - 1) * (residue2 - 3)) / 4 + 1;

        // This is the simplest way to determine which x value is correct
        // but is not secure. If possible, we should improve this.
        uint256 x;
        if (i == 1) {
            x = x1;
        } else if (i == 2) {
            x = x2;
        } else {
            x = x3;
        }

        // Now that we know x, we compute y
        y = mulmod(x, x, FIELD_MODULUS);
        y = mulmod(y, x, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        y = sqrt(y);

        // We now determine the sign of y based on t; this is a change from
        // the original FT 2012 paper and uses the suggestion from WB 2019.
        //
        // This is done to save computation, as using sign0 reduces the
        // number of calls to expmod from 5 to 4; currently, we call expmod
        // for inversion (alpha), two legendre calls (for residue1 and
        // residue2), and one sqrt call.
        // This change nullifies the proof in FT 2012 that we have a valid
        // hash function. Whether the proof could be slightly modified to
        // compensate for this change is possible but not currently known.
        //
        // (CHG: At the least, I am not sure that the proof holds, nor am I
        // able to see how the proof could potentially be fixed in order
        // for the hash function to be admissible.)
        //
        // If this is included as a precompile, it may be worth it to ignore
        // the cost savings in order to ensure uniformity of the hash function.
        // Also, we would need to change legendre so that legendre(0) == 1,
        // or else things would fail when t == 0. We could also have a separate
        // function for the sign determiniation.
        uint256 ySign;
        ySign = sign0(t);
        y = mulmod(y, ySign, FIELD_MODULUS);

        // Before returning the value, we check to make sure we have a valid
        // curve point. This ensures we will always have a valid point.
        // From Fouque-Tibouchi 2012, the only way to get an invalid point is
        // when t == 0, but we have already taken care of that to ensure that
        // when t == 0, we still return a valid curve point.
        if (!bn128IsOnCurve([x, y])) {
            revert CryptoLibraryErrors.PointNotOnCurve();
        }

        h[0] = x;
        h[1] = y;
    }

    // invert computes the multiplicative inverse of t modulo FIELD_MODULUS.
    // When t == 0, s == 0.
    function invert(uint256 t) internal view returns (uint256 s) {
        s = expmod(t, P_MINUS2, FIELD_MODULUS);
    }

    // sqrt computes the multiplicative square root of t modulo FIELD_MODULUS.
    // sqrt does not check that a square root is possible; see legendre.
    function sqrt(uint256 t) internal view returns (uint256 s) {
        s = expmod(t, P_PLUS1_OVER4, FIELD_MODULUS);
    }

    // legendre computes the legendre symbol of t with respect to FIELD_MODULUS.
    // That is, legendre(t) == 1 when a square root of t exists modulo
    // FIELD_MODULUS, legendre(t) == -1 when a square root of t does not exist
    // modulo FIELD_MODULUS, and legendre(t) == 0 when t == 0 mod FIELD_MODULUS.
    function legendre(uint256 t) internal view returns (int256 chi) {
        uint256 s = expmod(t, P_MINUS1_OVER2, FIELD_MODULUS);
        if (s != 0) {
            chi = 2 * int256(s & 1) - 1;
        } else {
            chi = 0;
        }
    }

    // AggregateSignatures takes takes the signature array sigs, index array
    // indices, and threshold to compute the thresholded group signature.
    // After ensuring some basic requirements are met, it calls
    // LagrangeInterpolationG1 to perform this interpolation.
    //
    // To trade computation (and expensive gas costs) for space, we choose
    // to require that the multiplicative inverses modulo GROUP_ORDER be
    // entered for this function call in invArray. This allows the expensive
    // portion of gas cost to grow linearly in the size of the group rather
    // than quadratically. Additional improvements made be included
    // in the future.
    //
    // One advantage to how this function is designed is that we do not need
    // to know the number of participants, as we only require inverses which
    // will be required as deteremined by indices.
    function aggregateSignatures(
        uint256[2][] memory sigs,
        uint256[] memory indices,
        uint256 threshold,
        uint256[] memory invArray
    ) internal view returns (uint256[2] memory) {
        if (sigs.length != indices.length) {
            revert CryptoLibraryErrors.SignatureIndicesLengthMismatch(sigs.length, indices.length);
        }

        if (sigs.length <= threshold) {
            revert CryptoLibraryErrors.SignaturesLengthThresholdNotMet(sigs.length, threshold);
        }

        uint256 maxIndex = computeArrayMax(indices);
        if (!checkInverses(invArray, maxIndex)) {
            revert CryptoLibraryErrors.InverseArrayIncorrect();
        }
        uint256[2] memory grpsig;
        grpsig = lagrangeInterpolationG1(sigs, indices, threshold, invArray);
        return grpsig;
    }

    // LagrangeInterpolationG1 efficiently computes Lagrange interpolation
    // of pointsG1 using indices as the point location in the finite field.
    // This is an efficient method of Lagrange interpolation as we assume
    // finite field inverses are in invArray.
    function lagrangeInterpolationG1(
        uint256[2][] memory pointsG1,
        uint256[] memory indices,
        uint256 threshold,
        uint256[] memory invArray
    ) internal view returns (uint256[2] memory) {
        if (pointsG1.length != indices.length) {
            revert CryptoLibraryErrors.SignatureIndicesLengthMismatch(
                pointsG1.length,
                indices.length
            );
        }
        uint256[2] memory val;
        val[0] = 0;
        val[1] = 0;
        uint256 i;
        uint256 ell;
        uint256 idxJ;
        uint256 idxK;
        uint256 rj;
        uint256 rjPartial;
        uint256[2] memory partialVal;
        for (i = 0; i < indices.length; i++) {
            idxJ = indices[i];
            if (i > threshold) {
                break;
            }
            rj = 1;
            for (ell = 0; ell < indices.length; ell++) {
                idxK = indices[ell];
                if (ell > threshold) {
                    break;
                }
                if (idxK == idxJ) {
                    continue;
                }
                rjPartial = liRjPartialConst(idxK, idxJ, invArray);
                rj = mulmod(rj, rjPartial, GROUP_ORDER);
            }
            partialVal = pointsG1[i];
            partialVal = bn128Multiply([partialVal[0], partialVal[1], rj]);
            val = bn128Add([val[0], val[1], partialVal[0], partialVal[1]]);
        }
        return val;
    }

    // liRjPartialConst computes the partial constants of rj in Lagrange
    // interpolation based on the the multiplicative inverses in invArray.
    function liRjPartialConst(
        uint256 k,
        uint256 j,
        uint256[] memory invArray
    ) internal pure returns (uint256) {
        if (k == j) {
            revert CryptoLibraryErrors.KMustNotEqualJ();
        }
        uint256 tmp1 = k;
        uint256 tmp2;
        if (k > j) {
            tmp2 = k - j;
        } else {
            tmp1 = mulmod(tmp1, GROUP_ORDER - 1, GROUP_ORDER);
            tmp2 = j - k;
        }
        tmp2 = invArray[tmp2 - 1];
        tmp2 = mulmod(tmp1, tmp2, GROUP_ORDER);
        return tmp2;
    }

    // TODO: identity (0, 0) should be considered a valid point
    function bn128IsOnCurve(uint256[2] memory point) internal pure returns (bool) {
        // check if the provided point is on the bn128 curve (y**2 = x**3 + 3)
        return
            mulmod(point[1], point[1], FIELD_MODULUS) ==
            addmod(
                mulmod(point[0], mulmod(point[0], point[0], FIELD_MODULUS), FIELD_MODULUS),
                3,
                FIELD_MODULUS
            );
    }

    // hashToBase takes in a byte slice message and bytes c0 and c1 for
    // domain separation. The idea is that we treat keccak256 as a random
    // oracle which outputs uint256. The problem is that we want to hash modulo
    // FIELD_MODULUS (p, a prime number). Just using uint256 mod p will lead
    // to bias in the distribution. In particular, there is bias towards the
    // lower 5% of the numbers in [0, FIELD_MODULUS). The 1-norm error between
    // s0 mod p and a uniform distribution is ~ 1/4. By itself, this 1-norm
    // error is not too enlightening, but continue reading, as we will compare
    // it with another distribution that has much smaller 1-norm error.
    //
    // To obtain a better distribution with less bias, we take 2 uint256 hash
    // outputs (using c0 and c1 for domain separation so the hashes are
    // independent) and ``combine them'' to form a ``uint512''. Of course,
    // this is not possible in practice, so we view the combined output as
    //
    //      x == s0*2^256 + s1.
    //
    // This implies that x (combined from s0 and s1 in this way) is a
    // 512-bit uint. If s0 and s1 are uniformly distributed modulo 2^256,
    // then x is uniformly distributed modulo 2^512. We now want to reduce
    // this modulo FIELD_MODULUS (p). This is done as follows:
    //
    //      x mod p == [(s0 mod p)*(2^256 mod p)] + s1 mod p.
    //
    // This allows us easily compute the result without needing to implement
    // higher precision. The 1-norm error between x mod p and a uniform
    // distribution is ~1e-77. This is a *signficant* improvement from s0 mod p.
    // For all practical purposes, there is no difference from a
    // uniform distribution.
    function hashToBase(
        bytes memory message,
        bytes1 c0,
        bytes1 c1
    ) internal pure returns (uint256 t) {
        uint256 s0 = uint256(keccak256(abi.encodePacked(c0, message)));
        uint256 s1 = uint256(keccak256(abi.encodePacked(c1, message)));
        t = addmod(mulmod(s0, TWO_256_MOD_P, FIELD_MODULUS), s1, FIELD_MODULUS);
    }

    // safeSigningPoint ensures that the HashToG1 point we are returning
    // is safe to sign; in particular, it is not Infinity (the group identity
    // element) or the standard curve generator (curveGen) or its negation.
    //
    // TODO: may want to confirm point is valid first as well as reducing mod field prime
    function safeSigningPoint(uint256[2] memory input) internal pure returns (bool) {
        if (input[0] == 0 || input[0] == 1) {
            return false;
        } else {
            return true;
        }
    }

    // neg computes the additive inverse (the negative) modulo FIELD_MODULUS.
    function neg(uint256 t) internal pure returns (uint256 s) {
        if (t == 0) {
            s = 0;
        } else {
            s = FIELD_MODULUS - t;
        }
    }

    // sign0 computes the sign of a finite field element.
    // sign0 is used instead of legendre in baseToG1 from the suggestion
    // of WB 2019.
    function sign0(uint256 t) internal pure returns (uint256 s) {
        s = 1;
        if (t > P_MINUS1_OVER2) {
            s = P_MINUS1;
        }
    }

    // checkInverses takes maxIndex as the maximum element of indices
    // (used in AggregateSignatures) and checks that all of the necessary
    // multiplicative inverses in invArray are correct and present.
    function checkInverses(
        uint256[] memory invArray,
        uint256 maxIndex
    ) internal pure returns (bool) {
        uint256 k;
        uint256 kInv;
        uint256 res;
        bool validInverses = true;
        if ((maxIndex - 1) > invArray.length) {
            revert CryptoLibraryErrors.InvalidInverseArrayLength();
        }
        for (k = 1; k < maxIndex; k++) {
            kInv = invArray[k - 1];
            res = mulmod(k, kInv, GROUP_ORDER);
            if (res != 1) {
                validInverses = false;
                break;
            }
        }
        return validInverses;
    }

    // checkIndices determines whether or not each of these arrays contain
    // unique indices. There is no reason any index should appear twice.
    // All indices should be in {1, 2, ..., n} and this function ensures this.
    // n is the total number of participants; that is, n == addresses.length.
    function checkIndices(
        uint256[] memory honestIndices,
        uint256[] memory dishonestIndices,
        uint256 n
    ) internal pure returns (bool validIndices) {
        validIndices = true;
        uint256 k;
        uint256 f;
        uint256 curIdx;

        assert(n > 0);
        assert(n < 256);

        // Make sure each honestIndices list is unique
        for (k = 0; k < honestIndices.length; k++) {
            curIdx = honestIndices[k];
            // All indices must be between 1 and n
            if ((curIdx == 0) || (curIdx > n)) {
                validIndices = false;
                break;
            }
            // Only check for equality with previous indices
            if ((f & (1 << curIdx)) == 0) {
                f |= 1 << curIdx;
            } else {
                // We have seen this index before; invalid index sets
                validIndices = false;
                break;
            }
        }
        if (!validIndices) {
            return validIndices;
        }

        // Make sure each dishonestIndices list is unique and does not match
        // any from honestIndices.
        for (k = 0; k < dishonestIndices.length; k++) {
            curIdx = dishonestIndices[k];
            // All indices must be between 1 and n
            if ((curIdx == 0) || (curIdx > n)) {
                validIndices = false;
                break;
            }
            // Only check for equality with previous indices
            if ((f & (1 << curIdx)) == 0) {
                f |= 1 << curIdx;
            } else {
                // We have seen this index before; invalid index sets
                validIndices = false;
                break;
            }
        }
        return validIndices;
    }

    // computeArrayMax computes the maximum uin256 element of uint256Array
    function computeArrayMax(uint256[] memory uint256Array) internal pure returns (uint256) {
        uint256 curVal;
        uint256 maxVal = uint256Array[0];
        for (uint256 i = 1; i < uint256Array.length; i++) {
            curVal = uint256Array[i];
            if (curVal > maxVal) {
                maxVal = curVal;
            }
        }
        return maxVal;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract Sigmoid {
    // Constants for P function
    uint256 internal constant _P_A = 200;
    uint256 internal constant _P_B = 2500 * 10 ** 18;
    uint256 internal constant _P_C = 5611050234958650739260304 + 125 * 10 ** 39;
    uint256 internal constant _P_D = 4;
    uint256 internal constant _P_S = 2524876234590519489452;

    // Constants for P Inverse function
    uint256 internal constant _P_INV_C_1 = _P_A * ((_P_A + _P_D) * _P_S + _P_A * _P_B);
    uint256 internal constant _P_INV_C_2 = _P_A + _P_D;
    uint256 internal constant _P_INV_C_3 = _P_D * (2 * _P_A + _P_D);
    uint256 internal constant _P_INV_D_0 = ((_P_A + _P_D) * _P_S + _P_A * _P_B) ** 2;
    uint256 internal constant _P_INV_D_1 = 2 * (_P_A * _P_S + (_P_A + _P_D) * _P_B);

    function _p(uint256 t) internal pure returns (uint256) {
        return
            (_P_A + _P_D) *
            t +
            (_P_A * _P_S) -
            _sqrt(_P_A ** 2 * ((_safeAbsSub(_P_B, t)) ** 2 + _P_C));
    }

    function _pInverse(uint256 m) internal pure returns (uint256) {
        return
            (_P_INV_C_2 *
                m +
                _sqrt(_P_A ** 2 * (m ** 2 + _P_INV_D_0 - _P_INV_D_1 * m)) -
                _P_INV_C_1) / _P_INV_C_3;
    }

    function _safeAbsSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _max(a, b) - _min(a, b);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256) {
        if (a_ <= b_) {
            return a_;
        }
        return b_;
    }

    function _max(uint256 a_, uint256 b_) internal pure returns (uint256) {
        if (a_ >= b_) {
            return a_;
        }
        return b_;
    }

    function _sqrt(uint256 x) internal pure returns (uint256) {
        unchecked {
            if (x <= 1) {
                return x;
            }
            if (x >= ((1 << 128) - 1) ** 2) {
                return (1 << 128) - 1;
            }
            // Here, e represents the bit length;
            // its value is at most 256, so it could fit in a uint16.
            uint256 e = 1;
            // Here, result is a copy of x to compute the bit length
            uint256 result = x;
            if (result >= (1 << 128)) {
                result >>= 128;
                e += 128;
            }
            if (result >= (1 << 64)) {
                result >>= 64;
                e += 64;
            }
            if (result >= (1 << 32)) {
                result >>= 32;
                e += 32;
            }
            if (result >= (1 << 16)) {
                result >>= 16;
                e += 16;
            }
            if (result >= (1 << 8)) {
                result >>= 8;
                e += 8;
            }
            if (result >= (1 << 4)) {
                result >>= 4;
                e += 4;
            }
            if (result >= (1 << 2)) {
                result >>= 2;
                e += 2;
            }
            if (result >= (1 << 1)) {
                e += 1;
            }
            // e is currently bit length; we overwrite it to scale x
            e = (256 - e) >> 1;
            // m now satisfies 2**254 <= m < 2**256
            uint256 m = x << (2 * e);
            // result now stores the result
            result = 1 + (m >> 254);
            result = (result << 1) + (m >> 251) / result;
            result = (result << 3) + (m >> 245) / result;
            result = (result << 7) + (m >> 233) / result;
            result = (result << 15) + (m >> 209) / result;
            result = (result << 31) + (m >> 161) / result;
            result = (result << 63) + (m >> 65) / result;
            result >>= e;
            return result * result <= x ? result : (result - 1);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

/* solhint-disable */
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "contracts/utils/Base64.sol";
import "contracts/libraries/metadata/StakingSVG.sol";

library StakingDescriptor {
    using Strings for uint256;

    struct ConstructTokenURIParams {
        uint256 tokenId;
        uint256 shares;
        uint256 freeAfter;
        uint256 withdrawFreeAfter;
        uint256 accumulatorEth;
        uint256 accumulatorToken;
    }

    /// @notice Constructs a token URI out of token URI parameters
    /// @param params parameters of the token URI
    /// @return the token URI
    function constructTokenURI(
        ConstructTokenURIParams memory params
    ) internal pure returns (string memory) {
        string memory name = generateName(params);
        string memory description = generateDescription();
        string memory attributes = generateAttributes(
            params.tokenId.toString(),
            params.shares.toString(),
            params.freeAfter.toString(),
            params.withdrawFreeAfter.toString(),
            params.accumulatorEth.toString(),
            params.accumulatorToken.toString()
        );
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "attributes": ',
                            attributes,
                            ', "image_data": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '"}'
                        )
                    )
                )
            );
    }

    /// @notice Escapes double quotes from a string
    /// @param symbol the string to be processed
    /// @return The string with escaped quotes
    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    /// @notice Generates a SVG image out of a token URI
    /// @param params parameters of the token URI
    /// @return svg A string with SVG data
    function generateSVGImage(
        ConstructTokenURIParams memory params
    ) internal pure returns (string memory svg) {
        StakingSVG.StakingSVGParams memory svgParams = StakingSVG.StakingSVGParams({
            shares: params.shares.toString(),
            freeAfter: params.freeAfter.toString(),
            withdrawFreeAfter: params.withdrawFreeAfter.toString(),
            accumulatorEth: params.accumulatorEth.toString(),
            accumulatorToken: params.accumulatorToken.toString()
        });

        return StakingSVG.generateSVG(svgParams);
    }

    /// @notice Generates the description of the Staking Descriptor
    /// @return A string with the description of the Staking Descriptor
    function generateDescription() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT represents a staked position on AliceNet. The owner of this NFT can modify or redeem the position."
                )
            );
    }

    /// @notice Generates the attributes part of the Staking Descriptor
    /// @param  tokenId the token id of this descriptor
    /// @param  shares number of ALCA
    /// @param  freeAfter block number after which the position may be burned.
    /// @param  withdrawFreeAfter block number after which the position may be collected or burned
    /// @param  accumulatorEth the last value of the ethState accumulator this account performed a withdraw at
    /// @param  accumulatorToken the last value of the tokenState accumulator this account performed a withdraw at
    /// @return A string with the attributes part of the Staking Descriptor
    function generateAttributes(
        string memory tokenId,
        string memory shares,
        string memory freeAfter,
        string memory withdrawFreeAfter,
        string memory accumulatorEth,
        string memory accumulatorToken
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    '{"trait_type": "Shares", "value": "',
                    shares,
                    '"},'
                    '{"trait_type": "Free After", "value": "',
                    freeAfter,
                    '"},'
                    '{"trait_type": "Withdraw Free After", "value": "',
                    withdrawFreeAfter,
                    '"},'
                    '{"trait_type": "Accumulator Eth", "value": "',
                    accumulatorEth,
                    '"},'
                    '{"trait_type": "Accumulator Token", "value": "',
                    accumulatorToken,
                    '"},'
                    '{"trait_type": "Token ID", "value": "',
                    tokenId,
                    '"}'
                    "]"
                )
            );
    }

    function generateName(
        ConstructTokenURIParams memory params
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked("AliceNet Staked Token For Position #", params.tokenId.toString())
            );
    }
}
/* solhint-enable */

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

/* solhint-disable */
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/utils/Base64.sol";

/// @title StakingSVG
/// @notice Provides a function for generating an SVG associated with a Staking NFT position
library StakingSVG {
    using Strings for uint256;

    struct StakingSVGParams {
        string shares;
        string freeAfter;
        string withdrawFreeAfter;
        string accumulatorEth;
        string accumulatorToken;
    }

    function generateSVG(StakingSVGParams memory params) internal pure returns (string memory svg) {
        return string(abi.encodePacked(generateSVGDefs(params), generateSVGText(params), "</svg>"));
    }

    function generateSVGText(
        StakingSVGParams memory params
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                "<text x='10' y='20'>Shares: ",
                params.shares,
                "</text>",
                "<text x='10' y='40'>Free after: ",
                params.freeAfter,
                "</text>",
                "<text x='10' y='60'>Withdraw Free After: ",
                params.withdrawFreeAfter,
                "</text>",
                "<text x='10' y='80'>Accumulator (ETH): ",
                params.accumulatorEth,
                "</text>",
                "<text x='10' y='100'>Accumulator (Token): ",
                params.accumulatorToken,
                "</text>"
            )
        );
    }

    function generateSVGDefs(
        StakingSVGParams memory params
    ) private pure returns (string memory svg) {
        params; //to silence the warnings
        svg = string(
            abi.encodePacked(
                '<svg width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg"',
                " xmlns:xlink='http://www.w3.org/1999/xlink'>"
            )
        );
    }
}
/* solhint-enable */

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/BaseParserLibraryErrors.sol";

library BaseParserLibrary {
    // Size of a word, in bytes.
    uint256 internal constant _WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint256 internal constant _BYTES_HEADER_SIZE = 32;

    /// @notice Extracts a uint32 from a little endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint32
    /// @dev ~559 gas
    function extractUInt32(bytes memory src, uint256 offset) internal pure returns (uint32 val) {
        if (offset + 4 <= offset) {
            revert BaseParserLibraryErrors.OffsetParameterOverflow(offset);
        }

        if (offset + 4 > src.length) {
            revert BaseParserLibraryErrors.OffsetOutOfBounds(offset + 4, src.length);
        }

        assembly ("memory-safe") {
            val := shr(sub(256, 32), mload(add(add(src, 0x20), offset)))
            val := or(
                or(
                    or(shr(24, and(val, 0xff000000)), shr(8, and(val, 0x00ff0000))),
                    shl(8, and(val, 0x0000ff00))
                ),
                shl(24, and(val, 0x000000ff))
            )
        }
    }

    /// @notice Extracts a uint16 from a little endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint16
    /// @dev ~204 gas
    function extractUInt16(bytes memory src, uint256 offset) internal pure returns (uint16 val) {
        if (offset + 2 <= offset) {
            revert BaseParserLibraryErrors.LEUint16OffsetParameterOverflow(offset);
        }

        if (offset + 2 > src.length) {
            revert BaseParserLibraryErrors.LEUint16OffsetOutOfBounds(offset + 2, src.length);
        }

        assembly ("memory-safe") {
            val := shr(sub(256, 16), mload(add(add(src, 0x20), offset)))
            val := or(shr(8, and(val, 0xff00)), shl(8, and(val, 0x00ff)))
        }
    }

    /// @notice Extracts a uint16 from a big endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint16
    /// @dev ~204 gas
    function extractUInt16FromBigEndian(
        bytes memory src,
        uint256 offset
    ) internal pure returns (uint16 val) {
        if (offset + 2 <= offset) {
            revert BaseParserLibraryErrors.BEUint16OffsetParameterOverflow(offset);
        }

        if (offset + 2 > src.length) {
            revert BaseParserLibraryErrors.BEUint16OffsetOutOfBounds(offset + 2, src.length);
        }

        assembly ("memory-safe") {
            val := and(shr(sub(256, 16), mload(add(add(src, 0x20), offset))), 0xffff)
        }
    }

    /// @notice Extracts a bool from a bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return a bool
    /// @dev ~204 gas
    function extractBool(bytes memory src, uint256 offset) internal pure returns (bool) {
        if (offset + 1 <= offset) {
            revert BaseParserLibraryErrors.BooleanOffsetParameterOverflow(offset);
        }

        if (offset + 1 > src.length) {
            revert BaseParserLibraryErrors.BooleanOffsetOutOfBounds(offset + 1, src.length);
        }

        uint256 val;
        assembly ("memory-safe") {
            val := shr(sub(256, 8), mload(add(add(src, 0x20), offset)))
            val := and(val, 0x01)
        }
        return val == 1;
    }

    /// @notice Extracts a uint256 from a little endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint256
    /// @dev ~5155 gas
    function extractUInt256(bytes memory src, uint256 offset) internal pure returns (uint256 val) {
        if (offset + 32 <= offset) {
            revert BaseParserLibraryErrors.LEUint256OffsetParameterOverflow(offset);
        }

        if (offset + 32 > src.length) {
            revert BaseParserLibraryErrors.LEUint256OffsetOutOfBounds(offset + 32, src.length);
        }

        assembly ("memory-safe") {
            val := mload(add(add(src, 0x20), offset))
        }
    }

    /// @notice Extracts a uint256 from a big endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint256
    /// @dev ~1400 gas
    function extractUInt256FromBigEndian(
        bytes memory src,
        uint256 offset
    ) internal pure returns (uint256 val) {
        if (offset + 32 <= offset) {
            revert BaseParserLibraryErrors.BEUint256OffsetParameterOverflow(offset);
        }

        if (offset + 32 > src.length) {
            revert BaseParserLibraryErrors.BEUint256OffsetOutOfBounds(offset + 32, src.length);
        }

        uint256 srcDataPointer;
        uint32 val0 = 0;
        uint32 val1 = 0;
        uint32 val2 = 0;
        uint32 val3 = 0;
        uint32 val4 = 0;
        uint32 val5 = 0;
        uint32 val6 = 0;
        uint32 val7 = 0;

        assembly ("memory-safe") {
            srcDataPointer := mload(add(add(src, 0x20), offset))
            val0 := and(srcDataPointer, 0xffffffff)
            val1 := and(shr(32, srcDataPointer), 0xffffffff)
            val2 := and(shr(64, srcDataPointer), 0xffffffff)
            val3 := and(shr(96, srcDataPointer), 0xffffffff)
            val4 := and(shr(128, srcDataPointer), 0xffffffff)
            val5 := and(shr(160, srcDataPointer), 0xffffffff)
            val6 := and(shr(192, srcDataPointer), 0xffffffff)
            val7 := and(shr(224, srcDataPointer), 0xffffffff)

            val0 := or(
                or(
                    or(shr(24, and(val0, 0xff000000)), shr(8, and(val0, 0x00ff0000))),
                    shl(8, and(val0, 0x0000ff00))
                ),
                shl(24, and(val0, 0x000000ff))
            )
            val1 := or(
                or(
                    or(shr(24, and(val1, 0xff000000)), shr(8, and(val1, 0x00ff0000))),
                    shl(8, and(val1, 0x0000ff00))
                ),
                shl(24, and(val1, 0x000000ff))
            )
            val2 := or(
                or(
                    or(shr(24, and(val2, 0xff000000)), shr(8, and(val2, 0x00ff0000))),
                    shl(8, and(val2, 0x0000ff00))
                ),
                shl(24, and(val2, 0x000000ff))
            )
            val3 := or(
                or(
                    or(shr(24, and(val3, 0xff000000)), shr(8, and(val3, 0x00ff0000))),
                    shl(8, and(val3, 0x0000ff00))
                ),
                shl(24, and(val3, 0x000000ff))
            )
            val4 := or(
                or(
                    or(shr(24, and(val4, 0xff000000)), shr(8, and(val4, 0x00ff0000))),
                    shl(8, and(val4, 0x0000ff00))
                ),
                shl(24, and(val4, 0x000000ff))
            )
            val5 := or(
                or(
                    or(shr(24, and(val5, 0xff000000)), shr(8, and(val5, 0x00ff0000))),
                    shl(8, and(val5, 0x0000ff00))
                ),
                shl(24, and(val5, 0x000000ff))
            )
            val6 := or(
                or(
                    or(shr(24, and(val6, 0xff000000)), shr(8, and(val6, 0x00ff0000))),
                    shl(8, and(val6, 0x0000ff00))
                ),
                shl(24, and(val6, 0x000000ff))
            )
            val7 := or(
                or(
                    or(shr(24, and(val7, 0xff000000)), shr(8, and(val7, 0x00ff0000))),
                    shl(8, and(val7, 0x0000ff00))
                ),
                shl(24, and(val7, 0x000000ff))
            )

            val := or(
                or(
                    or(
                        or(
                            or(
                                or(or(shl(224, val0), shl(192, val1)), shl(160, val2)),
                                shl(128, val3)
                            ),
                            shl(96, val4)
                        ),
                        shl(64, val5)
                    ),
                    shl(32, val6)
                ),
                val7
            )
        }
    }

    /// @notice Reverts a bytes array. Can be used to convert an array from little endian to big endian and vice-versa.
    /// @param orig the binary state
    /// @return reversed the reverted bytes array
    /// @dev ~13832 gas
    function reverse(bytes memory orig) internal pure returns (bytes memory reversed) {
        reversed = new bytes(orig.length);
        for (uint256 idx = 0; idx < orig.length; idx++) {
            reversed[orig.length - idx - 1] = orig[idx];
        }
    }

    /// @notice Copy 'len' bytes from memory address 'src', to address 'dest'. This function does not check the or destination, it only copies the bytes.
    /// @param src the pointer to the source
    /// @param dest the pointer to the destination
    /// @param len the len of state to be copied
    function copy(uint256 src, uint256 dest, uint256 len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= _WORD_SIZE; len -= _WORD_SIZE) {
            assembly ("memory-safe") {
                mstore(dest, mload(src))
            }
            dest += _WORD_SIZE;
            src += _WORD_SIZE;
        }
        // Returning earlier if there's no leftover bytes to copy
        if (len == 0) {
            return;
        }
        // Copy remaining bytes
        uint256 mask = 256 ** (_WORD_SIZE - len) - 1;
        assembly ("memory-safe") {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /// @notice Returns a memory pointer to the state portion of the provided bytes array.
    /// @param bts the bytes array to get a pointer from
    /// @return addr the pointer to the `bts` bytes array
    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly ("memory-safe") {
            addr := add(bts, _BYTES_HEADER_SIZE)
        }
    }

    /// @notice Extracts a bytes array with length `howManyBytes` from `src`'s `offset` forward.
    /// @param src the bytes array to extract from
    /// @param offset where to start extracting from
    /// @param howManyBytes how many bytes we want to extract from `src`
    /// @return out the extracted bytes array
    /// @dev Extracting the 32-64th bytes out of a 64 bytes array takes ~7828 gas.
    function extractBytes(
        bytes memory src,
        uint256 offset,
        uint256 howManyBytes
    ) internal pure returns (bytes memory out) {
        if (offset + howManyBytes < offset) {
            revert BaseParserLibraryErrors.BytesOffsetParameterOverflow(offset);
        }

        if (offset + howManyBytes > src.length) {
            revert BaseParserLibraryErrors.BytesOffsetOutOfBounds(
                offset + howManyBytes,
                src.length
            );
        }

        out = new bytes(howManyBytes);
        uint256 start;

        assembly ("memory-safe") {
            start := add(add(src, offset), _BYTES_HEADER_SIZE)
        }

        copy(start, dataPtr(out), howManyBytes);
    }

    /// @notice Extracts a bytes32 extracted from `src`'s `offset` forward.
    /// @param src the source bytes array to extract from
    /// @param offset where to start extracting from
    /// @return out the bytes32 state extracted from `src`
    /// @dev ~439 gas
    function extractBytes32(bytes memory src, uint256 offset) internal pure returns (bytes32 out) {
        if (offset + 32 <= offset) {
            revert BaseParserLibraryErrors.Bytes32OffsetParameterOverflow(offset);
        }

        if (offset + 32 > src.length) {
            revert BaseParserLibraryErrors.Bytes32OffsetOutOfBounds(offset + 32, src.length);
        }

        assembly ("memory-safe") {
            out := mload(add(add(src, _BYTES_HEADER_SIZE), offset))
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/BClaimsParserLibraryErrors.sol";
import "contracts/libraries/errors/GenericParserLibraryErrors.sol";

import "contracts/libraries/parsers/BaseParserLibrary.sol";

/// @title Library to parse the BClaims structure from a blob of capnproto state
library BClaimsParserLibrary {
    struct BClaims {
        uint32 chainId;
        uint32 height;
        uint32 txCount;
        bytes32 prevBlock;
        bytes32 txRoot;
        bytes32 stateRoot;
        bytes32 headerRoot;
    }

    /** @dev size in bytes of a BCLAIMS cap'npro structure without the cap'n
      proto header bytes*/
    uint256 internal constant _BCLAIMS_SIZE = 176;
    /** @dev Number of bytes of a capnproto header, the state starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;

    /**
    @notice This function computes the offset adjustment in the pointer section
    of the capnproto blob of state. In case the txCount is 0, the value is not
    included in the binary blob by capnproto. Therefore, we need to deduce 8
    bytes from the pointer's offset.
    */
    /// @param src Binary state containing a BClaims serialized struct
    /// @param dataOffset Blob of binary state with a capnproto serialization
    /// @return pointerOffsetAdjustment the pointer offset adjustment in the blob state
    /// @dev Execution cost: 499 gas
    function getPointerOffsetAdjustment(
        bytes memory src,
        uint256 dataOffset
    ) internal pure returns (uint16 pointerOffsetAdjustment) {
        // Size in capnproto words (16 bytes) of the state section
        uint16 dataSectionSize = BaseParserLibrary.extractUInt16(src, dataOffset);

        if (dataSectionSize <= 0 || dataSectionSize > 2) {
            revert BClaimsParserLibraryErrors.SizeThresholdExceeded(dataSectionSize);
        }

        // In case the txCount is 0, the value is not included in the binary
        // blob by capnproto. Therefore, we need to deduce 8 bytes from the
        // pointer's offset.
        if (dataSectionSize == 1) {
            pointerOffsetAdjustment = 8;
        } else {
            pointerOffsetAdjustment = 0;
        }
    }

    /**
    @notice This function is for deserializing state directly from capnproto
            BClaims. It will skip the first 8 bytes (capnproto headers) and
            deserialize the BClaims Data. This function also computes the right
            PointerOffset adjustment (see the documentation on
            `getPointerOffsetAdjustment(bytes, uint256)` for more details). If
            BClaims is being extracted from inside of other structure (E.g
            PClaims capnproto) use the `extractInnerBClaims(bytes, uint,
            uint16)` instead.
    */
    /// @param src Binary state containing a BClaims serialized struct with Capn Proto headers
    /// @return bClaims the BClaims struct
    /// @dev Execution cost: 2484 gas
    function extractBClaims(bytes memory src) internal pure returns (BClaims memory bClaims) {
        return extractInnerBClaims(src, _CAPNPROTO_HEADER_SIZE, getPointerOffsetAdjustment(src, 4));
    }

    /**
    @notice This function is for deserializing the BClaims struct from an defined
            location inside a binary blob. E.G Extract BClaims from inside of
            other structure (E.g PClaims capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary state containing a BClaims serialized struct without Capn proto headers
    /// @param dataOffset offset to start reading the BClaims state from inside src
    /// @param pointerOffsetAdjustment Pointer's offset that will be deduced from the pointers location, in case txCount is missing in the binary
    /// @return bClaims the BClaims struct
    /// @dev Execution cost: 2126 gas
    function extractInnerBClaims(
        bytes memory src,
        uint256 dataOffset,
        uint16 pointerOffsetAdjustment
    ) internal pure returns (BClaims memory bClaims) {
        if (dataOffset + _BCLAIMS_SIZE - pointerOffsetAdjustment <= dataOffset) {
            revert BClaimsParserLibraryErrors.DataOffsetOverflow(dataOffset);
        }
        if (dataOffset + _BCLAIMS_SIZE - pointerOffsetAdjustment > src.length) {
            revert BClaimsParserLibraryErrors.NotEnoughBytes(
                dataOffset + _BCLAIMS_SIZE - pointerOffsetAdjustment,
                src.length
            );
        }

        if (pointerOffsetAdjustment == 0) {
            bClaims.txCount = BaseParserLibrary.extractUInt32(src, dataOffset + 8);
        } else {
            // In case the txCount is 0, the value is not included in the binary
            // blob by capnproto.
            bClaims.txCount = 0;
        }

        bClaims.chainId = BaseParserLibrary.extractUInt32(src, dataOffset);
        if (bClaims.chainId == 0) {
            revert GenericParserLibraryErrors.ChainIdZero();
        }

        bClaims.height = BaseParserLibrary.extractUInt32(src, dataOffset + 4);
        if (bClaims.height == 0) {
            revert GenericParserLibraryErrors.HeightZero();
        }

        bClaims.prevBlock = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 48 - pointerOffsetAdjustment
        );
        bClaims.txRoot = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 80 - pointerOffsetAdjustment
        );
        bClaims.stateRoot = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 112 - pointerOffsetAdjustment
        );
        bClaims.headerRoot = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 144 - pointerOffsetAdjustment
        );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/MerkleProofParserLibraryErrors.sol";

import "contracts/libraries/parsers/BaseParserLibrary.sol";

/// @title Library to parse the MerkleProof structure from a blob of binary state
library MerkleProofParserLibrary {
    struct MerkleProof {
        bool included;
        uint16 keyHeight;
        bytes32 key;
        bytes32 proofKey;
        bytes32 proofValue;
        bytes bitmap;
        bytes auditPath;
    }
    /** @dev minimum size in bytes of a MerkleProof binary structure
      (without proofs and bitmap) */
    uint256 internal constant _MERKLE_PROOF_SIZE = 103;

    /**
    @notice This function is for deserializing the MerkleProof struct from a
            binary blob.
    */
    /// @param src Binary state containing a MerkleProof serialized struct
    /// @return mProof a MerkleProof struct
    /// @dev Execution cost: ~4000-51000 gas for a 10-256 height proof respectively
    function extractMerkleProof(
        bytes memory src
    ) internal pure returns (MerkleProof memory mProof) {
        if (src.length < _MERKLE_PROOF_SIZE) {
            revert MerkleProofParserLibraryErrors.InvalidProofMinimumSize(src.length);
        }
        uint16 bitmapLength = BaseParserLibrary.extractUInt16FromBigEndian(src, 99);
        uint16 auditPathLength = BaseParserLibrary.extractUInt16FromBigEndian(src, 101);
        if (src.length < _MERKLE_PROOF_SIZE + bitmapLength + auditPathLength * 32) {
            revert MerkleProofParserLibraryErrors.InvalidProofSize(src.length);
        }
        mProof.included = BaseParserLibrary.extractBool(src, 0);
        mProof.keyHeight = BaseParserLibrary.extractUInt16FromBigEndian(src, 1);
        if (mProof.keyHeight > 256) {
            revert MerkleProofParserLibraryErrors.InvalidKeyHeight(mProof.keyHeight);
        }
        mProof.key = BaseParserLibrary.extractBytes32(src, 3);
        mProof.proofKey = BaseParserLibrary.extractBytes32(src, 35);
        mProof.proofValue = BaseParserLibrary.extractBytes32(src, 67);
        mProof.bitmap = BaseParserLibrary.extractBytes(src, 103, bitmapLength);
        mProof.auditPath = BaseParserLibrary.extractBytes(
            src,
            103 + bitmapLength,
            auditPathLength * 32
        );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/GenericParserLibraryErrors.sol";

import "contracts/libraries/parsers/BaseParserLibrary.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "contracts/libraries/parsers/RCertParserLibrary.sol";

/// @title Library to parse the PClaims structure from a blob of capnproto state
library PClaimsParserLibrary {
    struct PClaims {
        BClaimsParserLibrary.BClaims bClaims;
        RCertParserLibrary.RCert rCert;
    }
    /** @dev size in bytes of a PCLAIMS cap'npro structure without the cap'n
      proto header bytes*/
    uint256 internal constant _PCLAIMS_SIZE = 456;
    /** @dev Number of bytes of a capnproto header, the state starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;

    /**
    @notice This function is for deserializing state directly from capnproto
            PClaims. Use `extractInnerPClaims()` if you are extracting PClaims
            from other capnproto structure (e.g Proposal).
    */
    /// @param src Binary state containing a RCert serialized struct with Capn Proto headers
    /// @return pClaims the PClaims struct
    /// @dev Execution cost: 7725 gas
    function extractPClaims(bytes memory src) internal pure returns (PClaims memory pClaims) {
        (pClaims, ) = extractInnerPClaims(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for deserializing the PClaims struct from an defined
            location inside a binary blob. E.G Extract PClaims from inside of
            other structure (E.g Proposal capnproto) or skipping the capnproto
            headers. Since PClaims is composed of a BClaims struct which has not
            a fixed sized depending on the txCount value, this function returns
            the pClaims struct deserialized and its binary size. The
            binary size must be used to adjust any other state that
            is being deserialized after PClaims in case PClaims is being
            deserialized from inside another struct.
    */
    /// @param src Binary state containing a PClaims serialized struct without Capn Proto headers
    /// @param dataOffset offset to start reading the PClaims state from inside src
    /// @return pClaims the PClaims struct
    /// @return pClaimsBinarySize the size of this PClaims
    /// @dev Execution cost: 7026 gas
    function extractInnerPClaims(
        bytes memory src,
        uint256 dataOffset
    ) internal pure returns (PClaims memory pClaims, uint256 pClaimsBinarySize) {
        if (dataOffset + _PCLAIMS_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        uint16 pointerOffsetAdjustment = BClaimsParserLibrary.getPointerOffsetAdjustment(
            src,
            dataOffset + 4
        );
        pClaimsBinarySize = _PCLAIMS_SIZE - pointerOffsetAdjustment;
        if (src.length < dataOffset + pClaimsBinarySize) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + pClaimsBinarySize
            );
        }
        pClaims.bClaims = BClaimsParserLibrary.extractInnerBClaims(
            src,
            dataOffset + 16,
            pointerOffsetAdjustment
        );
        pClaims.rCert = RCertParserLibrary.extractInnerRCert(
            src,
            dataOffset + 16 + BClaimsParserLibrary._BCLAIMS_SIZE - pointerOffsetAdjustment
        );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/GenericParserLibraryErrors.sol";

import "contracts/libraries/parsers/BaseParserLibrary.sol";
import "contracts/libraries/parsers/RClaimsParserLibrary.sol";

/// @title Library to parse the RCert structure from a blob of capnproto state
library RCertParserLibrary {
    struct RCert {
        RClaimsParserLibrary.RClaims rClaims;
        uint256[4] sigGroupPublicKey;
        uint256[2] sigGroupSignature;
    }

    /** @dev size in bytes of a RCert cap'npro structure without the cap'n proto
      header bytes */
    uint256 internal constant _RCERT_SIZE = 264;
    /** @dev Number of bytes of a capnproto header, the state starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;
    /** @dev Number of Bytes of the sig group array */
    uint256 internal constant _SIG_GROUP_SIZE = 192;

    /// @notice Extracts the signature group out of a Capn Proto blob.
    /// @param src Binary state containing signature group state
    /// @param dataOffset offset of the signature group state inside src
    /// @return publicKey the public keys
    /// @return signature the signature
    /// @dev Execution cost: 1645 gas.
    function extractSigGroup(
        bytes memory src,
        uint256 dataOffset
    ) internal pure returns (uint256[4] memory publicKey, uint256[2] memory signature) {
        if (dataOffset + RCertParserLibrary._SIG_GROUP_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        if (src.length < dataOffset + RCertParserLibrary._SIG_GROUP_SIZE) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + RCertParserLibrary._SIG_GROUP_SIZE
            );
        }
        // _SIG_GROUP_SIZE = 192 bytes -> size in bytes of 6 uint256/bytes32 elements (6*32)
        publicKey[0] = BaseParserLibrary.extractUInt256(src, dataOffset + 0);
        publicKey[1] = BaseParserLibrary.extractUInt256(src, dataOffset + 32);
        publicKey[2] = BaseParserLibrary.extractUInt256(src, dataOffset + 64);
        publicKey[3] = BaseParserLibrary.extractUInt256(src, dataOffset + 96);
        signature[0] = BaseParserLibrary.extractUInt256(src, dataOffset + 128);
        signature[1] = BaseParserLibrary.extractUInt256(src, dataOffset + 160);
    }

    /**
    @notice This function is for deserializing state directly from capnproto
            RCert. It will skip the first 8 bytes (capnproto headers) and
            deserialize the RCert Data. If RCert is being extracted from
            inside of other structure (E.g PClaim capnproto) use the
            `extractInnerRCert(bytes, uint)` instead.
    */
    /// @param src Binary state containing a RCert serialized struct with Capn Proto headers
    /// @return the RCert struct
    /// @dev Execution cost: 4076 gas
    function extractRCert(bytes memory src) internal pure returns (RCert memory) {
        return extractInnerRCert(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for deserializing the RCert struct from an defined
            location inside a binary blob. E.G Extract RCert from inside of
            other structure (E.g RCert capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary state containing a RCert serialized struct without Capn Proto headers
    /// @param dataOffset offset to start reading the RCert state from inside src
    /// @return rCert the RCert struct
    /// @dev Execution cost: 3691 gas
    function extractInnerRCert(
        bytes memory src,
        uint256 dataOffset
    ) internal pure returns (RCert memory rCert) {
        if (dataOffset + _RCERT_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        if (src.length < dataOffset + _RCERT_SIZE) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + _RCERT_SIZE
            );
        }
        rCert.rClaims = RClaimsParserLibrary.extractInnerRClaims(src, dataOffset + 16);
        (rCert.sigGroupPublicKey, rCert.sigGroupSignature) = extractSigGroup(src, dataOffset + 72);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/GenericParserLibraryErrors.sol";

import "contracts/libraries/parsers/BaseParserLibrary.sol";

/// @title Library to parse the RClaims structure from a blob of capnproto state
library RClaimsParserLibrary {
    struct RClaims {
        uint32 chainId;
        uint32 height;
        uint32 round;
        bytes32 prevBlock;
    }

    /** @dev size in bytes of a RCLAIMS cap'npro structure without the cap'n
      proto header bytes*/
    uint256 internal constant _RCLAIMS_SIZE = 56;
    /** @dev Number of bytes of a capnproto header, the state starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;

    /**
    @notice This function is for deserializing state directly from capnproto
            RClaims. It will skip the first 8 bytes (capnproto headers) and
            deserialize the RClaims Data. If RClaims is being extracted from
            inside of other structure (E.g RCert capnproto) use the
            `extractInnerRClaims(bytes, uint)` instead.
    */
    /// @param src Binary state containing a RClaims serialized struct with Capn Proto headers
    /// @dev Execution cost: 1506 gas
    function extractRClaims(bytes memory src) internal pure returns (RClaims memory rClaims) {
        return extractInnerRClaims(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for serializing the RClaims struct from an defined
            location inside a binary blob. E.G Extract RClaims from inside of
            other structure (E.g RCert capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary state containing a RClaims serialized struct without Capn Proto headers
    /// @param dataOffset offset to start reading the RClaims state from inside src
    /// @dev Execution cost: 1332 gas
    function extractInnerRClaims(
        bytes memory src,
        uint256 dataOffset
    ) internal pure returns (RClaims memory rClaims) {
        if (dataOffset + _RCLAIMS_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        if (src.length < dataOffset + _RCLAIMS_SIZE) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + _RCLAIMS_SIZE
            );
        }
        rClaims.chainId = BaseParserLibrary.extractUInt32(src, dataOffset);
        if (rClaims.chainId == 0) {
            revert GenericParserLibraryErrors.ChainIdZero();
        }
        rClaims.height = BaseParserLibrary.extractUInt32(src, dataOffset + 4);
        if (rClaims.height == 0) {
            revert GenericParserLibraryErrors.HeightZero();
        }
        rClaims.round = BaseParserLibrary.extractUInt32(src, dataOffset + 8);
        if (rClaims.round == 0) {
            revert GenericParserLibraryErrors.RoundZero();
        }
        rClaims.prevBlock = BaseParserLibrary.extractBytes32(src, dataOffset + 24);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/GenericParserLibraryErrors.sol";
import "contracts/libraries/parsers/BaseParserLibrary.sol";

/// @title Library to parse the TXInPreImage structure from a blob of capnproto state
library TXInPreImageParserLibrary {
    struct TXInPreImage {
        uint32 chainId;
        uint32 consumedTxIdx;
        bytes32 consumedTxHash; //todo: is always 32 bytes?
    }
    /** @dev size in bytes of a TXInPreImage cap'npro structure without the cap'n
      proto header bytes*/
    uint256 internal constant _TX_IN_PRE_IMAGE_SIZE = 48;
    /** @dev Number of bytes of a capnproto header, the state starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;

    /**
    @notice This function is for deserializing state directly from capnproto
            TXInPreImage. It will skip the first 8 bytes (capnproto headers) and
            deserialize the TXInPreImage Data. If TXInPreImage is being extracted from
            inside of other structure use the
            `extractTXInPreImage(bytes, uint)` instead.
    */
    /// @param src Binary state containing a TXInPreImage serialized struct with Capn Proto headers
    /// @dev Execution cost: 1120 gas
    /// @return a TXInPreImage struct
    function extractTXInPreImage(bytes memory src) internal pure returns (TXInPreImage memory) {
        return extractInnerTXInPreImage(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for deserializing the TXInPreImage struct from an defined
            location inside a binary blob. E.G Extract TXInPreImage from inside of
            other structure (E.g RCert capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary state containing a TXInPreImage serialized struct without CapnProto headers
    /// @param dataOffset offset to start reading the TXInPreImage state from inside src
    /// @dev Execution cost: 1084 gas
    /// @return txInPreImage a TXInPreImage struct
    function extractInnerTXInPreImage(
        bytes memory src,
        uint256 dataOffset
    ) internal pure returns (TXInPreImage memory txInPreImage) {
        if (dataOffset + _TX_IN_PRE_IMAGE_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        if (src.length < dataOffset + _TX_IN_PRE_IMAGE_SIZE) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + _TX_IN_PRE_IMAGE_SIZE
            );
        }
        txInPreImage.chainId = BaseParserLibrary.extractUInt32(src, dataOffset);
        if (txInPreImage.chainId == 0) {
            revert GenericParserLibraryErrors.ChainIdZero();
        }
        txInPreImage.consumedTxIdx = BaseParserLibrary.extractUInt32(src, dataOffset + 4);
        txInPreImage.consumedTxHash = BaseParserLibrary.extractBytes32(src, dataOffset + 16);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyImplementationGetter {
    function __getProxyImplementation(address _proxy) internal view returns (address implAddress) {
        bytes memory cdata = hex"0cbcae703c";
        assembly ("memory-safe") {
            let success := staticcall(gas(), _proxy, add(cdata, 0x20), mload(cdata), 0x00, 0x00)
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, returndatasize()))
            returndatacopy(ptr, 0x00, returndatasize())
            if iszero(success) {
                revert(ptr, returndatasize())
            }
            implAddress := shr(96, mload(ptr))
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyInternalUpgradeLock {
    function __lockImplementation() internal {
        assembly ("memory-safe") {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                or(
                    0xca11c0de15dead10deadc0de0000000000000000000000000000000000000000,
                    and(
                        sload(implSlot),
                        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                    )
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyInternalUpgradeUnlock {
    function __unlockImplementation() internal {
        assembly ("memory-safe") {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                and(
                    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff,
                    sload(implSlot)
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyUpgrader {
    function __upgrade(address _proxy, address _newImpl) internal {
        bytes memory cdata = abi.encodePacked(hex"ca11c0de11", uint256(uint160(_newImpl)));
        assembly ("memory-safe") {
            let success := call(gas(), _proxy, 0, add(cdata, 0x20), mload(cdata), 0x00, 0x00)
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, returndatasize()))
            returndatacopy(ptr, 0x00, returndatasize())
            if iszero(success) {
                revert(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/libraries/errors/SnapshotsErrors.sol";

struct Epoch {
    uint32 _value;
}

struct SnapshotBuffer {
    Snapshot[6] _array;
}

library RingBuffer {
    /***
     * @dev: Sets a new snapshot safely inside the ring buffer.
     * @param epochFor_: anonymous function to convert a height in an _epoch value.
     * @param new_: the new snapshot.
     * @return the the epoch number where the snapshot was stored.
     */
    function set(
        SnapshotBuffer storage self_,
        function(uint32) returns (uint32) epochFor_,
        Snapshot memory new_
    ) internal returns (uint32) {
        //get the epoch corresponding to the blocknumber
        uint32 epoch = epochFor_(new_.blockClaims.height);
        //gets the snapshot that was at that location of the buffer
        Snapshot storage old = self_._array[indexFor(self_, epoch)];
        //checks if the new snapshot height is greater than the previous
        if (new_.blockClaims.height <= old.blockClaims.height) {
            revert SnapshotsErrors.InvalidRingBufferBlockHeight(
                new_.blockClaims.height,
                old.blockClaims.height
            );
        }
        unsafeSet(self_, new_, epoch);
        return epoch;
    }

    /***
     * @dev: Sets a new snapshot inside the ring buffer in a specific index.
     * Don't call this function directly, use set() instead.
     * @param new_: the new snapshot.
     * @param epoch_: the index (epoch) where the new snapshot will be stored.
     */
    function unsafeSet(SnapshotBuffer storage self_, Snapshot memory new_, uint32 epoch_) internal {
        self_._array[indexFor(self_, epoch_)] = new_;
    }

    /**
     * @dev gets the snapshot value at an specific index (epoch).
     * @param epoch_: the index to retrieve a snapshot.
     * @return the snapshot stored at the epoch_ location.
     */
    function get(
        SnapshotBuffer storage self_,
        uint32 epoch_
    ) internal view returns (Snapshot storage) {
        return self_._array[indexFor(self_, epoch_)];
    }

    /**
     * @dev calculates the congruent value for current epoch in respect to the array length
     * for index to be replaced with most recent epoch.
     * @param epoch_ epoch_ number associated with the snapshot.
     * @return the index corresponding to the epoch number.
     */
    function indexFor(SnapshotBuffer storage self_, uint32 epoch_) internal view returns (uint256) {
        if (epoch_ == 0) {
            revert SnapshotsErrors.EpochMustBeNonZero();
        }
        return epoch_ % self_._array.length;
    }
}

library EpochLib {
    /***
     * @dev sets an epoch value in Epoch struct.
     * @param value_: the epoch value.
     */
    function set(Epoch storage self_, uint32 value_) internal {
        self_._value = value_;
    }

    /***
     * @dev gets the latest epoch value stored in the Epoch struct.
     * @return the latest epoch value stored in the Epoch struct.
     */
    function get(Epoch storage self_) internal view returns (uint32) {
        return self_._value;
    }
}

abstract contract SnapshotRingBuffer {
    using RingBuffer for SnapshotBuffer;
    using EpochLib for Epoch;

    /**
     * @notice Assigns the snapshot to correct index and updates __epoch
     * @param snapshot_ to be stored
     * @return epoch of the passed snapshot
     */
    function _setSnapshot(Snapshot memory snapshot_) internal returns (uint32) {
        uint32 epoch = _getSnapshots().set(_getEpochFromHeight, snapshot_);
        _epochRegister().set(epoch);
        return epoch;
    }

    /**
     * @notice Returns the snapshot for the passed epoch
     * @param epoch_ of the snapshot
     */
    function _getSnapshot(uint32 epoch_) internal view returns (Snapshot memory snapshot) {
        if (epoch_ == 0) {
            return Snapshot(0, BClaimsParserLibrary.BClaims(0, 0, 0, 0, 0, 0, 0));
        }
        //get the pointer to the specified epoch snapshot
        Snapshot memory snapshot_ = _getSnapshots().get(epoch_);
        if (_getEpochFromHeight(snapshot_.blockClaims.height) != epoch_) {
            revert SnapshotsErrors.SnapshotsNotInBuffer(epoch_);
        }
        return snapshot_;
    }

    /***
     * @dev: gets the latest snapshot stored in the ring buffer.
     * @return ok if the struct is valid and the snapshot struct itself
     */
    function _getLatestSnapshot() internal view returns (Snapshot memory snapshot) {
        return _getSnapshot(_epochRegister().get());
    }

    // Must be defined in storage contract
    function _getEpochFromHeight(uint32) internal view virtual returns (uint32);

    // Must be defined in storage contract
    function _getSnapshots() internal view virtual returns (SnapshotBuffer storage);

    // Must be defined in storage contract
    function _epochRegister() internal view virtual returns (Epoch storage);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/auth/ImmutableDynamics.sol";
import "contracts/libraries/snapshots/SnapshotRingBuffer.sol";

abstract contract SnapshotsStorage is
    ImmutableETHDKG,
    ImmutableValidatorPool,
    SnapshotRingBuffer,
    ImmutableDynamics
{
    uint256 internal immutable _epochLength;

    uint256 internal immutable _chainId;

    // Number of ethereum blocks that we should wait between snapshots. Mainly used to prevent the
    // submission of snapshots in short amount of time by validators that could be potentially being
    // malicious
    uint32 internal _minimumIntervalBetweenSnapshots;

    // after how many eth blocks of not having a snapshot will we start allowing more validators to
    // make it
    uint32 internal _snapshotDesperationDelay;

    // how quickly more validators will be allowed to make a snapshot, once
    // _snapshotDesperationDelay has passed
    uint32 internal _snapshotDesperationFactor;

    //epoch counter wrapped in a struct
    Epoch internal _epoch;
    //new snapshot ring buffer
    SnapshotBuffer internal _snapshots;

    constructor(
        uint256 chainId_,
        uint256 epochLength_
    ) ImmutableFactory(msg.sender) ImmutableETHDKG() ImmutableValidatorPool() ImmutableDynamics() {
        _chainId = chainId_;
        _epochLength = epochLength_;
    }

    function _getEpochFromHeight(uint32 height_) internal view override returns (uint32) {
        if (height_ <= _epochLength) {
            return 1;
        }
        if (height_ % _epochLength == 0) {
            return uint32(height_ / _epochLength);
        }
        return uint32((height_ / _epochLength) + 1);
    }

    function _getSnapshots() internal view override returns (SnapshotBuffer storage) {
        return _snapshots;
    }

    function _epochRegister() internal view override returns (Epoch storage) {
        return _epoch;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "contracts/libraries/governance/GovernanceMaxLock.sol";
import "contracts/libraries/StakingNFT/StakingNFTStorage.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/auth/ImmutableGovernance.sol";
import "contracts/utils/auth/ImmutableStakingPositionDescriptor.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicValue.sol";
import "contracts/utils/CircuitBreaker.sol";
import "contracts/utils/AtomicCounter.sol";
import "contracts/interfaces/ICBOpener.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IStakingNFTDescriptor.sol";
import "contracts/libraries/errors/StakingNFTErrors.sol";
import "contracts/libraries/errors/CircuitBreakerErrors.sol";

abstract contract StakingNFT is
    Initializable,
    ERC721EnumerableUpgradeable,
    CircuitBreaker,
    AtomicCounter,
    StakingNFTStorage,
    MagicValue,
    EthSafeTransfer,
    ERC20SafeTransfer,
    GovernanceMaxLock,
    ICBOpener,
    IStakingNFT,
    ImmutableFactory,
    ImmutableValidatorPool,
    ImmutableALCA,
    ImmutableGovernance,
    ImmutableStakingPositionDescriptor
{
    modifier onlyIfTokenExists(uint256 tokenID_) {
        if (!_exists(tokenID_)) {
            revert StakingNFTErrors.InvalidTokenId(tokenID_);
        }
        _;
    }

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableALCA()
        ImmutableGovernance()
        ImmutableValidatorPool()
        ImmutableStakingPositionDescriptor()
    {}

    /// @dev tripCB opens the circuit breaker may only be called by _factory owner
    function tripCB() public override onlyFactory {
        _tripCB();
    }

    /// skimExcessEth will send to the address passed as to_ any amount of Eth
    /// held by this contract that is not tracked by the Accumulator system. This
    /// function allows the Admin role to refund any Eth sent to this contract in
    /// error by a user. This method can not return any funds sent to the contract
    /// via the depositEth method. This function should only be necessary if a
    /// user somehow manages to accidentally selfDestruct a contract with this
    /// contract as the recipient.
    function skimExcessEth(address to_) public onlyFactory returns (uint256 excess) {
        excess = _estimateExcessEth();
        _safeTransferEth(to_, excess);
        return excess;
    }

    /// skimExcessToken will send to the address passed as to_ any amount of
    /// ALCA held by this contract that is not tracked by the Accumulator
    /// system. This function allows the Admin role to refund any ALCA sent to
    /// this contract in error by a user. This method can not return any funds
    /// sent to the contract via the depositToken method.
    function skimExcessToken(address to_) public onlyFactory returns (uint256 excess) {
        IERC20Transferable alca;
        (alca, excess) = _estimateExcessToken();
        _safeTransferERC20(alca, to_, excess);
        return excess;
    }

    /// lockPosition is called by governance system when a governance
    /// vote is cast. This function will lock the specified Position for up to
    /// _MAX_GOVERNANCE_LOCK. This method may only be called by the governance
    /// contract. This function will fail if the circuit breaker is tripped
    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) public override withCircuitBreaker onlyGovernance returns (uint256) {
        if (caller_ != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockPosition(tokenID_, lockDuration_);
    }

    /// This function will lock an owned Position for up to _MAX_GOVERNANCE_LOCK. This method may
    /// only be called by the owner of the Position. This function will fail if the circuit breaker
    /// is tripped
    function lockOwnPosition(
        uint256 tokenID_,
        uint256 lockDuration_
    ) public withCircuitBreaker returns (uint256) {
        if (msg.sender != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockPosition(tokenID_, lockDuration_);
    }

    /// This function will lock withdraws on the specified Position for up to
    /// _MAX_GOVERNANCE_LOCK. This function will fail if the circuit breaker is tripped
    function lockWithdraw(
        uint256 tokenID_,
        uint256 lockDuration_
    ) public withCircuitBreaker returns (uint256) {
        if (msg.sender != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockWithdraw(tokenID_, lockDuration_);
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION AS ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY. depositToken distributes ALCA
    /// to all stakers evenly should only be called during a slashing event. Any
    /// ALCA sent to this method in error will be lost. This function will
    /// fail if the circuit breaker is tripped. The magic_ parameter is intended
    /// to stop some one from successfully interacting with this method without
    /// first reading the source code and hopefully this comment
    function depositToken(
        uint8 magic_,
        uint256 amount_
    ) public withCircuitBreaker checkMagic(magic_) {
        // collect tokens
        _safeTransferFromERC20(IERC20Transferable(_alcaAddress()), msg.sender, amount_);
        // update state
        _tokenState = _deposit(amount_, _tokenState);
        _reserveToken += amount_;
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY depositEth distributes Eth to all
    /// stakers evenly should only be called by ALCBs contract any Eth sent to
    /// this method in error will be lost this function will fail if the circuit
    /// breaker is tripped the magic_ parameter is intended to stop some one from
    /// successfully interacting with this method without first reading the
    /// source code and hopefully this comment
    function depositEth(uint8 magic_) public payable withCircuitBreaker checkMagic(magic_) {
        _ethState = _deposit(msg.value, _ethState);
        _reserveEth += msg.value;
    }

    /// mint allows a staking position to be opened. This function
    /// requires the caller to have performed an approve invocation against
    /// ALCA into this contract. This function will fail if the circuit
    /// breaker is tripped.
    function mint(uint256 amount_) public virtual withCircuitBreaker returns (uint256 tokenID) {
        return _mintNFT(msg.sender, amount_);
    }

    /// mintTo allows a staking position to be opened in the name of an
    /// account other than the caller. This method also allows a lock to be
    /// placed on the position up to _MAX_MINT_LOCK . This function requires the
    /// caller to have performed an approve invocation against ALCA into
    /// this contract. This function will fail if the circuit breaker is
    /// tripped.
    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) public virtual withCircuitBreaker returns (uint256 tokenID) {
        if (lockDuration_ > _MAX_MINT_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanMintLock();
        }
        tokenID = _mintNFT(to_, amount_);
        if (lockDuration_ > 0) {
            _lockPosition(tokenID, lockDuration_);
        }
        return tokenID;
    }

    /// burn exits a staking position such that all accumulated value is
    /// transferred to the owner on burn.
    function burn(uint256 tokenID_) public virtual returns (uint256 payoutEth, uint256 payoutALCA) {
        return _burn(msg.sender, msg.sender, tokenID_);
    }

    /// burnTo exits a staking position such that all accumulated value
    /// is transferred to a specified account on burn
    function burnTo(
        address to_,
        uint256 tokenID_
    ) public virtual returns (uint256 payoutEth, uint256 payoutALCA) {
        return _burn(msg.sender, to_, tokenID_);
    }

    /// collects the ether yield of a given position. The caller of this function
    /// must be the owner of the tokenID.
    function collectEth(uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectEthTo(msg.sender, tokenID_);
    }

    /// collects the ALCa tokens yield of a given position. The caller of
    /// this function must be the owner of the tokenID.
    function collectToken(uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectTokenTo(msg.sender, tokenID_);
    }

    /// collects the ether and ALCa tokens yields of a given position. The caller of
    /// this function must be the owner of the tokenID.
    function collectAllProfits(
        uint256 tokenID_
    ) public returns (uint256 payoutEth, uint256 payoutToken) {
        payoutToken = _collectTokenTo(msg.sender, tokenID_);
        payoutEth = _collectEthTo(msg.sender, tokenID_);
    }

    /// collects the ether yield of a given position and send to the `to_` address.
    /// The caller of this function must be the owner of the tokenID.
    function collectEthTo(address to_, uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectEthTo(to_, tokenID_);
    }

    /// collects the ALCa tokens yield of a given position and send to the `to_`
    /// address. The caller of this function must be the owner of the tokenID.
    function collectTokenTo(address to_, uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectTokenTo(to_, tokenID_);
    }

    /// collects the ether and ALCa tokens yields of a given position and send to the
    /// `to_` address. The caller of this function must be the owner of the tokenID.
    function collectAllProfitsTo(
        address to_,
        uint256 tokenID_
    ) public returns (uint256 payoutEth, uint256 payoutToken) {
        payoutToken = _collectTokenTo(to_, tokenID_);
        payoutEth = _collectEthTo(to_, tokenID_);
    }

    /// gets the total amount of ALCA staked in contract
    function getTotalShares() public view returns (uint256) {
        return _shares;
    }

    /// gets the total amount of Ether staked in contract
    function getTotalReserveEth() public view returns (uint256) {
        return _reserveEth;
    }

    /// gets the total amount of ALCA staked in contract
    function getTotalReserveALCA() public view returns (uint256) {
        return _reserveToken;
    }

    /// estimateEthCollection returns the amount of eth a tokenID may withdraw
    function estimateEthCollection(
        uint256 tokenID_
    ) public view onlyIfTokenExists(tokenID_) returns (uint256 payout) {
        Position memory p = _positions[tokenID_];
        Accumulator memory ethState = _ethState;
        uint256 shares = _shares;
        (, , , payout) = _calculateCollection(shares, ethState, p, p.accumulatorEth);
        return payout;
    }

    /// estimateTokenCollection returns the amount of ALCA a tokenID may withdraw
    function estimateTokenCollection(
        uint256 tokenID_
    ) public view onlyIfTokenExists(tokenID_) returns (uint256 payout) {
        Position memory p = _positions[tokenID_];
        uint256 shares = _shares;
        Accumulator memory tokenState = _tokenState;
        (, , , payout) = _calculateCollection(shares, tokenState, p, p.accumulatorToken);
        return payout;
    }

    /// estimateAllProfits returns the amount of ALCA a tokenID may withdraw
    function estimateAllProfits(
        uint256 tokenID_
    ) public view onlyIfTokenExists(tokenID_) returns (uint256 payoutEth, uint256 payoutToken) {
        Position memory p = _positions[tokenID_];
        uint256 shares = _shares;
        (, , , payoutEth) = _calculateCollection(shares, _ethState, p, p.accumulatorEth);
        (, , , payoutToken) = _calculateCollection(shares, _tokenState, p, p.accumulatorToken);
    }

    /// estimateExcessToken returns the amount of ALCA that is held in the
    /// name of this contract. The value returned is the value that would be
    /// returned by a call to skimExcessToken.
    function estimateExcessToken() public view returns (uint256 excess) {
        (, excess) = _estimateExcessToken();
        return excess;
    }

    /// estimateExcessEth returns the amount of Eth that is held in the name of
    /// this contract. The value returned is the value that would be returned by
    /// a call to skimExcessEth.
    function estimateExcessEth() public view returns (uint256 excess) {
        return _estimateExcessEth();
    }

    /// gets the position struct given a tokenID. The tokenId must
    /// exist.
    function getPosition(
        uint256 tokenID_
    )
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        )
    {
        Position memory p = _positions[tokenID_];
        shares = uint256(p.shares);
        freeAfter = uint256(p.freeAfter);
        withdrawFreeAfter = uint256(p.withdrawFreeAfter);
        accumulatorEth = p.accumulatorEth;
        accumulatorToken = p.accumulatorToken;
    }

    /// Gets token URI
    function tokenURI(
        uint256 tokenID_
    ) public view override(ERC721Upgradeable) onlyIfTokenExists(tokenID_) returns (string memory) {
        return IStakingNFTDescriptor(_stakingPositionDescriptorAddress()).tokenURI(this, tokenID_);
    }

    /// gets the current value for the Eth accumulator
    function getEthAccumulator() public view returns (uint256 accumulator, uint256 slush) {
        accumulator = _ethState.accumulator;
        slush = _ethState.slush;
    }

    /// gets the current value for the Token accumulator
    function getTokenAccumulator() public view returns (uint256 accumulator, uint256 slush) {
        accumulator = _tokenState.accumulator;
        slush = _tokenState.slush;
    }

    /// gets the ID of the latest minted position
    function getLatestMintedPositionID() public view returns (uint256) {
        return _getCount();
    }

    /// gets the _ACCUMULATOR_SCALE_FACTOR used to scale the ether and tokens
    /// deposited on this contract to reduce the integer division errors.
    function getAccumulatorScaleFactor() public pure returns (uint256) {
        return _ACCUMULATOR_SCALE_FACTOR;
    }

    /// gets the _MAX_MINT_LOCK value. This value is the maximum duration of blocks that we allow a
    /// position to be locked when minted
    function getMaxMintLock() public pure returns (uint256) {
        return _MAX_MINT_LOCK;
    }

    /// gets the _MAX_MINT_LOCK value. This value is the maximum duration of blocks that we allow a
    /// position to be locked
    function getMaxGovernanceLock() public pure returns (uint256) {
        return _MAX_GOVERNANCE_LOCK;
    }

    function __stakingNFTInit(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
    }

    // _lockPosition prevents a position from being burned for duration_ number
    // of blocks by setting the freeAfter field on the Position struct returns
    // the number of shares in the locked Position so that governance vote
    // counting may be performed when setting a lock
    //
    // Note well: This function *assumes* that tokenID position exists.
    //            This is because the existance check is performed
    //            at the higher level.
    function _lockPosition(
        uint256 tokenID_,
        uint256 duration_
    ) internal onlyIfTokenExists(tokenID_) returns (uint256 shares) {
        Position memory p = _positions[tokenID_];
        uint32 freeDur = uint32(block.number) + uint32(duration_);
        p.freeAfter = freeDur > p.freeAfter ? freeDur : p.freeAfter;
        _positions[tokenID_] = p;
        return p.shares;
    }

    // _lockWithdraw prevents a position from being collected and burned for duration_ number of blocks
    // by setting the withdrawFreeAfter field on the Position struct.
    // returns the number of shares in the locked Position so that
    //
    // Note well: This function *assumes* that tokenID position exists.
    //            This is because the existance check is performed
    //            at the higher level.
    function _lockWithdraw(
        uint256 tokenID_,
        uint256 duration_
    ) internal onlyIfTokenExists(tokenID_) returns (uint256 shares) {
        Position memory p = _positions[tokenID_];
        uint256 freeDur = block.number + duration_;
        p.withdrawFreeAfter = freeDur > p.withdrawFreeAfter ? freeDur : p.withdrawFreeAfter;
        _positions[tokenID_] = p;
        return p.shares;
    }

    // _mintNFT performs the mint operation and invokes the inherited _mint method
    function _mintNFT(address to_, uint256 amount_) internal returns (uint256 tokenID) {
        // this is to allow struct packing and is safe due to ALCA having a
        // total distribution of 220M
        if (amount_ == 0) {
            revert StakingNFTErrors.MintAmountZero();
        }
        if (amount_ > 2 ** 224 - 1) {
            revert StakingNFTErrors.MintAmountExceedsMaximumSupply();
        }
        // transfer the number of tokens specified by amount_ into contract
        // from the callers account
        _safeTransferFromERC20(IERC20Transferable(_alcaAddress()), msg.sender, amount_);

        // get local copy of storage vars to save gas
        uint256 shares = _shares;
        Accumulator memory ethState = _ethState;
        Accumulator memory tokenState = _tokenState;

        // get new tokenID from counter
        tokenID = _increment();

        // Call _slushSkim on Eth and Token accumulator before minting staked position.
        // This ensures that all stakers receive their appropriate rewards.
        if (shares > 0) {
            (ethState.accumulator, ethState.slush) = _slushSkim(
                shares,
                ethState.accumulator,
                ethState.slush
            );
            _ethState = ethState;
            (tokenState.accumulator, tokenState.slush) = _slushSkim(
                shares,
                tokenState.accumulator,
                tokenState.slush
            );
            _tokenState = tokenState;
        }

        // update storage
        shares += amount_;
        _shares = shares;
        _positions[tokenID] = Position(
            uint224(amount_),
            uint32(block.number) + 1,
            uint32(block.number) + 1,
            ethState.accumulator,
            tokenState.accumulator
        );
        _reserveToken += amount_;
        // invoke inherited method and return
        ERC721Upgradeable._mint(to_, tokenID);
        return tokenID;
    }

    // _burn performs the burn operation and invokes the inherited _burn method
    function _burn(
        address from_,
        address to_,
        uint256 tokenID_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        if (from_ != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }

        // collect state
        Position memory p = _positions[tokenID_];
        // enforce freeAfter to prevent burn during lock
        if (p.freeAfter >= block.number || p.withdrawFreeAfter >= block.number) {
            revert StakingNFTErrors.FreeAfterTimeNotReached();
        }

        // get copy of storage to save gas
        uint256 shares = _shares;

        // calc Eth amounts due
        (p, payoutEth) = _collectEth(shares, p);

        // calc token amounts due
        (p, payoutToken) = _collectToken(shares, p);

        // add back to token payout the original stake position
        payoutToken += p.shares;

        // debit global shares counter and delete from mapping
        _shares -= p.shares;
        _reserveToken -= payoutToken;
        _reserveEth -= payoutEth;
        delete _positions[tokenID_];

        // invoke inherited burn method
        ERC721Upgradeable._burn(tokenID_);

        // transfer out all eth and tokens owed
        _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, payoutToken);
        _safeTransferEth(to_, payoutEth);
        return (payoutEth, payoutToken);
    }

    /// collectEth returns all due Eth allocations to the to_ address. The caller
    /// of this function must be the owner of the tokenID
    function _collectEthTo(address to_, uint256 tokenID_) internal returns (uint256 payout) {
        Position memory position = _getPositionToCollect(tokenID_);
        // get values and update state
        (_positions[tokenID_], payout) = _collectEth(_shares, position);
        _reserveEth -= payout;
        // perform transfer and return amount paid out
        _safeTransferEth(to_, payout);
        return payout;
    }

    function _collectTokenTo(address to_, uint256 tokenID_) internal returns (uint256 payout) {
        Position memory position = _getPositionToCollect(tokenID_);
        // get values and update state
        (_positions[tokenID_], payout) = _collectToken(_shares, position);
        _reserveToken -= payout;
        // perform transfer and return amount paid out
        _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, payout);
        return payout;
    }

    function _collectToken(
        uint256 shares_,
        Position memory p_
    ) internal returns (Position memory p, uint256 payout) {
        uint256 acc;
        Accumulator memory tokenState = _tokenState;
        (tokenState, p, acc, payout) = _calculateCollection(
            shares_,
            tokenState,
            p_,
            p_.accumulatorToken
        );
        _tokenState = tokenState;
        p.accumulatorToken = acc;
        return (p, payout);
    }

    // _collectEth performs call to _collect and updates state during a request
    // for an eth distribution
    function _collectEth(
        uint256 shares_,
        Position memory p_
    ) internal returns (Position memory p, uint256 payout) {
        uint256 acc;
        Accumulator memory ethState = _ethState;
        (ethState, p, acc, payout) = _calculateCollection(shares_, ethState, p_, p_.accumulatorEth);
        _ethState = ethState;
        p.accumulatorEth = acc;
        return (p, payout);
    }

    // _estimateExcessEth returns the amount of Eth that is held in the name of
    // this contract
    function _estimateExcessEth() internal view returns (uint256 excess) {
        uint256 reserve = _reserveEth;
        uint256 balance = address(this).balance;
        if (balance < reserve) {
            revert StakingNFTErrors.BalanceLessThanReserve(balance, reserve);
        }
        excess = balance - reserve;
    }

    // _estimateExcessToken returns the amount of ALCA that is held in the
    // name of this contract
    function _estimateExcessToken()
        internal
        view
        returns (IERC20Transferable alca, uint256 excess)
    {
        uint256 reserve = _reserveToken;
        alca = IERC20Transferable(_alcaAddress());
        uint256 balance = alca.balanceOf(address(this));
        if (balance < reserve) {
            revert StakingNFTErrors.BalanceLessThanReserve(balance, reserve);
        }
        excess = balance - reserve;
        return (alca, excess);
    }

    function _getPositionToCollect(
        uint256 tokenID_
    ) internal view returns (Position memory position) {
        address owner = ownerOf(tokenID_);
        if (msg.sender != owner) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        position = _positions[tokenID_];
        if (_positions[tokenID_].withdrawFreeAfter >= block.number) {
            revert StakingNFTErrors.LockDurationWithdrawTimeNotReached();
        }
    }

    // _calculateCollection performs calculations necessary to determine any distributions
    // due to an account such that it may be used for both token and eth
    // distributions this prevents the need to keep redundant logic
    function _calculateCollection(
        uint256 shares_,
        Accumulator memory state_,
        Position memory p_,
        uint256 positionAccumulatorValue_
    ) internal pure returns (Accumulator memory, Position memory, uint256, uint256) {
        (state_.accumulator, state_.slush) = _slushSkim(shares_, state_.accumulator, state_.slush);
        // determine number of accumulator steps this Position needs distributions from
        uint256 accumulatorDelta;
        if (positionAccumulatorValue_ > state_.accumulator) {
            accumulatorDelta = 2 ** 168 - positionAccumulatorValue_;
            accumulatorDelta += state_.accumulator;
            positionAccumulatorValue_ = state_.accumulator;
        } else {
            accumulatorDelta = state_.accumulator - positionAccumulatorValue_;
            // update accumulator value for calling method
            positionAccumulatorValue_ += accumulatorDelta;
        }
        // calculate payout based on shares held in position
        uint256 payout = accumulatorDelta * p_.shares;
        // if there are no shares other than this position, flush the slush fund
        // into the payout and update the in memory state object
        if (shares_ == p_.shares) {
            payout += state_.slush;
            state_.slush = 0;
        }

        uint256 payoutRemainder = payout;
        // reduce payout by scale factor
        payout /= _ACCUMULATOR_SCALE_FACTOR;
        // Computing and saving the numeric error from the floor division in the
        // slush.
        payoutRemainder -= payout * _ACCUMULATOR_SCALE_FACTOR;
        state_.slush += payoutRemainder;

        return (state_, p_, positionAccumulatorValue_, payout);
    }

    // _deposit allows an Accumulator to be updated with new value if there are
    // no currently staked positions, all value is stored in the slush
    function _deposit(
        uint256 delta_,
        Accumulator memory state_
    ) internal pure returns (Accumulator memory) {
        state_.slush += (delta_ * _ACCUMULATOR_SCALE_FACTOR);

        // Slush should be never be above 2**167 to protect against overflow in
        // the later code.
        if (state_.slush >= 2 ** 167) {
            revert StakingNFTErrors.SlushTooLarge(state_.slush);
        }
        return state_;
    }

    // _slushSkim flushes value from the slush into the accumulator if there are
    // no currently staked positions, all value is stored in the slush
    function _slushSkim(
        uint256 shares_,
        uint256 accumulator_,
        uint256 slush_
    ) internal pure returns (uint256, uint256) {
        if (shares_ > 0) {
            uint256 deltaAccumulator = slush_ / shares_;
            slush_ -= deltaAccumulator * shares_;
            accumulator_ += deltaAccumulator;
            // avoiding accumulator_ overflow.
            if (accumulator_ > type(uint168).max) {
                // The maximum allowed value for the accumulator is 2**168-1.
                // This hard limit was set to not overflow the operation
                // `accumulator * shares` that happens later in the code.
                accumulator_ = accumulator_ % (2 ** 168);
            }
        }
        return (accumulator_, slush_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract StakingNFTStorage {
    // Position describes a staked position
    struct Position {
        // number of alca
        uint224 shares;
        // block number after which the position may be burned.
        // prevents double spend of voting weight
        uint32 freeAfter;
        // block number after which the position may be collected or burned.
        uint256 withdrawFreeAfter;
        // the last value of the ethState accumulator this account performed a
        // withdraw at
        uint256 accumulatorEth;
        // the last value of the tokenState accumulator this account performed a
        // withdraw at
        uint256 accumulatorToken;
    }

    // Accumulator is a struct that allows values to be collected such that the
    // remainders of floor division may be cleaned up
    struct Accumulator {
        // accumulator is a sum of all changes always increasing
        uint256 accumulator;
        // slush stores division remainders until they may be distributed evenly
        uint256 slush;
    }

    // _MAX_MINT_LOCK describes the maximum interval a Position may be locked
    // during a call to mintTo
    uint256 internal constant _MAX_MINT_LOCK = 1051200;
    // 10**18
    uint256 internal constant _ACCUMULATOR_SCALE_FACTOR = 1000000000000000000;

    // _shares stores total amount of ALCA staked in contract
    uint256 internal _shares;

    // _tokenState tracks distribution of ALCA that originate from slashing
    // events
    Accumulator internal _tokenState;

    // _ethState tracks the distribution of Eth that originate from the sale of
    // ALCBs
    Accumulator internal _ethState;

    // _positions tracks all staked positions based on tokenID
    mapping(uint256 => Position) internal _positions;

    // state to keep track of the amount of Eth deposited and collected from the
    // contract
    uint256 internal _reserveEth;

    // state to keep track of the amount of ALCAs deposited and collected
    // from the contract
    uint256 internal _reserveToken;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/DeterministicAddress.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

abstract contract ValidatorPoolStorage is
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutablePublicStaking,
    ImmutableValidatorStaking,
    ImmutableALCA
{
    // POSITION_LOCK_PERIOD describes the maximum interval a PublicStaking Position may be locked after
    // being given back to validator exiting the pool
    uint256 public constant POSITION_LOCK_PERIOD = 172800;
    // Interval in AliceNet Epochs that a validator exiting the pool should before claiming is
    // PublicStaking position
    uint256 public constant CLAIM_PERIOD = 3;

    // Maximum number the ethereum blocks allowed without a validator committing a snapshot
    uint256 internal _maxIntervalWithoutSnapshots;

    // Minimum amount to stake
    uint256 internal _stakeAmount;
    // Max number of validators allowed in the pool
    uint256 internal _maxNumValidators;
    // Value in WEIs to be discounted of dishonest validator in case of slashing event. This value
    // is usually sent back to the disputer
    uint256 internal _disputerReward;

    // Boolean flag to be read by the snapshot contract in order to decide if the validator set
    // needs to be changed or not (i.e if a validator is going to be removed or added).
    bool internal _isMaintenanceScheduled;
    // Boolean flag to keep track if the consensus is running in the side chain or not. Validators
    // can only join or leave the pool in case this value is false.
    bool internal _isConsensusRunning;

    // The internal iterable mapping that tracks all ACTIVE validators in the Pool
    ValidatorDataMap internal _validators;

    // Mapping that keeps track of the validators leaving the Pool. Validators assets are hold by
    // `CLAIM_PERIOD` epochs before the user being able to claim the assets back in the form a new
    // PublicStaking position.
    mapping(address => ExitingValidatorData) internal _exitingValidatorsData;

    // Mapping to keep track of the active validators IPs.
    mapping(address => string) internal _ipLocations;

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutablePublicStaking()
        ImmutableValidatorStaking()
        ImmutableALCA()
    {}
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";

/// @custom:salt LiquidityProviderStaking
/// @custom:deploy-type deployUpgradeable
contract LiquidityProviderStaking is StakingNFT {
    constructor() StakingNFT() {}

    function initialize() public onlyFactory initializer {
        __stakingNFTInit("ALQSNFT", "ALQS");
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IERC721Transferable.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/BonusPool.sol";
import "contracts/RewardPool.sol";

/**
 * @notice This contract locks up publicStaking position for a certain period. The position is
 *  transferred to this contract, and the original owner is entitled to collect profits, and unlock
 *  the position. If the position was kept locked until the end of the locking period, the original
 *  owner will be able to get the original position back, plus any profits gained by the position
 *  (e.g from ALCB sale) + a bonus amount based on the amount of shares of the public staking
 *  position.
 *
 *  Original owner will be able to collect profits from the position normally during the locking
 *  period. However, a certain percentage will be held by the contract and only distributed after the
 *  locking period has finished and the user unlocks.
 *
 *  Original owner will be able to unlock position (partially or fully) before the locking period has
 *  finished. The owner will able to decide which will be the amount unlocked earlier (called
 *  exitAmount). In case of full exit (exitAmount == positionShares), the owner will not get the
 *  percentage of profits of that position that are held by this contract and he will not receive any
 *  bonus amount. In case, of partial exit (exitAmount < positionShares), the owner will be loosing
 *  only the profits + bonus relative to the exiting amount.
 *
 *
 * @dev deployed by the AliceNetFactory contract
 */

/// @custom:salt Lockup
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group lockup
/// @custom:deploy-group-index 0
contract Lockup is
    ImmutablePublicStaking,
    ImmutableALCA,
    ERC20SafeTransfer,
    EthSafeTransfer,
    ERC721Holder
{
    enum State {
        PreLock,
        InLock,
        PostLock
    }

    uint256 public constant SCALING_FACTOR = 10 ** 18;
    uint256 public constant FRACTION_RESERVED = SCALING_FACTOR / 5;
    // rewardPool contract address
    address internal immutable _rewardPool;
    // bonusPool contract address
    address internal immutable _bonusPool;
    // block on which lock starts
    uint256 internal immutable _startBlock;
    // block on which lock ends
    uint256 internal immutable _endBlock;
    // Total Locked describes the total number of ALCA locked in this contract.
    // Since no accumulators are used this is tracked to allow proportionate
    // payouts.
    uint256 internal _totalSharesLocked;
    // _ownerOf tracks who is the owner of a tokenID locked in this contract
    // mapping(tokenID -> owner).
    mapping(uint256 => address) internal _ownerOf;
    // _tokenOf is the inverse of ownerOf and returns the owner given the tokenID
    // users are only allowed 1 position per account, mapping (owner -> tokenID).
    mapping(address => uint256) internal _tokenOf;

    // maps and index to a tokenID for iterable counting i.e (index ->  tokenID).
    // Stop iterating when token id is zero. Must use tail insert to delete or else
    // pagination will end early.
    mapping(uint256 => uint256) internal _tokenIDs;
    // lookup index by ID (tokenID -> index).
    mapping(uint256 => uint256) internal _reverseTokenIDs;
    // tracks the number of tokenIDs this contract holds.
    uint256 internal _lenTokenIDs;

    // support mapping to keep track all the ethereum owed to user to be
    // redistributed in the postLock phase during safe mode.
    mapping(address => uint256) internal _rewardEth;
    // support mapping to keep track all the token owed to user to be
    // redistributed in the postLock phase during safe mode.
    mapping(address => uint256) internal _rewardTokens;
    // Flag to determine if we are in the postLock phase safe or unsafe, i.e if
    // users are allowed to withdrawal or not. All profits need to be collect by all
    // positions before setting the safe mode.
    bool public payoutSafe;

    // offset for pagination when collecting the profits in the postLock unsafe
    // phase. Many people may call aggregateProfits until all rewards has been
    // collected.
    uint256 internal _tokenIDOffset;

    event EarlyExit(address to_, uint256 tokenID_);
    event NewLockup(address from_, uint256 tokenID_);

    modifier onlyPreLock() {
        if (_getState() != State.PreLock) {
            revert LockupErrors.PreLockStateRequired();
        }
        _;
    }

    modifier excludePreLock() {
        if (_getState() == State.PreLock) {
            revert LockupErrors.PreLockStateNotAllowed();
        }
        _;
    }

    modifier onlyPostLock() {
        if (_getState() != State.PostLock) {
            revert LockupErrors.PostLockStateRequired();
        }
        _;
    }

    modifier excludePostLock() {
        if (_getState() == State.PostLock) {
            revert LockupErrors.PostLockStateNotAllowed();
        }
        _;
    }

    modifier onlyPayoutSafe() {
        if (!payoutSafe) {
            revert LockupErrors.PayoutUnsafe();
        }
        _;
    }

    modifier onlyPayoutUnSafe() {
        if (payoutSafe) {
            revert LockupErrors.PayoutSafe();
        }
        _;
    }

    modifier onlyInLock() {
        if (_getState() != State.InLock) {
            revert LockupErrors.InLockStateRequired();
        }
        _;
    }

    constructor(
        uint256 enrollmentPeriod_,
        uint256 lockDuration_,
        uint256 totalBonusAmount_
    ) ImmutableFactory(msg.sender) ImmutablePublicStaking() ImmutableALCA() {
        RewardPool rewardPool = new RewardPool(
            _alcaAddress(),
            _factoryAddress(),
            totalBonusAmount_
        );
        _rewardPool = address(rewardPool);
        _bonusPool = rewardPool.getBonusPoolAddress();
        _startBlock = block.number + enrollmentPeriod_;
        _endBlock = _startBlock + lockDuration_;
    }

    /// @dev only publicStaking and rewardPool are allowed to send ether to this contract
    receive() external payable {
        if (msg.sender != _publicStakingAddress() && msg.sender != _rewardPool) {
            revert LockupErrors.AddressNotAllowedToSendEther();
        }
    }

    /// @notice callback function called by the ERC721.safeTransfer. On safe transfer of
    /// publicStaking positions to this contract, it will be performing checks and in case everything
    /// is fine, that position will be locked in name of the original owner that performed the
    /// transfer
    /// @dev publicStaking positions can only be safe transferred to this contract on PreLock phase
    /// (enrollment phase)
    /// @param from_ original owner of the publicStaking Position. The position will locked for this
    /// address
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    function onERC721Received(
        address,
        address from_,
        uint256 tokenID_,
        bytes memory
    ) public override onlyPreLock returns (bytes4) {
        if (msg.sender != _publicStakingAddress()) {
            revert LockupErrors.OnlyStakingNFTAllowed();
        }

        _lockFromTransfer(tokenID_, from_);
        return this.onERC721Received.selector;
    }

    /// @notice transfer and locks a pre-approved publicStaking position to this contract
    /// @dev can only be called at PreLock phase (enrollment phase)
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    function lockFromApproval(uint256 tokenID_) public {
        // msg.sender already approved transfer, so contract can safeTransfer to itself; by doing
        // this onERC721Received is called as part of the chain of transfer methods hence the checks
        // run from within onERC721Received
        IERC721Transferable(_publicStakingAddress()).safeTransferFrom(
            msg.sender,
            address(this),
            tokenID_
        );
    }

    /// @notice locks a position that was already transferred to this contract without using
    /// safeTransfer. WARNING: SHOULD ONLY BE USED FROM SMART CONTRACT THAT TRANSFERS A POSITION AND
    /// CALL THIS METHOD RIGHT IN SEQUENCE
    /// @dev can only be called at PreLock phase (enrollment phase)
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    /// @param tokenOwner_ The address that will be used as the user entitled to that position
    function lockFromTransfer(uint256 tokenID_, address tokenOwner_) public onlyPreLock {
        _lockFromTransfer(tokenID_, tokenOwner_);
    }

    /// @notice collects all profits from a position locked up by this contract. Only a certain
    /// amount of the profits will be sent, the rest will held by the contract and released at the
    /// final unlock.
    /// @dev can only be called if the PostLock phase has not began
    /// @dev can only be called by position's entitled owner
    /// @return payoutEth the amount of eth that was sent to user
    /// @return payoutToken the amount of ALCA that was sent to user
    function collectAllProfits()
        public
        excludePostLock
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        return _collectAllProfits(_payableSender(), _validateAndGetTokenId());
    }

    /// @notice function to partially or fully unlock a locked position. The entitled owner will
    /// able to decide which will be the amount unlocked earlier (exitValue_). In case of full exit
    /// (exitValue_ == positionShares), the owner will not get the percentage of profits of that
    /// position that are held by this contract and he will not receive any bonus amount. In case, of
    /// partial exit (exitValue_< positionShares), the owner will be loosing only the profits + bonus
    /// relative to the exiting amount. The owner may choose via stakeExit_ boolean if the ALCA will be
    /// sent a new publicStaking position or as ALCA directly to his address.
    /// @dev can only be called if the PostLock phase has not began
    /// @dev can only be called by position's entitled owner
    /// @param exitValue_ The amount in which the user wants to unlock earlier
    /// @param stakeExit_ Flag to decide the ALCA will be sent directly or staked as new
    /// publicStaking position
    /// @return payoutEth the amount of eth that was sent to user discounting the reserved amount
    /// @return payoutToken the amount of ALCA discounting the reserved amount that was sent or
    /// staked as new position to the user
    function unlockEarly(
        uint256 exitValue_,
        bool stakeExit_
    ) public excludePostLock returns (uint256 payoutEth, uint256 payoutToken) {
        uint256 tokenID = _validateAndGetTokenId();
        // get the number of shares and check validity
        uint256 shares = _getNumShares(tokenID);
        if (exitValue_ > shares) {
            revert LockupErrors.InsufficientBalanceForEarlyExit(exitValue_, shares);
        }
        // burn the existing position
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).burn(tokenID);
        // separating alca reward from alca shares
        payoutToken -= shares;
        // blank old record
        _ownerOf[tokenID] = address(0);
        // create placeholder
        uint256 newTokenID;
        // find shares delta and mint new position
        uint256 remainingShares = shares - exitValue_;
        if (remainingShares > 0) {
            // approve the transfer of ALCA in order to mint the publicStaking position
            IERC20(_alcaAddress()).approve(_publicStakingAddress(), remainingShares);
            // burn profits contain staked position... so sub it out
            newTokenID = IStakingNFT(_publicStakingAddress()).mint(remainingShares);
            // set new records
            _ownerOf[newTokenID] = msg.sender;
            _replaceTokenID(tokenID, newTokenID);
        } else {
            _removeTokenID(tokenID);
        }
        // safe because newTokenId is zero if shares == exitValue
        _tokenOf[msg.sender] = newTokenID;
        _totalSharesLocked -= exitValue_;
        (payoutEth, payoutToken) = _distributeAllProfits(
            _payableSender(),
            payoutEth,
            payoutToken,
            exitValue_,
            stakeExit_
        );
        emit EarlyExit(msg.sender, tokenID);
    }

    /// @notice aggregateProfits iterate alls locked positions and collect their profits before
    /// allowing withdraws/unlocks. This step is necessary to make sure that the correct reserved
    /// amount is in the rewardPool before allowing unlocks. This function will not send any ether or
    /// ALCA to users, since this can be very dangerous (specially on a loop). Instead all the
    /// assets that are not sent to the rewardPool are held in the lockup contract, and the right
    /// balance is stored per position owner. All the value will be send to the owner address at the
    /// call of the `{unlock()}` function. This function can only be called after the locking period
    /// has finished. Anyone can call this function.
    function aggregateProfits() public onlyPayoutUnSafe onlyPostLock {
        // get some gas cost tracking setup
        uint256 gasStart = gasleft();
        uint256 gasLoop;
        // start index where we left off plus one
        uint256 i = _tokenIDOffset + 1;
        // for loop that will exit when one of following is true the gas remaining is less than 5x
        // the estimated per iteration cost or the iterator is done
        for (; ; i++) {
            (uint256 tokenID, bool ok) = _getTokenIDAtIndex(i);
            if (!ok) {
                // if we get here, iteration of array is done and we can move on with life and set
                // payoutSafe since all payouts have been recorded
                payoutSafe = true;
                // burn the bonus Position and send the bonus to the rewardPool contract
                BonusPool(payable(_bonusPool)).terminate();
                break;
            }
            address payable acct = _getOwnerOf(tokenID);
            _collectAllProfits(acct, tokenID);
            uint256 gasRem = gasleft();
            if (gasLoop == 0) {
                // record gas iteration estimate if not done
                gasLoop = gasStart - gasRem;
                // give 5x multi on it to ensure even an overpriced element by 2x the normal
                // cost will still pass
                gasLoop = 5 * gasLoop;
                // accounts for state writes on exit
                gasLoop = gasLoop + 10000;
            } else if (gasRem <= gasLoop) {
                // if we are below cutoff break
                break;
            }
        }
        _tokenIDOffset = i;
    }

    /// @notice unlocks a locked position and collect all kind of profits (bonus shares, held
    /// rewards etc). Can only be called after the locking period has finished and {aggregateProfits}
    /// has been executed for positions. Can only be called by the user entitled to a position
    /// (address that locked a position). This function can only be called after the locking period
    /// has finished and {aggregateProfits()} has been executed for all locked positions.
    /// @param to_ destination address were the profits, shares will be sent
    /// @param stakeExit_ boolean flag indicating if the ALCA should be returned directly or staked
    /// into a new publicStaking position.
    /// @return payoutEth the ether amount deposited to an address after unlock
    /// @return payoutToken the ALCA amount staked or sent to an address after unlock
    function unlock(
        address to_,
        bool stakeExit_
    ) public onlyPostLock onlyPayoutSafe returns (uint256 payoutEth, uint256 payoutToken) {
        uint256 tokenID = _validateAndGetTokenId();
        uint256 shares = _getNumShares(tokenID);
        bool isLastPosition = _lenTokenIDs == 1;

        (payoutEth, payoutToken) = _burnLockedPosition(tokenID, msg.sender);

        (uint256 accumulatedRewardEth, uint256 accumulatedRewardToken) = RewardPool(_rewardPool)
            .payout(_totalSharesLocked, shares, isLastPosition);
        payoutEth += accumulatedRewardEth;
        payoutToken += accumulatedRewardToken;

        (uint256 aggregatedEth, uint256 aggregatedToken) = _withdrawalAggregatedAmount(msg.sender);
        payoutEth += aggregatedEth;
        payoutToken += aggregatedToken;
        _transferEthAndTokensWithReStake(to_, payoutEth, payoutToken, stakeExit_);
    }

    /// @notice gets the address that is entitled to unlock/collect profits for a position. I.e the
    /// address that locked this position into this contract.
    /// @param tokenID_ the position Id to retrieve the owner
    /// @return the owner address of a position. Returns 0 if a position is not locked into this
    /// contract
    function ownerOf(uint256 tokenID_) public view returns (address payable) {
        return _getOwnerOf(tokenID_);
    }

    /// @notice gets the positionID that an address is entitled to unlock/collect profits. I.e
    /// position that an address locked into this contract.
    /// @param acct_ address to retrieve a position (tokenID)
    /// @return the position ID (tokenID) of the position that the address locked into this
    /// contract. If an address doesn't possess any locked position in this contract, this function
    /// returns 0
    function tokenOf(address acct_) public view returns (uint256) {
        return _getTokenOf(acct_);
    }

    /// @notice gets the total number of positions locked into this contract. Can be used with
    /// {getIndexByTokenId} and {getPositionByIndex} to get all publicStaking positions held by this
    /// contract.
    /// @return the total number of positions locked into this contract
    function getCurrentNumberOfLockedPositions() public view returns (uint256) {
        return _lenTokenIDs;
    }

    /// @notice gets the position referenced by an index in the enumerable mapping implemented by
    /// this contract. Can be used {getIndexByTokenId} to get all positions IDs locked by this
    /// contract.
    /// @param index_ the index to get the positionID
    /// @return the tokenId referenced by an index the enumerable mapping (indexes start at 1). If
    /// the index doesn't exists this function returns 0
    function getPositionByIndex(uint256 index_) public view returns (uint256) {
        return _tokenIDs[index_];
    }

    /// @notice gets the index of a position in the enumerable mapping implemented by this contract.
    /// Can be used {getPositionByIndex} to get all positions IDs locked by this contract.
    /// @param tokenID_ the position ID to get index for
    /// @return the index of a position in the enumerable mapping (indexes start at 1). If the
    /// tokenID is not locked into this contract this function returns 0
    function getIndexByTokenId(uint256 tokenID_) public view returns (uint256) {
        return _reverseTokenIDs[tokenID_];
    }

    /// @notice gets the ethereum block where the locking period will start. This block is also
    /// when the enrollment period will finish. I.e after this block we don't allow new positions to
    /// be locked.
    /// @return the ethereum block where the locking period will start
    function getLockupStartBlock() public view returns (uint256) {
        return _startBlock;
    }

    /// @notice gets the ethereum block where the locking period will end. After this block
    /// aggregateProfit has to be called to enable the unlock period.
    /// @return the ethereum block where the locking period will end
    function getLockupEndBlock() public view returns (uint256) {
        return _endBlock;
    }

    /// @notice gets the ether and ALCA balance owed to a user after aggregateProfit has been
    /// called. This funds are send after final unlock.
    /// @return user ether balance held by this contract
    /// @return user ALCA balance held by this contract
    function getTemporaryRewardBalance(address user_) public view returns (uint256, uint256) {
        return _getTemporaryRewardBalance(user_);
    }

    /// @notice gets the RewardPool contract address
    /// @return the reward pool contract address
    function getRewardPoolAddress() public view returns (address) {
        return _rewardPool;
    }

    /// @notice gets the bonusPool contract address
    /// @return the bonusPool contract address
    function getBonusPoolAddress() public view returns (address) {
        return _bonusPool;
    }

    /// @notice gets the current amount of ALCA that is locked in this contract, after all early exits
    /// @return the amount of ALCA that is currently locked in this contract
    function getTotalSharesLocked() public view returns (uint256) {
        return _totalSharesLocked;
    }

    /// @notice gets the current state of the lockup (preLock, InLock, PostLock)
    /// @return the current state of the lockup contract
    function getState() public view returns (State) {
        return _getState();
    }

    /// @notice estimate the (liquid) income that can be collected from locked positions via
    /// {collectAllProfits}
    /// @dev this functions deducts the reserved amount that is sent to rewardPool contract
    function estimateProfits(
        uint256 tokenID_
    ) public view returns (uint256 payoutEth, uint256 payoutToken) {
        // check if the position owned by this contract
        _verifyLockedPosition(tokenID_);
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).estimateAllProfits(
            tokenID_
        );
        (uint256 reserveEth, uint256 reserveToken) = _computeReservedAmount(payoutEth, payoutToken);
        payoutEth -= reserveEth;
        payoutToken -= reserveToken;
    }

    /// @notice function to estimate the final amount of ALCA and ether that a locked
    /// position will receive at the end of the locking period. Depending on the preciseEstimation_ flag this function can be an imprecise approximation,
    /// the real amount can differ especially as user's collect profits in the middle of the locking
    /// period. Passing preciseEstimation_ as true will give a precise estimate since all profits are aggregated in a loop,
    /// hence is optional as it can be expensive if called as part of a smart contract transaction that alters state. After the locking
    /// period has finished and aggregateProfits has been executed for all locked positions the estimate will also be accurate.
    /// @dev this function is just an approximation when preciseEstimation_ is false, the real amount can differ!
    /// @param tokenID_ The token to check for the final profits.
    /// @param preciseEstimation_ whether to use the precise estimation or the approximation (precise is expensive due to looping so use wisely)
    /// @return positionShares_ the positions ALCA shares
    /// @return payoutEth_ the ether amount that the position will receive as profit
    /// @return payoutToken_ the ALCA amount that the position will receive as profit
    function estimateFinalBonusWithProfits(
        uint256 tokenID_,
        bool preciseEstimation_
    ) public view returns (uint256 positionShares_, uint256 payoutEth_, uint256 payoutToken_) {
        // check if the position owned by this contract
        _verifyLockedPosition(tokenID_);
        positionShares_ = _getNumShares(tokenID_);

        uint256 currentSharesLocked = _totalSharesLocked;

        // get the bonus amount + any profit from the bonus staked position
        (payoutEth_, payoutToken_) = BonusPool(payable(_bonusPool)).estimateBonusAmountWithReward(
            currentSharesLocked,
            positionShares_
        );

        //  get the cumulative rewards held in the rewardPool so far. In the case that
        // aggregateProfits has not been ran, the amount returned by this call may not be precise,
        // since only some users may have been collected until this point, in which case
        // preciseEstimation_ can be passed as true to get a precise estimate.
        (uint256 rewardEthProfit, uint256 rewardTokenProfit) = RewardPool(_rewardPool)
            .estimateRewards(currentSharesLocked, positionShares_);
        payoutEth_ += rewardEthProfit;
        payoutToken_ += rewardTokenProfit;

        uint256 reservedEth;
        uint256 reservedToken;

        // if aggregateProfits has been called (indicated by the payoutSafe flag), this calculation is not needed
        if (preciseEstimation_ && !payoutSafe) {
            // get this positions share based on all user profits aggregated (NOTE: precise but expensive due to the loop)
            (reservedEth, reservedToken) = _estimateUserAggregatedProfits(
                positionShares_,
                currentSharesLocked
            );
        } else {
            // get any future profit that will be held in the rewardPool for this position
            (uint256 positionEthProfit, uint256 positionTokenProfit) = IStakingNFT(
                _publicStakingAddress()
            ).estimateAllProfits(tokenID_);
            (reservedEth, reservedToken) = _computeReservedAmount(
                positionEthProfit,
                positionTokenProfit
            );
        }

        payoutEth_ += reservedEth;
        payoutToken_ += reservedToken;

        // get any eth and token held by this contract as result of the call to the aggregateProfit
        // function
        (uint256 aggregatedEth, uint256 aggregatedTokens) = _getTemporaryRewardBalance(
            _getOwnerOf(tokenID_)
        );
        payoutEth_ += aggregatedEth;
        payoutToken_ += aggregatedTokens;
    }

    /// @notice return the percentage amount that is held from the locked positions
    /// @dev this value is scaled by 100. Therefore the values are from 0-100%
    /// @return the percentage amount that is held from the locked positions
    function getReservedPercentage() public pure returns (uint256) {
        return (100 * FRACTION_RESERVED) / SCALING_FACTOR;
    }

    /// @notice gets the fraction of the amount that is reserved to reward pool
    /// @return the calculated reserved amount
    function getReservedAmount(uint256 amount_) public pure returns (uint256) {
        return (amount_ * FRACTION_RESERVED) / SCALING_FACTOR;
    }

    function _lockFromTransfer(uint256 tokenID_, address tokenOwner_) internal {
        _validateEntry(tokenID_, tokenOwner_);
        _checkTokenTransfer(tokenID_);
        _lock(tokenID_, tokenOwner_);
    }

    function _lock(uint256 tokenID_, address tokenOwner_) internal {
        uint256 shares = _verifyPositionAndGetShares(tokenID_);
        _totalSharesLocked += shares;
        _tokenOf[tokenOwner_] = tokenID_;
        _ownerOf[tokenID_] = tokenOwner_;
        _newTokenID(tokenID_);
        emit NewLockup(tokenOwner_, tokenID_);
    }

    function _burnLockedPosition(
        uint256 tokenID_,
        address tokenOwner_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        // burn the old position
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).burn(tokenID_);
        //delete tokenID_ from iterable tokenID mapping
        _removeTokenID(tokenID_);
        delete (_tokenOf[tokenOwner_]);
        delete (_ownerOf[tokenID_]);
    }

    function _withdrawalAggregatedAmount(
        address account_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        // case of we are sending out final pay based on request just pay all
        payoutEth = _rewardEth[account_];
        payoutToken = _rewardTokens[account_];
        _rewardEth[account_] = 0;
        _rewardTokens[account_] = 0;
    }

    function _collectAllProfits(
        address payable acct_,
        uint256 tokenID_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).collectAllProfits(tokenID_);
        return _distributeAllProfits(acct_, payoutEth, payoutToken, 0, false);
    }

    function _distributeAllProfits(
        address payable acct_,
        uint256 payoutEth_,
        uint256 payoutToken_,
        uint256 additionalTokens,
        bool stakeExit_
    ) internal returns (uint256 userPayoutEth, uint256 userPayoutToken) {
        State state = _getState();
        bool localPayoutSafe = payoutSafe;
        userPayoutEth = payoutEth_;
        userPayoutToken = payoutToken_;
        (uint256 reservedEth, uint256 reservedToken) = _computeReservedAmount(
            payoutEth_,
            payoutToken_
        );
        userPayoutEth -= reservedEth;
        userPayoutToken -= reservedToken;
        // send tokens to reward pool
        _depositFundsInRewardPool(reservedEth, reservedToken);
        // in case this is being called by {aggregateProfits()} we don't send any asset to the
        // users, we just store the owed amounts on state
        if (!localPayoutSafe && state == State.PostLock) {
            // we should not send here and should instead track to local mapping as
            // otherwise a single bad user could block exit operations for all other users
            // by making the send to their account fail via a contract
            _rewardEth[acct_] += userPayoutEth;
            _rewardTokens[acct_] += userPayoutToken;
            return (userPayoutEth, userPayoutToken);
        }
        // adding any additional token that should be sent to the user (e.g shares from
        // burned position on early exit)
        userPayoutToken += additionalTokens;
        _transferEthAndTokensWithReStake(acct_, userPayoutEth, userPayoutToken, stakeExit_);
        return (userPayoutEth, userPayoutToken);
    }

    function _transferEthAndTokensWithReStake(
        address to_,
        uint256 payoutEth_,
        uint256 payoutToken_,
        bool stakeExit_
    ) internal {
        if (stakeExit_) {
            IERC20(_alcaAddress()).approve(_publicStakingAddress(), payoutToken_);
            IStakingNFT(_publicStakingAddress()).mintTo(to_, payoutToken_, 0);
        } else {
            _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, payoutToken_);
        }
        _safeTransferEth(to_, payoutEth_);
    }

    function _newTokenID(uint256 tokenID_) internal {
        uint256 index = _lenTokenIDs + 1;
        _tokenIDs[index] = tokenID_;
        _reverseTokenIDs[tokenID_] = index;
        _lenTokenIDs = index;
    }

    function _replaceTokenID(uint256 oldID_, uint256 newID_) internal {
        uint256 index = _reverseTokenIDs[oldID_];
        _reverseTokenIDs[oldID_] = 0;
        _tokenIDs[index] = newID_;
        _reverseTokenIDs[newID_] = index;
    }

    function _removeTokenID(uint256 tokenID_) internal {
        uint256 initialLen = _lenTokenIDs;
        if (initialLen == 0) {
            return;
        }
        if (initialLen == 1) {
            uint256 index = _reverseTokenIDs[tokenID_];
            _reverseTokenIDs[tokenID_] = 0;
            _tokenIDs[index] = 0;
            _lenTokenIDs = 0;
            return;
        }
        // pop the tail
        uint256 tailTokenID = _tokenIDs[initialLen];
        _tokenIDs[initialLen] = 0;
        _lenTokenIDs = initialLen - 1;
        if (tailTokenID == tokenID_) {
            // element was tail, so we are done
            _reverseTokenIDs[tailTokenID] = 0;
            return;
        }
        // use swap logic to re-insert tail over other position
        _replaceTokenID(tokenID_, tailTokenID);
    }

    function _depositFundsInRewardPool(uint256 reservedEth_, uint256 reservedToken_) internal {
        _safeTransferERC20(IERC20Transferable(_alcaAddress()), _rewardPool, reservedToken_);
        RewardPool(_rewardPool).deposit{value: reservedEth_}(reservedToken_);
    }

    function _getNumShares(uint256 tokenID_) internal view returns (uint256 shares) {
        (shares, , , , ) = IStakingNFT(_publicStakingAddress()).getPosition(tokenID_);
    }

    function _estimateTotalAggregatedProfits()
        internal
        view
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        for (uint256 i = 1; i <= _lenTokenIDs; i++) {
            (uint256 tokenID, ) = _getTokenIDAtIndex(i);
            (uint256 stakingProfitEth, uint256 stakingProfitToken) = IStakingNFT(
                _publicStakingAddress()
            ).estimateAllProfits(tokenID);
            (uint256 reserveEth, uint256 reserveToken) = _computeReservedAmount(
                stakingProfitEth,
                stakingProfitToken
            );
            payoutEth += reserveEth;
            payoutToken += reserveToken;
        }
    }

    function _estimateUserAggregatedProfits(
        uint256 userShares_,
        uint256 totalShares_
    ) internal view returns (uint256 payoutEth, uint256 payoutToken) {
        (payoutEth, payoutToken) = _estimateTotalAggregatedProfits();
        payoutEth = (payoutEth * userShares_) / totalShares_;
        payoutToken = (payoutToken * userShares_) / totalShares_;
    }

    function _payableSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _getTokenIDAtIndex(uint256 index_) internal view returns (uint256 tokenID, bool ok) {
        tokenID = _tokenIDs[index_];
        return (tokenID, tokenID > 0);
    }

    function _checkTokenTransfer(uint256 tokenID_) internal view {
        if (IERC721(_publicStakingAddress()).ownerOf(tokenID_) != address(this)) {
            revert LockupErrors.ContractDoesNotOwnTokenID(tokenID_);
        }
    }

    function _validateEntry(uint256 tokenID_, address sender_) internal view {
        if (_getOwnerOf(tokenID_) != address(0)) {
            revert LockupErrors.TokenIDAlreadyClaimed(tokenID_);
        }
        if (_getTokenOf(sender_) != 0) {
            revert LockupErrors.AddressAlreadyLockedUp();
        }
    }

    function _validateAndGetTokenId() internal view returns (uint256) {
        // get tokenID of caller
        uint256 tokenID = _getTokenOf(msg.sender);
        if (tokenID == 0) {
            revert LockupErrors.UserHasNoPosition();
        }
        return tokenID;
    }

    function _verifyLockedPosition(uint256 tokenID_) internal view {
        if (_getOwnerOf(tokenID_) == address(0)) {
            revert LockupErrors.TokenIDNotLocked(tokenID_);
        }
    }

    // Gets the shares of position and checks if a position exists and if we can collect the
    // profits after the _endBlock.
    function _verifyPositionAndGetShares(uint256 tokenId_) internal view returns (uint256) {
        // get position fails if the position doesn't exists!
        (uint256 shares, , uint256 withdrawFreeAfter, , ) = IStakingNFT(_publicStakingAddress())
            .getPosition(tokenId_);
        if (withdrawFreeAfter >= _endBlock) {
            revert LockupErrors.InvalidPositionWithdrawPeriod(withdrawFreeAfter, _endBlock);
        }
        return shares;
    }

    function _getState() internal view returns (State) {
        if (block.number < _startBlock) {
            return State.PreLock;
        }
        if (block.number < _endBlock) {
            return State.InLock;
        }
        return State.PostLock;
    }

    function _getOwnerOf(uint256 tokenID_) internal view returns (address payable) {
        return payable(_ownerOf[tokenID_]);
    }

    function _getTokenOf(address acct_) internal view returns (uint256) {
        return _tokenOf[acct_];
    }

    function _getTemporaryRewardBalance(address user_) internal view returns (uint256, uint256) {
        return (_rewardEth[user_], _rewardTokens[user_]);
    }

    function _computeReservedAmount(
        uint256 payoutEth_,
        uint256 payoutToken_
    ) internal pure returns (uint256 reservedEth, uint256 reservedToken) {
        reservedEth = (payoutEth_ * FRACTION_RESERVED) / SCALING_FACTOR;
        reservedToken = (payoutToken_ * FRACTION_RESERVED) / SCALING_FACTOR;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/libraries/parsers/PClaimsParserLibrary.sol";
import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/AccusationsLibrary.sol";
import "contracts/libraries/errors/AccusationsErrors.sol";

/// @custom:salt MultipleProposalAccusation
/// @custom:deploy-type deployUpgradeable
/// @custom:salt-type Accusation
contract MultipleProposalAccusation is
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutableValidatorPool
{
    mapping(bytes32 => bool) internal _accusations;

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutableValidatorPool()
    {}

    /// @notice This function validates an accusation of multiple proposals.
    /// @param _signature0 The signature of pclaims0
    /// @param _pClaims0 The PClaims of the accusation
    /// @param _signature1 The signature of pclaims1
    /// @param _pClaims1 The PClaims of the accusation
    /// @return the address of the signer
    function accuseMultipleProposal(
        bytes calldata _signature0,
        bytes calldata _pClaims0,
        bytes calldata _signature1,
        bytes calldata _pClaims1
    ) public view returns (address) {
        // ecrecover sig0/1 and ensure both are valid and accounts are equal
        address signerAccount0 = AccusationsLibrary.recoverMadNetSigner(_signature0, _pClaims0);
        address signerAccount1 = AccusationsLibrary.recoverMadNetSigner(_signature1, _pClaims1);

        if (signerAccount0 != signerAccount1) {
            revert AccusationsErrors.SignersDoNotMatch(signerAccount0, signerAccount1);
        }

        // ensure the hashes of blob0/1 are different
        if (keccak256(_pClaims0) == keccak256(_pClaims1)) {
            revert AccusationsErrors.PClaimsAreEqual();
        }

        PClaimsParserLibrary.PClaims memory pClaims0 = PClaimsParserLibrary.extractPClaims(
            _pClaims0
        );
        PClaimsParserLibrary.PClaims memory pClaims1 = PClaimsParserLibrary.extractPClaims(
            _pClaims1
        );

        // ensure the height of blob0/1 are equal using RCert sub object of PClaims
        if (pClaims0.rCert.rClaims.height != pClaims1.rCert.rClaims.height) {
            revert AccusationsErrors.PClaimsHeightsDoNotMatch(
                pClaims0.rCert.rClaims.height,
                pClaims1.rCert.rClaims.height
            );
        }

        // ensure the round of blob0/1 are equal using RCert sub object of PClaims
        if (pClaims0.rCert.rClaims.round != pClaims1.rCert.rClaims.round) {
            revert AccusationsErrors.PClaimsRoundsDoNotMatch(
                pClaims0.rCert.rClaims.round,
                pClaims1.rCert.rClaims.round
            );
        }

        // ensure the chainid of blob0/1 are equal using RCert sub object of PClaims
        if (pClaims0.rCert.rClaims.chainId != pClaims1.rCert.rClaims.chainId) {
            revert AccusationsErrors.PClaimsChainIdsDoNotMatch(
                pClaims0.rCert.rClaims.chainId,
                pClaims1.rCert.rClaims.chainId
            );
        }

        // ensure the chainid of blob0 is correct for this chain using RCert sub object of PClaims
        uint256 chainId = ISnapshots(_snapshotsAddress()).getChainId();
        if (pClaims0.rCert.rClaims.chainId != chainId) {
            revert AccusationsErrors.InvalidChainId(pClaims0.rCert.rClaims.chainId, chainId);
        }

        // ensure both accounts are applicable to a currently locked validator - Note<may be done in different layer?>
        if (!IValidatorPool(_validatorPoolAddress()).isAccusable(signerAccount0)) {
            revert AccusationsErrors.SignerNotValidValidator(signerAccount0);
        }

        return signerAccount0;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

/**
 * @notice Proxy is a delegatecall reverse proxy implementation that is secure against function
 * collision.
 *
 * The forwarding address is stored at the slot location of not(0). If not(0) has a value stored in
 * it that is of the form 0xca11c0de15dead10deadc0de< address > the proxy may no longer be upgraded
 * using the internal mechanism. This does not prevent the implementation from upgrading the proxy
 * by changing this slot.
 *
 * The proxy may be directly upgraded ( if the lock is not set ) by calling the proxy from the
 * factory address using the format abi.encodeWithSelector(0xca11c0de11, <address>);
 *
 * The proxy can return its implementation address by calling it using the format
 * abi.encodePacked(hex'0cbcae703c');
 *
 * All other calls will be proxied through to the implementation.
 *
 * The implementation can not be locked using the internal upgrade mechanism due to the fact that
 * the internal mechanism zeros out the higher order bits. Therefore, the implementation itself must
 * carry the locking mechanism that sets the higher order bits to lock the upgrade capability of the
 * proxy.
 *
 * @dev RUN OPTIMIZER OFF
 */
contract Proxy {
    address private immutable _factory;

    constructor() {
        _factory = msg.sender;
    }

    receive() external payable {
        _fallback();
    }

    fallback() external payable {
        _fallback();
    }

    /// Delegates calls to proxy implementation
    function _fallback() internal {
        // make local copy of factory since immutables are not accessible in assembly as of yet
        address factory = _factory;
        assembly ("memory-safe") {
            // check if the calldata has the special signatures to access the proxy functions. To
            // avoid collision the signatures for the proxy function are 5 bytes long (instead of
            // the normal 4).
            if or(eq(calldatasize(), 0x25), eq(calldatasize(), 0x5)) {
                {
                    let selector := shr(216, calldataload(0x00))
                    switch selector
                    // getImplementationAddress()
                    case 0x0cbcae703c {
                        let ptr := mload(0x40)
                        mstore(ptr, getImplementationAddress())
                        return(ptr, 0x14)
                    }
                    // setImplementationAddress()
                    case 0xca11c0de11 {
                        // revert in case user is not factory/admin
                        if iszero(eq(caller(), factory)) {
                            revertASM("unauthorized", 12)
                        }
                        // if caller is factory, and has 0xca11c0de00<address> as calldata,
                        // run admin logic and return
                        setImplementationAddress()
                    }
                    default {
                        revertASM("function not found", 18)
                    }
                }
            }
            // admin logic was not run so fallthrough to delegatecall
            passthrough()

            ///////////// Functions ///////////////

            function revertASM(str, len) {
                let ptr := mload(0x40)
                let startPtr := ptr
                mstore(ptr, hex"08c379a0") // keccak256('Error(string)')[0:4]
                ptr := add(ptr, 0x4)
                mstore(ptr, 0x20)
                ptr := add(ptr, 0x20)
                mstore(ptr, len) // string length
                ptr := add(ptr, 0x20)
                mstore(ptr, str)
                ptr := add(ptr, 0x20)
                revert(startPtr, sub(ptr, startPtr))
            }

            function getImplementationAddress() -> implAddr {
                implAddr := shl(
                    96,
                    and(
                        sload(not(0x00)),
                        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                    )
                )
            }

            // updateImplementation is the builtin logic to change the implementation
            function setImplementationAddress() {
                // check if the upgrade functionality is locked.
                if eq(shr(160, sload(not(0x00))), 0xca11c0de15dead10deadc0de) {
                    revertASM("update locked", 13)
                }
                // this is an assignment to implementation
                let newImpl := shr(96, shl(96, calldataload(0x05)))
                // store address into slot
                sstore(not(0x00), newImpl)
                // stop to not fall into the default case of the switch selector
                stop()
            }

            // passthrough is the passthrough logic to delegate to the implementation
            function passthrough() {
                let logicAddress := sload(not(0x00))
                if iszero(logicAddress) {
                    revertASM("logic not set", 13)
                }
                // load free memory pointer
                let ptr := mload(0x40)
                // allocate memory proportionate to calldata
                mstore(0x40, add(ptr, calldatasize()))
                // copy calldata into memory
                calldatacopy(ptr, 0x00, calldatasize())
                let ret := delegatecall(gas(), logicAddress, ptr, calldatasize(), 0x00, 0x00)
                returndatacopy(ptr, 0x00, returndatasize())
                if iszero(ret) {
                    revert(ptr, returndatasize())
                }
                return(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";

/// @custom:salt PublicStaking
/// @custom:deploy-type deployUpgradeable
contract PublicStaking is StakingNFT {
    constructor() StakingNFT() {}

    function initialize() public onlyFactory initializer {
        __stakingNFTInit("APSNFT", "APS");
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicEthTransfer.sol";

contract Redistribution is
    ImmutableALCA,
    ImmutablePublicStaking,
    ImmutableFoundation,
    ERC20SafeTransfer,
    MagicEthTransfer
{
    struct accountInfo {
        uint248 balance;
        bool isPositionTaken;
    }

    event Withdrawn(address indexed user, uint256 amount);
    event TokenAlreadyTransferred();

    error NotOperator();
    error WithdrawalWindowExpired();
    error WithdrawalWindowNotExpiredYet();
    error IncorrectLength();
    error ZeroAmountNotAllowed();
    error InvalidAllowanceSum(uint256 totalAllowance, uint256 maxRedistributionAmount);
    error DistributionTokenAlreadyCreated();
    error PositionAlreadyRegisteredOrTaken();
    error InvalidDistributionAmount(uint256 amount, uint256 maxAllowed);
    error NotEnoughFundsToRedistribute(uint256 withdrawAmount, uint256 currentAmount);
    error PositionAlreadyTaken();

    /// The amount of blocks that the withdraw position will be locked against burning. This is
    /// approximately 6 months.
    uint256 public constant MAX_MINT_LOCK = 1051200;
    /// The total amount of ALCA that can be redistributed to accounts via this contract.
    uint256 public immutable maxRedistributionAmount;
    /// The block number that the withdrawal window will expire.
    uint256 public immutable expireBlock;
    /// The address of the operator of the contract. The operator will be able to register new
    /// accounts that will have rights to withdraw funds.
    address public operator;
    /// The amount from the `maxRedistributionAmount` already reserved for distribution.
    uint256 public totalAllowances;
    /// The current tokenID of the public staking position that holds the ALCA to be distributed.
    uint256 public tokenID;
    mapping(address => accountInfo) internal _accounts;

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        _;
    }

    modifier notExpired() {
        if (block.number > expireBlock) {
            revert WithdrawalWindowExpired();
        }
        _;
    }

    /**
     * @notice This function is used to receive ETH from the public staking contract.
     */
    receive() external payable onlyPublicStaking {}

    constructor(
        uint256 withdrawalBlockWindow,
        uint256 maxRedistributionAmount_,
        address[] memory allowedAddresses,
        uint248[] memory allowedAmounts
    ) ImmutableFactory(msg.sender) ImmutableALCA() ImmutablePublicStaking() ImmutableFoundation() {
        if (allowedAddresses.length != allowedAmounts.length || allowedAddresses.length == 0) {
            revert IncorrectLength();
        }
        uint256 totalAllowance = 0;
        for (uint256 i = 0; i < allowedAddresses.length; i++) {
            if (allowedAddresses[i] == address(0) || _accounts[allowedAddresses[i]].balance > 0) {
                revert PositionAlreadyRegisteredOrTaken();
            }
            if (allowedAmounts[i] == 0) {
                revert ZeroAmountNotAllowed();
            }
            _accounts[allowedAddresses[i]] = accountInfo(allowedAmounts[i], false);
            totalAllowance += allowedAmounts[i];
        }
        if (totalAllowance > maxRedistributionAmount_) {
            revert InvalidAllowanceSum(totalAllowance, maxRedistributionAmount_);
        }
        maxRedistributionAmount = maxRedistributionAmount_;
        totalAllowances = totalAllowance;
        expireBlock = block.number + withdrawalBlockWindow;
    }

    /**
     * @notice Set a new operator for the contract. This function can only be called by the factory.
     * @param operator_ The new operator address.
     */
    function setOperator(address operator_) public onlyFactory {
        operator = operator_;
    }

    /**
     * @notice Creates the total staked position for the redistribution. This function can only be
     * called by the factory. This function can only be called if the withdrawal window has not expired
     * yet.
     * @dev the maxRedistributionAmount should be approved to this contract before calling this
     * function.
     */
    function createRedistributionStakedPosition() public onlyFactory notExpired {
        if (tokenID != 0) {
            revert DistributionTokenAlreadyCreated();
        }
        _safeTransferFromERC20(
            IERC20Transferable(_alcaAddress()),
            msg.sender,
            maxRedistributionAmount
        );
        // approve the staking contract to transfer the ALCA
        IERC20(_alcaAddress()).approve(_publicStakingAddress(), maxRedistributionAmount);
        tokenID = IStakingNFT(_publicStakingAddress()).mint(maxRedistributionAmount);
    }

    /**
     * @notice register an new address for a distribution amount. This function can only be called
     * by the operator. The distribution amount can not be greater that the total amount left for
     * distribution. Only one amount can be registered per address. Amount for already registered
     * addresses cannot be changed.
     * @dev This function can only be called if the withdrawal window has not expired yet.
     * @param user The address to register for distribution.
     * @param distributionAmount The amount to register for distribution.
     */
    function registerAddressForDistribution(
        address user,
        uint248 distributionAmount
    ) public onlyOperator notExpired {
        if (distributionAmount == 0) {
            revert ZeroAmountNotAllowed();
        }
        accountInfo memory account = _accounts[user];
        if (account.balance > 0 || account.isPositionTaken) {
            revert PositionAlreadyRegisteredOrTaken();
        }
        uint256 distributionLeft = _getDistributionLeft();
        if (distributionAmount > distributionLeft) {
            revert InvalidDistributionAmount(distributionAmount, distributionLeft);
        }
        _accounts[user] = accountInfo(distributionAmount, false);
        totalAllowances += distributionAmount;
    }

    /**
     *  @notice Withdraw the staked position to the user's address. It will burn the Public
     *  Staking position held by this contract and mint a new one to the user's address with the
     *  owned amount and in case there is a remainder, it will mint a new position to this contract.
     *  THE CALLER OF THIS FUNCTION MUST BE AN EOA (EXTERNAL OWNED ACCOUNT) OR PROXY WALLET THAT
     *  ACCEPTS AND HANDLE ERC721 POSITIONS. BEWARE IF THIS REQUIREMENTS ARE NOT FOLLOWED, THE
     *  POSITION CAN BE FOREVER LOST.
     *  @dev This function can only be called by the user that has the right to withdraw a staked
     *  position. This function can only be called if the withdrawal window has not expired yet.
     *  @param to The address to send the staked position to.
     */
    function withdrawStakedPosition(address to) public notExpired {
        accountInfo memory account = _accounts[msg.sender];
        if (account.balance == 0 || account.isPositionTaken) {
            revert PositionAlreadyTaken();
        }
        _accounts[msg.sender] = accountInfo(0, true);
        IStakingNFT staking = IStakingNFT(_publicStakingAddress());
        IERC20 alca = IERC20(_alcaAddress());
        staking.burn(tokenID);
        uint256 alcaBalance = alca.balanceOf(address(this));
        if (alcaBalance < account.balance) {
            revert NotEnoughFundsToRedistribute(alcaBalance, account.balance);
        }
        alca.approve(_publicStakingAddress(), alcaBalance);
        staking.mintTo(to, account.balance, MAX_MINT_LOCK);
        uint256 remainder = alcaBalance - account.balance;
        if (remainder > 0) {
            tokenID = staking.mint(remainder);
        }
        // send any eth balance collected to the foundation
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _safeTransferEthWithMagic(IMagicEthTransfer(_foundationAddress()), ethBalance);
        }
        emit Withdrawn(msg.sender, account.balance);
    }

    /**
     *  @notice Send any remaining funds that were not claimed during the valid time back to the
     *  factory. It will transfer the Public Staking position (in case it exists) and any ALCA back
     *  to the Factory. Ether will be send to the foundation.
     *  @dev This function can only be called by the AliceNet factory. This function never fails and
     *  can act as a skim of ether and ALCA.
     *  function never fails.
     */
    function sendExpiredFundsToFactory() public onlyFactory {
        if (block.number <= expireBlock) {
            revert WithdrawalWindowNotExpiredYet();
        }
        try
            IERC721(_publicStakingAddress()).transferFrom(address(this), _factoryAddress(), tokenID)
        {} catch {
            emit TokenAlreadyTransferred();
        }
        uint256 alcaBalance = IERC20(_alcaAddress()).balanceOf(address(this));
        if (alcaBalance > 0) {
            _safeTransferERC20(IERC20Transferable(_alcaAddress()), _factoryAddress(), alcaBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _safeTransferEthWithMagic(IMagicEthTransfer(_foundationAddress()), ethBalance);
        }
    }

    /**
     * @notice Returns the account info for a given user
     * @param user The address of the user
     */
    function getRedistributionInfo(address user) public view returns (accountInfo memory account) {
        account = _accounts[user];
    }

    /**
     * @notice Returns the amount of ALCA left to distribute
     */
    function getDistributionLeft() public view returns (uint256) {
        return _getDistributionLeft();
    }

    // internal function to get the amount of ALCA left to distribute
    function _getDistributionLeft() internal view returns (uint256) {
        return maxRedistributionAmount - totalAllowances;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/BonusPool.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";

/**
 * @notice RewardPool holds all ether and ALCA that is part of reserved amount
 * of rewards on base positions.
 * @dev deployed by the lockup contract
 */
contract RewardPool is AccessControlled, EthSafeTransfer, ERC20SafeTransfer {
    address internal immutable _alca;
    address internal immutable _lockupContract;
    address internal immutable _bonusPool;
    uint256 internal _ethReserve;
    uint256 internal _tokenReserve;

    constructor(address alca_, address aliceNetFactory_, uint256 totalBonusAmount_) {
        _bonusPool = address(
            new BonusPool(aliceNetFactory_, msg.sender, address(this), totalBonusAmount_)
        );
        _lockupContract = msg.sender;
        _alca = alca_;
    }

    /// @notice function that receives ether and updates the token and ether reservers. The ALCA
    /// tokens has to be sent prior the call to this function.
    /// @dev can only be called by the bonusPool or lockup contracts
    /// @param numTokens_ number of ALCA tokens transferred to this contract before the call to this
    /// function
    function deposit(uint256 numTokens_) public payable onlyLockupOrBonus {
        _tokenReserve += numTokens_;
        _ethReserve += msg.value;
    }

    /// @notice function to pay a user after the lockup period. If a user is the last exiting the
    /// lockup it will receive any remainders kept by this contract by integer division errors.
    /// @dev only can be called by the lockup contract
    /// @param totalShares_ the total shares at the end of the lockup period
    /// @param userShares_ the user shares
    /// @param isLastPosition_ if the user is the last position exiting from the lockup contract
    function payout(
        uint256 totalShares_,
        uint256 userShares_,
        bool isLastPosition_
    ) public onlyLockup returns (uint256 proportionalEth, uint256 proportionalTokens) {
        if (totalShares_ == 0 || userShares_ > totalShares_) {
            revert LockupErrors.InvalidTotalSharesValue();
        }

        // last position gets any remainder left on this contract
        if (isLastPosition_) {
            proportionalEth = address(this).balance;
            proportionalTokens = IERC20(_alca).balanceOf(address(this));
        } else {
            (proportionalEth, proportionalTokens) = _computeProportions(totalShares_, userShares_);
        }
        _safeTransferERC20(IERC20Transferable(_alca), _lockupContract, proportionalTokens);
        _safeTransferEth(payable(_lockupContract), proportionalEth);
    }

    /// @notice gets the bonusPool contract address
    /// @return the bonusPool contract address
    function getBonusPoolAddress() public view returns (address) {
        return _getBonusPoolAddress();
    }

    /// @notice gets the lockup contract address
    /// @return the lockup contract address
    function getLockupContractAddress() public view returns (address) {
        return _getLockupContractAddress();
    }

    /// @notice get the ALCA reserve kept by this contract
    /// @return the ALCA reserve kept by this contract
    function getTokenReserve() public view returns (uint256) {
        return _tokenReserve;
    }

    /// @notice get the ether reserve kept by this contract
    /// @return the ether reserve kept by this contract
    function getEthReserve() public view returns (uint256) {
        return _ethReserve;
    }

    /// @notice estimates the final amount that a user will receive from the assets hold by this
    /// contract after end of the lockup period.
    /// @param totalShares_ total number of shares locked by the lockup contract
    /// @param userShares_ the user's shares
    /// @return proportionalEth The ether that a user will receive at the end of the lockup period
    /// @return proportionalTokens The ALCA that a user will receive at the end of the lockup period
    function estimateRewards(
        uint256 totalShares_,
        uint256 userShares_
    ) public view returns (uint256 proportionalEth, uint256 proportionalTokens) {
        if (totalShares_ == 0 || userShares_ > totalShares_) {
            revert LockupErrors.InvalidTotalSharesValue();
        }
        return _computeProportions(totalShares_, userShares_);
    }

    function _computeProportions(
        uint256 totalShares_,
        uint256 userShares_
    ) internal view returns (uint256 proportionalEth, uint256 proportionalTokens) {
        proportionalEth = (_ethReserve * userShares_) / totalShares_;
        proportionalTokens = (_tokenReserve * userShares_) / totalShares_;
    }

    function _getLockupContractAddress() internal view override returns (address) {
        return _lockupContract;
    }

    function _getBonusPoolAddress() internal view override returns (address) {
        return _bonusPool;
    }

    function _getRewardPoolAddress() internal view override returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IDynamics.sol";
import "contracts/libraries/parsers/RCertParserLibrary.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/libraries/snapshots/SnapshotsStorage.sol";
import "contracts/utils/DeterministicAddress.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/libraries/errors/SnapshotsErrors.sol";

/// @custom:salt Snapshots
/// @custom:deploy-type deployUpgradeable
contract Snapshots is Initializable, SnapshotsStorage, ISnapshots {
    using EpochLib for Epoch;

    constructor(uint256 chainID_, uint256 epochLength_) SnapshotsStorage(chainID_, epochLength_) {}

    function initialize(
        uint32 desperationDelay_,
        uint32 desperationFactor_
    ) public onlyFactory initializer {
        // considering that in optimum conditions 1 Sidechain block is at every 3 seconds and 1 block at
        // ethereum is approx at 13 seconds
        _minimumIntervalBetweenSnapshots = uint32(_epochLength / 4);
        _snapshotDesperationDelay = desperationDelay_;
        _snapshotDesperationFactor = desperationFactor_;
    }

    /// @notice Set snapshot desperation delay
    /// @param desperationDelay_ The desperation delay
    // todo: compute this value using the dynamic system and the alicenet block times.
    function setSnapshotDesperationDelay(uint32 desperationDelay_) public onlyFactory {
        _snapshotDesperationDelay = desperationDelay_;
    }

    /// @notice Set snapshot desperation factor
    /// @param desperationFactor_ The desperation factor
    function setSnapshotDesperationFactor(uint32 desperationFactor_) public onlyFactory {
        _snapshotDesperationFactor = desperationFactor_;
    }

    /// @notice Set minimum interval between snapshots in Ethereum blocks
    /// @param minimumIntervalBetweenSnapshots_ The interval in blocks
    function setMinimumIntervalBetweenSnapshots(
        uint32 minimumIntervalBetweenSnapshots_
    ) public onlyFactory {
        _minimumIntervalBetweenSnapshots = minimumIntervalBetweenSnapshots_;
    }

    /// @notice Saves next snapshot
    /// @param groupSignature_ The group signature used to sign the snapshots' block claims
    /// @param bClaims_ The claims being made about given block
    /// @return returns true if the execution succeeded
    function snapshot(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public returns (bool) {
        if (!IValidatorPool(_validatorPoolAddress()).isValidator(msg.sender)) {
            revert SnapshotsErrors.OnlyValidatorsAllowed(msg.sender);
        }
        if (!IValidatorPool(_validatorPoolAddress()).isConsensusRunning()) {
            revert SnapshotsErrors.ConsensusNotRunning();
        }

        uint32 epoch = _epochRegister().get() + 1;
        BClaimsParserLibrary.BClaims memory blockClaims = _parseAndValidateBClaims(epoch, bClaims_);

        uint256 lastSnapshotCommittedAt = _getLatestSnapshot().committedAt;
        _checkSnapshotMinimumInterval(lastSnapshotCommittedAt);

        _isValidatorElectedToPerformSnapshot(
            msg.sender,
            lastSnapshotCommittedAt,
            keccak256(groupSignature_)
        );

        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = _checkBClaimsSignature(
            groupSignature_,
            bClaims_
        );

        bool isSafeToProceedConsensus = true;
        if (IValidatorPool(_validatorPoolAddress()).isMaintenanceScheduled()) {
            isSafeToProceedConsensus = false;
            IValidatorPool(_validatorPoolAddress()).pauseConsensus();
        }

        _setSnapshot(Snapshot(block.number, blockClaims));
        _epochRegister().set(epoch);

        emit SnapshotTaken(
            _chainId,
            epoch,
            blockClaims.height,
            msg.sender,
            isSafeToProceedConsensus,
            masterPublicKey,
            signature,
            blockClaims
        );

        // check and update the latest dynamics values in case the scheduled changes
        // start to become valid on this epoch
        IDynamics(_dynamicsAddress()).updateHead(epoch);

        return isSafeToProceedConsensus;
    }

    /// @notice Migrates a set of snapshots to bootstrap the side chain.
    /// @param groupSignature_ Array of group signature used to sign the snapshots' block claims
    /// @param bClaims_ Array of BClaims being migrated as snapshots
    /// @return returns true if the execution succeeded
    function migrateSnapshots(
        bytes[] memory groupSignature_,
        bytes[] memory bClaims_
    ) public onlyFactory returns (bool) {
        Epoch storage epochReg = _epochRegister();
        {
            if (epochReg.get() != 0) {
                revert SnapshotsErrors.MigrationNotAllowedAtCurrentEpoch();
            }
            if (groupSignature_.length != bClaims_.length || groupSignature_.length == 0) {
                revert SnapshotsErrors.MigrationInputDataMismatch(
                    groupSignature_.length,
                    bClaims_.length
                );
            }
        }
        uint256 epoch;
        for (uint256 i = 0; i < bClaims_.length; i++) {
            BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.extractBClaims(
                bClaims_[i]
            );
            if (blockClaims.height % _epochLength != 0) {
                revert SnapshotsErrors.BlockHeightNotMultipleOfEpochLength(
                    blockClaims.height,
                    _epochLength
                );
            }
            (
                uint256[4] memory masterPublicKey,
                uint256[2] memory signature
            ) = _checkBClaimsSignature(groupSignature_[i], bClaims_[i]);
            epoch = getEpochFromHeight(blockClaims.height);
            _setSnapshot(Snapshot(block.number, blockClaims));
            emit SnapshotTaken(
                _chainId,
                epoch,
                blockClaims.height,
                msg.sender,
                true,
                masterPublicKey,
                signature,
                blockClaims
            );
        }
        epochReg.set(uint32(epoch));
        return true;
    }

    /// @notice Gets snapshot desperation factor
    /// @return The snapshot desperation factor
    function getSnapshotDesperationFactor() public view returns (uint256) {
        return _snapshotDesperationFactor;
    }

    /// @notice Gets snapshot desperation delay
    /// @return The snapshot desperation delay
    function getSnapshotDesperationDelay() public view returns (uint256) {
        return _snapshotDesperationDelay;
    }

    /// @notice Gets minimal interval in Ethereum blocks between snapshots
    /// @return The minimal interval between snapshots
    function getMinimumIntervalBetweenSnapshots() public view returns (uint256) {
        return _minimumIntervalBetweenSnapshots;
    }

    /// @notice Gets the chain Id
    /// @return The chain Id
    function getChainId() public view returns (uint256) {
        return _chainId;
    }

    /// @notice Gets the epoch of epoch register
    /// @return The epoch
    function getEpoch() public view returns (uint256) {
        return _epochRegister().get();
    }

    /// @notice Gets the epoch length
    /// @return The epoch length
    function getEpochLength() public view returns (uint256) {
        return _epochLength;
    }

    /// @notice Gets the chain Id of snapshot at specified epoch
    /// @param epoch_ The epoch of the snapshot
    /// @return The chain Id
    /// This function will fail in case the user tries to get information of a snapshot older than 6 epochs from the current one
    function getChainIdFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _getSnapshot(uint32(epoch_)).blockClaims.chainId;
    }

    /// @notice Gets the chain Id of latest snapshot
    /// @return The chain Id
    function getChainIdFromLatestSnapshot() public view returns (uint256) {
        return _getLatestSnapshot().blockClaims.chainId;
    }

    /// @notice Gets block claims of snapshot at specified epoch
    /// @param epoch_ The epoch of the snapshot
    /// @return The block claims
    /// This function will fail in case the user tries to get information of a snapshot older than 6 epochs from the current one
    function getBlockClaimsFromSnapshot(
        uint256 epoch_
    ) public view returns (BClaimsParserLibrary.BClaims memory) {
        return _getSnapshot(uint32(epoch_)).blockClaims;
    }

    /// @notice Gets block claims of latest snapshot
    /// @return The block claims
    function getBlockClaimsFromLatestSnapshot()
        public
        view
        returns (BClaimsParserLibrary.BClaims memory)
    {
        return _getLatestSnapshot().blockClaims;
    }

    /// @notice Gets committed height of snapshot at specified epoch
    /// @param epoch_ The epoch of the snapshot
    /// @return The committed height
    /// This function will fail in case the user tries to get information of a snapshot older than 6 epochs from the current one
    function getCommittedHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _getSnapshot(uint32(epoch_)).committedAt;
    }

    /// @notice Gets committed height of latest snapshot
    /// @return The committed height of latest snapshot
    function getCommittedHeightFromLatestSnapshot() public view returns (uint256) {
        return _getLatestSnapshot().committedAt;
    }

    /// @notice Gets alicenet height of snapshot at specified epoch
    /// @param epoch_ The epoch of the snapshot
    /// @return The AliceNet height
    /// This function will fail in case the user tries to get information of a snapshot older than 6 epochs from the current one
    function getAliceNetHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _getSnapshot(uint32(epoch_)).blockClaims.height;
    }

    /// @notice Gets alicenet height of latest snapshot
    /// @return Alicenet height of latest snapshot
    function getAliceNetHeightFromLatestSnapshot() public view returns (uint256) {
        return _getLatestSnapshot().blockClaims.height;
    }

    /// @notice Gets snapshot for specified epoch
    /// @param epoch_ The epoch of the snapshot
    /// @return The snapshot at specified epoch
    /// This function will fail in case the user tries to get information of a snapshot older than 6 epochs from the current one
    function getSnapshot(uint256 epoch_) public view returns (Snapshot memory) {
        return _getSnapshot(uint32(epoch_));
    }

    /// @notice Gets latest snapshot
    /// @return The latest snapshot
    function getLatestSnapshot() public view returns (Snapshot memory) {
        return _getLatestSnapshot();
    }

    /// @notice Gets epoch for specified height
    /// @param height The height specified
    /// @return The epoch at specified height
    function getEpochFromHeight(uint256 height) public view returns (uint256) {
        return _getEpochFromHeight(uint32(height));
    }

    function checkBClaimsSignature(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public view returns (bool) {
        // if the function does not revert, it means that the signature is valid
        _checkBClaimsSignature(groupSignature_, bClaims_);
        return true;
    }

    function isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) public view returns (bool) {
        // if the function does not revert, it means that the validator is the selected to perform the snapshot
        _isValidatorElectedToPerformSnapshot(
            validator,
            lastSnapshotCommittedAt,
            groupSignatureHash
        );
        return true;
    }

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 randomSeed,
        uint256 desperationFactor
    ) public pure returns (bool) {
        (bool isValidatorElected, , ) = _mayValidatorSnapshot(
            numValidators,
            myIdx,
            blocksSinceDesperation,
            randomSeed,
            desperationFactor
        );
        return isValidatorElected;
    }

    /// @notice Checks if validator is the one elected to perform snapshot
    /// @param validator The validator to be checked
    /// @param lastSnapshotCommittedAt Block number of last snapshot committed
    /// @param groupSignatureHash The block groups signature hash
    function _isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) internal view {
        // Check if sender is the elected validator allowed to make the snapshot
        uint256 validatorIndex = IETHDKG(_ethdkgAddress()).getLastRoundParticipantIndex(validator);
        uint256 ethBlocksSinceLastSnapshot = block.number - lastSnapshotCommittedAt;
        uint256 desperationDelay = _snapshotDesperationDelay;
        uint256 blocksSinceDesperation = ethBlocksSinceLastSnapshot >= desperationDelay
            ? ethBlocksSinceLastSnapshot - desperationDelay
            : 0;
        (bool isValidatorElected, uint256 startIndex, uint256 endIndex) = _mayValidatorSnapshot(
            IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
            validatorIndex - 1,
            blocksSinceDesperation,
            groupSignatureHash,
            uint256(_snapshotDesperationFactor)
        );
        if (!isValidatorElected) {
            revert SnapshotsErrors.ValidatorNotElected(
                validatorIndex - 1,
                startIndex,
                endIndex,
                groupSignatureHash
            );
        }
    }

    /// @notice Validates Block Claims for an epoch
    /// @param epoch The epoch to be validated
    /// @param bClaims_ Encoded block claims
    /// @return blockClaims as struct if valid
    function _parseAndValidateBClaims(
        uint32 epoch,
        bytes calldata bClaims_
    ) internal view returns (BClaimsParserLibrary.BClaims memory blockClaims) {
        blockClaims = BClaimsParserLibrary.extractBClaims(bClaims_);

        if (epoch * _epochLength != blockClaims.height) {
            revert SnapshotsErrors.UnexpectedBlockHeight(blockClaims.height, epoch * _epochLength);
        }

        if (blockClaims.chainId != _chainId) {
            revert SnapshotsErrors.InvalidChainId(blockClaims.chainId);
        }
    }

    /// @notice Checks block claims signature
    /// @param groupSignature_ The group signature
    /// @param bClaims_ The block claims to be checked
    /// @return signature validity
    function _checkBClaimsSignature(
        bytes memory groupSignature_,
        bytes memory bClaims_
    ) internal view returns (uint256[4] memory, uint256[2] memory) {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        bytes32 calculatedMasterPublicKeyHash = keccak256(abi.encodePacked(masterPublicKey));
        bytes32 expectedMasterPublicKeyHash = IETHDKG(_ethdkgAddress()).getMasterPublicKeyHash();

        if (calculatedMasterPublicKeyHash != expectedMasterPublicKeyHash) {
            revert SnapshotsErrors.InvalidMasterPublicKey(
                calculatedMasterPublicKeyHash,
                expectedMasterPublicKeyHash
            );
        }

        if (
            !CryptoLibrary.verifySignatureASM(
                abi.encodePacked(keccak256(bClaims_)),
                signature,
                masterPublicKey
            )
        ) {
            revert SnapshotsErrors.SignatureVerificationFailed();
        }
        return (masterPublicKey, signature);
    }

    /// @notice Checks if snapshot minimum interval has passed
    /// @param lastSnapshotCommittedAt Block number of the last snapshot committed
    function _checkSnapshotMinimumInterval(uint256 lastSnapshotCommittedAt) internal view {
        uint256 minimumIntervalBetweenSnapshots = _minimumIntervalBetweenSnapshots;
        if (block.number < lastSnapshotCommittedAt + minimumIntervalBetweenSnapshots) {
            revert SnapshotsErrors.MinimumBlocksIntervalNotPassed(
                block.number,
                lastSnapshotCommittedAt + minimumIntervalBetweenSnapshots
            );
        }
    }

    /// @notice Checks if validator is allowed to take snapshots
    /// @param  numValidators number of current validators
    /// @param  myIdx index
    /// @param  blocksSinceDesperation Number of blocks since desperation
    /// @param  randomSeed Random seed
    /// @param  desperationFactor Desperation Factor
    /// @return true if allowed to do snapshots and start and end snapshot range
    function _mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 randomSeed,
        uint256 desperationFactor
    ) internal pure returns (bool, uint256, uint256) {
        uint256 numValidatorsAllowed = 1;

        uint256 desperation = 0;
        while (desperation < blocksSinceDesperation && numValidatorsAllowed < numValidators) {
            desperation += desperationFactor / numValidatorsAllowed;
            numValidatorsAllowed++;
        }

        uint256 rand = uint256(randomSeed);
        uint256 start = (rand % numValidators);
        uint256 end = (start + numValidatorsAllowed) % numValidators;
        bool isAllowedToDoSnapshots;
        if (end > start) {
            isAllowedToDoSnapshots = myIdx >= start && myIdx < end;
        } else {
            isAllowedToDoSnapshots = myIdx >= start || myIdx < end;
        }
        return (isAllowedToDoSnapshots, start, end);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import "contracts/libraries/metadata/StakingDescriptor.sol";
import "contracts/interfaces/IStakingNFTDescriptor.sol";

/// @custom:salt StakingPositionDescriptor
/// @custom:deploy-type deployUpgradeable
contract StakingPositionDescriptor is IStakingNFTDescriptor {
    function tokenURI(
        IStakingNFT _stakingNFT,
        uint256 tokenId
    ) external view override returns (string memory) {
        (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        ) = _stakingNFT.getPosition(tokenId);

        return
            StakingDescriptor.constructTokenURI(
                StakingDescriptor.ConstructTokenURIParams({
                    tokenId: tokenId,
                    shares: shares,
                    freeAfter: freeAfter,
                    withdrawFreeAfter: withdrawFreeAfter,
                    accumulatorEth: accumulatorEth,
                    accumulatorToken: accumulatorToken
                })
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/interfaces/IERC721Transferable.sol";
import "contracts/interfaces/IAliceNetFactory.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/Lockup.sol";

/// @custom:salt StakingRouterV1
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group lockup
/// @custom:deploy-group-index 1
contract StakingRouterV1 is
    ImmutablePublicStaking,
    ImmutableALCA,
    ERC20SafeTransfer,
    EthSafeTransfer
{
    error InvalidStakingAmount(uint256 stakingAmount, uint256 migratedAmount);

    bytes32 internal constant _LOCKUP_SALT =
        0x4c6f636b75700000000000000000000000000000000000000000000000000000;
    address internal immutable _legacyToken;
    address internal immutable _lockupContract;

    constructor() ImmutableFactory(msg.sender) ImmutablePublicStaking() ImmutableALCA() {
        _legacyToken = IStakingToken(_alcaAddress()).getLegacyTokenAddress();
        _lockupContract = IAliceNetFactory(_factoryAddress()).lookup(_LOCKUP_SALT);
    }

    /// @notice Migrates an amount of legacy token (MADToken) to ALCA tokens and stake them in the
    /// PublicStaking contract. User calling this function must have approved this contract to
    /// transfer the `migrationAmount_` MADTokens beforehand.
    /// @param to_ the address that will own the position
    /// @param migrationAmount_ the amount of legacy token to migrate
    /// @param stakingAmount_ the amount of ALCA that will staked and locked
    function migrateAndStake(address to_, uint256 migrationAmount_, uint256 stakingAmount_) public {
        uint256 migratedAmount = _migrate(msg.sender, migrationAmount_);
        _verifyAndSendAnyRemainder(to_, migratedAmount, stakingAmount_);
        _stake(to_, stakingAmount_);
    }

    /// @notice Migrates an amount of legacy token (MADToken) to ALCA tokens, stake them in the
    /// PublicStaking contract and in sequence lock the position. User calling this function must have
    /// approved this contract to transfer the `migrationAmount_` MADTokens beforehand.
    /// @param to_ the address that will own the locked position
    /// @param migrationAmount_ the amount of legacy token to migrate
    /// @param stakingAmount_ the amount of ALCA that will staked and locked
    function migrateStakeAndLock(
        address to_,
        uint256 migrationAmount_,
        uint256 stakingAmount_
    ) public {
        uint256 migratedAmount = _migrate(msg.sender, migrationAmount_);
        _verifyAndSendAnyRemainder(to_, migratedAmount, stakingAmount_);
        // mint the position directly to the lockup contract
        uint256 tokenID = _stake(_lockupContract, stakingAmount_);
        // right in sequence claim the minted position
        Lockup(payable(_lockupContract)).lockFromTransfer(tokenID, to_);
    }

    /// @notice Stake an amount of ALCA in the PublicStaking contract and lock the position in
    /// sequence. User calling this function must have approved this contract to
    /// transfer the `stakingAmount_` ALCA beforehand.
    /// @param to_ the address that will own the locked position
    /// @param stakingAmount_ the amount of ALCA that will staked
    function stakeAndLock(address to_, uint256 stakingAmount_) public {
        _safeTransferFromERC20(IERC20Transferable(_alcaAddress()), msg.sender, stakingAmount_);
        // mint the position directly to the lockup contract
        uint256 tokenID = _stake(_lockupContract, stakingAmount_);
        // right in sequence claim the minted position
        Lockup(payable(_lockupContract)).lockFromTransfer(tokenID, to_);
    }

    /// @notice Get the address of the legacy token.
    /// @return the address of the legacy token (MADToken).
    function getLegacyTokenAddress() public view returns (address) {
        return _legacyToken;
    }

    function _migrate(address from_, uint256 amount_) internal returns (uint256 migratedAmount_) {
        _safeTransferFromERC20(IERC20Transferable(_legacyToken), from_, amount_);
        IERC20(_legacyToken).approve(_alcaAddress(), amount_);
        migratedAmount_ = IStakingToken(_alcaAddress()).migrateTo(address(this), amount_);
    }

    function _stake(address to_, uint256 stakingAmount_) internal returns (uint256 tokenID_) {
        IERC20(_alcaAddress()).approve(_publicStakingAddress(), stakingAmount_);
        tokenID_ = IStakingNFT(_publicStakingAddress()).mintTo(to_, stakingAmount_, 0);
    }

    function _verifyAndSendAnyRemainder(
        address to_,
        uint256 migratedAmount_,
        uint256 stakingAmount_
    ) internal {
        if (stakingAmount_ > migratedAmount_) {
            revert InvalidStakingAmount(stakingAmount_, migratedAmount_);
        }
        uint256 remainder = migratedAmount_ - stakingAmount_;
        if (remainder > 0) {
            _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, remainder);
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/AccusationsErrors.sol";

library AccusationsLibrary {
    /// @notice Recovers the signer of a message
    /// @param signature The ECDSA signature
    /// @param prefix The prefix of the message
    /// @param message The message
    /// @return the address of the signer
    function recoverSigner(
        bytes memory signature,
        bytes memory prefix,
        bytes memory message
    ) internal pure returns (address) {
        if (signature.length != 65) {
            revert AccusationsErrors.SignatureLengthMustBe65Bytes(signature.length);
        }

        bytes32 hashedMessage = keccak256(abi.encodePacked(prefix, message));

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly ("memory-safe") {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        v = (v < 27) ? (v + 27) : v;

        if (v != 27 && v != 28) {
            revert AccusationsErrors.InvalidSignatureVersion(v);
        }

        return ecrecover(hashedMessage, v, r, s);
    }

    /// @notice Recovers the signer of a message in MadNet
    /// @param signature The ECDSA signature
    /// @param message The message
    /// @return the address of the signer
    function recoverMadNetSigner(
        bytes memory signature,
        bytes memory message
    ) internal pure returns (address) {
        return recoverSigner(signature, "Proposal", message);
    }

    /// @notice Computes the UTXOID
    /// @param txHash the transaction hash
    /// @param txIdx the transaction index
    /// @return the UTXOID
    function computeUTXOID(bytes32 txHash, uint32 txIdx) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(txHash, txIdx));
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/AdminErrors.sol";

abstract contract Admin {
    // _admin is a privileged role
    address internal _admin;

    /// @dev onlyAdmin enforces msg.sender is _admin
    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert AdminErrors.SenderNotAdmin(msg.sender);
        }
        _;
    }

    constructor(address admin_) {
        _admin = admin_;
    }

    /// @dev assigns a new admin may only be called by _admin
    function setAdmin(address admin_) public virtual onlyAdmin {
        _setAdmin(admin_);
    }

    /// @dev getAdmin returns the current _admin
    function getAdmin() public view returns (address) {
        return _admin;
    }

    // assigns a new admin may only be called by _admin
    function _setAdmin(address admin_) internal {
        _admin = admin_;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ArbitraryDeterministicAddress {
    function getArbitraryContractAddress(
        bytes32 _salt,
        address _factory,
        bytes32 byteCodeHash_
    ) public pure returns (address) {
        return
            address(
                uint160(
                    uint256(keccak256(abi.encodePacked(hex"ff", _factory, _salt, byteCodeHash_)))
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract AtomicCounter {
    // monotonically increasing counter
    uint256 internal _counter;

    // _newTokenID increments the counter and returns the new value
    function _increment() internal returns (uint256 count) {
        count = _counter;
        count += 1;
        _counter = count;
        return count;
    }

    function _getCount() internal view returns (uint256) {
        return _counter;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/interfaces/IAliceNetFactory.sol";

abstract contract ImmutableALCA is ImmutableFactory {
    address private immutable _alca;
    error OnlyALCA(address sender, address expected);

    modifier onlyALCA() {
        if (msg.sender != _alca) {
            revert OnlyALCA(msg.sender, _alca);
        }
        _;
    }

    constructor() {
        _alca = IAliceNetFactory(_factoryAddress()).lookup(_saltForALCA());
    }

    function _alcaAddress() internal view returns (address) {
        return _alca;
    }

    function _saltForALCA() internal pure returns (bytes32) {
        return 0x414c434100000000000000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableALCABurner is ImmutableFactory {
    address private immutable _alcaBurner;
    error OnlyALCABurner(address sender, address expected);

    modifier onlyALCABurner() {
        if (msg.sender != _alcaBurner) {
            revert OnlyALCABurner(msg.sender, _alcaBurner);
        }
        _;
    }

    constructor() {
        _alcaBurner = getMetamorphicContractAddress(
            0x414c43414275726e657200000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _alcaBurnerAddress() internal view returns (address) {
        return _alcaBurner;
    }

    function _saltForALCABurner() internal pure returns (bytes32) {
        return 0x414c43414275726e657200000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableALCAMinter is ImmutableFactory {
    address private immutable _alcaMinter;
    error OnlyALCAMinter(address sender, address expected);

    modifier onlyALCAMinter() {
        if (msg.sender != _alcaMinter) {
            revert OnlyALCAMinter(msg.sender, _alcaMinter);
        }
        _;
    }

    constructor() {
        _alcaMinter = getMetamorphicContractAddress(
            0x414c43414d696e74657200000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _alcaMinterAddress() internal view returns (address) {
        return _alcaMinter;
    }

    function _saltForALCAMinter() internal pure returns (bytes32) {
        return 0x414c43414d696e74657200000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/interfaces/IAliceNetFactory.sol";

abstract contract ImmutableALCB is ImmutableFactory {
    address private immutable _alcb;
    error OnlyALCB(address sender, address expected);

    modifier onlyALCB() {
        if (msg.sender != _alcb) {
            revert OnlyALCB(msg.sender, _alcb);
        }
        _;
    }

    constructor() {
        _alcb = IAliceNetFactory(_factoryAddress()).lookup(_saltForALCB());
    }

    function _alcbAddress() internal view returns (address) {
        return _alcb;
    }

    function _saltForALCB() internal pure returns (bytes32) {
        return 0x414c434200000000000000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableBridgePoolFactory is ImmutableFactory {
    address private immutable _bridgePoolFactory;
    error OnlyBridgePoolFactory(address sender, address expected);

    modifier onlyBridgePoolFactory() {
        if (msg.sender != _bridgePoolFactory) {
            revert OnlyBridgePoolFactory(msg.sender, _bridgePoolFactory);
        }
        _;
    }

    constructor() {
        _bridgePoolFactory = getMetamorphicContractAddress(
            0x427269646765506f6f6c466163746f7279000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _bridgePoolFactoryAddress() internal view returns (address) {
        return _bridgePoolFactory;
    }

    function _saltForBridgePoolFactory() internal pure returns (bytes32) {
        return 0x427269646765506f6f6c466163746f7279000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableDistribution is ImmutableFactory {
    address private immutable _distribution;
    error OnlyDistribution(address sender, address expected);

    modifier onlyDistribution() {
        if (msg.sender != _distribution) {
            revert OnlyDistribution(msg.sender, _distribution);
        }
        _;
    }

    constructor() {
        _distribution = getMetamorphicContractAddress(
            0x446973747269627574696f6e0000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _distributionAddress() internal view returns (address) {
        return _distribution;
    }

    function _saltForDistribution() internal pure returns (bytes32) {
        return 0x446973747269627574696f6e0000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableDutchAuction is ImmutableFactory {
    address private immutable _dutchAuction;
    error OnlyDutchAuction(address sender, address expected);

    modifier onlyDutchAuction() {
        if (msg.sender != _dutchAuction) {
            revert OnlyDutchAuction(msg.sender, _dutchAuction);
        }
        _;
    }

    constructor() {
        _dutchAuction = getMetamorphicContractAddress(
            0x447574636841756374696f6e0000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _dutchAuctionAddress() internal view returns (address) {
        return _dutchAuction;
    }

    function _saltForDutchAuction() internal pure returns (bytes32) {
        return 0x447574636841756374696f6e0000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableDynamics is ImmutableFactory {
    address private immutable _dynamics;
    error OnlyDynamics(address sender, address expected);

    modifier onlyDynamics() {
        if (msg.sender != _dynamics) {
            revert OnlyDynamics(msg.sender, _dynamics);
        }
        _;
    }

    constructor() {
        _dynamics = getMetamorphicContractAddress(
            0x44796e616d696373000000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _dynamicsAddress() internal view returns (address) {
        return _dynamics;
    }

    function _saltForDynamics() internal pure returns (bytes32) {
        return 0x44796e616d696373000000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableETHDKG is ImmutableFactory {
    address private immutable _ethdkg;
    error OnlyETHDKG(address sender, address expected);

    modifier onlyETHDKG() {
        if (msg.sender != _ethdkg) {
            revert OnlyETHDKG(msg.sender, _ethdkg);
        }
        _;
    }

    constructor() {
        _ethdkg = getMetamorphicContractAddress(
            0x455448444b470000000000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgAddress() internal view returns (address) {
        return _ethdkg;
    }

    function _saltForETHDKG() internal pure returns (bytes32) {
        return 0x455448444b470000000000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableETHDKGAccusations is ImmutableFactory {
    address private immutable _ethdkgAccusations;
    error OnlyETHDKGAccusations(address sender, address expected);

    modifier onlyETHDKGAccusations() {
        if (msg.sender != _ethdkgAccusations) {
            revert OnlyETHDKGAccusations(msg.sender, _ethdkgAccusations);
        }
        _;
    }

    constructor() {
        _ethdkgAccusations = getMetamorphicContractAddress(
            0x455448444b4741636375736174696f6e73000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgAccusationsAddress() internal view returns (address) {
        return _ethdkgAccusations;
    }

    function _saltForETHDKGAccusations() internal pure returns (bytes32) {
        return 0x455448444b4741636375736174696f6e73000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableETHDKGPhases is ImmutableFactory {
    address private immutable _ethdkgPhases;
    error OnlyETHDKGPhases(address sender, address expected);

    modifier onlyETHDKGPhases() {
        if (msg.sender != _ethdkgPhases) {
            revert OnlyETHDKGPhases(msg.sender, _ethdkgPhases);
        }
        _;
    }

    constructor() {
        _ethdkgPhases = getMetamorphicContractAddress(
            0x455448444b475068617365730000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgPhasesAddress() internal view returns (address) {
        return _ethdkgPhases;
    }

    function _saltForETHDKGPhases() internal pure returns (bytes32) {
        return 0x455448444b475068617365730000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

abstract contract ImmutableFactory is DeterministicAddress {
    address private immutable _factory;
    error OnlyFactory(address sender, address expected);

    modifier onlyFactory() {
        if (msg.sender != _factory) {
            revert OnlyFactory(msg.sender, _factory);
        }
        _;
    }

    constructor(address factory_) {
        _factory = factory_;
    }

    function _factoryAddress() internal view returns (address) {
        return _factory;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableFoundation is ImmutableFactory {
    address private immutable _foundation;
    error OnlyFoundation(address sender, address expected);

    modifier onlyFoundation() {
        if (msg.sender != _foundation) {
            revert OnlyFoundation(msg.sender, _foundation);
        }
        _;
    }

    constructor() {
        _foundation = getMetamorphicContractAddress(
            0x466f756e646174696f6e00000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _foundationAddress() internal view returns (address) {
        return _foundation;
    }

    function _saltForFoundation() internal pure returns (bytes32) {
        return 0x466f756e646174696f6e00000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableGovernance is ImmutableFactory {
    address private immutable _governance;
    error OnlyGovernance(address sender, address expected);

    modifier onlyGovernance() {
        if (msg.sender != _governance) {
            revert OnlyGovernance(msg.sender, _governance);
        }
        _;
    }

    constructor() {
        _governance = getMetamorphicContractAddress(
            0x476f7665726e616e636500000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _governanceAddress() internal view returns (address) {
        return _governance;
    }

    function _saltForGovernance() internal pure returns (bytes32) {
        return 0x476f7665726e616e636500000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableInvalidTxConsumptionAccusation is ImmutableFactory {
    address private immutable _invalidTxConsumptionAccusation;
    error OnlyInvalidTxConsumptionAccusation(address sender, address expected);

    modifier onlyInvalidTxConsumptionAccusation() {
        if (msg.sender != _invalidTxConsumptionAccusation) {
            revert OnlyInvalidTxConsumptionAccusation(msg.sender, _invalidTxConsumptionAccusation);
        }
        _;
    }

    constructor() {
        _invalidTxConsumptionAccusation = getMetamorphicContractAddress(
            0x92a73f2b6573522d63c8fc84b5d8e5d615fbb685c1b3d7fad2155fe227daf848,
            _factoryAddress()
        );
    }

    function _invalidTxConsumptionAccusationAddress() internal view returns (address) {
        return _invalidTxConsumptionAccusation;
    }

    function _saltForInvalidTxConsumptionAccusation() internal pure returns (bytes32) {
        return 0x92a73f2b6573522d63c8fc84b5d8e5d615fbb685c1b3d7fad2155fe227daf848;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableLiquidityProviderStaking is ImmutableFactory {
    address private immutable _liquidityProviderStaking;
    error OnlyLiquidityProviderStaking(address sender, address expected);

    modifier onlyLiquidityProviderStaking() {
        if (msg.sender != _liquidityProviderStaking) {
            revert OnlyLiquidityProviderStaking(msg.sender, _liquidityProviderStaking);
        }
        _;
    }

    constructor() {
        _liquidityProviderStaking = getMetamorphicContractAddress(
            0x4c697175696469747950726f76696465725374616b696e670000000000000000,
            _factoryAddress()
        );
    }

    function _liquidityProviderStakingAddress() internal view returns (address) {
        return _liquidityProviderStaking;
    }

    function _saltForLiquidityProviderStaking() internal pure returns (bytes32) {
        return 0x4c697175696469747950726f76696465725374616b696e670000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableMultipleProposalAccusation is ImmutableFactory {
    address private immutable _multipleProposalAccusation;
    error OnlyMultipleProposalAccusation(address sender, address expected);

    modifier onlyMultipleProposalAccusation() {
        if (msg.sender != _multipleProposalAccusation) {
            revert OnlyMultipleProposalAccusation(msg.sender, _multipleProposalAccusation);
        }
        _;
    }

    constructor() {
        _multipleProposalAccusation = getMetamorphicContractAddress(
            0xcfdffd500b4a956e03976b2afd69712237ffa06e35093df1e05e533688959fdc,
            _factoryAddress()
        );
    }

    function _multipleProposalAccusationAddress() internal view returns (address) {
        return _multipleProposalAccusation;
    }

    function _saltForMultipleProposalAccusation() internal pure returns (bytes32) {
        return 0xcfdffd500b4a956e03976b2afd69712237ffa06e35093df1e05e533688959fdc;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutablePublicStaking is ImmutableFactory {
    address private immutable _publicStaking;
    error OnlyPublicStaking(address sender, address expected);

    modifier onlyPublicStaking() {
        if (msg.sender != _publicStaking) {
            revert OnlyPublicStaking(msg.sender, _publicStaking);
        }
        _;
    }

    constructor() {
        _publicStaking = getMetamorphicContractAddress(
            0x5075626c69635374616b696e6700000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _publicStakingAddress() internal view returns (address) {
        return _publicStaking;
    }

    function _saltForPublicStaking() internal pure returns (bytes32) {
        return 0x5075626c69635374616b696e6700000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableSnapshots is ImmutableFactory {
    address private immutable _snapshots;
    error OnlySnapshots(address sender, address expected);

    modifier onlySnapshots() {
        if (msg.sender != _snapshots) {
            revert OnlySnapshots(msg.sender, _snapshots);
        }
        _;
    }

    constructor() {
        _snapshots = getMetamorphicContractAddress(
            0x536e617073686f74730000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _snapshotsAddress() internal view returns (address) {
        return _snapshots;
    }

    function _saltForSnapshots() internal pure returns (bytes32) {
        return 0x536e617073686f74730000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableStakingPositionDescriptor is ImmutableFactory {
    address private immutable _stakingPositionDescriptor;
    error OnlyStakingPositionDescriptor(address sender, address expected);

    modifier onlyStakingPositionDescriptor() {
        if (msg.sender != _stakingPositionDescriptor) {
            revert OnlyStakingPositionDescriptor(msg.sender, _stakingPositionDescriptor);
        }
        _;
    }

    constructor() {
        _stakingPositionDescriptor = getMetamorphicContractAddress(
            0x5374616b696e67506f736974696f6e44657363726970746f7200000000000000,
            _factoryAddress()
        );
    }

    function _stakingPositionDescriptorAddress() internal view returns (address) {
        return _stakingPositionDescriptor;
    }

    function _saltForStakingPositionDescriptor() internal pure returns (bytes32) {
        return 0x5374616b696e67506f736974696f6e44657363726970746f7200000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableValidatorPool is ImmutableFactory {
    address private immutable _validatorPool;
    error OnlyValidatorPool(address sender, address expected);

    modifier onlyValidatorPool() {
        if (msg.sender != _validatorPool) {
            revert OnlyValidatorPool(msg.sender, _validatorPool);
        }
        _;
    }

    constructor() {
        _validatorPool = getMetamorphicContractAddress(
            0x56616c696461746f72506f6f6c00000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _validatorPoolAddress() internal view returns (address) {
        return _validatorPool;
    }

    function _saltForValidatorPool() internal pure returns (bytes32) {
        return 0x56616c696461746f72506f6f6c00000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableValidatorStaking is ImmutableFactory {
    address private immutable _validatorStaking;
    error OnlyValidatorStaking(address sender, address expected);

    modifier onlyValidatorStaking() {
        if (msg.sender != _validatorStaking) {
            revert OnlyValidatorStaking(msg.sender, _validatorStaking);
        }
        _;
    }

    constructor() {
        _validatorStaking = getMetamorphicContractAddress(
            0x56616c696461746f725374616b696e6700000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _validatorStakingAddress() internal view returns (address) {
        return _validatorStaking;
    }

    function _saltForValidatorStaking() internal pure returns (bytes32) {
        return 0x56616c696461746f725374616b696e6700000000000000000000000000000000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "contracts/libraries/errors/Base64Errors.sol";

/* solhint-disable */

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly ("memory-safe") {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);

        if (data.length % 4 != 0) {
            revert Base64Errors.InvalidDecoderInput(data.length % 4);
        }

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly ("memory-safe") {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
                    ),
                    add(
                        shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
/* solhint-enable */

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BridgePoolAddressUtil {
    /**
     * @notice calculates salt for a BridgePool contract based on ERC contract's address, tokenType, chainID and version_
     * @param tokenContractAddr_ address of ERC contract of BridgePool
     * @param tokenType_ type of token (0=ERC20, 1=ERC721, 2=ERC1155)
     * @param version_ version of the implementation
     * @param chainID_ chain ID
     * @return calculated calculated salt
     */
    function getBridgePoolSalt(
        address tokenContractAddr_,
        uint8 tokenType_,
        uint256 chainID_,
        uint16 version_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    keccak256(abi.encodePacked(tokenContractAddr_)),
                    keccak256(abi.encodePacked(tokenType_)),
                    keccak256(abi.encodePacked(chainID_)),
                    keccak256(abi.encodePacked(version_))
                )
            );
    }

    function getBridgePoolAddress(
        bytes32 bridgePoolSalt_,
        address bridgeFactory_
    ) internal pure returns (address) {
        // works: 5880818283335afa3d82833e3d82f3
        bytes32 initCodeHash = 0xf231e946a2f88d89eafa7b43271c54f58277304b93ac77d138d9b0bb3a989b6d;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(hex"ff", bridgeFactory_, bridgePoolSalt_, initCodeHash)
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/CircuitBreakerErrors.sol";

abstract contract CircuitBreaker {
    // constants for the cb state
    bool internal constant _CIRCUIT_BREAKER_CLOSED = false;
    bool internal constant _CIRCUIT_BREAKER_OPENED = true;

    // Same as _CIRCUIT_BREAKER_CLOSED
    bool internal _circuitBreaker;

    // withCircuitBreaker is a modifier to enforce the CircuitBreaker must
    // be set for a call to succeed
    modifier withCircuitBreaker() {
        if (_circuitBreaker == _CIRCUIT_BREAKER_OPENED) {
            revert CircuitBreakerErrors.CircuitBreakerOpened();
        }
        _;
    }

    function circuitBreakerState() public view returns (bool) {
        return _circuitBreaker;
    }

    function _tripCB() internal {
        if (_circuitBreaker == _CIRCUIT_BREAKER_OPENED) {
            revert CircuitBreakerErrors.CircuitBreakerOpened();
        }

        _circuitBreaker = _CIRCUIT_BREAKER_OPENED;
    }

    function _resetCB() internal {
        if (_circuitBreaker == _CIRCUIT_BREAKER_CLOSED) {
            revert CircuitBreakerErrors.CircuitBreakerClosed();
        }

        _circuitBreaker = _CIRCUIT_BREAKER_CLOSED;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/CustomEnumerableMapsErrors.sol";

struct ValidatorData {
    address _address;
    uint256 _tokenID;
}

struct ExitingValidatorData {
    uint128 _tokenID;
    uint128 _freeAfter;
}

struct ValidatorDataMap {
    ValidatorData[] _values;
    mapping(address => uint256) _indexes;
}

library CustomEnumerableMaps {
    /**
     * @dev Add a value to a map. O(1).
     *
     * Returns true if the value was added to the map, that is if it was not
     * already present.
     */
    function add(ValidatorDataMap storage map, ValidatorData memory value) internal returns (bool) {
        if (!contains(map, value._address)) {
            map._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[value._address] = map._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a map using its address. O(1).
     *
     * Returns true if the value was removed from the map, that is if it was
     * present.
     */
    function remove(ValidatorDataMap storage map, address key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = map._indexes[key];

        if (valueIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = map._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                ValidatorData memory lastValue = map._values[lastIndex];

                // Move the last value to the index where the value to delete is
                map._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                map._indexes[lastValue._address] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved key was stored
            map._values.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(ValidatorDataMap storage map, address key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of values in the map. O(1).
     */
    function length(ValidatorDataMap storage map) internal view returns (uint256) {
        return map._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        ValidatorDataMap storage map,
        uint256 index
    ) internal view returns (ValidatorData memory) {
        return map._values[index];
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     */
    function tryGet(
        ValidatorDataMap storage map,
        address key
    ) internal view returns (bool, ValidatorData memory) {
        uint256 index = map._indexes[key];
        if (index == 0) {
            return (false, ValidatorData(address(0), 0));
        } else {
            return (true, map._values[index - 1]);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        ValidatorDataMap storage map,
        address key
    ) internal view returns (ValidatorData memory) {
        (bool success, ValidatorData memory value) = tryGet(map, key);
        if (!success) {
            revert CustomEnumerableMapsErrors.KeyNotInMap(key);
        }
        return value;
    }

    /**
     * @dev Return the entire map in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(ValidatorDataMap storage map) internal view returns (ValidatorData[] memory) {
        return map._values;
    }

    /**
     * @dev Return the address of every entry in the entire map in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function addressValues(ValidatorDataMap storage map) internal view returns (address[] memory) {
        ValidatorData[] memory _values = values(map);
        address[] memory addresses = new address[](_values.length);
        for (uint256 i = 0; i < _values.length; i++) {
            addresses[i] = _values[i]._address;
        }
        return addresses;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(
        bytes32 _salt,
        address _factory
    ) public pure returns (address) {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/libraries/errors/ERC20SafeTransferErrors.sol";

abstract contract ERC20SafeTransfer {
    // _safeTransferFromERC20 performs a transferFrom call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferFromERC20(
        IERC20Transferable contract_,
        address sender_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }

        bool success = contract_.transferFrom(sender_, address(this), amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                sender_,
                address(this),
                amount_
            );
        }
    }

    // _safeTransferERC20 performs a transfer call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferERC20(
        IERC20Transferable contract_,
        address to_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }
        bool success = contract_.transfer(to_, amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                address(this),
                to_,
                amount_
            );
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ETHDKGUtils {
    function _getThreshold(uint256 numParticipants_) internal pure returns (uint256 threshold) {
        // In our BFT consensus alg, we require t + 1 > 2*n/3.
        // Where t = threshold, n = numParticipants and k = quotient from the integer division
        // There are 3 possibilities for n:
        //
        //  n == 3*k:
        //      We set
        //                          t = 2*k
        //      This implies
        //                      2*k     == t     <= 2*n/3 == 2*k
        //      and
        //                      2*k + 1 == t + 1  > 2*n/3 == 2*k
        //
        //  n == 3*k + 1:
        //      We set
        //                          t = 2*k
        //      This implies
        //                      2*k     == t     <= 2*n/3 == 2*k + 1/3
        //      and
        //                      2*k + 1 == t + 1  > 2*n/3 == 2*k + 1/3
        //
        //  n == 3*k + 2:
        //      We set
        //                          t = 2*k + 1
        //      This implies
        //                      2*k + 1 == t     <= 2*n/3 == 2*k + 4/3
        //      and
        //                      2*k + 2 == t + 1  > 2*n/3 == 2*k + 4/3
        uint256 quotient = numParticipants_ / 3;
        threshold = 2 * quotient;
        uint256 remainder = numParticipants_ - 3 * quotient;
        if (remainder == 2) {
            threshold = threshold + 1;
        }
    }

    function _isBitSet(uint256 self, uint8 index) internal pure returns (bool) {
        uint256 val;
        assembly ("memory-safe") {
            val := and(shr(index, self), 1)
        }
        return (val == 1);
    }

    function _setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        assembly ("memory-safe") {
            self := or(shl(index, 1), self)
        }
        return (self);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/ETHSafeTransferErrors.sol";

abstract contract EthSafeTransfer {
    /// @notice _safeTransferEth performs a transfer of Eth using the call
    /// method / this function is resistant to breaking gas price changes and /
    /// performs call in a safe manner by reverting on failure. / this function
    /// will return without performing a call or reverting, / if amount_ is zero
    function _safeTransferEth(address to_, uint256 amount_) internal {
        if (amount_ == 0) {
            return;
        }
        if (to_ == address(0)) {
            revert ETHSafeTransferErrors.CannotTransferToZeroAddress();
        }
        address payable caller = payable(to_);
        (bool success, ) = caller.call{value: amount_}("");
        if (!success) {
            revert ETHSafeTransferErrors.EthTransferFailed(address(this), to_, amount_);
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MagicValue.sol";
import "contracts/interfaces/IMagicEthTransfer.sol";

abstract contract MagicEthTransfer is MagicValue {
    function _safeTransferEthWithMagic(IMagicEthTransfer to_, uint256 amount_) internal {
        to_.depositEth{value: amount_}(_getMagic());
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MagicValue.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IMagicTokenTransfer.sol";
import "contracts/libraries/errors/MagicTokenTransferErrors.sol";

abstract contract MagicTokenTransfer is MagicValue {
    function _safeTransferTokenWithMagic(
        IERC20Transferable token_,
        IMagicTokenTransfer to_,
        uint256 amount_
    ) internal {
        bool success = token_.approve(address(to_), amount_);
        if (!success) {
            revert MagicTokenTransferErrors.TransferFailed(address(token_), address(to_), amount_);
        }
        to_.depositToken(_getMagic(), amount_);
        token_.approve(address(to_), 0);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/MagicValueErrors.sol";

abstract contract MagicValue {
    // _MAGIC_VALUE is a constant that may be used to prevent
    // a user from calling a dangerous method without significant
    // effort or ( hopefully ) reading the code to understand the risk
    uint8 internal constant _MAGIC_VALUE = 42;

    modifier checkMagic(uint8 magic_) {
        if (magic_ != _getMagic()) {
            revert MagicValueErrors.BadMagic(magic_);
        }
        _;
    }

    // _getMagic returns the magic constant
    function _getMagic() internal pure returns (uint8) {
        return _MAGIC_VALUE;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/parsers/MerkleProofParserLibrary.sol";
import "contracts/libraries/errors/MerkleProofLibraryErrors.sol";

library MerkleProofLibrary {
    /// @notice Check if the bit at the given `index` in `self` is set. Function
    /// used to decode the bitmap, i.e, knowing when to use  a leaf node or a
    // default leaf node hash when reconstructing the proof.
    /// @param self the input bitmap as bytes
    /// @param index the index to check if it's set
    /// @return `true` if the value of the bit is `1`, `false` if the value of the bit is `0`
    function bitSet(bytes memory self, uint16 index) internal pure returns (bool) {
        uint256 val;
        assembly ("memory-safe") {
            val := shr(sub(255, index), and(mload(add(self, 0x20)), shl(sub(255, index), 1)))
        }
        return val == 1;
    }

    /// @notice Check if the bit at the given `index` in `self` is set. Similar
    //  to `bitSet(bytes)` but used to decide which side of the binary tree to
    //  follow using the key when reconstructing the merkle proof.
    /// @param self the input bitmap as bytes32 / @param index the index to
    ///check if it's set
    /// @return `true` if the value of the bit is `1`, `false` if the value of
    /// the bit is `0`
    function bitSetBytes32(bytes32 self, uint16 index) internal pure returns (bool) {
        uint256 val;
        assembly ("memory-safe") {
            val := shr(sub(255, index), and(self, shl(sub(255, index), 1)))
        }
        return val == 1;
    }

    /// @notice Computes the leaf hash.
    /// @param key the key/UTXOID
    /// @param value the value
    /// @param proofHeight the proof height (number of elements in the uncompressed merkle proof) from 0 - 256
    /// @return the leaf hash
    function computeLeafHash(
        bytes32 key,
        bytes32 value,
        uint16 proofHeight
    ) internal pure returns (bytes32) {
        if (proofHeight > 256) {
            revert MerkleProofLibraryErrors.InvalidProofHeight(proofHeight);
        }

        return keccak256(abi.encodePacked(key, value, uint8(256 - proofHeight)));
    }

    /// @notice Checks if `proof` is a valid inclusion proof.
    /// @param _proof the merkle proof (audit path)
    /// @param root the root of the tree
    function verifyInclusion(
        MerkleProofParserLibrary.MerkleProof memory _proof,
        bytes32 root
    ) internal pure {
        if (_proof.proofValue == 0) {
            revert MerkleProofLibraryErrors.InclusionZero();
        }
        bytes32 _keyHash = computeLeafHash(_proof.key, _proof.proofValue, _proof.keyHeight);
        bool result = checkProof(
            _proof.auditPath,
            root,
            _keyHash,
            _proof.key,
            _proof.bitmap,
            _proof.keyHeight
        );
        if (!result) {
            revert MerkleProofLibraryErrors.ProofDoesNotMatchTrieRoot();
        }
    }

    /// @notice Checks if `proof` is a valid non-inclusion proof.
    /// @param _proof the merkle proof (audit path)
    /// @param root the root of the tree
    function verifyNonInclusion(
        MerkleProofParserLibrary.MerkleProof memory _proof,
        bytes32 root
    ) internal pure {
        if (_proof.proofKey == 0 && _proof.proofValue == 0) {
            // Non-inclusion default value
            bytes32 _keyHash = bytes32(
                hex"bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a"
            );
            bool result = checkProof(
                _proof.auditPath,
                root,
                _keyHash,
                _proof.key,
                _proof.bitmap,
                _proof.keyHeight
            );
            if (!result) {
                revert MerkleProofLibraryErrors.DefaultLeafNotFoundInKeyPath();
            }
        } else if (_proof.proofKey != 0 && _proof.proofValue != 0) {
            // Non-inclusion leaf node
            bytes32 _keyHash = computeLeafHash(
                _proof.proofKey,
                _proof.proofValue,
                _proof.keyHeight
            );
            bool result = checkProof(
                _proof.auditPath,
                root,
                _keyHash,
                _proof.key,
                _proof.bitmap,
                _proof.keyHeight
            );
            if (!result) {
                revert MerkleProofLibraryErrors.ProvidedLeafNotFoundInKeyPath();
            }
        } else {
            // _proof.proofKey != 0 && _proof.proofValue == 0 or _proof.proofKey == 0 && _proof.proofValue != 0
            revert MerkleProofLibraryErrors.InvalidNonInclusionMerkleProof();
        }
    }

    /// @notice Checks if `proof` is a valid inclusion proof.
    /// @param auditPath the audit path to reconstruct the proof
    /// @param root the root of the tree
    /// @param keyHash the leaf hash used to reconstruct the proof
    /// @param key the key of the transaction
    /// @param bitmap the bitmap of the compact merkle proof
    /// @param proofHeight the height of the proof
    /// @return `true` if the proof is valid, `false` otherwise
    function checkProof(
        bytes memory auditPath,
        bytes32 root,
        bytes32 keyHash,
        bytes32 key,
        bytes memory bitmap,
        uint16 proofHeight
    ) internal pure returns (bool) {
        bytes32 el;
        bytes32 h = keyHash;

        bytes32 defaultLeaf = bytes32(
            hex"bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a"
        );

        uint16 proofIdx = 0;
        if (proofHeight > 256) {
            revert MerkleProofLibraryErrors.InvalidProofHeight(proofHeight);
        }
        for (uint256 i = 0; i < proofHeight; i++) {
            if (bitSet(bitmap, uint16(i))) {
                proofIdx += 32;
                assembly ("memory-safe") {
                    el := mload(add(auditPath, proofIdx))
                }
            } else {
                el = defaultLeaf;
            }

            if (bitSetBytes32(key, proofHeight - 1 - uint16(i))) {
                h = keccak256(abi.encodePacked(el, h));
            } else {
                h = keccak256(abi.encodePacked(h, el));
            }
        }
        return h == root;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/MutexErrors.sol";

abstract contract Mutex {
    uint256 internal constant _LOCKED = 1;
    uint256 internal constant _UNLOCKED = 2;
    uint256 internal _mutex;

    modifier withLock() {
        if (_mutex == _LOCKED) {
            revert MutexErrors.MutexLocked();
        }
        _mutex = _LOCKED;
        _;
        _mutex = _UNLOCKED;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

contract Utils {
    function getCodeSize(address target) public view returns (uint256) {
        uint256 csize;
        assembly ("memory-safe") {
            csize := extcodesize(target)
        }
        return csize;
    }

    function getCode(address addr_) public view returns (bytes memory outputCode) {
        assembly ("memory-safe") {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr_)
            // allocate output byte array - this could also be done without assembly
            // by using outputCode = new bytes(size)
            outputCode := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(outputCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(outputCode, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(addr_, add(outputCode, 0x20), 0, size)
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IERC721Transferable.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicValue.sol";
import "contracts/utils/CustomEnumerableMaps.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/libraries/validatorPool/ValidatorPoolStorage.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/libraries/errors/ValidatorPoolErrors.sol";

/**
 * @notice ValidatorPool is the contract responsible for interfacing and
 * handling all the logic for the AliceNet validators.
 * This contract interacts mainly with the validatorStaking, Snapshots and
 * Ethdkg contracts.
 *
 * @custom:salt ValidatorPool
 * @custom:deploy-type deployUpgradeable
 */
contract ValidatorPool is
    Initializable,
    ValidatorPoolStorage,
    IValidatorPool,
    MagicValue,
    EthSafeTransfer,
    ERC20SafeTransfer,
    ERC721Holder
{
    using CustomEnumerableMaps for ValidatorDataMap;

    /**
     * Modifier to guarantee that only a validator is calling a function.
     */
    modifier onlyValidator() {
        if (!_isValidator(msg.sender)) {
            revert ValidatorPoolErrors.CallerNotValidator(msg.sender);
        }
        _;
    }

    /**
     * Modifier to make sure that the AliceNet consensus is not running.
     */
    modifier assertNotConsensusRunning() {
        if (_isConsensusRunning) {
            revert ValidatorPoolErrors.ConsensusRunning();
        }
        _;
    }

    /**
     * Modifier to make sure that an ETHDKG round is not running.
     */
    modifier assertNotETHDKGRunning() {
        if (IETHDKG(_ethdkgAddress()).isETHDKGRunning()) {
            revert ValidatorPoolErrors.ETHDKGRoundRunning();
        }
        _;
    }

    /**
     * Modifier to make sure that the validatorPool doesn't held any asserts during
     * operations that send asserts to accounts.
     */
    modifier balanceShouldNotChange() {
        uint256 balanceBeforeToken = IERC20Transferable(_alcaAddress()).balanceOf(address(this));
        uint256 balanceBeforeEth = address(this).balance;
        _;
        if (balanceBeforeToken != IERC20Transferable(_alcaAddress()).balanceOf(address(this))) {
            revert ValidatorPoolErrors.TokenBalanceChangedDuringOperation();
        }
        if (balanceBeforeEth != address(this).balance) {
            revert ValidatorPoolErrors.EthBalanceChangedDuringOperation();
        }
    }

    constructor() ValidatorPoolStorage() {}

    /**
     * @dev only the staking contracts are allowed to send ethereum to this
     * contract. However, the ether is forward to other accounts in the same
     * transaction.
     */
    receive() external payable {
        if (msg.sender != _validatorStakingAddress() && msg.sender != _publicStakingAddress()) {
            revert ValidatorPoolErrors.OnlyStakingContractsAllowed();
        }
    }

    function initialize(
        uint256 stakeAmount_,
        uint256 maxNumValidators_,
        uint256 disputerReward_,
        uint256 maxIntervalWithoutSnapshots_
    ) public onlyFactory initializer {
        _stakeAmount = stakeAmount_;
        _maxNumValidators = maxNumValidators_;
        _disputerReward = disputerReward_;
        _maxIntervalWithoutSnapshots = maxIntervalWithoutSnapshots_;
    }

    /**
     * Sets the minimum stake amount to become a validator. Can only be called by
     * the contract factory.
     * @param stakeAmount_ the new minimum stake amount to become a validator.
     */
    function setStakeAmount(uint256 stakeAmount_) public onlyFactory {
        _stakeAmount = stakeAmount_;
    }

    /**
     * Sets the max interval without snapshot. If the interval has passed, all the
     * validators can be kicked by the factory. Can only be called by
     * the contract factory.
     * @param maxIntervalWithoutSnapshots The new max interval without snapshot.
     */
    function setMaxIntervalWithoutSnapshots(
        uint256 maxIntervalWithoutSnapshots
    ) public onlyFactory {
        if (maxIntervalWithoutSnapshots == 0) {
            revert ValidatorPoolErrors.MaxIntervalWithoutSnapshotsMustBeNonZero();
        }
        _maxIntervalWithoutSnapshots = maxIntervalWithoutSnapshots;
    }

    /**
     * Sets the max number of validators that we can have on AliceNet. Can only be
     * called by the contract factory.
     * @param maxNumValidators_ The new maximum number of validators.
     */
    function setMaxNumValidators(uint256 maxNumValidators_) public onlyFactory {
        if (maxNumValidators_ < _validators.length()) {
            revert ValidatorPoolErrors.MaxNumValidatorsIsTooLow(
                maxNumValidators_,
                _validators.length()
            );
        }
        _maxNumValidators = maxNumValidators_;
    }

    /**
     * Sets the amount of ALCA that a person valid accusing a validator will gain
     * as reward. Can only be called by the contract factory.
     * @param disputerReward_ the new reward amount.
     */
    function setDisputerReward(uint256 disputerReward_) public onlyFactory {
        _disputerReward = disputerReward_;
    }

    /**
     * Sets the ip location of a validator. Only a validator can register its
     * location.
     *  @param ip_ the validator's ip address.
     */
    function setLocation(string calldata ip_) public onlyValidator {
        _ipLocations[msg.sender] = ip_;
    }

    /**
     * Schedule a maintenance window to change validators. The maintenance window
     * will cause AliceNet consensus to halt on the next snapshot, allowing the safe
     * change (exit and entry) of validators. Can only be called by the factory.
     */
    function scheduleMaintenance() public onlyFactory {
        _isMaintenanceScheduled = true;
        emit MaintenanceScheduled();
    }

    /**
     * Initialize a new ETHDKG ceremony, where the validators can create a master
     * Private and public key to be used to participate on the aliceNet consensus
     * and mine blocks. This function can only be called by the factory and requires
     * that no ETHDKG round is running and the consensus is stopped on the AliceNet
     * network.
     */
    function initializeETHDKG()
        public
        onlyFactory
        assertNotETHDKGRunning
        assertNotConsensusRunning
    {
        IETHDKG(_ethdkgAddress()).initializeETHDKG();
    }

    /**
     * Callback function to be called by the ETHDKG contract to correctly set the
     * consensus running and maintenance flags. Can only be called by the ETHDKG
     * contract.
     */
    function completeETHDKG() public onlyETHDKG {
        _isMaintenanceScheduled = false;
        _isConsensusRunning = true;
    }

    /**
     * Callback function to be called by the snapshots contract to correctly set the
     * consensus flag. Can only be called by the snapshots contract.
     */
    function pauseConsensus() public onlySnapshots {
        _isConsensusRunning = false;
    }

    /**
     * Function to "pause" the AliceNet consensus flag in the smart contract if the
     * consensus is halted on the side chain. Consensus will be halted on the side
     * chain if not snapshot is committed by the validators in a certain amount of
     * time. Setting the `_isConsensusRunning ` flag, forcefully enables the factory
     * to change the validators without having to wait for a snapshot.
     */
    function pauseConsensusOnArbitraryHeight(uint256 aliceNetHeight_) public onlyFactory {
        uint256 targetBlockNumber = ISnapshots(_snapshotsAddress())
            .getCommittedHeightFromLatestSnapshot() + _maxIntervalWithoutSnapshots;
        if (block.number <= targetBlockNumber) {
            revert ValidatorPoolErrors.MinimumBlockIntervalNotMet(block.number, targetBlockNumber);
        }
        _isConsensusRunning = false;
        IETHDKG(_ethdkgAddress()).setCustomAliceNetHeight(aliceNetHeight_);
    }

    /**
     * Function that allows the factory to register a set of validators. In order to
     * register a validator, a Public staking position of amount greater the
     * `stakeAmount` should be consumed. As a result of becoming a validator, the
     * registered address will have the right to collect the profits for a validator
     * staking position held by this contract after it has successfully participated
     * on an ETHDKG ceremony. This function can only be called by the factory and as
     * requirements the AliceNetConsensus and ETHDKG round should not be running.
     * @param validators_ array of addresses that will be added as validators.
     * @param stakerTokenIDs_ array of public staking positions that will be
     * consumed to register the validators.
     */
    function registerValidators(
        address[] memory validators_,
        uint256[] memory stakerTokenIDs_
    ) public onlyFactory assertNotETHDKGRunning assertNotConsensusRunning {
        if (validators_.length + _validators.length() > _maxNumValidators) {
            revert ValidatorPoolErrors.NotEnoughValidatorSlotsAvailable(
                validators_.length,
                _maxNumValidators - _validators.length()
            );
        }
        if (validators_.length != stakerTokenIDs_.length) {
            revert ValidatorPoolErrors.RegistrationParameterLengthMismatch(
                validators_.length,
                stakerTokenIDs_.length
            );
        }

        for (uint256 i = 0; i < validators_.length; i++) {
            if (msg.sender != IERC721(_publicStakingAddress()).ownerOf(stakerTokenIDs_[i])) {
                revert ValidatorPoolErrors.SenderShouldOwnPosition(stakerTokenIDs_[i]);
            }
            _registerValidator(validators_[i], stakerTokenIDs_[i]);
        }
    }

    /**
     * Function that allows the factory to unregister validators. Unregistered
     * validators will be able to get the stake amount of the original public
     * position consumed on registration back as another public staking position by
     * calling the `claimExitingNFTPosition` after X amount of epochs has passed.
     * This function can only be called by the factory and as requirements the
     * AliceNetConsensus and ETHDKG round should not be running.
     * @param validators_ the array of validators to be unregistered.
     */
    function unregisterValidators(
        address[] memory validators_
    ) public onlyFactory assertNotETHDKGRunning assertNotConsensusRunning {
        if (validators_.length > _validators.length()) {
            revert ValidatorPoolErrors.LengthGreaterThanAvailableValidators(
                validators_.length,
                _validators.length()
            );
        }
        for (uint256 i = 0; i < validators_.length; i++) {
            _unregisterValidator(validators_[i]);
        }
    }

    /**
     * Same as unregisterValidators but unregister all validators at once. This
     * function can only be called by the factory and as requirements the
     * AliceNetConsensus and ETHDKG round should not be running.
     */
    function unregisterAllValidators()
        public
        onlyFactory
        assertNotETHDKGRunning
        assertNotConsensusRunning
    {
        while (_validators.length() > 0) {
            address validator = _validators.at(_validators.length() - 1)._address;
            _unregisterValidator(validator);
        }
    }

    /**
     * Function that allows an address registered as validator to collect the
     * profits of "its" entitled validator staking position.
     */
    function collectProfits()
        public
        onlyValidator
        balanceShouldNotChange
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        if (!_isConsensusRunning) {
            revert ValidatorPoolErrors.ProfitsOnlyClaimableWhileConsensusRunning();
        }

        uint256 validatorTokenID = _validators.get(msg.sender)._tokenID;
        payoutEth = IStakingNFT(_validatorStakingAddress()).collectEthTo(
            msg.sender,
            validatorTokenID
        );
        payoutToken = IStakingNFT(_validatorStakingAddress()).collectTokenTo(
            msg.sender,
            validatorTokenID
        );

        return (payoutEth, payoutToken);
    }

    /**
     * Function that allows an unregistered validator to claim the registered staked
     * amount as public staking position after the waiting period in epochs has
     * passed.
     */
    function claimExitingNFTPosition() public returns (uint256) {
        ExitingValidatorData memory data = _exitingValidatorsData[msg.sender];
        if (data._freeAfter == 0) {
            revert ValidatorPoolErrors.SenderNotInExitingQueue(msg.sender);
        }
        if (ISnapshots(_snapshotsAddress()).getEpoch() <= data._freeAfter) {
            revert ValidatorPoolErrors.WaitingPeriodNotMet();
        }

        _removeExitingQueueData(msg.sender);

        IStakingNFT(_publicStakingAddress()).lockOwnPosition(data._tokenID, POSITION_LOCK_PERIOD);

        IERC721Transferable(_publicStakingAddress()).safeTransferFrom(
            address(this),
            msg.sender,
            data._tokenID
        );

        return data._tokenID;
    }

    function majorSlash(
        address dishonestValidator_,
        address disputer_
    ) public onlyETHDKG balanceShouldNotChange {
        if (!_isAccusable(dishonestValidator_)) {
            revert ValidatorPoolErrors.AddressNotAccusable(dishonestValidator_);
        }

        (uint256 minerShares, uint256 payoutEth, uint256 payoutToken) = _slash(dishonestValidator_);
        // deciding which state to clean based if the accusable person was a active validator or was
        // in the exiting line
        if (isValidator(dishonestValidator_)) {
            _removeValidatorData(dishonestValidator_);
        } else {
            _removeExitingQueueData(dishonestValidator_);
        }
        // redistribute the dishonest staking equally with the other validators

        IERC20Transferable(_alcaAddress()).approve(_validatorStakingAddress(), minerShares);
        IStakingNFT(_validatorStakingAddress()).depositToken(_getMagic(), minerShares);
        // transfer to the disputer any profit that the dishonestValidator had when his
        // position was burned + the disputerReward
        _transferEthAndTokens(disputer_, payoutEth, payoutToken);

        emit ValidatorMajorSlashed(dishonestValidator_);
    }

    function minorSlash(
        address dishonestValidator_,
        address disputer_
    ) public onlyETHDKG balanceShouldNotChange {
        if (!_isAccusable(dishonestValidator_)) {
            revert ValidatorPoolErrors.AddressNotAccusable(dishonestValidator_);
        }
        (uint256 minerShares, uint256 payoutEth, uint256 payoutToken) = _slash(dishonestValidator_);
        uint256 stakeTokenID;
        // In case there's not enough shares to create a new PublicStaking position, state is just
        // cleaned and the rest of the funds is sent to the disputer
        if (minerShares > 0) {
            stakeTokenID = _mintPublicStakingPosition(minerShares);
            _moveToExitingQueue(dishonestValidator_, stakeTokenID);
        } else {
            if (isValidator(dishonestValidator_)) {
                _removeValidatorData(dishonestValidator_);
            } else {
                _removeExitingQueueData(dishonestValidator_);
            }
        }
        _transferEthAndTokens(disputer_, payoutEth, payoutToken);
        emit ValidatorMinorSlashed(dishonestValidator_, stakeTokenID);
    }

    /// skimExcessEth will allow the Admin role to refund any Eth sent to this contract in error by a
    /// user. This function should only be necessary if a user somehow manages to accidentally
    /// selfDestruct a contract with this contract as the recipient or use the PublicStaking burnTo with the
    /// address of this contract.
    function skimExcessEth(address to_) public onlyFactory returns (uint256 excess) {
        // This contract shouldn't held any eth balance.
        // todo: revisit this when we have the dutch auction
        excess = address(this).balance;
        _safeTransferEth(to_, excess);
        return excess;
    }

    /// skimExcessToken will allow the Admin role to refund any ALCA sent to this contract in error
    /// by a user.
    function skimExcessToken(address to_) public onlyFactory returns (uint256 excess) {
        // This contract shouldn't held any token balance.
        IERC20Transferable alca = IERC20Transferable(_alcaAddress());
        excess = alca.balanceOf(address(this));
        _safeTransferERC20(alca, to_, excess);
        return excess;
    }

    function getStakeAmount() public view returns (uint256) {
        return _stakeAmount;
    }

    function getMaxIntervalWithoutSnapshots()
        public
        view
        returns (uint256 maxIntervalWithoutSnapshots)
    {
        return _maxIntervalWithoutSnapshots;
    }

    function getMaxNumValidators() public view returns (uint256) {
        return _maxNumValidators;
    }

    function getDisputerReward() public view returns (uint256) {
        return _disputerReward;
    }

    function getValidatorsCount() public view returns (uint256) {
        return _validators.length();
    }

    function getValidatorsAddresses() public view returns (address[] memory) {
        return _validators.addressValues();
    }

    function getValidator(uint256 index_) public view returns (address) {
        if (index_ >= _validators.length()) {
            revert ValidatorPoolErrors.InvalidIndex(index_);
        }
        return _validators.at(index_)._address;
    }

    function getValidatorData(uint256 index_) public view returns (ValidatorData memory) {
        if (index_ >= _validators.length()) {
            revert ValidatorPoolErrors.InvalidIndex(index_);
        }
        return _validators.at(index_);
    }

    function getLocation(address validator_) public view returns (string memory) {
        return _ipLocations[validator_];
    }

    function getLocations(address[] calldata validators_) public view returns (string[] memory) {
        string[] memory ret = new string[](validators_.length);
        for (uint256 i = 0; i < validators_.length; i++) {
            ret[i] = _ipLocations[validators_[i]];
        }
        return ret;
    }

    /// @notice Try to get the NFT tokenID for an account.
    /// @param account_ address of the account to try to retrieve the tokenID
    /// @return tuple (bool, address, uint256). Return true if the value was found, false if not.
    /// Returns the address of the NFT contract and the tokenID. In case the value was not found, tokenID
    /// and address are 0.
    function tryGetTokenID(address account_) public view returns (bool, address, uint256) {
        if (_isValidator(account_)) {
            return (true, _validatorStakingAddress(), _validators.get(account_)._tokenID);
        } else if (_isInExitingQueue(account_)) {
            return (true, _publicStakingAddress(), _exitingValidatorsData[account_]._tokenID);
        } else {
            return (false, address(0), 0);
        }
    }

    function isValidator(address account_) public view returns (bool) {
        return _isValidator(account_);
    }

    function isInExitingQueue(address account_) public view returns (bool) {
        return _isInExitingQueue(account_);
    }

    function isAccusable(address account_) public view returns (bool) {
        return _isAccusable(account_);
    }

    function isMaintenanceScheduled() public view returns (bool) {
        return _isMaintenanceScheduled;
    }

    function isConsensusRunning() public view returns (bool) {
        return _isConsensusRunning;
    }

    function _transferEthAndTokens(address to_, uint256 payoutEth_, uint256 payoutToken_) internal {
        _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, payoutToken_);
        _safeTransferEth(to_, payoutEth_);
    }

    function _registerValidator(
        address validator_,
        uint256 stakerTokenID_
    )
        internal
        balanceShouldNotChange
        returns (uint256 validatorTokenID, uint256 payoutEth, uint256 payoutToken)
    {
        if (_validators.length() >= _maxNumValidators) {
            revert ValidatorPoolErrors.NotEnoughValidatorSlotsAvailable(1, 0);
        }
        if (_isAccusable(validator_)) {
            revert ValidatorPoolErrors.AddressAlreadyValidator(validator_);
        }

        (validatorTokenID, payoutEth, payoutToken) = _swapPublicStakingForValidatorStaking(
            msg.sender,
            stakerTokenID_
        );

        _validators.add(ValidatorData(validator_, validatorTokenID));
        // transfer back any profit that was available for the PublicStaking position by the time that we
        // burned it
        _transferEthAndTokens(validator_, payoutEth, payoutToken);
        emit ValidatorJoined(validator_, validatorTokenID);
    }

    function _unregisterValidator(
        address validator_
    )
        internal
        balanceShouldNotChange
        returns (uint256 stakeTokenID, uint256 payoutEth, uint256 payoutToken)
    {
        if (!_isValidator(validator_)) {
            revert ValidatorPoolErrors.AddressNotValidator(validator_);
        }
        (stakeTokenID, payoutEth, payoutToken) = _swapValidatorStakingForPublicStaking(validator_);

        _moveToExitingQueue(validator_, stakeTokenID);

        // transfer back any profit that was available for the PublicStaking position by the time that we
        // burned it
        _transferEthAndTokens(validator_, payoutEth, payoutToken);
        emit ValidatorLeft(validator_, stakeTokenID);
    }

    function _swapPublicStakingForValidatorStaking(
        address to_,
        uint256 stakerTokenID_
    ) internal returns (uint256 validatorTokenID, uint256 payoutEth, uint256 payoutToken) {
        (uint256 stakeShares, , , , ) = IStakingNFT(_publicStakingAddress()).getPosition(
            stakerTokenID_
        );
        uint256 stakeAmount = _stakeAmount;
        if (stakeShares < stakeAmount) {
            revert ValidatorPoolErrors.InsufficientFundsInStakePosition(stakeShares, stakeAmount);
        }
        IERC721Transferable(_publicStakingAddress()).safeTransferFrom(
            to_,
            address(this),
            stakerTokenID_
        );
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).burn(stakerTokenID_);

        // Subtracting the shares from PublicStaking profit. The shares will be used to mint the new
        // ValidatorPosition
        //payoutToken should always have the minerShares in it!
        if (payoutToken < stakeShares) {
            revert ValidatorPoolErrors.PayoutTooLow();
        }
        payoutToken -= stakeAmount;

        validatorTokenID = _mintValidatorStakingPosition(stakeAmount);

        return (validatorTokenID, payoutEth, payoutToken);
    }

    function _swapValidatorStakingForPublicStaking(
        address validator_
    ) internal returns (uint256, uint256, uint256) {
        (
            uint256 minerShares,
            uint256 payoutEth,
            uint256 payoutToken
        ) = _burnValidatorStakingPosition(validator_);
        //payoutToken should always have the minerShares in it!
        if (payoutToken < minerShares) {
            revert ValidatorPoolErrors.PayoutTooLow();
        }
        payoutToken -= minerShares;

        uint256 stakeTokenID = _mintPublicStakingPosition(minerShares);

        return (stakeTokenID, payoutEth, payoutToken);
    }

    function _mintValidatorStakingPosition(
        uint256 minerShares_
    ) internal returns (uint256 validatorTokenID) {
        // We should approve the validatorStaking to transferFrom the tokens of this contract
        IERC20Transferable(_alcaAddress()).approve(_validatorStakingAddress(), minerShares_);
        validatorTokenID = IStakingNFT(_validatorStakingAddress()).mint(minerShares_);
    }

    function _mintPublicStakingPosition(
        uint256 minerShares_
    ) internal returns (uint256 stakeTokenID) {
        // We should approve the PublicStaking to transferFrom the tokens of this contract
        IERC20Transferable(_alcaAddress()).approve(_publicStakingAddress(), minerShares_);
        stakeTokenID = IStakingNFT(_publicStakingAddress()).mint(minerShares_);
    }

    function _burnValidatorStakingPosition(
        address validator_
    ) internal returns (uint256 minerShares, uint256 payoutEth, uint256 payoutToken) {
        uint256 validatorTokenID = _validators.get(validator_)._tokenID;
        (minerShares, payoutEth, payoutToken) = _burnNFTPosition(
            validatorTokenID,
            _validatorStakingAddress()
        );
    }

    function _burnExitingPublicStakingPosition(
        address validator_
    ) internal returns (uint256 minerShares, uint256 payoutEth, uint256 payoutToken) {
        uint256 stakerTokenID = _exitingValidatorsData[validator_]._tokenID;
        (minerShares, payoutEth, payoutToken) = _burnNFTPosition(
            stakerTokenID,
            _publicStakingAddress()
        );
    }

    function _burnNFTPosition(
        uint256 tokenID_,
        address stakeContractAddress_
    ) internal returns (uint256 minerShares, uint256 payoutEth, uint256 payoutToken) {
        IStakingNFT stakeContract = IStakingNFT(stakeContractAddress_);
        (minerShares, , , , ) = stakeContract.getPosition(tokenID_);
        (payoutEth, payoutToken) = stakeContract.burn(tokenID_);
    }

    function _slash(
        address dishonestValidator_
    ) internal returns (uint256 minerShares, uint256 payoutEth, uint256 payoutToken) {
        if (!_isAccusable(dishonestValidator_)) {
            revert ValidatorPoolErrors.AddressNotAccusable(dishonestValidator_);
        }
        // If the user accused is a valid validator, we should burn is validatorStaking position,
        // otherwise we burn the user's PublicStaking in the exiting line
        if (_isValidator(dishonestValidator_)) {
            (minerShares, payoutEth, payoutToken) = _burnValidatorStakingPosition(
                dishonestValidator_
            );
        } else {
            (minerShares, payoutEth, payoutToken) = _burnExitingPublicStakingPosition(
                dishonestValidator_
            );
        }
        uint256 disputerReward = _disputerReward;
        if (minerShares >= disputerReward) {
            minerShares -= disputerReward;
        } else {
            // In case there's not enough shares to cover the _disputerReward, minerShares is set to
            // 0 and the rest of the payout Token is sent to disputer
            minerShares = 0;
        }
        //payoutToken should always have the minerShares in it!
        if (payoutToken < minerShares) {
            revert ValidatorPoolErrors.PayoutTooLow();
        }
        payoutToken -= minerShares;
    }

    function _moveToExitingQueue(address validator_, uint256 stakeTokenID_) internal {
        if (_isValidator(validator_)) {
            _removeValidatorData(validator_);
        }
        _exitingValidatorsData[validator_] = ExitingValidatorData(
            uint128(stakeTokenID_),
            uint128(ISnapshots(_snapshotsAddress()).getEpoch() + CLAIM_PERIOD)
        );
    }

    function _removeValidatorData(address validator_) internal {
        _validators.remove(validator_);
        delete _ipLocations[validator_];
    }

    function _removeExitingQueueData(address validator_) internal {
        delete _exitingValidatorsData[validator_];
    }

    function _isValidator(address account_) internal view returns (bool) {
        return _validators.contains(account_);
    }

    function _isInExitingQueue(address account_) internal view returns (bool) {
        return _exitingValidatorsData[account_]._freeAfter > 0;
    }

    function _isAccusable(address account_) internal view returns (bool) {
        return _isValidator(account_) || _isInExitingQueue(account_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";

/// @custom:salt ValidatorStaking
/// @custom:deploy-type deployUpgradeable
contract ValidatorStaking is StakingNFT {
    constructor() StakingNFT() {}

    function initialize() public initializer onlyFactory {
        __stakingNFTInit("AVSNFT", "AVS");
    }

    /// mint allows a staking position to be opened. This function
    /// requires the caller to have performed an approve invocation against
    /// ALCA into this contract. This function will fail if the circuit
    /// breaker is tripped.
    function mint(
        uint256 amount_
    ) public override withCircuitBreaker onlyValidatorPool returns (uint256 tokenID) {
        return _mintNFT(msg.sender, amount_);
    }

    /// mintTo allows a staking position to be opened in the name of an
    /// account other than the caller. This method also allows a lock to be
    /// placed on the position up to _MAX_MINT_LOCK . This function requires the
    /// caller to have performed an approve invocation against ALCA into
    /// this contract. This function will fail if the circuit breaker is
    /// tripped.
    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) public override withCircuitBreaker onlyValidatorPool returns (uint256 tokenID) {
        if (lockDuration_ > _MAX_MINT_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanMintLock();
        }
        tokenID = _mintNFT(to_, amount_);
        if (lockDuration_ > 0) {
            _lockPosition(tokenID, lockDuration_);
        }
        return tokenID;
    }

    /// burn exits a staking position such that all accumulated value is
    /// transferred to the owner on burn.
    function burn(
        uint256 tokenID_
    ) public override onlyValidatorPool returns (uint256 payoutEth, uint256 payoutALCA) {
        return _burn(msg.sender, msg.sender, tokenID_);
    }

    /// burnTo exits a staking position such that all accumulated value
    /// is transferred to a specified account on burn
    function burnTo(
        address to_,
        uint256 tokenID_
    ) public override onlyValidatorPool returns (uint256 payoutEth, uint256 payoutALCA) {
        return _burn(msg.sender, to_, tokenID_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/AccusationsLibrary.sol";

import "contracts/libraries/parsers/RCertParserLibrary.sol";

contract AccusationsLibraryMock {
    function recoverSigner(
        bytes memory signature,
        bytes memory prefix,
        bytes memory message
    ) public pure returns (address) {
        return AccusationsLibrary.recoverSigner(signature, prefix, message);
    }

    function recoverMadNetSigner(
        bytes memory signature,
        bytes memory message
    ) public pure returns (address) {
        return AccusationsLibrary.recoverMadNetSigner(signature, message);
    }

    function computeUTXOID(bytes32 txHash, uint32 txIdx) public pure returns (bytes32) {
        return AccusationsLibrary.computeUTXOID(txHash, txIdx);
    }

    function recoverGroupSignature(
        bytes calldata bClaimsSigGroup_
    ) public pure returns (uint256[4] memory publicKey, uint256[2] memory signature) {
        (publicKey, signature) = RCertParserLibrary.extractSigGroup(bClaimsSigGroup_, 0);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

contract ALCABurnerMock is ImmutableALCA {
    constructor() ImmutableFactory(msg.sender) ImmutableALCA() {}

    function burn(address to, uint256 amount) public {
        IStakingToken(_alcaAddress()).externalBurn(to, amount);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

contract ALCAMinterMock is ImmutableALCA {
    constructor() ImmutableFactory(msg.sender) ImmutableALCA() {}

    function mint(address to, uint256 amount) public {
        IStakingToken(_alcaAddress()).externalMint(to, amount);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/libraries/errors/BridgePoolFactoryErrors.sol";
import "contracts/interfaces/IBridgePool.sol";
import "contracts/utils/BridgePoolAddressUtil.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract BridgePoolFactoryBaseERC777Mock is ImmutableFactory {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155,
        ERC777
    }
    enum PoolType {
        NATIVE,
        EXTERNAL
    }
    //chainid of layer 1 chain, 1 for ether mainnet
    uint256 internal immutable _chainID;
    bool public publicPoolDeploymentEnabled;
    address internal _implementation;
    mapping(string => address) internal _logicAddresses;
    //mapping of native and external pools to mapping of pool types to most recent version of logic
    mapping(PoolType => mapping(TokenType => uint16)) internal _logicVersionsDeployed;
    //existing pools
    mapping(address => bool) public poolExists;
    event BridgePoolCreated(address poolAddress, address token);

    modifier onlyFactoryOrPublicEnabled() {
        if (msg.sender != _factoryAddress() && !publicPoolDeploymentEnabled) {
            revert BridgePoolFactoryErrors.PublicPoolDeploymentTemporallyDisabled();
        }
        _;
    }

    constructor() ImmutableFactory(msg.sender) {
        _chainID = block.chainid;
    }

    function getNativePoolType() public pure returns (PoolType) {
        return PoolType.NATIVE;
    }

    // NativeERC20V!
    /**
     * @notice returns bytecode for a Minimal Proxy (EIP-1167) that routes to BridgePool implementation
     */
    // solhint-disable-next-line
    fallback() external {
        address implementation_ = _implementation;
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, shl(176, 0x363d3d373d3d3d363d73)) //10
            mstore(add(ptr, 10), shl(96, implementation_)) //20
            mstore(add(ptr, 30), shl(136, 0x5af43d82803e903d91602b57fd5bf3)) //15
            return(ptr, 45)
        }
    }

    /**
     * @notice returns the most recent version of the pool logic
     * @param chainId_ native chainID of the token ie 1 for ethereum erc20
     * @param tokenType_ type of token 0 for ERC20 1 for ERC721 and 2 for ERC1155
     */
    function getLatestPoolLogicVersion(
        uint256 chainId_,
        uint8 tokenType_
    ) public view returns (uint16) {
        if (chainId_ != _chainID) {
            return _logicVersionsDeployed[PoolType.EXTERNAL][TokenType(tokenType_)];
        } else {
            return _logicVersionsDeployed[PoolType.NATIVE][TokenType(tokenType_)];
        }
    }

    function _deployPoolLogic(
        uint8 tokenType_,
        uint256 chainId_,
        uint256 value_,
        bytes calldata deployCode_
    ) internal returns (address) {
        address addr;
        uint32 codeSize;
        bool native = true;
        uint16 version;
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, deployCode_.offset, deployCode_.length)
            addr := create(value_, ptr, deployCode_.length)
            codeSize := extcodesize(addr)
        }
        if (codeSize == 0) {
            revert BridgePoolFactoryErrors.FailedToDeployLogic();
        }
        if (chainId_ != _chainID) {
            native = false;
            version = _logicVersionsDeployed[PoolType.EXTERNAL][TokenType(tokenType_)] + 1;
            _logicVersionsDeployed[PoolType.EXTERNAL][TokenType(tokenType_)] = version;
        } else {
            version = _logicVersionsDeployed[PoolType.NATIVE][TokenType(tokenType_)] + 1;
            _logicVersionsDeployed[PoolType.NATIVE][TokenType(tokenType_)] = version;
        }
        _logicAddresses[_getImplementationAddressKey(tokenType_, version, native)] = addr;
        return addr;
    }

    /**
     * @dev enables or disables public pool deployment
     **/
    function _togglePublicPoolDeployment() internal {
        publicPoolDeploymentEnabled = !publicPoolDeploymentEnabled;
    }

    /**
     * @notice Deploys a new bridge to pass tokens to layer 2 chain from the specified ERC contract.
     * The pools are created as thin proxies (EIP1167) routing to versioned implementations identified by correspondent salt.
     * @param tokenType_ type of token (0=ERC20, 1=ERC721, 2=ERC1155)
     * @param ercContract_ address of ERC20 source token contract
     * @param poolVersion_ version of BridgePool implementation to use
     */
    function _deployNewNativePool(
        uint8 tokenType_,
        address ercContract_,
        uint16 poolVersion_
    ) internal {
        bool native = true;
        //calculate the unique salt for the bridge pool
        bytes32 bridgePoolSalt = BridgePoolAddressUtil.getBridgePoolSalt(
            ercContract_,
            tokenType_,
            _chainID,
            poolVersion_
        );
        //calculate the address of the pool's logic contract
        address implementation = _logicAddresses[
            _getImplementationAddressKey(tokenType_, poolVersion_, native)
        ];
        _implementation = implementation;
        //check if the logic exists for the specified pool
        uint256 implementationSize;
        assembly ("memory-safe") {
            implementationSize := extcodesize(implementation)
        }
        if (implementationSize == 0) {
            revert BridgePoolFactoryErrors.PoolVersionNotSupported(poolVersion_);
        }
        address contractAddr = _deployStaticPool(bridgePoolSalt);
        IBridgePool(contractAddr).initialize(ercContract_);
        emit BridgePoolCreated(contractAddr, ercContract_);
    }

    /**
     * @notice creates a BridgePool contract with specific salt and bytecode returned by this contract fallback
     * @param salt_ salt of the implementation contract
     * @return contractAddr the address of the BridgePool
     */
    function _deployStaticPool(bytes32 salt_) internal returns (address contractAddr) {
        uint256 contractSize;
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, shl(136, 0x5880818283335afa3d82833e3d82f3))
            contractAddr := create2(0, ptr, 15, salt_)
            contractSize := extcodesize(contractAddr)
        }
        if (contractSize == 0) {
            revert BridgePoolFactoryErrors.StaticPoolDeploymentFailed(salt_);
        }
        poolExists[contractAddr] = true;
        return contractAddr;
    }

    /**
     * @notice calculates salt for a BridgePool implementation contract based on tokenType and version
     * @param tokenType_ type of token (0=ERC20, 1=ERC721, 2=ERC1155)
     * @param version_ version of the implementation
     * @param native_ boolean flag to specifier native or external token pools
     * @return calculated key
     */
    function _getImplementationAddressKey(
        uint8 tokenType_,
        uint16 version_,
        bool native_
    ) internal pure returns (string memory) {
        string memory key;
        if (native_) {
            key = "Native";
        } else {
            key = "External";
        }
        if (tokenType_ == uint8(TokenType.ERC20)) {
            key = string.concat(key, "ERC20");
        } else if (tokenType_ == uint8(TokenType.ERC721)) {
            key = string.concat(key, "ERC721");
        } else if (tokenType_ == uint8(TokenType.ERC1155)) {
            key = string.concat(key, "ERC1155");
        } else if (tokenType_ == uint8(TokenType.ERC777)) {
            key = string.concat(key, "ERC777");
        }
        key = string.concat(key, "V", Strings.toString(version_));
        return key;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/BridgePoolFactoryErrors.sol";
import "test/contract-mocks/bridgePool/BridgePoolFactoryBaseERC777Mock.sol";

contract BridgePoolFactoryERC777Mock is BridgePoolFactoryBaseERC777Mock {
    constructor() BridgePoolFactoryBaseERC777Mock() {}

    /**
     * @notice Deploys a new bridge to pass tokens to our chain from the specified ERC contract.
     * The pools are created as thin proxies (EIP1167) routing to versioned implementations identified by corresponding salt.
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param ercContract_ address of ERC20 source token contract
     * @param implementationVersion_ version of BridgePool implementation to use
     */
    function deployNewNativePool(
        uint8 tokenType_,
        address ercContract_,
        uint16 implementationVersion_
    ) public onlyFactoryOrPublicEnabled {
        _deployNewNativePool(tokenType_, ercContract_, implementationVersion_);
    }

    /**
     * @notice deploys logic for bridge pools and stores it in a logicAddresses mapping
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param chainId_ address of ERC20 source token contract
     * @param value_ amount of eth to send to the contract on creation
     * @param deployCode_ logic contract deployment bytecode
     */
    function deployPoolLogic(
        uint8 tokenType_,
        uint256 chainId_,
        uint256 value_,
        bytes calldata deployCode_
    ) public onlyFactory returns (address) {
        return _deployPoolLogic(tokenType_, chainId_, value_, deployCode_);
    }

    /**
     * @dev enables or disables public pool deployment
     **/
    function togglePublicPoolDeployment() public onlyFactory {
        _togglePublicPoolDeployment();
    }

    /**
     * @notice calculates bridge pool address with associated bytes32 salt
     * @param bridgePoolSalt_ bytes32 salt associated with the pool, calculated with getBridgePoolSalt
     * @return poolAddress calculated calculated bridgePool Address
     */
    function lookupBridgePoolAddress(
        bytes32 bridgePoolSalt_
    ) public view returns (address poolAddress) {
        poolAddress = BridgePoolAddressUtil.getBridgePoolAddress(bridgePoolSalt_, address(this));
    }

    /**
     * @notice calculates salt for a BridgePool contract based on ERC contract's address, tokenType, chainID and version_
     * @param tokenContractAddr_ address of ERC Token contract
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param version_ version of the implementation
     * @param chainID_ chain ID
     * @return calculated calculated salt
     */
    function getBridgePoolSalt(
        address tokenContractAddr_,
        uint8 tokenType_,
        uint256 chainID_,
        uint16 version_
    ) public pure returns (bytes32) {
        return
            BridgePoolAddressUtil.getBridgePoolSalt(
                tokenContractAddr_,
                tokenType_,
                chainID_,
                version_
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("ERC20 Mock", "ERC20MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

contract BridgeRouterMock {
    uint256 internal immutable _fee;
    uint256 internal _dummy = 0;

    constructor(uint256 fee_) {
        _fee = fee_;
    }

    function routeDeposit(address account, bytes calldata data) external returns (uint256) {
        account = account;
        data = data;
        _dummy = 0;
        return _fee;
    }
}

contract CentralBridgeRouterMock {
    uint256 internal immutable _fee;
    uint256 internal _dummy = 0;

    constructor(uint256 fee_) {
        _fee = fee_;
    }

    function routeDeposit(
        address account,
        uint8 version,
        bytes calldata data
    ) external returns (uint256) {
        account = account;
        data = data;
        version = version;
        _dummy = 0;
        return _fee;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCB.sol";
import "contracts/interfaces/IUtilityToken.sol";
import "contracts/utils/MagicEthTransfer.sol";

contract ReentrantLoopDistributionMock is MagicEthTransfer, ImmutableFactory, ImmutableALCB {
    uint256 internal _counter;

    constructor() ImmutableFactory(msg.sender) ImmutableALCB() {}

    receive() external payable {
        _internalLoop();
    }

    function depositEth(uint8 magic_) public payable checkMagic(magic_) {
        _internalLoop();
    }

    function _internalLoop() internal {
        _counter++;
        if (_counter <= 3) {
            IUtilityToken(_alcbAddress()).distribute();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract TestUtils {
    receive() external payable {}

    function payUnpayable(address unpayable) public {
        selfdestruct(payable(unpayable));
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/utils/AtomicCounter.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IETHDKGEvents.sol";
import "contracts/libraries/ethdkg/ETHDKGStorage.sol";
import "contracts/utils/ETHDKGUtils.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableETHDKGAccusations.sol";
import "contracts/utils/auth/ImmutableETHDKGPhases.sol";
import "contracts/libraries/errors/ETHDKGErrors.sol";
import "contracts/libraries/proxy/ProxyImplementationGetter.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ETHDKGMock is
    ETHDKGStorage,
    IETHDKG,
    ETHDKGUtils,
    ImmutableETHDKGAccusations,
    ImmutableETHDKGPhases,
    IETHDKGEvents,
    ProxyImplementationGetter
{
    using Address for address;

    modifier onlyValidator() {
        if (!IValidatorPool(_validatorPoolAddress()).isValidator(msg.sender)) {
            revert ETHDKGErrors.OnlyValidatorsAllowed(msg.sender);
        }
        _;
    }

    constructor() ETHDKGStorage() ImmutableETHDKGAccusations() ImmutableETHDKGPhases() {}

    function minorSlash(address validator, address accussator) external {
        IValidatorPool(_validatorPoolAddress()).minorSlash(validator, accussator);
    }

    function majorSlash(address validator, address accussator) external {
        IValidatorPool(_validatorPoolAddress()).majorSlash(validator, accussator);
    }

    function setConsensusRunning() external {
        IValidatorPool(_validatorPoolAddress()).completeETHDKG();
    }

    function initialize(uint256 phaseLength_, uint256 confirmationLength_) public initializer {
        _phaseLength = uint16(phaseLength_);
        _confirmationLength = uint16(confirmationLength_);
    }

    function reinitialize(
        uint256 phaseLength_,
        uint256 confirmationLength_
    ) public reinitializer(2) {
        _phaseLength = uint16(phaseLength_);
        _confirmationLength = uint16(confirmationLength_);
    }

    function setPhaseLength(uint16 phaseLength_) public {
        if (_isETHDKGRunning()) {
            revert ETHDKGErrors.VariableNotSettableWhileETHDKGRunning();
        }
        _phaseLength = phaseLength_;
    }

    function setConfirmationLength(uint16 confirmationLength_) public {
        if (_isETHDKGRunning()) {
            revert ETHDKGErrors.VariableNotSettableWhileETHDKGRunning();
        }
        _confirmationLength = confirmationLength_;
    }

    function setCustomAliceNetHeight(uint256 aliceNetHeight) public {
        _customAliceNetHeight = aliceNetHeight;
        emit ValidatorSetCompleted(
            0,
            _nonce,
            ISnapshots(_snapshotsAddress()).getEpoch(),
            ISnapshots(_snapshotsAddress()).getCommittedHeightFromLatestSnapshot(),
            aliceNetHeight,
            0x0,
            0x0,
            0x0,
            0x0
        );
    }

    function initializeETHDKG() public {
        _initializeETHDKG();
    }

    function register(uint256[2] memory publicKey) public onlyValidator {
        _callPhaseContract(abi.encodeWithSignature("register(uint256[2])", publicKey));
    }

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature("accuseParticipantNotRegistered(address[])", dishonestAddresses)
        );
    }

    function distributeShares(
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments
    ) public onlyValidator {
        _callPhaseContract(
            abi.encodeWithSignature(
                "distributeShares(uint256[],uint256[2][])",
                encryptedShares,
                commitments
            )
        );
    }

    ///
    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotDistributeShares(address[])",
                dishonestAddresses
            )
        );
    }

    // Someone sent bad shares
    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) public onlyValidator {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDistributedBadShares(address,uint256[],uint256[2][],uint256[2],uint256[2])",
                dishonestAddress,
                encryptedShares,
                commitments,
                sharedKey,
                sharedKeyCorrectnessProof
            )
        );
    }

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) public onlyValidator {
        _callPhaseContract(
            abi.encodeWithSignature(
                "submitKeyShare(uint256[2],uint256[2],uint256[4])",
                keyShareG1,
                keyShareG1CorrectnessProof,
                keyShareG2
            )
        );
    }

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotSubmitKeyShares(address[])",
                dishonestAddresses
            )
        );
    }

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) public {
        _callPhaseContract(
            abi.encodeWithSignature("submitMasterPublicKey(uint256[4])", masterPublicKey_)
        );
    }

    function submitGPKJ(uint256[4] memory gpkj) public onlyValidator {
        _callPhaseContract(abi.encodeWithSignature("submitGPKJ(uint256[4])", gpkj));
    }

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotSubmitGPKJ(address[])",
                dishonestAddresses
            )
        );
    }

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) public onlyValidator {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantSubmittedBadGPKJ(address[],bytes32[],uint256[2][][],address)",
                validators,
                encryptedSharesHash,
                commitments,
                dishonestAddress
            )
        );
    }

    // Successful_Completion should be called at the completion of the DKG algorithm.
    function complete() public {
        _callPhaseContract(abi.encodeWithSignature("complete()"));
    }

    function setValidMasterPublicKey(bytes32 mpk_) public {
        _masterPublicKeyRegistry[mpk_] = true;
    }

    function isETHDKGRunning() public view returns (bool) {
        return _isETHDKGRunning();
    }

    function isETHDKGCompleted() public view returns (bool) {
        return _isETHDKGCompleted();
    }

    function isETHDKGHalted() public view returns (bool) {
        return _isETHDKGHalted();
    }

    function isMasterPublicKeySet() public view returns (bool) {
        return ((_masterPublicKey[0] != 0) ||
            (_masterPublicKey[1] != 0) ||
            (_masterPublicKey[2] != 0) ||
            (_masterPublicKey[3] != 0));
    }

    function isValidMasterPublicKey(bytes32 masterPublicKeyHash) public view returns (bool) {
        return _masterPublicKeyRegistry[masterPublicKeyHash];
    }

    function getNonce() public view returns (uint256) {
        return _nonce;
    }

    function getPhaseStartBlock() public view returns (uint256) {
        return _phaseStartBlock;
    }

    function getPhaseLength() public view returns (uint256) {
        return _phaseLength;
    }

    function getConfirmationLength() public view returns (uint256) {
        return _confirmationLength;
    }

    function getETHDKGPhase() public view returns (Phase) {
        return _ethdkgPhase;
    }

    function getNumParticipants() public view returns (uint256) {
        return _numParticipants;
    }

    function getBadParticipants() public view returns (uint256) {
        return _badParticipants;
    }

    function getParticipantInternalState(
        address participant
    ) public view returns (Participant memory) {
        return _participants[participant];
    }

    function getParticipantsInternalState(
        address[] calldata participantAddresses
    ) public view returns (Participant[] memory) {
        Participant[] memory participants = new Participant[](participantAddresses.length);

        for (uint256 i = 0; i < participantAddresses.length; i++) {
            participants[i] = _participants[participantAddresses[i]];
        }

        return participants;
    }

    function getLastRoundParticipantIndex(address participant) public view returns (uint256) {
        uint256 participantDataIndex = _participants[participant].index;
        uint256 participantDataNonce = _participants[participant].nonce;
        uint256 nonce = _nonce;
        if (nonce == 0 || participantDataNonce != nonce) {
            revert ETHDKGErrors.ParticipantNotFoundInLastRound(participant);
        }
        return participantDataIndex;
    }

    function getMasterPublicKey() public view returns (uint256[4] memory) {
        return _masterPublicKey;
    }

    function getMasterPublicKeyHash() public view returns (bytes32) {
        return _masterPublicKeyHash;
    }

    function migrateValidators(
        address[] memory validatorsAccounts_,
        uint256[] memory validatorIndexes_,
        uint256[4][] memory validatorShares_,
        uint8 validatorCount_,
        uint256 epoch_,
        uint256 sideChainHeight_,
        uint256 ethHeight_,
        uint256[4] memory masterPublicKey_
    ) public pure {
        validatorsAccounts_;
        validatorIndexes_;
        validatorShares_;
        validatorCount_;
        epoch_;
        sideChainHeight_;
        ethHeight_;
        masterPublicKey_;
    }

    function getMinValidators() public pure returns (uint256) {
        return _MIN_VALIDATORS;
    }

    function _callAccusationContract(bytes memory callData) internal returns (bytes memory) {
        return _getETHDKGAccusationsAddress().functionDelegateCall(callData);
    }

    function _callPhaseContract(bytes memory callData) internal returns (bytes memory) {
        return _getETHDKGPhasesAddress().functionDelegateCall(callData);
    }

    function _initializeETHDKG() internal {
        //todo: should we reward ppl here?
        uint256 numberValidators = IValidatorPool(_validatorPoolAddress()).getValidatorsCount();
        if (numberValidators < _MIN_VALIDATORS) {
            revert ETHDKGErrors.MinimumValidatorsNotMet(numberValidators);
        }

        _phaseStartBlock = uint64(block.number);
        _nonce++;
        _numParticipants = 0;
        _badParticipants = 0;
        _mpkG1 = [uint256(0), uint256(0)];
        _ethdkgPhase = Phase.RegistrationOpen;

        delete _masterPublicKey;

        emit RegistrationOpened(
            block.number,
            numberValidators,
            _nonce,
            _phaseLength,
            _confirmationLength
        );
    }

    function _getETHDKGPhasesAddress() internal view returns (address ethdkgPhases) {
        ethdkgPhases = __getProxyImplementation(_ethdkgPhasesAddress());
        if (!ethdkgPhases.isContract()) {
            revert ETHDKGErrors.ETHDKGSubContractNotSet();
        }
    }

    function _getETHDKGAccusationsAddress() internal view returns (address ethdkgAccusations) {
        ethdkgAccusations = __getProxyImplementation(_ethdkgAccusationsAddress());
        if (!ethdkgAccusations.isContract()) {
            revert ETHDKGErrors.ETHDKGSubContractNotSet();
        }
    }

    function _isETHDKGCompleted() internal view returns (bool) {
        return _ethdkgPhase == Phase.Completion;
    }

    function _isETHDKGRunning() internal view returns (bool) {
        // Handling initial case
        if (_phaseStartBlock == 0) {
            return false;
        }
        return !_isETHDKGCompleted() && !_isETHDKGHalted();
    }

    // todo: generate truth table
    function _isETHDKGHalted() internal view returns (bool) {
        bool ethdkgFailedInDisputePhase = (_ethdkgPhase == Phase.DisputeShareDistribution ||
            _ethdkgPhase == Phase.DisputeGPKJSubmission) &&
            block.number >= _phaseStartBlock + _phaseLength &&
            _badParticipants != 0;
        bool ethdkgFailedInNormalPhase = block.number >= _phaseStartBlock + 2 * _phaseLength;
        return ethdkgFailedInNormalPhase || ethdkgFailedInDisputePhase;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";

interface IMockBaseContract {
    function setV(uint256 _v) external;

    function lock() external;

    function unlock() external;

    function fail() external;

    function getVar() external view returns (uint256);

    function getImut() external view returns (uint256);
}

/// @custom:salt Mock
contract MockBaseContract is
    ProxyInternalUpgradeLock,
    ProxyInternalUpgradeUnlock,
    IMockBaseContract
{
    error Failed();
    address internal _factory;
    uint256 internal _var;
    uint256 internal immutable _imut;
    string internal _pString;

    constructor(uint256 imut_, string memory pString_) {
        _pString = pString_;
        _imut = imut_;
        _factory = msg.sender;
    }

    function payMe() public payable {}

    function setV(uint256 _v) public {
        _var = _v;
    }

    function lock() public {
        __lockImplementation();
    }

    function unlock() public {
        __unlockImplementation();
    }

    function setFactory(address factory_) public {
        _factory = factory_;
    }

    function getFactory() public view returns (address) {
        return _factory;
    }

    function getpString() public view returns (string memory) {
        return _pString;
    }

    function getImut() public view returns (uint256) {
        return _imut;
    }

    function getVar() public view returns (uint256) {
        return _var;
    }

    function fail() public pure {
        if (false != true) {
            revert Failed();
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMockEndPoint {
    function addOne() external;

    function addTwo() external;

    function factory() external returns (address);

    function i() external view returns (uint256);
}

/// @custom:salt MockEndPoint
contract MockEndPoint is IMockEndPoint {
    address public immutable factory;
    address public owner;
    uint256 public i;

    event AddedOne(uint256 indexed i);
    event AddedTwo(uint256 indexed i);
    event UpgradeLock(bool indexed lock);

    constructor() {
        factory = msg.sender;
    }

    function addOne() public {
        i++;
        emit AddedOne(i);
    }

    function addTwo() public {
        i = i + 2;
        emit AddedTwo(i);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/Proxy.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";
import "contracts/libraries/proxy/ProxyImplementationGetter.sol";

interface IMockEndPointLockable {
    function addOne() external;

    function addTwo() external;

    function factory() external returns (address);

    function i() external view returns (uint256);
}

/// @custom:salt MockEndPointLockable
contract MockEndPointLockable is
    ProxyInternalUpgradeLock,
    ProxyInternalUpgradeUnlock,
    ProxyImplementationGetter,
    IMockEndPointLockable
{
    error Unauthorized();
    address private immutable _factory;
    address public owner;
    uint256 public i;

    event AddedOne(uint256 indexed i);
    event AddedTwo(uint256 indexed i);
    event UpgradeLocked(bool indexed lock);
    event UpgradeUnlocked(bool indexed lock);

    modifier onlyOwner() {
        _requireAuth(msg.sender == owner);
        _;
    }

    constructor(address f) {
        _factory = f;
    }

    function addOne() public {
        i++;
        emit AddedOne(i);
    }

    function addTwo() public {
        i = i + 2;
        emit AddedTwo(i);
    }

    function poluteImplementationAddress() public {
        assembly ("memory-safe") {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                or(
                    0xbabeffff15deffffbabeffff0000000000000000000000000000000000000000,
                    sload(implSlot)
                )
            )
        }
    }

    function upgradeLock() public {
        __lockImplementation();
        emit UpgradeLocked(true);
    }

    function upgradeUnlock() public {
        __unlockImplementation();
        emit UpgradeUnlocked(false);
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function _requireAuth(bool isOk_) internal pure {
        if (!isOk_) {
            revert Unauthorized();
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/DeterministicAddress.sol";
import "contracts/libraries/proxy/ProxyUpgrader.sol";

contract MockFactory is DeterministicAddress, ProxyUpgrader {
    /**
    @dev owner role for priveledged access to functions
    */
    address private _owner;

    /**
    @dev delegator role for priveledged access to delegateCallAny
    */
    address private _delegator;

    /**
    @dev array to store list of contract salts
    */
    bytes32[] private _contracts;

    /**
    @dev slot for storing implementation address
    */
    address private _implementation;

    function setOwner(address new_) public {
        _owner = new_;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";

import "test/contract-mocks/factory/MockBaseContract.sol";

/// @custom:salt MockInitializable
contract MockInitializable is
    ProxyInternalUpgradeLock,
    ProxyInternalUpgradeUnlock,
    IMockBaseContract
{
    error ContractAlreadyInitialized();
    error ContractNotInitializing();
    error Failed();
    address internal _factory;
    uint256 internal _var;
    uint256 internal _imut;
    address public immutable factoryAddress = 0x0BBf39118fF9dAfDC8407c507068D47572623069;
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        if (_initializing ? !_isConstructor() : _initialized) {
            revert ContractAlreadyInitialized();
        }

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (!_initializing) {
            revert ContractNotInitializing();
        }
        _;
    }

    function getFactory() external view returns (address) {
        return _factory;
    }

    function initialize(uint256 i_) public virtual initializer {
        __mockInit(i_);
    }

    function setFactory(address factory_) public {
        _factory = factory_;
    }

    function setV(uint256 _v) public {
        _var = _v;
    }

    function lock() public {
        __lockImplementation();
    }

    function unlock() public {
        __unlockImplementation();
    }

    function getVar() public view returns (uint256) {
        return _var;
    }

    function getImut() public view returns (uint256) {
        return _imut;
    }

    function fail() public pure {
        if (false != true) {
            revert Failed();
        }
    }

    function __mockInit(uint256 i_) internal onlyInitializing {
        __mockInitUnchained(i_);
    }

    function __mockInitUnchained(uint256 i_) internal onlyInitializing {
        _imut = i_;
        _factory = msg.sender;
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function _isConstructor() private view returns (bool) {
        return !_isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "test/contract-mocks/factory/MockInitializable.sol";

/// @custom:salt MockInitializableConstructable
contract MockInitializableConstructable is MockInitializable {
    uint256 public immutable constructorValue;

    constructor(uint256 _constructorValue) {
        constructorValue = _constructorValue;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";

/// @custom:salt MockSelfDestruct
contract MockSelfDestruct is ProxyInternalUpgradeLock, ProxyInternalUpgradeUnlock {
    address internal _factory;
    uint256 public v;
    uint256 public immutable i;

    constructor(uint256 _i, bytes memory) {
        i = _i;
        _factory = msg.sender;
    }

    function getFactory() external view returns (address) {
        return _factory;
    }

    function setV(uint256 _v) public {
        v = _v;
    }

    function lock() public {
        __lockImplementation();
    }

    function unlock() public {
        __unlockImplementation();
    }

    function setFactory(address factory_) public {
        _factory = factory_;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

/// @custom:salt MockWithConstructor
contract MockWithConstructor {
    uint256 public immutable constructorValue;

    constructor(uint256 _constructorValue) {
        constructorValue = _constructorValue;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/utils/Admin.sol";

contract LegacyToken is ERC20, Admin {
    constructor() ERC20("LegacyToken", "LT") Admin(msg.sender) {
        _mint(msg.sender, 320000000 * 10 ** decimals());
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/libraries/parsers/RCertParserLibrary.sol";

contract CryptoLibraryWrapper {
    function validateSignature(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public view returns (bool, uint256) {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        uint256 gasBefore = gasleft();
        return (
            CryptoLibrary.verifySignature(
                abi.encodePacked(keccak256(bClaims_)),
                signature,
                masterPublicKey
            ),
            gasBefore - gasleft()
        );
    }

    function validateSignatureASM(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public view returns (bool, uint256) {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        uint256 gasBefore = gasleft();
        return (
            CryptoLibrary.verifySignatureASM(
                abi.encodePacked(keccak256(bClaims_)),
                signature,
                masterPublicKey
            ),
            gasBefore - gasleft()
        );
    }

    function validateBadSignatureASM(
        bytes calldata groupSignature_,
        bytes calldata bClaims_,
        uint256 salt
    ) public view returns (bool, uint256) {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        uint256 gasBefore = gasleft();
        return (
            CryptoLibrary.verifySignatureASM(
                abi.encodePacked(keccak256(abi.encodePacked(bClaims_, salt))),
                signature,
                masterPublicKey
            ),
            gasBefore - gasleft()
        );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/math/Sigmoid.sol";

contract MockSigmoid is Sigmoid {
    function p(uint256 x) public pure returns (uint256) {
        return Sigmoid._p(x);
    }

    function pInverse(uint256 x) public pure returns (uint256) {
        return Sigmoid._pInverse(x);
    }

    function safeAbsSub(uint256 a, uint256 b) public pure returns (uint256) {
        return Sigmoid._safeAbsSub(a, b);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return Sigmoid._min(a, b);
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return Sigmoid._max(a, b);
    }

    function sqrt(uint256 x) public pure returns (uint256) {
        return Sigmoid._sqrt(x);
    }

    function pConstA() public pure returns (uint256) {
        return Sigmoid._P_A;
    }

    function pConstB() public pure returns (uint256) {
        return Sigmoid._P_B;
    }

    function pConstC() public pure returns (uint256) {
        return Sigmoid._P_C;
    }

    function pConstD() public pure returns (uint256) {
        return Sigmoid._P_D;
    }

    function pConstS() public pure returns (uint256) {
        return Sigmoid._P_S;
    }

    function pInverseConstC1() public pure returns (uint256) {
        return Sigmoid._P_INV_C_1;
    }

    function pInverseConstC2() public pure returns (uint256) {
        return Sigmoid._P_INV_C_2;
    }

    function pInverseConstC3() public pure returns (uint256) {
        return Sigmoid._P_INV_C_3;
    }

    function pInverseConstD0() public pure returns (uint256) {
        return Sigmoid._P_INV_D_0;
    }

    function pInverseConstD1() public pure returns (uint256) {
        return Sigmoid._P_INV_D_1;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/metadata/StakingDescriptor.sol";

contract StakingDescriptorMock {
    function constructTokenURI(
        StakingDescriptor.ConstructTokenURIParams memory params
    ) public pure returns (string memory) {
        return StakingDescriptor.constructTokenURI(params);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/metadata/StakingSVG.sol";

contract StakingSVGMock {
    function generateSVG(
        StakingSVG.StakingSVGParams memory svgParams
    ) public pure returns (string memory svg) {
        return StakingSVG.generateSVG(svgParams);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/PublicStaking.sol";
import "contracts/ALCA.sol";

abstract contract BaseMock {
    PublicStaking public publicStaking;
    ALCA public alca;

    receive() external payable virtual {}

    function setTokens(ALCA alca_, PublicStaking stakeNFT_) public {
        publicStaking = stakeNFT_;
        alca = alca_;
    }

    function mint(uint256 amount_) public returns (uint256) {
        return publicStaking.mint(amount_);
    }

    function mintTo(address to_, uint256 amount_, uint256 duration_) public returns (uint256) {
        return publicStaking.mintTo(to_, amount_, duration_);
    }

    function burn(uint256 tokenID) public returns (uint256, uint256) {
        return publicStaking.burn(tokenID);
    }

    function burnTo(address to_, uint256 tokenID) public returns (uint256, uint256) {
        return publicStaking.burnTo(to_, tokenID);
    }

    function approve(address who, uint256 amount_) public returns (bool) {
        return alca.approve(who, amount_);
    }

    function depositToken(uint256 amount_) public {
        publicStaking.depositToken(42, amount_);
    }

    function depositEth(uint256 amount_) public {
        publicStaking.depositEth{value: amount_}(42);
    }

    function collectToken(uint256 tokenID_) public returns (uint256 payout) {
        return publicStaking.collectToken(tokenID_);
    }

    function collectEth(uint256 tokenID_) public returns (uint256 payout) {
        return publicStaking.collectEth(tokenID_);
    }

    function approveNFT(address to, uint256 tokenID_) public {
        return publicStaking.approve(to, tokenID_);
    }

    function setApprovalForAll(address to, bool approve_) public {
        return publicStaking.setApprovalForAll(to, approve_);
    }

    function transferFrom(address from, address to, uint256 tokenID_) public {
        return publicStaking.transferFrom(from, to, tokenID_);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID_,
        bytes calldata data
    ) public {
        return publicStaking.safeTransferFrom(from, to, tokenID_, data);
    }

    function lockWithdraw(uint256 tokenID, uint256 lockDuration) public returns (uint256) {
        return publicStaking.lockWithdraw(tokenID, lockDuration);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "test/contract-mocks/publicStaking/BaseMock.sol";
import "contracts/libraries/StakingNFT/StakingNFT.sol";

contract HugeAccumulatorStaking is StakingNFT {
    uint256 public constant OFFSET_TO_OVERFLOW = 1_000000000000000000;

    constructor() StakingNFT() {}

    function initialize() public onlyFactory initializer {
        __stakingNFTInit("HugeAccumulator", "APS");
        _tokenState.accumulator = uint256(type(uint168).max - OFFSET_TO_OVERFLOW);
        _ethState.accumulator = uint256(type(uint168).max - OFFSET_TO_OVERFLOW);
    }

    function getOffsetToOverflow() public pure returns (uint256) {
        return OFFSET_TO_OVERFLOW;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "test/contract-mocks/publicStaking/BaseMock.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ReentrantLoopEthCollectorAccount is BaseMock {
    uint256 internal _tokenID;

    constructor() {}

    receive() external payable virtual override {
        collectEth(_tokenID);
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ReentrantFiniteEthCollectorAccount is BaseMock {
    uint256 internal _tokenID;
    uint256 internal _count = 0;

    constructor() {}

    receive() external payable virtual override {
        if (_count < 2) {
            _count++;
            collectEth(_tokenID);
        } else {
            return;
        }
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ReentrantLoopBurnAccount is BaseMock {
    uint256 internal _tokenID;

    constructor() {}

    receive() external payable virtual override {
        burn(_tokenID);
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ReentrantFiniteBurnAccount is BaseMock {
    uint256 internal _tokenID;
    uint256 internal _count = 0;

    constructor() {}

    receive() external payable virtual override {
        if (_count < 2) {
            _count++;
            burn(_tokenID);
        } else {
            return;
        }
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ERC721ReceiverAccount is BaseMock, IERC721Receiver {
    constructor() {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract ReentrantLoopBurnERC721ReceiverAccount is BaseMock, IERC721Receiver {
    uint256 internal _tokenId;

    constructor() {}

    receive() external payable virtual override {
        publicStaking.burn(_tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        data;
        _tokenId = tokenId;
        publicStaking.burn(tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract ReentrantFiniteBurnERC721ReceiverAccount is BaseMock, IERC721Receiver {
    uint256 internal _tokenId;
    uint256 internal _count = 0;

    constructor() {}

    receive() external payable virtual override {
        publicStaking.burn(_tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        if (_count < 2) {
            _count++;
            _tokenId = tokenId;
            publicStaking.burn(tokenId);
        }

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract ReentrantLoopCollectEthERC721ReceiverAccount is BaseMock, IERC721Receiver {
    uint256 internal _tokenId;

    constructor() {}

    receive() external payable virtual override {
        publicStaking.collectEth(_tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        data;
        _tokenId = tokenId;
        publicStaking.collectEth(tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IStakingToken.sol";
import "contracts/interfaces/IUtilityToken.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/libraries/errors/RegisterValidatorErrors.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/auth/ImmutableALCB.sol";
import "contracts/utils/auth/ImmutableALCAMinter.sol";

contract ExternalStoreRegistration is ImmutableFactory {
    uint256 internal _counter;
    uint256[] internal _tokenIDs;

    constructor(address factory_) ImmutableFactory(factory_) {}

    function storeTokenIds(uint256[] memory tokenIDs) public onlyFactory {
        _tokenIDs = tokenIDs;
    }

    function incrementCounter() public onlyFactory {
        _counter++;
    }

    function getTokenIds() public view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](_tokenIDs.length);
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            ret[i] = _tokenIDs[i];
        }
        return ret;
    }

    function getCounter() public view returns (uint256) {
        return _counter;
    }

    function getTokenIDsLength() public view returns (uint256) {
        return _tokenIDs.length;
    }
}

contract RegisterValidators is
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutableALCA,
    ImmutableALCAMinter,
    ImmutableALCB,
    ImmutablePublicStaking,
    ImmutableValidatorPool
{
    uint256 public constant EPOCH_LENGTH = 1024;
    ExternalStoreRegistration internal immutable _externalStore;

    constructor(
        address factory_
    )
        ImmutableFactory(factory_)
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutableALCA()
        ImmutableALCB()
        ImmutableALCAMinter()
        ImmutablePublicStaking()
        ImmutableValidatorPool()
    {
        _externalStore = new ExternalStoreRegistration(factory_);
    }

    function stakeValidators(uint256 numValidators) public {
        // Setting staking amount
        IValidatorPool(_validatorPoolAddress()).setStakeAmount(1);
        // Minting 4 alcasWei to stake the validators
        IStakingTokenMinter(_alcaMinterAddress()).mint(_factoryAddress(), numValidators);
        IERC20Transferable(_alcaAddress()).approve(_publicStakingAddress(), numValidators);
        uint256[] memory tokenIDs = new uint256[](numValidators);
        for (uint256 i; i < numValidators; i++) {
            // minting publicStaking position for the factory
            tokenIDs[i] = IStakingNFT(_publicStakingAddress()).mint(1);
            IERC721(_publicStakingAddress()).approve(_validatorPoolAddress(), tokenIDs[i]);
        }
        _externalStore.storeTokenIds(tokenIDs);
    }

    function registerValidators(address[] calldata validatorsAccounts_) public {
        if (validatorsAccounts_.length != _externalStore.getTokenIDsLength()) {
            revert RegisterValidatorErrors.InvalidNumberOfValidators(
                validatorsAccounts_.length,
                _externalStore.getTokenIDsLength()
            );
        }
        uint256[] memory tokenIDs = _externalStore.getTokenIds();
        ////////////// Registering validators /////////////////////////
        IValidatorPool(_validatorPoolAddress()).registerValidators(validatorsAccounts_, tokenIDs);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/snapshots/SnapshotRingBuffer.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";

contract SnapshotsRingBufferMock is SnapshotRingBuffer {
    using EpochLib for Epoch;
    using RingBuffer for SnapshotBuffer;
    uint256 internal constant _EPOCH_LENGTH = 1024;
    //epoch counter wrapped in a struct
    Epoch internal _epoch;
    //new snapshot ring buffer
    SnapshotBuffer internal _snapshots;

    function setSnapshot(bytes calldata bClaims_) public returns (uint32) {
        BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.extractBClaims(
            bClaims_
        );
        return _setSnapshot(Snapshot(block.number, blockClaims));
    }

    function setEpoch(uint32 epoch_) public {
        _epoch.set(epoch_);
    }

    function getEpoch() public view returns (uint32) {
        return _epoch.get();
    }

    function getSnapshot(uint32 epoch_) public view returns (Snapshot memory) {
        return _getSnapshot(epoch_);
    }

    function getLatestSnapshot() public view returns (Snapshot memory) {
        return _getLatestSnapshot();
    }

    function getSnapshots() public view returns (SnapshotBuffer memory) {
        return _getSnapshots();
    }

    function getEpochRegister() public view returns (Epoch memory) {
        return _epochRegister();
    }

    function _getSnapshots() internal view override returns (SnapshotBuffer storage) {
        return _snapshots;
    }

    function _epochRegister() internal view override returns (Epoch storage) {
        return _epoch;
    }

    function _getEpochFromHeight(uint32 height_) internal pure override returns (uint32) {
        if (height_ <= _EPOCH_LENGTH) {
            return 1;
        }
        if (height_ % _EPOCH_LENGTH == 0) {
            return uint32(height_ / _EPOCH_LENGTH);
        }
        return uint32((height_ / _EPOCH_LENGTH) + 1);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/auth/ImmutableDynamics.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IDynamics.sol";

contract SnapshotsMock is Initializable, ImmutableValidatorPool, ISnapshots, ImmutableDynamics {
    error onlyAdminAllowed();
    uint32 internal _epoch;
    uint32 internal _epochLength;

    // after how many eth blocks of not having a snapshot will we start allowing more validators to
    // make it
    uint32 internal _snapshotDesperationDelay;
    // how quickly more validators will be allowed to make a snapshot, once
    // _snapshotDesperationDelay has passed
    uint32 internal _snapshotDesperationFactor;

    mapping(uint256 => Snapshot) internal _snapshots;

    address internal _admin;
    uint256 internal immutable _chainId;
    uint256 internal _minimumIntervalBetweenSnapshots;

    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert onlyAdminAllowed();
        }
        _;
    }

    constructor(
        uint32 chainID_,
        uint32 epochLength_
    ) ImmutableFactory(msg.sender) ImmutableValidatorPool() {
        _admin = msg.sender;
        _chainId = chainID_;
        _epochLength = epochLength_;
    }

    function initialize(uint32 desperationDelay_, uint32 desperationFactor_) public initializer {
        // considering that in optimum conditions 1 Sidechain block is at every 3 seconds and 1 block at
        // ethereum is approx at 13 seconds
        _minimumIntervalBetweenSnapshots = 0;
        _snapshotDesperationDelay = desperationDelay_;
        _snapshotDesperationFactor = desperationFactor_;
    }

    function setEpochLength(uint32 epochLength_) public {
        _epochLength = epochLength_;
    }

    function setSnapshotDesperationDelay(uint32 desperationDelay_) public onlyAdmin {
        _snapshotDesperationDelay = desperationDelay_;
    }

    function setSnapshotDesperationFactor(uint32 desperationFactor_) public onlyAdmin {
        _snapshotDesperationFactor = desperationFactor_;
    }

    function setMinimumIntervalBetweenSnapshots(uint32 minimumIntervalBetweenSnapshots_) public {
        _minimumIntervalBetweenSnapshots = minimumIntervalBetweenSnapshots_;
    }

    function snapshot(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public returns (bool) {
        bool isSafeToProceedConsensus = true;
        if (IValidatorPool(_validatorPoolAddress()).isMaintenanceScheduled()) {
            isSafeToProceedConsensus = false;
            IValidatorPool(_validatorPoolAddress()).pauseConsensus();
        }
        // dummy to silence compiling warnings
        groupSignature_;
        bClaims_;
        BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.BClaims(
            0,
            0,
            0,
            0x00,
            0x00,
            0x00,
            0x00
        );
        _epoch++;
        _snapshots[_epoch] = Snapshot(block.number, blockClaims);
        IDynamics(_dynamicsAddress()).updateHead(_epoch);

        return true;
    }

    function snapshotWithValidData(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public returns (bool) {
        bool isSafeToProceedConsensus = true;
        if (IValidatorPool(_validatorPoolAddress()).isMaintenanceScheduled()) {
            isSafeToProceedConsensus = false;
            IValidatorPool(_validatorPoolAddress()).pauseConsensus();
        }
        groupSignature_;
        BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.extractBClaims(
            bClaims_
        );

        _epoch++;
        _snapshots[_epoch] = Snapshot(block.number, blockClaims);
        IDynamics(_dynamicsAddress()).updateHead(_epoch);

        return true;
    }

    function setCommittedHeightFromLatestSnapshot(uint256 height_) public returns (uint256) {
        _snapshots[_epoch].committedAt = height_;
        return height_;
    }

    function getEpochFromHeight(uint256 height) public view returns (uint256) {
        if (height <= _epochLength) {
            return 1;
        }
        if (height % _epochLength == 0) {
            return height / _epochLength;
        }
        return (height / _epochLength) + 1;
    }

    function getSnapshotDesperationDelay() public view returns (uint256) {
        return _snapshotDesperationDelay;
    }

    function getSnapshotDesperationFactor() public view returns (uint256) {
        return _snapshotDesperationFactor;
    }

    function getMinimumIntervalBetweenSnapshots() public view returns (uint256) {
        return _minimumIntervalBetweenSnapshots;
    }

    function getChainId() public view returns (uint256) {
        return _chainId;
    }

    function getEpoch() public view returns (uint256) {
        return _epoch;
    }

    function getEpochLength() public view returns (uint256) {
        return _epochLength;
    }

    function getChainIdFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].blockClaims.chainId;
    }

    function getChainIdFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].blockClaims.chainId;
    }

    function getBlockClaimsFromSnapshot(
        uint256 epoch_
    ) public view returns (BClaimsParserLibrary.BClaims memory) {
        return _snapshots[epoch_].blockClaims;
    }

    function getBlockClaimsFromLatestSnapshot()
        public
        view
        returns (BClaimsParserLibrary.BClaims memory)
    {
        return _snapshots[_epoch].blockClaims;
    }

    function getCommittedHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].committedAt;
    }

    function getCommittedHeightFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].committedAt;
    }

    function getAliceNetHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].blockClaims.height;
    }

    function getAliceNetHeightFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].blockClaims.height;
    }

    function getSnapshot(uint256 epoch_) public view returns (Snapshot memory) {
        return _snapshots[epoch_];
    }

    function getLatestSnapshot() public view returns (Snapshot memory) {
        return _snapshots[_epoch];
    }

    function isMock() public pure returns (bool) {
        return true;
    }

    function migrateSnapshots(
        bytes[] memory groupSignature_,
        bytes[] memory bClaims_
    ) public pure returns (bool) {
        groupSignature_;
        bClaims_;
        return true;
    }

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 blsig,
        uint256 desperationFactor
    ) public pure returns (bool) {
        numValidators;
        myIdx;
        blocksSinceDesperation;
        blsig;
        desperationFactor;
        return true;
    }

    function checkBClaimsSignature(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public pure returns (bool) {
        groupSignature_;
        bClaims_;
        return true;
    }

    function isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) public pure returns (bool) {
        validator;
        lastSnapshotCommittedAt;
        groupSignatureHash;
        return true;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";
import "contracts/libraries/StakingNFT/StakingNFTStorage.sol";
import "contracts/libraries/governance/GovernanceMaxLock.sol";

contract MockStakingNFT is StakingNFT {
    uint256 internal _dummy = 0;

    function mintMock(uint256 amount_) public returns (uint256) {
        return StakingNFT.mint(amount_);
    }

    function mintToMock(address to_, uint256 amount_, uint256 duration_) public returns (uint256) {
        return StakingNFT.mintTo(to_, amount_, duration_);
    }

    function mintNFTMock(address to_, uint256 amount_) public returns (uint256) {
        return StakingNFT._mintNFT(to_, amount_);
    }

    function burnMock(uint256 tokenID_) public returns (uint256, uint256) {
        return StakingNFT.burn(tokenID_);
    }

    function burnToMock(address to_, uint256 tokenID_) public returns (uint256, uint256) {
        return StakingNFT.burnTo(to_, tokenID_);
    }

    function burnNFTMock(
        address from_,
        address to_,
        uint256 tokenID_
    ) public returns (uint256, uint256) {
        return StakingNFT._burn(from_, to_, tokenID_);
    }

    function collectEthMock(uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectEth(tokenID_);
    }

    function collectEthToMock(address to_, uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectEthTo(to_, tokenID_);
    }

    function collectTokenMock(uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectToken(tokenID_);
    }

    function collectTokenToMock(address to_, uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectTokenTo(to_, tokenID_);
    }

    function depositEthMock(uint8 magic) public payable {
        StakingNFT.depositEth(magic);
    }

    function lockPositionMock(
        address caller_,
        uint256 tokenID_,
        uint256 duration_
    ) public returns (uint256) {
        return StakingNFT.lockPosition(caller_, tokenID_, duration_);
    }

    function lockOwnPositionMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT.lockOwnPosition(tokenID_, duration_);
    }

    function lockPositionLowMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT._lockPosition(tokenID_, duration_);
    }

    function lockWithdrawMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT.lockWithdraw(tokenID_, duration_);
    }

    function lockWithdrawLowMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT._lockWithdraw(tokenID_, duration_);
    }

    function depositTokenMock(uint8 magic, uint256 amount) public {
        StakingNFT.depositToken(magic, amount);
    }

    function tripCBMock() public {
        StakingNFT.tripCB();
    }

    function tripCBLowMock() public {
        _tripCB();
    }

    function resetCBLowMock() public {
        _resetCB();
    }

    function skimExcessEthMock(address to_) public returns (uint256) {
        return StakingNFT.skimExcessEth(to_);
    }

    function skimExcessTokenMock(address to_) public returns (uint256) {
        return StakingNFT.skimExcessToken(to_);
    }

    function incrementMock() public returns (uint256) {
        _dummy = 0;
        return _increment();
    }

    function collectMock(
        uint256 shares_,
        Accumulator memory state_,
        Position memory p_,
        uint256 positionAccumulatorValue_
    ) public returns (Accumulator memory, Position memory, uint256, uint256) {
        _dummy = 0;
        return StakingNFT._calculateCollection(shares_, state_, p_, positionAccumulatorValue_);
    }

    function depositMock(
        uint256 delta_,
        Accumulator memory state_
    ) public returns (Accumulator memory) {
        _dummy = 0;
        return StakingNFT._deposit(delta_, state_);
    }

    function slushSkimMock(
        uint256 shares_,
        uint256 accumulator_,
        uint256 slush_
    ) public returns (uint256, uint256) {
        _dummy = 0;
        return StakingNFT._slushSkim(shares_, accumulator_, slush_);
    }

    function getTotalSharesMock() public view returns (uint256) {
        return StakingNFT.getTotalShares();
    }

    function getTotalReserveEthMock() public view returns (uint256) {
        return StakingNFT.getTotalReserveEth();
    }

    function getTotalReserveALCAMock() public view returns (uint256) {
        return StakingNFT.getTotalReserveALCA();
    }

    function estimateEthCollectionMock(uint256 tokenID_) public view returns (uint256) {
        return StakingNFT.estimateEthCollection(tokenID_);
    }

    function estimateTokenCollectionMock(uint256 tokenID_) public view returns (uint256) {
        return StakingNFT.estimateTokenCollection(tokenID_);
    }

    function estimateExcessEthMock() public view returns (uint256) {
        return StakingNFT.estimateExcessEth();
    }

    function estimateExcessTokenMock() public view returns (uint256) {
        return StakingNFT.estimateExcessToken();
    }

    function getPositionMock(
        uint256 tokenID_
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        return StakingNFT.getPosition(tokenID_);
    }

    function tokenURIMock(uint256 tokenID_) public view returns (string memory) {
        return StakingNFT.tokenURI(tokenID_);
    }

    function circuitBreakerStateMock() public view returns (bool) {
        return circuitBreakerState();
    }

    function getCountMock() public view returns (uint256) {
        return _getCount();
    }

    function getAccumulatorScaleFactorMock() public pure returns (uint256) {
        return StakingNFT.getAccumulatorScaleFactor();
    }

    function getMaxMintLockMock() public pure returns (uint256) {
        return StakingNFT.getMaxMintLock();
    }

    function collectPure(
        uint256 shares_,
        Accumulator memory state_,
        Position memory p_,
        uint256 positionAccumulatorValue_
    ) public pure returns (Accumulator memory, Position memory, uint256, uint256) {
        return StakingNFT._calculateCollection(shares_, state_, p_, positionAccumulatorValue_);
    }

    function depositPure(
        uint256 delta_,
        Accumulator memory state_
    ) public pure returns (Accumulator memory) {
        return StakingNFT._deposit(delta_, state_);
    }

    function slushSkimPure(
        uint256 shares_,
        uint256 accumulator_,
        uint256 slush_
    ) public pure returns (uint256, uint256) {
        return StakingNFT._slushSkim(shares_, accumulator_, slush_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Minter {
    constructor(address payable addr) payable {
        uint256 gl = gasleft();
        while (gl > 801010) {
            FooToken(addr).mint{gas: 801010}(msg.sender);
            gl = gasleft();
        }
    }
}

contract FooToken is ERC20("foo", "f") {
    function mint(address to) public payable {
        _mint(to, 1);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/parsers/MerkleProofParserLibrary.sol";
import "contracts/utils/MerkleProofLibrary.sol";

contract MockMerkleProofLibrary {
    function computeLeafHash(
        bytes32 key,
        bytes32 value,
        uint16 proofHeight
    ) public pure returns (bytes32) {
        return MerkleProofLibrary.computeLeafHash(key, value, proofHeight);
    }

    function verifyInclusion(
        MerkleProofParserLibrary.MerkleProof memory _proof,
        bytes32 root
    ) public pure {
        MerkleProofLibrary.verifyInclusion(_proof, root);
    }

    function verifyNonInclusion(
        MerkleProofParserLibrary.MerkleProof memory _proof,
        bytes32 root
    ) public pure {
        MerkleProofLibrary.verifyNonInclusion(_proof, root);
    }

    function checkProof(
        bytes memory auditPath,
        bytes32 root,
        bytes32 keyHash,
        bytes32 key,
        bytes memory bitmap,
        uint16 proofHeight
    ) public pure returns (bool) {
        return MerkleProofLibrary.checkProof(auditPath, root, keyHash, key, bitmap, proofHeight);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/utils/CustomEnumerableMaps.sol";
import "contracts/utils/DeterministicAddress.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/libraries/errors/ValidatorPoolErrors.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

contract ValidatorPoolMock is
    Initializable,
    IValidatorPool,
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutableValidatorStaking,
    ImmutableALCA
{
    using CustomEnumerableMaps for ValidatorDataMap;
    error OnlyAdminAllowed();

    uint256 public constant POSITION_LOCK_PERIOD = 3; // Actual is 172800

    uint256 internal _maxIntervalWithoutSnapshots = 0; // Actual is 8192

    uint256 internal _tokenIDCounter;
    //IETHDKG immutable internal _ethdkg;
    //ISnapshots immutable internal _snapshots;

    ValidatorDataMap internal _validators;

    address internal _admin;

    bool internal _isMaintenanceScheduled;
    bool internal _isConsensusRunning;

    uint256 internal _stakeAmount;

    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert OnlyAdminAllowed();
        }
        _;
    }

    // solhint-disable no-empty-blocks
    constructor()
        ImmutableFactory(msg.sender)
        ImmutableValidatorStaking()
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutableALCA()
    {}

    function initialize() public onlyFactory initializer {
        //20000*10**18 ALCAWei = 20k ALCAs
        _stakeAmount = 20000 * 10 ** 18;
    }

    function initializeETHDKG() public {
        IETHDKG(_ethdkgAddress()).initializeETHDKG();
    }

    function setDisputerReward(uint256 disputerReward_) public {}

    function pauseConsensusOnArbitraryHeight(uint256 aliceNetHeight_) public onlyFactory {
        uint256 targetBlockNumber = ISnapshots(_snapshotsAddress())
            .getCommittedHeightFromLatestSnapshot() + _maxIntervalWithoutSnapshots;
        if (block.number <= targetBlockNumber) {
            revert ValidatorPoolErrors.MinimumBlockIntervalNotMet(block.number, targetBlockNumber);
        }
        _isConsensusRunning = false;
        IETHDKG(_ethdkgAddress()).setCustomAliceNetHeight(aliceNetHeight_);
    }

    function mintValidatorStaking() public returns (uint256 stakeID_) {
        IERC20Transferable(_alcaAddress()).transferFrom(msg.sender, address(this), _stakeAmount);
        IERC20Transferable(_alcaAddress()).approve(_validatorStakingAddress(), _stakeAmount);
        stakeID_ = IStakingNFT(_validatorStakingAddress()).mint(_stakeAmount);
    }

    function burnValidatorStaking(
        uint256 tokenID_
    ) public returns (uint256 payoutEth, uint256 payoutALCA) {
        return IStakingNFT(_validatorStakingAddress()).burn(tokenID_);
    }

    function mintToValidatorStaking(address to_) public returns (uint256 stakeID_) {
        IERC20Transferable(_alcaAddress()).transferFrom(msg.sender, address(this), _stakeAmount);
        IERC20Transferable(_alcaAddress()).approve(_validatorStakingAddress(), _stakeAmount);
        stakeID_ = IStakingNFT(_validatorStakingAddress()).mintTo(to_, _stakeAmount, 1);
    }

    function burnToValidatorStaking(
        uint256 tokenID_,
        address to_
    ) public returns (uint256 payoutEth, uint256 payoutALCA) {
        return IStakingNFT(_validatorStakingAddress()).burnTo(to_, tokenID_);
    }

    function minorSlash(address validator, address disputer) public {
        disputer; //no-op to suppress warning of not using disputer address
        _removeValidator(validator);
    }

    function majorSlash(address validator, address disputer) public {
        disputer; //no-op to suppress warning of not using disputer address
        _removeValidator(validator);
    }

    function unregisterValidators(address[] memory validators) public {
        for (uint256 idx; idx < validators.length; idx++) {
            _removeValidator(validators[idx]);
        }
    }

    function unregisterAllValidators() public {
        while (_validators.length() > 0) {
            _removeValidator(_validators.at(_validators.length() - 1)._address);
        }
    }

    function completeETHDKG() public {
        _isMaintenanceScheduled = false;
        _isConsensusRunning = true;
    }

    function pauseConsensus() public onlySnapshots {
        _isConsensusRunning = false;
    }

    function scheduleMaintenance() public {
        _isMaintenanceScheduled = true;
    }

    function setConsensusRunning(bool isRunning) public {
        _isConsensusRunning = isRunning;
    }

    function setMaxIntervalWithoutSnapshots(uint256 maxIntervalWithoutSnapshots) public {
        if (maxIntervalWithoutSnapshots == 0) {
            revert ValidatorPoolErrors.MaxIntervalWithoutSnapshotsMustBeNonZero();
        }
        _maxIntervalWithoutSnapshots = maxIntervalWithoutSnapshots;
    }

    function setStakeAmount(uint256 stakeAmount_) public {}

    function setSnapshot(address _address) public {}

    function setMaxNumValidators(uint256 maxNumValidators_) public {}

    function setLocation(string memory ip) public {}

    function registerValidators(
        address[] memory validators,
        uint256[] memory stakerTokenIDs
    ) public {
        stakerTokenIDs;
        _registerValidators(validators);
    }

    function isValidator(address participant) public view returns (bool) {
        return _isValidator(participant);
    }

    function getStakeAmount() public view returns (uint256) {
        return _stakeAmount;
    }

    function getMaxIntervalWithoutSnapshots()
        public
        view
        returns (uint256 maxIntervalWithoutSnapshots)
    {
        return _maxIntervalWithoutSnapshots;
    }

    function getValidatorsCount() public view returns (uint256) {
        return _validators.length();
    }

    function getValidator(uint256 index_) public view returns (address) {
        if (index_ >= _validators.length()) {
            revert ValidatorPoolErrors.InvalidIndex(index_);
        }
        return _validators.at(index_)._address;
    }

    function getValidatorsAddresses() public view returns (address[] memory addresses) {
        return _validators.addressValues();
    }

    function isMaintenanceScheduled() public view returns (bool) {
        return _isMaintenanceScheduled;
    }

    function isConsensusRunning() public view returns (bool) {
        return _isConsensusRunning;
    }

    function getValidatorData(uint256 index) public view returns (ValidatorData memory) {
        return _validators.at(index);
    }

    function isAccusable(address participant) public view returns (bool) {
        participant;
        return _isValidator(participant);
    }

    function getMaxNumValidators() public pure returns (uint256) {
        return 5;
    }

    function getDisputerReward() public pure returns (uint256) {
        return 1;
    }

    function claimExitingNFTPosition() public pure returns (uint256) {
        return 0;
    }

    function tryGetTokenID(address account_) public pure returns (bool, address, uint256) {
        account_; //no-op to suppress compiling warnings
        return (false, address(0), 0);
    }

    function collectProfits() public pure returns (uint256 payoutEth, uint256 payoutToken) {
        return (0, 0);
    }

    function getLocations(address[] memory validators_) public pure returns (string[] memory) {
        validators_;
        return new string[](1);
    }

    function isInExitingQueue(address participant) public pure returns (bool) {
        participant;
        return false;
    }

    function getLocation(address validator) public pure returns (string memory) {
        validator;
        return "";
    }

    function isMock() public pure returns (bool) {
        return true;
    }

    function _removeValidator(address validator_) internal {
        _validators.remove(validator_);
    }

    function _registerValidators(address[] memory v) internal {
        for (uint256 idx; idx < v.length; idx++) {
            uint256 tokenID = _tokenIDCounter + 1;
            _validators.add(ValidatorData(v[idx], tokenID));
            _tokenIDCounter = tokenID;
        }
    }

    function _isValidator(address participant) internal view returns (bool) {
        return _validators.contains(participant);
    }
}