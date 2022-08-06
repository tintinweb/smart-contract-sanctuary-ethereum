// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
                version == 1 && !Address.isContract(address(this)),
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721CollectionMetadataExtension.sol";

interface IERC721AutoIdMinterExtension {
    function setMaxSupply(uint256 newValue) external;

    function freezeMaxSupply() external;

    function totalSupply() external view returns (uint256);
}

/**
 * @dev Extension to add minting capability with an auto incremented ID for each token and a maximum supply setting.
 */
abstract contract ERC721AutoIdMinterExtension is
    IERC721AutoIdMinterExtension,
    ERC721CollectionMetadataExtension
{
    using SafeMath for uint256;

    uint256 public maxSupply;
    bool public maxSupplyFrozen;

    uint256 internal _currentTokenId = 0;

    function __ERC721AutoIdMinterExtension_init(uint256 _maxSupply)
        internal
        onlyInitializing
    {
        __ERC721AutoIdMinterExtension_init_unchained(_maxSupply);
    }

    function __ERC721AutoIdMinterExtension_init_unchained(uint256 _maxSupply)
        internal
        onlyInitializing
    {
        maxSupply = _maxSupply;

        _registerInterface(type(IERC721AutoIdMinterExtension).interfaceId);
        _registerInterface(type(IERC721).interfaceId);
    }

    /* ADMIN */

    function setMaxSupply(uint256 newValue) 
        public
        virtual
        override 
        onlyOwner 
    {
        require(!maxSupplyFrozen, "FROZEN");
        require(newValue >= totalSupply(), "LOWER_THAN_SUPPLY");
        maxSupply = newValue;
    }

    function freezeMaxSupply() external onlyOwner {
        maxSupplyFrozen = true;
    }

    /* PUBLIC */

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }

    /* INTERNAL */

    function _mintTo(address to, uint256 count) internal {
        require(totalSupply() + count <= maxSupply, "EXCEEDS_SUPPLY");

        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _currentTokenId;
            _safeMint(to, newTokenId);
            _incrementTokenId();
        }
    }

    /**
     * Increments the value of _currentTokenId
     */
    function _incrementTokenId() internal {
        _currentTokenId++;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721CollectionMetadataExtension {
    function setContractURI(string memory newValue) external;

    function contractURI() external view returns (string memory);
}

/**
 * @dev Extension to allow configuring contract-level collection metadata URI.
 */
abstract contract ERC721CollectionMetadataExtension is
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721
{
    string private _name;

    string private _symbol;

    string private _contractURI;

    function __ERC721CollectionMetadataExtension_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        __ERC721CollectionMetadataExtension_init_unchained(
            name_,
            symbol_,
            contractURI_
        );
    }

    function __ERC721CollectionMetadataExtension_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;

        _registerInterface(
            type(IERC721CollectionMetadataExtension).interfaceId
        );
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
    }

    /* ADMIN */

    function setContractURI(string memory newValue) external onlyOwner {
        _contractURI = newValue;
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721AutoIdMinterExtension.sol";

interface IERC721LockableExtension {
    function locked(uint256 tokenId) external view returns (bool);

    function lock(uint256 tokenId) external;

    function lock(uint256[] calldata tokenIds) external;

    function unlock(uint256 tokenId) external;

    function unlock(uint256[] calldata tokenIds) external;
}

/**
 * @dev Extension to allow locking NFTs, for use-cases like staking, without leaving holders wallet.
 */
abstract contract ERC721LockableExtension is
    IERC721LockableExtension,
    Initializable,
    ERC165Storage,
    ERC721AutoIdMinterExtension,
    ReentrancyGuard
{
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap internal lockedTokens;

    function __ERC721LockableExtension_init() internal onlyInitializing {
        __ERC721LockableExtension_init_unchained();
    }

    function __ERC721LockableExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721LockableExtension).interfaceId);
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721CollectionMetadataExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    /**
     * Returns if a token is locked or not.
     */
    function locked(uint256 tokenId) public view virtual returns (bool) {
        return lockedTokens.get(tokenId);
    }

    function filterUnlocked(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory unlocked = new uint256[](ticketTokenIds.length);

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            if (!locked(ticketTokenIds[i])) {
                unlocked[i] = ticketTokenIds[i];
            }
        }

        return unlocked;
    }

    /* INTERNAL */

    /**
     * At this moment staking is only possible from a certain address (usually a smart contract).
     *
     * This is because in almost all cases you want another contract to perform custom logic on lock and unlock operations,
     * without allowing users to directly unlock their tokens and sell them, for example.
     */
    function _lock(uint256 tokenId) internal virtual {
        require(!lockedTokens.get(tokenId), "LOCKED");
        lockedTokens.set(tokenId);
    }

    function _unlock(uint256 tokenId) internal virtual {
        require(lockedTokens.get(tokenId), "NOT_LOCKED");
        lockedTokens.unset(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        require(!lockedTokens.get(tokenId), "LOCKED");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

enum WithdrawMode {
    OWNER,
    RECIPIENT,
    ANYONE,
    NOBODY
}

interface IWithdrawExtension {
    function setWithdrawRecipient(address _withdrawRecipient) external;

    function lockWithdrawRecipient() external;

    function revokeWithdrawPower() external;

    function setWithdrawMode(WithdrawMode _withdrawMode) external;

    function lockWithdrawMode() external;

    function withdraw(
        address[] calldata claimTokens,
        uint256[] calldata amounts
    ) external;
}

abstract contract WithdrawExtension is
    IWithdrawExtension,
    Initializable,
    Ownable,
    ERC165Storage
{
    using Address for address;
    using Address for address payable;

    event WithdrawPowerRevoked();
    event Withdrawn(address[] claimTokens, uint256[] amounts);

    address public withdrawRecipient;
    bool public withdrawRecipientLocked;

    bool public withdrawPowerRevoked;

    WithdrawMode public withdrawMode;
    bool public withdrawModeLocked;

    /* INTERNAL */

    function __WithdrawExtension_init(
        address _withdrawRecipient,
        WithdrawMode _withdrawMode
    ) internal onlyInitializing {
        __WithdrawExtension_init_unchained(_withdrawRecipient, _withdrawMode);
    }

    function __WithdrawExtension_init_unchained(
        address _withdrawRecipient,
        WithdrawMode _withdrawMode
    ) internal onlyInitializing {
        _registerInterface(type(IWithdrawExtension).interfaceId);

        withdrawRecipient = _withdrawRecipient;
        withdrawMode = _withdrawMode;
    }

    /* ADMIN */

    function setWithdrawRecipient(address _withdrawRecipient)
        external
        onlyOwner
    {
        require(!withdrawRecipientLocked, "LOCKED");
        withdrawRecipient = _withdrawRecipient;
    }

    function lockWithdrawRecipient() external onlyOwner {
        require(!withdrawRecipientLocked, "LOCKED");
        withdrawRecipientLocked = true;
    }

    function setWithdrawMode(WithdrawMode _withdrawMode) external onlyOwner {
        require(!withdrawModeLocked, "LOCKED");
        withdrawMode = _withdrawMode;
    }

    function lockWithdrawMode() external onlyOwner {
        require(!withdrawModeLocked, "OCKED");
        withdrawModeLocked = true;
    }

    /* PUBLIC */

    function withdraw(
        address[] calldata claimTokens,
        uint256[] calldata amounts
    ) external {
        /**
         * We are using msg.sender for smaller attack surface when evaluating
         * the sender of the function call. If in future we want to handle "withdraw"
         * functionality via meta transactions, we should consider using `_msgSender`
         */
        _assertWithdrawAccess(msg.sender);

        require(withdrawRecipient != address(0), "WITHDRAW/NO_RECIPIENT");
        require(!withdrawPowerRevoked, "WITHDRAW/EMERGENCY_POWER_REVOKED");

        for (uint256 i = 0; i < claimTokens.length; i++) {
            if (claimTokens[i] == address(0)) {
                payable(withdrawRecipient).sendValue(amounts[i]);
            } else {
                IERC20(claimTokens[i]).transfer(withdrawRecipient, amounts[i]);
            }
        }

        emit Withdrawn(claimTokens, amounts);
    }

    function revokeWithdrawPower() external onlyOwner {
        withdrawPowerRevoked = true;
        emit WithdrawPowerRevoked();
    }

    /* INTERNAL */

    function _assertWithdrawAccess(address account) internal view {
        if (withdrawMode == WithdrawMode.NOBODY) {
            revert("WITHDRAW/LOCKED");
        } else if (withdrawMode == WithdrawMode.ANYONE) {
            return;
        } else if (withdrawMode == WithdrawMode.RECIPIENT) {
            require(withdrawRecipient == account, "WITHDRAW/ONLY_RECIPIENT");
        } else if (withdrawMode == WithdrawMode.OWNER) {
            require(owner() == account, "WITHDRAW/ONLY_OWNER");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721MultiTokenStream {
    // Claim native currency for a single ticket token
    function claim(uint256 ticketTokenId) external;

    // Claim an erc20 claim token for a single ticket token
    function claim(uint256 ticketTokenId, address claimToken) external;

    // Claim native currency for multiple ticket tokens (only if all owned by sender)
    function claim(uint256[] calldata ticketTokenIds) external;

    // Claim native or erc20 tokens for multiple ticket tokens (only if all owned by `owner`)
    function claim(
        uint256[] calldata ticketTokenIds,
        address claimToken,
        address owner
    ) external;

    // Total native currency ever supplied to this stream
    function streamTotalSupply() external view returns (uint256);

    // Total erc20 token ever supplied to this stream by claim token address
    function streamTotalSupply(address claimToken)
        external
        view
        returns (uint256);

    // Total native currency ever claimed from this stream
    function streamTotalClaimed() external view returns (uint256);

    // Total erc20 token ever claimed from this stream by claim token address
    function streamTotalClaimed(address claimToken)
        external
        view
        returns (uint256);

    // Total native currency ever claimed for a single ticket token
    function streamTotalClaimed(uint256 ticketTokenId)
        external
        view
        returns (uint256);

    // Total native currency ever claimed for multiple token IDs
    function streamTotalClaimed(uint256[] calldata ticketTokenIds)
        external
        view
        returns (uint256);

    // Total erc20 token ever claimed for multiple token IDs
    function streamTotalClaimed(
        uint256[] calldata ticketTokenIds,
        address claimToken
    ) external view returns (uint256);

    // Calculate currently claimable amount for a specific ticket token ID and a specific claim token address
    // Pass 0x0000000000000000000000000000000000000000 as claim token to represent native currency
    function streamClaimableAmount(uint256 ticketTokenId, address claimToken)
        external
        view
        returns (uint256 claimableAmount);
}

abstract contract ERC721MultiTokenStream is
    IERC721MultiTokenStream,
    Initializable,
    Ownable,
    ERC165Storage,
    ReentrancyGuard
{
    using Address for address;
    using Address for address payable;

    struct Entitlement {
        uint256 totalClaimed;
        uint256 lastClaimedAt;
    }

    // Config
    address public ticketToken;

    // Locks changing the config until this timestamp is reached
    uint64 public lockedUntilTimestamp;

    // Map of ticket token ID -> claim token address -> entitlement
    mapping(uint256 => mapping(address => Entitlement)) public entitlements;

    // Map of claim token address -> Total amount claimed by all holders
    mapping(address => uint256) internal _streamTotalClaimed;

    /* EVENTS */

    event Claim(
        address operator,
        address beneficiary,
        uint256 ticketTokenId,
        address claimToken,
        uint256 releasedAmount
    );

    event ClaimMany(
        address operator,
        address beneficiary,
        uint256[] ticketTokenIds,
        address claimToken,
        uint256 releasedAmount
    );

    function __ERC721MultiTokenStream_init(
        address _ticketToken,
        uint64 _lockedUntilTimestamp
    ) internal onlyInitializing {
        __ERC721MultiTokenStream_init_unchained(
            _ticketToken,
            _lockedUntilTimestamp
        );
    }

    function __ERC721MultiTokenStream_init_unchained(
        address _ticketToken,
        uint64 _lockedUntilTimestamp
    ) internal onlyInitializing {
        ticketToken = _ticketToken;
        lockedUntilTimestamp = _lockedUntilTimestamp;

        _registerInterface(type(IERC721MultiTokenStream).interfaceId);
    }

    /* ADMIN */

    function lockUntil(uint64 newValue) public onlyOwner {
        require(newValue > lockedUntilTimestamp, "CANNOT_REWIND");
        lockedUntilTimestamp = newValue;
    }

    /* PUBLIC */

    receive() external payable {
        require(msg.value > 0);
    }

    function claim(uint256 ticketTokenId) public {
        claim(ticketTokenId, address(0));
    }

    function claim(uint256 ticketTokenId, address claimToken)
        public
        nonReentrant
    {
        /* CHECKS */
        address beneficiary = _msgSender();
        _beforeClaim(ticketTokenId, claimToken, beneficiary);

        uint256 claimable = streamClaimableAmount(ticketTokenId, claimToken);
        require(claimable > 0, "NOTHING_TO_CLAIM");

        /* EFFECTS */

        entitlements[ticketTokenId][claimToken].totalClaimed += claimable;
        entitlements[ticketTokenId][claimToken].lastClaimedAt = block.timestamp;

        _streamTotalClaimed[claimToken] += claimable;

        /* INTERACTIONS */

        if (claimToken == address(0)) {
            payable(address(beneficiary)).sendValue(claimable);
        } else {
            IERC20(claimToken).transfer(beneficiary, claimable);
        }

        /* LOGS */

        emit Claim(
            _msgSender(),
            beneficiary,
            ticketTokenId,
            claimToken,
            claimable
        );
    }

    function claim(uint256[] calldata ticketTokenIds) public {
        claim(ticketTokenIds, address(0), _msgSender());
    }

    function claim(
        uint256[] calldata ticketTokenIds,
        address claimToken,
        address beneficiary
    ) public nonReentrant {
        uint256 totalClaimable;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            _beforeClaim(ticketTokenIds[i], claimToken, beneficiary);

            /* EFFECTS */
            uint256 claimable = streamClaimableAmount(
                ticketTokenIds[i],
                claimToken
            );

            if (claimable > 0) {
                entitlements[ticketTokenIds[i]][claimToken]
                    .totalClaimed += claimable;
                entitlements[ticketTokenIds[i]][claimToken]
                    .lastClaimedAt = block.timestamp;

                totalClaimable += claimable;
            }
        }

        _streamTotalClaimed[claimToken] += totalClaimable;

        /* INTERACTIONS */

        if (claimToken == address(0)) {
            payable(address(beneficiary)).sendValue(totalClaimable);
        } else {
            IERC20(claimToken).transfer(beneficiary, totalClaimable);
        }

        /* LOGS */

        emit ClaimMany(
            _msgSender(),
            beneficiary,
            ticketTokenIds,
            claimToken,
            totalClaimable
        );
    }

    /* READ ONLY */

    function streamTotalSupply() public view returns (uint256) {
        return streamTotalSupply(address(0));
    }

    function streamTotalSupply(address claimToken)
        public
        view
        returns (uint256)
    {
        if (claimToken == address(0)) {
            return _streamTotalClaimed[claimToken] + address(this).balance;
        }

        return
            _streamTotalClaimed[claimToken] +
            IERC20(claimToken).balanceOf(address(this));
    }

    function streamTotalClaimed() public view returns (uint256) {
        return _streamTotalClaimed[address(0)];
    }

    function streamTotalClaimed(address claimToken)
        public
        view
        returns (uint256)
    {
        return _streamTotalClaimed[claimToken];
    }

    function streamTotalClaimed(uint256 ticketTokenId)
        public
        view
        returns (uint256)
    {
        return entitlements[ticketTokenId][address(0)].totalClaimed;
    }

    function streamTotalClaimed(uint256 ticketTokenId, address claimToken)
        public
        view
        returns (uint256)
    {
        return entitlements[ticketTokenId][claimToken].totalClaimed;
    }

    function streamTotalClaimed(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256)
    {
        return streamTotalClaimed(ticketTokenIds, address(0));
    }

    function streamTotalClaimed(
        uint256[] calldata ticketTokenIds,
        address claimToken
    ) public view returns (uint256) {
        uint256 claimed = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            claimed += entitlements[ticketTokenIds[i]][claimToken].totalClaimed;
        }

        return claimed;
    }

    function streamClaimableAmount(
        uint256[] calldata ticketTokenIds,
        address claimToken
    ) public view returns (uint256) {
        uint256 claimable = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            claimable += streamClaimableAmount(ticketTokenIds[i], claimToken);
        }

        return claimable;
    }

    function streamClaimableAmount(uint256 ticketTokenId)
        public
        view
        returns (uint256)
    {
        return streamClaimableAmount(ticketTokenId, address(0));
    }

    function streamClaimableAmount(uint256 ticketTokenId, address claimToken)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 totalReleased = _totalTokenReleasedAmount(
            _totalStreamReleasedAmount(
                streamTotalSupply(claimToken),
                ticketTokenId,
                claimToken
            ),
            ticketTokenId,
            claimToken
        );

        return
            totalReleased -
            entitlements[ticketTokenId][claimToken].totalClaimed;
    }

    function _totalStreamReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual returns (uint256);

    function _totalTokenReleasedAmount(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual returns (uint256);

    /* INTERNAL */

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address beneficiary_
    ) internal virtual {
        require(
            IERC721(ticketToken).ownerOf(ticketTokenId_) == beneficiary_,
            "NOT_NFT_OWNER"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721LockableExtension} from "../../../collections/ERC721/extensions/ERC721LockableExtension.sol";

import "./ERC721StakingExtension.sol";

/**
 * @author Flair (https://flair.finance)
 */
interface IERC721CustodialStakingExtension {
    function hasERC721CustodialStakingExtension() external view returns (bool);

    function tokensInCustody(
        address staker,
        uint256 startTokenId,
        uint256 endTokenId
    ) external view returns (bool[] memory);
}

/**
 * @author Flair (https://flair.finance)
 */
abstract contract ERC721CustodialStakingExtension is
    IERC721CustodialStakingExtension,
    ERC721StakingExtension
{
    mapping(uint256 => address) public stakers;

    /* INIT */

    function __ERC721CustodialStakingExtension_init(
        uint64 _minStakingDuration,
        uint64 _maxStakingTotalDurations
    ) internal onlyInitializing {
        __ERC721CustodialStakingExtension_init_unchained();
        __ERC721StakingExtension_init_unchained(
            _minStakingDuration,
            _maxStakingTotalDurations
        );
    }

    function __ERC721CustodialStakingExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721CustodialStakingExtension).interfaceId);
    }

    /* PUBLIC */

    function hasERC721CustodialStakingExtension() external pure returns (bool) {
        return true;
    }

    function tokensInCustody(
        address staker,
        uint256 startTokenId,
        uint256 endTokenId
    ) external view returns (bool[] memory tokens) {
        tokens = new bool[](endTokenId - startTokenId + 1);

        for (uint256 i = startTokenId; i <= endTokenId; i++) {
            if (stakers[i] == staker) {
                tokens[i - startTokenId] = true;
            }
        }

        return tokens;
    }

    /* INTERNAL */

    function _stake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual override {
        stakers[tokenId] = operator;
        super._stake(operator, currentTime, tokenId);
        IERC721(ticketToken).transferFrom(operator, address(this), tokenId);
    }

    function _unstake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual override {
        require(stakers[tokenId] == operator, "NOT_STAKER");
        delete stakers[tokenId];

        super._unstake(operator, currentTime, tokenId);
        IERC721(ticketToken).transferFrom(address(this), operator, tokenId);
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address beneficiary_
    ) internal virtual override {
        claimToken_;

        if (stakers[ticketTokenId_] == address(0)) {
            require(
                IERC721(ticketToken).ownerOf(ticketTokenId_) == beneficiary_,
                "NOT_NFT_OWNER"
            );
        } else {
            require(beneficiary_ == stakers[ticketTokenId_], "NOT_STAKER");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

interface IERC721EmissionReleaseExtension {
    function hasERC721EmissionReleaseExtension() external view returns (bool);

    function setEmissionRate(uint256 newValue) external;

    function setEmissionTimeUnit(uint64 newValue) external;

    function setEmissionStart(uint64 newValue) external;

    function setEmissionEnd(uint64 newValue) external;

    function releasedAmountUntil(uint64 calcUntil)
        external
        view
        returns (uint256);

    function emissionAmountUntil(uint64 calcUntil)
        external
        view
        returns (uint256);

    function rateByToken(uint256[] calldata tokenIds)
        external
        view
        returns (uint256);
}

/**
 * @author Flair (https://flair.finance)
 */
abstract contract ERC721EmissionReleaseExtension is
    IERC721EmissionReleaseExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721MultiTokenStream
{
    // Number of tokens released every `emissionTimeUnit`
    uint256 public emissionRate;

    // Time unit to release tokens, users can only claim once every `emissionTimeUnit`
    uint64 public emissionTimeUnit;

    // When emission and calculating tokens starts
    uint64 public emissionStart;

    // When to stop calculating the tokens released
    uint64 public emissionEnd;

    /* INIT */

    function __ERC721EmissionReleaseExtension_init(
        uint256 _emissionRate,
        uint64 _emissionTimeUnit,
        uint64 _emissionStart,
        uint64 _emissionEnd
    ) internal onlyInitializing {
        __ERC721EmissionReleaseExtension_init_unchained(
            _emissionRate,
            _emissionTimeUnit,
            _emissionStart,
            _emissionEnd
        );
    }

    function __ERC721EmissionReleaseExtension_init_unchained(
        uint256 _emissionRate,
        uint64 _emissionTimeUnit,
        uint64 _emissionStart,
        uint64 _emissionEnd
    ) internal onlyInitializing {
        emissionRate = _emissionRate;
        emissionTimeUnit = _emissionTimeUnit;
        emissionStart = _emissionStart;
        emissionEnd = _emissionEnd;

        _registerInterface(type(IERC721EmissionReleaseExtension).interfaceId);
    }

    /* ADMIN */

    function setEmissionRate(uint256 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        emissionRate = newValue;
    }

    function setEmissionTimeUnit(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        emissionTimeUnit = newValue;
    }

    function setEmissionStart(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        emissionStart = newValue;
    }

    function setEmissionEnd(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        emissionEnd = newValue;
    }

    /* PUBLIC */

    function hasERC721EmissionReleaseExtension() external pure returns (bool) {
        return true;
    }

    function releasedAmountUntil(uint64 calcUntil)
        public
        view
        virtual
        returns (uint256)
    {
        return
            emissionRate *
            // Intentionally rounded down:
            ((calcUntil - emissionStart) / emissionTimeUnit);
    }

    function emissionAmountUntil(uint64 calcUntil)
        public
        view
        virtual
        returns (uint256)
    {
        return ((calcUntil - emissionStart) * emissionRate) / emissionTimeUnit;
    }

    function rateByToken(uint256[] calldata tokenIds)
        public
        view
        virtual
        returns (uint256);

    /* INTERNAL */

    function _totalStreamReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual override returns (uint256) {
        streamTotalSupply_;
        ticketTokenId_;
        claimToken_;

        if (block.timestamp < emissionStart) {
            return 0;
        } else if (emissionEnd > 0 && block.timestamp > emissionEnd) {
            return releasedAmountUntil(emissionEnd);
        } else {
            return releasedAmountUntil(uint64(block.timestamp));
        }
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address beneficiary_
    ) internal virtual override {
        beneficiary_;

        require(emissionStart < block.timestamp, "NOT_STARTED");

        require(
            entitlements[ticketTokenId_][claimToken_].lastClaimedAt <
                block.timestamp - emissionTimeUnit,
            "TOO_EARLY"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

interface IERC721EqualSplitExtension {
    function hasERC721EqualSplitExtension() external view returns (bool);

    function setTotalTickets(uint256 newValue) external;
}

abstract contract ERC721EqualSplitExtension is
    IERC721EqualSplitExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721MultiTokenStream
{
    // Total number of ERC721 tokens to calculate their equal split share
    uint256 public totalTickets;

    /* INTERNAL */

    function __ERC721EqualSplitExtension_init(uint256 _totalTickets)
        internal
        onlyInitializing
    {
        __ERC721EqualSplitExtension_init_unchained(_totalTickets);
    }

    function __ERC721EqualSplitExtension_init_unchained(uint256 _totalTickets)
        internal
        onlyInitializing
    {
        totalTickets = _totalTickets;

        _registerInterface(type(IERC721EqualSplitExtension).interfaceId);
    }

    /* ADMIN */

    function setTotalTickets(uint256 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        totalTickets = newValue;
    }

    /* PUBLIC */

    function hasERC721EqualSplitExtension() external pure returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _totalTokenReleasedAmount(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual override returns (uint256) {
        ticketTokenId_;
        claimToken_;

        return totalReleasedAmount_ / totalTickets;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

interface IERC721LockableClaimExtension {
    function hasERC721LockableClaimExtension() external view returns (bool);

    function setClaimLockedUntil(uint64 newValue) external;
}

abstract contract ERC721LockableClaimExtension is
    IERC721LockableClaimExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721MultiTokenStream
{
    // Claiming is only possible after this time (unix timestamp)
    uint64 public claimLockedUntil;

    /* INTERNAL */

    function __ERC721LockableClaimExtension_init(uint64 _claimLockedUntil)
        internal
        onlyInitializing
    {
        __ERC721LockableClaimExtension_init_unchained(_claimLockedUntil);
    }

    function __ERC721LockableClaimExtension_init_unchained(
        uint64 _claimLockedUntil
    ) internal onlyInitializing {
        claimLockedUntil = _claimLockedUntil;

        _registerInterface(type(IERC721LockableClaimExtension).interfaceId);
    }

    /* ADMIN */

    function setClaimLockedUntil(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        claimLockedUntil = newValue;
    }

    /* PUBLIC */

    function hasERC721LockableClaimExtension() external pure returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address beneficiary_
    ) internal virtual override {
        ticketTokenId_;
        claimToken_;
        beneficiary_;

        require(claimLockedUntil < block.timestamp, "CLAIM_LOCKED");
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

/**
 * @author Flair (https://flair.finance)
 */
interface IERC721StakingExtension {
    function hasERC721StakingExtension() external view returns (bool);

    function stake(uint256 tokenId) external;

    function stake(uint256[] calldata tokenIds) external;
}

/**
 * @author Flair (https://flair.finance)
 */
abstract contract ERC721StakingExtension is
    IERC721StakingExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721MultiTokenStream
{
    // Minimum seconds that token must be staked before unstaking.
    uint64 public minStakingDuration;

    // Maximum sum total of all durations staking that will be counted (across all stake/unstakes for each token). Staked durations beyond this number is ignored.
    uint64 public maxStakingTotalDurations;

    // Map of token ID to the time of last staking
    mapping(uint256 => uint64) public lastStakingTime;

    // Map of token ID to the sum total of all previous staked durations
    mapping(uint256 => uint64) public savedStakedDurations;

    /* INIT */

    function __ERC721StakingExtension_init(
        uint64 _minStakingDuration,
        uint64 _maxStakingTotalDurations
    ) internal onlyInitializing {
        __ERC721StakingExtension_init_unchained(
            _minStakingDuration,
            _maxStakingTotalDurations
        );
    }

    function __ERC721StakingExtension_init_unchained(
        uint64 _minStakingDuration,
        uint64 _maxStakingTotalDurations
    ) internal onlyInitializing {
        minStakingDuration = _minStakingDuration;
        maxStakingTotalDurations = _maxStakingTotalDurations;

        _registerInterface(type(IERC721StakingExtension).interfaceId);
    }

    /* ADMIN */

    function setMinStakingDuration(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        minStakingDuration = newValue;
    }

    function setMaxStakingTotalDurations(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        maxStakingTotalDurations = newValue;
    }

    /* PUBLIC */

    function hasERC721StakingExtension() external pure returns (bool) {
        return true;
    }

    function stake(uint256 tokenId) public virtual {
        _stake(_msgSender(), uint64(block.timestamp), tokenId);
    }

    function stake(uint256[] calldata tokenIds) public virtual {
        address operator = _msgSender();
        uint64 currentTime = uint64(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(operator, currentTime, tokenIds[i]);
        }
    }

    function unstake(uint256 tokenId) public virtual {
        _unstake(_msgSender(), uint64(block.timestamp), tokenId);
    }

    function unstake(uint256[] calldata tokenIds) public virtual {
        address operator = _msgSender();
        uint64 currentTime = uint64(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(operator, currentTime, tokenIds[i]);
        }
    }

    function totalStakedDuration(uint256[] calldata ticketTokenIds)
        public
        view
        virtual
        returns (uint64)
    {
        uint64 totalDurations = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalDurations += totalStakedDuration(ticketTokenIds[i]);
        }

        return totalDurations;
    }

    function totalStakedDuration(uint256 ticketTokenId)
        public
        view
        virtual
        returns (uint64)
    {
        uint64 total = savedStakedDurations[ticketTokenId];

        if (lastStakingTime[ticketTokenId] > 0) {
            uint64 targetTime = _stakingTimeLimit();

            if (targetTime > block.timestamp) {
                targetTime = uint64(block.timestamp);
            }

            if (lastStakingTime[ticketTokenId] > 0) {
                if (targetTime > lastStakingTime[ticketTokenId]) {
                    total += (targetTime - lastStakingTime[ticketTokenId]);
                }
            }
        }

        if (total > maxStakingTotalDurations) {
            total = maxStakingTotalDurations;
        }

        return total;
    }

    function unlockingTime(uint256 ticketTokenId)
        public
        view
        returns (uint256)
    {
        return
            lastStakingTime[ticketTokenId] > 0
                ? lastStakingTime[ticketTokenId] + minStakingDuration
                : 0;
    }

    function unlockingTime(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory unlockedAt = new uint256[](ticketTokenIds.length);

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            unlockedAt[i] = unlockingTime(ticketTokenIds[i]);
        }

        return unlockedAt;
    }

    /* INTERNAL */

    function _stakingTimeLimit() internal view virtual returns (uint64) {
        return 18_446_744_073_709_551_615; // max(uint64)
    }

    function _stake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual {
        require(
            totalStakedDuration(tokenId) < maxStakingTotalDurations,
            "MAX_DURATION_EXCEEDED"
        );

        lastStakingTime[tokenId] = currentTime;
    }

    function _unstake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual {
        operator;

        require(lastStakingTime[tokenId] > 0, "NOT_STAKED");

        require(
            currentTime >= lastStakingTime[tokenId] + minStakingDuration,
            "NOT_STAKED_LONG_ENOUGH"
        );

        savedStakedDurations[tokenId] = totalStakedDuration(tokenId);

        lastStakingTime[tokenId] = 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../../common/WithdrawExtension.sol";
import "../extensions/ERC721EmissionReleaseExtension.sol";
import "../extensions/ERC721EqualSplitExtension.sol";
import "../extensions/ERC721CustodialStakingExtension.sol";
import "../extensions/ERC721LockableClaimExtension.sol";

/**
 * @author Flair (https://flair.finance)
 */
contract ERC721CustodialStakingEmissionStream is
    Initializable,
    Ownable,
    ERC721EmissionReleaseExtension,
    ERC721EqualSplitExtension,
    ERC721CustodialStakingExtension,
    ERC721LockableClaimExtension,
    WithdrawExtension
{
    using Address for address;
    using Address for address payable;

    string public constant name = "ERC721 Custodial Staking Emission Stream";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Locked staking extension
        uint64 minStakingDuration; // in seconds. Minimum time the NFT must stay locked before unstaking.
        uint64 maxStakingTotalDurations; // in seconds. Maximum sum total of all durations staking that will be counted (across all stake/unstakes for each token).
        // Emission release extension
        uint256 emissionRate;
        uint64 emissionTimeUnit;
        uint64 emissionStart;
        uint64 emissionEnd;
        // Equal split extension
        uint256 totalTickets;
        // Lockable claim extension
        uint64 claimLockedUntil;
    }

    /* INTERNAL */

    constructor(Config memory config) {
        initialize(config, msg.sender);
    }

    function initialize(Config memory config, address deployer)
        public
        initializer
    {
        _transferOwnership(deployer);

        __WithdrawExtension_init(deployer, WithdrawMode.OWNER);
        __ERC721MultiTokenStream_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __ERC721CustodialStakingExtension_init(
            config.minStakingDuration,
            config.maxStakingTotalDurations
        );
        __ERC721EmissionReleaseExtension_init(
            config.emissionRate,
            config.emissionTimeUnit,
            config.emissionStart,
            config.emissionEnd
        );
        __ERC721EqualSplitExtension_init(config.totalTickets);
        __ERC721LockableClaimExtension_init(config.claimLockedUntil);
    }

    function _totalStreamReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    )
        internal
        view
        virtual
        override(ERC721MultiTokenStream, ERC721EmissionReleaseExtension)
        returns (uint256)
    {
        // Removing the logic from emission extension because it is irrevelant when staking.
        return 0;
    }

    function _totalTokenReleasedAmount(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    )
        internal
        view
        virtual
        override(ERC721MultiTokenStream, ERC721EqualSplitExtension)
        returns (uint256)
    {
        totalReleasedAmount_;
        ticketTokenId_;
        claimToken_;

        // Get the rate per token to calculate based on stake duration
        return
            (emissionRate / totalTickets) *
            // Intentionally rounded down
            (totalStakedDuration(ticketTokenId_) / emissionTimeUnit);
    }

    function _stakingTimeLimit()
        internal
        view
        virtual
        override
        returns (uint64)
    {
        if (emissionEnd > 0) {
            return emissionEnd;
        }

        return super._stakingTimeLimit();
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address beneficiary_
    )
        internal
        override(
            ERC721MultiTokenStream,
            ERC721CustodialStakingExtension,
            ERC721EmissionReleaseExtension,
            ERC721LockableClaimExtension
        )
    {
        // Intentionally skipping ERC721MultiTokenStream because we need to check ownership based on current status of custody.
        ERC721CustodialStakingExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            beneficiary_
        );
        ERC721LockableClaimExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            beneficiary_
        );
        ERC721EmissionReleaseExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            beneficiary_
        );
    }

    /* PUBLIC */

    function stake(uint256 tokenId) public override nonReentrant {
        require(uint64(block.timestamp) >= emissionStart, "NOT_STARTED_YET");

        super.stake(tokenId);
    }

    function stake(uint256[] calldata tokenIds) public override nonReentrant {
        require(uint64(block.timestamp) >= emissionStart, "NOT_STARTED_YET");

        super.stake(tokenIds);
    }

    function unstake(uint256 tokenId) public override nonReentrant {
        super.unstake(tokenId);
    }

    function unstake(uint256[] calldata tokenIds) public override nonReentrant {
        super.unstake(tokenIds);
    }

    function rateByToken(uint256[] calldata tokenIds)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 staked;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (lastStakingTime[tokenIds[i]] > 0) {
                staked++;
            }
        }

        return (emissionRate * staked) / totalTickets;
    }

    function rewardAmountByToken(uint256 ticketTokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return
            ((emissionRate * totalStakedDuration(ticketTokenId)) /
                totalTickets) / emissionTimeUnit;
    }

    function rewardAmountByToken(uint256[] calldata ticketTokenIds)
        public
        view
        virtual
        returns (uint256 total)
    {
        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            total += rewardAmountByToken(ticketTokenIds[i]);
        }
    }
}