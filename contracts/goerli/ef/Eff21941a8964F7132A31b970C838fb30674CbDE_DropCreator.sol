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
library ClonesUpgradeable {
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
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
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0

/**

    ExpandedNFTs
    
 */

pragma solidity ^0.8.15;

import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./ExpandedNFT.sol";

contract DropCreator {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// Counter for current contract id upgraded
    CountersUpgradeable.Counter private _atContract;

    /// Address for implementation of ExpandedNFT to clone
    address public implementation;

    /// Initializes factory with address of implementation logic
    /// @param _implementation ExpandedNFT logic implementation contract to clone
    constructor(address _implementation) {
        implementation = _implementation;
    }

    /// Creates a new drop contract as a factory with a deterministic address
    /// Important: None of these fields (except the Url fields with the same hash) can be changed after calling
    /// @param _artistWallet User that created the drop
    /// @param _name Name of the drop contract
    /// @param _symbol Symbol of the drop contract
    function createDrop(
        address _artistWallet,
        string memory _name,
        string memory _symbol,
        uint256 _dropSize
    ) external returns (uint256) {
        require(_dropSize > 0, "Drop size must be > 0");

        address newContract = ClonesUpgradeable.cloneDeterministic(
            implementation,
            bytes32(abi.encodePacked(_atContract.current()))
        );

        ExpandedNFT(newContract).initialize(
            msg.sender,
            _artistWallet,
            _name,
            _symbol,
            _dropSize
        );

        uint256 newId = _atContract.current();        
        emit CreatedDrop(newId, msg.sender, _dropSize, newContract);
        // Returns the ID of the recently created minting contract
        // Also increments for the next contract creation call
        _atContract.increment();
        return newId;
    }

    /// Get drop given the created ID
    /// @param dropId id of drop to get contract for
    /// @return ExpandedNFT Drop NFT contract
    function getDropAtId(uint256 dropId)
        external
        view
        returns (ExpandedNFT)
    {
        return
            ExpandedNFT(
                ClonesUpgradeable.predictDeterministicAddress(
                    implementation,
                    bytes32(abi.encodePacked(dropId)),
                    address(this)
                )
            );
    }

    /// Emitted when a drop is created reserving the corresponding token IDs.
    /// @param dropId ID of newly created drop
    event CreatedDrop(
        uint256 indexed dropId,
        address indexed creator,
        uint256 dropSize,
        address dropContractAddress
    );
}

// SPDX-License-Identifier: GPL-3.0

/**

    ExpandedNFTs

 */

pragma solidity ^0.8.15;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {SharedNFTLogic} from "./SharedNFTLogic.sol";
import {IExpandedNFT} from "./IExpandedNFT.sol";
/**
    This is a smart contract for handling dynamic contract minting.

    @dev This allows creators to mint a unique serial drop of an expanded NFT within a custom contract
    @author Zien
    Repository: https://github.com/joinzien/expanded-nft
*/
contract ExpandedNFT is
    ERC721Upgradeable,
    IExpandedNFT,
    IERC2981Upgradeable,
    OwnableUpgradeable
{
    enum WhoCanMint{ ONLY_OWNER, VIPS, MEMBERS, ANYONE }

    enum ExpandedNFTStates{ UNMINTED, MINTED, REDEEM_STARTED, SET_OFFER_TERMS, ACCEPTED_OFFER, PRODUCTION_COMPLETE, REDEEMED }
    
    event PriceChanged(uint256 amount);
    event EditionSold(uint256 price, address owner);
    event WhoCanMintChanged(WhoCanMint minters);

    // State change events
    event RedeemStarted(uint256 tokenId, address owner);
    event RedeemAborted(uint256 tokenId, address owner);    
    event OfferTermsSet(uint256 tokenId);
    event OfferAccepted(uint256 tokenId);
    event OfferRejected(uint256 tokenId);
    event ProductionComplete(uint256 tokenId);
    event DeliveryAccepted(uint256 tokenId);

    struct PerToken { 
        // Hashmap of the Edition ID to the current 
        ExpandedNFTStates editionState;

        // Redemption price
        uint256 editionFee; 

        // Edition description
        string description;

        bool metadataLoaded;

        // Minted

        // animation_url field in the metadata
        string animationUrl;
        // Hash for the associated animation
        bytes32 animationHash;
        // Image in the metadata
        string imageUrl;
        // Hash for the associated image
        bytes32 imageHash;

        // Redeemed

        // animation_url field in the metadata
        string redeemedAnimationUrl;
        // Hash for the associated animation
        bytes32 redeemedAnimationHash;
        // Image in the metadata
        string redeemedImageUrl;
        // Hash for the associated image
        bytes32 redeemedImageHash;
        // Condition report in the metadata
        string conditionReportUrl;
        // Hash for the condition report
        bytes32 conditionReportHash;
    }

    struct Pricing { 
        // Royalty amount in bps
        uint256 royaltyBPS;

        // Split amount to the platforms. the artist in bps
        uint256 splitBPS;

        // Price for VIP sales
        uint256 vipSalePrice;

        // Price for member sales
        uint256 membersSalePrice;   

        // Price for VIP sales
        uint256 vipMintLimit;

        // Price for member sales
        uint256 membersMintLimit;

        // Price for general sales
        uint256 generalMintLimit;   

        // Addresses allowed to mint edition
        mapping(address => bool) allowedMinters;
        // VIP Addresses allowed to mint edition
        mapping(address => bool) vipAllowedMinters;

        // Who can currently mint
        WhoCanMint whoCanMint;

        // Mint counts for each address
        mapping(address => uint256) mintCounts;                               
    }

    // metadata
    string public description;

    // Artists wallet address
    address private _artistWallet;

    // Per Token data
    mapping(uint256 => PerToken) private _perTokenMetadata;

    // Total size of the drop that can be minted
    uint256 public dropSize;

    uint256 private _loadedMetadata;

    // reservation list
    uint256 private _reserveCount;
    mapping(uint256 => address) private _reserveAddress;
    mapping(uint256 => uint256) private _reserveTokenId;

    mapping(uint256 => bool) private _tokenClaimed; 
    uint256 private _claimCount; 
    uint256 private _currentIndex;

    Pricing private _pricing;

    // Price for general sales
    uint256 public salePrice;

    // ERC20 interface for the payment token
    IERC20Upgradeable private _paymentTokenERC20;

    // NFT rendering logic contract
    SharedNFTLogic private immutable _sharedNFTLogic;

    // Global constructor for factory
    constructor(SharedNFTLogic sharedNFTLogic) {
        _sharedNFTLogic = sharedNFTLogic;
        _pricing.whoCanMint = WhoCanMint.ONLY_OWNER;

        _disableInitializers();
    }

    /**
      @param _owner wallet addres for the user that owns and can mint the drop, gets royalty and sales payouts and can update the base url if needed.
      @param artistWallet wallet address for thr User that created the drop
      @param _name Name of drop, used in the title as "$NAME NUMBER/TOTAL"
      @param _symbol Symbol of the new token contract
      @param _dropSize Number of editions that can be minted in total.    
      @dev Function to create a new drop. Can only be called by the allowed creator
           Sets the only allowed minter to the address that creates/owns the drop.
           This can be re-assigned or updated later
     */
    function initialize(
        address _owner,
        address artistWallet,
        string memory _name,
        string memory _symbol,
        uint256 _dropSize
    ) public initializer {
        require(_dropSize > 0, "Drop size must be > 0");

        __ERC721_init(_name, _symbol);
        __Ownable_init();

        // Set ownership to original sender of contract call
        transferOwnership(_owner);

        _artistWallet = artistWallet;
        dropSize = _dropSize;

        // Set edition id start to be 1 not 0
        _claimCount = 0; 
        _currentIndex = 1;

        // Set the metadata
        description = _name;
        _loadedMetadata = 0; 
    }

    /**
      @param startIndex The first ID index to write the data
      @param _description How many rows of data to load
      @param count Description of the edition, used in the description field of the NFT
      @param animationUrl Animation URL of the edition. Not required, but if omitted image URL needs to be included. This follows the opensea spec for NFTs
      @param animationHash The associated hash of the animation in sha-256 bytes32 format. If animation is omitted the hash can be zero.
      @param imageUrl Image URL of the the edition. Strongly encouraged to be used, if necessary, only animation URL can be used. One of animation and image url need to exist in a drop to render the NFT.
      @param imageHash SHA256 of the given image in bytes32 format (0xHASH). If no image is included, the hash can be zero.
      @dev Function to create a new drop. Can only be called by the allowed creator
           Sets the only allowed minter to the address that creates/owns the drop.
           This can be re-assigned or updated later
     */
    function loadMetadataChunk(
        uint256 startIndex,
        uint256 count,
        string[] memory _description,
        string[] memory animationUrl,
        bytes32[] memory animationHash,
        string[] memory imageUrl,
        bytes32[] memory imageHash

    ) public {
        require(startIndex > 0, "StartIndex > 0");
        require(startIndex + count <= dropSize + 1, "Data large than drop size");

        require(_description.length == count, "Data size mismatch");
        require(animationUrl.length == count, "Data size mismatch");
        require(animationHash.length == count, "Data size mismatch");
        require(imageUrl.length == count, "Data size mismatch");
        require(imageHash.length == count, "Data size mismatch");

        for (uint i = 0; i < count; i++) {
            uint index =  startIndex + i;
            
            _perTokenMetadata[index].description = _description[i];
            _perTokenMetadata[index].imageUrl = imageUrl[i];
            _perTokenMetadata[index].imageHash = imageHash[i];
            _perTokenMetadata[index].animationUrl = animationUrl[i];
            _perTokenMetadata[index].animationHash = animationHash[i];

            if (_perTokenMetadata[index].metadataLoaded != true) {
                _perTokenMetadata[index].metadataLoaded = true;
               _loadedMetadata++; 
            }
        }
    }

    function metadataloaded() public view returns (bool){
        return (_loadedMetadata >= dropSize);
    }

    /// @dev returns the number of minted tokens within the drop
    function totalSupply() public view returns (uint256) {
        return _claimCount;
    }

    /// @dev returns the royalty BPS
    function getRoyaltyBPS() public view returns (uint256) {
        return _pricing.royaltyBPS;
    }

    /// @dev returns the split BPS
    function getSplitBPS() public view returns (uint256) {
        return _pricing.splitBPS;
    }

    /// @dev returns the VIP sale price
    function getVIPSalePrice() public view returns (uint256) {
        return _pricing.vipSalePrice;
    }

    /// @dev returns the member sale price
    function getMembersSalePrice() public view returns (uint256) {
        return _pricing.membersSalePrice;
    }

    /// @dev returns the VIP mint limit
    function getVIPMintLimit() public view returns (uint256) {
        return _pricing.vipMintLimit;
    }

    /// @dev returns the member mint limit
    function getMembersMintLimit() public view returns (uint256) {
        return _pricing.membersMintLimit;
    }

    /// @dev returns the general mint limit
    function getGeneralMintLimit() public view returns (uint256) {
        return salePrice;
    }

    /// @dev returns who can mint
    function getWhoCanMint() public view returns (uint256) {
        return uint256(_pricing.whoCanMint);
    }

    /**
        Simple eth-based sales function
        More complex sales functions can be implemented through IExpandedNFT interface
     */

    /**
      @dev This allows the user to purchase an edition
           at the given price in the contract.
     */

    function purchase() external payable returns (uint256) {
        uint256 currentPrice = _currentSalesPrice();
        emit EditionSold(currentPrice, msg.sender);

        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;

        return _mintEditionsBody(toMint);  
    }

     /**
      @param to address to send the newly minted edition to
      @dev This mints one edition to the given address by an allowed minter on the edition instance.
     */
    function mintEdition(address to) external payable override returns (uint256) {
        address[] memory toMint = new address[](1);
        toMint[0] = to;

        return _mintEditionsBody(toMint);        
    }

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditions(address[] memory recipients)
        external payable override returns (uint256)
    {
        return _mintEditionsBody(recipients);
    }   

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function _mintEditionsBody(address[] memory recipients)
        internal returns (uint256)
    {
        require(_loadedMetadata >= dropSize, "Not all metadata loaded");

        require(_isAllowedToMint(), "Needs to be an allowed minter");

        uint256 currentPrice = _currentSalesPrice();
        require(currentPrice > 0, "Not for sale");
        require(msg.value == (currentPrice * recipients.length), "Wrong price");

        require((_pricing.mintCounts[msg.sender] + recipients.length - 1) < _currentMintLimit(), "Exceeded mint limit");

        require(_claimCount + recipients.length <= dropSize, "Over drop size");

        if (_pricing.whoCanMint == WhoCanMint.VIPS) {
            return _vipMintEditions(recipients);
        }

        return _mintEditions(recipients);
    }  

    /**
      @dev Private function to mint without any access checks.
           Called by the public edition minting functions.
     */
    function _vipMintEditions(address[] memory recipients)
        internal
        returns (uint256)
    {
        address currentMinter = msg.sender;

        uint256 unclaimed = 0;
        uint256 firstUnclaimed = _reserveCount;

        for (uint256 r = 0; r < _reserveCount; r++) {
            if (_reserveAddress[r] == currentMinter) {
                uint256 id = _reserveTokenId[r];

                if (_tokenClaimed[id] != true) {
                    if (r < firstUnclaimed) {
                       firstUnclaimed = r; 
                    }

                    unclaimed++;
                }
            }
        }

        require(unclaimed >= recipients.length, "Can not mint all editions");

        uint256 idToMint = 1;

        uint256 reservationCounter = firstUnclaimed;
        for (uint256 i = 0; i < recipients.length; i++) {
            while (_reserveAddress[reservationCounter] != currentMinter) {
                reservationCounter++;
            }  

            idToMint = _reserveTokenId[reservationCounter];

            _mint(recipients[i], idToMint);

            _perTokenMetadata[idToMint].editionState = ExpandedNFTStates.MINTED;
            _tokenClaimed[idToMint] = true;
            _pricing.mintCounts[currentMinter]++;
            _claimCount++;

            reservationCounter++;
        }

        return idToMint;            
    }    

    /**
      @dev Private function to mint without any access checks.
           Called by the public edition minting functions.
     */
    function _mintEditions(address[] memory recipients)
        internal
        returns (uint256)
    {
        address currentMinter = msg.sender;
       
        for (uint256 i = 0; i < recipients.length; i++) {
            while (_tokenClaimed[_currentIndex] == true) {
                _currentIndex++;
            }  

            _mint(recipients[i], _currentIndex);

            _perTokenMetadata[_currentIndex].editionState = ExpandedNFTStates.MINTED;
            _tokenClaimed[_currentIndex] = true;
            _pricing.mintCounts[currentMinter]++;
            _claimCount++;
        }

        return _currentIndex;        
    }    

    /**
      @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
      @param _splitBPS BPS of the royalty set on the contract. Can be 0 for no royalty. 
      @param _vipSalePrice Sale price for VIPs
      @param _membersSalePrice SalePrice for Members  
      @param _generalSalePrice SalePrice for the general public     
      @param _vipMintLimit Mint limit for VIPs
      @param _membersMintLimit Mint limit for Members  
      @param _generalMintLimit Mint limit for the general public                                                                                 
      @dev Set various pricing related values
     */
    function setPricing (
        uint256 _royaltyBPS,
        uint256 _splitBPS,
        uint256 _vipSalePrice,
        uint256 _membersSalePrice,      
        uint256 _generalSalePrice,
        uint256 _vipMintLimit,
        uint256 _membersMintLimit,
        uint256 _generalMintLimit             
    ) external onlyOwner {  
        _pricing.royaltyBPS = _royaltyBPS;
        _pricing.splitBPS = _splitBPS;

        _pricing.vipSalePrice = _vipSalePrice;
        _pricing.membersSalePrice = _membersSalePrice;
        salePrice = _generalSalePrice;

        _pricing.vipMintLimit = _vipMintLimit;
        _pricing.membersMintLimit = _membersMintLimit;
        _pricing.generalMintLimit = _generalMintLimit;

        emit PriceChanged(salePrice);
    }

    /**
      @dev returns the current ETH sales price
           based on who can currently mint.
     */
    function _currentSalesPrice() internal view returns (uint256){
        if (_pricing.whoCanMint == WhoCanMint.VIPS) {
            return _pricing.vipSalePrice;
        } else if (_pricing.whoCanMint == WhoCanMint.MEMBERS) {
            return _pricing.membersSalePrice;
        } else if (_pricing.whoCanMint == WhoCanMint.ANYONE) {
            return salePrice;
        } 
            
        return 0;       
    }

    /**
      @param wallets A list of wallets
      @param tokenIDs A list of tokenId to reserve                                                                           
      @dev Set various pricing related values
     */
    function reserve (address[] calldata wallets, uint256[] calldata tokenIDs) 
        external onlyOwner {  
        for (uint256 i = 0; i < wallets.length; i++) {
            _reserveAddress[_reserveCount] = wallets[i]; 
            _reserveTokenId[_reserveCount] = tokenIDs[i];                
            _reserveCount++;
        }
    }

    /**
      @dev returns the current loimit on edition that 
           can be minted by one wallet
     */
    function _currentMintLimit() internal view returns (uint256){
        if (_pricing.whoCanMint == WhoCanMint.VIPS) {
            return _pricing.vipMintLimit;
        } else if (_pricing.whoCanMint == WhoCanMint.MEMBERS) {
            return _pricing.membersMintLimit;
        } else if (_pricing.whoCanMint == WhoCanMint.ANYONE) {
            return _pricing.generalMintLimit;
        } 
            
        return 0;       
    }

    /**
      @param _salePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @dev This sets a simple ETH sales price
           Setting a sales price allows users to mint the drop until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;

        _pricing.whoCanMint = WhoCanMint.ANYONE;

        emit WhoCanMintChanged(_pricing.whoCanMint);
        emit PriceChanged(salePrice);
    }

    /**
      @param _salePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @dev This sets the VIP ETH sales price
           Setting a sales price allows users to mint the drop until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setVIPSalePrice(uint256 _salePrice) external onlyOwner {
        _pricing.vipSalePrice = _salePrice;

        _pricing.whoCanMint = WhoCanMint.VIPS;

        emit WhoCanMintChanged(_pricing.whoCanMint);
        emit PriceChanged(salePrice);
    }

     /**
      @param _salePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @dev This sets the members ETH sales price
           Setting a sales price allows users to mint the drop until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setMembersSalePrice(uint256 _salePrice) external onlyOwner {
        _pricing.membersSalePrice = _salePrice;

        _pricing.whoCanMint = WhoCanMint.MEMBERS;

        emit WhoCanMintChanged(_pricing.whoCanMint);
        emit PriceChanged(salePrice);
    }   


     /**
      @param vipSalePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @param membersSalePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @param generalSalePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.                                              
      @dev This sets the members ETH sales price
           Setting a sales price allows users to mint the drop until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrices(uint256 vipSalePrice, uint256 membersSalePrice, uint256 generalSalePrice) external onlyOwner {
        _pricing.vipSalePrice = vipSalePrice;
        _pricing.membersSalePrice = membersSalePrice;
        salePrice = generalSalePrice;        

        emit PriceChanged(salePrice);
    }  

    /**
      @dev This withdraws ETH from the contract to the contract owner.
     */
    function withdraw() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        if (currentBalance > 0) {
            uint256 platformFee = (currentBalance * _pricing.splitBPS) / 10000;
            uint256 artistFee = currentBalance - platformFee;

            AddressUpgradeable.sendValue(payable(owner()), platformFee);
            AddressUpgradeable.sendValue(payable(_artistWallet), artistFee);
        }

        if (address(_paymentTokenERC20) != address(0x0)) {
            uint256 currentBalanceERC20 = _paymentTokenERC20.balanceOf(address(this));
            if (currentBalanceERC20 > 0) {
                uint256 platformFee = (currentBalanceERC20 * _pricing.splitBPS) / 10000;
                uint256 artistFee = currentBalanceERC20 - platformFee;

                _paymentTokenERC20.transfer(owner(), platformFee);
                _paymentTokenERC20.transfer(_artistWallet, artistFee);
            }
        }
    }

    /**
      @dev This helper function checks if the msg.sender is allowed to mint the
            given edition id.
     */
    function _isAllowedToMint() internal view returns (bool) {
        if (_pricing.whoCanMint == WhoCanMint.ANYONE) {
            return true;
        }

        if (_pricing.whoCanMint == WhoCanMint.MEMBERS) {
            if (_pricing.vipAllowedMinters[msg.sender]) {
                return true;
            }   

            if (_pricing.allowedMinters[msg.sender]) {
                return true;
            }          
        }

        if (_pricing.whoCanMint == WhoCanMint.VIPS) {
            if (_pricing.vipAllowedMinters[msg.sender]) {
                return true;
            }            
        }

        if (owner() == msg.sender) {
            return true;
        }

        return false;
    }

    /**
        Simple override for owner interface.
     */
    function owner()
        public
        view
        override(OwnableUpgradeable, IExpandedNFT)
        returns (address)
    {
        return super.owner();
    }

    /**
        return the artists wallet address
     */
    function getArtistWallet()
        public
        view
        returns (address)
    {
        return _artistWallet;
    }

     /**
        set the artists wallet address
     */
    function setArtistWallet(address wallet)
        public
        onlyOwner
    {
        _artistWallet = wallet;
    }   

    /**
        return the payment tokens address
     */
    function getPaymentToken()
        public
        view
        returns (address)
    {
        return address(_paymentTokenERC20);
    }

     /**
        set a new payment token address
     */
    function setPaymentToken(address paymentToken)
        public
        onlyOwner
    {
        if (address(_paymentTokenERC20) != address(0x0)) {
            require(_paymentTokenERC20.balanceOf(address(this)) == 0, "token must have 0 balance");
        }

        _paymentTokenERC20 = IERC20Upgradeable(paymentToken);
    }   

    /**
      @dev Sets the types of users who is allowed to mint.
     */
    function getAllowedMinter() public view returns (WhoCanMint){
        return _pricing.whoCanMint;
    }

    /**
      @param minters WhoCanMint enum of minter types
      @dev Sets the types of users who is allowed to mint.
     */
    function setAllowedMinter(WhoCanMint minters) public onlyOwner {
        require(((minters >= WhoCanMint.ONLY_OWNER) && (minters <= WhoCanMint.ANYONE)), "Needs to be a valid minter type");

        _pricing.whoCanMint = minters;
        emit WhoCanMintChanged(minters);
    }

    /**
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
             anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setApprovedMinters(uint256 count, address[] calldata minter, bool[] calldata allowed) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _pricing.allowedMinters[minter[i]] = allowed[i];
        }
    }

    /**
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
             anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setApprovedVIPMinters(uint256 count, address[] calldata minter, bool[] calldata allowed) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _pricing.vipAllowedMinters[minter[i]] = allowed[i];
        }
    }

    /**
      @dev Allows for updates of edition urls by the owner of the edition.
           Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function updateEditionURLs(
        uint256 tokenId,
        string memory imageUrl,
        string memory animationUrl
    ) public onlyOwner {
        _perTokenMetadata[tokenId].imageUrl = imageUrl;
        _perTokenMetadata[tokenId].animationUrl = animationUrl;
    }

    /// Returns the number of editions allowed to mint
    function numberCanMint() public view override returns (uint256) {
        return dropSize - _claimCount;
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id 
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");
        _burn(tokenId);
    }

    function redeem(uint256 tokenId) public {
        require(_exists(tokenId), "No token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");

        require((_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.MINTED), "You currently can not redeem");

        _perTokenMetadata[tokenId].editionState = ExpandedNFTStates.REDEEM_STARTED;
        emit RedeemStarted(tokenId, _msgSender());
    }

    function abortRedemption(uint256 tokenId) public {
        require(_exists(tokenId), "No token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");

        require((_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.REDEEM_STARTED), "You currently can not redeem");

        _perTokenMetadata[tokenId].editionState = ExpandedNFTStates.MINTED;
        emit RedeemAborted(tokenId, _msgSender());
    }

    function setOfferTerms(uint256 tokenId, uint256 fee) public onlyOwner {
        require(_exists(tokenId), "No token");        
        require((_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.REDEEM_STARTED), "Wrong state");

        _perTokenMetadata[tokenId].editionState = ExpandedNFTStates.SET_OFFER_TERMS;
        _perTokenMetadata[tokenId].editionFee = fee;

        emit OfferTermsSet(tokenId);
    }

    function rejectOfferTerms(uint256 tokenId) public {
        require(_exists(tokenId), "No token");        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");

        require((_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.SET_OFFER_TERMS), "You currently can not redeem");

        _perTokenMetadata[tokenId].editionState = ExpandedNFTStates.MINTED;

        emit OfferRejected(tokenId);
    }

    function acceptOfferTerms(uint256 tokenId, uint256 paymentAmount) external {
        require(_exists(tokenId), "No token");        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");

        require((_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.SET_OFFER_TERMS), "You currently can not redeem");

        require(paymentAmount >= _perTokenMetadata[tokenId].editionFee, "Wrong price");
        require(_paymentTokenERC20.allowance(_msgSender(), address(this)) >= _perTokenMetadata[tokenId].editionFee, "Insufficient allowance");

        bool success = _paymentTokenERC20.transferFrom(_msgSender(), address(this), _perTokenMetadata[tokenId].editionFee);
        require(success, "Could not transfer token");

        _perTokenMetadata[tokenId].editionState = ExpandedNFTStates.ACCEPTED_OFFER; 

        emit OfferAccepted(tokenId);
    }

    function productionComplete(
        uint256 tokenId,
        string memory _description,
        string memory animationUrl,
        bytes32 animationHash,
        string memory imageUrl,
        bytes32 imageHash, 
        string memory conditionReportUrl,
        bytes32 conditionReportHash               
    ) public onlyOwner {
        require(_exists(tokenId), "No token");        
        require((_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.ACCEPTED_OFFER), "You currently can not redeem");

        // Set the NFT to display as redeemed
        _perTokenMetadata[tokenId].description = _description;
        _perTokenMetadata[tokenId].redeemedAnimationUrl = animationUrl;
        _perTokenMetadata[tokenId].redeemedAnimationHash = animationHash;
        _perTokenMetadata[tokenId].redeemedImageUrl = imageUrl;
        _perTokenMetadata[tokenId].redeemedImageHash = imageHash;
        _perTokenMetadata[tokenId].conditionReportUrl = conditionReportUrl;
        _perTokenMetadata[tokenId].conditionReportHash = conditionReportHash;

        _perTokenMetadata[tokenId].editionState = ExpandedNFTStates.PRODUCTION_COMPLETE;

        emit ProductionComplete(tokenId);
    }

    function acceptDelivery(uint256 tokenId) public {
        require(_exists(tokenId), "No token");        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");

        require((_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.PRODUCTION_COMPLETE), "You currently can not redeem");

        _perTokenMetadata[tokenId].editionState = ExpandedNFTStates.REDEEMED;

        emit OfferRejected(tokenId);
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getDescription(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _perTokenMetadata[tokenId].description;
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getImageUrl(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _perTokenMetadata[tokenId].imageUrl;
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getImageHash(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return _perTokenMetadata[tokenId].imageHash;
    }

     /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getAnimationUrl(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _perTokenMetadata[tokenId].animationUrl;
    }  

     /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getAnimationHash(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return _perTokenMetadata[tokenId].animationHash;
    }  

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getRedeemedImageUrl(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _perTokenMetadata[tokenId].redeemedImageUrl;
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getRedeemedImageHash(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return _perTokenMetadata[tokenId].redeemedImageHash;
    }

     /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getRedeemedAnimationUrl(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _perTokenMetadata[tokenId].redeemedAnimationUrl;
    }   

     /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function getRedeemedAnimationHash(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return _perTokenMetadata[tokenId].redeemedAnimationHash;
    }  

    /**
      @dev Get URIs for the condition report
      @return conditionReportUrl, conditionReportHash
     */
    function getConditionReportUrl(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return (_perTokenMetadata[tokenId].conditionReportUrl);
    }

    /**
      @dev Get URIs for the condition report
      @return conditionReportUrl, conditionReportHash
     */
    function getConditionReportHash(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return (_perTokenMetadata[tokenId].conditionReportHash);
    }

    /**
        @dev Get royalty information for token
        @param _salePrice Sale price for the token
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (owner() == address(0x0)) {
            return (owner(), 0);
        }
        return (owner(), (_salePrice * _pricing.royaltyBPS) / 10_000);
    }

    /**
      @dev Get URIs for edition NFT
      @return _imageUrl, _imageHash, _animationUrl, _animationHash
     */
    function getURIs(uint256 tokenId)
        public
        view
        returns (
            string memory,
            bytes32,
            string memory,
            bytes32
        )
    {
        if (_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.REDEEMED) {        
           return (_perTokenMetadata[tokenId].redeemedImageUrl, _perTokenMetadata[tokenId].redeemedImageHash,
                _perTokenMetadata[tokenId].redeemedAnimationUrl, _perTokenMetadata[tokenId].redeemedAnimationHash);
        }

        return (_perTokenMetadata[tokenId].imageUrl, _perTokenMetadata[tokenId].imageHash,
             _perTokenMetadata[tokenId].animationUrl, _perTokenMetadata[tokenId].animationHash);
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        if (_perTokenMetadata[tokenId].editionState == ExpandedNFTStates.REDEEMED) {
            return
                _sharedNFTLogic.createMetadataEdition(
                    name(),
                    _perTokenMetadata[tokenId].description,
                    _perTokenMetadata[tokenId].redeemedImageUrl,
                    _perTokenMetadata[tokenId].redeemedAnimationUrl,
                    tokenId,
                    dropSize
                );
        }

        return
            _sharedNFTLogic.createMetadataEdition(
                name(),
                _perTokenMetadata[tokenId].description,
                _perTokenMetadata[tokenId].imageUrl,
                _perTokenMetadata[tokenId].animationUrl,
                tokenId,
                dropSize
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IExpandedNFT {
  function mintEdition(address to) external payable returns (uint256);
  function mintEditions(address[] memory to) external payable returns (uint256);
  function numberCanMint() external view returns (uint256);
  function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

/// Shared public library for on-chain NFT functions
interface IPublicSharedMetadata {
    /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        external
        pure
        returns (string memory);

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        external
        pure
        returns (string memory);

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64} from "base64-sol/base64.sol";
import {IPublicSharedMetadata} from "./IPublicSharedMetadata.sol";

/// Shared NFT logic for rendering metadata associated with editions
/// @dev Can safely be used for generic base64Encode and numberToString functions
contract SharedNFTLogic is IPublicSharedMetadata {
    /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        public
        pure
        override
        returns (string memory)
    {
        return Base64.encode(unencoded);
    }

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        public
        pure
        override
        returns (string memory)
    {
        return StringsUpgradeable.toString(value);
    }

    /// Generate edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param name Name of NFT in metadata
    /// @param description Description of NFT in metadata
    /// @param imageUrl URL of image to render for edition
    /// @param animationUrl URL of animation to render for edition
    /// @param tokenOfEdition Token ID for specific token
    /// @param editionSize Size of entire edition to show
    function createMetadataEdition(
        string memory name,
        string memory description,
        string memory imageUrl,
        string memory animationUrl,
        uint256 tokenOfEdition,
        uint256 editionSize
    ) external pure returns (string memory) {
        string memory _tokenMediaData = tokenMediaData(
            imageUrl,
            animationUrl,
            tokenOfEdition
        );
        bytes memory json = createMetadataJSON(
            name,
            description,
            _tokenMediaData,
            tokenOfEdition,
            editionSize
        );
        return encodeMetadataJSON(json);
    }

    /// Function to create the metadata json string for the nft edition
    /// @param name Name of NFT in metadata
    /// @param description Description of NFT in metadata
    /// @param mediaData Data for media to include in json object
    /// @param tokenOfEdition Token ID for specific token
    /// @param editionSize Size of entire edition to show
    function createMetadataJSON(
        string memory name,
        string memory description,
        string memory mediaData,
        uint256 tokenOfEdition,
        uint256 editionSize
    ) public pure returns (bytes memory) {
        bytes memory editionSizeText;
        if (editionSize > 0) {
            editionSizeText = abi.encodePacked(
                "/",
                numberToString(editionSize)
            );
        }
        return
            // solhint-disable quotes
            abi.encodePacked(
                '{"name": "',
                name,
                " ",
                numberToString(tokenOfEdition),
                editionSizeText,
                '", "',
                'description": "',
                description,
                '", "',
                mediaData,
                'properties": {"number": ',
                numberToString(tokenOfEdition),
                ', "name": "',
                name,
                '"}}'
            );
            // solhint-enable quotes
    }

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64Encode(json)
                )
            );
    }

    /// Generates edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param imageUrl URL of image to render for edition
    /// @param animationUrl URL of animation to render for edition
    function tokenMediaData(
        string memory imageUrl,
        string memory animationUrl,
        uint256 tokenOfEdition
    ) public pure returns (string memory) {
        bool hasImage = bytes(imageUrl).length > 0;
        bool hasAnimation = bytes(animationUrl).length > 0;
        if (hasImage && hasAnimation) {
            return
                // solhint-disable quotes
                string(
                    abi.encodePacked(
                        'image": "',
                        imageUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "animation_url": "',
                        animationUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "'
                    )
                );
                // solhint-enable quotes
        }
        if (hasImage) {
            return
                // solhint-disable quotes
                string(
                    abi.encodePacked(
                        'image": "',
                        imageUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "'
                    )
                );
                // solhint-enable quotes
        }
        if (hasAnimation) {
            return
                // solhint-disable quotes
                string(
                    abi.encodePacked(
                        'animation_url": "',
                        animationUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "'
                    )
                );
                // solhint-enable quotes
        }

        return "";
    }
}