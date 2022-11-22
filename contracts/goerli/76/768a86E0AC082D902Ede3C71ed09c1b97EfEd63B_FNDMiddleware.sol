// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Royalty registry interface
 */
interface IRoyaltyRegistry is IERC165 {

     event RoyaltyOverride(address owner, address tokenAddress, address royaltyAddress);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     * 
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress) external;

    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view returns(address);

    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function overrideAllowed(address tokenAddress) external view returns(bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./libraries/LockedBalance.sol";
import "./libraries/TimeLibrary.sol";

error FETH_Cannot_Deposit_For_Lockup_With_Address_Zero();
error FETH_Cannot_Deposit_To_Address_Zero();
error FETH_Cannot_Deposit_To_FETH();
error FETH_Cannot_Withdraw_To_Address_Zero();
error FETH_Cannot_Withdraw_To_FETH();
error FETH_Cannot_Withdraw_To_Market();
error FETH_Escrow_Expired();
error FETH_Escrow_Not_Found();
error FETH_Expiration_Too_Far_In_Future();
/// @param amount The current allowed amount the spender is authorized to transact for this account.
error FETH_Insufficient_Allowance(uint256 amount);
/// @param amount The current available (unlocked) token count of this account.
error FETH_Insufficient_Available_Funds(uint256 amount);
/// @param amount The current number of tokens this account has for the given lockup expiry bucket.
error FETH_Insufficient_Escrow(uint256 amount);
error FETH_Invalid_Lockup_Duration();
error FETH_Market_Must_Be_A_Contract();
error FETH_Must_Deposit_Non_Zero_Amount();
error FETH_Must_Lockup_Non_Zero_Amount();
error FETH_No_Funds_To_Withdraw();
error FETH_Only_FND_Market_Allowed();
error FETH_Too_Much_ETH_Provided();
error FETH_Transfer_To_Address_Zero_Not_Allowed();
error FETH_Transfer_To_FETH_Not_Allowed();

/**
 * @title An ERC-20 token which wraps ETH, potentially with a 1 day lockup period.
 * @notice FETH is an [ERC-20 token](https://eips.ethereum.org/EIPS/eip-20) modeled after
 * [WETH9](https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code).
 * It has the added ability to lockup tokens for 24-25 hours - during this time they may not be
 * transferred or withdrawn, except by our market contract which requested the lockup in the first place.
 * @dev Locked balances are rounded up to the next hour.
 * They are grouped by the expiration time of the lockup into what we refer to as a lockup "bucket".
 * At any time there may be up to 25 buckets but never more than that which prevents loops from exhausting gas limits.
 * FETH is an upgradeable contract. Overtime we will progressively decentralize, potentially giving upgrade permissions
 * to a DAO ownership or removing the permissions entirely.
 * @author batu-inal & HardlyDifficult
 */
contract FETH {
  using AddressUpgradeable for address payable;
  using LockedBalance for LockedBalance.Lockups;
  using Math for uint256;
  using TimeLibrary for uint32;
  using TimeLibrary for uint256;

  /// @notice Tracks an account's info.
  struct AccountInfo {
    /// @notice The number of tokens which have been unlocked already.
    uint96 freedBalance;
    /// @notice The first applicable lockup bucket for this account.
    uint32 lockupStartIndex;
    /// @notice Stores up to 25 buckets of locked balance for a user, one per hour.
    LockedBalance.Lockups lockups;
    /// @notice Returns the amount which a spender is still allowed to withdraw from this account.
    mapping(address => uint256) allowance;
  }

  /// @notice Stores per-account details.
  mapping(address => AccountInfo) private accountToInfo;

  // Lockup configuration
  /// @notice The minimum lockup period in seconds.
  uint256 private immutable lockupDuration;
  /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
  uint256 private immutable lockupInterval;

  /// @notice The Foundation market contract with permissions to manage lockups.
  address payable private immutable foundationMarket;

  /// @notice The Foundation drop market contract with permissions to withdraw available funds.
  address payable private immutable foundationDropMarket;

  // ERC-20 metadata fields
  /**
   * @notice The number of decimals the token uses.
   * @dev This method can be used to improve usability when displaying token amounts, but all interactions
   * with this contract use whole amounts not considering decimals.
   * @return 18
   */
  uint8 public constant decimals = 18;
  /**
   * @notice The name of the token.
   * @return Foundation ETH
   */
  string public constant name = "Foundation ETH";
  /**
   * @notice The symbol of the token.
   * @return FETH
   */
  string public constant symbol = "FETH";

  // ERC-20 events
  /**
   * @notice Emitted when the allowance for a spender account is updated.
   * @param from The account the spender is authorized to transact for.
   * @param spender The account with permissions to manage FETH tokens for the `from` account.
   * @param amount The max amount of tokens which can be spent by the `spender` account.
   */
  event Approval(address indexed from, address indexed spender, uint256 amount);
  /**
   * @notice Emitted when a transfer of FETH tokens is made from one account to another.
   * @param from The account which is sending FETH tokens.
   * @param to The account which is receiving FETH tokens.
   * @param amount The number of FETH tokens which were sent.
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Custom events
  /**
   * @notice Emitted when FETH tokens are locked up by the Foundation market for 24-25 hours
   * and may include newly deposited ETH which is added to the account's total FETH balance.
   * @param account The account which has access to the FETH after the `expiration`.
   * @param expiration The time at which the `from` account will have access to the locked FETH.
   * @param amount The number of FETH tokens which where locked up.
   * @param valueDeposited The amount of ETH added to their account's total FETH balance,
   * this may be lower than `amount` if available FETH was leveraged.
   */
  event BalanceLocked(address indexed account, uint256 indexed expiration, uint256 amount, uint256 valueDeposited);
  /**
   * @notice Emitted when FETH tokens are unlocked by the Foundation market.
   * @dev This event will not be emitted when lockups expire,
   * it's only for tokens which are unlocked before their expiry.
   * @param account The account which had locked FETH freed before expiration.
   * @param expiration The time this balance was originally scheduled to be unlocked.
   * @param amount The number of FETH tokens which were unlocked.
   */
  event BalanceUnlocked(address indexed account, uint256 indexed expiration, uint256 amount);
  /**
   * @notice Emitted when ETH is withdrawn from a user's account.
   * @dev This may be triggered by the user, an approved operator, or the Foundation market.
   * @param from The account from which FETH was deducted in order to send the ETH.
   * @param to The address the ETH was sent to.
   * @param amount The number of tokens which were deducted from the user's FETH balance and transferred as ETH.
   */
  event ETHWithdrawn(address indexed from, address indexed to, uint256 amount);

  /// @dev Allows the Foundation market permission to manage lockups for a user.
  modifier onlyFoundationMarket() {
    if (msg.sender != foundationMarket && msg.sender != foundationDropMarket) {
      revert FETH_Only_FND_Market_Allowed();
    }
    _;
  }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param _foundationMarket The address of the Foundation NFT marketplace.
   * @param _lockupDuration The minimum length of time to lockup tokens for when `BalanceLocked`, in seconds.
   */
  constructor(address payable _foundationMarket, address payable _foundationDropMarket, uint256 _lockupDuration) {
    if (!_foundationMarket.isContract()) {
      revert FETH_Market_Must_Be_A_Contract();
    }
    if (!_foundationDropMarket.isContract()) {
      revert FETH_Market_Must_Be_A_Contract();
    }
    foundationMarket = _foundationMarket;
    foundationDropMarket = _foundationDropMarket;
    lockupDuration = _lockupDuration;
    lockupInterval = _lockupDuration / 24;
    if (lockupInterval * 24 != _lockupDuration || _lockupDuration == 0) {
      revert FETH_Invalid_Lockup_Duration();
    }
  }

  /**
   * @notice Transferring ETH (via `msg.value`) to the contract performs a `deposit` into the user's account.
   */
  receive() external payable {
    depositFor(msg.sender);
  }

  /**
   * @notice Approves a `spender` as an operator with permissions to transfer from your account.
   * @dev To prevent attack vectors, clients SHOULD make sure to create user interfaces in such a way
   * that they set the allowance first to 0 before setting it to another value for the same spender.
   * We will add support for `increaseAllowance` in the future.
   * @param spender The address of the operator account that has approval to spend funds
   * from the `msg.sender`'s account.
   * @param amount The max number of FETH tokens from `msg.sender`'s account that this spender is
   * allowed to transact with.
   * @return success Always true.
   */
  function approve(address spender, uint256 amount) external returns (bool success) {
    accountToInfo[msg.sender].allowance[spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Deposit ETH (via `msg.value`) and receive the equivalent amount in FETH tokens.
   * These tokens are not subject to any lockup period.
   */
  function deposit() external payable {
    depositFor(msg.sender);
  }

  /**
   * @notice Deposit ETH (via `msg.value`) and credit the `account` provided with the equivalent amount in FETH tokens.
   * These tokens are not subject to any lockup period.
   * @dev This may be used by the Foundation market to credit a user's account with FETH tokens.
   * @param account The account to credit with FETH tokens.
   */
  function depositFor(address account) public payable {
    if (msg.value == 0) {
      revert FETH_Must_Deposit_Non_Zero_Amount();
    } else if (account == address(0)) {
      revert FETH_Cannot_Deposit_To_Address_Zero();
    } else if (account == address(this)) {
      revert FETH_Cannot_Deposit_To_FETH();
    }
    AccountInfo storage accountInfo = accountToInfo[account];
    // ETH value cannot realistically overflow 96 bits.
    unchecked {
      accountInfo.freedBalance += uint96(msg.value);
    }
    emit Transfer(address(0), account, msg.value);
  }

  /**
   * @notice Used by the market contract only:
   * Remove an account's lockup and then create a new lockup, potentially for a different account.
   * @dev Used by the market when an offer for an NFT is increased.
   * This may be for a single account (increasing their offer)
   * or two different accounts (outbidding someone elses offer).
   * @param unlockFrom The account whose lockup is to be removed.
   * @param unlockExpiration The original lockup expiration for the tokens to be unlocked.
   * This will revert if the lockup has already expired.
   * @param unlockAmount The number of tokens to be unlocked from `unlockFrom`'s account.
   * This will revert if the tokens were previously unlocked.
   * @param lockupFor The account to which the funds are to be deposited for (via the `msg.value`) and tokens locked up.
   * @param lockupAmount The number of tokens to be locked up for the `lockupFor`'s account.
   * `msg.value` must be <= `lockupAmount` and any delta will be taken from the account's available FETH balance.
   * @return expiration The expiration timestamp for the FETH tokens that were locked.
   */
  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address lockupFor,
    uint256 lockupAmount
  ) external payable onlyFoundationMarket returns (uint256 expiration) {
    _marketUnlockFor(unlockFrom, unlockExpiration, unlockAmount);
    return _marketLockupFor(lockupFor, lockupAmount);
  }

  /**
   * @notice Used by the market contract only:
   * Lockup an account's FETH tokens for 24-25 hours.
   * @dev Used by the market when a new offer for an NFT is made.
   * @param account The account to which the funds are to be deposited for (via the `msg.value`) and tokens locked up.
   * @param amount The number of tokens to be locked up for the `lockupFor`'s account.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available FETH balance.
   * @return expiration The expiration timestamp for the FETH tokens that were locked.
   */
  function marketLockupFor(address account, uint256 amount)
    external
    payable
    onlyFoundationMarket
    returns (uint256 expiration)
  {
    return _marketLockupFor(account, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Remove an account's lockup, making the FETH tokens available for transfer or withdrawal.
   * @dev Used by the market when an offer is invalidated, which occurs when an auction for the same NFT
   * receives its first bid or the buyer purchased the NFT another way, such as with `buy`.
   * @param account The account whose lockup is to be unlocked.
   * @param expiration The original lockup expiration for the tokens to be unlocked unlocked.
   * This will revert if the lockup has already expired.
   * @param amount The number of tokens to be unlocked from `account`.
   * This will revert if the tokens were previously unlocked.
   */
  function marketUnlockFor(address account, uint256 expiration, uint256 amount) external onlyFoundationMarket {
    _marketUnlockFor(account, expiration, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Removes tokens from the user's available balance and returns ETH to the caller.
   * @dev Used by the market when a user's available FETH balance is used to make a purchase
   * including accepting a buy price or a private sale, or placing a bid in an auction.
   * @param from The account whose available balance is to be withdrawn from.
   * @param amount The number of tokens to be deducted from `unlockFrom`'s available balance and transferred as ETH.
   * This will revert if the tokens were previously unlocked.
   */
  function marketWithdrawFrom(address from, uint256 amount) external onlyFoundationMarket {
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    _deductBalanceFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(from, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Removes a lockup from the user's account and then returns ETH to the caller.
   * @dev Used by the market to extract unexpired funds as ETH to distribute for
   * a sale when the user's offer is accepted.
   * @param account The account whose lockup is to be removed.
   * @param expiration The original lockup expiration for the tokens to be unlocked.
   * This will revert if the lockup has already expired.
   * @param amount The number of tokens to be unlocked and withdrawn as ETH.
   */
  function marketWithdrawLocked(address account, uint256 expiration, uint256 amount) external onlyFoundationMarket {
    _removeFromLockedBalance(account, expiration, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(account, msg.sender, amount);
  }

  /**
   * @notice Transfers an amount from your account.
   * @param to The address of the account which the tokens are transferred from.
   * @param amount The number of FETH tokens to be transferred.
   * @return success Always true (reverts if insufficient funds).
   */
  function transfer(address to, uint256 amount) external returns (bool success) {
    return transferFrom(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount from the account specified if the `msg.sender` has approval.
   * @param from The address from which the available tokens are transferred from.
   * @param to The address to which the tokens are to be transferred.
   * @param amount The number of FETH tokens to be transferred.
   * @return success Always true (reverts if insufficient funds or not approved).
   */
  function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
    if (to == address(0)) {
      revert FETH_Transfer_To_Address_Zero_Not_Allowed();
    } else if (to == address(this)) {
      revert FETH_Transfer_To_FETH_Not_Allowed();
    }
    AccountInfo storage fromAccountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowanceFrom(fromAccountInfo, amount, from);
    }
    _deductBalanceFrom(fromAccountInfo, amount);
    AccountInfo storage toAccountInfo = accountToInfo[to];

    // Total ETH cannot realistically overflow 96 bits.
    unchecked {
      toAccountInfo.freedBalance += uint96(amount);
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @notice Withdraw all tokens available in your account and receive ETH.
   */
  function withdrawAvailableBalance() external {
    AccountInfo storage accountInfo = _freeFromEscrow(msg.sender);
    uint256 amount = accountInfo.freedBalance;
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    }
    delete accountInfo.freedBalance;

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Withdraw the specified number of tokens from the `from` accounts available balance
   * and send ETH to the destination address, if the `msg.sender` has approval.
   * @param from The address from which the available funds are to be withdrawn.
   * @param to The destination address for the ETH to be transferred to.
   * @param amount The number of tokens to be withdrawn and transferred as ETH.
   */
  function withdrawFrom(address from, address payable to, uint256 amount) external {
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    } else if (to == address(0)) {
      revert FETH_Cannot_Withdraw_To_Address_Zero();
    } else if (to == address(this)) {
      revert FETH_Cannot_Withdraw_To_FETH();
    } else if (to == address(foundationMarket)) {
      revert FETH_Cannot_Withdraw_To_Market();
    } else if (to == address(foundationDropMarket)) {
      revert FETH_Cannot_Withdraw_To_Market();
    }

    AccountInfo storage accountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowanceFrom(accountInfo, amount, from);
    }
    _deductBalanceFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    to.sendValue(amount);

    emit ETHWithdrawn(from, to, amount);
  }

  /**
   * @dev Require msg.sender has been approved and deducts the amount from the available allowance.
   */
  function _deductAllowanceFrom(AccountInfo storage accountInfo, uint256 amount, address from) private {
    uint256 spenderAllowance = accountInfo.allowance[msg.sender];
    if (spenderAllowance == type(uint256).max) {
      return;
    }
    if (spenderAllowance < amount) {
      revert FETH_Insufficient_Allowance(spenderAllowance);
    }
    // The check above ensures allowance cannot underflow.
    unchecked {
      spenderAllowance -= amount;
    }
    accountInfo.allowance[msg.sender] = spenderAllowance;
    emit Approval(from, msg.sender, spenderAllowance);
  }

  /**
   * @dev Removes an amount from the account's available FETH balance.
   */
  function _deductBalanceFrom(AccountInfo storage accountInfo, uint256 amount) private {
    uint96 freedBalance = accountInfo.freedBalance;
    // Free from escrow in order to consider any expired escrow balance
    if (freedBalance < amount) {
      revert FETH_Insufficient_Available_Funds(freedBalance);
    }
    // The check above ensures balance cannot underflow.
    unchecked {
      accountInfo.freedBalance = freedBalance - uint96(amount);
    }
  }

  /**
   * @dev Moves expired escrow to the available balance.
   * Sets the next bucket that hasn't expired as the new start index.
   */
  function _freeFromEscrow(address account) private returns (AccountInfo storage) {
    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    // If the first bucket (the oldest) is empty or not yet expired, no change to escrowStartIndex is required
    if (escrow.expiration == 0 || !escrow.expiration.hasExpired()) {
      return accountInfo;
    }

    while (true) {
      // Total ETH cannot realistically overflow 96 bits.
      unchecked {
        accountInfo.freedBalance += escrow.totalAmount;
        accountInfo.lockups.del(escrowIndex);
        // Escrow index cannot overflow 32 bits.
        escrow = accountInfo.lockups.get(escrowIndex + 1);
      }

      // If the next bucket is empty, the start index is set to the previous bucket
      if (escrow.expiration == 0) {
        break;
      }

      // Escrow index cannot overflow 32 bits.
      unchecked {
        // Increment the escrow start index if the next bucket is not empty
        ++escrowIndex;
      }

      // If the next bucket is expired, that's the new start index
      if (!escrow.expiration.hasExpired()) {
        break;
      }
    }

    // Escrow index cannot overflow 32 bits.
    unchecked {
      accountInfo.lockupStartIndex = uint32(escrowIndex);
    }
    return accountInfo;
  }

  /**
   * @notice Lockup an account's FETH tokens for 24-25 hours.
   */
  /* solhint-disable-next-line code-complexity */
  function _marketLockupFor(address account, uint256 amount) private returns (uint256 expiration) {
    if (account == address(0)) {
      revert FETH_Cannot_Deposit_For_Lockup_With_Address_Zero();
    }
    if (amount == 0) {
      revert FETH_Must_Lockup_Non_Zero_Amount();
    }

    // Block timestamp in seconds is small enough to never overflow
    unchecked {
      // Lockup expires after 24 hours, rounded up to the next hour for a total of [24-25) hours
      expiration = lockupDuration + block.timestamp.ceilDiv(lockupInterval) * lockupInterval;
    }

    // Update available escrow
    // Always free from escrow to ensure the max bucket count is <= 25
    AccountInfo storage accountInfo = _freeFromEscrow(account);
    if (msg.value < amount) {
      unchecked {
        // The if check above prevents an underflow here
        _deductBalanceFrom(accountInfo, amount - msg.value);
      }
    } else if (msg.value != amount) {
      // There's no reason to send msg.value more than the amount being locked up
      revert FETH_Too_Much_ETH_Provided();
    }

    // Add to locked escrow
    unchecked {
      // The number of buckets is always < 256 bits.
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          if (expiration > type(uint32).max) {
            revert FETH_Expiration_Too_Far_In_Future();
          }
          // Amount (ETH) will always be < 96 bits.
          accountInfo.lockups.set(escrowIndex, expiration, amount);
          break;
        }
        if (escrow.expiration == expiration) {
          // Total ETH will always be < 96 bits.
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount + amount);
          break;
        }
      }
    }

    emit BalanceLocked(account, expiration, amount, msg.value);
  }

  /**
   * @notice Remove an account's lockup, making the FETH tokens available for transfer or withdrawal.
   */
  function _marketUnlockFor(address account, uint256 expiration, uint256 amount) private {
    AccountInfo storage accountInfo = _removeFromLockedBalance(account, expiration, amount);
    // Total ETH cannot realistically overflow 96 bits.
    unchecked {
      accountInfo.freedBalance += uint96(amount);
    }
  }

  /**
   * @dev Removes the specified amount from locked escrow, potentially before its expiration.
   */
  /* solhint-disable-next-line code-complexity */
  function _removeFromLockedBalance(address account, uint256 expiration, uint256 amount)
    private
    returns (AccountInfo storage)
  {
    if (expiration.hasExpired()) {
      revert FETH_Escrow_Expired();
    }

    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    if (escrow.expiration == expiration) {
      // If removing from the first bucket, we may be able to delete it
      if (escrow.totalAmount == amount) {
        accountInfo.lockups.del(escrowIndex);

        // Bump the escrow start index unless it's the last one
        unchecked {
          if (accountInfo.lockups.get(escrowIndex + 1).expiration != 0) {
            // The number of escrow buckets will never overflow 32 bits.
            ++accountInfo.lockupStartIndex;
          }
        }
      } else {
        if (escrow.totalAmount < amount) {
          revert FETH_Insufficient_Escrow(escrow.totalAmount);
        }
        // The require above ensures balance will not underflow.
        unchecked {
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
        }
      }
    } else {
      // Removing from the 2nd+ bucket
      while (true) {
        // The number of escrow buckets will never overflow 32 bits.
        unchecked {
          ++escrowIndex;
        }
        escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == expiration) {
          if (amount > escrow.totalAmount) {
            revert FETH_Insufficient_Escrow(escrow.totalAmount);
          }
          // The require above ensures balance will not underflow.
          unchecked {
            accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
          }
          // We may have an entry with 0 totalAmount but expiration will be set
          break;
        }
        if (escrow.expiration == 0) {
          revert FETH_Escrow_Not_Found();
        }
      }
    }

    emit BalanceUnlocked(account, expiration, amount);
    return accountInfo;
  }

  /**
   * @notice Returns the amount which a spender is still allowed to transact from the `account`'s balance.
   * @param account The owner of the funds.
   * @param operator The address with approval to spend from the `account`'s balance.
   * @return amount The number of tokens the `operator` is still allowed to transact with.
   */
  function allowance(address account, address operator) external view returns (uint256 amount) {
    AccountInfo storage accountInfo = accountToInfo[account];
    amount = accountInfo.allowance[operator];
  }

  /**
   * @notice Returns the balance of an account which is available to transfer or withdraw.
   * @dev This will automatically increase as soon as locked tokens reach their expiry date.
   * @param account The account to query the available balance of.
   * @return balance The available balance of the account.
   */
  function balanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
    unchecked {
      // Add expired lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0 || !escrow.expiration.hasExpired()) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Gets the Foundation market address which has permissions to manage lockups.
   * @return market The Foundation market contract address.
   */
  function getFoundationMarket() external view returns (address market) {
    market = foundationMarket;
  }

  /**
   * @notice Gets the Foundation drop market address which has permissions to withdraw available funds.
   * @return market The Foundation drop market contract address.
   */
  function getFoundationDropMarket() external view returns (address market) {
    market = foundationDropMarket;
  }

  /**
   * @notice Returns the balance and each outstanding (unexpired) lockup bucket for an account, grouped by expiry.
   * @dev `expires.length` == `amounts.length`
   * and `amounts[i]` is the number of tokens which will expire at `expires[i]`.
   * The results returned are sorted by expiry, with the earliest expiry date first.
   * @param account The account to query the locked balance of.
   * @return expiries The time at which each outstanding lockup bucket expires.
   * @return amounts The number of FETH tokens which will expire for each outstanding lockup bucket.
   */
  function getLockups(address account) external view returns (uint256[] memory expiries, uint256[] memory amounts) {
    AccountInfo storage accountInfo = accountToInfo[account];

    // Count lockups
    uint256 lockedCount;
    // The number of buckets is always < 256 bits.
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (!escrow.expiration.hasExpired() && escrow.totalAmount != 0) {
          // Lockup count will never overflow 256 bits.
          ++lockedCount;
        }
      }
    }

    // Allocate arrays
    expiries = new uint256[](lockedCount);
    amounts = new uint256[](lockedCount);

    // Populate results
    uint256 i;
    // The number of buckets is always < 256 bits.
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (!escrow.expiration.hasExpired() && escrow.totalAmount != 0) {
          expiries[i] = escrow.expiration;
          amounts[i] = escrow.totalAmount;
          ++i;
        }
      }
    }
  }

  /**
   * @notice Returns the total balance of an account, including locked FETH tokens.
   * @dev Use `balanceOf` to get the number of tokens available for transfer or withdrawal.
   * @param account The account to query the total balance of.
   * @return balance The total FETH balance tracked for this account.
   */
  function totalBalanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
    unchecked {
      // Add all lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the total amount of ETH locked in this contract.
   * @return supply The total amount of ETH locked in this contract.
   * @dev It is possible for this to diverge from the total token count by transferring ETH on self destruct
   * but this is on-par with the WETH implementation and done for gas savings.
   */
  function totalSupply() external view returns (uint256 supply) {
    return address(this).balance;
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/dependencies/ens/IENS.sol";
import "./interfaces/dependencies/ens/IPublicResolver.sol";
import "./interfaces/dependencies/ens/IReverseRegistrar.sol";

import "./libraries/TimeLibrary.sol";

import "./NFTCollection.sol";
import "./FETH.sol";
import "./NFTMarket.sol";
import "./NFTDropMarket.sol";
import "./PercentSplitETH.sol";

import "./mixins/shared/Constants.sol";

/**
 * @title Convenience methods to ease integration with other contracts.
 * @notice This will aggregate calls and format the output per the needs of our frontend or other consumers.
 * @author batu-inal & HardlyDifficult
 */
contract FNDMiddleware {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Strings for uint256;
  using Strings for address;
  using TimeLibrary for uint256;
  using ERC165Checker for address;

  struct Fee {
    uint256 percentInBasisPoints;
    uint256 amountInWei;
  }
  struct FeeWithRecipient {
    uint256 percentInBasisPoints;
    uint256 amountInWei;
    address payable recipient;
  }
  struct RevSplit {
    uint256 relativePercentInBasisPoints;
    uint256 absolutePercentInBasisPoints;
    uint256 amountInWei;
    address payable recipient;
  }

  NFTMarket private immutable market;
  NFTDropMarket private immutable nftDropMarket;
  FETH private immutable feth;
  IENS private immutable ens;

  constructor(address payable _market, address payable _nftDropMarket, address payable _feth, address _ens) {
    market = NFTMarket(_market);
    nftDropMarket = NFTDropMarket(_nftDropMarket);
    feth = FETH(_feth);
    ens = IENS(_ens);
  }

  // solhint-disable-next-line code-complexity
  function getFees(address nftContract, uint256 tokenId, uint256 price)
    external
    view
    returns (
      FeeWithRecipient memory protocol,
      Fee memory creator,
      FeeWithRecipient memory owner,
      RevSplit[] memory creatorRevSplit
    )
  {
    address payable[] memory creatorRecipients;
    uint256[] memory creatorShares;
    uint256 creatorRevBP;
    {
      bool isDropMarket;
      try IERC721(nftContract).ownerOf(tokenId) returns (
        address /*ownerOf*/ // solhint-disable-next-line no-empty-blocks
      ) {
        // NFT minted an owner returns
        // TODO: consider address(0) as dropMarket?
      } catch {
        // NFT not minted yet - belongs to dropMarket primary sale.
        isDropMarket = true;
      }

      // Note that the protocol fee returned does not account for the referrals (which are not known until sale).
      protocol.recipient = isDropMarket ? nftDropMarket.getFoundationTreasury() : market.getFoundationTreasury();
      {
        (
          protocol.amountInWei,
          creator.amountInWei,
          creatorRecipients,
          creatorShares,
          owner.amountInWei,
          owner.recipient
        ) = isDropMarket
          ? nftDropMarket.getFeesAndRecipients(nftContract, tokenId, price)
          : market.getFeesAndRecipients(nftContract, tokenId, price);
        if (creatorShares.length == 0) {
          creatorShares = new uint256[](creatorRecipients.length);
          if (creatorShares.length == 1) {
            creatorShares[0] = BASIS_POINTS;
          }
        }
      }
      {
        uint256 totalFeesBP;
        uint256 sellerRevBP;
        (totalFeesBP, creatorRevBP, , , sellerRevBP, ) = isDropMarket
          ? nftDropMarket.getFeesAndRecipients(nftContract, tokenId, BASIS_POINTS)
          : market.getFeesAndRecipients(nftContract, tokenId, BASIS_POINTS);
        protocol.percentInBasisPoints = totalFeesBP;
        creator.percentInBasisPoints = creatorRevBP;
        owner.percentInBasisPoints = sellerRevBP;
      }
    }

    // Normalize shares to 10%
    {
      uint256 totalShares = 0;
      for (uint256 i = 0; i < creatorShares.length; ++i) {
        // TODO handle ignore if > 100% (like the market would)
        totalShares += creatorShares[i];
      }

      if (totalShares != 0) {
        for (uint256 i = 0; i < creatorShares.length; ++i) {
          creatorShares[i] = (BASIS_POINTS * creatorShares[i]) / totalShares;
        }
      }
    }
    // Count creators and split recipients
    {
      uint256 creatorCount = creatorRecipients.length;
      for (uint256 i = 0; i < creatorRecipients.length; ++i) {
        // Check if the address is a percent split
        if (address(creatorRecipients[i]).isContract()) {
          try this.getSplitShareLength(creatorRecipients[i]) returns (uint256 recipientCount) {
            creatorCount += recipientCount - 1;
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Not a Foundation percent split
          }
        }
      }
      creatorRevSplit = new RevSplit[](creatorCount);
    }

    // Populate rev splits, including any percent splits
    uint256 revSplitIndex = 0;
    for (uint256 i = 0; i < creatorRecipients.length; ++i) {
      if (address(creatorRecipients[i]).isContract()) {
        try this.getSplitShareLength(creatorRecipients[i]) returns (uint256 recipientCount) {
          uint256 totalSplitShares;
          for (uint256 splitIndex = 0; splitIndex < recipientCount; ++splitIndex) {
            uint256 share = PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex);
            totalSplitShares += share;
          }
          for (uint256 splitIndex = 0; splitIndex < recipientCount; ++splitIndex) {
            uint256 splitShare = (PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex) *
              BASIS_POINTS) / totalSplitShares;
            splitShare = (splitShare * creatorShares[i]) / BASIS_POINTS;
            creatorRevSplit[revSplitIndex++] = _calcRevSplit(
              price,
              splitShare,
              creatorRevBP,
              PercentSplitETH(creatorRecipients[i]).getShareRecipientByIndex(splitIndex)
            );
          }
          continue;
        } catch // solhint-disable-next-line no-empty-blocks
        {
          // Not a Foundation percent split
        }
      }
      {
        creatorRevSplit[revSplitIndex++] = _calcRevSplit(price, creatorShares[i], creatorRevBP, creatorRecipients[i]);
      }
    }

    // Bubble the creator to the first position in `creatorRevSplit`
    {
      address creatorAddress;
      try this.getTokenCreator(nftContract, tokenId) returns (address _creatorAddress) {
        creatorAddress = _creatorAddress;
      } catch // solhint-disable-next-line no-empty-blocks
      {

      }
      if (creatorAddress != address(0)) {
        for (uint256 i = 1; i < creatorRevSplit.length; ++i) {
          if (creatorRevSplit[i].recipient == creatorAddress) {
            (creatorRevSplit[i], creatorRevSplit[0]) = (creatorRevSplit[0], creatorRevSplit[i]);
            break;
          }
        }
      }
    }
  }

  /**
   * @notice Checks who the seller for an NFT is, checking both markets or returning the current owner.
   */
  function getSellerOrOwnerOf(address nftContract, uint256 tokenId)
    public
    view
    virtual
    returns (address payable ownerOrSeller)
  {
    ownerOrSeller = market.getSellerOf(nftContract, tokenId);
    if (ownerOrSeller == address(0)) {
      ownerOrSeller = nftDropMarket.getSellerOf(nftContract, tokenId);
      if (ownerOrSeller == address(0)) {
        ownerOrSeller = payable(IERC721(nftContract).ownerOf(tokenId));
      }
    }
  }

  function getSplitShareLength(address payable recipient) external view returns (uint256 count) {
    count = PercentSplitETH(recipient).getShareLength{ gas: READ_ONLY_GAS_LIMIT }();
  }

  function getTokenCreator(address nftContract, uint256 tokenId) external view returns (address creatorAddress) {
    try market.internalGetTokenCreator{ gas: READ_ONLY_GAS_LIMIT }(nftContract, tokenId) returns (
      address payable _creator
    ) {
      return _creator;
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // 7th priority: owner from contract or override
    try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address _owner) {
      if (_owner != address(0)) {
        return _owner;
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }
  }

  /**
   * @notice Checks an NFT to confirm it will function correctly with our marketplace.
   * @dev This should be called with as `call` to simulate the tx; never `sendTransaction`.
   * @return 0 if the NFT is supported, otherwise a hash of the error reason.
   */
  function probeNFT(address nftContract, uint256 tokenId) external payable returns (bytes32) {
    if (!nftContract.supportsInterface(type(IERC721).interfaceId)) {
      return keccak256("Not an ERC721");
    }
    RevSplit[] memory creatorRevSplit;
    try this.getFees(nftContract, tokenId, BASIS_POINTS) returns (
      FeeWithRecipient memory,
      Fee memory,
      FeeWithRecipient memory,
      RevSplit[] memory _creatorRevSplit
    ) {
      creatorRevSplit = _creatorRevSplit;
    } catch {
      return keccak256("Failed to getFees");
    }
    if (creatorRevSplit.length == 0) {
      return keccak256("No royalty recipients");
    }
    for (uint256 i = 0; i < creatorRevSplit.length; ++i) {
      address recipient = creatorRevSplit[i].recipient;
      if (recipient == address(0)) {
        return keccak256("address(0) recipient");
      }
      // Sending > 1 to help confirm when the recipient is a contract forwarding to other addresses
      // Silk Road by Ezra Miller requires > 100 wei to when testing payments
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = recipient.call{ value: 1_000, gas: SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS }("");
      if (!success) {
        return keccak256("Recipient not receivable");
      }
    }

    return 0x0;
  }

  function getAccountInfo(address account)
    external
    view
    returns (uint256 ethBalance, uint256 availableFethBalance, uint256 lockedFethBalance, string memory ensName)
  {
    ethBalance = account.balance;
    availableFethBalance = feth.balanceOf(account);
    lockedFethBalance = feth.totalBalanceOf(account) - availableFethBalance;

    // Lookup ENS name, if one was registered
    ensName = _getENSName(account);
  }

  /**
   * @notice Retrieves details about the current state of an NFT in the FND Market.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return owner The account which currently holds the NFT or has listed it for sale.
   * @return isInEscrow True if the NFT is currently held in escrow by the Market (for an auction or buy price).
   * @return auctionBidder The current highest bidder for the auction, or address(0) if there's not an active auction.
   * @return auctionEndTime The time at which this auction will not accept any new bids,
   *                        this is `0` until the first bid is placed.
   * @return auctionPrice The latest price of the NFT in this auction.
   *                      This is set to the reserve price, and then to the highest bid once the auction has started.
   *                      Returns `0` if there's no auction for this NFT.
   * @return auctionId The id of the auction, or 0 if no auction is found.
   * @return buyPrice The price at which you could buy this NFT.
   *                  Returns max uint256 if there is no buy price set for this NFT (since a price of 0 is supported).
   * @return offerAmount The amount being offered for this NFT.
   *                     Returns `0` if there is no offer or the most recent offer has expired.
   * @return offerBuyer The address of the buyer that made the current highest offer.
   *                    Returns `address(0)` if there is no offer or the most recent offer has expired.
   * @return offerExpiration The timestamp that the current highest offer expires.
   *                         Returns `0` if there is no offer or the most recent offer has expired.
   */
  function getNFTDetails(address nftContract, uint256 tokenId)
    public
    view
    returns (
      address owner,
      bool isInEscrow,
      address auctionBidder,
      uint256 auctionEndTime,
      uint256 auctionPrice,
      uint256 auctionId,
      uint256 buyPrice,
      uint256 offerAmount,
      address offerBuyer,
      uint256 offerExpiration
    )
  {
    (owner, buyPrice) = market.getBuyPrice(nftContract, tokenId);
    (offerBuyer, offerExpiration, offerAmount) = market.getOffer(nftContract, tokenId);
    auctionId = market.getReserveAuctionIdFor(nftContract, tokenId);
    if (auctionId != 0) {
      NFTMarketReserveAuction.ReserveAuction memory auction = market.getReserveAuction(auctionId);
      auctionEndTime = auction.endTime;
      auctionPrice = auction.amount;
      auctionBidder = auction.bidder;
      owner = auction.seller;
    }

    if (owner == address(0)) {
      owner = payable(IERC721(nftContract).ownerOf(tokenId));
      isInEscrow = false;
    } else {
      isInEscrow = true;
    }
  }

  /**
   * @notice Retrieves details about the current state of an NFT in the FND Market as a string.
   * @dev This API is for investigations & convenience, it is not meant to be consumed by an app directly.
   *      Future upgrades may not be backwards compatible.
   */
  // solhint-disable-next-line code-complexity
  function getNFTDetailString(address nftContract, uint256 tokenId) external view returns (string memory details) {
    (
      address owner,
      bool isInEscrow,
      address auctionBidder,
      uint256 auctionEndTime,
      uint256 auctionPrice,
      uint256 auctionId,
      uint256 buyPrice,
      uint256 offerAmount,
      address offerBuyer,
      uint256 offerExpiration
    ) = getNFTDetails(nftContract, tokenId);
    details = _getAddressAndName(owner);
    if (isInEscrow) {
      if (auctionEndTime > 0) {
        if (!auctionEndTime.hasExpired()) {
          // Active auction
          details = string.concat(
            details,
            " has it in active auction going for ",
            _getETHString(auctionPrice),
            ", bid from ",
            _getAddressAndName(auctionBidder),
            " and ends in ",
            _getDeltaTimeString(auctionEndTime - block.timestamp),
            " [auctionId: ",
            auctionId.toString(),
            "]"
          );
        } else {
          // Auction ended, pending finalization
          details = string.concat(
            details,
            " sold it in auction for ",
            _getETHString(auctionPrice),
            " to ",
            _getAddressAndName(auctionBidder),
            " ",
            _getDeltaTimeString(block.timestamp - auctionEndTime),
            " ago [pending settlement / auctionId: ",
            auctionId.toString(),
            "]"
          );
        }
      } else {
        // Buy now and/or reserve price
        details = string.concat(details, " listed for ");
        if (buyPrice < type(uint256).max) {
          details = string.concat(details, "buy now at ", _getETHString(buyPrice));
        }
        if (buyPrice < type(uint256).max && auctionPrice > 0) {
          details = string.concat(details, " or ");
        }
        if (auctionPrice > 0) {
          details = string.concat(
            details,
            "reserve price of ",
            _getETHString(auctionPrice),
            " [auctionId: ",
            auctionId.toString(),
            "]"
          );
        }
      }

      if (offerAmount > 0) {
        // With an offer too
        details = string.concat(
          details,
          " with an offer of ",
          _getOfferString(offerAmount, offerBuyer, offerExpiration)
        );
      }
    } else if (offerAmount > 0) {
      // Just an offer
      details = string.concat(details, " has an offer for ", _getOfferString(offerAmount, offerBuyer, offerExpiration));
    } else {
      // Nothing
      details = string.concat(details, " has not listed nor gotten an offer");
    }
  }

  function _calcRevSplit(uint256 price, uint256 share, uint256 creatorRevBP, address payable recipient)
    private
    pure
    returns (RevSplit memory)
  {
    uint256 absoluteShare = (share * creatorRevBP) / BASIS_POINTS;
    uint256 amount = (absoluteShare * price) / BASIS_POINTS;
    return RevSplit(share, absoluteShare, amount, recipient);
  }

  function _getAddressAndName(address account) private view returns (string memory name) {
    string memory ensName = _getENSName(account);
    if (bytes(ensName).length > 0) {
      name = string.concat(account.toHexString(), " (", ensName, ")");
    } else {
      name = account.toHexString();
    }
  }

  // solhint-disable-next-line code-complexity
  function _getDeltaTimeString(uint256 timeRemaining) private pure returns (string memory delta) {
    uint256 secondsRemaining = timeRemaining;
    // Days
    if (timeRemaining >= 1 days) {
      uint256 day = secondsRemaining / (1 days);
      if (day == 1) {
        delta = "1 day";
      } else {
        delta = string.concat(day.toString(), " days");
      }
      secondsRemaining -= day * 1 days;
      if (secondsRemaining == 0) {
        return delta;
      } else {
        delta = string.concat(delta, " ");
      }
    }
    // Hours
    if (timeRemaining >= 1 hours) {
      uint256 hrs = secondsRemaining / (1 hours);
      if (hrs == 1) {
        delta = string.concat(delta, "1 hour");
      } else {
        delta = string.concat(delta, hrs.toString(), " hours");
      }
      secondsRemaining -= hrs * 1 hours;
      if (secondsRemaining == 0) {
        return delta;
      } else {
        delta = string.concat(delta, " ");
      }
    }
    // Minutes
    if (timeRemaining >= 1 minutes) {
      uint256 mins = secondsRemaining / (1 minutes);
      if (mins == 1) {
        delta = string.concat(delta, "1 min");
      } else {
        delta = string.concat(delta, mins.toString(), " mins");
      }
      secondsRemaining -= mins * 1 minutes;
      if (secondsRemaining == 0) {
        return delta;
      } else {
        delta = string.concat(delta, " ");
      }
    }
    // Seconds
    if (secondsRemaining == 1) {
      delta = string.concat(delta, "1 sec");
    } else {
      delta = string.concat(delta, secondsRemaining.toString(), " secs");
    }
  }

  // solhint-disable-next-line code-complexity
  function _getETHString(uint256 amount) private pure returns (string memory eth) {
    string memory amountString = amount.toString();
    uint256 printedCount = 0;
    if (bytes(amountString).length > 18) {
      for (uint256 i = 0; i < bytes(amountString).length - 18; ++i) {
        bytes memory byteArray = new bytes(1);
        byteArray[0] = bytes(amountString)[i];
        eth = string.concat(eth, string(byteArray));
        printedCount++;
      }
    } else {
      eth = "0";
    }
    uint256 endingZeros = 0;
    for (uint256 i = bytes(amountString).length - 1; i > 0; --i) {
      if (bytes(amountString)[i] == bytes("0")[0]) {
        ++endingZeros;
      } else {
        break;
      }
    }
    if (endingZeros < 18) {
      eth = string.concat(eth, ".");

      if (bytes(amountString).length < 18) {
        // add leading zeros
        for (uint256 i = 0; i < 18 - bytes(amountString).length; ++i) {
          eth = string.concat(eth, "0");
        }
      }
      for (; printedCount < bytes(amountString).length - endingZeros; ++printedCount) {
        bytes memory byteArray = new bytes(1);
        byteArray[0] = bytes(amountString)[printedCount];
        eth = string.concat(eth, string(byteArray));
      }
    }

    eth = string.concat(eth, " ETH");
  }

  function _getENSName(address account) private view returns (string memory ensName) {
    IReverseRegistrar reverseRegistrar = IReverseRegistrar(
      ens.owner(
        keccak256(
          abi.encodePacked(keccak256(abi.encodePacked(abi.encode(bytes32(0)), keccak256("reverse"))), keccak256("addr"))
        )
      )
    );
    bytes32 node = reverseRegistrar.node(account);
    if (node != bytes32(0)) {
      IPublicResolver resolver = IPublicResolver(ens.resolver(node));

      // The standard call style is reverting when no results are found
      (bool success, bytes memory data) = address(resolver).staticcall(abi.encodeWithSignature("name(bytes32)", node));

      if (success && data.length > 0) {
        ensName = resolver.name(node);

        // TODO this only works for .eth names, subdomains and others will be ignored
        bytes32 nameNode = keccak256(
          abi.encodePacked(
            keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))),
            keccak256(_substring(ensName, 0, bytes(ensName).length - 4))
          )
        );

        // Validate ownership
        address owner = ens.owner(nameNode);
        if (owner != account) {
          // Invalid reverse registration
          ensName = "";
        }
      }
    }
  }

  function _getOfferString(uint256 amount, address buyer, uint256 expiration)
    private
    view
    returns (string memory offer)
  {
    offer = string.concat(
      _getETHString(amount),
      " from ",
      _getAddressAndName(buyer),
      " that expires in ",
      _getDeltaTimeString(expiration - block.timestamp)
    );
  }

  function _substring(string memory str, uint256 startIndex, uint256 endIndex)
    private
    pure
    returns (bytes memory result)
  {
    bytes memory strBytes = bytes(str);
    result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; ++i) {
      result[i - startIndex] = strBytes[i];
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Interface for the main ENS contract
 */
interface IENS {
  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);

  function setResolver(bytes32 node, address resolver) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Interface for the main ENS resolver contract.
 */
interface IPublicResolver {
  function setAddr(bytes32 node, address a) external;

  function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Interface for the main ENS reverse registrar contract.
 */
interface IReverseRegistrar {
  function setName(string memory name) external;

  function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

interface IERC20Approve {
  function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

interface IERC20IncreaseAllowance {
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice Interface for functions the market uses in FETH.
 * @author batu-inal & HardlyDifficult
 */
interface IFethMarket {
  function depositFor(address account) external payable;

  function marketLockupFor(address account, uint256 amount) external payable returns (uint256 expiration);

  function marketWithdrawFrom(address from, uint256 amount) external;

  function marketWithdrawLocked(address account, uint256 expiration, uint256 amount) external;

  function marketUnlockFor(address account, uint256 expiration, uint256 amount) external;

  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address lockupFor,
    uint256 lockupAmount
  ) external payable returns (uint256 expiration);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @author batu-inal & HardlyDifficult
 */
interface INFTCollectionInitializer {
  function initialize(address payable _creator, string memory _name, string memory _symbol) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice The required interface for collections to support the NFTDropMarket.
 * @dev This interface must be registered as a ERC165 supported interface to support the NFTDropMarket.
 * @author batu-inal & HardlyDifficult
 */
interface INFTDropCollectionMint {
  function mintCountTo(uint16 count, address to) external returns (uint256 firstTokenId);

  function numberOfTokensAvailableToMint() external view returns (uint256 count);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 * @author batu-inal & HardlyDifficult
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 * @author batu-inal & HardlyDifficult
 */
interface IOperatorRole {
  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
interface IGetFees {
  /**
   * @notice Get the recipient addresses to which creator royalties should be sent.
   * @dev The expected royalty amounts are communicated with `getFeeBps`.
   * @param tokenId The ID of the NFT to get royalties for.
   * @return recipients An array of addresses to which royalties should be sent.
   */
  function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory recipients);

  /**
   * @notice Get the creator royalty amounts to be sent to each recipient, in basis points.
   * @dev The expected recipients are communicated with `getFeeRecipients`.
   * @param tokenId The ID of the NFT to get royalties for.
   * @return royaltiesInBasisPoints The array of fees to be sent to each recipient, in basis points.
   */
  function getFeeBps(uint256 tokenId) external view returns (uint256[] memory royaltiesInBasisPoints);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

interface IGetRoyalties {
  /**
   * @notice Get the creator royalties to be sent.
   * @dev The data is the same as when calling `getFeeRecipients` and `getFeeBps` separately.
   * @param tokenId The ID of the NFT to get royalties for.
   * @return recipients An array of addresses to which royalties should be sent.
   * @return royaltiesInBasisPoints The array of fees to be sent to each recipient, in basis points.
   */
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory royaltiesInBasisPoints);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice Interface for EIP-2981: NFT Royalty Standard.
 * For more see: https://eips.ethereum.org/EIPS/eip-2981.
 */
interface IRoyaltyInfo {
  /**
   * @notice Get the creator royalties to be sent.
   * @param tokenId The ID of the NFT to get royalties for.
   * @param salePrice The total price of the sale.
   * @return receiver The address to which royalties should be sent.
   * @return royaltyAmount The total amount that should be sent to the `receiver`.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

interface ITokenCreator {
  /**
   * @notice Returns the creator of this NFT collection.
   * @param tokenId The ID of the NFT to get the creator payment address for.
   * @return creator The creator of this collection.
   */
  function tokenCreator(uint256 tokenId) external view returns (address payable creator);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

struct CallWithoutValue {
  address target;
  bytes callData;
}

/**
 * @title A library for address helpers not already covered by the OZ library.
 * @author batu-inal & HardlyDifficult
 */
library AddressLibrary {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /**
   * @notice Calls an external contract with arbitrary data and parse the return value into an address.
   * @param externalContract The address of the contract to call.
   * @param callData The data to send to the contract.
   * @return contractAddress The address of the contract returned by the call.
   */
  function callAndReturnContractAddress(address externalContract, bytes calldata callData)
    internal
    returns (address payable contractAddress)
  {
    bytes memory returnData = externalContract.functionCall(callData);
    contractAddress = abi.decode(returnData, (address));
    require(contractAddress.isContract(), "InternalProxyCall: did not return a contract");
  }

  function callAndReturnContractAddress(CallWithoutValue calldata call)
    internal
    returns (address payable contractAddress)
  {
    contractAddress = callAndReturnContractAddress(call.target, call.callData);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Helper functions for arrays.
 * @author batu-inal & HardlyDifficult
 */
library ArrayLibrary {
  /**
   * @notice Reduces the size of an array if it's greater than the specified max size,
   * using the first maxSize elements.
   */
  function capLength(address payable[] memory data, uint256 maxLength) internal pure {
    if (data.length > maxLength) {
      assembly {
        mstore(data, maxLength)
      }
    }
  }

  /**
   * @notice Reduces the size of an array if it's greater than the specified max size,
   * using the first maxSize elements.
   */
  function capLength(uint256[] memory data, uint256 maxLength) internal pure {
    if (data.length > maxLength) {
      assembly {
        mstore(data, maxLength)
      }
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

error BytesLibrary_Expected_Address_Not_Found();
error BytesLibrary_Start_Location_Too_Large();

/**
 * @title A library for manipulation of byte arrays.
 * @author batu-inal & HardlyDifficult
 */
library BytesLibrary {
  /// @notice An address is 20 bytes long
  uint256 private constant ADDRESS_BYTES_LENGTH = 20;

  /// @notice A signature is 4 bytes long
  uint256 private constant SIGNATURE_BYTES_LENGTH = 4;

  /**
   * @dev Replace the address at the given location in a byte array if the contents at that location
   * match the expected address.
   */
  function replaceAtIf(bytes memory data, uint256 startLocation, address expectedAddress, address newAddress)
    internal
    pure
  {
    unchecked {
      if (startLocation > type(uint256).max - ADDRESS_BYTES_LENGTH) {
        revert BytesLibrary_Start_Location_Too_Large();
      }
      bytes memory expectedData = abi.encodePacked(expectedAddress);
      bytes memory newData = abi.encodePacked(newAddress);
      uint256 dataLocation;
      for (uint256 i = 0; i < ADDRESS_BYTES_LENGTH; ++i) {
        dataLocation = startLocation + i;
        if (data[dataLocation] != expectedData[i]) {
          revert BytesLibrary_Expected_Address_Not_Found();
        }
        data[dataLocation] = newData[i];
      }
    }
  }

  /**
   * @dev Checks if the call data starts with the given function signature.
   */
  function startsWith(bytes memory callData, bytes4 functionSig) internal pure returns (bool) {
    // A signature is 4 bytes long
    if (callData.length < SIGNATURE_BYTES_LENGTH) {
      return false;
    }
    return bytes4(callData) == functionSig;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Library that handles locked balances efficiently using bit packing.
 * @author batu-inal & HardlyDifficult
 */
library LockedBalance {
  /// @dev Tracks an account's total lockup per expiration time.
  struct Lockup {
    uint32 expiration;
    uint96 totalAmount;
  }

  struct Lockups {
    /// @dev Mapping from key to lockups.
    /// i) A key represents 2 lockups. The key for a lockup is `index / 2`.
    ///     For instance, elements with index 25 and 24 would map to the same key.
    /// ii) The `value` for the `key` is split into two 128bits which are used to store the metadata for a lockup.
    mapping(uint256 => uint256) lockups;
  }

  // Masks used to split a uint256 into two equal pieces which represent two individual Lockups.
  uint256 private constant last128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant first128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000;

  // Masks used to retrieve or set the totalAmount value of a single Lockup.
  uint256 private constant firstAmountBitsMask = 0xFFFFFFFF000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant secondAmountBitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;

  /**
   * @notice Clears the lockup at the index.
   */
  function del(Lockups storage lockups, uint256 index) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask);
      }
    }
  }

  /**
   * @notice Sets the Lockup at the provided index.
   */
  function set(Lockups storage lockups, uint256 index, uint256 expiration, uint256 totalAmount) internal {
    unchecked {
      uint256 lockedBalanceBits = totalAmount | (expiration << 96);
      if (index % 2 == 0) {
        // set first 128 bits.
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask) | (lockedBalanceBits << 128);
      } else {
        // set last 128 bits.
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask) | lockedBalanceBits;
      }
    }
  }

  /**
   * @notice Sets only the totalAmount for a lockup at the index.
   */
  function setTotalAmount(Lockups storage lockups, uint256 index, uint256 totalAmount) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & firstAmountBitsMask) | (totalAmount << 128);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & secondAmountBitsMask) | totalAmount;
      }
    }
  }

  /**
   * @notice Returns the Lockup at the provided index.
   * @dev To get the lockup stored in the *first* 128 bits (first slot/lockup):
   *       - we remove the last 128 bits (done by >> 128)
   *      To get the lockup stored in the *last* 128 bits (second slot/lockup):
   *       - we take the last 128 bits (done by % (2**128))
   *      Once the lockup is obtained:
   *       - get `expiration` by peaking at the first 32 bits (done by >> 96)
   *       - get `totalAmount` by peaking at the last 96 bits (done by % (2**96))
   */
  function get(Lockups storage lockups, uint256 index) internal view returns (Lockup memory balance) {
    unchecked {
      uint256 lockupMetadata = lockups.lockups[index / 2];
      if (lockupMetadata == 0) {
        return balance;
      }
      uint128 lockedBalanceBits;
      if (index % 2 == 0) {
        // use first 128 bits.
        lockedBalanceBits = uint128(lockupMetadata >> 128);
      } else {
        // use last 128 bits.
        lockedBalanceBits = uint128(lockupMetadata % (2**128));
      }
      // unpack the bits to retrieve the Lockup.
      balance.expiration = uint32(lockedBalanceBits >> 96);
      balance.totalAmount = uint96(lockedBalanceBits % (2**96));
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Helper library for interacting with Merkle trees & proofs.
 * @author batu-inal & HardlyDifficult & reggieag
 */
library MerkleAddressLibrary {
  using MerkleProof for bytes32[];

  /**
   * @notice Gets the root for a merkle tree comprised only of addresses, using the msg.sender.
   */
  function getMerkleRootForSender(bytes32[] calldata proof) internal view returns (bytes32 root) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    root = proof.processProofCalldata(leaf);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Helpers for working with time.
 * @author batu-inal & HardlyDifficult
 */
library TimeLibrary {
  /**
   * @notice Checks if the given timestamp is in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different than `hasBeenReached` in that it will return false if the expiry is now.
   */
  function hasExpired(uint256 expiry) internal view returns (bool) {
    return expiry < block.timestamp;
  }

  /**
   * @notice Checks if the given timestamp is now or in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different from `hasExpired` in that it will return true if the timestamp is now.
   */
  function hasBeenReached(uint256 timestamp) internal view returns (bool) {
    return timestamp <= block.timestamp;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "../../interfaces/standards/royalties/IGetFees.sol";
import "../../interfaces/standards/royalties/IGetRoyalties.sol";
import "../../interfaces/standards/royalties/IRoyaltyInfo.sol";
import "../../interfaces/standards/royalties/ITokenCreator.sol";

import "../shared/Constants.sol";

/**
 * @title Defines various royalty APIs for broad marketplace support.
 * @author batu-inal & HardlyDifficult
 */
abstract contract CollectionRoyalties is IGetRoyalties, IGetFees, IRoyaltyInfo, ITokenCreator, ERC165Upgradeable {
  /**
   * @inheritdoc IGetFees
   */
  function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory recipients) {
    recipients = new address payable[](1);
    recipients[0] = getTokenCreatorPaymentAddress(tokenId);
  }

  /**
   * @inheritdoc IGetFees
   * @dev The tokenId param is ignored since all NFTs return the same value.
   */
  function getFeeBps(uint256 /* tokenId */) external pure returns (uint256[] memory royaltiesInBasisPoints) {
    royaltiesInBasisPoints = new uint256[](1);
    royaltiesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
  }

  /**
   * @inheritdoc IGetRoyalties
   */
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory royaltiesInBasisPoints)
  {
    recipients = new address payable[](1);
    recipients[0] = getTokenCreatorPaymentAddress(tokenId);
    royaltiesInBasisPoints = new uint256[](1);
    royaltiesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
  }

  /**
   * @notice The address to pay the creator proceeds/royalties for the collection.
   * @param tokenId The ID of the NFT to get the creator payment address for.
   * @return creatorPaymentAddress The address to which royalties should be paid.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    virtual
    returns (address payable creatorPaymentAddress);

  /**
   * @inheritdoc IRoyaltyInfo
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = getTokenCreatorPaymentAddress(tokenId);
    unchecked {
      royaltyAmount = salePrice / ROYALTY_RATIO;
    }
  }

  /**
   * @inheritdoc IERC165Upgradeable
   * @dev Checks the supported royalty interfaces.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool interfaceSupported) {
    interfaceSupported = (interfaceId == type(IRoyaltyInfo).interfaceId ||
      interfaceId == type(ITokenCreator).interfaceId ||
      interfaceId == type(IGetRoyalties).interfaceId ||
      interfaceId == type(IGetFees).interfaceId ||
      super.supportsInterface(interfaceId));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

import "../../interfaces/standards/royalties/ITokenCreator.sol";

/**
 * @title Extends the OZ ERC721 implementation for collections which mint sequential token IDs.
 * @author batu-inal & HardlyDifficult
 */
abstract contract SequentialMintCollection is ITokenCreator, Initializable, ERC721BurnableUpgradeable {
  /****** Slot 0 (after inheritance) ******/
  /**
   * @notice The creator/owner of this NFT collection.
   * @dev This is the default royalty recipient if a different `paymentAddress` was not provided.
   * @return The collection's creator/owner address.
   */
  address payable public owner;

  /**
   * @notice The tokenId of the most recently created NFT.
   * @dev Minting starts at tokenId 1. Each mint will use this value + 1.
   * @return The most recently minted tokenId, or 0 if no NFTs have been minted yet.
   */
  uint32 public latestTokenId;

  /**
   * @notice The max tokenId which can be minted.
   * @dev This max may be less than the final `totalSupply` if 1 or more tokens were burned.
   * @return The max tokenId which can be minted.
   */
  uint32 public maxTokenId;

  /**
   * @notice Tracks how many tokens have been burned.
   * @dev This number is used to calculate the total supply efficiently.
   */
  uint32 private burnCounter;

  /****** End of storage ******/

  /**
   * @notice Emitted when the max tokenId supported by this collection is updated.
   * @param maxTokenId The new max tokenId. All NFTs in this collection will have a tokenId less than
   * or equal to this value.
   */
  event MaxTokenIdUpdated(uint256 indexed maxTokenId);

  /**
   * @notice Emitted when this collection is self destructed by the creator/owner/admin.
   * @param admin The account which requested this contract be self destructed.
   */
  event SelfDestruct(address indexed admin);

  modifier onlyOwner() {
    require(msg.sender == owner, "SequentialMintCollection: Caller is not owner");
    _;
  }

  function _initializeSequentialMintCollection(address payable _creator, uint32 _maxTokenId) internal onlyInitializing {
    owner = _creator;
    maxTokenId = _maxTokenId;
  }

  /**
   * @notice Allows the collection owner to destroy this contract only if
   * no NFTs have been minted yet or the minted NFTs have been burned.
   */
  function _selfDestruct() internal {
    require(totalSupply() == 0, "SequentialMintCollection: Any NFTs minted must be burned first");

    emit SelfDestruct(msg.sender);
    selfdestruct(payable(msg.sender));
  }

  /**
   * @notice Allows the owner to set a max tokenID.
   * This provides a guarantee to collectors about the limit of this collection contract, if applicable.
   * @dev Once this value has been set, it may be decreased but can never be increased.
   * @param _maxTokenId The max tokenId to set, all NFTs must have a tokenId less than or equal to this value.
   */
  function _updateMaxTokenId(uint32 _maxTokenId) internal {
    require(_maxTokenId != 0, "SequentialMintCollection: Max token ID may not be cleared");
    require(maxTokenId == 0 || _maxTokenId < maxTokenId, "SequentialMintCollection: Max token ID may not increase");
    require(latestTokenId <= _maxTokenId, "SequentialMintCollection: Max token ID must be >= last mint");

    maxTokenId = _maxTokenId;
    emit MaxTokenIdUpdated(_maxTokenId);
  }

  function _burn(uint256 tokenId) internal virtual override {
    unchecked {
      // Number of burned tokens cannot exceed latestTokenId which is the same size.
      ++burnCounter;
    }
    super._burn(tokenId);
  }

  /**
   * @inheritdoc ITokenCreator
   * @dev The tokenId param is ignored since all NFTs return the same value.
   */
  function tokenCreator(uint256 /* tokenId */) external view returns (address payable creator) {
    creator = owner;
  }

  /**
   * @notice Returns the total amount of tokens stored by the contract.
   * @dev From the ERC-721 enumerable standard.
   * @return supply The total number of NFTs tracked by this contract.
   */
  function totalSupply() public view returns (uint256 supply) {
    unchecked {
      // Number of tokens minted is always >= burned tokens.
      supply = latestTokenId - burnCounter;
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title A place for common modifiers and functions used by various market mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTDropMarketCore {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../interfaces/internal/INFTDropCollectionMint.sol";

import "../../libraries/MerkleAddressLibrary.sol";
import "../../libraries/TimeLibrary.sol";
import "../shared/Constants.sol";
import "../shared/MarketFees.sol";

/// @param limitPerAccount The limit of tokens an account can purchase.
error NFTDropMarketFixedPriceSale_Cannot_Buy_More_Than_Limit(uint256 limitPerAccount);
/// @param earlyAccessStartTime The time when early access starts, in seconds since the Unix epoch.
error NFTDropMarketFixedPriceSale_Early_Access_Not_Open(uint256 earlyAccessStartTime);
error NFTDropMarketFixedPriceSale_Early_Access_Start_Time_Has_Expired();
/// @param generalAvailabilityStartTime The start time of the general availability period, in seconds since the Unix
/// epoch.
error NFTDropMarketFixedPriceSale_General_Access_Not_Open(uint256 generalAvailabilityStartTime);
error NFTDropMarketFixedPriceSale_General_Access_Start_Time_Must_Come_After_Early_Access();
error NFTDropMarketFixedPriceSale_Invalid_Merkle_Proof();
error NFTDropMarketFixedPriceSale_Invalid_Merkle_Root();
error NFTDropMarketFixedPriceSale_Invalid_Merkle_Tree_URI();
error NFTDropMarketFixedPriceSale_Limit_Per_Account_Must_Be_Set();
error NFTDropMarketFixedPriceSale_Mint_Permission_Required();
error NFTDropMarketFixedPriceSale_Must_Buy_At_Least_One_Token();
error NFTDropMarketFixedPriceSale_Must_Have_Sale_In_Progress();
error NFTDropMarketFixedPriceSale_Must_Not_Be_Sold_Out();
error NFTDropMarketFixedPriceSale_Must_Not_Have_Pending_Sale();
error NFTDropMarketFixedPriceSale_Must_Support_Collection_Mint_Interface();
error NFTDropMarketFixedPriceSale_Must_Support_ERC721();
error NFTDropMarketFixedPriceSale_Only_Callable_By_Collection_Owner();
/// @param mintCost The total cost for this purchase.
error NFTDropMarketFixedPriceSale_Too_Much_Value_Provided(uint256 mintCost);
error NFTDropMarketFixedPriceSale_Tx_Deadline_Expired();

/**
 * @title Allows creators to list a drop collection for sale at a fixed price point.
 * @dev Listing a collection for sale in this market requires the collection to implement
 * the functions in `INFTDropCollectionMint` and to register that interface with ERC165.
 * Additionally the collection must implement access control, or more specifically:
 * `hasRole(bytes32(0), msg.sender)` must return true when called from the creator or admin's account
 * and `hasRole(keccak256("MINTER_ROLE", address(this)))` must return true for this market's address.
 * @author batu-inal & HardlyDifficult & reggieag
 */
abstract contract NFTDropMarketFixedPriceSale is MarketFees {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using ERC165Checker for address;
  using MerkleAddressLibrary for bytes32[];
  using SafeCast for uint256;
  using TimeLibrary for uint256;
  using TimeLibrary for uint32;

  /**
   * @notice Configuration for the terms of the sale.
   */
  struct FixedPriceSaleConfig {
    /**
     * @notice The seller for the drop.
     */
    address payable seller;
    /**
     * @notice The fixed price per NFT in the collection.
     * @dev The maximum price that can be set on an NFT is ~1.2M (2^80/10^18) ETH.
     */
    uint80 price;
    /**
     * @notice The max number of NFTs an account may mint in this sale.
     */
    uint16 limitPerAccount;
    /**
     * @notice Tracks how many NFTs a given user has already minted.
     */
    mapping(address => uint256) userToMintedCount;
    /**
     * @notice The start time of the general availability period, in seconds since the Unix epoch.
     * @dev This must be >= `earlyAccessStartTime`.
     */
    uint32 generalAvailabilityStartTime;
    /**
     * @notice The time when early access purchasing may begin, in seconds since the Unix epoch.
     * @dev This must be <= `generalAvailabilityStartTime`.
     */
    uint32 earlyAccessStartTime;
    /**
     * @notice Merkle roots representing which users have access to purchase during the early access period.
     * @dev There may be many roots supported per sale where each is considered additive as any root may be used to
     * purchase. Note that in our initial implementation we will only support a single root per sale.
     */
    mapping(bytes32 => bool) earlyAccessMerkleRoots;
  }

  /**
   * @notice Stores the current sale information for all drop contracts.
   */
  mapping(address => FixedPriceSaleConfig) private nftContractToFixedPriceSaleConfig;

  /**
   * @notice The `role` type used to validate drop collections have granted this market access to mint.
   * @return `keccak256("MINTER_ROLE")`
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @notice Emitted when a collection is listed for sale.
   * @param nftContract The address of the NFT drop collection.
   * @param seller The address for the seller which listed this for sale.
   * @param price The price per NFT minted.
   * @param limitPerAccount The max number of NFTs an account may have while minting.
   * @param generalAvailabilityStartTime The time at which general purchases are available, in seconds since Unix epoch.
   * @param earlyAccessStartTime The time at which early access purchases are available, in seconds since Unix epoch.
   * @param merkleRoot The merkleRoot used to authorize early access purchases, or 0 if n/a.
   * @param merkleTreeUri The URI for the merkle tree represented by the merkleRoot, or empty if n/a.
   */
  event CreateFixedPriceSale(
    address indexed nftContract,
    address indexed seller,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 earlyAccessStartTime,
    bytes32 merkleRoot,
    string merkleTreeUri
  );

  /**
   * @notice Emitted when NFTs are minted from the drop.
   * @dev The total price paid by the buyer is `totalFees + creatorRev`.
   * @param nftContract The address of the NFT drop collection.
   * @param buyer The address of the buyer.
   * @param firstTokenId The tokenId for the first NFT minted.
   * The other minted tokens are assigned sequentially, so `firstTokenId` - `firstTokenId + count - 1` were minted.
   * @param count The number of NFTs minted.
   * @param totalFees The amount of ETH that was sent to Foundation & referrals for this sale.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   */
  event MintFromFixedPriceDrop(
    address indexed nftContract,
    address indexed buyer,
    uint256 indexed firstTokenId,
    uint256 count,
    uint256 totalFees,
    uint256 creatorRev
  );

  /**
   * @notice Create a fixed price sale drop without an early access period.
   * @param nftContract The address of the NFT drop collection.
   * @param price The price per NFT minted.
   * Set price to 0 for a first come first serve airdrop-like drop.
   * @param limitPerAccount The max number of NFTs an account may have while minting.
   * @dev Notes:
   *   a) The sale is final and can not be updated or canceled.
   *   b) The sale is immediately kicked off.
   *   c) Any collection that abides by `INFTDropCollectionMint` and `IAccessControl` is supported.
   */
  function createFixedPriceSale(address nftContract, uint80 price, uint16 limitPerAccount) external {
    _createFixedPriceSale(nftContract, price, limitPerAccount, block.timestamp, block.timestamp, bytes32(0), "");
  }

  /**
   * @notice Create a fixed price sale drop with an early access period.
   * @param nftContract The address of the NFT drop collection.
   * @param price The price per NFT minted.
   * Set price to 0 for a first come first serve airdrop-like drop.
   * @param limitPerAccount The max number of NFTs an account may have while minting.
   * @param generalAvailabilityStartTime The time at which general purchases are available, in seconds since Unix epoch.
   * Set this to 0 in order to have early access begin as soon as the transaction is mined.
   * This value must be >= `earlyAccessStartTime`.
   * @param earlyAccessStartTime The time at which early access purchases are available, in seconds since Unix epoch.
   * Set this to 0 in order to have early access begin as soon as the transaction is mined.
   * @param merkleRoot The merkleRoot used to authorize early access purchases, or 0 if n/a.
   * @param merkleTreeUri The URI for the merkle tree represented by the merkleRoot, or empty if n/a.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * @dev Notes:
   *   a) The sale is final and can not be updated or canceled.
   *   b) The sale is immediately kicked off.
   *   c) Any collection that abides by `INFTDropCollectionMint` and `IAccessControl` is supported.
   */
  function createFixedPriceSaleWithEarlyAccessAllowlist(
    address nftContract,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 earlyAccessStartTime,
    bytes32 merkleRoot,
    string calldata merkleTreeUri,
    uint256 txDeadlineTime
  ) external {
    if (txDeadlineTime.hasExpired()) {
      revert NFTDropMarketFixedPriceSale_Tx_Deadline_Expired();
    }

    // When earlyAccessStartTime is not specified, default to now.
    if (earlyAccessStartTime == 0) {
      earlyAccessStartTime = block.timestamp;

      // General availability can only start now if there is no early access period for this sale.
      if (generalAvailabilityStartTime == 0) {
        generalAvailabilityStartTime = block.timestamp;
      }
    }

    _createFixedPriceSale(
      nftContract,
      price,
      limitPerAccount,
      generalAvailabilityStartTime,
      earlyAccessStartTime,
      merkleRoot,
      merkleTreeUri
    );
  }

  /**
   * @notice Used to mint `count` number of NFTs from the collection during general availability.
   * @param nftContract The address of the NFT drop collection.
   * @param count The number of NFTs to mint.
   * @param buyReferrer The address which referred this purchase, or address(0) if n/a.
   * @return firstTokenId The tokenId for the first NFT minted.
   * The other minted tokens are assigned sequentially, so `firstTokenId` - `firstTokenId + count - 1` were minted.
   * @dev This call may revert if the collection has sold out, has an insufficient number of tokens available,
   * or if the market's minter permissions were removed.
   * If insufficient msg.value is included, the msg.sender's available FETH token balance will be used.
   */
  function mintFromFixedPriceSale(address nftContract, uint16 count, address payable buyReferrer)
    external
    payable
    returns (uint256 firstTokenId)
  {
    FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];

    // Must be in general access period.
    if (!saleConfig.generalAvailabilityStartTime.hasBeenReached()) {
      revert NFTDropMarketFixedPriceSale_General_Access_Not_Open(saleConfig.generalAvailabilityStartTime);
    }

    firstTokenId = _mintFromFixedPriceSale(saleConfig, nftContract, count, buyReferrer);
  }

  /**
   * @notice Used to mint `count` number of NFTs from the collection during early access.
   * @param nftContract The address of the NFT drop collection.
   * @param count The number of NFTs to mint.
   * @param buyReferrer The address which referred this purchase, or address(0) if n/a.
   * @param proof The merkle proof used to authorize this purchase.
   * @return firstTokenId The tokenId for the first NFT minted.
   * The other minted tokens are assigned sequentially, so `firstTokenId` - `firstTokenId + count - 1` were minted.
   * @dev This call may revert if the collection has sold out, has an insufficient number of tokens available,
   * or if the market's minter permissions were removed.
   * If insufficient msg.value is included, the msg.sender's available FETH token balance will be used.
   */
  function mintFromFixedPriceSaleWithEarlyAccessAllowlist(
    address nftContract,
    uint16 count,
    address payable buyReferrer,
    bytes32[] calldata proof
  ) external payable returns (uint256 firstTokenId) {
    FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];

    // Must be in early access period or beyond.
    if (!saleConfig.earlyAccessStartTime.hasBeenReached()) {
      revert NFTDropMarketFixedPriceSale_Early_Access_Not_Open(saleConfig.earlyAccessStartTime);
    }

    // Skip proof check if in general access period.
    if (!saleConfig.generalAvailabilityStartTime.hasBeenReached()) {
      bytes32 root = proof.getMerkleRootForSender();
      if (!saleConfig.earlyAccessMerkleRoots[root]) {
        revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Proof();
      }
    }

    firstTokenId = _mintFromFixedPriceSale(saleConfig, nftContract, count, buyReferrer);
  }

  /* solhint-disable-next-line code-complexity */
  function _createFixedPriceSale(
    address nftContract,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 earlyAccessStartTime,
    bytes32 merkleRoot,
    string memory merkleTreeUri
  ) internal {
    // Validate input params.
    if (earlyAccessStartTime.hasExpired()) {
      // The start time must be now or in the future.
      revert NFTDropMarketFixedPriceSale_Early_Access_Start_Time_Has_Expired();
    }
    if (earlyAccessStartTime > generalAvailabilityStartTime) {
      // Early access cannot start after general availability.
      revert NFTDropMarketFixedPriceSale_General_Access_Start_Time_Must_Come_After_Early_Access();
    }
    if (limitPerAccount == 0) {
      // A non-zero limit is required.
      revert NFTDropMarketFixedPriceSale_Limit_Per_Account_Must_Be_Set();
    }
    if (earlyAccessStartTime != generalAvailabilityStartTime) {
      // If there is a non-zero early access duration, require a merkle root defining access.
      if (merkleRoot == bytes32(0)) {
        revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Root();
      }
      if (bytes(merkleTreeUri).length == 0) {
        revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Tree_URI();
      }
    } else {
      // If there is no early access duration, the merkle root must not be specified.
      if (merkleRoot != bytes32(0)) {
        revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Root();
      }
      if (bytes(merkleTreeUri).length != 0) {
        revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Tree_URI();
      }
    }

    // Confirm the drop collection is supported
    if (!nftContract.supportsInterface(type(INFTDropCollectionMint).interfaceId)) {
      // Must support the mint interface this market depends on.
      revert NFTDropMarketFixedPriceSale_Must_Support_Collection_Mint_Interface();
    }
    if (!nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId)) {
      // Must be an ERC-721 NFT collection.
      revert NFTDropMarketFixedPriceSale_Must_Support_ERC721();
    }
    if (INFTDropCollectionMint(nftContract).numberOfTokensAvailableToMint() == 0) {
      // Must have at least one token available to mint.
      revert NFTDropMarketFixedPriceSale_Must_Not_Be_Sold_Out();
    }
    if (!IAccessControl(nftContract).hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      // The msg.sender must have permissions to list this collection.
      revert NFTDropMarketFixedPriceSale_Only_Callable_By_Collection_Owner();
    }
    if (!IAccessControl(nftContract).hasRole(MINTER_ROLE, address(this))) {
      // This contract must have been granted permission to mint.
      revert NFTDropMarketFixedPriceSale_Mint_Permission_Required();
    }

    // Confirm this collection has not already been listed.
    FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];
    if (saleConfig.seller != payable(0)) {
      revert NFTDropMarketFixedPriceSale_Must_Not_Have_Pending_Sale();
    }

    // Save the sale details.
    saleConfig.seller = payable(msg.sender);
    // Any price is supported, including 0.
    saleConfig.price = price.toUint80();
    saleConfig.limitPerAccount = limitPerAccount.toUint16();

    if (generalAvailabilityStartTime != block.timestamp) {
      // If starting now we don't need to write to storage
      saleConfig.generalAvailabilityStartTime = generalAvailabilityStartTime.toUint32();
    }

    // Store early access details if there is a non-zero early access duration.
    if (earlyAccessStartTime != generalAvailabilityStartTime) {
      saleConfig.earlyAccessStartTime = earlyAccessStartTime.toUint32();
      saleConfig.earlyAccessMerkleRoots[merkleRoot] = true;
    }

    emit CreateFixedPriceSale(
      nftContract,
      msg.sender,
      price,
      limitPerAccount,
      generalAvailabilityStartTime,
      earlyAccessStartTime,
      merkleRoot,
      merkleTreeUri
    );
  }

  function _mintFromFixedPriceSale(
    FixedPriceSaleConfig storage saleConfig,
    address nftContract,
    uint16 count,
    address payable buyReferrer
  ) internal returns (uint256 firstTokenId) {
    // Validate input params.
    if (count == 0) {
      revert NFTDropMarketFixedPriceSale_Must_Buy_At_Least_One_Token();
    }

    // Confirm that the buyer will not exceed the limit specified after minting.
    uint256 minted = saleConfig.userToMintedCount[msg.sender] + count;
    if (minted > saleConfig.limitPerAccount) {
      if (saleConfig.limitPerAccount == 0) {
        // Provide a more targeted error if the collection has not been listed.
        revert NFTDropMarketFixedPriceSale_Must_Have_Sale_In_Progress();
      }
      revert NFTDropMarketFixedPriceSale_Cannot_Buy_More_Than_Limit(saleConfig.limitPerAccount);
    }
    saleConfig.userToMintedCount[msg.sender] = minted;

    // Calculate the total cost, considering the `count` requested.
    uint256 mintCost;
    unchecked {
      // Can not overflow as 2^80 * 2^16 == 2^96 max which fits in 256 bits.
      mintCost = uint256(saleConfig.price) * count;
    }

    // The sale price is immutable so the buyer is aware of how much they will be paying when their tx is broadcasted.
    if (msg.value > mintCost) {
      // Since price is known ahead of time, if too much ETH is sent then something went wrong.
      revert NFTDropMarketFixedPriceSale_Too_Much_Value_Provided(mintCost);
    }
    // Withdraw from the user's available FETH balance if insufficient msg.value was included.
    _tryUseFETHBalance(mintCost, false);

    // Mint the NFTs.
    firstTokenId = INFTDropCollectionMint(nftContract).mintCountTo(count, msg.sender);

    // Distribute revenue from this sale.
    (uint256 totalFees, uint256 creatorRev, ) = _distributeFunds(
      nftContract,
      firstTokenId,
      saleConfig.seller,
      mintCost,
      buyReferrer,
      payable(0),
      0
    );

    emit MintFromFixedPriceDrop(nftContract, msg.sender, firstTokenId, count, totalFees, creatorRev);
  }

  /**
   * @notice Returns the max number of NFTs a given account may mint.
   * @param nftContract The address of the NFT drop collection.
   * @param user The address of the user which will be minting.
   * @return numberThatCanBeMinted How many NFTs the user can mint.
   */
  function getAvailableCountFromFixedPriceSale(address nftContract, address user)
    external
    view
    returns (uint256 numberThatCanBeMinted)
  {
    (, , uint256 limitPerAccount, uint256 numberOfTokensAvailableToMint, bool marketCanMint, , ) = getFixedPriceSale(
      nftContract
    );
    if (!marketCanMint) {
      // No one can mint in the current state.
      return 0;
    }
    uint256 mintedCount = nftContractToFixedPriceSaleConfig[nftContract].userToMintedCount[user];
    if (mintedCount >= limitPerAccount) {
      // User has exhausted their limit.
      return 0;
    }

    unchecked {
      numberThatCanBeMinted = limitPerAccount - mintedCount;
    }
    if (numberThatCanBeMinted > numberOfTokensAvailableToMint) {
      // User has more tokens available than the collection has available.
      numberThatCanBeMinted = numberOfTokensAvailableToMint;
    }
  }

  /**
   * @notice Returns details for a drop collection's fixed price sale.
   * @param nftContract The address of the NFT drop collection.
   * @return seller The address of the seller which listed this drop for sale.
   * This value will be address(0) if the collection is not listed or has sold out.
   * @return price The price per NFT minted.
   * @return limitPerAccount The max number of NFTs an account may have while minting.
   * @return numberOfTokensAvailableToMint The number of NFTs available to mint.
   * @return marketCanMint True if this contract has permissions to mint from the given collection.
   * @return generalAvailabilityStartTime The time at which general availability starts.
   * @return earlyAccessStartTime The timestamp at which the allowlist period starts.
   */
  function getFixedPriceSale(address nftContract)
    public
    view
    returns (
      address payable seller,
      uint256 price,
      uint256 limitPerAccount,
      uint256 numberOfTokensAvailableToMint,
      bool marketCanMint,
      uint256 generalAvailabilityStartTime,
      uint256 earlyAccessStartTime
    )
  {
    try INFTDropCollectionMint(nftContract).numberOfTokensAvailableToMint() returns (uint256 count) {
      if (count != 0) {
        try IAccessControl(nftContract).hasRole(MINTER_ROLE, address(this)) returns (bool hasRole) {
          FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];
          seller = saleConfig.seller;
          price = saleConfig.price;
          limitPerAccount = saleConfig.limitPerAccount;
          numberOfTokensAvailableToMint = count;
          marketCanMint = hasRole;
          earlyAccessStartTime = saleConfig.earlyAccessStartTime;
          generalAvailabilityStartTime = saleConfig.generalAvailabilityStartTime;
        } catch // solhint-disable-next-line no-empty-blocks
        {
          // The contract is not supported - return default values.
        }
      }
      // Else minted completed -- return default values.
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Contract not supported or self destructed - return default values
    }
  }

  /**
   * @notice Checks if a given merkle root has been authorized to purchase from a given drop collection.
   * @param nftContract The address of the NFT drop collection.
   * @param merkleRoot The merkle root to check.
   * @return supported True if the merkle root has been authorized.
   */
  function getFixedPriceSaleEarlyAccessAllowlistSupported(address nftContract, bytes32 merkleRoot)
    external
    view
    returns (bool supported)
  {
    supported = nftContractToFixedPriceSaleConfig[nftContract].earlyAccessMerkleRoots[merkleRoot];
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns the seller for a collection if listed and not already sold out.
   */
  function _getSellerOf(address nftContract, uint256 /* tokenId */)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    (seller, , , , , , ) = getFixedPriceSale(nftContract);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketAuction is Initializable {
  /**
   * @notice A global id for auctions of any type.
   */
  uint256 private nextAuctionId;

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This sets the initial auction id to 1, making the first auction cheaper
   * and id 0 represents no auction found.
   */
  function _initializeNFTMarketAuction() internal onlyInitializing {
    nextAuctionId = 1;
  }

  /**
   * @notice Returns id to assign to the next auction.
   */
  function _getNextAndIncrementAuctionId() internal returns (uint256) {
    // AuctionId cannot overflow 256 bits.
    unchecked {
      return nextAuctionId++;
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../shared/MarketFees.sol";
import "../shared/FoundationTreasuryNode.sol";
import "../shared/FETHNode.sol";
import "../shared/MarketSharedCore.sol";
import "../shared/SendValueWithFallbackWithdraw.sol";

import "./NFTMarketCore.sol";

/// @param buyPrice The current buy price set for this NFT.
error NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(uint256 buyPrice);
error NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
error NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
/// @param owner The current owner of this NFT.
error NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(address owner);
/// @param owner The current owner of this NFT.
error NFTMarketBuyPrice_Only_Owner_Can_Set_Price(address owner);
error NFTMarketBuyPrice_Price_Already_Set();
error NFTMarketBuyPrice_Price_Too_High();
/// @param seller The current owner of this NFT.
error NFTMarketBuyPrice_Seller_Mismatch(address seller);

/**
 * @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
 * @notice NFTs with a buy price set are escrowed in the market contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketBuyPrice is
  Initializable,
  FoundationTreasuryNode,
  FETHNode,
  MarketSharedCore,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  MarketFees
{
  using AddressUpgradeable for address payable;

  /// @notice Stores the buy price details for a specific NFT.
  /// @dev The struct is packed into a single slot to optimize gas.
  struct BuyPrice {
    /// @notice The current owner of this NFT which set a buy price.
    /// @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
    address payable seller;
    /// @notice The current buy price set for this NFT.
    uint96 price;
  }

  /// @notice Stores the current buy price for each NFT.
  mapping(address => mapping(uint256 => BuyPrice)) private nftContractToTokenIdToBuyPrice;

  /**
   * @notice Emitted when an NFT is bought by accepting the buy price,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The total buy price that was accepted is `totalFees` + `creatorRev` + `sellerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that purchased the NFT using `buy`.
   * @param seller The address of the seller which originally set the buy price.
   * @param totalFees The amount of ETH that was sent to Foundation & referrals for this sale.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event BuyPriceAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 totalFees,
    uint256 creatorRev,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when the buy price is removed by the owner of an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceCanceled(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is invalidated due to other market activity.
   * @dev This occurs when the buy price is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceInvalidated(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is set by the owner of an NFT.
   * @dev The NFT is transferred into the market contract for escrow unless it was already escrowed,
   * e.g. for auction listing.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param seller The address of the NFT owner which set the buy price.
   * @param price The price of the NFT.
   */
  event BuyPriceSet(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);

  /**
   * @notice Buy the NFT at the set buy price.
   * `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available FETH balance.
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param maxPrice The maximum price to pay for the NFT.
   */
  function buy(address nftContract, uint256 tokenId, uint256 maxPrice) external payable {
    buyV2(nftContract, tokenId, maxPrice, payable(0));
  }

  /**
   * @notice Buy the NFT at the set buy price.
   * `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available FETH balance.
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param maxPrice The maximum price to pay for the NFT.
   * @param referrer The address of the referrer.
   */
  function buyV2(address nftContract, uint256 tokenId, uint256 maxPrice, address payable referrer) public payable {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.price > maxPrice) {
      revert NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(buyPrice.price);
    } else if (buyPrice.seller == address(0)) {
      revert NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
    }

    _buy(nftContract, tokenId, referrer);
  }

  /**
   * @notice Removes the buy price set for an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  function cancelBuyPrice(address nftContract, uint256 tokenId) external nonReentrant {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // This check is redundant with the next one, but done in order to provide a more clear error message.
      revert NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
    } else if (seller != msg.sender) {
      revert NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(seller);
    }

    // Remove the buy price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Transfer the NFT back to the owner if it is not listed in auction.
    _transferFromEscrowIfAvailable(nftContract, tokenId, msg.sender);

    emit BuyPriceCanceled(nftContract, tokenId);
  }

  /**
   * @notice Sets the buy price for an NFT and escrows it in the market contract.
   * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
   * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The price at which someone could buy this NFT.
   */
  function setBuyPrice(address nftContract, uint256 tokenId, uint256 price) external nonReentrant {
    // If there is a valid offer at this price or higher, accept that instead.
    if (_autoAcceptOffer(nftContract, tokenId, price)) {
      return;
    }

    if (price > type(uint96).max) {
      // This ensures that no data is lost when storing the price as `uint96`.
      revert NFTMarketBuyPrice_Price_Too_High();
    }

    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    address seller = buyPrice.seller;

    if (buyPrice.price == price && seller != address(0)) {
      revert NFTMarketBuyPrice_Price_Already_Set();
    }

    // Store the new price for this NFT.
    buyPrice.price = uint96(price);

    if (seller == address(0)) {
      // Transfer the NFT into escrow, if it's already in escrow confirm the `msg.sender` is the owner.
      _transferToEscrow(nftContract, tokenId);

      // The price was not previously set for this NFT, store the seller.
      buyPrice.seller = payable(msg.sender);
    } else if (seller != msg.sender) {
      // Buy price was previously set by a different user
      revert NFTMarketBuyPrice_Only_Owner_Can_Set_Price(seller);
    }

    emit BuyPriceSet(nftContract, tokenId, msg.sender, price);
  }

  /**
   * @notice If there is a buy price at this price or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(address nftContract, uint256 tokenId, uint256 maxPrice)
    internal
    override
    returns (bool)
  {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.seller == address(0) || buyPrice.price > maxPrice) {
      // No buy price was found, or the price is too high.
      return false;
    }

    _buy(nftContract, tokenId, payable(0));
    return true;
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the buy price on a auction start, if one is found.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.seller != address(0)) {
      // A buy price was set for this NFT, invalidate it.
      _invalidateBuyPrice(nftContract, tokenId);
    }
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @notice Process the purchase of an NFT at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _buy(address nftContract, uint256 tokenId, address payable referrer) private nonReentrant {
    BuyPrice memory buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Remove the buy now price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Cancel the buyer's offer if there is one in order to free up their FETH balance
    // even if they don't need the FETH for this specific purchase.
    _cancelSendersOffer(nftContract, tokenId);

    _tryUseFETHBalance(buyPrice.price, true);

    // Transfer the NFT to the buyer.
    // The seller was already authorized when the buyPrice was set originally set.
    _transferFromEscrow(nftContract, tokenId, msg.sender, address(0));

    // Distribute revenue for this sale.
    (uint256 totalFees, uint256 creatorRev, uint256 sellerRev) = _distributeFunds(
      nftContract,
      tokenId,
      buyPrice.seller,
      buyPrice.price,
      referrer,
      payable(0),
      0
    );

    emit BuyPriceAccepted(nftContract, tokenId, buyPrice.seller, msg.sender, totalFees, creatorRev, sellerRev);
  }

  /**
   * @notice Clear a buy price and emit BuyPriceInvalidated.
   * @dev The caller must confirm the buy price is set before calling this function.
   */
  function _invalidateBuyPrice(address nftContract, uint256 tokenId) private {
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    emit BuyPriceInvalidated(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the buy price if one is found before transferring the NFT.
   * This will revert if there is a buy price set but the `authorizeSeller` is not the owner.
   */
  function _transferFromEscrow(address nftContract, uint256 tokenId, address recipient, address authorizeSeller)
    internal
    virtual
    override
  {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller != address(0)) {
      // A buy price was set for this NFT.
      // `authorizeSeller != address(0) &&` could be added when other mixins use this flow.
      // ATM that additional check would never return false.
      if (seller != authorizeSeller) {
        // When there is a buy price set, the `buyPrice.seller` is the owner of the NFT.
        revert NFTMarketBuyPrice_Seller_Mismatch(seller);
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);

      // Invalidate the buy price as the NFT will no longer be in escrow.
      _invalidateBuyPrice(nftContract, tokenId);
    }

    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if there is a buy price set, if not then allow the transfer to proceed.
   */
  function _transferFromEscrowIfAvailable(address nftContract, uint256 tokenId, address recipient)
    internal
    virtual
    override
  {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // A buy price has been set for this NFT so it should remain in escrow.
      super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if the NFT is already in escrow for buy now.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // The NFT is not in escrow for buy now.
      super._transferToEscrow(nftContract, tokenId);
    } else if (seller != msg.sender) {
      // When there is a buy price set, the `seller` is the owner of the NFT.
      revert NFTMarketBuyPrice_Seller_Mismatch(seller);
    }
  }

  /**
   * @notice Returns the buy price details for an NFT if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return seller The address of the owner that listed a buy price for this NFT.
   * Returns `address(0)` if there is no buy price set for this NFT.
   * @return price The price of the NFT.
   * Returns max uint256 if there is no buy price set for this NFT (since a price of 0 is supported).
   */
  function getBuyPrice(address nftContract, uint256 tokenId) external view returns (address seller, uint256 price) {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      return (seller, type(uint256).max);
    }
    price = nftContractToTokenIdToBuyPrice[nftContract][tokenId].price;
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns the seller if there is a buy price set for this NFT, otherwise
   * bubbles the call up for other considerations.
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override(MarketSharedCore, NFTMarketCore)
    returns (address payable seller)
  {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      seller = super._getSellerOf(nftContract, tokenId);
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/internal/IFethMarket.sol";

import "../shared/Constants.sol";
import "../shared/MarketSharedCore.sol";

error NFTMarketCore_Seller_Not_Found();

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketCore is Initializable, MarketSharedCore {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /**
   * @notice If there is a buy price at this amount or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(address nftContract, uint256 tokenId, uint256 amount) internal virtual returns (bool);

  /**
   * @notice If there is a valid offer at the given price or higher, accept that and return true.
   */
  function _autoAcceptOffer(address nftContract, uint256 tokenId, uint256 minAmount) internal virtual returns (bool);

  /**
   * @notice Notify implementors when an auction has received its first bid.
   * Once a bid is received the sale is guaranteed to the auction winner
   * and other sale mechanisms become unavailable.
   * @dev Implementors of this interface should update internal state to reflect an auction has been kicked off.
   */
  function _beforeAuctionStarted(
    address /*nftContract*/,
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @notice Cancel the `msg.sender`'s offer if there is one, freeing up their FETH balance.
   * @dev This should be used when it does not make sense to keep the original offer around,
   * e.g. if a collector accepts a Buy Price then keeping the offer around is not necessary.
   */
  function _cancelSendersOffer(address nftContract, uint256 tokenId) internal virtual;

  /**
   * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
   * @param authorizeSeller The address of the seller pending authorization.
   * Once it's been authorized by one of the escrow managers, it should be set to address(0)
   * indicated that it's no longer pending authorization.
   */
  function _transferFromEscrow(address nftContract, uint256 tokenId, address recipient, address authorizeSeller)
    internal
    virtual
  {
    if (authorizeSeller != address(0)) {
      revert NFTMarketCore_Seller_Not_Found();
    }
    IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
  }

  /**
   * @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(address nftContract, uint256 tokenId, address recipient) internal virtual {
    _transferFromEscrow(nftContract, tokenId, recipient, address(0));
  }

  /**
   * @notice Transfers an NFT into escrow,
   * if already there this requires the msg.sender is authorized to manage the sale of this NFT.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual {
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

  /**
   * @dev Determines the minimum amount when increasing an existing offer or bid.
   */
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount;
    unchecked {
      minIncrement /= MIN_PERCENT_INCREMENT_DENOMINATOR;
    }
    if (minIncrement == 0) {
      // Since minIncrement reduces from the currentAmount, this cannot overflow.
      // The next amount must be at least 1 wei greater than the current.
      return currentAmount + 1;
    }

    return minIncrement + currentAmount;
  }

  /**
   * @inheritdoc MarketSharedCore
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  // solhint-disable-next-line no-empty-blocks
  {
    // No-op by default
  }

  /**
   * @inheritdoc MarketSharedCore
   */
  function _getSellerOrOwnerOf(address nftContract, uint256 tokenId)
    internal
    view
    override
    returns (address payable sellerOrOwner)
  {
    sellerOrOwner = _getSellerOf(nftContract, tokenId);
    if (sellerOrOwner == address(0)) {
      sellerOrOwner = payable(IERC721(nftContract).ownerOf(tokenId));
    }
  }

  /**
   * @notice Checks if an escrowed NFT is currently in active auction.
   * @return Returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view virtual returns (bool);

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 50 slots were consumed by adding `ReentrancyGuard`.
   */
  uint256[450] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

error NFTMarketExhibition_Allowlist_Already_Initialized();
/// @param curator The curator for this exhibition.
error NFTMarketExhibition_Caller_Is_Not_Curator(address curator);
error NFTMarketExhibition_Can_Not_Add_Dupe_Seller();
error NFTMarketExhibition_Curator_Automatically_Allowed();
error NFTMarketExhibition_Exhibition_Does_Not_Exist();
error NFTMarketExhibition_Seller_Not_Allowed_In_Exhibition();
error NFTMarketExhibition_Sellers_Required();
error NFTMarketExhibition_Take_Rate_Too_High();
error NFTMarketExhibition_Too_Many_Sellers();

/// @dev The max take rate an exhibition can have.
uint256 constant MAX_TAKE_RATE = 5_000;
/// @dev The max number of sellers that can be approved for an exhibition.
uint256 constant MAX_SELLER_LIST_LENGTH = 50;

/**
 * @title Enables a curation surface for sellers to exhibit their NFTs.
 */
abstract contract NFTMarketExhibition {
  /**
   * @notice Stores details about an exhibition.
   */
  struct Exhibition {
    /// @notice The curator which created this exhibition.
    address payable curator;
    /// @notice The rate of the sale which goes to the curator.
    uint16 takeRateInBasisPoints;
    // 80-bits available in the first slot

    /// @notice A name for the exhibition.
    string name;
  }

  /// @notice Tracks the next sequence ID to be assigned to an exhibition.
  uint256 private latestExhibitionId;

  /// @notice Maps the exhibition ID to their details.
  mapping(uint256 => Exhibition) private idToExhibition;

  /// @notice Maps an exhibition to the list of sellers allowed to list with it.
  mapping(uint256 => mapping(address => bool)) private exhibitionIdToSellerToIsAllowed;

  /// @notice Maps an NFT to the exhibition it was listed with.
  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToExhibitionId;

  /**
   * @notice Emitted when an exhibition is created.
   * @param exhibitionId The ID for this exhibition.
   * @param curator The curator which created this exhibition.
   * @param name The name for this exhibition.
   * @param takeRateInBasisPoints The rate of the sale which goes to the curator.
   */
  event ExhibitionCreated(
    uint256 indexed exhibitionId,
    address indexed curator,
    string name,
    uint16 takeRateInBasisPoints
  );

  /**
   * @notice Emitted when an exhibition is deleted.
   * @param exhibitionId The ID for the exhibition.
   */
  event ExhibitionDeleted(uint256 indexed exhibitionId);

  /**
   * @notice Emitted when an NFT is listed in an exhibition.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   * @param exhibitionId The ID of the exhibition it was listed with.
   */
  event NftAddedToExhibition(address indexed nftContract, uint256 indexed tokenId, uint256 indexed exhibitionId);

  /**
   * @notice Emitted when an NFT is no longer associated with an exhibition for reasons other than a sale.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   */
  event NftRemovedFromExhibition(address indexed nftContract, uint256 indexed tokenId, uint256 indexed exhibitionId);

  /**
   * @notice Emitted when sellers are granted access to list with an exhibition.
   * @param exhibitionId The ID of the exhibition.
   * @param sellers The list of sellers granted access.
   */
  event SellersAddedToExhibition(uint256 indexed exhibitionId, address[] sellers);

  modifier onlyExhibitionCurator(uint256 exhibitionId) {
    address curator = idToExhibition[exhibitionId].curator;
    if (curator == address(0)) {
      revert NFTMarketExhibition_Exhibition_Does_Not_Exist();
    }
    if (curator != msg.sender) {
      revert NFTMarketExhibition_Caller_Is_Not_Curator(curator);
    }
    _;
  }

  /**
   * @notice Creates an exhibition.
   * @param name The name for this exhibition.
   * @param takeRateInBasisPoints The rate of the sale which goes to the msg.sender as the curator of this exhibition.
   * @param sellers The list of sellers allowed to list with this exhibition.
   * @dev The list of sellers may not be modified after the exhibition is created.
   */
  function createExhibition(string calldata name, uint16 takeRateInBasisPoints, address[] calldata sellers)
    external
    returns (uint256 exhibitionId)
  {
    if (takeRateInBasisPoints > MAX_TAKE_RATE) {
      revert NFTMarketExhibition_Take_Rate_Too_High();
    }
    uint256 listLength = sellers.length;
    if (listLength == 0) {
      revert NFTMarketExhibition_Sellers_Required();
    }
    if (listLength > MAX_SELLER_LIST_LENGTH) {
      revert NFTMarketExhibition_Too_Many_Sellers();
    }

    // Create exhibition
    unchecked {
      exhibitionId = ++latestExhibitionId;
    }
    idToExhibition[exhibitionId] = Exhibition({
      curator: payable(msg.sender),
      takeRateInBasisPoints: takeRateInBasisPoints,
      name: name
    });
    emit ExhibitionCreated(exhibitionId, msg.sender, name, takeRateInBasisPoints);

    // Populate allow list
    address curator = idToExhibition[exhibitionId].curator;
    for (uint256 i = 0; i < listLength; ) {
      address seller = sellers[i];
      if (exhibitionIdToSellerToIsAllowed[exhibitionId][seller]) {
        revert NFTMarketExhibition_Can_Not_Add_Dupe_Seller();
      }
      if (seller == curator) {
        revert NFTMarketExhibition_Curator_Automatically_Allowed();
      }
      exhibitionIdToSellerToIsAllowed[exhibitionId][seller] = true;
      unchecked {
        ++i;
      }
    }
    emit SellersAddedToExhibition(exhibitionId, sellers);
  }

  /**
   * @notice Deletes an exhibition created by the msg.sender.
   * @param exhibitionId The ID of the exhibition to delete.
   * @dev Once deleted, any NFTs listed with this exhibition will still be listed but will no longer be associated with
   * or share revenue with the exhibition.
   */
  function deleteExhibition(uint256 exhibitionId) external onlyExhibitionCurator(exhibitionId) {
    delete idToExhibition[exhibitionId];
    emit ExhibitionDeleted(exhibitionId);
  }

  /**
   * @notice Assigns an NFT to an exhibition.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   * @param exhibitionId The ID of the exhibition to list the NFT with.
   */
  function _addNftToExhibition(address nftContract, uint256 tokenId, uint256 exhibitionId) internal {
    if (exhibitionId != 0) {
      Exhibition storage exhibition = idToExhibition[exhibitionId];
      if (exhibition.curator == address(0)) {
        revert NFTMarketExhibition_Exhibition_Does_Not_Exist();
      }
      if (!exhibitionIdToSellerToIsAllowed[exhibitionId][msg.sender] && exhibition.curator != msg.sender) {
        revert NFTMarketExhibition_Seller_Not_Allowed_In_Exhibition();
      }
      nftContractToTokenIdToExhibitionId[nftContract][tokenId] = exhibitionId;
      emit NftAddedToExhibition(nftContract, tokenId, exhibitionId);
    }
  }

  /**
   * @notice Returns exhibition details if this NFT was assigned to one, and clears the assignment.
   * @return paymentAddress The address to send the payment to, or address(0) if n/a.
   * @return takeRateInBasisPoints The rate of the sale which goes to the curator, or 0 if n/a.
   */
  function _getAndRemoveNftFromExhibition(address nftContract, uint256 tokenId)
    internal
    returns (address payable paymentAddress, uint16 takeRateInBasisPoints)
  {
    uint256 exhibitionId = nftContractToTokenIdToExhibitionId[nftContract][tokenId];
    if (exhibitionId != 0) {
      paymentAddress = idToExhibition[exhibitionId].curator;
      takeRateInBasisPoints = idToExhibition[exhibitionId].takeRateInBasisPoints;
      delete nftContractToTokenIdToExhibitionId[nftContract][tokenId];
    }
  }

  /**
   * @notice Clears an NFT's association with an exhibition.
   */
  function _removeNftFromExhibition(address nftContract, uint256 tokenId) internal {
    uint256 exhibitionId = nftContractToTokenIdToExhibitionId[nftContract][tokenId];
    if (exhibitionId != 0) {
      delete nftContractToTokenIdToExhibitionId[nftContract][tokenId];
      emit NftRemovedFromExhibition(nftContract, tokenId, exhibitionId);
    }
  }

  /**
   * @notice Returns exhibition details for a given ID.
   * @param exhibitionId The ID of the exhibition to look up.
   * @return name The name of the exhibition.
   * @return curator The curator of the exhibition.
   * @return takeRateInBasisPoints The rate of the sale which goes to the curator.
   */
  function getExhibition(uint256 exhibitionId)
    external
    view
    returns (string memory name, address payable curator, uint16 takeRateInBasisPoints)
  {
    Exhibition memory exhibition = idToExhibition[exhibitionId];
    name = exhibition.name;
    curator = exhibition.curator;
    takeRateInBasisPoints = exhibition.takeRateInBasisPoints;
  }

  /**
   * @notice Returns the exhibition ID for a given NFT.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   * @return exhibitionId The ID of the exhibition this NFT is assigned to, or 0 if it's not assigned to an exhibition.
   */
  function getExhibitionIdForNft(address nftContract, uint256 tokenId) external view returns (uint256 exhibitionId) {
    exhibitionId = nftContractToTokenIdToExhibitionId[nftContract][tokenId];
  }

  /**
   * @notice Checks if a given seller is approved to list with a given exhibition.
   * @param exhibitionId The ID of the exhibition to check.
   * @param seller The address of the seller to check.
   * @return allowedSeller True if the seller is approved to list with the exhibition.
   */
  function isAllowedSellerForExhibition(uint256 exhibitionId, address seller)
    external
    view
    returns (bool allowedSeller)
  {
    address curator = idToExhibition[exhibitionId].curator;
    if (curator != address(0)) {
      allowedSeller = exhibitionIdToSellerToIsAllowed[exhibitionId][seller] || seller == curator;
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 500 slots.
   */
  uint256[496] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../libraries/TimeLibrary.sol";

import "../shared/MarketFees.sol";
import "../shared/FoundationTreasuryNode.sol";
import "../shared/FETHNode.sol";
import "../shared/SendValueWithFallbackWithdraw.sol";

import "./NFTMarketCore.sol";

error NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
/// @param currentOfferAmount The current highest offer available for this NFT.
error NFTMarketOffer_Offer_Below_Min_Amount(uint256 currentOfferAmount);
/// @param expiry The time at which the offer had expired.
error NFTMarketOffer_Offer_Expired(uint256 expiry);
/// @param currentOfferFrom The address of the collector which has made the current highest offer.
error NFTMarketOffer_Offer_From_Does_Not_Match(address currentOfferFrom);
/// @param minOfferAmount The minimum amount that must be offered in order for it to be accepted.
error NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(uint256 minOfferAmount);

/**
 * @title Allows collectors to make an offer for an NFT, valid for 24-25 hours.
 * @notice Funds are escrowed in the FETH ERC-20 token contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketOffer is
  Initializable,
  FoundationTreasuryNode,
  FETHNode,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  MarketFees
{
  using AddressUpgradeable for address;
  using TimeLibrary for uint32;

  /// @notice Stores offer details for a specific NFT.
  struct Offer {
    // Slot 1: When increasing an offer, only this slot is updated.
    /// @notice The expiration timestamp of when this offer expires.
    uint32 expiration;
    /// @notice The amount, in wei, of the highest offer.
    uint96 amount;
    /// @notice First slot (of 16B) used for the offerReferrerAddress.
    // The offerReferrerAddress is the address used to pay the
    // referrer on an accepted offer.
    uint128 offerReferrerAddressSlot0;
    // Slot 2: When the buyer changes, both slots need updating
    /// @notice The address of the collector who made this offer.
    address buyer;
    /// @notice Second slot (of 4B) used for the offerReferrerAddress.
    uint32 offerReferrerAddressSlot1;
    // 96 bits (12B) are available in slot 1.
  }

  /// @notice Stores the highest offer for each NFT.
  mapping(address => mapping(uint256 => Offer)) private nftContractToIdToOffer;

  /**
   * @notice Emitted when an offer is accepted,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The accepted total offer amount is `totalFees` + `creatorRev` + `sellerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that made the offer which was accepted.
   * @param seller The address of the seller which accepted the offer.
   * @param totalFees The amount of ETH that was sent to Foundation & referrals for this sale.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event OfferAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    address seller,
    uint256 totalFees,
    uint256 creatorRev,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when an offer is invalidated due to other market activity.
   * When this occurs, the collector which made the offer has their FETH balance unlocked
   * and the funds are available to place other offers or to be withdrawn.
   * @dev This occurs when the offer is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event OfferInvalidated(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when an offer is made.
   * @dev The `amount` of the offer is locked in the FETH ERC-20 contract, guaranteeing that the funds
   * remain available until the `expiration` date.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that made the offer to buy this NFT.
   * @param amount The amount, in wei, of the offer.
   * @param expiration The expiration timestamp for the offer.
   */
  event OfferMade(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 amount,
    uint256 expiration
  );

  /**
   * @notice Accept the highest offer for an NFT.
   * @dev The offer must not be expired and the NFT owned + approved by the seller or
   * available in the market contract's escrow.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param offerFrom The address of the collector that you wish to sell to.
   * If the current highest offer is not from this user, the transaction will revert.
   * This could happen if a last minute offer was made by another collector,
   * and would require the seller to try accepting again.
   * @param minAmount The minimum value of the highest offer for it to be accepted.
   * If the value is less than this amount, the transaction will revert.
   * This could happen if the original offer expires and is replaced with a smaller offer.
   */
  function acceptOffer(address nftContract, uint256 tokenId, address offerFrom, uint256 minAmount)
    external
    nonReentrant
  {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    // Validate offer expiry and amount
    if (offer.expiration.hasExpired()) {
      revert NFTMarketOffer_Offer_Expired(offer.expiration);
    } else if (offer.amount < minAmount) {
      revert NFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    }
    // Validate the buyer
    if (offer.buyer != offerFrom) {
      revert NFTMarketOffer_Offer_From_Does_Not_Match(offer.buyer);
    }

    _acceptOffer(nftContract, tokenId);
  }

  /**
   * @notice Make an offer for any NFT which is valid for 24-25 hours.
   * The funds will be locked in the FETH token contract and become available once the offer is outbid or has expired.
   * @dev An offer may be made for an NFT before it is minted, although we generally not recommend you do that.
   * If there is a buy price set at this price or lower, that will be accepted instead of making an offer.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available FETH balance.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param amount The amount to offer for this NFT.
   * @param referrer The refrerrer address for the offer.
   * @return expiration The timestamp for when this offer will expire.
   * This is provided as a return value in case another contract would like to leverage this information,
   * user's should refer to the expiration in the `OfferMade` event log.
   * If the buy price is accepted instead, `0` is returned as the expiration since that's n/a.
   */
  function makeOfferV2(address nftContract, uint256 tokenId, uint256 amount, address payable referrer)
    external
    payable
    returns (uint256 expiration)
  {
    // If there is a buy price set at this price or lower, accept that instead.
    if (_autoAcceptBuyPrice(nftContract, tokenId, amount)) {
      // If the buy price is accepted, `0` is returned as the expiration since that's n/a.
      return 0;
    }

    if (_isInActiveAuction(nftContract, tokenId)) {
      revert NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
    }

    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];

    if (offer.expiration.hasExpired()) {
      // This is a new offer for the NFT (no other offer found or the previous offer expired)

      // Lock the offer amount in FETH until the offer expires in 24-25 hours.
      expiration = feth.marketLockupFor{ value: msg.value }(msg.sender, amount);
    } else {
      // A previous offer exists and has not expired

      uint256 minIncrement = _getMinIncrement(offer.amount);
      if (amount < minIncrement) {
        // A non-trivial increase in price is required to avoid sniping
        revert NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(minIncrement);
      }

      // Unlock the previous offer so that the FETH tokens are available for other offers or to transfer / withdraw
      // and lock the new offer amount in FETH until the offer expires in 24-25 hours.
      expiration = feth.marketChangeLockup{ value: msg.value }(
        offer.buyer,
        offer.expiration,
        offer.amount,
        msg.sender,
        amount
      );
    }

    // Record offer details
    offer.buyer = msg.sender;
    // The FETH contract guarantees that the expiration fits into 32 bits.
    offer.expiration = uint32(expiration);
    // `amount` is capped by the ETH provided, which cannot realistically overflow 96 bits.
    offer.amount = uint96(amount);
    // Set offerReferrerAddressSlot0 to the first 16B of the referrer address.
    // By shifting the referrer 32 bits to the right we obtain the first 16B.
    offer.offerReferrerAddressSlot0 = uint128(uint160(address(referrer)) >> 32);
    // Set offerReferrerAddressSlot1 to the last 4B of the referrer address.
    // By casting the referrer address to 32bits we discard the first 16B.
    offer.offerReferrerAddressSlot1 = uint32(uint160(address(referrer)));

    emit OfferMade(nftContract, tokenId, msg.sender, amount, expiration);
  }

  /**
   * @notice Accept the highest offer for an NFT from the `msg.sender` account.
   * The NFT will be transferred to the buyer and revenue from the sale will be distributed.
   * @dev The caller must validate the expiry and amount before calling this helper.
   * This may invalidate other market tools, such as clearing the buy price if set.
   */
  function _acceptOffer(address nftContract, uint256 tokenId) private {
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];

    // Remove offer
    delete nftContractToIdToOffer[nftContract][tokenId];
    // Withdraw ETH from the buyer's account in the FETH token contract.
    feth.marketWithdrawLocked(offer.buyer, offer.expiration, offer.amount);

    // Transfer the NFT to the buyer.
    try
      IERC721(nftContract).transferFrom(msg.sender, offer.buyer, tokenId) // solhint-disable-next-line no-empty-blocks
    {
      // NFT was in the seller's wallet so the transfer is complete.
    } catch {
      // If the transfer fails then attempt to transfer from escrow instead.
      // This should revert if `msg.sender` is not the owner of this NFT.
      _transferFromEscrow(nftContract, tokenId, offer.buyer, msg.sender);
    }

    // Distribute revenue for this sale leveraging the ETH received from the FETH contract in the line above.
    (uint256 totalFees, uint256 creatorRev, uint256 sellerRev) = _distributeFunds(
      nftContract,
      tokenId,
      payable(msg.sender),
      offer.amount,
      _getOfferReferrerFromSlots(offer.offerReferrerAddressSlot0, offer.offerReferrerAddressSlot1),
      payable(0),
      0
    );

    emit OfferAccepted(nftContract, tokenId, offer.buyer, msg.sender, totalFees, creatorRev, sellerRev);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the highest offer when an auction is kicked off, if one is found.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateOffer(nftContract, tokenId);
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _autoAcceptOffer(address nftContract, uint256 tokenId, uint256 minAmount) internal override returns (bool) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration.hasExpired() || offer.amount < minAmount) {
      // No offer found, the most recent offer is now expired, or the highest offer is below the minimum amount.
      return false;
    }

    _acceptOffer(nftContract, tokenId);
    return true;
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _cancelSendersOffer(address nftContract, uint256 tokenId) internal override {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.buyer == msg.sender) {
      _invalidateOffer(nftContract, tokenId);
    }
  }

  /**
   * @notice Invalidates the offer and frees ETH from escrow, if the offer has not already expired.
   * @dev Offers are not invalidated when the NFT is purchased by accepting the buy price unless it
   * was purchased by the same user.
   * The user which just purchased the NFT may have buyer's remorse and promptly decide they want a fast exit,
   * accepting a small loss to limit their exposure.
   */
  function _invalidateOffer(address nftContract, uint256 tokenId) private {
    if (!nftContractToIdToOffer[nftContract][tokenId].expiration.hasExpired()) {
      // An offer was found and it has not already expired
      Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];

      // Remove offer
      delete nftContractToIdToOffer[nftContract][tokenId];

      // Unlock the offer so that the FETH tokens are available for other offers or to transfer / withdraw
      feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);

      emit OfferInvalidated(nftContract, tokenId);
    }
  }

  /**
   * @notice Returns the minimum amount a collector must offer for this NFT in order for the offer to be valid.
   * @dev Offers for this NFT which are less than this value will revert.
   * Once the previous offer has expired smaller offers can be made.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return minimum The minimum amount that must be offered for this NFT.
   */
  function getMinOfferAmount(address nftContract, uint256 tokenId) external view returns (uint256 minimum) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (!offer.expiration.hasExpired()) {
      return _getMinIncrement(offer.amount);
    }
    // Absolute min is anything > 0
    return 1;
  }

  /**
   * @notice Returns details about the current highest offer for an NFT.
   * @dev Default values are returned if there is no offer or the offer has expired.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return buyer The address of the buyer that made the current highest offer.
   * Returns `address(0)` if there is no offer or the most recent offer has expired.
   * @return expiration The timestamp that the current highest offer expires.
   * Returns `0` if there is no offer or the most recent offer has expired.
   * @return amount The amount being offered for this NFT.
   * Returns `0` if there is no offer or the most recent offer has expired.
   */
  function getOffer(address nftContract, uint256 tokenId)
    external
    view
    returns (address buyer, uint256 expiration, uint256 amount)
  {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration.hasExpired()) {
      // Offer not found or has expired
      return (address(0), 0, 0);
    }

    // An offer was found and it has not yet expired.
    return (offer.buyer, offer.expiration, offer.amount);
  }

  /**
   * @notice Returns the current highest offer's referral for an NFT.
   * @dev Default value of `payable(0)` is returned if
   * there is no offer, the offer has expired or does not have a referral.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return referrer The payable address of the referrer for the offer.
   */
  function getOfferReferrer(address nftContract, uint256 tokenId) external view returns (address payable referrer) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration.hasExpired()) {
      // Offer not found or has expired
      return payable(0);
    }
    return _getOfferReferrerFromSlots(offer.offerReferrerAddressSlot0, offer.offerReferrerAddressSlot1);
  }

  function _getOfferReferrerFromSlots(uint128 offerReferrerAddressSlot0, uint32 offerReferrerAddressSlot1)
    private
    pure
    returns (address payable referrer)
  {
    // Stitch offerReferrerAddressSlot0 and offerReferrerAddressSlot1 to obtain the payable offerReferrerAddress.
    // Left shift offerReferrerAddressSlot0 by 32 bits OR it with offerReferrerAddressSlot1.
    referrer = payable(address((uint160(offerReferrerAddressSlot0) << 32) | uint160(offerReferrerAddressSlot1)));
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Reserves space previously occupied by private sales.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketPrivateSaleGap {
  // Original data:
  // bytes32 private __gap_was_DOMAIN_SEPARATOR;
  // mapping(address => mapping(uint256 => mapping(address => mapping(address => mapping(uint256 =>
  //   mapping(uint256 => bool)))))) private privateSaleInvalidated;
  // uint256[999] private __gap;

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 1 slot was consumed by privateSaleInvalidated.
   */
  uint256[1001] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../libraries/TimeLibrary.sol";

import "../shared/FoundationTreasuryNode.sol";
import "../shared/FETHNode.sol";
import "../shared/MarketFees.sol";
import "../shared/MarketSharedCore.sol";
import "../shared/SendValueWithFallbackWithdraw.sol";

import "./NFTMarketAuction.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketExhibition.sol";

/// @param auctionId The already listed auctionId for this NFT.
error NFTMarketReserveAuction_Already_Listed(uint256 auctionId);
/// @param minAmount The minimum amount that must be bid in order for it to be accepted.
error NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(uint256 minAmount);
/// @param reservePrice The current reserve price.
error NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(uint256 reservePrice);
/// @param endTime The timestamp at which the auction had ended.
error NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
/// @param endTime The timestamp at which the auction will end.
error NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
error NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
/// @param maxDuration The maximum configuration for a duration of the auction, in seconds.
error NFTMarketReserveAuction_Exceeds_Max_Duration(uint256 maxDuration);
/// @param extensionDuration The extension duration, in seconds.
error NFTMarketReserveAuction_Less_Than_Extension_Duration(uint256 extensionDuration);
error NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
/// @param seller The current owner of the NFT.
error NFTMarketReserveAuction_Not_Matching_Seller(address seller);
/// @param owner The current owner of the NFT.
error NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(address owner);
error NFTMarketReserveAuction_Price_Already_Set();
error NFTMarketReserveAuction_Too_Much_Value_Provided();

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the market contract.
 * @dev There is room to optimize the storage for auctions, significantly reducing gas costs.
 * This may be done in the future, but for now it will remain as is in order to ease upgrade compatibility.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketReserveAuction is
  Initializable,
  FoundationTreasuryNode,
  FETHNode,
  MarketSharedCore,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  MarketFees,
  NFTMarketExhibition,
  NFTMarketAuction
{
  using TimeLibrary for uint256;

  /// @notice The auction configuration for a specific NFT.
  struct ReserveAuction {
    /// @notice The address of the NFT contract.
    address nftContract;
    /// @notice The id of the NFT.
    uint256 tokenId;
    /// @notice The owner of the NFT which listed it in auction.
    address payable seller;
    /// @notice The duration for this auction.
    uint256 duration;
    /// @notice The extension window for this auction.
    uint256 extensionDuration;
    /// @notice The time at which this auction will not accept any new bids.
    /// @dev This is `0` until the first bid is placed.
    uint256 endTime;
    /// @notice The current highest bidder in this auction.
    /// @dev This is `address(0)` until the first bid is placed.
    address payable bidder;
    /// @notice The latest price of the NFT in this auction.
    /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
    uint256 amount;
  }

  /// @notice Stores the auction configuration for a specific NFT.
  /// @dev This allows us to modify the storage struct without changing external APIs.
  struct ReserveAuctionStorage {
    /// @notice The address of the NFT contract.
    address nftContract;
    /// @notice The id of the NFT.
    uint256 tokenId;
    /// @notice The owner of the NFT which listed it in auction.
    address payable seller;
    /// @notice First slot (of 12B) used for the bidReferrerAddress.
    /// The bidReferrerAddress is the address used to pay the referrer on finalize.
    /// @dev This approach is used in order to pack storage, saving gas.
    uint96 bidReferrerAddressSlot0;
    /// @dev This field is no longer used.
    uint256 __gap_was_duration;
    /// @dev This field is no longer used.
    uint256 __gap_was_extensionDuration;
    /// @notice The time at which this auction will not accept any new bids.
    /// @dev This is `0` until the first bid is placed.
    uint256 endTime;
    /// @notice The current highest bidder in this auction.
    /// @dev This is `address(0)` until the first bid is placed.
    address payable bidder;
    /// @notice Second slot (of 8B) used for the bidReferrerAddress.
    uint64 bidReferrerAddressSlot1;
    /// @notice The latest price of the NFT in this auction.
    /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
    uint256 amount;
  }

  /// @notice The auction configuration for a specific auction id.
  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
  /// @notice The auction id for a specific NFT.
  /// @dev This is deleted when an auction is finalized or canceled.
  mapping(uint256 => ReserveAuctionStorage) private auctionIdToAuction;

  /**
   * @dev Removing old unused variables in an upgrade safe way. Was:
   * uint256 private __gap_was_minPercentIncrementInBasisPoints;
   * uint256 private __gap_was_maxBidIncrementRequirement;
   * uint256 private __gap_was_duration;
   * uint256 private __gap_was_extensionDuration;
   * uint256 private __gap_was_goLiveDate;
   */
  uint256[5] private __gap_was_config;

  /// @notice How long an auction lasts for once the first bid has been received.
  uint256 private immutable DURATION;

  /// @notice The window for auction extensions, any bid placed in the final 15 minutes
  /// of an auction will reset the time remaining to 15 minutes.
  uint256 private constant EXTENSION_DURATION = 15 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 private constant MAX_MAX_DURATION = 1_000 days;

  /**
   * @notice Emitted when a bid is placed.
   * @param auctionId The id of the auction this bid was for.
   * @param bidder The address of the bidder.
   * @param amount The amount of the bid.
   * @param endTime The new end time of the auction (which may have been set or extended by this bid).
   */
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  /**
   * @notice Emitted when an auction is canceled.
   * @dev This is only possible if the auction has not received any bids.
   * @param auctionId The id of the auction that was canceled.
   */
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  /**
   * @notice Emitted when an NFT is listed for auction.
   * @param seller The address of the seller.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param duration The duration of the auction (always 24-hours).
   * @param extensionDuration The duration of the auction extension window (always 15-minutes).
   * @param reservePrice The reserve price to kick off the auction.
   * @param auctionId The id of the auction that was created.
   */
  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  /**
   * @notice Emitted when an auction that has already ended is finalized,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The amount of the highest bid / final sale price for this auction
   * is `totalFees` + `creatorRev` + `sellerRev`.
   * @param auctionId The id of the auction that was finalized.
   * @param seller The address of the seller.
   * @param bidder The address of the highest bidder that won the NFT.
   * @param totalFees The amount of ETH that was sent to Foundation & referrals for this sale.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 totalFees,
    uint256 creatorRev,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when an auction is invalidated due to other market activity.
   * @dev This occurs when the NFT is sold another way, such as with `buy` or `acceptOffer`.
   * @param auctionId The id of the auction that was invalidated.
   */
  event ReserveAuctionInvalidated(uint256 indexed auctionId);
  /**
   * @notice Emitted when the auction's reserve price is changed.
   * @dev This is only possible if the auction has not received any bids.
   * @param auctionId The id of the auction that was updated.
   * @param reservePrice The new reserve price for the auction.
   */
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);

  /// @notice Confirms that the reserve price is not zero.
  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    if (reservePrice == 0) {
      revert NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
    }
    _;
  }

  /**
   * @notice Configures the duration for auctions.
   * @param duration The duration for auctions, in seconds.
   */
  constructor(uint256 duration) {
    if (duration > MAX_MAX_DURATION) {
      // This ensures that math in this file will not overflow due to a huge duration.
      revert NFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
    }
    if (duration < EXTENSION_DURATION) {
      // The auction duration configuration must be greater than the extension window of 15 minutes
      revert NFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
    }
    DURATION = duration;
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * @dev The NFT is transferred back to the owner unless there is still a buy price set.
   * @param auctionId The id of the auction to cancel.
   */
  function cancelReserveAuction(uint256 auctionId) external nonReentrant {
    ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];
    _removeNftFromExhibition(auction.nftContract, auction.tokenId);

    // Transfer the NFT unless it still has a buy price set.
    _transferFromEscrowIfAvailable(auction.nftContract, auction.tokenId, auction.seller);

    emit ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param reservePrice The initial reserve price for the auction.
   * @dev This API is deprecated and will be removed in the future, `createReserveAuctionV2` should be used instead.
   */
  function createReserveAuction(address nftContract, uint256 tokenId, uint256 reservePrice) external {
    createReserveAuctionV2(nftContract, tokenId, reservePrice, 0);
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param reservePrice The initial reserve price for the auction.
   * @param exhibitionId The exhibition to list with, or 0 if n/a.
   * @return auctionId The id of the auction that was created.
   */
  function createReserveAuctionV2(address nftContract, uint256 tokenId, uint256 reservePrice, uint256 exhibitionId)
    public
    nonReentrant
    onlyValidAuctionConfig(reservePrice)
    returns (uint256 auctionId)
  {
    auctionId = _getNextAndIncrementAuctionId();

    // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
    _transferToEscrow(nftContract, tokenId);

    // This check must be after _transferToEscrow in case auto-settle was required
    if (nftContractToTokenIdToAuctionId[nftContract][tokenId] != 0) {
      revert NFTMarketReserveAuction_Already_Listed(nftContractToTokenIdToAuctionId[nftContract][tokenId]);
    }

    // Store the auction details
    nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    auction.nftContract = nftContract;
    auction.tokenId = tokenId;
    auction.seller = payable(msg.sender);
    auction.amount = reservePrice;

    _addNftToExhibition(nftContract, tokenId, exhibitionId);

    emit ReserveAuctionCreated(msg.sender, nftContract, tokenId, DURATION, EXTENSION_DURATION, reservePrice, auctionId);
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the NFT to the highest bidder and distribute revenue for this sale.
   * @param auctionId The id of the auction to settle.
   */
  function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
    if (auctionIdToAuction[auctionId].endTime == 0) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
    }
    _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: false });
  }

  /**
   * @notice Place a bid in an auction.
   * A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * @dev This API is deprecated and will be removed in the future, `placeBidV2` should be used instead.
   * @param auctionId The id of the auction to bid on.
   */
  function placeBid(uint256 auctionId) external payable {
    placeBidV2(auctionId, msg.value, payable(0));
  }

  /**
   * @notice Place a bid in an auction.
   * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * @dev `amount` - `msg.value` is withdrawn from the bidder's FETH balance.
   * @param auctionId The id of the auction to bid on.
   * @param amount The amount to bid, if this is more than `msg.value` funds will be withdrawn from your FETH balance.
   */
  /* solhint-disable-next-line code-complexity */
  function placeBidV2(uint256 auctionId, uint256 amount, address payable referrer) public payable nonReentrant {
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];

    if (auction.amount == 0) {
      // No auction found
      revert NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
    } else if (amount < msg.value) {
      // The amount is specified by the bidder, so if too much ETH is sent then something went wrong.
      revert NFTMarketReserveAuction_Too_Much_Value_Provided();
    }

    uint256 endTime = auction.endTime;

    // Store the bid referral
    if (referrer != address(0) || endTime != 0) {
      auction.bidReferrerAddressSlot0 = uint96(uint160(address(referrer)) >> 64);
      auction.bidReferrerAddressSlot1 = uint64(uint160(address(referrer)));
    }

    if (endTime == 0) {
      // This is the first bid, kicking off the auction.

      if (amount < auction.amount) {
        // The bid must be >= the reserve price.
        revert NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(auction.amount);
      }

      // Notify other market tools that an auction for this NFT has been kicked off.
      // The only state change before this call is potentially withdrawing funds from FETH.
      _beforeAuctionStarted(auction.nftContract, auction.tokenId);

      // Store the bid details.
      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      // On the first bid, set the endTime to now + duration.
      unchecked {
        // Duration is always set to 24hrs so the below can't overflow.
        endTime = block.timestamp + DURATION;
      }
      auction.endTime = endTime;
    } else {
      if (endTime.hasExpired()) {
        // The auction has already ended.
        revert NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(endTime);
      } else if (auction.bidder == msg.sender) {
        // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
        revert NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
      } else {
        uint256 minIncrement = _getMinIncrement(auction.amount);
        if (amount < minIncrement) {
          // If this bid outbids another, it must be at least 10% greater than the last bid.
          revert NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(minIncrement);
        }
      }

      // Cache and update bidder state
      uint256 originalAmount = auction.amount;
      address payable originalBidder = auction.bidder;
      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      unchecked {
        // When a bid outbids another, check to see if a time extension should apply.
        // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
        // Current time plus extension duration (always 15 mins) cannot overflow.
        uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
        if (endTime < endTimeWithExtension) {
          endTime = endTimeWithExtension;
          auction.endTime = endTime;
        }
      }

      // Refund the previous bidder
      _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    _tryUseFETHBalance(amount, false);

    emit ReserveAuctionBidPlaced(auctionId, msg.sender, amount, endTime);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, the reservePrice may be
   * changed by the seller.
   * @param auctionId The id of the auction to change.
   * @param reservePrice The new reserve price for this auction.
   */
  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) external onlyValidAuctionConfig(reservePrice) {
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    } else if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    } else if (auction.amount == reservePrice) {
      revert NFTMarketReserveAuction_Price_Already_Set();
    }

    // Update the current reserve price.
    auction.amount = reservePrice;

    emit ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice Settle an auction that has already ended.
   * This will send the NFT to the highest bidder and distribute revenue for this sale.
   * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
   * redundant transfers if the NFT should remain in escrow, such as when the new owner
   * sets a buy price or lists it in a new auction.
   */
  function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow) private {
    ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];

    if (!auction.endTime.hasExpired()) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(auction.endTime);
    }
    (
      address payable sellerReferrerPaymentAddress,
      uint16 sellerReferrerTakeRateInBasisPoints
    ) = _getAndRemoveNftFromExhibition(auction.nftContract, auction.tokenId);

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    if (!keepInEscrow) {
      // The seller was authorized when the auction was originally created
      super._transferFromEscrow(auction.nftContract, auction.tokenId, auction.bidder, address(0));
    }

    // Distribute revenue for this sale.
    (uint256 totalFees, uint256 creatorRev, uint256 sellerRev) = _distributeFunds(
      auction.nftContract,
      auction.tokenId,
      auction.seller,
      auction.amount,
      payable(address((uint160(auction.bidReferrerAddressSlot0) << 64) | uint160(auction.bidReferrerAddressSlot1))),
      sellerReferrerPaymentAddress,
      sellerReferrerTakeRateInBasisPoints
    );

    emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, totalFees, creatorRev, sellerRev);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev If an auction is found:
   *  - If the auction is over, it will settle the auction and confirm the new seller won the auction.
   *  - If the auction has not received a bid, it will invalidate the auction.
   *  - If the auction is in progress, this will revert.
   */
  function _transferFromEscrow(address nftContract, uint256 tokenId, address recipient, address authorizeSeller)
    internal
    virtual
    override
  {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId != 0) {
      ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
      if (auction.endTime == 0) {
        // The auction has not received any bids yet so it may be invalided.

        if (authorizeSeller != address(0) && auction.seller != authorizeSeller) {
          // The account trying to transfer the NFT is not the current owner.
          revert NFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[nftContract][tokenId];
        delete auctionIdToAuction[auctionId];
        _removeNftFromExhibition(nftContract, tokenId);

        emit ReserveAuctionInvalidated(auctionId);
      } else {
        // If the auction has ended, the highest bidder will be the new owner
        // and if the auction is in progress, this will revert.

        // `authorizeSeller != address(0)` does not apply here since an unsettled auction must go
        // through this path to know who the authorized seller should be.
        if (auction.bidder != authorizeSeller) {
          revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
        }

        // Finalization will revert if the auction has not yet ended.
        _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);
    }

    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if there is an auction for this NFT before allowing the transfer to continue.
   */
  function _transferFromEscrowIfAvailable(address nftContract, uint256 tokenId, address recipient)
    internal
    virtual
    override
  {
    if (nftContractToTokenIdToAuctionId[nftContract][tokenId] == 0) {
      // No auction was found

      super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId == 0) {
      // NFT is not in auction
      super._transferToEscrow(nftContract, tokenId);
      return;
    }
    // Using storage saves gas since most of the data is not needed
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      // Reserve price set, confirm the seller is a match
      if (auction.seller != msg.sender) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
      }
    } else {
      // Auction in progress, confirm the highest bidder is a match
      if (auction.bidder != msg.sender) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
      }

      // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
      _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
    }
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   * Bids must be greater than or equal to this value or they will revert.
   * @param auctionId The id of the auction to check.
   * @return minimum The minimum amount for a bid to be accepted.
   */
  function getMinBidAmount(uint256 auctionId) external view returns (uint256 minimum) {
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

  /**
   * @notice Returns auction details for a given auctionId.
   * @param auctionId The id of the auction to lookup.
   */
  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory auction) {
    ReserveAuctionStorage storage auctionStorage = auctionIdToAuction[auctionId];
    auction = ReserveAuction(
      auctionStorage.nftContract,
      auctionStorage.tokenId,
      auctionStorage.seller,
      DURATION,
      EXTENSION_DURATION,
      auctionStorage.endTime,
      auctionStorage.bidder,
      auctionStorage.amount
    );
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return auctionId The id of the auction, or 0 if no auction is found.
   */
  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256 auctionId) {
    auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
  }

  /**
   * @notice Returns the referrer for the current highest bid in the auction, or address(0).
   */
  function getReserveAuctionBidReferrer(uint256 auctionId) external view returns (address payable referrer) {
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    referrer = payable(
      address((uint160(auction.bidReferrerAddressSlot0) << 64) | uint160(auction.bidReferrerAddressSlot1))
    );
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns the seller that has the given NFT in escrow for an auction,
   * or bubbles the call up for other considerations.
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override(MarketSharedCore, NFTMarketCore)
    returns (address payable seller)
  {
    seller = auctionIdToAuction[nftContractToTokenIdToAuctionId[nftContract][tokenId]].seller;
    if (seller == address(0)) {
      seller = super._getSellerOf(nftContract, tokenId);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    return auctionId != 0 && !auctionIdToAuction[auctionId].endTime.hasExpired();
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/// Constant values shared across mixins.

/**
 * @dev 100% in basis points.
 */
uint256 constant BASIS_POINTS = 10_000;

/**
 * @dev The default admin role defined by OZ ACL modules.
 */
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

/**
 * @dev Cap the number of royalty recipients.
 * A cap is required to ensure gas costs are not too high when a sale is settled.
 */
uint256 constant MAX_ROYALTY_RECIPIENTS = 5;

/**
 * @dev The minimum increase of 10% required when making an offer or placing a bid.
 */
uint256 constant MIN_PERCENT_INCREMENT_DENOMINATOR = BASIS_POINTS / 1_000;

/**
 * @dev The gas limit used when making external read-only calls.
 * This helps to ensure that external calls does not prevent the market from executing.
 */
uint256 constant READ_ONLY_GAS_LIMIT = 40_000;

/**
 * @dev Default royalty cut paid out on secondary sales.
 * Set to 10% of the secondary sale.
 */
uint96 constant ROYALTY_IN_BASIS_POINTS = 1_000;

/**
 * @dev 10%, expressed as a denominator for more efficient calculations.
 */
uint256 constant ROYALTY_RATIO = BASIS_POINTS / ROYALTY_IN_BASIS_POINTS;

/**
 * @dev The gas limit to send ETH to multiple recipients, enough for a 5-way split.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210_000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20_000;

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title Stores a reference to the factory which is used to create contract proxies.
 * @author batu-inal & HardlyDifficult
 */
abstract contract ContractFactory {
  using AddressUpgradeable for address;

  /**
   * @notice The address of the factory which was used to create this contract.
   * @return The factory contract address.
   */
  address public immutable contractFactory;

  modifier onlyContractFactory() {
    require(msg.sender == contractFactory, "ContractFactory: Caller is not the factory");
    _;
  }

  /**
   * @notice Initialize the template's immutable variables.
   * @param _contractFactory The factory which will be used to create these contracts.
   */
  constructor(address _contractFactory) {
    require(_contractFactory.isContract(), "ContractFactory: Factory is not a contract");
    contractFactory = _contractFactory;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../interfaces/internal/IFethMarket.sol";

error FETHNode_FETH_Address_Is_Not_A_Contract();
error FETHNode_Only_FETH_Can_Transfer_ETH();

/**
 * @title A mixin for interacting with the FETH contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract FETHNode {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /// @notice The FETH ERC-20 token for managing escrow and lockup.
  IFethMarket internal immutable feth;

  constructor(address _feth) {
    if (!_feth.isContract()) {
      revert FETHNode_FETH_Address_Is_Not_A_Contract();
    }

    feth = IFethMarket(_feth);
  }

  /**
   * @notice Only used by FETH. Any direct transfer from users will revert.
   */
  receive() external payable {
    if (msg.sender != address(feth)) {
      revert FETHNode_Only_FETH_Can_Transfer_ETH();
    }
  }

  /**
   * @notice Withdraw the msg.sender's available FETH balance if they requested more than the msg.value provided.
   * @dev This may revert if the msg.sender is non-receivable.
   * This helper should not be used anywhere that may lead to locked assets.
   * @param totalAmount The total amount of ETH required (including the msg.value).
   * @param shouldRefundSurplus If true, refund msg.value - totalAmount to the msg.sender.
   */
  function _tryUseFETHBalance(uint256 totalAmount, bool shouldRefundSurplus) internal {
    if (totalAmount > msg.value) {
      // Withdraw additional ETH required from the user's available FETH balance.
      unchecked {
        // The if above ensures delta will not underflow.
        // Withdraw ETH from the user's account in the FETH token contract,
        // making the funds available in this contract as ETH.
        feth.marketWithdrawFrom(msg.sender, totalAmount - msg.value);
      }
    } else if (shouldRefundSurplus && totalAmount < msg.value) {
      // Return any surplus ETH to the user.
      unchecked {
        // The if above ensures this will not underflow
        payable(msg.sender).sendValue(msg.value - totalAmount);
      }
    }
  }

  /**
   * @notice Gets the FETH contract used to escrow offer funds.
   * @return fethAddress The FETH contract address.
   */
  function getFethAddress() external view returns (address fethAddress) {
    fethAddress = address(feth);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../interfaces/internal/roles/IAdminRole.sol";
import "../../interfaces/internal/roles/IOperatorRole.sol";

error FoundationTreasuryNode_Address_Is_Not_A_Contract();
error FoundationTreasuryNode_Caller_Not_Admin();
error FoundationTreasuryNode_Caller_Not_Operator();

/**
 * @title A mixin that stores a reference to the Foundation treasury contract.
 * @notice The treasury collects fees and defines admin/operator roles.
 * @author batu-inal & HardlyDifficult
 */
abstract contract FoundationTreasuryNode {
  using AddressUpgradeable for address payable;

  /// @dev This value was replaced with an immutable version.
  address payable private __gap_was_treasury;

  /// @notice The address of the treasury contract.
  address payable private immutable treasury;

  /// @notice Requires the caller is a Foundation admin.
  modifier onlyFoundationAdmin() {
    if (!IAdminRole(treasury).isAdmin(msg.sender)) {
      revert FoundationTreasuryNode_Caller_Not_Admin();
    }
    _;
  }

  /// @notice Requires the caller is a Foundation operator.
  modifier onlyFoundationOperator() {
    if (!IOperatorRole(treasury).isOperator(msg.sender)) {
      revert FoundationTreasuryNode_Caller_Not_Operator();
    }
    _;
  }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Assigns the treasury contract address.
   */
  constructor(address payable _treasury) {
    if (!_treasury.isContract()) {
      revert FoundationTreasuryNode_Address_Is_Not_A_Contract();
    }
    treasury = _treasury;
  }

  /**
   * @notice Gets the Foundation treasury contract.
   * @dev This call is used in the royalty registry contract.
   * @return treasuryAddress The address of the Foundation treasury contract.
   */
  function getFoundationTreasury() public view returns (address payable treasuryAddress) {
    treasuryAddress = treasury;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[2_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title A placeholder contract leaving room for new mixins to be added to the future.
 * @author batu-inal & HardlyDifficult
 */
abstract contract Gap10000 {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[10_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title A placeholder contract leaving room for new mixins to be added to the future.
 * @author batu-inal & HardlyDifficult
 */
abstract contract Gap500 {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[500] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyRegistry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../../interfaces/standards/royalties/IGetFees.sol";
import "../../interfaces/standards/royalties/IGetRoyalties.sol";
import "../../interfaces/standards/royalties/IOwnable.sol";
import "../../interfaces/standards/royalties/IRoyaltyInfo.sol";
import "../../interfaces/standards/royalties/ITokenCreator.sol";

import "../../libraries/ArrayLibrary.sol";

import "./Constants.sol";
import "./FoundationTreasuryNode.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./MarketSharedCore.sol";

error NFTMarketFees_Address_Does_Not_Support_IRoyaltyRegistry();
error NFTMarketFees_Invalid_Protocol_Fee();

/**
 * @title A mixin to distribute funds when an NFT is sold.
 * @author batu-inal & HardlyDifficult
 */
abstract contract MarketFees is FoundationTreasuryNode, MarketSharedCore, SendValueWithFallbackWithdraw {
  using AddressUpgradeable for address;
  using ArrayLibrary for address payable[];
  using ArrayLibrary for uint256[];
  using ERC165Checker for address;

  /**
   * @dev Removing old unused variables in an upgrade safe way. Was:
   * uint256 private _primaryFoundationFeeBasisPoints;
   * uint256 private _secondaryFoundationFeeBasisPoints;
   * uint256 private _secondaryCreatorFeeBasisPoints;
   * mapping(address => mapping(uint256 => bool)) private _nftContractToTokenIdToFirstSaleCompleted;
   */
  uint256[4] private __gap_was_fees;

  /// @notice The royalties sent to creator recipients on secondary sales.
  uint256 private constant CREATOR_ROYALTY_DENOMINATOR = BASIS_POINTS / 1_000; // 10%
  /// @notice The fee collected by Foundation for sales facilitated by this market contract.
  uint256 private immutable PROTOCOL_FEE_IN_BASIS_POINTS;
  /// @notice The fee collected by the buy referrer for sales facilitated by this market contract.
  ///         This fee is calculated from the total protocol fee.
  uint256 private constant BUY_REFERRER_FEE_DENOMINATOR = BASIS_POINTS / 100; // 1%

  IRoyaltyRegistry private immutable royaltyRegistry;

  /// @notice The address of this contract's implementation.
  /// @dev This is used when making stateless external calls to this contract,
  /// saving gas over hopping through the proxy which is only necessary when accessing state.
  MarketFees private immutable implementationAddress;

  /// @notice True for the Drop market which only performs primary sales. False if primary & secondary are supported.
  bool private immutable assumePrimarySale;

  /**
   * @notice Emitted when an NFT sold with a referrer.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyReferrer The account which received the buy referral incentive.
   * @param buyReferrerFee The portion of the protocol fee collected by the buy referrer.
   * @param buyReferrerSellerFee The portion of the owner revenue collected by the buy referrer (not implemented).
   */
  event BuyReferralPaid(
    address indexed nftContract,
    uint256 indexed tokenId,
    address buyReferrer,
    uint256 buyReferrerFee,
    uint256 buyReferrerSellerFee
  );

  /**
   * @notice Emitted when an NFT is sold when associated with a sell referrer.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param sellerReferrer The account which received the sell referral incentive.
   * @param sellerReferrerFee The portion of the seller revenue collected by the sell referrer.
   */
  event SellerReferralPaid(
    address indexed nftContract,
    uint256 indexed tokenId,
    address sellerReferrer,
    uint256 sellerReferrerFee
  );

  /**
   * @notice Configures the registry allowing for royalty overrides to be defined.
   * @param _royaltyRegistry The registry to use for royalty overrides.
   * @param _assumePrimarySale True for the Drop market which only performs primary sales.
   * False if primary & secondary are supported.
   */
  constructor(uint16 protocolFeeInBasisPoints, address _royaltyRegistry, bool _assumePrimarySale) {
    if (
      protocolFeeInBasisPoints < BASIS_POINTS / BUY_REFERRER_FEE_DENOMINATOR ||
      protocolFeeInBasisPoints + BASIS_POINTS / CREATOR_ROYALTY_DENOMINATOR >= BASIS_POINTS
    ) {
      /* If the protocol fee is invalid, revert:
       * Protocol fee must be greater than the buy referrer fee since referrer fees are deducted from the protocol fee.
       * The protocol fee must leave room for the creator royalties.
       */
      revert NFTMarketFees_Invalid_Protocol_Fee();
    }
    PROTOCOL_FEE_IN_BASIS_POINTS = protocolFeeInBasisPoints;

    if (!_royaltyRegistry.supportsInterface(type(IRoyaltyRegistry).interfaceId)) {
      revert NFTMarketFees_Address_Does_Not_Support_IRoyaltyRegistry();
    }
    royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);

    assumePrimarySale = _assumePrimarySale;

    // In the constructor, `this` refers to the implementation address. Everywhere else it'll be the proxy.
    implementationAddress = this;
  }

  /**
   * @notice Distributes funds to foundation, creator recipients, and NFT owner after a sale.
   */
  function _distributeFunds(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price,
    address payable buyReferrer,
    address payable sellerReferrerPaymentAddress,
    uint16 sellerReferrerTakeRateInBasisPoints
  ) internal returns (uint256 totalFees, uint256 creatorRev, uint256 sellerRev) {
    if (price == 0) {
      // When the sale price is 0, there are no revenue to distribute.
      return (0, 0, 0);
    }

    address payable[] memory creatorRecipients;
    uint256[] memory creatorShares;

    uint256 buyReferrerFee;
    uint256 sellerReferrerFee;
    (totalFees, creatorRecipients, creatorShares, sellerRev, buyReferrerFee, sellerReferrerFee) = _getFees(
      nftContract,
      tokenId,
      seller,
      price,
      buyReferrer,
      sellerReferrerTakeRateInBasisPoints
    );

    // Pay the creator(s)
    // If just a single recipient was defined, use a larger gas limit in order to support in-contract split logic.
    uint256 creatorGasLimit = creatorRecipients.length == 1
      ? SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS
      : SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT;
    unchecked {
      for (uint256 i = 0; i < creatorRecipients.length; ++i) {
        _sendValueWithFallbackWithdraw(creatorRecipients[i], creatorShares[i], creatorGasLimit);
        // Sum the total creator rev from shares
        // creatorShares is in ETH so creatorRev will not overflow here.
        creatorRev += creatorShares[i];
      }
    }

    // Pay the seller
    _sendValueWithFallbackWithdraw(seller, sellerRev, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    // Pay the protocol fee
    _sendValueWithFallbackWithdraw(getFoundationTreasury(), totalFees, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    // Pay the buy referrer fee
    if (buyReferrerFee != 0) {
      _sendValueWithFallbackWithdraw(buyReferrer, buyReferrerFee, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
      emit BuyReferralPaid(nftContract, tokenId, buyReferrer, buyReferrerFee, 0);
      unchecked {
        // Add the referrer fee back into the total fees so that all 3 return fields sum to the total price for events
        totalFees += buyReferrerFee;
      }
    }

    if (sellerReferrerFee != 0) {
      _sendValueWithFallbackWithdraw(
        sellerReferrerPaymentAddress,
        sellerReferrerFee,
        SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
      );
      emit SellerReferralPaid(nftContract, tokenId, sellerReferrerPaymentAddress, sellerReferrerFee);

      // Add the seller referrer fee back to revenue so that all 3 return fields sum to the total price for events.
      unchecked {
        if (sellerRev == 0) {
          // When sellerRev is 0, this is a primary sale and all revenue is attributed to the "creator".
          creatorRev += sellerReferrerFee;
        } else {
          sellerRev += sellerReferrerFee;
        }
      }
    }
  }

  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The sale price to calculate the fees for.
   * @return totalFees How much will be sent to the Foundation treasury and/or referrals.
   * @return creatorRev How much will be sent across all the `creatorRecipients` defined.
   * @return creatorRecipients The addresses of the recipients to receive a portion of the creator fee.
   * @return creatorShares The percentage of the creator fee to be distributed to each `creatorRecipient`.
   * If there is only one `creatorRecipient`, this may be an empty array.
   * Otherwise `creatorShares.length` == `creatorRecipients.length`.
   * @return sellerRev How much will be sent to the owner/seller of the NFT.
   * If the NFT is being sold by the creator, this may be 0 and the full revenue will appear as `creatorRev`.
   * @return seller The address of the owner of the NFT.
   * If `sellerRev` is 0, this may be `address(0)`.
   */
  function getFeesAndRecipients(address nftContract, uint256 tokenId, uint256 price)
    external
    view
    returns (
      uint256 totalFees,
      uint256 creatorRev,
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      uint256 sellerRev,
      address payable seller
    )
  {
    seller = _getSellerOrOwnerOf(nftContract, tokenId);
    (totalFees, creatorRecipients, creatorShares, sellerRev, , ) = _getFees(
      nftContract,
      tokenId,
      seller,
      price,
      // Notice: Setting this value is a breaking change for the FNDMiddleware contract.
      // Will be wired in an upcoming release to communicate the buy referral information.
      payable(0),
      0
    );

    // Sum the total creator rev from shares
    unchecked {
      for (uint256 i = 0; i < creatorShares.length; ++i) {
        creatorRev += creatorShares[i];
      }
    }
  }

  /**
   * @notice Returns the address of the registry allowing for royalty configuration overrides.
   * @dev See https://royaltyregistry.xyz/
   * @return registry The address of the royalty registry contract.
   */
  function getRoyaltyRegistry() external view returns (address registry) {
    registry = address(royaltyRegistry);
  }

  /**
   * @notice **For internal use only.**
   * @dev This function is external to allow using try/catch but is not intended for external use.
   * This checks the token creator.
   */
  function internalGetTokenCreator(address nftContract, uint256 tokenId)
    external
    view
    returns (address payable creator)
  {
    creator = ITokenCreator(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId);
  }

  /**
   * @notice **For internal use only.**
   * @dev This function is external to allow using try/catch but is not intended for external use.
   * If ERC2981 royalties (or getRoyalties) are defined by the NFT contract, allow this standard to define immutable
   * royalties that cannot be later changed via the royalty registry.
   */
  function internalGetImmutableRoyalties(address nftContract, uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory splitPerRecipientInBasisPoints)
  {
    // 1st priority: ERC-2981
    if (nftContract.supportsERC165InterfaceUnchecked(type(IRoyaltyInfo).interfaceId)) {
      try IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenId, BASIS_POINTS) returns (
        address receiver,
        uint256 royaltyAmount
      ) {
        // Manifold contracts return (address(this), 0) when royalties are not defined
        // - so ignore results when the amount is 0
        if (royaltyAmount > 0) {
          recipients = new address payable[](1);
          recipients[0] = payable(receiver);
          splitPerRecipientInBasisPoints = new uint256[](1);
          // The split amount is assumed to be 100% when only 1 recipient is returned
          return (recipients, splitPerRecipientInBasisPoints);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 2nd priority: getRoyalties
    if (nftContract.supportsERC165InterfaceUnchecked(type(IGetRoyalties).interfaceId)) {
      try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients,
        uint256[] memory recipientBasisPoints
      ) {
        if (_recipients.length != 0 && _recipients.length == recipientBasisPoints.length) {
          return (_recipients, recipientBasisPoints);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }
  }

  /**
   * @notice **For internal use only.**
   * @dev This function is external to allow using try/catch but is not intended for external use.
   * This checks for royalties defined in the royalty registry or via a non-standard royalty API.
   */
  // solhint-disable-next-line code-complexity
  function internalGetMutableRoyalties(address nftContract, uint256 tokenId, address payable creator)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory splitPerRecipientInBasisPoints)
  {
    /* Overrides must support ERC-165 when registered, except for overrides defined by the registry owner.
       If that results in an override w/o 165 we may need to upgrade the market to support or ignore that override. */
    // The registry requires overrides are not 0 and contracts when set.
    // If no override is set, the nftContract address is returned.

    try royaltyRegistry.getRoyaltyLookupAddress{ gas: READ_ONLY_GAS_LIMIT }(nftContract) returns (
      address overrideContract
    ) {
      if (overrideContract != nftContract) {
        nftContract = overrideContract;

        // The functions above are repeated here if an override is set.

        // 3rd priority: ERC-2981 override
        if (nftContract.supportsERC165InterfaceUnchecked(type(IRoyaltyInfo).interfaceId)) {
          try IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenId, BASIS_POINTS) returns (
            address receiver,
            uint256 royaltyAmount
          ) {
            // Manifold contracts return (address(this), 0) when royalties are not defined
            // - so ignore results when the amount is 0
            if (royaltyAmount != 0) {
              recipients = new address payable[](1);
              recipients[0] = payable(receiver);
              splitPerRecipientInBasisPoints = new uint256[](1);
              // The split amount is assumed to be 100% when only 1 recipient is returned
              return (recipients, splitPerRecipientInBasisPoints);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }

        // 4th priority: getRoyalties override
        if (recipients.length == 0 && nftContract.supportsERC165InterfaceUnchecked(type(IGetRoyalties).interfaceId)) {
          try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
            address payable[] memory _recipients,
            uint256[] memory recipientBasisPoints
          ) {
            if (_recipients.length != 0 && _recipients.length == recipientBasisPoints.length) {
              return (_recipients, recipientBasisPoints);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Ignore out of gas errors and continue using the nftContract address
    }

    // 5th priority: getFee* from contract or override
    if (nftContract.supportsERC165InterfaceUnchecked(type(IGetFees).interfaceId)) {
      try IGetFees(nftContract).getFeeRecipients{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients
      ) {
        if (_recipients.length != 0) {
          try IGetFees(nftContract).getFeeBps{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
            uint256[] memory recipientBasisPoints
          ) {
            if (_recipients.length == recipientBasisPoints.length) {
              return (_recipients, recipientBasisPoints);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 6th priority: tokenCreator w/ or w/o requiring 165 from contract or override
    if (creator != address(0)) {
      // Only pay the tokenCreator if there wasn't another royalty defined
      recipients = new address payable[](1);
      recipients[0] = creator;
      splitPerRecipientInBasisPoints = new uint256[](1);
      // The split amount is assumed to be 100% when only 1 recipient is returned
      return (recipients, splitPerRecipientInBasisPoints);
    }

    // 7th priority: owner from contract or override
    try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address owner) {
      if (owner != address(0)) {
        // Only pay the owner if there wasn't another royalty defined
        recipients = new address payable[](1);
        recipients[0] = payable(owner);
        splitPerRecipientInBasisPoints = new uint256[](1);
        // The split amount is assumed to be 100% when only 1 recipient is returned
        return (recipients, splitPerRecipientInBasisPoints);
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // If no valid payment address or creator is found, return 0 recipients
  }

  /**
   * @notice Calculates how funds should be distributed for the given sale details.
   * @dev When the NFT is being sold by the `tokenCreator`, all the seller revenue will
   * be split with the royalty recipients defined for that NFT.
   */
  // solhint-disable-next-line code-complexity
  function _getFees(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price,
    address payable buyReferrer,
    uint16 sellerReferrerTakeRateInBasisPoints
  )
    private
    view
    returns (
      uint256 totalFees,
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      uint256 sellerRev,
      uint256 buyReferrerFee,
      uint256 sellerReferrerFee
    )
  {
    // Calculate the protocol fee
    totalFees = (price * PROTOCOL_FEE_IN_BASIS_POINTS) / BASIS_POINTS;

    address payable creator;
    try implementationAddress.internalGetTokenCreator(nftContract, tokenId) returns (address payable _creator) {
      creator = _creator;
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    try implementationAddress.internalGetImmutableRoyalties(nftContract, tokenId) returns (
      address payable[] memory _recipients,
      uint256[] memory _splitPerRecipientInBasisPoints
    ) {
      (creatorRecipients, creatorShares) = (_recipients, _splitPerRecipientInBasisPoints);
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    if (creatorRecipients.length == 0) {
      // Check mutable royalties only if we didn't find results from the immutable API
      try implementationAddress.internalGetMutableRoyalties(nftContract, tokenId, creator) returns (
        address payable[] memory _recipients,
        uint256[] memory _splitPerRecipientInBasisPoints
      ) {
        (creatorRecipients, creatorShares) = (_recipients, _splitPerRecipientInBasisPoints);
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    if (creatorRecipients.length != 0 || assumePrimarySale) {
      uint256 creatorRev;
      if (assumePrimarySale) {
        // All revenue should go to the creator recipients
        unchecked {
          // totalFees is always < price.
          creatorRev = price - totalFees;
        }
        if (creatorRecipients.length == 0) {
          // If no creators were found via the royalty APIs, then set that recipient to the seller's address
          creatorRecipients = new address payable[](1);
          creatorRecipients[0] = seller;
          creatorShares = new uint256[](1);
          // The split amount is assumed to be 100% when only 1 recipient is returned
        }
      } else if (seller == creator || (creatorRecipients.length != 0 && seller == creatorRecipients[0])) {
        // When sold by the creator, all revenue is split if applicable.
        unchecked {
          // totalFees is always < price.
          creatorRev = price - totalFees;
        }
      } else {
        // Rounding favors the owner first, then creator, and foundation last.
        unchecked {
          // Safe math is not required when dividing by a non-zero constant.
          creatorRev = price / CREATOR_ROYALTY_DENOMINATOR;
        }
        sellerRev = price - totalFees - creatorRev;
      }

      // Cap the max number of recipients supported
      creatorRecipients.capLength(MAX_ROYALTY_RECIPIENTS);
      creatorShares.capLength(MAX_ROYALTY_RECIPIENTS);

      if (sellerReferrerTakeRateInBasisPoints != 0) {
        sellerReferrerFee = (price * sellerReferrerTakeRateInBasisPoints) / BASIS_POINTS;

        // Subtract the seller referrer fee from the seller revenue so we do not double pay.
        if (sellerRev == 0) {
          // If the seller revenue is 0, this is a primary sale where all seller revenue is attributed to the "creator".
          creatorRev -= sellerReferrerFee;
        } else {
          sellerRev -= sellerReferrerFee;
        }
      }

      // Sum the total shares defined
      uint256 totalShares;
      if (creatorRecipients.length > 1) {
        unchecked {
          for (uint256 i = 0; i < creatorRecipients.length; ++i) {
            if (creatorRecipients[i] == seller) {
              // If the seller is any of the recipients defined, assume a primary sale
              creatorRev += sellerRev;
              sellerRev = 0;
            }
            if (creatorShares[i] > BASIS_POINTS) {
              // If the numbers are >100% we ignore the fee recipients and pay just the first instead
              totalShares = 0;
              break;
            }
            totalShares += creatorShares[i];
          }
        }

        if (totalShares == 0) {
          // If no shares were defined or shares were out of bounds, pay only the first recipient
          creatorRecipients.capLength(1);
          creatorShares.capLength(1);
        }
      }

      // Send payouts to each additional recipient if more than 1 was defined
      uint256 totalRoyaltiesDistributed;
      for (uint256 i = 1; i < creatorRecipients.length; ) {
        uint256 royalty = (creatorRev * creatorShares[i]) / totalShares;
        totalRoyaltiesDistributed += royalty;
        creatorShares[i] = royalty;
        unchecked {
          ++i;
        }
      }

      // Send the remainder to the 1st creator, rounding in their favor
      creatorShares[0] = creatorRev - totalRoyaltiesDistributed;
    } else {
      // No royalty recipients found.
      unchecked {
        // totalFees is always < price.
        sellerRev = price - totalFees;
      }
    }

    if (buyReferrer != address(0) && buyReferrer != msg.sender && buyReferrer != seller && buyReferrer != creator) {
      unchecked {
        buyReferrerFee = price / BUY_REFERRER_FEE_DENOMINATOR;

        // buyReferrerFee is always <= totalFees
        totalFees -= buyReferrerFee;
      }
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[500] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./FETHNode.sol";

/**
 * @title A place for common modifiers and functions used by various market mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract MarketSharedCore is FETHNode {
  /**
   * @notice Checks who the seller for an NFT is if listed in this market.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return seller The seller which listed this NFT for sale, or address(0) if not listed.
   */
  function getSellerOf(address nftContract, uint256 tokenId) external view returns (address payable seller) {
    seller = _getSellerOf(nftContract, tokenId);
  }

  /**
   * @notice Checks who the seller for an NFT is if listed in this market.
   */
  function _getSellerOf(address nftContract, uint256 tokenId) internal view virtual returns (address payable seller);

  /**
   * @notice Checks who the seller for an NFT is if listed in this market or returns the current owner.
   */
  function _getSellerOrOwnerOf(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    returns (address payable sellerOrOwner);

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[500] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./FETHNode.sol";

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the FETH token contract for future withdrawal instead.
 * @dev This mixin was recently switched to escrow funds in FETH.
 * Once we have confirmed all pending balances have been withdrawn, we can remove the escrow tracking here.
 * @author batu-inal & HardlyDifficult
 */
abstract contract SendValueWithFallbackWithdraw is FETHNode {
  using AddressUpgradeable for address payable;

  /// @dev Removing old unused variables in an upgrade safe way.
  uint256 private __gap_was_pendingWithdrawals;

  /**
   * @notice Emitted when escrowed funds are withdrawn to FETH.
   * @param user The account which has withdrawn ETH.
   * @param amount The amount of ETH which has been withdrawn.
   */
  event WithdrawalToFETH(address indexed user, uint256 amount);

  /**
   * @notice Attempt to send a user or contract ETH.
   * If it fails store the amount owned for later withdrawal in FETH.
   * @dev This may fail when sending ETH to a contract that is non-receivable or exceeds the gas limit specified.
   */
  function _sendValueWithFallbackWithdraw(address payable user, uint256 amount, uint256 gasLimit) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Store the funds that failed to send for the user in the FETH token
      feth.depositFor{ value: amount }(user);
      emit WithdrawalToFETH(user, amount);
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[999] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./interfaces/internal/INFTCollectionInitializer.sol";
import "./interfaces/standards/royalties/IGetRoyalties.sol";
import "./interfaces/standards/royalties/ITokenCreator.sol";
import "./interfaces/standards/royalties/IGetFees.sol";
import "./interfaces/standards/royalties/IRoyaltyInfo.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./libraries/AddressLibrary.sol";

import "./mixins/collections/SequentialMintCollection.sol";
import "./mixins/collections/CollectionRoyalties.sol";
import "./mixins/shared/ContractFactory.sol";

/**
 * @title A collection of NFTs by a single creator.
 * @notice All NFTs from this contract are minted by the same creator.
 * A 10% royalty to the creator is included which may be split with collaborators on a per-NFT basis.
 * @author batu-inal & HardlyDifficult
 */
contract NFTCollection is
  INFTCollectionInitializer,
  IGetRoyalties,
  IGetFees,
  IRoyaltyInfo,
  ITokenCreator,
  ContractFactory,
  Initializable,
  ERC165Upgradeable,
  ERC721Upgradeable,
  ERC721BurnableUpgradeable,
  SequentialMintCollection,
  CollectionRoyalties
{
  using AddressLibrary for address;
  using AddressUpgradeable for address;

  /**
   * @notice The baseURI to use for the tokenURI, if undefined then `ipfs://` is used.
   */
  string private baseURI_;

  /**
   * @notice Stores hashes minted to prevent duplicates.
   * @dev 0 means not yet minted, set to 1 when minted.
   * For why using uint is better than using bool here:
   * github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/security/ReentrancyGuard.sol#L23-L27
   */
  mapping(string => uint256) private cidToMinted;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   * The target address may be a contract which could split or escrow payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  /**
   * @dev Stores a CID for each NFT.
   */
  mapping(uint256 => string) private _tokenCIDs;

  /**
   * @notice Emitted when the owner changes the base URI to be used for NFTs in this collection.
   * @param baseURI The new base URI to use.
   */
  event BaseURIUpdated(string baseURI);
  /**
   * @notice Emitted when a new NFT is minted.
   * @param creator The address of the collection owner at this time this NFT was minted.
   * @param tokenId The tokenId of the newly minted NFT.
   * @param indexedTokenCID The CID of the newly minted NFT, indexed to enable watching for mint events by the tokenCID.
   * @param tokenCID The actual CID of the newly minted NFT.
   */
  event Minted(address indexed creator, uint256 indexed tokenId, string indexed indexedTokenCID, string tokenCID);
  /**
   * @notice Emitted when the payment address for creator royalties is set.
   * @param fromPaymentAddress The original address used for royalty payments.
   * @param toPaymentAddress The new address used for royalty payments.
   * @param tokenId The NFT which had the royalty payment address updated.
   */
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );

  /**
   * @notice Initialize the template's immutable variables.
   * @param _contractFactory The factory which will be used to create collection contracts.
   */
  constructor(address _contractFactory)
    ContractFactory(_contractFactory) // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Called by the contract factory on creation.
   * @param _creator The creator of this collection.
   * @param _name The collection's `name`.
   * @param _symbol The collection's `symbol`.
   */
  function initialize(address payable _creator, string calldata _name, string calldata _symbol)
    external
    initializer
    onlyContractFactory
  {
    __ERC721_init(_name, _symbol);
    _initializeSequentialMintCollection(_creator, 0);
  }

  /**
   * @notice Allows the creator to burn a specific token if they currently own the NFT.
   * @param tokenId The ID of the NFT to burn.
   * @dev The function here asserts `onlyOwner` while the super confirms ownership.
   */
  function burn(uint256 tokenId) public override onlyOwner {
    super.burn(tokenId);
  }

  /**
   * @notice Mint an NFT defined by its metadata path.
   * @dev This is only callable by the collection creator/owner.
   * @param tokenCID The CID for the metadata json of the NFT to mint.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mint(string calldata tokenCID) external returns (uint256 tokenId) {
    tokenId = _mint(tokenCID);
  }

  /**
   * @notice Mint an NFT defined by its metadata path and approves the provided operator address.
   * @dev This is only callable by the collection creator/owner.
   * It can be used the first time they mint to save having to issue a separate approval
   * transaction before listing the NFT for sale.
   * @param tokenCID The CID for the metadata json of the NFT to mint.
   * @param operator The address to set as an approved operator for the creator's account.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintAndApprove(string calldata tokenCID, address operator) external returns (uint256 tokenId) {
    tokenId = _mint(tokenCID);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Mint an NFT defined by its metadata path and have creator revenue/royalties sent to an alternate address.
   * @dev This is only callable by the collection creator/owner.
   * @param tokenCID The CID for the metadata json of the NFT to mint.
   * @param tokenCreatorPaymentAddress The royalty recipient address to use for this NFT.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentAddress(string calldata tokenCID, address payable tokenCreatorPaymentAddress)
    public
    returns (uint256 tokenId)
  {
    require(tokenCreatorPaymentAddress != address(0), "NFTCollection: tokenCreatorPaymentAddress is required");
    tokenId = _mint(tokenCID);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
    emit TokenCreatorPaymentAddressSet(address(0), tokenCreatorPaymentAddress, tokenId);
  }

  /**
   * @notice Mint an NFT defined by its metadata path and approves the provided operator address.
   * @dev This is only callable by the collection creator/owner.
   * It can be used the first time they mint to save having to issue a separate approval
   * transaction before listing the NFT for sale.
   * @param tokenCID The CID for the metadata json of the NFT to mint.
   * @param tokenCreatorPaymentAddress The royalty recipient address to use for this NFT.
   * @param operator The address to set as an approved operator for the creator's account.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentAddressAndApprove(
    string calldata tokenCID,
    address payable tokenCreatorPaymentAddress,
    address operator
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentAddress(tokenCID, tokenCreatorPaymentAddress);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Mint an NFT defined by its metadata path and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * @dev This is only callable by the collection creator/owner.
   * @param tokenCID The CID for the metadata json of the NFT to mint.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCall The call details to send to the factory provided.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentFactory(
    string calldata tokenCID,
    address paymentAddressFactory,
    bytes calldata paymentAddressCall
  ) public returns (uint256 tokenId) {
    address payable tokenCreatorPaymentAddress = paymentAddressFactory.callAndReturnContractAddress(paymentAddressCall);
    tokenId = mintWithCreatorPaymentAddress(tokenCID, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Mint an NFT defined by its metadata path and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * @dev This is only callable by the collection creator/owner.
   * It can be used the first time they mint to save having to issue a separate approval
   * transaction before listing the NFT for sale.
   * @param tokenCID The CID for the metadata json of the NFT to mint.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCall The call details to send to the factory provided.
   * @param operator The address to set as an approved operator for the creator's account.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentFactoryAndApprove(
    string calldata tokenCID,
    address paymentAddressFactory,
    bytes calldata paymentAddressCall,
    address operator
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentFactory(tokenCID, paymentAddressFactory, paymentAddressCall);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Allows the collection creator to destroy this contract only if
   * no NFTs have been minted yet or the minted NFTs have been burned.
   * @dev Once destructed, a new collection could be deployed to this address (although that's discouraged).
   */
  function selfDestruct() external onlyOwner {
    _selfDestruct();
  }

  /**
   * @notice Allows the owner to assign a baseURI to use for the tokenURI instead of the default `ipfs://`.
   * @param baseURIOverride The new base URI to use for all NFTs in this collection.
   */
  function updateBaseURI(string calldata baseURIOverride) external onlyOwner {
    baseURI_ = baseURIOverride;

    emit BaseURIUpdated(baseURIOverride);
  }

  /**
   * @notice Allows the owner to set a max tokenID.
   * This provides a guarantee to collectors about the limit of this collection contract, if applicable.
   * @dev Once this value has been set, it may be decreased but can never be increased.
   * This max may be more than the final `totalSupply` if 1 or more tokens were burned.
   * @param _maxTokenId The max tokenId to set, all NFTs must have a tokenId less than or equal to this value.
   */
  function updateMaxTokenId(uint32 _maxTokenId) external onlyOwner {
    _updateMaxTokenId(_maxTokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721Upgradeable, SequentialMintCollection) {
    delete cidToMinted[_tokenCIDs[tokenId]];
    delete tokenIdToCreatorPaymentAddress[tokenId];
    delete _tokenCIDs[tokenId];
    super._burn(tokenId);
  }

  function _mint(string calldata tokenCID) private onlyOwner returns (uint256 tokenId) {
    require(bytes(tokenCID).length != 0, "NFTCollection: tokenCID is required");
    require(cidToMinted[tokenCID] == 0, "NFTCollection: NFT was already minted");
    // Number of tokens cannot realistically overflow 32 bits.
    tokenId = ++latestTokenId;
    require(maxTokenId == 0 || tokenId <= maxTokenId, "NFTCollection: Max token count has already been minted");
    cidToMinted[tokenCID] = 1;
    _tokenCIDs[tokenId] = tokenCID;
    _safeMint(msg.sender, tokenId);
    emit Minted(msg.sender, tokenId, tokenCID, tokenCID);
  }

  /**
   * @notice The base URI used for all NFTs in this collection.
   * @dev The `tokenCID` is appended to this to obtain an NFT's `tokenURI`.
   *      e.g. The URI for a token with the `tokenCID`: "foo" and `baseURI`: "ipfs://" is "ipfs://foo".
   * @return uri The base URI used by this collection.
   */
  function baseURI() external view returns (string memory uri) {
    uri = _baseURI();
  }

  /**
   * @notice Checks if the creator has already minted a given NFT using this collection contract.
   * @param tokenCID The CID to check for.
   * @return hasBeenMinted True if the creator has already minted an NFT with this CID.
   */
  function getHasMintedCID(string calldata tokenCID) external view returns (bool hasBeenMinted) {
    hasBeenMinted = cidToMinted[tokenCID] != 0;
  }

  /**
   * @inheritdoc CollectionRoyalties
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    override
    returns (address payable creatorPaymentAddress)
  {
    creatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (creatorPaymentAddress == address(0)) {
      creatorPaymentAddress = owner;
    }
  }

  /**
   * @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165Upgradeable, ERC721Upgradeable, CollectionRoyalties)
    returns (bool interfaceSupported)
  {
    // This is a no-op function required to avoid compile errors.
    interfaceSupported = super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IERC721MetadataUpgradeable
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
    require(_exists(tokenId), "NFTCollection: URI query for nonexistent token");

    uri = string.concat(_baseURI(), _tokenCIDs[tokenId]);
  }

  function _baseURI() internal view override returns (string memory uri) {
    uri = baseURI_;
    if (bytes(uri).length == 0) {
      uri = "ipfs://";
    }
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./mixins/shared/FETHNode.sol";
import "./mixins/shared/FoundationTreasuryNode.sol";
import "./mixins/shared/Gap10000.sol";
import "./mixins/shared/Gap500.sol";
import "./mixins/shared/MarketFees.sol";
import "./mixins/shared/MarketSharedCore.sol";
import "./mixins/shared/SendValueWithFallbackWithdraw.sol";

import "./mixins/nftDropMarket/NFTDropMarketCore.sol";
import "./mixins/nftDropMarket/NFTDropMarketFixedPriceSale.sol";

error NFTDropMarket_NFT_Already_Minted();

/**
 * @title A market for minting NFTs with Foundation.
 * @author batu-inal & HardlyDifficult & reggieag
 */
contract NFTDropMarket is
  Initializable,
  FoundationTreasuryNode,
  FETHNode,
  MarketSharedCore,
  NFTDropMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  MarketFees,
  Gap500,
  Gap10000,
  NFTDropMarketFixedPriceSale
{
  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param treasury The Foundation Treasury contract address.
   * @param feth The FETH ERC-20 token contract address.
   * @param royaltyRegistry The Royalty Registry contract address.
   */
  constructor(address payable treasury, address feth, address royaltyRegistry)
    FoundationTreasuryNode(treasury)
    FETHNode(feth)
    MarketFees(
      /* protocolFeeInBasisPoints: */
      1500,
      royaltyRegistry,
      /* assumePrimarySale: */
      true
    )
    initializer // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
   */
  function initialize() external initializer {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns address(0) if the NFT has already been sold, otherwise checks for a listing in this market.
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    override(MarketSharedCore, NFTDropMarketFixedPriceSale)
    returns (address payable seller)
  {
    // Check the current owner first in case it has been sold.
    try IERC721(nftContract).ownerOf(tokenId) returns (address owner) {
      if (owner != address(0)) {
        // If sold, return address(0) since that owner cannot sell via this market.
        return payable(address(0));
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    return super._getSellerOf(nftContract, tokenId);
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Reverts if the NFT has already been sold, otherwise checks for a listing in this market.
   */
  function _getSellerOrOwnerOf(address nftContract, uint256 tokenId)
    internal
    view
    override
    returns (address payable sellerOrOwner)
  {
    // Check the current owner first in case it has been sold.
    try IERC721(nftContract).ownerOf(tokenId) returns (address owner) {
      if (owner != address(0)) {
        // Once an NFT has been minted, it cannot be sold through this contract.
        revert NFTDropMarket_NFT_Already_Minted();
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    sellerOrOwner = super._getSellerOf(nftContract, tokenId);
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./mixins/shared/Constants.sol";
import "./mixins/shared/FETHNode.sol";
import "./mixins/shared/FoundationTreasuryNode.sol";
import "./mixins/shared/MarketFees.sol";
import "./mixins/shared/MarketSharedCore.sol";
import "./mixins/shared/SendValueWithFallbackWithdraw.sol";

import "./mixins/nftMarket/NFTMarketAuction.sol";
import "./mixins/nftMarket/NFTMarketBuyPrice.sol";
import "./mixins/nftMarket/NFTMarketCore.sol";
import "./mixins/nftMarket/NFTMarketOffer.sol";
import "./mixins/nftMarket/NFTMarketPrivateSaleGap.sol";
import "./mixins/nftMarket/NFTMarketReserveAuction.sol";
import "./mixins/nftMarket/NFTMarketExhibition.sol";

/**
 * @title A market for NFTs on Foundation.
 * @notice The Foundation marketplace is a contract which allows traders to buy and sell NFTs.
 * It supports buying and selling via auctions, private sales, buy price, and offers.
 * @dev All sales in the Foundation market will pay the creator 10% royalties on secondary sales. This is not specific
 * to NFTs minted on Foundation, it should work for any NFT. If royalty information was not defined when the NFT was
 * originally deployed, it may be added using the [Royalty Registry](https://royaltyregistry.xyz/) which will be
 * respected by our market contract.
 * @author batu-inal & HardlyDifficult
 */
contract NFTMarket is
  Initializable,
  FoundationTreasuryNode,
  FETHNode,
  MarketSharedCore,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  MarketFees,
  NFTMarketExhibition,
  NFTMarketAuction,
  NFTMarketReserveAuction,
  NFTMarketPrivateSaleGap,
  NFTMarketBuyPrice,
  NFTMarketOffer
{
  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param treasury The Foundation Treasury contract address.
   * @param feth The FETH ERC-20 token contract address.
   * @param royaltyRegistry The Royalty Registry contract address.
   * @param duration The duration of the auction in seconds.
   */
  constructor(address payable treasury, address feth, address royaltyRegistry, uint256 duration)
    FoundationTreasuryNode(treasury)
    FETHNode(feth)
    MarketFees(
      /* protocolFeeInBasisPoints: */
      500,
      royaltyRegistry,
      /* assumePrimarySale: */
      false
    )
    NFTMarketReserveAuction(duration)
    initializer // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
   */
  function initialize() external initializer {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    NFTMarketAuction._initializeNFTMarketAuction();
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId)
    internal
    override(NFTMarketCore, NFTMarketBuyPrice, NFTMarketOffer)
  {
    // This is a no-op function required to avoid compile errors.
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferFromEscrow(address nftContract, uint256 tokenId, address recipient, address authorizeSeller)
    internal
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
  {
    // This is a no-op function required to avoid compile errors.
    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferFromEscrowIfAvailable(address nftContract, uint256 tokenId, address recipient)
    internal
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
  {
    // This is a no-op function required to avoid compile errors.
    super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferToEscrow(address nftContract, uint256 tokenId)
    internal
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
  {
    // This is a no-op function required to avoid compile errors.
    super._transferToEscrow(nftContract, tokenId);
  }

  /**
   * @inheritdoc MarketSharedCore
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    override(MarketSharedCore, NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
    returns (address payable seller)
  {
    // This is a no-op function required to avoid compile errors.
    seller = super._getSellerOf(nftContract, tokenId);
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./interfaces/dependencies/tokens/IERC20Approve.sol";
import "./interfaces/dependencies/tokens/IERC20IncreaseAllowance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./libraries/BytesLibrary.sol";

/**
 * @title Auto-forward ETH to a pre-determined list of addresses.
 * @notice Deploys contracts which auto-forwards any ETH sent to it to a list of recipients
 * considering their percent share of the payment received.
 * ERC-20 tokens are also supported and may be split on demand by calling `splitERC20Tokens`.
 * If another asset type is sent to this contract address such as an NFT, arbitrary calls may be made by one
 * of the split recipients in order to recover them.
 * @dev Uses create2 counterfactual addresses so that the destination is known from the terms of the split.
 * @author batu-inal & HardlyDifficult
 */
contract PercentSplitETH is Initializable {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;
  using BytesLibrary for bytes;
  using SafeMath for uint256;

  /// @notice A representation of shares using 16-bits for efficient storage.
  /// @dev This is only used internally.
  struct ShareCompressed {
    address payable recipient;
    uint16 percentInBasisPoints;
  }

  /// @notice A representation of shares using 256-bits to ease integration.
  struct Share {
    address payable recipient;
    uint256 percentInBasisPoints;
  }

  ShareCompressed[] private _shares;

  uint256 private constant BASIS_POINTS = 10_000;

  /**
   * @notice Emitted when an ERC20 token is transferred to a recipient through this split contract.
   * @param erc20Contract The address of the ERC20 token contract.
   * @param account The account which received payment.
   * @param amount The amount of ERC20 tokens sent to this recipient.
   */
  event ERC20Transferred(address indexed erc20Contract, address indexed account, uint256 amount);
  /**
   * @notice Emitted when ETH is transferred to a recipient through this split contract.
   * @param account The account which received payment.
   * @param amount The amount of ETH payment sent to this recipient.
   */
  event ETHTransferred(address indexed account, uint256 amount);
  /**
   * @notice Emitted when a new percent split contract is created from this factory.
   * @param contractAddress The address of the new percent split contract.
   */
  event PercentSplitCreated(address indexed contractAddress);
  /**
   * @notice Emitted for each share of the split being defined.
   * @param recipient The address of the recipient when payment to the split is received.
   * @param percentInBasisPoints The percent of the payment received by the recipient, in basis points.
   */
  event PercentSplitShare(address indexed recipient, uint256 percentInBasisPoints);

  /**
   * @dev Requires that the msg.sender is one of the recipients in this split.
   */
  modifier onlyRecipient() {
    for (uint256 i = 0; i < _shares.length; ) {
      if (_shares[i].recipient == msg.sender) {
        _;
        return;
      }
      unchecked {
        ++i;
      }
    }
    revert("Split: Can only be called by one of the recipients");
  }

  // solhint-disable-next-line no-empty-blocks
  constructor() initializer {
    // Initialize the template to avoid confusion.
    // https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680/6
  }

  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This will be called by `createSplit` after deploying the proxy so it should never be called directly.
   * @param shares The list of recipients and their share of the payment for the template to use.
   */
  function initialize(Share[] calldata shares) external initializer {
    require(shares.length > 1, "Split: Too few recipients");
    require(shares.length < 6, "Split: Too many recipients");
    uint256 total;
    unchecked {
      // The array length cannot overflow 256 bits.
      for (uint256 i = 0; i < shares.length; ++i) {
        require(shares[i].percentInBasisPoints < BASIS_POINTS, "Split: Share must be less than 100%");
        // Require above ensures total will not overflow.
        total += shares[i].percentInBasisPoints;
        _shares.push(
          ShareCompressed({
            recipient: shares[i].recipient,
            percentInBasisPoints: uint16(shares[i].percentInBasisPoints)
          })
        );
        emit PercentSplitShare(shares[i].recipient, shares[i].percentInBasisPoints);
      }
    }
    require(total == BASIS_POINTS, "Split: Total amount must equal 100%");
  }

  /**
   * @notice Forwards any ETH received to the recipients in this split.
   * @dev Each recipient increases the gas required to split
   * and contract recipients may significantly increase the gas required.
   */
  receive() external payable {
    _splitETH(msg.value);
  }

  /**
   * @notice Creates a new minimal proxy contract and initializes it with the given split terms.
   * If the contract had already been created, its address is returned.
   * This must be called on the original implementation and not a proxy created previously.
   * @param shares The list of recipients and their share of the payment for this split.
   * @return splitInstance The contract address for the split contract created.
   */
  function createSplit(Share[] calldata shares) external returns (PercentSplitETH splitInstance) {
    bytes32 salt = keccak256(abi.encode(shares));
    address clone = Clones.predictDeterministicAddress(address(this), salt);
    splitInstance = PercentSplitETH(payable(clone));
    if (!clone.isContract()) {
      emit PercentSplitCreated(clone);
      Clones.cloneDeterministic(address(this), salt);
      splitInstance.initialize(shares);
    }
  }

  /**
   * @notice Allows the split recipients to make an arbitrary contract call.
   * @dev This is provided to allow recovering from unexpected scenarios,
   * such as receiving an NFT at this address.
   *
   * It will first attempt a fair split of ERC20 tokens before proceeding.
   *
   * This contract is built to split ETH payments. The ability to attempt to make other calls is here
   * just in case other assets were also sent so that they don't get locked forever in the contract.
   * @param target The address of the contract to call.
   * @param callData The data to send to the `target` contract.
   */
  function proxyCall(address payable target, bytes calldata callData) external onlyRecipient {
    require(
      !callData.startsWith(type(IERC20Approve).interfaceId) &&
        !callData.startsWith(type(IERC20IncreaseAllowance).interfaceId),
      "Split: ERC20 tokens must be split"
    );
    _splitERC20Tokens(IERC20(target));
    target.functionCall(callData);
  }

  /**
   * @notice Allows any ETH stored by the contract to be split among recipients.
   * @dev Normally ETH is forwarded as it comes in, but a balance in this contract
   * is possible if it was sent before the contract was created or if self destruct was used.
   */
  function splitETH() external {
    _splitETH(address(this).balance);
  }

  /**
   * @notice Anyone can call this function to split all available tokens at the provided address between the recipients.
   * @dev This contract is built to split ETH payments. The ability to attempt to split ERC20 tokens is here
   * just in case tokens were also sent so that they don't get locked forever in the contract.
   * @param erc20Contract The address of the ERC20 token contract to split tokens for.
   */
  function splitERC20Tokens(IERC20 erc20Contract) external {
    require(_splitERC20Tokens(erc20Contract), "Split: ERC20 split failed");
  }

  function _splitERC20Tokens(IERC20 erc20Contract) private returns (bool) {
    try erc20Contract.balanceOf(address(this)) returns (uint256 balance) {
      if (balance == 0) {
        return false;
      }
      uint256 amountToSend;
      uint256 totalSent;
      unchecked {
        for (uint256 i = _shares.length - 1; i != 0; i--) {
          ShareCompressed memory share = _shares[i];
          bool success;
          (success, amountToSend) = balance.tryMul(share.percentInBasisPoints);
          if (!success) {
            return false;
          }
          amountToSend /= BASIS_POINTS;
          totalSent += amountToSend;
          try erc20Contract.transfer(share.recipient, amountToSend) {
            emit ERC20Transferred(address(erc20Contract), share.recipient, amountToSend);
          } catch {
            return false;
          }
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = balance - totalSent;
      }
      try erc20Contract.transfer(_shares[0].recipient, amountToSend) {
        emit ERC20Transferred(address(erc20Contract), _shares[0].recipient, amountToSend);
      } catch {
        return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  function _splitETH(uint256 value) private {
    if (value != 0) {
      uint256 totalSent;
      uint256 amountToSend;
      unchecked {
        for (uint256 i = _shares.length - 1; i != 0; i--) {
          ShareCompressed memory share = _shares[i];
          amountToSend = (value * share.percentInBasisPoints) / BASIS_POINTS;
          totalSent += amountToSend;
          share.recipient.sendValue(amountToSend);
          emit ETHTransferred(share.recipient, amountToSend);
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = value - totalSent;
      }
      _shares[0].recipient.sendValue(amountToSend);
      emit ETHTransferred(_shares[0].recipient, amountToSend);
    }
  }

  /**
   * @notice Returns a recipient's percent share in basis points.
   * @param index The index of the recipient to get the share of.
   * @return percentInBasisPoints The percent of the payment received by the recipient, in basis points.
   */
  function getPercentInBasisPointsByIndex(uint256 index) external view returns (uint256 percentInBasisPoints) {
    percentInBasisPoints = _shares[index].percentInBasisPoints;
  }

  /**
   * @notice Returns the address for the proxy contract which would represent the given split terms.
   * @dev The contract may or may not already be deployed at the address returned.
   * Ensure that it is deployed before sending funds to this address.
   * @param shares The list of recipients and their share of the payment for this split.
   * @return splitInstance The contract address for the split contract created.
   */
  function getPredictedSplitAddress(Share[] calldata shares) external view returns (address splitInstance) {
    bytes32 salt = keccak256(abi.encode(shares));
    splitInstance = Clones.predictDeterministicAddress(address(this), salt);
  }

  /**
   * @notice Returns how many recipients are part of this split.
   * @return length The number of recipients in this split.
   */
  function getShareLength() external view returns (uint256 length) {
    length = _shares.length;
  }

  /**
   * @notice Returns a recipient in this split.
   * @param index The index of the recipient to get.
   * @return recipient The recipient at the given index.
   */
  function getShareRecipientByIndex(uint256 index) external view returns (address payable recipient) {
    recipient = _shares[index].recipient;
  }

  /**
   * @notice Returns a tuple with the terms of this split.
   * @return shares The list of recipients and their share of the payment for this split.
   */
  function getShares() external view returns (Share[] memory shares) {
    shares = new Share[](_shares.length);
    for (uint256 i = 0; i < shares.length; ) {
      shares[i] = Share({ recipient: _shares[i].recipient, percentInBasisPoints: _shares[i].percentInBasisPoints });

      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/FETH.sol";

contract $FETH is FETH {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _foundationMarket, address payable _foundationDropMarket, uint256 _lockupDuration) FETH(_foundationMarket, _foundationDropMarket, _lockupDuration) {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/FNDMiddleware.sol";

contract $FNDMiddleware is FNDMiddleware {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _market, address payable _nftDropMarket, address payable _feth, address _ens) FNDMiddleware(_market, _nftDropMarket, _feth, _ens) {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/dependencies/ens/IENS.sol";

abstract contract $IENS is IENS {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/dependencies/ens/IPublicResolver.sol";

abstract contract $IPublicResolver is IPublicResolver {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/dependencies/ens/IReverseRegistrar.sol";

abstract contract $IReverseRegistrar is IReverseRegistrar {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/dependencies/tokens/IERC20Approve.sol";

abstract contract $IERC20Approve is IERC20Approve {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/dependencies/tokens/IERC20IncreaseAllowance.sol";

abstract contract $IERC20IncreaseAllowance is IERC20IncreaseAllowance {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/internal/IFethMarket.sol";

abstract contract $IFethMarket is IFethMarket {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/internal/INFTCollectionInitializer.sol";

abstract contract $INFTCollectionInitializer is INFTCollectionInitializer {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/internal/INFTDropCollectionMint.sol";

abstract contract $INFTDropCollectionMint is INFTDropCollectionMint {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/internal/roles/IAdminRole.sol";

abstract contract $IAdminRole is IAdminRole {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/internal/roles/IOperatorRole.sol";

abstract contract $IOperatorRole is IOperatorRole {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/standards/royalties/IGetFees.sol";

abstract contract $IGetFees is IGetFees {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/standards/royalties/IGetRoyalties.sol";

abstract contract $IGetRoyalties is IGetRoyalties {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/standards/royalties/IOwnable.sol";

abstract contract $IOwnable is IOwnable {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/standards/royalties/IRoyaltyInfo.sol";

abstract contract $IRoyaltyInfo is IRoyaltyInfo {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/standards/royalties/ITokenCreator.sol";

abstract contract $ITokenCreator is ITokenCreator {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/AddressLibrary.sol";

contract $AddressLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $callAndReturnContractAddress_address_bytes_Returned(address payable arg0);

    event $callAndReturnContractAddress_CallWithoutValue_Returned(address payable arg0);

    constructor() {}

    function $callAndReturnContractAddress(address externalContract,bytes calldata callData) external payable returns (address payable) {
        (address payable ret0) = AddressLibrary.callAndReturnContractAddress(externalContract,callData);
        emit $callAndReturnContractAddress_address_bytes_Returned(ret0);
        return (ret0);
    }

    function $callAndReturnContractAddress(CallWithoutValue calldata call) external payable returns (address payable) {
        (address payable ret0) = AddressLibrary.callAndReturnContractAddress(call);
        emit $callAndReturnContractAddress_CallWithoutValue_Returned(ret0);
        return (ret0);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/ArrayLibrary.sol";

contract $ArrayLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $capLength(address payable[] calldata data,uint256 maxLength) external pure {
        return ArrayLibrary.capLength(data,maxLength);
    }

    function $capLength(uint256[] calldata data,uint256 maxLength) external pure {
        return ArrayLibrary.capLength(data,maxLength);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/BytesLibrary.sol";

contract $BytesLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $replaceAtIf(bytes calldata data,uint256 startLocation,address expectedAddress,address newAddress) external pure {
        return BytesLibrary.replaceAtIf(data,startLocation,expectedAddress,newAddress);
    }

    function $startsWith(bytes calldata callData,bytes4 functionSig) external pure returns (bool) {
        return BytesLibrary.startsWith(callData,functionSig);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/LockedBalance.sol";

contract $LockedBalance {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    mapping(uint256 => LockedBalance.Lockups) internal $v_LockedBalance_Lockups;

    constructor() {}

    function $del(uint256 lockups,uint256 index) external payable {
        return LockedBalance.del($v_LockedBalance_Lockups[lockups],index);
    }

    function $set(uint256 lockups,uint256 index,uint256 expiration,uint256 totalAmount) external payable {
        return LockedBalance.set($v_LockedBalance_Lockups[lockups],index,expiration,totalAmount);
    }

    function $setTotalAmount(uint256 lockups,uint256 index,uint256 totalAmount) external payable {
        return LockedBalance.setTotalAmount($v_LockedBalance_Lockups[lockups],index,totalAmount);
    }

    function $get(uint256 lockups,uint256 index) external view returns (LockedBalance.Lockup memory) {
        return LockedBalance.get($v_LockedBalance_Lockups[lockups],index);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/MerkleAddressLibrary.sol";

contract $MerkleAddressLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $getMerkleRootForSender(bytes32[] calldata proof) external view returns (bytes32) {
        return MerkleAddressLibrary.getMerkleRootForSender(proof);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/TimeLibrary.sol";

contract $TimeLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $hasExpired(uint256 expiry) external view returns (bool) {
        return TimeLibrary.hasExpired(expiry);
    }

    function $hasBeenReached(uint256 timestamp) external view returns (bool) {
        return TimeLibrary.hasBeenReached(timestamp);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/collections/CollectionRoyalties.sol";

abstract contract $CollectionRoyalties is CollectionRoyalties {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $__ERC165_init() external {
        return super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        return super.__ERC165_init_unchained();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/collections/SequentialMintCollection.sol";

contract $SequentialMintCollection is SequentialMintCollection {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_initializeSequentialMintCollection(address payable _creator,uint32 _maxTokenId) external {
        return super._initializeSequentialMintCollection(_creator,_maxTokenId);
    }

    function $_selfDestruct() external {
        return super._selfDestruct();
    }

    function $_updateMaxTokenId(uint32 _maxTokenId) external {
        return super._updateMaxTokenId(_maxTokenId);
    }

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $__ERC721Burnable_init() external {
        return super.__ERC721Burnable_init();
    }

    function $__ERC721Burnable_init_unchained() external {
        return super.__ERC721Burnable_init_unchained();
    }

    function $__ERC721_init(string calldata name_,string calldata symbol_) external {
        return super.__ERC721_init(name_,symbol_);
    }

    function $__ERC721_init_unchained(string calldata name_,string calldata symbol_) external {
        return super.__ERC721_init_unchained(name_,symbol_);
    }

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_safeTransfer(address from,address to,uint256 tokenId,bytes calldata data) external {
        return super._safeTransfer(from,to,tokenId,data);
    }

    function $_ownerOf(uint256 tokenId) external view returns (address) {
        return super._ownerOf(tokenId);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId,bytes calldata data) external {
        return super._safeMint(to,tokenId,data);
    }

    function $_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function $_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function $_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_requireMinted(uint256 tokenId) external view {
        return super._requireMinted(tokenId);
    }

    function $_beforeTokenTransfer(address from,address to,uint256 arg2,uint256 batchSize) external {
        return super._beforeTokenTransfer(from,to,arg2,batchSize);
    }

    function $_afterTokenTransfer(address from,address to,uint256 firstTokenId,uint256 batchSize) external {
        return super._afterTokenTransfer(from,to,firstTokenId,batchSize);
    }

    function $__ERC165_init() external {
        return super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        return super.__ERC165_init_unchained();
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftDropMarket/NFTDropMarketCore.sol";

contract $NFTDropMarketCore is NFTDropMarketCore {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftDropMarket/NFTDropMarketFixedPriceSale.sol";

abstract contract $NFTDropMarketFixedPriceSale is NFTDropMarketFixedPriceSale {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    mapping(uint256 => NFTDropMarketFixedPriceSale.FixedPriceSaleConfig) internal $v_NFTDropMarketFixedPriceSale_FixedPriceSaleConfig;

    event $_mintFromFixedPriceSale_Returned(uint256 arg0);

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable _treasury, address _feth, uint16 protocolFeeInBasisPoints, address _royaltyRegistry, bool _assumePrimarySale) FoundationTreasuryNode(_treasury) FETHNode(_feth) MarketFees(protocolFeeInBasisPoints, _royaltyRegistry, _assumePrimarySale) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_createFixedPriceSale(address nftContract,uint256 price,uint256 limitPerAccount,uint256 generalAvailabilityStartTime,uint256 earlyAccessStartTime,bytes32 merkleRoot,string calldata merkleTreeUri) external {
        return super._createFixedPriceSale(nftContract,price,limitPerAccount,generalAvailabilityStartTime,earlyAccessStartTime,merkleRoot,merkleTreeUri);
    }

    function $_mintFromFixedPriceSale(uint256 saleConfig,address nftContract,uint16 count,address payable buyReferrer) external returns (uint256) {
        (uint256 ret0) = super._mintFromFixedPriceSale($v_NFTDropMarketFixedPriceSale_FixedPriceSaleConfig[saleConfig],nftContract,count,buyReferrer);
        emit $_mintFromFixedPriceSale_Returned(ret0);
        return (ret0);
    }

    function $_getSellerOf(address nftContract,uint256 arg1) external view returns (address payable) {
        return super._getSellerOf(nftContract,arg1);
    }

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketAuction.sol";

contract $NFTMarketAuction is NFTMarketAuction {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementAuctionId_Returned(uint256 arg0);

    constructor() {}

    function $_initializeNFTMarketAuction() external {
        return super._initializeNFTMarketAuction();
    }

    function $_getNextAndIncrementAuctionId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementAuctionId();
        emit $_getNextAndIncrementAuctionId_Returned(ret0);
        return (ret0);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketBuyPrice.sol";

abstract contract $NFTMarketBuyPrice is NFTMarketBuyPrice {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_autoAcceptBuyPrice_Returned(bool arg0);

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable _treasury, address _feth, uint16 protocolFeeInBasisPoints, address _royaltyRegistry, bool _assumePrimarySale) FoundationTreasuryNode(_treasury) FETHNode(_feth) MarketFees(protocolFeeInBasisPoints, _royaltyRegistry, _assumePrimarySale) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_autoAcceptBuyPrice(address nftContract,uint256 tokenId,uint256 maxPrice) external returns (bool) {
        (bool ret0) = super._autoAcceptBuyPrice(nftContract,tokenId,maxPrice);
        emit $_autoAcceptBuyPrice_Returned(ret0);
        return (ret0);
    }

    function $_beforeAuctionStarted(address nftContract,uint256 tokenId) external {
        return super._beforeAuctionStarted(nftContract,tokenId);
    }

    function $_transferFromEscrow(address nftContract,uint256 tokenId,address recipient,address authorizeSeller) external {
        return super._transferFromEscrow(nftContract,tokenId,recipient,authorizeSeller);
    }

    function $_transferFromEscrowIfAvailable(address nftContract,uint256 tokenId,address recipient) external {
        return super._transferFromEscrowIfAvailable(nftContract,tokenId,recipient);
    }

    function $_transferToEscrow(address nftContract,uint256 tokenId) external {
        return super._transferToEscrow(nftContract,tokenId);
    }

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $__ReentrancyGuard_init() external {
        return super.__ReentrancyGuard_init();
    }

    function $__ReentrancyGuard_init_unchained() external {
        return super.__ReentrancyGuard_init_unchained();
    }

    function $_getMinIncrement(uint256 currentAmount) external pure returns (uint256) {
        return super._getMinIncrement(currentAmount);
    }

    function $_getSellerOrOwnerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOrOwnerOf(nftContract,tokenId);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketCore.sol";

abstract contract $NFTMarketCore is NFTMarketCore {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _feth) FETHNode(_feth) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_beforeAuctionStarted(address arg0,uint256 arg1) external {
        return super._beforeAuctionStarted(arg0,arg1);
    }

    function $_transferFromEscrow(address nftContract,uint256 tokenId,address recipient,address authorizeSeller) external {
        return super._transferFromEscrow(nftContract,tokenId,recipient,authorizeSeller);
    }

    function $_transferFromEscrowIfAvailable(address nftContract,uint256 tokenId,address recipient) external {
        return super._transferFromEscrowIfAvailable(nftContract,tokenId,recipient);
    }

    function $_transferToEscrow(address nftContract,uint256 tokenId) external {
        return super._transferToEscrow(nftContract,tokenId);
    }

    function $_getMinIncrement(uint256 currentAmount) external pure returns (uint256) {
        return super._getMinIncrement(currentAmount);
    }

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_getSellerOrOwnerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOrOwnerOf(nftContract,tokenId);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketExhibition.sol";

contract $NFTMarketExhibition is NFTMarketExhibition {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getAndRemoveNftFromExhibition_Returned(address payable arg0, uint16 arg1);

    constructor() {}

    function $_addNftToExhibition(address nftContract,uint256 tokenId,uint256 exhibitionId) external {
        return super._addNftToExhibition(nftContract,tokenId,exhibitionId);
    }

    function $_getAndRemoveNftFromExhibition(address nftContract,uint256 tokenId) external returns (address payable, uint16) {
        (address payable ret0, uint16 ret1) = super._getAndRemoveNftFromExhibition(nftContract,tokenId);
        emit $_getAndRemoveNftFromExhibition_Returned(ret0, ret1);
        return (ret0, ret1);
    }

    function $_removeNftFromExhibition(address nftContract,uint256 tokenId) external {
        return super._removeNftFromExhibition(nftContract,tokenId);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketOffer.sol";

abstract contract $NFTMarketOffer is NFTMarketOffer {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_autoAcceptOffer_Returned(bool arg0);

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable _treasury, address _feth, uint16 protocolFeeInBasisPoints, address _royaltyRegistry, bool _assumePrimarySale) FoundationTreasuryNode(_treasury) FETHNode(_feth) MarketFees(protocolFeeInBasisPoints, _royaltyRegistry, _assumePrimarySale) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_beforeAuctionStarted(address nftContract,uint256 tokenId) external {
        return super._beforeAuctionStarted(nftContract,tokenId);
    }

    function $_autoAcceptOffer(address nftContract,uint256 tokenId,uint256 minAmount) external returns (bool) {
        (bool ret0) = super._autoAcceptOffer(nftContract,tokenId,minAmount);
        emit $_autoAcceptOffer_Returned(ret0);
        return (ret0);
    }

    function $_cancelSendersOffer(address nftContract,uint256 tokenId) external {
        return super._cancelSendersOffer(nftContract,tokenId);
    }

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $__ReentrancyGuard_init() external {
        return super.__ReentrancyGuard_init();
    }

    function $__ReentrancyGuard_init_unchained() external {
        return super.__ReentrancyGuard_init_unchained();
    }

    function $_transferFromEscrow(address nftContract,uint256 tokenId,address recipient,address authorizeSeller) external {
        return super._transferFromEscrow(nftContract,tokenId,recipient,authorizeSeller);
    }

    function $_transferFromEscrowIfAvailable(address nftContract,uint256 tokenId,address recipient) external {
        return super._transferFromEscrowIfAvailable(nftContract,tokenId,recipient);
    }

    function $_transferToEscrow(address nftContract,uint256 tokenId) external {
        return super._transferToEscrow(nftContract,tokenId);
    }

    function $_getMinIncrement(uint256 currentAmount) external pure returns (uint256) {
        return super._getMinIncrement(currentAmount);
    }

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_getSellerOrOwnerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOrOwnerOf(nftContract,tokenId);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketPrivateSaleGap.sol";

contract $NFTMarketPrivateSaleGap is NFTMarketPrivateSaleGap {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketReserveAuction.sol";

abstract contract $NFTMarketReserveAuction is NFTMarketReserveAuction {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementAuctionId_Returned(uint256 arg0);

    event $_getAndRemoveNftFromExhibition_Returned(address payable arg0, uint16 arg1);

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable _treasury, address _feth, uint16 protocolFeeInBasisPoints, address _royaltyRegistry, bool _assumePrimarySale, uint256 duration) FoundationTreasuryNode(_treasury) FETHNode(_feth) MarketFees(protocolFeeInBasisPoints, _royaltyRegistry, _assumePrimarySale) NFTMarketReserveAuction(duration) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_transferFromEscrow(address nftContract,uint256 tokenId,address recipient,address authorizeSeller) external {
        return super._transferFromEscrow(nftContract,tokenId,recipient,authorizeSeller);
    }

    function $_transferFromEscrowIfAvailable(address nftContract,uint256 tokenId,address recipient) external {
        return super._transferFromEscrowIfAvailable(nftContract,tokenId,recipient);
    }

    function $_transferToEscrow(address nftContract,uint256 tokenId) external {
        return super._transferToEscrow(nftContract,tokenId);
    }

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_isInActiveAuction(address nftContract,uint256 tokenId) external view returns (bool) {
        return super._isInActiveAuction(nftContract,tokenId);
    }

    function $_initializeNFTMarketAuction() external {
        return super._initializeNFTMarketAuction();
    }

    function $_getNextAndIncrementAuctionId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementAuctionId();
        emit $_getNextAndIncrementAuctionId_Returned(ret0);
        return (ret0);
    }

    function $_addNftToExhibition(address nftContract,uint256 tokenId,uint256 exhibitionId) external {
        return super._addNftToExhibition(nftContract,tokenId,exhibitionId);
    }

    function $_getAndRemoveNftFromExhibition(address nftContract,uint256 tokenId) external returns (address payable, uint16) {
        (address payable ret0, uint16 ret1) = super._getAndRemoveNftFromExhibition(nftContract,tokenId);
        emit $_getAndRemoveNftFromExhibition_Returned(ret0, ret1);
        return (ret0, ret1);
    }

    function $_removeNftFromExhibition(address nftContract,uint256 tokenId) external {
        return super._removeNftFromExhibition(nftContract,tokenId);
    }

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $__ReentrancyGuard_init() external {
        return super.__ReentrancyGuard_init();
    }

    function $__ReentrancyGuard_init_unchained() external {
        return super.__ReentrancyGuard_init_unchained();
    }

    function $_beforeAuctionStarted(address arg0,uint256 arg1) external {
        return super._beforeAuctionStarted(arg0,arg1);
    }

    function $_getMinIncrement(uint256 currentAmount) external pure returns (uint256) {
        return super._getMinIncrement(currentAmount);
    }

    function $_getSellerOrOwnerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOrOwnerOf(nftContract,tokenId);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/Constants.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/ContractFactory.sol";

contract $ContractFactory is ContractFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _contractFactory) ContractFactory(_contractFactory) {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/FETHNode.sol";

contract $FETHNode is FETHNode {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _feth) FETHNode(_feth) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/FoundationTreasuryNode.sol";

contract $FoundationTreasuryNode is FoundationTreasuryNode {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _treasury) FoundationTreasuryNode(_treasury) {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/Gap10000.sol";

contract $Gap10000 is Gap10000 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/Gap500.sol";

contract $Gap500 is Gap500 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/MarketFees.sol";

abstract contract $MarketFees is MarketFees {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable _treasury, address _feth, uint16 protocolFeeInBasisPoints, address _royaltyRegistry, bool _assumePrimarySale) FoundationTreasuryNode(_treasury) FETHNode(_feth) MarketFees(protocolFeeInBasisPoints, _royaltyRegistry, _assumePrimarySale) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/MarketSharedCore.sol";

abstract contract $MarketSharedCore is MarketSharedCore {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _feth) FETHNode(_feth) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/shared/SendValueWithFallbackWithdraw.sol";

contract $SendValueWithFallbackWithdraw is SendValueWithFallbackWithdraw {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _feth) FETHNode(_feth) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/NFTCollection.sol";

contract $NFTCollection is NFTCollection {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _contractFactory) NFTCollection(_contractFactory) {}

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_initializeSequentialMintCollection(address payable _creator,uint32 _maxTokenId) external {
        return super._initializeSequentialMintCollection(_creator,_maxTokenId);
    }

    function $_selfDestruct() external {
        return super._selfDestruct();
    }

    function $_updateMaxTokenId(uint32 _maxTokenId) external {
        return super._updateMaxTokenId(_maxTokenId);
    }

    function $__ERC721Burnable_init() external {
        return super.__ERC721Burnable_init();
    }

    function $__ERC721Burnable_init_unchained() external {
        return super.__ERC721Burnable_init_unchained();
    }

    function $__ERC721_init(string calldata name_,string calldata symbol_) external {
        return super.__ERC721_init(name_,symbol_);
    }

    function $__ERC721_init_unchained(string calldata name_,string calldata symbol_) external {
        return super.__ERC721_init_unchained(name_,symbol_);
    }

    function $_safeTransfer(address from,address to,uint256 tokenId,bytes calldata data) external {
        return super._safeTransfer(from,to,tokenId,data);
    }

    function $_ownerOf(uint256 tokenId) external view returns (address) {
        return super._ownerOf(tokenId);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId,bytes calldata data) external {
        return super._safeMint(to,tokenId,data);
    }

    function $_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function $_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function $_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_requireMinted(uint256 tokenId) external view {
        return super._requireMinted(tokenId);
    }

    function $_beforeTokenTransfer(address from,address to,uint256 arg2,uint256 batchSize) external {
        return super._beforeTokenTransfer(from,to,arg2,batchSize);
    }

    function $_afterTokenTransfer(address from,address to,uint256 firstTokenId,uint256 batchSize) external {
        return super._afterTokenTransfer(from,to,firstTokenId,batchSize);
    }

    function $__ERC165_init() external {
        return super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        return super.__ERC165_init_unchained();
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/NFTDropMarket.sol";

contract $NFTDropMarket is NFTDropMarket {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    mapping(uint256 => NFTDropMarketFixedPriceSale.FixedPriceSaleConfig) internal $v_NFTDropMarketFixedPriceSale_FixedPriceSaleConfig;

    event $_mintFromFixedPriceSale_Returned(uint256 arg0);

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable treasury, address feth, address royaltyRegistry) NFTDropMarket(treasury, feth, royaltyRegistry) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_getSellerOrOwnerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOrOwnerOf(nftContract,tokenId);
    }

    function $_createFixedPriceSale(address nftContract,uint256 price,uint256 limitPerAccount,uint256 generalAvailabilityStartTime,uint256 earlyAccessStartTime,bytes32 merkleRoot,string calldata merkleTreeUri) external {
        return super._createFixedPriceSale(nftContract,price,limitPerAccount,generalAvailabilityStartTime,earlyAccessStartTime,merkleRoot,merkleTreeUri);
    }

    function $_mintFromFixedPriceSale(uint256 saleConfig,address nftContract,uint16 count,address payable buyReferrer) external returns (uint256) {
        (uint256 ret0) = super._mintFromFixedPriceSale($v_NFTDropMarketFixedPriceSale_FixedPriceSaleConfig[saleConfig],nftContract,count,buyReferrer);
        emit $_mintFromFixedPriceSale_Returned(ret0);
        return (ret0);
    }

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $__ReentrancyGuard_init() external {
        return super.__ReentrancyGuard_init();
    }

    function $__ReentrancyGuard_init_unchained() external {
        return super.__ReentrancyGuard_init_unchained();
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/NFTMarket.sol";

contract $NFTMarket is NFTMarket {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_autoAcceptOffer_Returned(bool arg0);

    event $_autoAcceptBuyPrice_Returned(bool arg0);

    event $_getNextAndIncrementAuctionId_Returned(uint256 arg0);

    event $_getAndRemoveNftFromExhibition_Returned(address payable arg0, uint16 arg1);

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable treasury, address feth, address royaltyRegistry, uint256 duration) NFTMarket(treasury, feth, royaltyRegistry, duration) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_beforeAuctionStarted(address nftContract,uint256 tokenId) external {
        return super._beforeAuctionStarted(nftContract,tokenId);
    }

    function $_transferFromEscrow(address nftContract,uint256 tokenId,address recipient,address authorizeSeller) external {
        return super._transferFromEscrow(nftContract,tokenId,recipient,authorizeSeller);
    }

    function $_transferFromEscrowIfAvailable(address nftContract,uint256 tokenId,address recipient) external {
        return super._transferFromEscrowIfAvailable(nftContract,tokenId,recipient);
    }

    function $_transferToEscrow(address nftContract,uint256 tokenId) external {
        return super._transferToEscrow(nftContract,tokenId);
    }

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_autoAcceptOffer(address nftContract,uint256 tokenId,uint256 minAmount) external returns (bool) {
        (bool ret0) = super._autoAcceptOffer(nftContract,tokenId,minAmount);
        emit $_autoAcceptOffer_Returned(ret0);
        return (ret0);
    }

    function $_cancelSendersOffer(address nftContract,uint256 tokenId) external {
        return super._cancelSendersOffer(nftContract,tokenId);
    }

    function $_autoAcceptBuyPrice(address nftContract,uint256 tokenId,uint256 maxPrice) external returns (bool) {
        (bool ret0) = super._autoAcceptBuyPrice(nftContract,tokenId,maxPrice);
        emit $_autoAcceptBuyPrice_Returned(ret0);
        return (ret0);
    }

    function $_isInActiveAuction(address nftContract,uint256 tokenId) external view returns (bool) {
        return super._isInActiveAuction(nftContract,tokenId);
    }

    function $_initializeNFTMarketAuction() external {
        return super._initializeNFTMarketAuction();
    }

    function $_getNextAndIncrementAuctionId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementAuctionId();
        emit $_getNextAndIncrementAuctionId_Returned(ret0);
        return (ret0);
    }

    function $_addNftToExhibition(address nftContract,uint256 tokenId,uint256 exhibitionId) external {
        return super._addNftToExhibition(nftContract,tokenId,exhibitionId);
    }

    function $_getAndRemoveNftFromExhibition(address nftContract,uint256 tokenId) external returns (address payable, uint16) {
        (address payable ret0, uint16 ret1) = super._getAndRemoveNftFromExhibition(nftContract,tokenId);
        emit $_getAndRemoveNftFromExhibition_Returned(ret0, ret1);
        return (ret0, ret1);
    }

    function $_removeNftFromExhibition(address nftContract,uint256 tokenId) external {
        return super._removeNftFromExhibition(nftContract,tokenId);
    }

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $__ReentrancyGuard_init() external {
        return super.__ReentrancyGuard_init();
    }

    function $__ReentrancyGuard_init_unchained() external {
        return super.__ReentrancyGuard_init_unchained();
    }

    function $_getMinIncrement(uint256 currentAmount) external pure returns (uint256) {
        return super._getMinIncrement(currentAmount);
    }

    function $_getSellerOrOwnerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOrOwnerOf(nftContract,tokenId);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/PercentSplitETH.sol";

contract $PercentSplitETH is PercentSplitETH {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}