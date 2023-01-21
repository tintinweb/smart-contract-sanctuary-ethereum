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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/ERC721.sol)

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

        _beforeTokenTransfer(address(0), to, tokenId);

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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _beforeTokenTransfer(owner, address(0), tokenId);

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

        _afterTokenTransfer(owner, address(0), tokenId);
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

        _beforeTokenTransfer(from, to, tokenId);

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

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
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

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/extensions/ERC721Enumerable.sol)

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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and 'to' cannot be the zero address at the same time.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
     * @dev Hook that is called before any batch token transfer. For now this is limited
     * to batch minting by the {ERC721Consecutive} extension.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96 size
    ) internal virtual override {
        // We revert because enumerability is not supported with consecutive batch minting.
        // This conditional is only needed to silence spurious warnings about unreachable code.
        if (size > 0) {
            revert("ERC721Enumerable: consecutive transfers not supported");
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        address owner = _owners[tokenId];
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
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccess is Ownable {
    mapping(address => bool) public admins;
    address public genartAdmin;

    constructor() Ownable() {
        genartAdmin = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the GEN.ART admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genartAdmin == sender,
            "GenArtAccess: caller is not genart admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genartAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccessUpgradable is OwnableUpgradeable {
    mapping(address => bool) public admins;
    address public genArtAdmin;

    function __GenArtAccessUpgradable_init(address owner, address admin)
        internal
        onlyInitializing
    {
        __GenArtAccessUpgradable_init_unchained(owner, admin);
    }

    function __GenArtAccessUpgradable_init_unchained(
        address owner,
        address admin
    ) internal onlyInitializing {
        _transferOwnership(owner);
        genArtAdmin = owner;
        admins[admin] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccessUpgradable: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the ECLIPSE admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genArtAdmin == sender,
            "GenArtAccessUpgradable: caller is not eclipse admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genArtAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../storage/GenArtStorage.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtMinter.sol";
import "../factory/GenArtCollectionFactory.sol";
import "../factory/GenArtPaymentSplitterFactory.sol";

/**
 * @dev GEN.ART Curated
 * Admin of {GenArtCollectionFactory} and {GenArtPaymentSplitterFactory}
 */

struct CreateCollectionParams {
    address artist;
    string name;
    string symbol;
    string script;
    uint8 collectionType;
    uint256 maxSupply;
    uint8 erc721Index;
    uint8 pricingMode;
    bytes pricingData;
    uint8 paymentSplitterIndex;
    address[] payeesMint;
    address[] payeesRoyalties;
    uint256[] sharesMint;
    uint256[] sharesRoyalties;
}
struct PricingParams {
    uint8 mode;
    bytes data;
}

struct CollectionInfo {
    string name;
    string symbol;
    address minter;
    Collection collection;
    Artist artist;
}

contract GenArtCurated is GenArtAccess {
    address public collectionFactory;
    address public paymentSplitterFactory;
    GenArtStorage public store;
    mapping(uint8 => address) public minters;

    event ScriptUpdated(address collection, string script);

    constructor(
        address collectionFactory_,
        address paymentSplitterFactory_,
        address store_
    ) {
        collectionFactory = collectionFactory_;
        paymentSplitterFactory = paymentSplitterFactory_;
        store = GenArtStorage(payable(store_));
    }

    /**
     * @dev Internal functtion to close the ERC721 implementation contract
     */
    function _cloneCollection(CollectionParams memory params)
        internal
        returns (address instance, uint256 id)
    {
        return
            GenArtCollectionFactory(collectionFactory).cloneCollectionContract(
                params
            );
    }

    /**
     * @dev Internal functtion to create the collection and risgister to minter
     */
    function _createCollection(CollectionParams memory params)
        internal
        returns (address instance, uint256 id)
    {
        (instance, id) = _cloneCollection(params);
        store.setCollection(
            Collection(
                id,
                params.artist,
                instance,
                params.maxSupply,
                params.script,
                params.paymentSplitter
            )
        );
    }

    /**
     * @dev Clones an ERC721 implementation contract
     * @param params params
     * @dev artist address of artist
     * @dev name name of collection
     * @dev symbol ERC721 symbol for collection
     * @dev script single html as string
     * @dev maxSupply max token supply
     * @dev erc721Index ERC721 implementation index
     * @dev pricingMode minter index
     * @dev pricingData calldata for `setPricing` function
     * @dev payeesMint address list of payees of mint proceeds
     * @dev payeesRoyalties address list of payees of royalties
     * @dev sharesMint list of shares for mint proceeds
     * @dev sharesRoyalties list of shares for royalties
     * Note payee and shares indices must be in respective order
     */
    function createCollection(CreateCollectionParams calldata params)
        external
        onlyAdmin
    {
        address artistAddress = params.artist;
        address minter = minters[params.pricingMode];
        _createArtist(artistAddress);
        address paymentSplitter = GenArtPaymentSplitterFactory(
            paymentSplitterFactory
        ).clone(
                genartAdmin,
                artistAddress,
                params.paymentSplitterIndex,
                params.payeesMint,
                params.payeesRoyalties,
                params.sharesMint,
                params.sharesRoyalties
            );
        address instance = GenArtCollectionFactory(collectionFactory)
            .predictDeterministicAddress(params.erc721Index);
        uint256 price = IGenArtMinter(minter).setPricing(
            instance,
            params.pricingData
        );
        _createCollection(
            CollectionParams(
                artistAddress,
                params.name,
                params.symbol,
                price,
                params.script,
                params.collectionType,
                params.maxSupply,
                params.erc721Index,
                minter,
                paymentSplitter
            )
        );
    }

    /**
     * @dev Internal helper method to create artist
     * @param artist address of artist
     */
    function _createArtist(address artist) internal {
        if (store.getArtist(artist).wallet != address(0)) return;
        address[] memory collections_;
        store.setArtist(Artist(artist, collections_));
    }

    /**
     * @dev Set the {GenArtCollectionFactory} contract address
     */
    function setCollectionFactory(address factory) external onlyAdmin {
        collectionFactory = factory;
    }

    /**
     * @dev Set the {GenArtPaymentSplitterFactory} contract address
     */
    function setPaymentSplitterFactory(address factory) external onlyAdmin {
        paymentSplitterFactory = factory;
    }

    /**
     * @dev Add a minter contract and map by index
     */
    function addMinter(uint8 index, address minter) external onlyAdmin {
        minters[index] = minter;
    }

    /**
     * @dev Get collection info
     * @param collection contract address of the collection
     */
    function getCollectionInfo(address collection)
        external
        view
        returns (CollectionInfo memory info)
    {
        (
            string memory name,
            string memory symbol,
            address artist,
            address minter,
            ,
            ,

        ) = IGenArtERC721(collection).getInfo();
        Artist memory artist_ = store.getArtist(artist);

        info = CollectionInfo(
            name,
            symbol,
            minter,
            store.getCollection(collection),
            artist_
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../access/GenArtAccess.sol";
import "../interface/IGenArtMinter.sol";

/**
 * GenArt ERC721 contract factory
 */

struct CollectionParams {
    address artist;
    string name;
    string symbol;
    uint256 price;
    string script;
    uint8 collectionType;
    uint256 maxSupply;
    uint8 erc721Index;
    address minter;
    address paymentSplitter;
}
struct CollectionType {
    string name;
    uint256 prefix;
    uint256 lastId;
}
struct CollectionCreatedEvent {
    uint256 id;
    address contractAddress;
    uint8 collectionType;
    address artist;
    string name;
    string symbol;
    uint256 price;
    string script;
    uint256 maxSupply;
    address minter;
    address implementation;
    address paymentSplitter;
}

contract GenArtCollectionFactory is GenArtAccess {
    mapping(uint8 => address) public erc721Implementations;
    mapping(uint8 => CollectionType) public collectionTypes;
    string public uri;

    event Created(CollectionCreatedEvent collection);

    constructor(string memory uri_) GenArtAccess() {
        uri = uri_;
        collectionTypes[0] = CollectionType("js", 30003, 0);
    }

    /**
     * @dev Get next collection id
     */
    function _getNextCollectionId(uint8 collectioType)
        internal
        returns (uint256)
    {
        CollectionType memory obj = collectionTypes[collectioType];
        uint256 id = obj.prefix + obj.lastId + 1;
        collectionTypes[collectioType].lastId += 1;
        return id;
    }

    /**
     * @dev Create initializer for clone
     * Note The method signature is created on chain to prevent malicious initialization args
     */
    function _createInitializer(
        uint256 id,
        address artist,
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address minter,
        address paymentSplitter
    ) internal view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(string,string,string,uint256,uint256,address,address,address,address)",
                name,
                symbol,
                uri,
                id,
                maxSupply,
                genartAdmin,
                artist,
                minter,
                paymentSplitter
            );
    }

    /**
     * @dev Cone an implementation contract
     */
    function cloneCollectionContract(CollectionParams memory params)
        external
        onlyAdmin
        returns (address, uint256)
    {
        address implementation = erc721Implementations[params.erc721Index];
        require(implementation != address(0), "invalid erc721Index");
        uint256 id = _getNextCollectionId(params.collectionType);
        bytes memory initializer = _createInitializer(
            id,
            params.artist,
            params.name,
            params.symbol,
            params.maxSupply,
            params.minter,
            params.paymentSplitter
        );
        address instance = Clones.cloneDeterministic(
            implementation,
            bytes32(block.number)
        );
        Address.functionCall(instance, initializer);
        emit Created(
            CollectionCreatedEvent(
                id,
                instance,
                params.collectionType,
                params.artist,
                params.name,
                params.symbol,
                params.price,
                params.script,
                params.maxSupply,
                params.minter,
                implementation,
                params.paymentSplitter
            )
        );
        return (instance, id);
    }

    /**
     * @dev Add an ERC721 implementation contract and map by index
     */
    function addErc721Implementation(uint8 index, address implementation)
        external
        onlyAdmin
    {
        erc721Implementations[index] = implementation;
    }

    /**
     * @dev Add a collectionType and map by index
     */
    function addCollectionType(
        uint8 index,
        string memory name,
        uint256 prefix,
        uint256 lastId
    ) external onlyAdmin {
        collectionTypes[index] = CollectionType(name, prefix, lastId);
    }

    /**
     * @dev Sets the base tokenURI for collections
     */
    function setUri(string memory uri_) external onlyAdmin {
        uri = uri_;
    }

    /**
     * @dev Predict contract address for new collection
     */
    function predictDeterministicAddress(uint8 erc721Index)
        external
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                erc721Implementations[erc721Index],
                bytes32(block.number),
                address(this)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../access/GenArtAccess.sol";

/**
 * GEN.ART {GenArtPaymentSplitter} contract factory
 */

contract GenArtPaymentSplitterFactory is GenArtAccess {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }
    mapping(uint8 => address) public implementations;

    event Created(
        address contractAddress,
        address artist,
        address[] payeesMint,
        address[] payeesRoyalties,
        uint256[] sharesMint,
        uint256[] sharesRoyalties
    );

    constructor(address implementation_) GenArtAccess() {
        implementations[0] = implementation_;
    }

    /**
     * @dev Intenal helper method to create initializer
     */
    function _createInitializer(
        address owner,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address[],address[],uint256[],uint256[])",
                owner,
                payeesMint,
                payeesRoyalties,
                sharesMint,
                sharesRoyalties
            );
    }

    /**
     * @dev Cone a {PaymentSplitter} implementation contract
     */
    function clone(
        address owner,
        address artist,
        uint8 implementation,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) external onlyAdmin returns (address) {
        bytes memory initializer = _createInitializer(
            owner,
            payeesMint,
            payeesRoyalties,
            sharesMint,
            sharesRoyalties
        );
        address instance = Clones.clone(implementations[implementation]);
        Address.functionCall(instance, initializer);
        emit Created(
            instance,
            artist,
            payeesMint,
            payeesRoyalties,
            sharesMint,
            sharesRoyalties
        );
        return instance;
    }

    /**
     * @dev Set the {GenArtPaymentSplitter} implementation
     */
    function setImplementation(uint8 index, address implementation_)
        external
        onlyAdmin
    {
        implementations[index] = implementation_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../access/GenArtAccessUpgradable.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";
import "../interface/IGenArtERC721.sol";

/**
 * @dev GEN.ART ERC721 V4
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 */

contract GenArtERC721V4 is
    ERC721EnumerableUpgradeable,
    GenArtAccessUpgradable,
    IGenArtERC721
{
    struct CollectionInfo {
        uint256 id;
        uint256 maxSupply;
        address artist;
    }

    CollectionInfo public _info;
    address public _royaltyReceiver;
    address public _mainMinter;
    mapping(address => bool) public _minters;

    string private _uri;

    bool public _reservedMinted = false;
    bool public _paused = true;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to,
        bytes32 hash
    );

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize contract
     * Note This method has to be called right after the creation of the clone.
     * If not, the contract can be taken over by some attacker.
     */

    function initialize(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 id,
        uint256 maxSupply,
        address admin,
        address artist,
        address minter,
        address paymentSplitter
    ) public override initializer {
        __GenArtAccessUpgradable_init(admin, artist);
        __ERC721_init(name, symbol);
        _uri = uri;
        _info = CollectionInfo(id, maxSupply, artist);
        _minters[minter] = true;
        _mainMinter = minter;
        _royaltyReceiver = paymentSplitter;
    }

    /**
     * @dev Helper method to check allowed minters
     */
    function _checkMint() internal view {
        require(_minters[_msgSender()], "only minter allowed");
    }

    /**
     * @dev Mint a token
     * @param to address to mint to
     * @param membershipId address to mint to
     */
    function mint(address to, uint256 membershipId) external override {
        _checkMint();
        _mintOne(to, membershipId);
    }

    /**
     * @dev Creates the token and its hash
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _info.id * 100_000 + totalSupply() + 1;
        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, block.timestamp, to)
        );
        _safeMint(to, tokenId);
        emit Mint(tokenId, _info.id, membershipId, to, hash);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((IGenArtPaymentSplitterV5(_royaltyReceiver).getTotalShares(1)) *
                salePrice_) / 10_000
        );
    }

    /**
     *@dev Get collection info
     */
    function getInfo()
        external
        view
        virtual
        override
        returns (
            string memory,
            string memory,
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            name(),
            symbol(),
            _info.artist,
            _mainMinter,
            _info.id,
            _info.maxSupply,
            totalSupply()
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        external
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint. Token will be sent to sender
     */
    function mintReserved() public onlyAdmin {
        require(!_reservedMinted, "GenArtERC721: reserved already minted");
        _mintOne(msg.sender, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     *@dev add minter
     */
    function setMinter(
        address minter,
        bool enable,
        bool mainMinter
    ) public onlyGenArtAdmin {
        _minters[minter] = enable;
        if (enable && mainMinter) {
            _mainMinter = minter;
        }
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../access/GenArtAccessUpgradable.sol";
import "../interface/IGenArtPaymentSplitterV4.sol";

contract GenArtPaymentSplitterV4 is
    Initializable,
    GenArtAccessUpgradable,
    IGenArtPaymentSplitterV4
{
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(uint256 paymentType, address payee, uint256 amount);

    mapping(address => uint256) public _ethBalances;
    Payment private _payment;
    Payment private _paymentRoyalties;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) public initializer {
        __GenArtAccessUpgradable_init(owner, owner);
        _payment = Payment(payeesMint, sharesMint);
        _paymentRoyalties = Payment(payeesRoyalties, sharesRoyalties);
    }

    function splitPayment() external payable override {
        uint256 value = msg.value;
        require(value > 0, "nothing to receive");
        uint256 totalShares = getTotalShares(0);
        for (uint8 i; i < _payment.payees.length; i++) {
            address payee = _payment.payees[i];
            uint256 ethAmount = (value * _payment.shares[i]) / totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty() internal {
        uint256 totalShares = getTotalShares(1);
        for (uint8 i; i < _paymentRoyalties.payees.length; i++) {
            address payee = _paymentRoyalties.payees[i];
            uint256 ethAmount = (msg.value * _paymentRoyalties.shares[i]) /
                totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(1, payee, ethAmount);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentRoyalties
     */
    function getTotalShares(uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        Payment memory payment = paymentType == 0
            ? _payment
            : _paymentRoyalties;
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) external override {
        uint256 amount = _ethBalances[account];
        require(amount > 0, "no funds to release");
        _ethBalances[account] = 0;
        payable(account).transfer(amount);
    }

    function releaseTokens(address token) external {
        uint256 totalShares = getTotalShares(1);
        uint256 totalBalance = IERC20(token).balanceOf(address(this));
        require(totalBalance > 0, "no funds to release");

        for (uint8 i; i < _paymentRoyalties.payees.length; i++) {
            address payee = _paymentRoyalties.payees[i];
            uint256 amount = (totalBalance * _paymentRoyalties.shares[i]) /
                totalShares;
            IERC20(token).transfer(payee, amount);
            emit IncomingPayment(1, payee, amount);
        }
    }

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external override {
        Payment storage payment = paymentType == 0
            ? _payment
            : _paymentRoyalties;
        address oldPayee = payment.payees[payeeIndex];
        require(oldPayee == _msgSender(), "sender is not current payee");
        payment.payees[payeeIndex] = newPayee;
    }

    receive() external payable {
        splitPaymentRoyalty();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../access/GenArtAccessUpgradable.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";

contract GenArtPaymentSplitterV5 is
    Initializable,
    GenArtAccessUpgradable,
    IGenArtPaymentSplitterV5
{
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(uint256 paymentType, address payee, uint256 amount);

    mapping(address => uint256) public _ethBalances;

    Payment private _payment;
    Payment private _paymentRoyalties;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) public initializer {
        __GenArtAccessUpgradable_init(owner, owner);
        _payment = Payment(payeesMint, sharesMint);
        _paymentRoyalties = Payment(payeesRoyalties, sharesRoyalties);
    }

    function splitPayment(uint256 mintValue) external payable override {
        uint256 value = msg.value;
        require(value > 0, "nothing to receive");
        uint256 loyaltyBps = ((mintValue - value) * 1000) / mintValue;
        uint256 totalShares = (getTotalShares(0) * 1000) / (1000 - loyaltyBps);

        for (uint8 i; i < _payment.payees.length; i++) {
            address payee = _payment.payees[i];
            uint256 ethAmount = (mintValue * _payment.shares[i]) / totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty() internal {
        uint256 totalShares = getTotalShares(1);
        for (uint8 i; i < _paymentRoyalties.payees.length; i++) {
            address payee = _paymentRoyalties.payees[i];
            uint256 ethAmount = (msg.value * _paymentRoyalties.shares[i]) /
                totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(1, payee, ethAmount);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentRoyalties
     */
    function getTotalShares(uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        Payment memory payment = paymentType == 0
            ? _payment
            : _paymentRoyalties;
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) external override {
        uint256 amount = _ethBalances[account];
        require(amount > 0, "no funds to release");
        _ethBalances[account] = 0;
        payable(account).transfer(amount);
    }

    function releaseTokens(address token) external {
        uint256 totalShares = getTotalShares(1);
        uint256 totalBalance = IERC20(token).balanceOf(address(this));
        require(totalBalance > 0, "no funds to release");

        for (uint8 i; i < _paymentRoyalties.payees.length; i++) {
            address payee = _paymentRoyalties.payees[i];
            uint256 amount = (totalBalance * _paymentRoyalties.shares[i]) /
                totalShares;
            IERC20(token).transfer(payee, amount);
            emit IncomingPayment(1, payee, amount);
        }
    }

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external override {
        Payment storage payment = paymentType == 0
            ? _payment
            : _paymentRoyalties;
        address oldPayee = payment.payees[payeeIndex];
        require(oldPayee == _msgSender(), "sender is not current payee");
        payment.payees[payeeIndex] = newPayee;
    }

    receive() external payable {
        splitPaymentRoyalty();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArt {
    function isGoldToken(uint256 _membershipId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";

interface IGenArtERC721 is
    IERC721MetadataUpgradeable,
    IERC2981Upgradeable,
    IERC721EnumerableUpgradeable
{
    function initialize(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 id,
        uint256 maxSupply,
        address admin,
        address artist,
        address minter,
        address paymentSplitter
    ) external;

    function getTokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function getInfo()
        external
        view
        returns (
            string memory,
            string memory,
            address,
            address,
            uint256,
            uint256,
            uint256
        );

    function mint(address to, uint256 membershipId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterface {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV4 {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId)
        external
        view
        returns (address, bool);

    function isVaulted(uint256 _membershipId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtMintAllocator {
    function init(address collection, uint8[3] memory mintAlloc) external;

    function update(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) external;

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256);

    function setReservedGold(address collection, uint8 reservedGold) external;

    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtMinter {
    function mintOne(address collection, uint256 membershipId) external payable;

    function mint(address collection, uint256 amount) external payable;

    function getPrice(address collection) external view returns (uint256);

    function setPricing(address collection, bytes memory data)
        external
        returns (uint256);

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256);

    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitterV4 {
    function splitPayment() external payable;

    function getTotalShares(uint8 _payment) external view returns (uint256);

    function release(address account) external;

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitterV5 {
    function splitPayment(uint256 mintValue) external payable;

    function getTotalShares(uint8 _payment) external view returns (uint256);

    function release(address account) external;

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Gen Art ERC721 Membership Token
 */

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

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
    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            "EnumerableMap: index out of bounds"
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key)
        private
        view
        returns (bool, bytes32)
    {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool, address)
    {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return
            address(
                uint160(uint256(_get(map._inner, bytes32(key), errorMessage)))
            );
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    address payable private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address payable) {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract GenArt is
    Ownable,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    event Mint(address indexed to, uint256 tokenId, bool isGold);

    uint256 MAX_MEMBERS = 5000;
    uint256 MAX_MEMBERS_GOLD = 100;
    uint256 MEMBERSHIP_PRICE = 100000000000000000; // 0.1 ETH
    uint256 MEMBERSHIP_GOLD_PRICE = 500000000000000000; // 0.5 ETH

    bool private _paused = true;
    uint256 _reservedTokens = 20;
    uint256 _reservedTokensGold = 5;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    string private _uri_standard;
    string private _uri_gold;
    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;
    mapping(uint256 => bool) private _goldTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;
    EnumerableMap.UintToAddressMap private _goldOwners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_standard_,
        string memory uri_gold_,
        uint256 max_members_
    ) public {
        _name = name_;
        _symbol = symbol_;
        _uri_standard = uri_standard_;
        _uri_gold = uri_gold_;
        MAX_MEMBERS = max_members_;
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function mint(address _to) public payable {
        require(!_paused, "minting is paused");
        require(msg.value >= MEMBERSHIP_PRICE, "wrong amount sent");
        uint256 _totalSupplyGold = totalGoldOwners();
        uint256 _totalSupply = totalSupply() - _totalSupplyGold;
        require(_totalSupply < MAX_MEMBERS, "mint would exceed totalSupply");
        uint256 _tokenId = _totalSupply + 1;
        _safeMint(_to, _tokenId);
        emit Mint(_to, _tokenId, false);
    }

    function mintMany(address _to, uint256 amount) public payable {
        require(!_paused, "minting is paused");
        require(msg.value >= (MEMBERSHIP_PRICE * amount), "wrong amount sent");
        _mintMany(_to, amount);
    }

    function mintGold(address _to) public payable {
        require(!_paused, "minting is paused");
        require(msg.value >= MEMBERSHIP_GOLD_PRICE, "wrong amount sent");
        _mintGold(_to);
    }

    function _mintGold(address _to) internal virtual {
        uint256 _totalSupply = totalGoldOwners();
        uint256 _tokenId = MAX_MEMBERS + _totalSupply + 1;
        require(
            _tokenId <= MAX_MEMBERS + MAX_MEMBERS_GOLD,
            "mint would exceed totalSupply"
        );
        _goldOwners.set(_tokenId, _to);
        _safeMint(_to, _tokenId);
        emit Mint(_to, _tokenId, true);
    }

    function _mintMany(address _to, uint256 _amount) internal {
        require(_to != address(0), "mint to the zero address");
        uint256 _totalSupplyGold = totalGoldOwners();
        uint256 _totalSupply = totalSupply() - _totalSupplyGold;
        require(
            (_totalSupply + _amount) <= MAX_MEMBERS,
            "mint would exceed totalSupply"
        );
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = _totalSupply + 1 + i;
            _safeMint(_to, _tokenId);
            emit Mint(_to, _tokenId, false);
        }
    }

    function withdraw(uint256 value) public onlyOwner {
        address payable _owner = owner();
        _owner.transfer(value);
    }

    function setPaused(bool _isPaused) public onlyOwner {
        _paused = _isPaused;
    }

    function setUriStandard(string memory _uri) public onlyOwner {
        _uri_standard = _uri;
    }

    function setUriGold(string memory _uri) public onlyOwner {
        _uri_gold = _uri;
    }

    function mintReservedGold(address _to) public onlyOwner {
        uint256 _totalSupply = totalGoldOwners();
        require(
            _totalSupply < MAX_MEMBERS_GOLD,
            "mint exceeds Gold totalSupply"
        );
        _mintGold(_to);
        _reservedTokensGold = _reservedTokensGold - 1;
    }

    function mintReserved(address _to, uint256 _amount) public onlyOwner {
        require(
            _amount <= _reservedTokens,
            "reserved token mint exceeds limit"
        );
        uint256 _totalSupply = totalSupply();
        require(
            (_totalSupply + _amount) <= MAX_MEMBERS,
            "mint exceeds totalSupply"
        );
        _mintMany(_to, _amount);
        _reservedTokens = _reservedTokens - _amount;
    }

    function totalGoldOwners() public view returns (uint256) {
        return _goldOwners.length();
    }

    function isGoldToken(uint256 _tokenId) public view returns (bool) {
        return int256(_tokenId) - int256(MAX_MEMBERS) > 0;
    }

    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "owner query for nonexistent token");
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        bool isGold = isGoldToken(tokenId);

        if (isGold) {
            return _uri_gold;
        }

        return _uri_standard;
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = GenArt.ownerOf(tokenId);
        require(to != owner, "approval to current owner");
        address sender = _msgSender();
        require(
            sender == owner || GenArt.isApprovedForAll(owner, sender),
            "approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(_exists(tokenId), "approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        address sender = _msgSender();
        require(operator != sender, "approve to caller");

        _operatorApprovals[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        address sender = _msgSender();
        require(
            _isApprovedOrOwner(sender, tokenId),
            "transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        address sender = _msgSender();

        require(
            _isApprovedOrOwner(sender, tokenId),
            "transfer caller is not owner nor approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "transfer to non ERC721Receiver implementer"
        );
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
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "operator query for nonexistent token");
        address owner = GenArt.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            GenArt.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "transfer to non ERC721Receiver implementer"
        );
        _mint(to, tokenId);
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
        require(!_exists(tokenId), "token already minted");
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);
        emit Transfer(address(0), to, tokenId);
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
        require(
            GenArt.ownerOf(tokenId) == from,
            "transfer of token that is not own"
        ); // internal owner
        require(to != address(0), "transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ),
            "transfer to non ERC721Receiver implementer"
        );
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(GenArt.ownerOf(tokenId), to, tokenId); // internal owner
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccess is Ownable {
    mapping(address => bool) public admins;
    address public genartAdmin;

    constructor() Ownable() {
        genartAdmin = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the GEN.ART admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genartAdmin == sender,
            "GenArtAccess: caller is not genart admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genartAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./GenArtAccess.sol";
import "./MintStates.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitter.sol";
import "./IGenArtInterfaceV2.sol";

/**
 * @dev GEN.ART ERC721 V1
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721 is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStates for MintStates.State;

    uint256 public _mintPrice;
    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _artist;
    address public _paymentSplitter;
    address public _genartInterface;
    address public _genartMembership;
    string private _uri;
    bool public _paused = true;

    MintStates.State public _mintstate;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 collectionId_,
        uint256 mintPrice_,
        uint256 mintSupply_,
        uint256 reservedGold_,
        address genartMembership_,
        address genartInterface_,
        address paymentSplitter_,
        address artist_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _collectionId = collectionId_;
        _mintPrice = mintPrice_;
        _mintSupply = mintSupply_;
        _mintstate.init(reservedGold_);
        _genartMembership = genartMembership_;
        _genartInterface = genartInterface_;
        _paymentSplitter = paymentSplitter_;
        _artist = artist_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get available mints for an account
     */
    function getAvailableMintsForAccount(address account)
        public
        view
        returns (uint256)
    {
        uint256[] memory memberships = IGenArtMembership(_genartMembership)
            .getTokensByOwner(account);

        uint256 availableMints;
        for (uint256 i; i < memberships.length; i++) {
            availableMints += _mintstate.getAvailableMints(
                memberships[i],
                IGenArtInterfaceV2(_genartInterface).isGoldToken(
                    memberships[i]
                ),
                _mintSupply,
                totalSupply()
            );
        }
        return availableMints;
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate.getAvailableMints(
                membershipId,
                IGenArtInterfaceV2(_genartInterface).isGoldToken(membershipId),
                _mintSupply,
                totalSupply()
            );
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _mintstate.getMints(membershipId);
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(uint256 amount, uint256 availableMints) internal view {
        require(!_paused, "GenArtERC721: minting is paused");
        require(availableMints > 0, "GenArtERC721: no mints available");
        require(
            availableMints >= amount,
            "GenArtERC721: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _mintPrice * amount;
        }
        require(
            ethAmount <= msg.value,
            "GenArtERC721: transaction underpriced"
        );
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = getAvailableMintsForAccount(_msgSender());
        checkMint(amount, availableMints);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtMembership(_genartMembership)
            .getTokensByOwner(_msgSender());
        uint256 minted;
        uint256 i;

        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // check if membership is gold
            bool isGold = IGenArtInterfaceV2(_genartInterface).isGoldToken(
                memberships[i]
            );
            // get available mints for membership
            uint256 mints = _mintstate.getAvailableMints(
                memberships[i],
                isGold,
                _mintSupply,
                totalSupply()
            );
            // mint tokens with membership and stop if desired amount reached
            for (uint256 j; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i], isGold);
                minted++;
            }
            i++;
        }
        // send funds to PaymentSplitter
        IGenArtPaymentSplitter(_paymentSplitter).splitPayment{value: msg.value}(
            address(this)
        );
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterfaceV2(_genartInterface).ownerOf(membershipId) ==
                _msgSender(),
            "GenArtERC721: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints);
        // mint token
        mintForMembership(
            to,
            membershipId,
            IGenArtInterfaceV2(_genartInterface).isGoldToken(membershipId)
        );
        // send funds to PaymentSplitter
        IGenArtPaymentSplitter(_paymentSplitter).splitPayment{value: msg.value}(
            address(this)
        );
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(
        address to,
        uint256 membershipId,
        bool isGold
    ) internal {
        // update mint state once membership minted a token
        _mintstate.update(membershipId, isGold, 1);
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((
                IGenArtPaymentSplitter(_paymentSplitter)
                    .getTotalSharesOfCollection(address(this), 1)
            ) * salePrice_) / 10_000
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint.
     */
    function mintReserved() public onlyAdmin {
        require(!_reservedMinted, "GenArtERC721: reserved already minted");
        _mintOne(genartAdmin, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set {PaymentSplitter} address
     */
    function setPaymentSplitter(address paymentSplitter)
        public
        onlyGenArtAdmin
    {
        _paymentSplitter = paymentSplitter;
    }

    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     *@dev Set reserved mints for gold members
     */
    function setReservedGold(uint256 reserved) public onlyGenArtAdmin {
        _mintstate.setReservedGold(reserved);
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     *@dev Royalties are forwarded to {PaymentSplitter}
     */
    receive() external payable {
        IGenArtPaymentSplitter(_paymentSplitter).splitPaymentRoyalty{
            value: msg.value
        }(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./GenArtAccess.sol";
import "./MintStateReserveGold.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721AI is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateReserveGold for MintStateReserveGold.State;

    uint256 public _mintPrice;
    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _genartInterface;
    address public _paymentSplitter;
    address public _wethAddress;
    string private _uri;
    bool public _paused = true;

    MintStateReserveGold.State public _mintstate;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 collectionId_,
        uint256 mintPrice_,
        uint256 mintSupply_,
        address genartInterface_,
        address paymentSplitter_,
        address wethAddress_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _collectionId = collectionId_;
        _mintPrice = mintPrice_;
        _mintSupply = mintSupply_;
        _genartInterface = genartInterface_;
        _paymentSplitter = paymentSplitter_;
        _wethAddress = wethAddress_;
        _mintstate.init(mintSupply_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _mintstate.getMints(membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate.getAvailableMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                _mintSupply,
                totalSupply()
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(uint256 amount, uint256 availableMints) internal view {
        require(!_paused, "GenArtERC721AI: minting is paused");
        require(availableMints > 0, "GenArtERC721AI: no mints available");
        require(
            availableMints >= amount,
            "GenArtERC721AI: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _mintPrice * amount;
        }
        require(
            ethAmount <= msg.value,
            "GenArtERC721AI: transaction underpriced"
        );
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterfaceV3(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterfaceV3(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;

        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // check if membership is gold
            bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
                memberships[i]
            );
            // get available mints for membership
            uint256 mints = _mintstate.getAvailableMints(
                memberships[i],
                isGold,
                _mintSupply,
                totalSupply()
            );
            // mint tokens with membership and stop if desired amount reached
            for (uint256 j; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i], isGold);
                minted++;
            }
            i++;
        }
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterfaceV3(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721AI: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints);

        bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
            membershipId
        );
        // mint token
        mintForMembership(to, membershipId, isGold);
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(
        address to,
        uint256 membershipId,
        bool isGold
    ) internal {
        // update mint state once membership minted a token
        _mintstate.update(membershipId, isGold, 1);
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721AI: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((
                IGenArtPaymentSplitterV2(_paymentSplitter)
                    .getTotalSharesOfCollection(address(this), 1)
            ) * salePrice_) / 10_000
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Release WETH royalties and send them to {PaymentSplitter}
     */
    function releaseWETHRoyalties() public {
        IERC20 weth = IERC20(_wethAddress);
        uint256 wethAmount = weth.balanceOf(address(this));
        weth.transfer(_paymentSplitter, wethAmount);
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyaltyWETH(
            address(this),
            wethAmount
        );
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Set reserved mints for gold members
     */
    function setReservedGold(uint8 reserved) public onlyGenArtAdmin {
        _mintstate.setReservedGold(reserved);
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint.
     */
    function mintReserved() public onlyAdmin {
        require(
            !_reservedMinted,
            "GenArtERC721AI: reserved already minted"
        );
        _mintOne(genartAdmin, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set {PaymentSplitter} address
     */
    function setPaymentSplitter(address paymentSplitter)
        public
        onlyGenArtAdmin
    {
        _paymentSplitter = paymentSplitter;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     *@dev Royalties are forwarded to {PaymentSplitter}
     */
    receive() external payable {
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyalty{
            value: msg.value
        }(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./GenArtAccess.sol";
import "./MintStateGoldAirdrop.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721Ailbums is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateGoldAirdrop for MintStateGoldAirdrop.State;

    uint256 public _mintPrice;
    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _paymentSplitter;
    address public _genartInterface;
    string private _uri;
    bool public _paused = true;
    address public _wethAddress;

    MintStateGoldAirdrop.State public _mintstate;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 collectionId_,
        uint8 standardSupply_,
        uint8 goldSupply_,
        uint256 mintPrice_,
        uint256 mintSupply_,
        address genartInterface_,
        address paymentSplitter_,
        address wethAddress_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _collectionId = collectionId_;
        _mintPrice = mintPrice_;
        _mintSupply = mintSupply_;
        _genartInterface = genartInterface_;
        _paymentSplitter = paymentSplitter_;
        _wethAddress = wethAddress_;
        _mintstate.init(standardSupply_, goldSupply_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _mintstate.getMints(membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate.getAvailableMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                _mintSupply,
                totalSupply()
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(uint256 amount, uint256 availableMints) internal view {
        require(!_paused, "GenArtERC721Ailbums: minting is paused");
        require(availableMints > 0, "GenArtERC721Ailbums: no mints available");
        require(
            availableMints >= amount,
            "GenArtERC721Ailbums: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _mintPrice * amount;
        }
        require(
            ethAmount <= msg.value,
            "GenArtERC721Ailbums: transaction underpriced"
        );
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterfaceV3(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterfaceV3(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;

        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // check if membership is gold
            bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
                memberships[i]
            );
            // get available mints for membership
            uint256 mints = _mintstate.getAvailableMints(
                memberships[i],
                isGold,
                _mintSupply,
                totalSupply()
            );
            // mint tokens with membership and stop if desired amount reached
            for (uint256 j; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i]);
                minted++;
            }
            i++;
        }
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterfaceV3(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721Ailbums: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints);
        // mint token
        mintForMembership(to, membershipId);
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(address to, uint256 membershipId) internal {
        // update mint state once membership minted a token
        uint256 tokenId = _collectionId *
            100_000 +
            totalSupply() -
            _mintstate.getGoldMints() +
            1;

        bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
            membershipId
        );
        _mintOne(to, tokenId, membershipId);
        if (isGold) {
            uint256 tokenIdGold = _collectionId *
                100_000 +
                _mintSupply +
                _mintstate.getGoldMints() +
                1;
            _mintOne(to, tokenIdGold, membershipId);
        }
        _mintstate.update(membershipId, isGold, 1);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(
        address to,
        uint256 tokenId,
        uint256 membershipId
    ) internal virtual {
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721Ailbums: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((
                IGenArtPaymentSplitterV2(_paymentSplitter)
                    .getTotalSharesOfCollection(address(this), 1)
            ) * salePrice_) / 10_000
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Release WETH royalties and send them to {PaymentSplitter}
     */
    function releaseWETHRoyalties() public {
        IERC20 weth = IERC20(_wethAddress);
        uint256 wethAmount = weth.balanceOf(address(this));
        weth.transfer(_paymentSplitter, wethAmount);
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyaltyWETH(
            address(this),
            wethAmount
        );
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint.
     */
    function mintReserved() public onlyAdmin {
        require(
            !_reservedMinted,
            "GenArtERC721Ailbums: reserved already minted"
        );
        uint256 tokenId = _collectionId *
            100_000 +
            totalSupply() -
            _mintstate.getGoldMints() +
            1;
        _mintOne(genartAdmin, tokenId, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set {PaymentSplitter} address
     */
    function setPaymentSplitter(address paymentSplitter)
        public
        onlyGenArtAdmin
    {
        _paymentSplitter = paymentSplitter;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     *@dev Royalties are forwarded to {PaymentSplitter}
     */
    receive() external payable {
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyalty{
            value: msg.value
        }(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./GenArtAccess.sol";
import "./MintStateReserveGold.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721Closer is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateReserveGold for MintStateReserveGold.State;

    uint256 public _mintPrice;
    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _genartInterface;
    address public _paymentSplitter;
    address public _wethAddress;
    string private _uri;
    bool public _paused = true;

    MintStateReserveGold.State public _mintstate;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 collectionId_,
        uint256 mintPrice_,
        uint256 mintSupply_,
        address genartInterface_,
        address paymentSplitter_,
        address wethAddress_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _collectionId = collectionId_;
        _mintPrice = mintPrice_;
        _mintSupply = mintSupply_;
        _genartInterface = genartInterface_;
        _paymentSplitter = paymentSplitter_;
        _wethAddress = wethAddress_;
        _mintstate.init(mintSupply_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _mintstate.getMints(membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate.getAvailableMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                _mintSupply,
                totalSupply()
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(uint256 amount, uint256 availableMints) internal view {
        require(!_paused, "GenArtERC721Closer: minting is paused");
        require(availableMints > 0, "GenArtERC721Closer: no mints available");
        require(
            availableMints >= amount,
            "GenArtERC721Closer: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _mintPrice * amount;
        }
        require(
            ethAmount <= msg.value,
            "GenArtERC721Closer: transaction underpriced"
        );
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterfaceV3(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterfaceV3(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;

        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // check if membership is gold
            bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
                memberships[i]
            );
            // get available mints for membership
            uint256 mints = _mintstate.getAvailableMints(
                memberships[i],
                isGold,
                _mintSupply,
                totalSupply()
            );
            // mint tokens with membership and stop if desired amount reached
            for (uint256 j; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i], isGold);
                minted++;
            }
            i++;
        }
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterfaceV3(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721Closer: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints);

        bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
            membershipId
        );
        // mint token
        mintForMembership(to, membershipId, isGold);
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(
        address to,
        uint256 membershipId,
        bool isGold
    ) internal {
        // update mint state once membership minted a token
        _mintstate.update(membershipId, isGold, 1);
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721Closer: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((
                IGenArtPaymentSplitterV2(_paymentSplitter)
                    .getTotalSharesOfCollection(address(this), 1)
            ) * salePrice_) / 10_000
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Release WETH royalties and send them to {PaymentSplitter}
     */
    function releaseWETHRoyalties() public {
        IERC20 weth = IERC20(_wethAddress);
        uint256 wethAmount = weth.balanceOf(address(this));
        weth.transfer(_paymentSplitter, wethAmount);
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyaltyWETH(
            address(this),
            wethAmount
        );
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Set reserved mints for gold members
     */
    function setReservedGold(uint8 reserved) public onlyGenArtAdmin {
        _mintstate.setReservedGold(reserved);
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint.
     */
    function mintReserved() public onlyAdmin {
        require(
            !_reservedMinted,
            "GenArtERC721Closer: reserved already minted"
        );
        _mintOne(genartAdmin, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set {PaymentSplitter} address
     */
    function setPaymentSplitter(address paymentSplitter)
        public
        onlyGenArtAdmin
    {
        _paymentSplitter = paymentSplitter;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     *@dev Royalties are forwarded to {PaymentSplitter}
     */
    receive() external payable {
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyalty{
            value: msg.value
        }(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./GenArtAccess.sol";
import "./MintStateDefault.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721Script is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateDefault for MintStateDefault.State;

    uint256 public _mintPrice;
    string public _script;
    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _genartInterface;
    address public _paymentSplitter;
    address public _wethAddress;
    string private _uri;
    bool public _paused = true;

    MintStateDefault.State public _mintstate;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to,
        bytes32 hash
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        string memory script_,
        uint256 collectionId_,
        uint8 standardSupply_,
        uint8 goldSupply_,
        uint256 mintPrice_,
        uint256 mintSupply_,
        address[3] memory addresses
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _collectionId = collectionId_;
        _mintPrice = mintPrice_;
        _mintSupply = mintSupply_;
        _genartInterface = addresses[0];
        _paymentSplitter = addresses[1];
        _wethAddress = addresses[2];
        _script = script_;
        _mintstate.init(standardSupply_, goldSupply_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _mintstate.getMints(membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate.getAvailableMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                _mintSupply,
                totalSupply()
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(uint256 amount, uint256 availableMints) internal view {
        require(!_paused, "GenArtERC721Script: minting is paused");
        require(availableMints > 0, "GenArtERC721Script: no mints available");
        require(
            availableMints >= amount,
            "GenArtERC721Script: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _mintPrice * amount;
        }
        require(
            ethAmount <= msg.value,
            "GenArtERC721Script: transaction underpriced"
        );
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterfaceV3(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterfaceV3(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;

        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // check if membership is gold
            bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
                memberships[i]
            );
            // get available mints for membership
            uint256 mints = _mintstate.getAvailableMints(
                memberships[i],
                isGold,
                _mintSupply,
                totalSupply()
            );
            // mint tokens with membership and stop if desired amount reached
            for (uint256 j; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i]);
                minted++;
            }
            i++;
        }
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterfaceV3(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721Script: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints);
        // mint token
        mintForMembership(to, membershipId);
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(address to, uint256 membershipId) internal {
        // update mint state once membership minted a token
        _mintstate.update(membershipId, 1);
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, block.timestamp, to)
        );
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to, hash);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721Script: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((
                IGenArtPaymentSplitterV2(_paymentSplitter)
                    .getTotalSharesOfCollection(address(this), 1)
            ) * salePrice_) / 10_000
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Release WETH royalties and send them to {PaymentSplitter}
     */
    function releaseWETHRoyalties() public {
        IERC20 weth = IERC20(_wethAddress);
        uint256 wethAmount = weth.balanceOf(address(this));
        weth.transfer(_paymentSplitter, wethAmount);
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyaltyWETH(
            address(this),
            wethAmount
        );
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint.
     */
    function mintReserved() public onlyAdmin {
        require(
            !_reservedMinted,
            "GenArtERC721Script: reserved already minted"
        );
        _mintOne(genartAdmin, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set {PaymentSplitter} address
     */
    function setPaymentSplitter(address paymentSplitter)
        public
        onlyGenArtAdmin
    {
        _paymentSplitter = paymentSplitter;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     *@dev Royalties are forwarded to {PaymentSplitter}
     */
    receive() external payable {
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyalty{
            value: msg.value
        }(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./GenArtAccess.sol";
import "./MintStateDefault.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721V2 is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateDefault for MintStateDefault.State;

    uint256 public _mintPrice;
    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _genartInterface;
    address public _paymentSplitter;
    address public _wethAddress;
    string private _uri;
    bool public _paused = true;

    MintStateDefault.State public _mintstate;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 collectionId_,
        uint8 standardSupply_,
        uint8 goldSupply_,
        uint256 mintPrice_,
        uint256 mintSupply_,
        address genartInterface_,
        address paymentSplitter_,
        address wethAddress_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _collectionId = collectionId_;
        _mintPrice = mintPrice_;
        _mintSupply = mintSupply_;
        _genartInterface = genartInterface_;
        _paymentSplitter = paymentSplitter_;
        _wethAddress = wethAddress_;
        _mintstate.init(standardSupply_, goldSupply_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _mintstate.getMints(membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate.getAvailableMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                _mintSupply,
                totalSupply()
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(uint256 amount, uint256 availableMints) internal view {
        require(!_paused, "GenArtERC721V2: minting is paused");
        require(availableMints > 0, "GenArtERC721V2: no mints available");
        require(
            availableMints >= amount,
            "GenArtERC721V2: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _mintPrice * amount;
        }
        require(
            ethAmount <= msg.value,
            "GenArtERC721V2: transaction underpriced"
        );
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterfaceV3(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterfaceV3(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;

        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // check if membership is gold
            bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
                memberships[i]
            );
            // get available mints for membership
            uint256 mints = _mintstate.getAvailableMints(
                memberships[i],
                isGold,
                _mintSupply,
                totalSupply()
            );
            // mint tokens with membership and stop if desired amount reached
            for (uint256 j; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i]);
                minted++;
            }
            i++;
        }
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterfaceV3(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721V2: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints);
        // mint token
        mintForMembership(to, membershipId);
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(address to, uint256 membershipId) internal {
        // update mint state once membership minted a token
        _mintstate.update(membershipId, 1);
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721V2: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((
                IGenArtPaymentSplitterV2(_paymentSplitter)
                    .getTotalSharesOfCollection(address(this), 1)
            ) * salePrice_) / 10_000
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Release WETH royalties and send them to {PaymentSplitter}
     */
    function releaseWETHRoyalties() public {
        IERC20 weth = IERC20(_wethAddress);
        uint256 wethAmount = weth.balanceOf(address(this));
        weth.transfer(_paymentSplitter, wethAmount);
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyaltyWETH(
            address(this),
            wethAmount
        );
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint.
     */
    function mintReserved() public onlyAdmin {
        require(!_reservedMinted, "GenArtERC721V2: reserved already minted");
        _mintOne(genartAdmin, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set {PaymentSplitter} address
     */
    function setPaymentSplitter(address paymentSplitter)
        public
        onlyGenArtAdmin
    {
        _paymentSplitter = paymentSplitter;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     *@dev Royalties are forwarded to {PaymentSplitter}
     */
    receive() external payable {
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyalty{
            value: msg.value
        }(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
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
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
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
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract GenArtGovToken is Ownable {
    using SafeMath for uint256;
    using SafeCast for uint256;

    /// @dev EIP-20 token name for this token
    string public constant name = "GEN.ART";

    /// @dev EIP-20 token symbol for this token
    string public constant symbol = "GENART";

    /// @dev EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @dev Total number of tokens in circulation
    uint256 public totalSupply = 100_000_000e18; // 100 million

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;

    /// @dev A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @dev A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    /// @dev A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @dev The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @dev The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /// @dev A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @dev An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @dev An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @dev The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor(address treasury_) {
        _mint(treasury_, 100 * 10**24);
    }

    /**
     * @dev Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
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
        require(
            owner != address(0),
            "GenArtGovToken: approve from the zero address"
        );
        require(
            spender != address(0),
            "GenArtGovToken: approve to the zero address"
        );

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GenArtGovToken: invalid signature");
        require(signatory == owner, "GenArtGovToken: unauthorized");
        require(
            block.timestamp <= deadline,
            "GenArtGovToken: signature expired"
        );

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Transfer `amount` tokens from `msg.sender` to `dst`
     * @param to The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        address spender = _msgSender();

        uint256 currentAllowance = allowances[sender][spender];
        require(
            currentAllowance >= amount,
            "GenArtGovToken: transfer amount exceeds allowance"
        );
        _transferTokens(sender, recipient, amount);

        unchecked {
            approve(spender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GenArtGovToken: invalid signature");
        require(nonce == nonces[signatory]++, "GenArtGovToken: invalid nonce");
        require(block.timestamp <= expiry, "GenArtGovToken: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @dev Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @dev Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint32 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "GenArtGovToken: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(
            from != address(0),
            "GenArtGovToken: cannot transfer from the zero address"
        );
        require(
            to != address(0),
            "GenArtGovToken: cannot transfer to the zero address"
        );

        balances[from] = balances[from].sub(
            amount,
            "GenArtGovToken: transfer amount exceeds balance"
        );

        balances[to] = balances[to].add(amount);

        emit Transfer(from, to, amount);

        _moveDelegates(delegates[from], delegates[to], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.sub(
                    amount,
                    "GenArtGovToken: vote amount underflows"
                );

                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount);

                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint224 _votes = newVotes.toUint224();
        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = _votes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                block.number.toUint32(),
                _votes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, _votes);
    }

    function getChainId() public view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _mint(address account, uint96 amount) internal virtual {
        require(
            account != address(0),
            "GenArtGovToken: mint to the zero address"
        );

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArt {
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isGoldToken(uint256 _tokenId) external view returns (bool);
}

interface IGenArtCollection {
    function mintGen(
        address _to,
        uint256 _groupId,
        uint256 _membershipId
    ) external;

    function mint(
        address _to,
        uint256 _groupId,
        uint256 _membershipId
    ) external;

    function mintMany(
        address _to,
        uint256 _groupId,
        uint256 _membershipId,
        uint256 _amount
    ) external;

    function mintManyGen(
        address _to,
        uint256 _groupId,
        uint256 _membershipId,
        uint256 _amount
    ) external;

    function getAllowedMintForMembership(uint256 _group, uint256 _membershipId)
        external
        view
        returns (uint256);
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * Interface to the GEN.ART Membership and Governance Token Contracts
 */

contract GenArtInterfaceV2 is Ownable {
    IGenArt private _genArtMembership;
    IERC20 private _genArtToken;
    bool private _genAllowed = false;

    constructor(address genArtMembershipAddress_) {
        _genArtMembership = IGenArt(genArtMembershipAddress_);
    }

    function getMaxMintForMembership(uint256 _membershipId)
        public
        view
        returns (uint256)
    {
        _genArtMembership.ownerOf(_membershipId);
        bool isGold = _genArtMembership.isGoldToken(_membershipId);
        return (isGold ? 5 : 1);
    }

    function getMaxMintForOwner(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = _genArtMembership.getTokensByOwner(owner);
        uint256 maxMint = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            maxMint += getMaxMintForMembership(tokenIds[i]);
        }

        return maxMint;
    }

    function upgradeGenArtTokenContract(address _genArtTokenAddress)
        public
        onlyOwner
    {
        _genArtToken = IERC20(_genArtTokenAddress);
    }

    function setAllowGen(bool allow) public onlyOwner {
        _genAllowed = allow;
    }

    function isGoldToken(uint256 _membershipId) public view returns (bool) {
        return _genArtMembership.isGoldToken(_membershipId);
    }

    function genAllowed() public view returns (bool) {
        return _genAllowed;
    }

    function ownerOf(uint256 _membershipId) public view returns (address) {
        return _genArtMembership.ownerOf(_membershipId);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _genArtToken.balanceOf(_owner);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        _genArtToken.transferFrom(_from, _to, _amount);
    }

    function getRandomChoice(uint256[] memory choices, uint256 seed)
        public
        view
        returns (uint256)
    {
        require(
            choices.length > 0,
            "GenArtInterfaceV2: choices must have at least 1 value"
        );
        if (choices.length == 1) return choices[0];
        uint256 i = ((
            uint256(
                keccak256(abi.encodePacked(block.timestamp, seed, msg.sender))
            )
        ) % choices.length) + 1;

        return choices[i - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtMembership.sol";
import "./IGenArtERC721V2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * Interface to the GEN.ART Membership and Governance Token Contracts
 */

contract GenArtInterfaceV3 is GenArtAccess, IGenArtInterfaceV3 {
    IGenArtMembership private _genArtMembership;

    constructor(address genArtMembershipAddress_) {
        _genArtMembership = IGenArtMembership(genArtMembershipAddress_);
    }

    function isGoldToken(uint256 _membershipId)
        public
        view
        override
        returns (bool)
    {
        return _genArtMembership.isGoldToken(_membershipId);
    }

    function getMembershipsOf(address account)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _genArtMembership.getTokensByOwner(account);
    }

    function ownerOfMembership(uint256 _membershipId)
        public
        view
        override
        returns (address)
    {
        return _genArtMembership.ownerOf(_membershipId);
    }

    /**
     *@dev Get available mints for an account
     */
    function getAvailableMintsForAccount(address collection, address account)
        public
        view
        override
        returns (uint256)
    {
        uint256[] memory memberships = getMembershipsOf(account);
        uint256 availableMints;
        for (uint256 i; i < memberships.length; i++) {
            availableMints += IGenArtERC721V2(collection)
                .getAvailableMintsForMembership(memberships[i]);
        }
        return availableMints;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract GenArtPaymentProxy {   
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(address payee, uint256 amount);
    mapping(address => mapping(uint256 => uint256)) public receivedTokens;
    Payment private _payment;

    constructor(address[] memory payeeAddresses, uint256[] memory payeeShares) {
        require(
            payeeAddresses.length == payeeShares.length,
            "GenArtPaymentProxy: Invalid payees set"
        );
        _payment = Payment(payeeAddresses, payeeShares);
    }

    function withdrawTokens(address tokenAddress, uint256 payeeIndex)
        public
        payable
    {
        address payee = _payment.payees[payeeIndex];
        require(
            payee == msg.sender,
            "GenArtPaymentProxy: Sender must be payee"
        );
        uint256 totalShares = getTotalShares();
        uint256 totalTokenBalance = getTotalTokenBalance(tokenAddress);
        uint256 tokenAmount = (totalTokenBalance *
            _payment.shares[payeeIndex]) /
            totalShares -
            receivedTokens[tokenAddress][payeeIndex];
        require(tokenAmount > 0, "GenArtPaymentProxy: zero balance");
        receivedTokens[tokenAddress][payeeIndex] += tokenAmount;
        IERC20(tokenAddress).transfer(payee, tokenAmount);
        emit IncomingPayment(payee, tokenAmount);
    }

    /**
     *@dev Get total shares
     */
    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        for (uint8 i; i < _payment.shares.length; i++) {
            unchecked {
                totalShares += _payment.shares[i];
            }
        }
        return totalShares;
    }

    function getTotalTokenBalance(address tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 totalTokenBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        for (uint8 i; i < _payment.payees.length; i++) {
            unchecked {
                totalTokenBalance += receivedTokens[tokenAddress][i];
            }
        }
        return totalTokenBalance;
    }

    function updatePayee(uint256 payeeIndex, address newPayee) public {
        address oldPayee = _payment.payees[payeeIndex];
        require(
            oldPayee == msg.sender,
            "GenArtPaymentProxy: sender is not current payee"
        );
        _payment.payees[payeeIndex] = newPayee;
    }

    receive() external payable {
        uint256 totalShares = getTotalShares();
        for (uint8 i; i < _payment.payees.length; i++) {
            address payee = _payment.payees[i];
            uint256 ethAmount = (msg.value * _payment.shares[i]) / totalShares;
            payable(payee).transfer(ethAmount);
            emit IncomingPayment(payee, ethAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtPaymentSplitter.sol";

contract GenArtPaymentSplitter is GenArtAccess, IGenArtPaymentSplitter {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(
        address collection,
        uint256 paymentType,
        address payee,
        uint256 amount
    );

    mapping(address => uint256) public _balances;
    mapping(address => Payment) private _payments;
    mapping(address => Payment) private _paymentsRoyalties;

    /**
     * @dev Throws if called by any account other than the owner, admin or collection contract.
     */
    modifier onlyCollectionContractOrAdmin(bool isCollection) {
        address sender = _msgSender();
        require(
            isCollection || (owner() == sender) || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitter: invalid arguments"
        );

        _payments[collection] = Payment(payees, shares);
    }

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitter: invalid arguments"
        );
        _paymentsRoyalties[collection] = Payment(payees, shares);
    }

    function sanityCheck(address collection, uint8 paymentType) internal view {
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        require(
            payment.payees.length > 0,
            "GenArtPaymentSplitter: payment not found for collection"
        );
    }

    function splitPayment(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(_payments[msg.sender].payees.length > 0)
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 0);
        for (uint8 i; i < _payments[collection].payees.length; i++) {
            address payee = _payments[collection].payees[i];
            uint256 ethAmount = (msg.value * _payments[collection].shares[i]) /
                totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 ethAmount = (msg.value *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 1, payee, ethAmount);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentsRoyalties
     */
    function getTotalSharesOfCollection(address collection, uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        sanityCheck(collection, paymentType);
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) public override {
        uint256 amount = _balances[account];
        require(amount > 0, "GenArtPaymentSplitter: no funds to release");
        _balances[account] = 0;
        payable(account).transfer(amount);
    }

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) public override {
        sanityCheck(collection, paymentType);
        Payment storage payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        address oldPayee = payment.payees[payeeIndex];
        require(
            oldPayee == _msgSender(),
            "GenArtPaymentSplitter: sender is not current payee"
        );
        payment.payees[payeeIndex] = newPayee;
    }

    function getBalanceForAccount(address account)
        public
        view
        returns (uint256)
    {
        return _balances[account];
    }

    function emergencyWithdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract GenArtPaymentSplitterV2 is GenArtAccess, IGenArtPaymentSplitterV2 {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(
        address collection,
        uint256 paymentType,
        address payee,
        uint256 amount
    );

    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _wethBalances;
    mapping(address => Payment) private _payments;
    mapping(address => Payment) private _paymentsRoyalties;
    address public _wethAddress;
    bool public _destoryed = false;

    constructor(address wethAddress_) GenArtAccess() {
        _wethAddress = wethAddress_;
    }

    /**
     * @dev Throws if called by any account other than the owner, admin or collection contract.
     */
    modifier onlyCollectionContractOrAdmin(bool isCollection) {
        address sender = _msgSender();
        require(
            isCollection || (owner() == sender) || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitterV2: invalid arguments"
        );

        _payments[collection] = Payment(payees, shares);
    }

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitterV2: invalid arguments"
        );
        _paymentsRoyalties[collection] = Payment(payees, shares);
    }

    function sanityCheck(address collection, uint8 paymentType) internal view {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        require(
            payment.payees.length > 0,
            "GenArtPaymentSplitterV2: payment not found for collection"
        );
    }

    function splitPayment(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(_payments[msg.sender].payees.length > 0)
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 0);
        for (uint8 i; i < _payments[collection].payees.length; i++) {
            address payee = _payments[collection].payees[i];
            uint256 ethAmount = (msg.value * _payments[collection].shares[i]) /
                totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 ethAmount = (msg.value *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 1, payee, ethAmount);
        }
    }

    function splitPaymentRoyaltyWETH(address collection, uint256 wethAmount)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 wethAmountShare = (wethAmount *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _wethBalances[payee] += wethAmountShare;
            }
            emit IncomingPayment(collection, 1, payee, wethAmountShare);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentsRoyalties
     */
    function getTotalSharesOfCollection(address collection, uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        sanityCheck(collection, paymentType);
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) public override {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        uint256 amount = _balances[account];
        uint256 wethAmount = _wethBalances[account];
        require(
            amount > 0 || wethAmount > 0,
            "GenArtPaymentSplitterV2: no funds to release"
        );
        if (amount > 0) {
            _balances[account] = 0;
            payable(account).transfer(amount);
        }
        if (wethAmount > 0) {
            _wethBalances[account] = 0;
            IERC20(_wethAddress).transfer(account, wethAmount);
        }
    }

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) public override {
        sanityCheck(collection, paymentType);
        Payment storage payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        address oldPayee = payment.payees[payeeIndex];
        require(
            oldPayee == _msgSender(),
            "GenArtPaymentSplitterV2: sender is not current payee"
        );
        payment.payees[payeeIndex] = newPayee;
    }

    function getBalanceForAccount(address account)
        public
        view
        returns (uint256)
    {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        return _balances[account];
    }

    function emergencyWithdraw() public onlyOwner {
        _destoryed = true;
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtERC721V2 {
    function getAvailableMintsForMembership(uint256 membershipId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV2 {
    function getMaxMintForMembership(uint256 _membershipId)
        external
        view
        returns (uint256);

    function getMaxMintForOwner(address owner) external view returns (uint256);

    function upgradeGenArtTokenContract(address _genArtTokenAddress) external;

    function setAllowGen(bool allow) external;

    function genAllowed() external view returns (bool);

    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function getRandomChoice(uint256[] memory choices, uint256 seed)
        external
        view
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _membershipId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV3 {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtMembership {
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isGoldToken(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitter {
    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function splitPayment(address collection) external payable;

    function splitPaymentRoyalty(address collection) external payable;

    function getTotalSharesOfCollection(address collection, uint8 _payment)
        external
        view
        returns (uint256);

    function release(address account) external;

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitterV2 {
    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function splitPayment(address collection) external payable;

    function splitPaymentRoyalty(address collection) external payable;

    function splitPaymentRoyaltyWETH(address collection, uint256 wethAmount)
        external
        payable;

    function getTotalSharesOfCollection(address collection, uint8 _payment)
        external
        view
        returns (uint256);

    function release(address account) external;

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStateDefault {
    struct State {
        uint8 allowedMintGold;
        uint8 allowedMintStandard;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
    }

    function init(
        State storage state,
        uint8 allowedMintStandard,
        uint8 allowedMintGold
    ) internal {
        state.allowedMintStandard = allowedMintStandard;
        state.allowedMintGold = allowedMintGold;
    }

    function getMints(State storage state, uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        return state._mints[membershipId];
    }

    function getAllowedMints(State storage state, bool isGold)
        internal
        view
        returns (uint256)
    {
        return (isGold ? state.allowedMintGold : state.allowedMintStandard);
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 collectionSupply,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 availableMints = collectionSupply - currentSupply;

        return
            availableMints > 0
                ? getAllowedMints(state, isGold) - getMints(state, membershipId)
                : 0;
    }

    function update(
        State storage state,
        uint256 membershipId,
        uint256 value
    ) internal {
        unchecked {
            state._mints[membershipId] += value;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStateGoldAirdrop {
    struct State {
        uint8 _allowedMintGold;
        uint8 _allowedMintStandard;
        uint256 _goldMints;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
    }

    function init(
        State storage state,
        uint8 allowedMintStandard,
        uint8 allowedMintGold
    ) internal {
        state._allowedMintStandard = allowedMintStandard;
        state._allowedMintGold = allowedMintGold;
    }

    function getMints(State storage state, uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        return state._mints[membershipId];
    }

    function getGoldMints(State storage state) internal view returns (uint256) {
        return state._goldMints;
    }

    function getAllowedMints(State storage state, bool isGold)
        internal
        view
        returns (uint256)
    {
        return (isGold ? state._allowedMintGold : state._allowedMintStandard);
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 maxMints,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 availableMints = maxMints - (currentSupply - state._goldMints);

        return
            availableMints > 0
                ? getAllowedMints(state, isGold) - getMints(state, membershipId)
                : 0;
    }

    function update(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 value
    ) internal {
        unchecked {
            state._mints[membershipId] += value;
        }
        if (isGold) {
            unchecked {
                state._goldMints += value;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStateReserveGold {
    struct State {
        uint256 reservedGoldSupply;
        uint256 allowedMintGold;
        uint256 allowedMintStandard;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
        uint256 _goldMints;
    }

    function getMints(State storage state, uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        return state._mints[membershipId];
    }

    function getAllowedMints(State storage state, bool isGold)
        internal
        view
        returns (uint256)
    {
        return (isGold ? state.allowedMintGold : state.allowedMintStandard);
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 collectionSupply,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 reserved = state.reservedGoldSupply <= state._goldMints
            ? 0
            : !isGold
            ? (state.reservedGoldSupply - state._goldMints)
            : 0;
        uint256 availableMints = reserved > collectionSupply - currentSupply
            ? 0
            : collectionSupply - currentSupply - reserved;

        return
            availableMints > 0
                ? getAllowedMints(state, isGold) - getMints(state, membershipId)
                : 0;
    }

    function init(State storage state, uint256 reservedGold) internal {
        state.reservedGoldSupply = reservedGold;
        state.allowedMintGold = 1;
        state.allowedMintStandard = 1;
    }

    function setReservedGold(State storage state, uint256 reservedGold)
        internal
    {
        state.reservedGoldSupply = reservedGold;
    }

    function update(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 value
    ) internal {
        unchecked {
            state._mints[membershipId] += value;
        }
        if (isGold) {
            unchecked {
                state._goldMints += value;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStates {
    struct State {
        uint256 reservedGoldSupply;
        uint256 allowedMintGold;
        uint256 allowedMintStandard;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
        uint256 _goldMints;
    }

    function getMints(State storage state, uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        return state._mints[membershipId];
    }

    function getAllowedMints(State storage state, bool isGold)
        internal
        view
        returns (uint256)
    {
        return (isGold ? state.allowedMintGold : state.allowedMintStandard);
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 collectionSupply,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 reserved = state.reservedGoldSupply <= state._goldMints
            ? 0
            : !isGold
            ? (state.reservedGoldSupply - state._goldMints)
            : 0;
        uint256 availableMints = collectionSupply - currentSupply - reserved;

        return
            availableMints > 0
                ? getAllowedMints(state, isGold) - getMints(state, membershipId)
                : 0;
    }

    function init(State storage state, uint256 reservedGold) internal {
        state.reservedGoldSupply = reservedGold;
        state.allowedMintGold = 1;
        state.allowedMintStandard = 1;
    }

    function setReservedGold(State storage state, uint256 reservedGold)
        internal
    {
        state.reservedGoldSupply = reservedGold;
    }

    function update(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 value
    ) internal {
        unchecked {
            state._mints[membershipId] += value;
        }
        if (isGold) {
            unchecked {
                state._goldMints += value;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../legacy/IGenArtMembership.sol";
import {GenArtLoyaltyVault} from "../loyalty/GenArtLoyaltyVault.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtInterfaceV4.sol";

/**
 * Interface to the GEN.ART Membership and Vault
 */

contract GenArtInterfaceV4 is GenArtAccess, IGenArtInterfaceV4 {
    IGenArtMembership public genArtMembership;
    GenArtLoyaltyVault public genartVault;

    constructor(address genArtMembershipAddress_) {
        genArtMembership = IGenArtMembership(genArtMembershipAddress_);
    }

    function isGoldToken(uint256 _membershipId)
        external
        view
        override
        returns (bool)
    {
        return genArtMembership.isGoldToken(_membershipId);
    }

    function getMembershipsOf(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory vaultedMemberships = genartVault.getMembershipsOf(
            account
        );
        uint256[] memory memberships = genArtMembership.getTokensByOwner(
            account
        );
        uint256 vaultedMembershipsLength = vaultedMemberships.length;
        uint256 membershipsLength = memberships.length;
        uint256[] memory returnArr = new uint256[](
            vaultedMembershipsLength + membershipsLength
        );
        for (uint256 i = 0; i < vaultedMembershipsLength; i++) {
            returnArr[i] = vaultedMemberships[i];
        }
        for (uint256 i = 0; i < membershipsLength; i++) {
            returnArr[vaultedMembershipsLength + i] = memberships[i];
        }

        return returnArr;
    }

    function ownerOfMembership(uint256 _membershipId)
        external
        view
        override
        returns (address, bool)
    {
        address account = genArtMembership.ownerOf(_membershipId);

        if (account == address(genartVault)) {
            return (genartVault.membershipOwners(_membershipId), true);
        }

        return (account, false);
    }

    function isVaulted(uint256 _membershipId)
        external
        view
        override
        returns (bool)
    {
        return genArtMembership.ownerOf(_membershipId) == address(genartVault);
    }

    function setLoyaltyVault(address genartVault_) external onlyAdmin {
        genartVault = GenArtLoyaltyVault(payable(genartVault_));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "./GenArtLoyaltyVault.sol";

/**
 * @dev Implements rebates and loyalties for GEN.ART members
 */
abstract contract GenArtLoyalty is GenArtAccess {
    uint256 constant DOMINATOR = 1000;
    uint256 public baseRebateBps = 125;
    uint256 public loyaltyRewardBps = 0;
    uint256 public rebateWindowSec = 60 * 60 * 24 * 5; // 5 days
    uint256 public loyaltyDistributionBlocks = 260 * 24 * 30; // 30 days
    uint256 public distributionDelayBlock = 260 * 24 * 14; // 14 days
    uint256 public lastDistributionBlock;

    GenArtLoyaltyVault public genartVault;

    constructor(address genartVault_) {
        genartVault = GenArtLoyaltyVault(payable(genartVault_));
    }

    /**
     * @dev Public method to send funds to {GenArtLoyaltyVault} for distribution
     */
    function distributeLoyalties() public {
        require(
            lastDistributionBlock == 0 ||
                block.number >= lastDistributionBlock + distributionDelayBlock,
            "distribution delayed"
        );
        uint256 balance = address(this).balance;
        require(balance > 0, "zero balance");
        genartVault.updateRewards{value: balance}(loyaltyDistributionBlocks);
        lastDistributionBlock = block.number;
    }

    /**
     * @dev Set the {GenArtLoyaltyVault} contract address
     */
    function setGenartVault(address genartVault_) external onlyAdmin {
        genartVault = GenArtLoyaltyVault(payable(genartVault_));
    }

    /**
     * @dev Set the base rebate bps per mint {e.g 125}
     */
    function setBaseRebateBps(uint256 bps) external onlyAdmin {
        baseRebateBps = bps;
    }

    /**
     * @dev Set the loyalty reward bps per mint {e.g 25}
     */
    function setLoyaltyRewardBps(uint256 bps) external onlyAdmin {
        loyaltyRewardBps = bps;
    }

    /**
     * @dev Set the rebate window
     */
    function setRebateWindow(uint256 rebateWindowSec_) external onlyAdmin {
        rebateWindowSec = rebateWindowSec_;
    }

    /**
     * @dev Set the block range for loyalty distribution
     */
    function setLoyaltyDistributionBlocks(uint256 blocks) external onlyAdmin {
        loyaltyDistributionBlocks = blocks;
    }

    /**
     * @dev Set the delay loyalty distribution (in blocks)
     */
    function setDistributionDelayBlock(uint256 blocks) external onlyAdmin {
        distributionDelayBlock = blocks;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArt.sol";
import "../access/GenArtAccess.sol";

/**
 * @title GenArtValut
 * @notice It handles the distribution of ETH loyalties
 * @notice forked from https://etherscan.io/address/0xbcd7254a1d759efa08ec7c3291b2e85c5dcc12ce#code
 */
contract GenArtLoyaltyVault is ReentrancyGuard, GenArtAccess {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 tokens; // shares of token staked
        uint256[] membershipIds;
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalTokenShares;
    uint256 public totalMembershipShares;

    uint256 public minimumTokenAmount = 4_000;
    uint256 public minimumMembershipAmount = 1;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable genartToken;
    address public immutable genartMembership;

    mapping(address => uint256) public lockedWithdraw;

    uint256 public weightFactorTokens = 2;
    uint256 public weightFactorMemberships = 1;

    mapping(uint256 => address) public membershipOwners;

    bool public emergencyWithdrawDisabled;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(
        uint256 numberBlocks,
        uint256 rewardPerBlock,
        uint256 reward
    );
    event Withdraw(address indexed user, uint256 amount, uint256[] memberships);

    /**
     * @notice Constructor
     * @param _genartToken address of the token staked (GRNART)
     */
    constructor(address _genartMembership, address _genartToken) {
        genartToken = IERC20(_genartToken);
        genartMembership = _genartMembership;
    }

    modifier requireNotLocked(address user) {
        require(block.timestamp > lockedWithdraw[user], "assets locked");
        _;
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in GENART)
     */
    function deposit(uint256[] memory membershipIds, uint256 amount)
        external
        nonReentrant
    {
        address sender = _msgSender();
        _checkDeposit(sender, membershipIds, amount);
        _deposit(sender, membershipIds, amount);
    }

    function harvest() external nonReentrant {
        address sender = _msgSender();
        uint256 pendingRewards = _harvest(sender);
        require(pendingRewards > 0, "zero rewards to harvest");
        // transfer reward token to sender
        payable(sender).transfer(pendingRewards);
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     */
    function withdraw() external requireNotLocked(msg.sender) nonReentrant {
        address sender = _msgSender();
        require(userInfo[sender].tokens > 0, "zero shares");
        _withdraw(sender);
    }

    /**
     * @notice Withdraw staked tokens and memberships
     */
    function withdrawPartial(
        uint256 amount,
        uint256[] memory membershipsToWithdraw
    ) external requireNotLocked(msg.sender) nonReentrant {
        _withdrawPartial(msg.sender, amount, membershipsToWithdraw);
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 rewardDurationInBlocks)
        external
        payable
        onlyAdmin
    {
        // adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = msg.value / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (msg.value +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(
            rewardDurationInBlocks,
            currentRewardPerBlock,
            msg.value
        );
    }

    function lockUserWithdraw(address user, uint256 toTimestamp)
        external
        onlyAdmin
    {
        if (lockedWithdraw[user] >= toTimestamp) return;
        lockedWithdraw[user] = toTimestamp;
    }

    function setWeightFactors(
        uint256 newWeightFactorTokens,
        uint256 newWeightFactorMemberships
    ) external onlyAdmin {
        weightFactorTokens = newWeightFactorTokens;
        weightFactorMemberships = newWeightFactorMemberships;
    }

    function setMinTokenAndMembershipAmount(
        uint256 minimumTokenAmount_,
        uint256 minimumMembershipAmount_
    ) external onlyAdmin {
        minimumTokenAmount = minimumTokenAmount_;
        minimumMembershipAmount = minimumMembershipAmount_;
    }

    /**
     * @dev Disable emergency withdraw
     */
    function disableEmergencyWithdraw() public onlyAdmin {
        emergencyWithdrawDisabled = true;
    }

    /**
     * @dev Withdraw funds on contract to owner in case of emergency
     */
    function emergencyWithdraw() public onlyAdmin {
        require(!emergencyWithdrawDisabled, "emergency withdraw disabled");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Checks requirements for depositing a stake
     */
    function _checkDeposit(
        address user,
        uint256[] memory membershipIds,
        uint256 amount
    ) internal view {
        // check required amount of tokens
        require(
            amount >=
                (
                    userInfo[user].membershipIds.length == 0
                        ? minimumTokenAmount * PRECISION_FACTOR
                        : 0
                ),
            "not enough tokens"
        );
        if (userInfo[user].membershipIds.length == 0) {
            require(
                membershipIds.length >= minimumMembershipAmount,
                "not enough memberships"
            );
        }
    }

    /**
     * @notice Return share value of a membership based on tier
     */
    function _getMembershipShareValue(uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        // 5 shares per gold membership. 1 share for standard memberships
        return
            (IGenArt(genartMembership).isGoldToken(membershipId) ? 5 : 1) *
            PRECISION_FACTOR;
    }

    function _deposit(
        address user,
        uint256[] memory membershipIds,
        uint256 amount
    ) internal {
        // update reward for user
        _updateReward(user);
        // send memberships to this contract
        for (uint256 i; i < membershipIds.length; i++) {
            IERC721(genartMembership).transferFrom(
                user,
                address(this),
                membershipIds[i]
            );
            // save the membership token Ids
            userInfo[user].membershipIds.push(membershipIds[i]);
            membershipOwners[membershipIds[i]] = user;
            // adjust internal membership shares
            totalMembershipShares += _getMembershipShareValue(membershipIds[i]);
        }

        // transfer GENART tokens to this address
        genartToken.transferFrom(user, address(this), amount);

        // adjust internal token shares
        userInfo[user].tokens += amount;
        totalTokenShares += amount;

        emit Deposit(user, amount);
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerShare();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens and memberships and collect rewards
     */
    function _withdraw(address user) internal {
        // harvest rewards
        uint256 pendingRewards = _harvest(user);
        uint256 tokens = userInfo[user].tokens;
        uint256[] memory memberships = userInfo[user].membershipIds;

        // adjust internal token shares
        userInfo[user].tokens = 0;
        totalTokenShares -= tokens;

        // transfer GENART tokens to user
        genartToken.safeTransfer(user, tokens);
        for (uint256 i = memberships.length; i >= 1; i--) {
            // remove membership token id from user info object
            userInfo[user].membershipIds.pop();
            membershipOwners[memberships[i - 1]] = address(0);
            // adjust internal membership shares
            totalMembershipShares -= _getMembershipShareValue(
                memberships[i - 1]
            );
            IERC721(genartMembership).transferFrom(
                address(this),
                user,
                memberships[i - 1]
            );
        }
        // transfer reward token to user
        payable(user).transfer(pendingRewards);
        emit Withdraw(user, tokens, memberships);
    }

    /**
     * @notice Withdraw staked tokens and memberships
     */
    function _withdrawPartial(
        address user,
        uint256 amount,
        uint256[] memory membershipsToWithdraw
    ) internal {
        // harvest rewards
        uint256 pendingRewards = _harvest(user);
        uint256 tokens = userInfo[user].tokens;

        uint256 remainingTokens;
        uint256 remainingMemberships;
        unchecked {
            remainingTokens = tokens - amount;
            remainingMemberships =
                userInfo[user].membershipIds.length -
                membershipsToWithdraw.length;
        }
        require(
            remainingTokens >= minimumTokenAmount,
            "remaining tokens less then minimumTokenAmount"
        );
        require(
            remainingMemberships >= minimumMembershipAmount,
            "remaining memberships less then minimumMembershipAmount"
        );

        // adjust internal token shares
        userInfo[user].tokens = remainingTokens;
        totalTokenShares -= amount;

        // transfer GENART tokens to user
        genartToken.safeTransfer(user, amount);
        for (uint256 i; i < membershipsToWithdraw.length; i++) {
            // remove membership token id from user info object
            uint256 vaultedMembershipIndex = findArrayIndex(
                userInfo[user].membershipIds,
                membershipsToWithdraw[i]
            );
            userInfo[user].membershipIds[vaultedMembershipIndex] = userInfo[
                user
            ].membershipIds[userInfo[user].membershipIds.length - 1];

            userInfo[user].membershipIds.pop();

            membershipOwners[membershipsToWithdraw[i]] = address(0);
            // adjust internal membership shares
            totalMembershipShares -= _getMembershipShareValue(
                membershipsToWithdraw[i]
            );
            IERC721(genartMembership).transferFrom(
                address(this),
                user,
                membershipsToWithdraw[i]
            );
        }
        // transfer reward token to user
        payable(user).transfer(pendingRewards);
        emit Withdraw(user, tokens, membershipsToWithdraw);
    }

    function findArrayIndex(uint256[] memory array, uint256 value)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) return i;
        }
        revert("value not found in array");
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function _harvest(address user) internal returns (uint256) {
        // update reward for user
        _updateReward(user);

        // retrieve pending rewards
        uint256 pendingRewards = userInfo[user].rewards;

        if (pendingRewards == 0) return 0;
        // adjust user rewards and transfer
        userInfo[user].rewards = 0;

        emit Harvest(user, pendingRewards);

        return pendingRewards;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per share
     */
    function _rewardPerShare() internal view returns (uint256) {
        if (totalTokenShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock));
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        return
            (((getUserShares(user)) *
                (_rewardPerShare() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Return rewards per share
     */
    function rewardPerShare() external view returns (uint256) {
        return _rewardPerShare();
    }

    /**
     * @notice Return weighted shares of user
     */
    function getUserShares(address user) public view returns (uint256) {
        uint256 userMembershipShares;
        for (uint256 i = 0; i < userInfo[user].membershipIds.length; i++) {
            userMembershipShares += _getMembershipShareValue(
                userInfo[user].membershipIds[i]
            );
        }
        unchecked {
            uint256 tokenShares = totalTokenShares == 0
                ? 0
                : (weightFactorTokens *
                    userInfo[user].tokens *
                    PRECISION_FACTOR) / totalTokenShares;

            uint256 membershipShares = totalMembershipShares == 0
                ? 0
                : (weightFactorMemberships *
                    userMembershipShares *
                    PRECISION_FACTOR) / totalMembershipShares;
            return
                (tokenShares + membershipShares) /
                (weightFactorMemberships + weightFactorTokens);
        }
    }

    function getStake(address user)
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        return (
            userInfo[user].tokens,
            userInfo[user].membershipIds,
            totalTokenShares == 0 ? 0 : getUserShares(user),
            _calculatePendingRewards(user)
        );
    }

    function getMembershipsOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].membershipIds;
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MintAlloc.sol";
import "../access/GenArtAccess.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtMintAllocator.sol";

/**
 * @dev GEN.ART Mint Allocator
 */

contract GenArtMintAllocator is GenArtAccess, IGenArtMintAllocator {
    using MintAlloc for MintAlloc.State;

    mapping(address => MintAlloc.State) public mintstates;
    address public genartInterface;

    constructor(address genartInterface_) GenArtAccess() {
        genartInterface = genartInterface_;
    }

    /**
     *@dev Initialize mint state for collection
     */
    function init(address collection, uint8[3] memory mintAlloc)
        external
        override
        onlyAdmin
    {
        mintstates[collection].init(mintAlloc);
    }

    /**
     *@dev Update mint state
     */
    function update(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) external override onlyAdmin {
        mintstates[collection].update(
            MintUpdateParams(
                membershipId,
                IGenArtInterfaceV4(genartInterface).isGoldToken(membershipId),
                amount
            )
        );
    }

    function setReservedGold(address collection, uint8 reservedGold)
        external
        override
        onlyAdmin
    {
        mintstates[collection].setReservedGold(reservedGold);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view override returns (uint256) {
        return _getAvailableMintsForMembership(collection, membershipId);
    }

    /**
     *@dev Internal helper method to get available mints for a membershipId
     */
    function _getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) internal view returns (uint256) {
        (, , , , , uint256 maxSupply, uint256 totalSupply) = IGenArtERC721(
            collection
        ).getInfo();
        return
            mintstates[collection].getAvailableMints(
                MintParams(
                    membershipId,
                    IGenArtInterfaceV4(genartInterface).isGoldToken(
                        membershipId
                    ),
                    maxSupply,
                    totalSupply
                )
            );
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        override
        returns (uint256)
    {
        return mintstates[collection].getMints(membershipId);
    }

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        override
        returns (uint256)
    {
        uint256[] memory memberships = IGenArtInterfaceV4(genartInterface)
            .getMembershipsOf(account);
        uint256 available;
        for (uint256 i; i < memberships.length; i++) {
            available += _getAvailableMintsForMembership(
                collection,
                memberships[i]
            );
        }

        return available;
    }

    function getMintAlloc(address collection)
        external
        view
        returns (
            uint8,
            uint8,
            uint8,
            uint256
        )
    {
        return (
            mintstates[collection].reservedGoldSupply,
            mintstates[collection].allowedMintGold,
            mintstates[collection].allowedMintStandard,
            mintstates[collection]._goldMints
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMintAllocator.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";
import "./GenArtMinterBase.sol";

/**
 * @dev GEN.ART Default Minter
 * Admin for collections deployed on {GenArtCurated}
 */
struct FixedPriceParams {
    uint256 startTime;
    uint256 price;
    address mintAllocContract;
    uint8[3] mintAlloc;
}

contract GenArtMinter is GenArtMinterBase {
    mapping(address => uint256) public prices;

    constructor(address genartInterface_, address genartCurated_)
        GenArtMinterBase(genartInterface_, genartCurated_)
    {}

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data encoded pricing data
     */
    function setPricing(address collection, bytes memory data)
        external
        override
        onlyAdmin
        returns (uint256)
    {
        FixedPriceParams memory params = abi.decode(data, (FixedPriceParams));
        super._setMintParams(
            collection,
            params.startTime,
            params.mintAllocContract
        );
        prices[collection] = params.price;
        IGenArtMintAllocator(params.mintAllocContract).init(
            collection,
            params.mintAlloc
        );

        return params.price;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection, uint256 amount) internal view {
        require(
            msg.value >= getPrice(collection) * amount,
            "wrong amount sent"
        );
        require(
            mintParams[collection].startTime != 0 &&
                mintParams[collection].startTime <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Helper function to check for available mints for sender
     */
    function _checkAvailableMints(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) internal view {
        uint256 availableMints = IGenArtMintAllocator(
            mintParams[collection].mintAllocContract
        ).getAvailableMintsForMembership(collection, membershipId);
        require(availableMints >= amount, "no mints available");
        (address owner, ) = IGenArtInterfaceV4(genartInterface)
            .ownerOfMembership(membershipId);
        require(owner == msg.sender, "sender must be owner of membership");
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function mintOne(address collection, uint256 membershipId)
        external
        payable
        override
    {
        _checkMint(collection, 1);
        _checkAvailableMints(collection, membershipId, 1);
        IGenArtMintAllocator(mintParams[collection].mintAllocContract).update(
            collection,
            membershipId,
            1
        );
        IGenArtERC721(collection).mint(msg.sender, membershipId);
        _splitPayment(collection);
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param amount amount of tokens to mint
     */
    function mint(address collection, uint256 amount)
        external
        payable
        override
    {
        // get all available mints for sender
        _checkMint(collection, amount);

        // get all memberships for sender
        address user = _msgSender();
        uint256[] memory memberships = IGenArtInterfaceV4(genartInterface)
            .getMembershipsOf(user);
        uint256 minted;
        uint256 i;
        IGenArtMintAllocator mintAlloc = IGenArtMintAllocator(
            mintParams[collection].mintAllocContract
        );
        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // get available mints for membership
            uint256 membershipId = memberships[i];
            uint256 mints = mintAlloc.getAvailableMintsForMembership(
                collection,
                membershipId
            );
            // mint tokens with membership and stop if desired amount reached
            uint256 j;
            for (j = 0; j < mints && minted < amount; j++) {
                IGenArtERC721(collection).mint(user, membershipId);
                minted++;
            }
            // update mint state once membership minted tokens
            mintAlloc.update(collection, membershipId, j);
            i++;
        }
        require(minted > 0, "no mints available");
        _splitPayment(collection);
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(address collection) internal {
        uint256 value = msg.value;
        address paymentSplitter = GenArtCurated(genArtCurated)
            .store()
            .getPaymentSplitterForCollection(collection);
        IGenArtPaymentSplitterV5(paymentSplitter).splitPayment{value: value}(
            value
        );
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(address collection)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return prices[collection];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../interface/IGenArtMinter.sol";
import "../interface/IGenArtMintAllocator.sol";

/**
 * @dev GEN.ART Default Minter
 * Admin for collections deployed on {GenArtCurated}
 */

abstract contract GenArtMinterBase is GenArtAccess, IGenArtMinter {
    struct MintParams {
        uint256 startTime;
        address mintAllocContract;
    }
    address public genArtCurated;
    address public genartInterface;
    mapping(address => MintParams) public mintParams;

    constructor(address genartInterface_, address genartCurated_)
        GenArtAccess()
    {
        genartInterface = genartInterface_;
        genArtCurated = genartCurated_;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function _setMintParams(
        address collection,
        uint256 startTime,
        address mintAllocContract
    ) internal {
        require(
            mintParams[collection].startTime == 0,
            "pricing already exists for collection"
        );
        require(
            mintParams[collection].startTime < block.timestamp,
            "mint already started for collection"
        );
        require(startTime > block.timestamp, "startTime too early");

        mintParams[collection] = MintParams(startTime, mintAllocContract);
    }

    /**
     * @dev Set the {GenArtInferface} contract address
     */
    function setInterface(address genartInterface_) external onlyAdmin {
        genartInterface = genartInterface_;
    }

    /**
     * @dev Set the {GenArtCurated} contract address
     */
    function setCurated(address genartCurated_) external onlyAdmin {
        genArtCurated = genartCurated_;
    }

    /**
     * @dev Get all available mints for account
     * @param collection contract address of the collection
     * @param account address of account
     */
    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getAvailableMintsForAccount(collection, account);
    }

    /**
     * @dev Get available mints for a GEN.ART membership
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view virtual override returns (uint256) {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getAvailableMintsForMembership(collection, membershipId);
    }

    /**
     * @dev Get amount of minted tokens for a GEN.ART membership
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getMembershipMints(collection, membershipId);
    }

    /**
     * @dev Get collection {MintParams} object
     * @param collection contract address of the collection
     */
    function getMintParams(address collection)
        external
        view
        returns (MintParams memory)
    {
        return mintParams[collection];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMintAllocator.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";
import "./GenArtMinterBase.sol";

/**
 * @dev GEN.ART Minter Flash loan
 * Admin for collections deployed on {GenArtCurated}
 */

struct FlashLoanParams {
    uint256 startTime;
    uint256 price;
    address mintAllocContract;
}

contract GenArtMinterFlash is GenArtMinterBase {
    address public payoutAddress;
    address public membershipLendingPool;
    uint256 public lendingFeePercentage = 0;

    mapping(address => uint256[]) public pooledMemberships;
    mapping(address => uint256) public prices;

    constructor(
        address genartInterface_,
        address genartCurated_,
        address membershipLendingPool_,
        address payoutAddress_
    ) GenArtMinterBase(genartInterface_, genartCurated_) {
        membershipLendingPool = membershipLendingPool_;
        payoutAddress = payoutAddress_;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data encoded data
     */
    function setPricing(address collection, bytes memory data)
        external
        override
        onlyAdmin
        returns (uint256)
    {
        FlashLoanParams memory params = abi.decode(data, (FlashLoanParams));
        _setPricing(
            collection,
            params.startTime,
            params.price,
            params.mintAllocContract
        );
        return params.price;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract
    ) external onlyAdmin {
        _setPricing(collection, startTime, price, mintAllocContract);
    }

    /**
     * @dev Internal helper method to set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function _setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract
    ) internal {
        super._setMintParams(collection, startTime, mintAllocContract);
        prices[collection] = price;
        pooledMemberships[collection] = IGenArtInterfaceV4(genartInterface)
            .getMembershipsOf(membershipLendingPool);
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(address collection)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return (prices[collection] * (1000 + lendingFeePercentage)) / 1000;
    }

    /**
     * @dev Get available pooled memberships
     * @param collection contract address of the collection
     */
    function getPooledMemberships(address collection)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return pooledMemberships[collection];
    }

    /**
     * @dev Get available pooled memberships
     * @param collection contract address of the collection
     */
    function getTotalPooledMemberships(address collection)
        public
        view
        virtual
        returns (uint256)
    {
        return pooledMemberships[collection].length;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection) internal view {
        require(msg.value == getPrice(collection), "wrong amount sent");
        (, , , , , uint256 maxSupply, uint256 totalSupply) = IGenArtERC721(
            collection
        ).getInfo();
        require(totalSupply + 1 <= maxSupply, "collection sold out");
        require(
            pooledMemberships[collection].length > 0,
            "no memberships available"
        );
        require(
            mintParams[collection].startTime != 0,
            "falsh loan mint not started yet"
        );
        require(
            mintParams[collection].startTime <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param "" any uint256
     */
    function mintOne(address collection, uint256) external payable override {
        _checkMint(collection);
        uint256 membershipId = pooledMemberships[collection][
            pooledMemberships[collection].length - 1
        ];
        pooledMemberships[collection].pop();
        _mint(collection, membershipId);
        _splitPayment(collection);
    }

    /**
     * @dev Internal function to mint tokens on {IGenArtERC721} contracts
     */
    function _mint(address collection, uint256 membershipId) internal {
        IGenArtMintAllocator(mintParams[collection].mintAllocContract).update(
            collection,
            membershipId,
            1
        );
        IGenArtERC721(collection).mint(msg.sender, membershipId);
    }

    /**
     * @dev Only one token possible to mint
     * Note DO NOT USE
     */
    function mint(address, uint256) external payable override {
        revert("not implemented");
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(address collection) internal {
        uint256 value = msg.value;
        address paymentSplitter = GenArtCurated(genArtCurated)
            .store()
            .getPaymentSplitterForCollection(collection);
        uint256 amount = (value / (1000 + lendingFeePercentage)) * 1000;
        IGenArtPaymentSplitterV5(paymentSplitter).splitPayment{value: amount}(
            value
        );
    }

    /**
     * @dev Set the flash lending fee
     */
    function setMembershipLendingFee(uint256 lendingFeePercentage_)
        external
        onlyAdmin
    {
        lendingFeePercentage = lendingFeePercentage_;
    }

    /**
     * @dev Set membership pool address
     */
    function setMembershipLendingPool(address membershipLendingPool_)
        external
        onlyAdmin
    {
        membershipLendingPool = membershipLendingPool_;
    }

    /**
     * @dev Set the payout address for the flash lending fees
     */
    function setPayoutAddress(address payoutAddress_) external onlyGenArtAdmin {
        payoutAddress = payoutAddress_;
    }

    /**
     * @dev Widthdraw contract balance
     */
    function withdraw() external onlyAdmin {
        payable(payoutAddress).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMintAllocator.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";
import "./GenArtMinterBase.sol";
import {GenArtLoyalty} from "../loyalty/GenArtLoyalty.sol";

/**
 * @dev GEN.ART Minter Loyalty
 * Admin for collections deployed on {GenArtCurated}
 * Claims rebate from {GenArtLoyalty} on mint
 */

struct FixedPriceParams {
    uint256 startTime;
    uint256 price;
    address mintAllocContract;
    uint8[3] mintAlloc;
}

contract GenArtMinterLoyalty is
    GenArtMinterBase,
    GenArtLoyalty,
    ReentrancyGuard
{
    mapping(address => uint256) public prices;

    constructor(
        address genartInterface_,
        address genartCurated_,
        address genartVault_
    )
        GenArtMinterBase(genartInterface_, genartCurated_)
        GenArtLoyalty(genartVault_)
    {}

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data encoded pricing data
     */
    function setPricing(address collection, bytes memory data)
        external
        override
        onlyAdmin
        returns (uint256)
    {
        FixedPriceParams memory params = abi.decode(data, (FixedPriceParams));
        super._setMintParams(
            collection,
            params.startTime,
            params.mintAllocContract
        );
        prices[collection] = params.price;
        IGenArtMintAllocator(params.mintAllocContract).init(
            collection,
            params.mintAlloc
        );

        return params.price;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection, uint256 amount)
        internal
        view
        returns (uint256 price)
    {
        price = getPrice(collection);
        uint256 timestamp = mintParams[collection].startTime;
        uint256 value = price * amount;
        require(msg.value >= value, "wrong amount sent");
        require(
            timestamp != 0 && timestamp <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Helper function to check for available mints for sender
     */
    function _checkAvailableMints(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) internal view returns (bool) {
        uint256 availableMints = IGenArtMintAllocator(
            mintParams[collection].mintAllocContract
        ).getAvailableMintsForMembership(collection, membershipId);
        require(availableMints >= amount, "no mints available");
        (address owner, bool isVaulted) = IGenArtInterfaceV4(genartInterface)
            .ownerOfMembership(membershipId);
        require(owner == msg.sender, "sender must be owner of membership");

        return isVaulted;
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function mintOne(address collection, uint256 membershipId)
        external
        payable
        override
        nonReentrant
    {
        address user = _msgSender();
        bool isVaulted = _checkAvailableMints(collection, membershipId, 1);
        uint256 price = _checkMint(collection, 1);

        IGenArtMintAllocator(mintParams[collection].mintAllocContract).update(
            collection,
            membershipId,
            1
        );
        IGenArtERC721(collection).mint(user, membershipId);
        _splitPayment(collection, user, price, isVaulted ? 1 : 0, 1);
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param amount amount of tokens to mint
     */
    function mint(address collection, uint256 amount)
        external
        payable
        override
        nonReentrant
    {
        // get all available mints for sender
        uint256 price = _checkMint(collection, amount);

        address user = _msgSender();
        IGenArtInterfaceV4 iface = IGenArtInterfaceV4(genartInterface);
        // get all memberships for sender
        uint256[] memory memberships = iface.getMembershipsOf(user);
        uint256 minted;
        uint256 vaultedMints;
        uint256 i;
        IGenArtMintAllocator mintAlloc = IGenArtMintAllocator(
            mintParams[collection].mintAllocContract
        );
        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // get available mints for membership
            uint256 membershipId = memberships[i];
            uint256 mints = mintAlloc.getAvailableMintsForMembership(
                collection,
                membershipId
            );
            // mint tokens with membership and stop if desired amount reached
            uint256 j;
            for (j = 0; j < mints && minted < amount; j++) {
                IGenArtERC721(collection).mint(user, membershipId);
                minted++;
                if (iface.isVaulted(membershipId)) vaultedMints++;
            }
            // update mint state once membership minted tokens
            mintAlloc.update(collection, membershipId, j);
            i++;
        }
        require(minted > 0, "no mints available");
        _splitPayment(collection, user, price, vaultedMints, minted);
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(
        address collection,
        address user,
        uint256 price,
        uint256 vaultedMints,
        uint256 totalMints
    ) internal {
        uint256 value = msg.value;
        uint256 rebate = (price * baseRebateBps) / DOMINATOR;
        address paymentSplitter = GenArtCurated(genArtCurated)
            .store()
            .getPaymentSplitterForCollection(collection);
        IGenArtPaymentSplitterV5(paymentSplitter).splitPayment{
            value: value - (rebate * totalMints)
        }(value);
        uint256 rebateWindow = mintParams[collection].startTime +
            rebateWindowSec;
        if (vaultedMints > 0 && block.timestamp <= rebateWindow) {
            genartVault.lockUserWithdraw(user, rebateWindow);
            payable(user).transfer(
                ((rebate * vaultedMints * (DOMINATOR - loyaltyRewardBps)) /
                    DOMINATOR)
            );
        }
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(address collection)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return prices[collection];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMintAllocator.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";
import "./GenArtMinterBase.sol";

/**
 * @dev GEN.ART Whitelist Minter
 * Admin for collections deployed on {GenArtCurated}
 */

contract GenArtWhitelistMinter is GenArtMinterBase {
    struct WhitelistParams {
        uint256 startTime;
        uint256 price;
        address mintAllocContract;
        address[] whitelist;
    }
    address public payoutAddress;
    uint256 public whitelistFee = 0;
    mapping(address => uint256) public prices;
    mapping(address => mapping(address => bool)) public whitelists;

    constructor(
        address genartInterface_,
        address genartCurated_,
        address payoutAddress_
    ) GenArtMinterBase(genartInterface_, genartCurated_) {
        payoutAddress = payoutAddress_;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data encoded pricing data
     */
    function setPricing(address collection, bytes memory data)
        external
        override
        onlyAdmin
        returns (uint256)
    {
        WhitelistParams memory params = abi.decode(data, (WhitelistParams));
        _setPricing(
            collection,
            params.startTime,
            params.price,
            params.mintAllocContract,
            params.whitelist
        );

        return params.price;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract mint allocator contract address
     * @param whitelist list of whitelisted addresses
     */
    function setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract,
        address[] memory whitelist
    ) external onlyAdmin {
        _setPricing(collection, startTime, price, mintAllocContract, whitelist);
    }

    /**
     * @dev Internal helper method to set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract mint allocator contract address
     * @param whitelist list of whitelisted addresses
     */
    function _setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract,
        address[] memory whitelist
    ) internal {
        super._setMintParams(collection, startTime, mintAllocContract);
        prices[collection] = price;
        for (uint256 i; i < whitelist.length; i++) {
            whitelists[collection][whitelist[i]] = true;
        }
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(address collection)
        public
        view
        override
        returns (uint256)
    {
        return (prices[collection] * (1000 + whitelistFee)) / 1000;
    }

    /**
     * @dev Helper function to check for mint price, start date
     * and avaialble mints for sender
     */
    function _checkMint(address collection) internal view {
        require(msg.value >= getPrice(collection), "wrong amount sent");

        bool availableMint = whitelists[collection][msg.sender];

        require(availableMint, "no mints available");

        require(
            mintParams[collection].startTime != 0,
            "whitelist mint not started yet"
        );
        require(
            mintParams[collection].startTime <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param "" any uint256
     */
    function mintOne(address collection, uint256) external payable override {
        _checkMint(collection);
        _mint(collection);
        _splitPayment(collection);
    }

    /**
     * @dev Internal function to mint tokens on {IGenArtERC721} contracts
     */
    function _mint(address collection) internal {
        address sender = _msgSender();
        whitelists[collection][sender] = false;

        IGenArtERC721(collection).mint(sender, 0);
    }

    /**
     * @dev Only one token possible to mint
     * Note DO NOT USE
     */
    function mint(address, uint256) external payable override {
        revert("Not implemented");
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(address collection) internal {
        uint256 value = msg.value;
        address paymentSplitter = GenArtCurated(genArtCurated)
            .store()
            .getPaymentSplitterForCollection(collection);
        uint256 amount = (msg.value / (1000 + whitelistFee)) * 1000;
        IGenArtPaymentSplitterV5(paymentSplitter).splitPayment{value: amount}(
            value
        );
    }

    /**
     * @dev Set the whitelist fee
     */
    function setWhitelistFee(uint256 whitelistFee_) external onlyAdmin {
        whitelistFee = whitelistFee_;
    }

    /**
     * @dev Set the payout address for the flash lending fees
     */
    function setPayoutAddress(address payoutAddress_) external onlyGenArtAdmin {
        payoutAddress = payoutAddress_;
    }

    /**
     * @dev Get all available mints for account
     * @param collection contract address of the collection
     * @param account address of account
     */
    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return whitelists[collection][account] ? 1 : 0;
    }

    /**
     * @dev Not need
     * Note DO NOT USE
     */
    function getAvailableMintsForMembership(address, uint256)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    /**
     * @dev Not need
     * Note DO NOT USE
     */
    function getMembershipMints(address, uint256)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function setWhitelist(
        address collection,
        address account,
        bool whitelisted
    ) external onlyAdmin {
        whitelists[collection][account] = whitelisted;
    }

    /**
     * @dev Widthdraw contract balance
     */
    function withdraw() external onlyAdmin {
        payable(payoutAddress).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
struct MintParams {
    uint256 membershipId;
    bool isGold;
    uint256 maxSupply;
    uint256 totalSupply;
}
struct MintUpdateParams {
    uint256 membershipId;
    bool isGold;
    uint256 amount;
}

library MintAlloc {
    struct State {
        uint8 reservedGoldSupply;
        uint8 allowedMintGold;
        uint8 allowedMintStandard;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
        uint256 _goldMints;
    }

    function getMints(State storage state, uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        return state._mints[membershipId];
    }

    function getAllowedMints(State storage state, bool isGold)
        internal
        view
        returns (uint256)
    {
        return (isGold ? state.allowedMintGold : state.allowedMintStandard);
    }

    function getAvailableMints(State storage state, MintParams memory params)
        internal
        view
        returns (uint256)
    {
        uint256 reserved = state.reservedGoldSupply <= state._goldMints
            ? 0
            : !params.isGold
            ? (state.reservedGoldSupply - state._goldMints)
            : 0;
        uint256 availableMints = reserved >
            params.maxSupply - params.totalSupply
            ? 0
            : params.maxSupply - params.totalSupply - reserved;

        return
            availableMints > 0
                ? getAllowedMints(state, params.isGold) -
                    getMints(state, params.membershipId)
                : 0;
    }

    function init(State storage state, uint8[3] memory allocParams) internal {
        state.allowedMintStandard = allocParams[0];
        state.allowedMintGold = allocParams[1];
        state.reservedGoldSupply = allocParams[2];
    }

    function setReservedGold(State storage state, uint8 reservedGold)
        internal
    {
        state.reservedGoldSupply = reservedGold;
    }

    function update(State storage state, MintUpdateParams memory params) internal {
        unchecked {
            state._mints[params.membershipId] += params.amount;
        }
        if (params.isGold) {
            unchecked {
                state._goldMints += params.amount;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../legacy/GenArtAccess.sol";
import "./GenArtDutchAuctionHouse.sol";

contract GenArtDARefund is GenArtAccess {
    GenArtDutchAuctionHouse public _genartDA;
    mapping(address => uint256) public _refundsEth;
    address[] public _fundedCollections;
    // collection => user => bool
    mapping(address => mapping(address => bool)) public _claimedCollections;

    constructor(address genartDA_) {
        _genartDA = GenArtDutchAuctionHouse(payable(genartDA_));
    }

    /**
     * @dev modifier to only allow DA contract to call functions
     */
    modifier onlyDAContract() {
        require(
            address(_genartDA) == msg.sender,
            "GenArtDARefund: only DA contract allowed"
        );
        _;
    }

    function claim(address collection) public {
        uint256 amount = _getClaimableAmount(collection, msg.sender);
        payable(msg.sender).transfer(amount);
    }

    function claimCollections(address[] memory collections) public {
        uint256 amount;
        for (uint256 i; i < collections.length; i++) {
            amount += _getClaimableAmount(collections[i], msg.sender);
        }
        payable(msg.sender).transfer(amount);
    }

    function claimAll() public {
        _claim(msg.sender);
    }

    function _claim(address user) internal {
        uint256 amount;

        // claim all funden collections for user
        for (uint256 i; i < _fundedCollections.length; i++) {
            amount += _getClaimableAmount(_fundedCollections[i], user);
        }
        payable(user).transfer(amount);
    }

    function _getClaimableAmount(address collection, address user)
        internal
        returns (uint256)
    {
        if (_claimedCollections[collection][user]) return 0;
        uint256 refunds = calcDARefunds(collection, user);
        _claimedCollections[collection][user] = true;
        return refunds;
    }

    function calcDARefunds(address collection, address user)
        public
        view
        returns (uint256)
    {
        uint256 totalRefund;
        uint256 refundPhase = _genartDA.calcRefundPhase(collection);
        uint256 avgPrice = _genartDA.calcAvgPrice(collection);

        for (uint256 i = 1; i <= refundPhase; i++) {
            uint256 mints = _genartDA._mints(collection, user, refundPhase);
            uint256 price = _genartDA.getAuctionPriceByPhase(
                collection,
                refundPhase
            );
            totalRefund += (price - avgPrice) * mints;
        }

        return totalRefund;
    }

    function receiveFunds(address collection) external payable onlyDAContract {
        _refundsEth[collection] += msg.value;
        _fundedCollections.push(collection);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../legacy/GenArtAccess.sol";
import "./GenArtDutchAuctionHouse.sol";
import "./IGenArtSharing.sol";

contract GenArtDistributor is GenArtAccess {
    address public treasury;
    address public genartSharing;
    uint256 public treasuryShare = 0;
    uint256 public rewardDistributionPeriodBlocks = 260 * 24 * 30; // 30 days
    uint256 public rewardDistributionDelay = 260 * 24 * 14; // 14 days
    uint256 public lastRewardDistributionBlock = 0;
    uint256 public constant DOMINATOR = 1000;

    constructor(address _treasury, address _genartSharing) {
        treasury = _treasury;
        genartSharing = _genartSharing;
    }

    receive() external payable {
        if (treasuryShare == 0) return;
        // send to treasury wallet or contract
        payable(treasury).transfer((msg.value * treasuryShare) / DOMINATOR);
    }

    function setTreasuryAddress(address _treasury) public onlyAdmin {
        treasury = _treasury;
    }

    function setTreasuryShare(uint256 _share) public onlyAdmin {
        treasuryShare = _share;
    }

    function setRewardDistributionPeriod(uint256 _blocks) public onlyAdmin {
        rewardDistributionPeriodBlocks = _blocks;
    }

    function setRewardDistributionDelay(uint256 _blocks) public onlyAdmin {
        rewardDistributionDelay = _blocks;
    }

    function distributeStakingRewards() public {
        require(
            lastRewardDistributionBlock + rewardDistributionDelay <=
                block.number,
            "GenArtDistributor: distribution not ready"
        );
        uint256 balance = address(this).balance;
        require(balance > 0, "GenArtDistributor: zero balance");
        // send funds to staking contact and update rewards
        IGenArtSharing(genartSharing).updateRewards{value: balance}(
            rewardDistributionPeriodBlocks
        );
        lastRewardDistributionBlock = block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../legacy/GenArtAccess.sol";
import "./IGenArtDutchAuctionHouse.sol";
import "./MintStateDA.sol";
import "../legacy/IGenArtInterfaceV3.sol";
import "./IGenArtDARefund.sol";

contract GenArtDutchAuctionHouse is GenArtAccess, IGenArtDutchAuctionHouse {
    using MintStateDA for MintStateDA.State;

    struct Mint {
        uint256 amount;
        uint256 eth;
    }

    mapping(address => MintStateDA.State) public _mintstate;

    // maps collections to auctions
    mapping(address => Auction) public _auctions;

    // maps the auctions to memberships mints by phase
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public _mints;

    // maps total funds earned by an auction
    mapping(address => uint256) public _auctionFunds;

    // marks if artist funds for an auction have been withdrawn
    mapping(address => bool) public _artistsWithdrawHistory;

    // maps total funds earned by an auction split by phase
    mapping(address => mapping(uint256 => uint256)) public _auctionFundsByPhase;

    // uint256 public constant BLOCKS_PER_HOUR = 260;
    uint256 public constant BLOCKS_PER_HOUR = 1;
    uint256 public constant DECAY = 20;
    uint256 public constant DECAY_PER_BLOCKS = BLOCKS_PER_HOUR * 12;
    uint256 public constant BLOCKS_TO_PUBLIC_MINT = BLOCKS_PER_HOUR * 72;
    uint256 public constant AUCTION_BLOCK_DURATION = BLOCKS_PER_HOUR * 336;
    address public _genartInterface;

    /**
     @dev Artist | GEN.ART | GEN.ART Treausry/Distributor
     */
    uint256[3] public _salesShares = [700, 175, 125];

    // GEN.ART | GenArtDistributor (GENART Staking contract) | GenArtDARefund
    address[3] public _payoutAddresses = [owner(), address(0), address(0)];

    modifier onlyCollection(address collection) {
        require(
            _auctions[collection].startBlock > 0,
            "GenArtDutchAuctionHouse: only collection contract allowed"
        );
        _;
    }

    modifier onlyArtist(address collection) {
        require(
            _auctions[collection].artist == msg.sender,
            "GenArtDutchAuctionHouse: only artist allowed"
        );
        _;
    }

    function addAuction(
        address collection,
        address artist,
        uint256 supply,
        uint256 startPrice,
        uint256 startBlock,
        uint8[4] memory mintAllowanceValues
    ) public override onlyAdmin {
        _auctions[collection] = Auction({
            artist: artist,
            startBlock: startBlock,
            startPrice: startPrice,
            supply: supply,
            endBlock: startBlock + AUCTION_BLOCK_DURATION,
            distributed: false
        });
        _mintstate[collection].init(mintAllowanceValues);
    }

    function getAuction(address collection)
        public
        view
        override
        returns (Auction memory)
    {
        Auction memory auction = _auctions[collection];
        require(
            auction.startBlock > 0,
            "GenArtDutchAuctionHouse: auction not found"
        );
        return auction;
    }

    /**
    @dev Get status of an auction
    - 0 : ended
    - 1 : open for GEN.ART members
    - 2 : open for public
    */
    function getAuctionStatus(address collection)
        public
        view
        override
        returns (uint8)
    {
        Auction memory auction = getAuction(collection);
        return
            block.number > auction.endBlock
                ? 0
                : block.number > (auction.startBlock + BLOCKS_TO_PUBLIC_MINT)
                ? 2
                : 1;
    }

    /**
     * @notice An auction has 4 phases which are determinted by amount of blocks passed since start of auction
     */
    function getAuctionPhase(address collection) public view returns (uint256) {
        uint256 lambda = ((block.number - getAuction(collection).startBlock) /
            DECAY_PER_BLOCKS) + 1;
        // Maximum 4 phases
        return lambda > 4 ? 4 : lambda;
    }

    function getAuctionPriceByPhase(address collection, uint256 phase)
        public
        view
        returns (uint256)
    {
        Auction memory auction = getAuction(collection);
        return
            (auction.startPrice * ((100 - DECAY)**(phase - 1))) /
            (100**(phase - 1));
    }

    function getAuctionPrice(address collection)
        public
        view
        override
        returns (uint256)
    {
        Auction memory auction = getAuction(collection);

        // revert if auction is closed
        require(
            block.number >= auction.startBlock &&
                block.number <= auction.endBlock,
            "GenArtDutchAuctionHouse: auction closed"
        );

        uint8 status = getAuctionStatus(collection);

        // return the price based on the auction status
        return
            status == 2
                ? calcAvgPrice(collection)
                : getAuctionPriceByPhase(
                    collection,
                    getAuctionPhase(collection)
                );
    }

    function calcAvgPrice(address collection) public view returns (uint256) {
        uint256 supply = IERC721Enumerable(collection).totalSupply();

        if (supply <= 1) {
            // in case no items were sold during the auction there is no avg price
            // but the price of the last phase
            return getAuctionPriceByPhase(collection, 4);
        }
        // caclulate the average price and exclude the reserved mint
        return _auctionFunds[collection] / (supply - 1);
    }

    function getMintsByMembership(address collection, uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate[collection].getMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                getAuctionPhase(collection)
            );
    }

    function getAvailableMintsByMembership(
        address collection,
        uint256 membershipId
    ) external view override returns (uint256) {
        return
            _mintstate[collection].getAvailableMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                getAuctionPhase(collection),
                getAuction(collection).supply,
                IERC721Enumerable(collection).totalSupply()
            );
    }

    /**
        @dev Calculate the total revenue shares of an auction 
        - `index`: index of `_salesShares`
     */
    function calcShares(address collection, uint8 index)
        internal
        view
        returns (uint256)
    {
        uint256 value = ((_auctionFunds[collection] -
            calcTotalDARefundAmount(collection)) * _salesShares[index]) / 1000;

        return value;
    }

    /**
     * @notice Calculate total ETH amount to be refunded
     */
    function calcTotalDARefundAmount(address collection)
        internal
        view
        returns (uint256)
    {
        uint256 refundPhasesEth;
        uint256 refundPhasesSales;
        uint256 currentPhase = 1;
        // get avg price and exclude the reserved mint
        uint256 avgPriceDA = calcAvgPrice(collection);

        while (currentPhase <= 4) {
            uint256 price = getAuctionPriceByPhase(collection, currentPhase);
            if (price > avgPriceDA) {
                refundPhasesEth += _auctionFundsByPhase[collection][
                    currentPhase
                ];
                refundPhasesSales +=
                    _auctionFundsByPhase[collection][currentPhase] /
                    price;
            }
            currentPhase++;
        }

        uint256 totalDARefunds = refundPhasesEth -
            (refundPhasesSales * avgPriceDA);

        return totalDARefunds;
    }

    /**
     * @notice Whenever a token is minted in `GenArtERC721DA` this function is been called
     */
    function saveMint(
        uint256 membershipId,
        address minter,
        uint256 amount
    ) external onlyCollection(msg.sender) {
        uint256 phase = getAuctionPhase(msg.sender);

        // calculate amount of ETH minter has spend
        uint256 value = amount * getAuctionPriceByPhase(msg.sender, phase);

        // save amount per collection, minter and phase
        _mints[msg.sender][minter][phase] += amount;

        // update mint state
        _mintstate[msg.sender].update(
            membershipId,
            IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
            phase,
            amount
        );

        // adjust auction funds
        _auctionFundsByPhase[msg.sender][phase] += value;
    }

    /**
     * @notice External function called by GenArtERC721DA contract to send funds to the auction house
     */
    function sendFunds() external payable onlyCollection(msg.sender) {
        _auctionFunds[msg.sender] += msg.value;
    }

    /**
     * @notice Determine the phases that need to be refunded
     */
    function calcRefundPhase(address collection)
        external
        view
        returns (uint256)
    {
        uint256 refundPhase;
        uint256 currentPhase = 4;
        // get average price
        uint256 avgPriceDA = calcAvgPrice(collection);

        // loop through all phases
        while (currentPhase >= 1) {
            if (getAuctionPriceByPhase(collection, currentPhase) > avgPriceDA) {
                refundPhase = currentPhase;
                // break the loop since remaining phases must be refunded too
                break;
            }
            currentPhase--;
        }
        return refundPhase;
    }

    /**
     * @notice function for artists to withdraw their shares
     */
    function withdrawArtist(address collection) public onlyArtist(collection) {
        Auction memory auction = getAuction(collection);

        // revert if auction not ended yet
        require(
            block.number > auction.endBlock + 1,
            "GenArtDutchAuctionHouse: auction not ended yet"
        );

        // revert if funds for collection were already withdrawn
        require(
            !_artistsWithdrawHistory[collection],
            "GenArtDutchAuctionHouse: already widthdrawn"
        );

        _artistsWithdrawHistory[collection] = true;

        // send fund to artist
        payable(auction.artist).transfer(calcShares(collection, 0));
    }

    function distributeRewards(address collection) external onlyAdmin {
        Auction memory auction = getAuction(collection);

        // revert if auction not ended yet
        require(
            block.number > auction.endBlock,
            "GenArtDutchAuctionHouse: auction not finished yet"
        );

        // revert if funds for collection were already distributed
        require(
            !auction.distributed,
            "GenArtDutchAuctionHouse: already distributed"
        );

        // check if payout addresses were set
        require(
            _payoutAddresses[0] != address(0) &&
                _payoutAddresses[1] != address(0) &&
                _payoutAddresses[2] != address(0),
            "GenArtDutchAuctionHouse: payout addresses not set"
        );

        // calculate rewards for token stakers
        uint256 stakingRewards = calcShares(collection, 2);

        // calculate DA refund
        uint256 daRefunds = calcTotalDARefundAmount(collection);

        _auctions[collection].distributed = true;

        // send rewards to distributor
        payable(_payoutAddresses[1]).transfer(stakingRewards);

        // send funds to DA refund contract
        IGenArtDARefund(_payoutAddresses[2]).receiveFunds{value: daRefunds}(
            collection
        );

        // send fund to GA admin
        payable(_payoutAddresses[0]).transfer(calcShares(collection, 1));
    }

    /**
     * @notice set payout addresses
     */
    function setSalesShares(uint256[3] memory newShares)
        public
        onlyGenArtAdmin
    {
        uint256 totalShares;
        for (uint8 i; i < newShares.length; i++) {
            totalShares += newShares[i];
        }
        require(
            totalShares == 1000,
            "GenArtDutchAuctionHouse: total shares must be 1000"
        );
        _salesShares = newShares;
    }

    /**
    @dev set the payout address for ETH distribution
    - `index`: 0 (GEN.ART) | 1 (Staking contract) | 2 (Refund contract)
    - `payoutAddress`: new address
 */
    function setPayoutAddress(uint8 index, address payoutAddress)
        public
        onlyGenArtAdmin
    {
        _payoutAddresses[index] = payoutAddress;
    }

    /**
     *@dev Set Interface contract address
     */
    function setInterface(address interfaceAddress) public onlyAdmin {
        _genartInterface = interfaceAddress;
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../legacy/GenArtAccess.sol";
import "../legacy/IGenArtMembership.sol";
import "../legacy/IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterface.sol";
import "./GenArtDutchAuctionHouse.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721DA is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateDA for MintStateDA.State;

    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _royaltyPoints;
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _genartInterface;
    address public _wethAddress;
    GenArtDutchAuctionHouse public _genartDA;
    string private _uri;
    string private _script;
    bool public _paused = true;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        string memory script_,
        uint256 collectionId_,
        uint256 mintSupply_,
        address genartInterface_,
        address wethAddress_,
        address genartDA_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _script = script_;
        _collectionId = collectionId_;
        _mintSupply = mintSupply_;
        _genartInterface = genartInterface_;
        _wethAddress = wethAddress_;
        _genartDA = GenArtDutchAuctionHouse(payable(genartDA_));
        _mintOne(genartAdmin, 0);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _genartDA.getMintsByMembership(address(this), membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _genartDA.getAvailableMintsByMembership(
                address(this),
                membershipId
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(
        uint256 amount,
        uint256 availableMints,
        uint256 auctionStatus
    ) internal view {
        require(!_paused, "GenArtERC721DA: minting is paused");
        require(
            availableMints > 0 && totalSupply() + amount <= _mintSupply,
            "GenArtERC721DA: no mints available"
        );
        require(
            _genartDA.getAuctionStatus(address(this)) == auctionStatus,
            "GenArtERC721DA: not allowed to mint"
        );
        require(
            availableMints >= amount,
            "GenArtERC721DA: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _genartDA.getAuctionPrice(address(this)) * amount;
        }
        require(ethAmount == msg.value, "GenArtERC721DA: wrong amount sent");
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterface(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints, 1);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterface(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;
        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // get available mints for membership
            uint256 mints = getAvailableMintsForMembership(memberships[i]);
            // mint tokens with membership and stop if desired amount reached
            uint256 j;
            for (j = 0; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i]);
                // update mint state once membership minted a token
                minted++;
            }
            _genartDA.saveMint(memberships[i], msg.sender, j);
            i++;
        }
        _genartDA.sendFunds{value: msg.value}();
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterface(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721DA: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints, 1);
        // mint token
        mintForMembership(to, membershipId);
        // update mint state once membership minted a token
        _genartDA.saveMint(membershipId, msg.sender, 1);
        _genartDA.sendFunds{value: msg.value}();
    }

    function mintPublic(address to, uint8 amount) public payable {
        // get available mints for membership
        uint256 availableMints = _genartDA.getAuction(address(this)).supply -
            totalSupply();
        checkMint(amount, availableMints, 2);
        // mint token
        for (uint8 i; i < amount; i++) {
            _mintOne(to, 0);
        }
        // update mint state once membership minted a token
        _genartDA.sendFunds{value: msg.value}();
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(address to, uint256 membershipId) internal {
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721DA: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (_royaltyReceiver, (_royaltyPoints * salePrice_) / 10_000);
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyInfo(address receiver, uint256 royaltyPoints)
        public
        onlyGenArtAdmin
    {
        _royaltyReceiver = receiver;
        _royaltyPoints = royaltyPoints;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IGenArtInterface.sol";
import "../legacy/GenArtAccess.sol";

/**
 * @title GenArtSharing
 * @notice It handles the distribution of ETH revenues
 * @notice forked from https://etherscan.io/address/0xbcd7254a1d759efa08ec7c3291b2e85c5dcc12ce#code
 */
contract GenArtSharing is ReentrancyGuard, GenArtAccess {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 tokens; // shares of token staked
        uint256[] membershipIds;
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalTokenShares;
    uint256 public totalMembershipShares;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable genartToken;

    address public genartInterface;

    address public genartMembership;

    uint256 public weightFactorTokens = 5;
    uint256 public weightFactorMemberships = 1;

    mapping(uint256 => address) public membershipOwners;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(
        uint256 numberBlocks,
        uint256 rewardPerBlock,
        uint256 reward
    );
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Constructor
     * @param _genartToken address of the token staked (GRNART)
     */
    constructor(
        address _genartMembership,
        address _genartToken,
        address _genartInterace
    ) {
        genartToken = IERC20(_genartToken);
        genartInterface = _genartInterace;
        genartMembership = _genartMembership;
    }

    /**
     * checks requirements for depositing a stake
     */
    function _checkDeposit(uint256[] memory membershipIds, uint256 amount)
        internal
        view
    {
        // check required amount of tokens
        require(
            amount >=
                (
                    userInfo[msg.sender].membershipIds.length == 0
                        ? 4000 * PRECISION_FACTOR
                        : 0
                ),
            "GenArtSharing: amount too small"
        );
        if (userInfo[msg.sender].membershipIds.length == 0) {
            require(
                membershipIds.length > 0,
                "GenArtSharing: minimum one GEN.ART membership required"
            );
        }
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in GENART)
     */
    function deposit(uint256[] memory membershipIds, uint256 amount)
        external
        nonReentrant
    {
        _checkDeposit(membershipIds, amount);
        _deposit(membershipIds, amount);
    }

    function _deposit(uint256[] memory membershipIds, uint256 amount) internal {
        // Update reward for user
        _updateReward(msg.sender);

        // send memberships to this contract
        for (uint256 i; i < membershipIds.length; i++) {
            IERC721(genartMembership).transferFrom(
                msg.sender,
                address(this),
                membershipIds[i]
            );
            // save the membership token Ids
            userInfo[msg.sender].membershipIds.push(membershipIds[i]);
            membershipOwners[membershipIds[i]] = msg.sender;
            // adjust internal membership shares
            totalMembershipShares += _getMembershipShareValue(membershipIds[i]);
        }

        // Transfer GENART tokens to this address
        genartToken.transferFrom(msg.sender, address(this), amount);

        // Adjust internal token shares
        userInfo[msg.sender].tokens += amount;
        totalTokenShares += amount;

        emit Deposit(msg.sender, amount);
    }

    function harvest() external nonReentrant {
        // // If pending rewards are null, revert
        uint256 pendingRewards = _harvest();
        require(pendingRewards > 0, "GenArtSharing: zero rewards to harvest");
        // Transfer reward token to sender
        payable(msg.sender).transfer(pendingRewards);
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function _harvest() internal returns (uint256) {
        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 pendingRewards = userInfo[msg.sender].rewards;

        if (pendingRewards == 0) return 0;
        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        emit Harvest(msg.sender, pendingRewards);

        return pendingRewards;
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     */
    function withdraw() external nonReentrant {
        require(userInfo[msg.sender].tokens > 0, "GenArtSharing: zero shares");
        _withdraw();
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 rewardDurationInBlocks)
        external
        payable
        onlyAdmin
    {
        // Adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = msg.value / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (msg.value +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(
            rewardDurationInBlocks,
            currentRewardPerBlock,
            msg.value
        );
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Return rewards per share
     */
    function rewardPerShare() external view returns (uint256) {
        return _rewardPerShare();
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        return
            (((getUserSharesAbs(user)) *
                (_rewardPerShare() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Return absolute total shares
     */
    function getTotalSharesAbs() public view returns (uint256) {
        return
            (weightFactorTokens * totalTokenShares) +
            (weightFactorMemberships * totalMembershipShares);
    }

    /**
     * @notice Return weighted shares of user
     */
    function getUserSharesAbs(address user) public view returns (uint256) {
        uint256 userMembershipShares;
        for (uint256 i = 0; i < userInfo[user].membershipIds.length; i++) {
            userMembershipShares += _getMembershipShareValue(
                userInfo[user].membershipIds[i]
            );
        }

        unchecked {
            return (weightFactorTokens *
                userInfo[user].tokens +
                weightFactorMemberships *
                userMembershipShares);
        }
    }

    /**
     * @notice Return share value of a membership based on tier
     */
    function _getMembershipShareValue(uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        // 5 shares per gold membership. 1 share for standard memberships
        return
            (
                IGenArtInterface(genartInterface).isGoldToken(membershipId)
                    ? 5
                    : 1
            ) * PRECISION_FACTOR;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per share
     */
    function _rewardPerShare() internal view returns (uint256) {
        uint256 totalShares = getTotalSharesAbs();
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) *
                (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerShare();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens and memberships and collect rewards
     */
    function _withdraw() internal {
        // harvest rewards
        uint256 pendingRewards = _harvest();

        uint256 tokens = userInfo[msg.sender].tokens;
        uint256[] memory memberships = userInfo[msg.sender].membershipIds;

        // adjust internal token shares
        userInfo[msg.sender].tokens = 0;
        totalTokenShares -= tokens;

        // Transfer GENART tokens to sender
        genartToken.safeTransfer(msg.sender, tokens);
        for (uint256 i = memberships.length; i >= 1; i--) {
            // remove membership token id from user info object
            userInfo[msg.sender].membershipIds.pop();
            membershipOwners[memberships[i - 1]] = address(0);
            // adjust internal membership shares
            totalMembershipShares -= _getMembershipShareValue(
                memberships[i - 1]
            );
            IERC721(genartMembership).transferFrom(
                address(this),
                msg.sender,
                memberships[i - 1]
            );
        }
        // Transfer reward token to sender
        payable(msg.sender).transfer(pendingRewards);
        emit Withdraw(msg.sender, tokens);
    }

    function setWeightFactors(
        uint256 newWeightFactorTokens,
        uint256 newWeightFactorMemberships
    ) public onlyAdmin {
        weightFactorTokens = newWeightFactorTokens;
        weightFactorMemberships = newWeightFactorMemberships;
    }

    function collectDust(uint256 amount) public onlyAdmin {
        payable(owner()).transfer(amount);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function getMembershipsOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].membershipIds;
    }

    function getStake(address user)
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        uint256 totalShares = getTotalSharesAbs();
        return (
            userInfo[user].tokens,
            userInfo[user].membershipIds,
            totalShares == 0
                ? 0
                : (getUserSharesAbs(user) * PRECISION_FACTOR) / totalShares,
            _calculatePendingRewards(user)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../legacy/GenArtAccess.sol";
import "./IGenArtInterface.sol";

/**
 * @title GenArtSharingToken
 * @notice It handles the distribution of $GENART tokens
 * @notice forked from https://etherscan.io/address/0xbcd7254a1d759efa08ec7c3291b2e85c5dcc12ce#code
 */
contract GenArtSharingToken is ReentrancyGuard, GenArtAccess {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 shares; // shares of memberships staked
        uint256[] membershipIds;
        uint256 userRewardPerTokenPaid; // user reward per share paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalShares;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable genartToken;

    address public genartInterface;

    address public genartMembership;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(
        uint256 numberBlocks,
        uint256 rewardPerBlock,
        uint256 reward
    );
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Constructor
     * @param _genartToken address of the token staked (GRNART)
     */
    constructor(
        address _genartMembership,
        address _genartToken,
        address _genartInterace
    ) {
        genartToken = IERC20(_genartToken);
        genartInterface = _genartInterace;
        genartMembership = _genartMembership;
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     */
    function deposit(uint256[] memory membershipIds) external nonReentrant {
        // revert if no memberships passed
        require(
            membershipIds.length > 0,
            "GenArtSharing: minimum one membership required"
        );
        _deposit(membershipIds);
    }

    function _deposit(uint256[] memory membershipIds) internal {
        // Update reward for user
        _updateReward(msg.sender);

        uint256 shares;
        // send memberships to this contract
        for (uint256 i; i < membershipIds.length; i++) {
            IERC721(genartMembership).transferFrom(
                msg.sender,
                address(this),
                membershipIds[i]
            );

            shares += _getMembershipShareValue(membershipIds[i]);
            // save the membership token Ids
            userInfo[msg.sender].membershipIds.push(membershipIds[i]);
        }

        // adjust internal shares
        userInfo[msg.sender].shares += shares;
        totalShares += shares;

        emit Deposit(msg.sender, shares);
    }

    function harvest() external nonReentrant {
        // // If pending rewards are null, revert
        uint256 amount = _harvest();
        require(amount > 0, "GenArtSharing: zero rewards to harvest");
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function _harvest() internal returns (uint256) {
        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 pendingRewards = userInfo[msg.sender].rewards;

        if (pendingRewards == 0) return 0;
        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        // Transfer reward token to sender
        genartToken.safeTransfer(msg.sender, pendingRewards);

        emit Harvest(msg.sender, pendingRewards);

        return pendingRewards;
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     */
    function withdraw() external nonReentrant {
        require(userInfo[msg.sender].shares > 0, "GenArtSharing: zero shares");
        _withdraw();
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(
        uint256 rewardDurationInBlocks,
        address treasury,
        uint256 rewards
    ) external onlyAdmin {
        // Adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = rewards / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (rewards +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        genartToken.transferFrom(treasury, address(this), rewards);

        emit NewRewardPeriod(
            rewardDurationInBlocks,
            currentRewardPerBlock,
            rewards
        );
    }

    /**
     * @notice Return share value of a membership based on tier
     */
    function _getMembershipShareValue(uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        // 5 shares per gold membership. 1 share for standard memberships
        return
            (
                IGenArtInterface(genartInterface).isGoldToken(membershipId)
                    ? 5
                    : 1
            ) * PRECISION_FACTOR;
    }

    /**
     * @notice Return rewards per share
     */
    function rewardPerShare() external view returns (uint256) {
        return _rewardPerToken();
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        return
            ((userInfo[user].shares *
                (_rewardPerToken() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per token
     */
    function _rewardPerToken() internal view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) *
                (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerToken();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens and collect rewards
     */
    function _withdraw() internal {
        // harvest rewards
        _harvest();

        uint256 shares = userInfo[msg.sender].shares;
        uint256[] memory memberships = userInfo[msg.sender].membershipIds;

        // adjust internal shares
        userInfo[msg.sender].shares = 0;
        totalShares -= shares;

        for (uint256 i = memberships.length; i >= 1; i--) {
            userInfo[msg.sender].membershipIds.pop();
            IERC721(genartMembership).transferFrom(
                address(this),
                msg.sender,
                memberships[i - 1]
            );
        }

        emit Withdraw(msg.sender, shares);
    }

    function collectDust(uint256 amount) public onlyAdmin {
        address owner_ = owner();
        payable(owner_).transfer(address(this).balance);
        genartToken.transfer(owner_, amount);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function getMembershipsOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].membershipIds;
    }

    function getStake(address user)
        external
        view
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        return (
            userInfo[user].membershipIds,
            totalShares == 0
                ? 0
                : (userInfo[user].shares * PRECISION_FACTOR) / totalShares,
            _calculatePendingRewards(user)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtDARefund {
    function receiveFunds(address collection) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Auction {
    uint256 startBlock;
    uint256 endBlock;
    uint256 startPrice;
    uint256 supply;
    address artist;
    bool distributed;
}

interface IGenArtDutchAuctionHouse {
    function addAuction(
        address collection,
        address artist,
        uint256 supply,
        uint256 startPrice,
        uint256 startBlock,
        uint8[4] memory mintAllowanceValues
    ) external;

    function getAuction(address collection)
        external
        view
        returns (Auction memory);

    function getAuctionStatus(address collection) external view returns (uint8);

    function getAuctionPrice(address collection)
        external
        view
        returns (uint256);

    function getAvailableMintsByMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterface {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtSharing {
    function updateRewards(uint256 rewardDurationInBlocks) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStateDA {
    struct State {
        uint8 allowedMintGoldPhase1;
        uint8 allowedMintGoldPhasesOtherEach;
        uint8 allowedMintStandardPhase1;
        uint8 allowedMintStandardPhasesOtherAccu;
        // maps membershipIds to the amount of mints
        mapping(uint256 => mapping(uint256 => uint256)) _mints;
    }

    function init(State storage state, uint8[4] memory values) internal {
        state.allowedMintStandardPhase1 = values[0]; // 1
        state.allowedMintStandardPhasesOtherAccu = values[1]; //1
        state.allowedMintGoldPhase1 = values[2]; // 3
        state.allowedMintGoldPhasesOtherEach = values[3]; //1
    }

    function getMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 daPhase
    ) internal view returns (uint256) {
        uint256 key = isGold ? daPhase : daPhase > 1 ? 2 : daPhase;
        return state._mints[membershipId][key];
    }

    function getAllowedMints(
        State storage state,
        bool isGold,
        uint256 daPhase
    ) internal view returns (uint256) {
        uint256 key = isGold ? daPhase : daPhase > 1 ? 2 : daPhase;
        return
            isGold
                ? (
                    key > 1
                        ? state.allowedMintGoldPhasesOtherEach
                        : state.allowedMintGoldPhase1
                )
                : (
                    key > 1
                        ? state.allowedMintStandardPhasesOtherAccu
                        : state.allowedMintStandardPhase1
                );
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 daPhase,
        uint256 collectionSupply,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 availableMints = collectionSupply - currentSupply;

        return
            availableMints > 0
                ? getAllowedMints(state, isGold, daPhase) -
                    getMints(state, membershipId, isGold, daPhase)
                : 0;
    }

    function update(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 daPhase,
        uint256 value
    ) internal {
        uint256 key = isGold ? daPhase : daPhase > 1 ? 2 : daPhase;
        unchecked {
            state._mints[membershipId][key] += value;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";

struct Collection {
    uint256 id;
    address artist;
    address contractAddress;
    uint256 maxSupply;
    string script;
    address paymentSplitter;
}

struct Artist {
    address wallet;
    address[] collections;
}

contract GenArtStorage is GenArtAccess {
    mapping(address => Collection) public collections;
    mapping(address => Artist) public artists;

    event ScriptUpdated(address collection, string script);

    /**
     * @dev Helper function to get {PaymentSplitter} of artist
     */
    function getPaymentSplitterForCollection(address collection)
        external
        view
        returns (address)
    {
        return collections[collection].paymentSplitter;
    }

    /**
     * @dev Update script of collection
     * @param collection contract address of the collection
     * @param script single html as string
     */
    function updateScript(address collection, string memory script) external {
        address sender = _msgSender();
        require(
            collections[collection].artist == sender ||
                admins[sender] ||
                owner() == sender,
            "not allowed"
        );
        collections[collection].script = script;
        emit ScriptUpdated(collection, script);
    }

    /**
     * @dev set collection
     * @param collection contract object
     */
    function setCollection(Collection calldata collection) external onlyAdmin {
        collections[collection.contractAddress] = collection;
        artists[collection.artist].collections.push(collection.contractAddress);
    }

    /**
     * @dev set collection
     * @param artist artist object
     */
    function setArtist(Artist calldata artist) external onlyAdmin {
        artists[artist.wallet] = artist;
    }

    /**
     * @dev Get artist struct
     * @param artist adress of artist
     */
    function getArtist(address artist) external view returns (Artist memory) {
        return artists[artist];
    }

    /**
     * @dev Get collection struct
     * @param collection collection address
     */
    function getCollection(address collection)
        external
        view
        returns (Collection memory)
    {
        return collections[collection];
    }

    /**
     * @dev Update payment splitter for collection
     * @param paymentSplitter address of new payment splitter
     */
    function setPaymentSplitter(address collection, address paymentSplitter)
        external
        onlyAdmin
    {
        collections[collection].paymentSplitter = paymentSplitter;
    }
}