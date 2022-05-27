// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
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
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "base64-sol/base64.sol";

import {IBorrowerPools} from "./interfaces/IBorrowerPools.sol";
import {IPoolsController} from "./interfaces/IPoolsController.sol";

import "./interfaces/IBorrowerPools.sol";
import "./interfaces/IPositionDescriptor.sol";
import "./interfaces/IPositionManager.sol";
import "./lib/Errors.sol";
import "./lib/Scaling.sol";
import "./lib/Types.sol";

contract PositionManager is ERC721Upgradeable, IPositionManager {
  using Scaling for uint128;

  IBorrowerPools public pools;
  IPositionDescriptor public positionDescriptor;

  // next position id
  uint128 private _nextId;

  mapping(uint128 => Types.PositionDetails) public _positions;

  function initialize(
    string memory _name,
    string memory _symbol,
    IBorrowerPools _pools,
    IPositionDescriptor _positionDescriptor
  ) public virtual initializer {
    __ERC721_init(_name, _symbol);
    pools = _pools;
    positionDescriptor = _positionDescriptor;
    _nextId = 1;
  }

  /**
   * @notice Emitted when #withdraw is called and is a success
   * @param tokenId The tokenId of the position
   * @return poolHash The identifier of the pool
   * @return adjustedBalance Adjusted balance of the position original deposit
   * @return rate Position bidding rate
   * @return underlyingToken Address of the tokens the position contains
   * @return remainingBonds Quantity of bonds remaining in the position after a partial withdraw
   * @return bondsMaturity Maturity of the position's remaining bonds
   * @return bondsIssuanceIndex Borrow period the deposit was made in
   **/
  function position(uint128 tokenId)
    public
    view
    override
    returns (
      bytes32 poolHash,
      uint128 adjustedBalance,
      uint128 rate,
      address underlyingToken,
      uint128 remainingBonds,
      uint128 bondsMaturity,
      uint128 bondsIssuanceIndex
    )
  {
    Types.PositionDetails memory _position = _positions[tokenId];
    return (
      _position.poolHash,
      _position.adjustedBalance,
      _position.rate,
      _position.underlyingToken,
      _position.remainingBonds,
      _position.bondsMaturity,
      _position.bondsIssuanceIndex
    );
  }

  /**
   * @notice Returns the encoded svg data
   * @param tokenId The tokenId of the position
   * @return encoded svg
   **/
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
      revert Errors.POS_POSITION_DOES_NOT_EXIST();
    }
    return IPositionDescriptor(positionDescriptor).tokenURI(this, uint128(tokenId));
  }

  function revertIfPositionDefaulted(uint256 tokenId) private view {
    (, bool defaulted, , , , , , , , , , ) = IPoolsController(address(pools)).getPoolState(
      _positions[uint128(tokenId)].poolHash
    );
    if (defaulted) {
      revert Errors.POS_POOL_DEFAULTED();
    }
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    revertIfPositionDefaulted(tokenId);
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    revertIfPositionDefaulted(tokenId);
    super.safeTransferFrom(from, to, tokenId);
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
    revertIfPositionDefaulted(tokenId);
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  /**
   * @notice Returns the balance on yield provider and the quantity of bond held
   * @param tokenId The tokenId of the position
   * @return bondsQuantity Quantity of bond held, represents funds borrowed
   * @return normalizedDepositedAmount Amount of deposit placed on yield provider
   **/
  function getPositionRepartition(uint128 tokenId)
    external
    view
    override
    returns (uint128 bondsQuantity, uint128 normalizedDepositedAmount)
  {
    if (!_exists(tokenId)) {
      return (0, 0);
    }
    uint256 poolCurrentMaturity = pools.getPoolMaturity(_positions[tokenId].poolHash);
    if ((_positions[tokenId].bondsMaturity > 0) && (_positions[tokenId].bondsMaturity == poolCurrentMaturity)) {
      return (_positions[tokenId].remainingBonds, 0);
    }
    return
      pools.getAmountRepartition(
        _positions[tokenId].poolHash,
        _positions[tokenId].rate,
        _positions[tokenId].adjustedBalance,
        _positions[tokenId].bondsIssuanceIndex
      );
  }

  /**
   * @notice Deposits tokens into the yield provider and places a bid at the indicated rate within the
   * respective pool's order book. A new position is created within the positions map that keeps
   * track of this position's composition. An ERC721 NFT is minted for the user as a representation
   * of the position.
   * @param to The address for which the position is created
   * @param amount The amount of tokens to be deposited
   * @param rate The rate at which to bid for a bonds
   * @param poolHash The identifier of the pool
   * @param underlyingToken The contract address of the token to be deposited
   **/
  function deposit(
    address to,
    uint128 amount,
    uint128 rate,
    bytes32 poolHash,
    address underlyingToken
  ) external override returns (uint128 tokenId) {
    if (amount == 0) {
      revert Errors.POS_ZERO_AMOUNT();
    }

    tokenId = _nextId++;

    _safeMint(to, tokenId);

    uint8 decimals = ERC20Upgradeable(underlyingToken).decimals();

    uint128 normalizedAmount = amount.scaleToWad(decimals);

    (uint128 adjustedBalance, uint128 bondsIssuanceIndex) = pools.deposit(
      rate,
      poolHash,
      underlyingToken,
      _msgSender(),
      normalizedAmount
    );

    _positions[tokenId] = Types.PositionDetails({
      adjustedBalance: adjustedBalance,
      rate: rate,
      poolHash: poolHash,
      underlyingToken: underlyingToken,
      remainingBonds: 0,
      bondsMaturity: 0,
      bondsIssuanceIndex: bondsIssuanceIndex,
      creationTimestamp: uint128(block.timestamp)
    });

    emit Deposit(to, tokenId, normalizedAmount, rate, poolHash, bondsIssuanceIndex);
  }

  /**
   * @notice Allows a user to update the rate at which to bid for bonds. A rate is only
   * upgradable as long as the full amount of deposits are currently allocated with the
   * yield provider i.e the position does not hold any bonds.
   * @param tokenId The tokenId of the position
   * @param newRate The new rate at which to bid for bonds
   **/
  function updateRate(uint128 tokenId, uint128 newRate) external override {
    if (ownerOf(tokenId) != _msgSender()) {
      revert Errors.POS_MGMT_ONLY_OWNER();
    }
    if (_positions[tokenId].creationTimestamp == block.timestamp) {
      revert Errors.POS_TIMELOCK();
    }

    uint128 oldRate = _positions[tokenId].rate;

    (uint128 newAmount, uint128 newBondsIssuanceIndex, uint128 normalizedAmount) = pools.updateRate(
      _positions[tokenId].adjustedBalance,
      _positions[tokenId].poolHash,
      oldRate,
      newRate,
      _positions[tokenId].bondsIssuanceIndex
    );

    _positions[tokenId].adjustedBalance = newAmount;
    _positions[tokenId].rate = newRate;
    _positions[tokenId].bondsIssuanceIndex = newBondsIssuanceIndex;

    emit UpdateRate(_msgSender(), tokenId, normalizedAmount, newRate, _positions[tokenId].poolHash);
  }

  /**
   * @notice Withdraws the amount of tokens that are deposited with the yield provider.
   * The bonds portion of the position is not affected.
   * @param tokenId The tokenId of the position
   **/
  function withdraw(uint128 tokenId) external override {
    if (ownerOf(tokenId) != _msgSender()) {
      revert Errors.POS_MGMT_ONLY_OWNER();
    }
    if (_positions[tokenId].creationTimestamp == block.timestamp) {
      revert Errors.POS_TIMELOCK();
    }
    uint256 poolCurrentMaturity = pools.getPoolMaturity(_positions[tokenId].poolHash);
    if (
      !((_positions[tokenId].remainingBonds == 0) ||
        ((block.timestamp >= _positions[tokenId].bondsMaturity) &&
          (_positions[tokenId].bondsMaturity != poolCurrentMaturity)))
    ) {
      revert Errors.POS_POSITION_ONLY_IN_BONDS();
    }

    (
      uint128 adjustedAmountToWithdraw,
      uint128 depositedAmountToWithdraw,
      uint128 remainingBondsQuantity,
      uint128 bondsMaturity
    ) = pools.getWithdrawAmounts(
        _positions[tokenId].poolHash,
        _positions[tokenId].rate,
        _positions[tokenId].adjustedBalance,
        _positions[tokenId].bondsIssuanceIndex
      );

    _positions[tokenId].adjustedBalance -= depositedAmountToWithdraw;
    _positions[tokenId].remainingBonds = remainingBondsQuantity;
    _positions[tokenId].bondsMaturity = bondsMaturity;

    uint128 normalizedWithdrawnDeposit = pools.withdraw(
      _positions[tokenId].poolHash,
      _positions[tokenId].rate,
      adjustedAmountToWithdraw,
      _positions[tokenId].bondsIssuanceIndex,
      _msgSender()
    );

    emit Withdraw(
      _msgSender(),
      tokenId,
      normalizedWithdrawnDeposit,
      remainingBondsQuantity,
      _positions[tokenId].rate,
      _positions[tokenId].poolHash
    );

    if (_positions[tokenId].remainingBonds == 0) {
      _burn(tokenId);
      delete _positions[tokenId];
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../extensions/AaveILendingPool.sol";
import "../lib/Types.sol";

/**
 * @title IBorrowerPools
 * @notice Used by the Position contract to pool lender positions in the borrowers order books
 *         Used by the borrowers to manage their loans on their pools
 **/
interface IBorrowerPools {
  // EVENTS

  /**
   * @notice Emitted after a successful borrow
   * @param poolHash The identifier of the pool
   * @param normalizedBorrowedAmount The actual amount of tokens borrowed
   * @param establishmentFees Fees paid to the protocol at borrow time
   **/
  event Borrow(bytes32 indexed poolHash, uint128 normalizedBorrowedAmount, uint128 establishmentFees);

  /**
   * @notice Emitted after a successful further borrow
   * @param poolHash The identifier of the pool
   * @param normalizedBorrowedAmount The actual amount of tokens borrowed
   * @param establishmentFees Fees paid to the protocol at borrow time
   **/
  event FurtherBorrow(bytes32 indexed poolHash, uint128 normalizedBorrowedAmount, uint128 establishmentFees);

  /**
   * @notice Emitted after a successful repay
   * @param poolHash The identifier of the pool
   * @param normalizedRepayAmount The actual amount of tokens repaid
   * @param repaymentFee The amount of fee paid to the protocol at repay time
   * @param normalizedDepositsAfterRepay The actual amount of tokens deposited and available for next loan after repay
   * @param nextLoanMinStart The timestamp after which a new loan can be taken
   **/
  event Repay(
    bytes32 indexed poolHash,
    uint128 normalizedRepayAmount,
    uint128 repaymentFee,
    uint128 normalizedDepositsAfterRepay,
    uint128 nextLoanMinStart
  );

  /**
   * @notice Emitted after a successful early repay
   * @param poolHash The identifier of the pool
   * @param normalizedRepayAmount The actual amount of tokens repaid
   * @param repaymentFee The amount of fee paid to the protocol at repay time
   * @param normalizedDepositsAfterRepay The actual amount of tokens deposited and available for next loan after repay
   * @param nextLoanMinStart The timestamp after which a new loan can be taken
   **/
  event EarlyRepay(
    bytes32 indexed poolHash,
    uint128 normalizedRepayAmount,
    uint128 repaymentFee,
    uint128 normalizedDepositsAfterRepay,
    uint128 nextLoanMinStart
  );

  /**
   * @notice Emitted after a successful repay, made after the repayment period
   * Includes a late repay fee
   * @param poolHash The identifier of the pool
   * @param normalizedRepayAmount The actual amount of tokens repaid
   * @param lateRepayFee The amount of fee paid due to a late repayment
   * @param repaymentFee The amount of fee paid to the protocol at repay time
   * @param normalizedDepositsAfterRepay The actual amount of tokens deposited and available for next loan after repay
   * @param nextLoanMinStart The timestamp after which a new loan can be taken
   **/
  event LateRepay(
    bytes32 indexed poolHash,
    uint128 normalizedRepayAmount,
    uint128 lateRepayFee,
    uint128 repaymentFee,
    uint128 normalizedDepositsAfterRepay,
    uint128 nextLoanMinStart
  );

  /**
   * @notice Emitted after a borrower successfully deposits tokens in its pool liquidity rewards reserve
   * @param poolHash The identifier of the pool
   * @param normalizedAmount The actual amount of tokens deposited into the reserve
   **/
  event TopUpLiquidityRewards(bytes32 poolHash, uint128 normalizedAmount);

  // The below events and enums are being used in the PoolLogic library
  // The same way that libraries don't have storage, they don't have an event log
  // Hence event logs will be saved in the calling contract
  // For the contract abi to reflect this and be used by offchain libraries,
  // we define these events and enums in the contract itself as well

  /**
   * @notice Emitted when a tick is initialized, i.e. when its first deposited in
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param atlendisLiquidityRatio The tick current liquidity index
   **/
  event TickInitialized(bytes32 poolHash, uint128 rate, uint128 atlendisLiquidityRatio);

  /**
   * @notice Emitted after a deposit on a tick that was done during a loan
   * @param poolHash The identifier of the pool
   * @param rate The position bidding rate
   * @param adjustedPendingDeposit The amount of tokens deposited during a loan, adjusted to the current liquidity index
   **/
  event TickLoanDeposit(bytes32 poolHash, uint128 rate, uint128 adjustedPendingDeposit);

  /**
   * @notice Emitted after a deposit on a tick that was done without an active loan
   * @param poolHash The identifier of the pool
   * @param rate The position bidding rate
   * @param adjustedAvailableDeposit The amount of tokens available to the borrower for its next loan
   * @param atlendisLiquidityRatio The tick current liquidity index
   **/
  event TickNoLoanDeposit(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAvailableDeposit,
    uint128 atlendisLiquidityRatio
  );

  /**
   * @notice Emitted when a borrow successfully impacts a tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedRemainingAmountReduction The amount of tokens left to borrow from other ticks
   * @param loanedAmount The amount borrowed from the tick
   * @param atlendisLiquidityRatio The tick current liquidity index
   * @param unborrowedRatio Proportion of ticks funds that were not borrowed
   **/
  event TickBorrow(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedRemainingAmountReduction,
    uint128 loanedAmount,
    uint128 atlendisLiquidityRatio,
    uint128 unborrowedRatio
  );

  /**
   * @notice Emitted when a withdraw is done outside of a loan on the tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedAmountToWithdraw The amount of tokens to withdraw, adjusted to the tick liquidity index
   **/
  event TickWithdrawPending(bytes32 poolHash, uint128 rate, uint128 adjustedAmountToWithdraw);

  /**
   * @notice Emitted when a withdraw is done during a loan on the tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedAmountToWithdraw The amount of tokens to withdraw, adjusted to the tick liquidity index
   * @param atlendisLiquidityRatio The tick current liquidity index
   * @param accruedFeesToWithdraw The amount of fees the position has a right to claim
   **/
  event TickWithdrawRemaining(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 atlendisLiquidityRatio,
    uint128 accruedFeesToWithdraw
  );

  /**
   * @notice Emitted when pending amounts are merged with the rest of the pool during a repay
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedPendingAmount The amount of pending funds deposited with available funds
   **/
  event TickPendingDeposit(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedPendingAmount,
    bool poolBondIssuanceIndexIncremented
  );

  /**
   * @notice Emitted when funds from a tick are repaid by the borrower
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedRemainingAmount The total amount of tokens available to the borrower for
   * its next loan, adjusted to the tick current liquidity index
   * @param atlendisLiquidityRatio The tick current liquidity index
   **/
  event TickRepay(bytes32 poolHash, uint128 rate, uint128 adjustedRemainingAmount, uint128 atlendisLiquidityRatio);

  /**
   * @notice Emitted when liquidity rewards are distributed to a tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param remainingLiquidityRewards the amount of liquidityRewards added to the tick
   * @param addedAccruedFees Increase in accrued fees for that tick
   **/
  event CollectFeesForTick(bytes32 poolHash, uint128 rate, uint128 remainingLiquidityRewards, uint128 addedAccruedFees);

  // VIEW METHODS

  /**
   * @notice Returns the liquidity ratio of a given tick in a pool's order book.
   * The liquidity ratio is an accounting construct to deduce the accrued interest over time.
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to extract the liquidity ratio
   * @return liquidityRatio The liquidity ratio of the given tick
   **/
  function getTickLiquidityRatio(bytes32 poolHash, uint128 rate) external view returns (uint128 liquidityRatio);

  /**
   * @notice Returns the repartition between bonds and deposits of the given tick.
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to get data
   * @return adjustedTotalAmount Total amount of deposit in the tick
   * @return adjustedRemainingAmount Amount of tokens in tick deposited with the
   * underlying yield provider that were deposited before bond issuance
   * @return bondsQuantity The quantity of bonds within the tick
   * @return adjustedPendingAmount Amount of deposit in tick deposited with the
   * underlying yield provider that were deposited after bond issuance
   * @return atlendisLiquidityRatio The liquidity ratio of the given tick
   * @return accruedFees The total fees claimable in the current tick, either from
   * yield provider interests or liquidity rewards accrual
   **/
  function getTickAmounts(bytes32 poolHash, uint128 rate)
    external
    view
    returns (
      uint128 adjustedTotalAmount,
      uint128 adjustedRemainingAmount,
      uint128 bondsQuantity,
      uint128 adjustedPendingAmount,
      uint128 atlendisLiquidityRatio,
      uint128 accruedFees
    );

  /**
   * @notice Returns the timestamp of the last fee distribution to the tick
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to get data
   * @return lastFeeDistributionTimestamp Timestamp of the last fee's distribution to the tick
   **/
  function getTickLastUpdate(string calldata poolHash, uint128 rate)
    external
    view
    returns (uint128 lastFeeDistributionTimestamp);

  /**
   * @notice Returns the current state of the pool's parameters
   * @param poolHash The identifier of the pool
   * @return weightedAverageLendingRate The average deposit bidding rate in the order book
   * @return adjustedPendingDeposits Amount of tokens deposited after bond
   * issuance and currently on third party yield provider
   **/
  function getPoolAggregates(bytes32 poolHash)
    external
    view
    returns (uint128 weightedAverageLendingRate, uint128 adjustedPendingDeposits);

  /**
   * @notice Returns the current maturity of the pool
   * @param poolHash The identifier of the pool
   * @return poolCurrentMaturity The pool's current maturity
   **/
  function getPoolMaturity(bytes32 poolHash) external view returns (uint128 poolCurrentMaturity);

  /**
   * @notice Estimates the lending rate corresponding to the input amount,
   * depending on the current state of the pool
   * @param normalizedBorrowedAmount The amount to be borrowed from the pool
   * @param poolHash The identifier of the pool
   * @return estimatedRate The estimated loan rate for the current state of the pool
   **/
  function estimateLoanRate(uint128 normalizedBorrowedAmount, bytes32 poolHash)
    external
    view
    returns (uint128 estimatedRate);

  /**
   * @notice Returns the token amount's repartition between bond quantity and normalized
   * deposited amount currently placed on third party yield provider
   * @param poolHash The identifier of the pool
   * @param rate Tick's rate
   * @param adjustedAmount Adjusted amount of tokens currently on third party yield provider
   * @param bondsIssuanceIndex The identifier of the borrow group
   * @return bondsQuantity Quantity of bonds held
   * @return normalizedDepositedAmount Amount of deposit currently on third party yield provider
   **/
  function getAmountRepartition(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  ) external view returns (uint128 bondsQuantity, uint128 normalizedDepositedAmount);

  /**
   * @notice Returns the total amount a borrower has to repay to a pool. Includes borrowed
   * amount, late repay fees and protocol fees
   * @param poolHash The identifier of the pool
   * @param earlyRepay indicates if this is an early repay
   * @return normalizedRepayAmount Total repay amount
   * @return lateRepayFee Normalized amount to be paid to each bond in case of late repayment
   * @return repaymentFee Normalized fee amount paid to the protocol
   **/
  function getRepayAmounts(bytes32 poolHash, bool earlyRepay)
    external
    view
    returns (
      uint128 normalizedRepayAmount,
      uint128 lateRepayFee,
      uint128 repaymentFee
    );

  // LENDER METHODS

  /**
   * @notice Gets called within the Position.deposit() function and enables a lender to deposit assets
   * into a given borrower's order book. The lender specifies a rate (price) at which it is willing to
   * lend out its assets (bid on the zero coupon bond). The full amount will initially be deposited
   * on the underlying yield provider until the borrower sells bonds at the specified rate.
   * @param normalizedAmount The amount of the given asset to deposit
   * @param rate The rate at which to bid for a bond
   * @param poolHash The identifier of the pool
   * @param underlyingToken Contract' address of the token to be deposited
   * @param sender The lender address who calls the deposit function on the Position
   * @return adjustedAmount Deposited amount adjusted with current liquidity index
   * @return bondsIssuanceIndex The identifier of the borrow group to which the deposit has been allocated
   **/
  function deposit(
    uint128 rate,
    bytes32 poolHash,
    address underlyingToken,
    address sender,
    uint128 normalizedAmount
  ) external returns (uint128 adjustedAmount, uint128 bondsIssuanceIndex);

  /**
   * @notice Gets called within the Position.withdraw() function and enables a lender to
   * evaluate the exact amount of tokens it is allowed to withdraw
   * @dev This method is meant to be used exclusively with the withdraw() method
   * Under certain circumstances, this method can return incorrect values, that would otherwise
   * be rejected by the checks made in the withdraw() method
   * @param poolHash The identifier of the pool
   * @param rate The rate the position is bidding for
   * @param adjustedAmount The amount of tokens in the position, adjusted to the deposit liquidity ratio
   * @param bondsIssuanceIndex An index determining deposit timing
   * @return adjustedAmountToWithdraw The amount of tokens to withdraw, adjuste for borrow pool use
   * @return depositedAmountToWithdraw The amount of tokens to withdraw, adjuste for position use
   * @return remainingBondsQuantity The quantity of bonds remaining within the position
   * @return bondsMaturity The maturity of bonds remaining within the position after withdraw
   **/
  function getWithdrawAmounts(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  )
    external
    view
    returns (
      uint128 adjustedAmountToWithdraw,
      uint128 depositedAmountToWithdraw,
      uint128 remainingBondsQuantity,
      uint128 bondsMaturity
    );

  /**
   * @notice Gets called within the Position.withdraw() function and enables a lender to
   * withdraw assets that are deposited with the underlying yield provider
   * @param poolHash The identifier of the pool
   * @param rate The rate the position is bidding for
   * @param adjustedAmountToWithdraw The actual amount of tokens to withdraw from the position
   * @param bondsIssuanceIndex An index determining deposit timing
   * @param owner The address to which the withdrawns funds are sent
   * @return normalizedDepositedAmountToWithdraw Actual amount of tokens withdrawn and sent to the lender
   **/
  function withdraw(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 bondsIssuanceIndex,
    address owner
  ) external returns (uint128 normalizedDepositedAmountToWithdraw);

  /**
   * @notice Gets called within Position.updateRate() and updates the order book ticks affected by the position
   * updating its rate. This is only possible as long as there are no bonds in the position, i.e the full
   * position currently lies with the yield provider
   * @param adjustedAmount The adjusted balance of tokens of the given position
   * @param poolHash The identifier of the pool
   * @param oldRate The current rate of the position
   * @param newRate The new rate of the position
   * @param oldBondsIssuanceIndex The identifier of the borrow group from the given position
   * @return newAdjustedAmount The updated amount of tokens of the position adjusted by the
   * new tick's global liquidity ratio
   * @return newBondsIssuanceIndex The new borrow group id to which the updated position is linked
   **/
  function updateRate(
    uint128 adjustedAmount,
    bytes32 poolHash,
    uint128 oldRate,
    uint128 newRate,
    uint128 oldBondsIssuanceIndex
  )
    external
    returns (
      uint128 newAdjustedAmount,
      uint128 newBondsIssuanceIndex,
      uint128 normalizedAmount
    );

  // BORROWER METHODS

  /**
   * @notice Called by the borrower to sell bonds to the order book.
   * The affected ticks get updated according the amount of bonds sold.
   * @param to The address to which the borrowed funds should be sent.
   * @param loanAmount The total amount of the loan
   **/
  function borrow(address to, uint128 loanAmount) external;

  /**
   * @notice Repays a currently outstanding bonds of the given borrower.
   **/
  function repay() external;

  /**
   * @notice Called by the borrower to top up liquidity rewards' reserve that
   * is distributed to liquidity providers at the pre-defined distribution rate.
   * @param normalizedAmount Amount of tokens  that will be add up to the borrower's liquidity rewards reserve
   **/
  function topUpLiquidityRewards(uint128 normalizedAmount) external;

  // FEE COLLECTION

  /**
   * @notice Collect yield provider fees as well as liquidity rewards for the target tick
   * @param poolHash The identifier of the pool
   **/
  function collectFeesForTick(bytes32 poolHash, uint128 rate) external;

  /**
   * @notice Collect yield provider fees as well as liquidity rewards for the whole pool
   * Iterates over all pool initialized ticks
   * @param poolHash The identifier of the pool
   **/
  function collectFees(bytes32 poolHash) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../lib/Types.sol";

/**
 * @title IPoolsController
 * @notice Management of the pools
 **/
interface IPoolsController {
  // EVENTS

  /**
   * @notice Emitted after a pool was creted
   **/
  event PoolCreated(PoolCreationParams params);

  /**
   * @notice Emitted after a borrower address was allowed to borrow from a pool
   * @param borrowerAddress The address to allow
   * @param poolHash The identifier of the pool
   **/
  event BorrowerAllowed(address borrowerAddress, bytes32 poolHash);

  /**
   * @notice Emitted after a borrower address was disallowed to borrow from a pool
   * @param borrowerAddress The address to disallow
   * @param poolHash The identifier of the pool
   **/
  event BorrowerDisallowed(address borrowerAddress, bytes32 poolHash);

  /**
   * @notice Emitted when a pool is active, i.e. after the borrower deposits enough tokens
   * in its pool liquidity rewards reserve as agreed before the pool creation
   * @param poolHash The identifier of the pool
   **/
  event PoolActivated(bytes32 poolHash);

  /**
   * @notice Emitted after pool is closed
   * @param poolHash The identifier of the pool
   * @param collectedLiquidityRewards The amount of liquidity rewards to have been collected at closing time
   **/
  event PoolClosed(bytes32 poolHash, uint128 collectedLiquidityRewards);

  /**
   * @notice Emitted when a pool defaults on its loan repayment
   * @param poolHash The identifier of the pool
   * @param distributedLiquidityRewards The remaining liquidity rewards distributed to
   * bond holders
   **/
  event Default(bytes32 poolHash, uint128 distributedLiquidityRewards);

  /**
   * @notice Emitted after governance sets the maximum borrowable amount for a pool
   **/
  event SetMaxBorrowableAmount(uint128 maxTokenDeposit, bytes32 poolHash);

  /**
   * @notice Emitted after governance sets the liquidity rewards distribution rate for a pool
   **/
  event SetLiquidityRewardsDistributionRate(uint128 distributionRate, bytes32 poolHash);

  /**
   * @notice Emitted after governance sets the establishment fee for a pool
   **/
  event SetEstablishmentFeeRate(uint128 establishmentRate, bytes32 poolHash);

  /**
   * @notice Emitted after governance sets the repayment fee for a pool
   **/
  event SetRepaymentFeeRate(uint128 repaymentFeeRate, bytes32 poolHash);

  /**
   * @notice Emitted after governance claims the fees associated with a pool
   * @param poolHash The identifier of the pool
   * @param normalizedAmount The amount of tokens claimed
   * @param to The address receiving the fees
   **/
  event ClaimProtocolFees(bytes32 poolHash, uint128 normalizedAmount, address to);

  // VIEW METHODS

  /**
   * @notice Returns the parameters of a pool
   * @param poolHash The identifier of the pool
   * @return underlyingToken Address of the underlying token of the pool
   * @return minRate Minimum rate of deposits accepted in the pool
   * @return maxRate Maximum rate of deposits accepted in the pool
   * @return rateSpacing Difference between two rates in the pool
   * @return maxBorrowableAmount Maximum amount of tokens that can be borrowed from the pool
   * @return loanDuration Duration of a loan in the pool
   * @return liquidityRewardsDistributionRate Rate at which liquidity rewards are distributed to lenders
   * @return cooldownPeriod Period after a loan during which a borrower cannot take another loan
   * @return repaymentPeriod Period after a loan end during which a borrower can repay without penalty
   * @return lateRepayFeePerBondRate Penalty a borrower has to pay when it repays late
   * @return liquidityRewardsActivationThreshold Minimum amount of liqudity rewards a borrower has to
   * deposit to active the pool
   **/
  function getPoolParameters(bytes32 poolHash)
    external
    view
    returns (
      address underlyingToken,
      uint128 minRate,
      uint128 maxRate,
      uint128 rateSpacing,
      uint128 maxBorrowableAmount,
      uint128 loanDuration,
      uint128 liquidityRewardsDistributionRate,
      uint128 cooldownPeriod,
      uint128 repaymentPeriod,
      uint128 lateRepayFeePerBondRate,
      uint128 liquidityRewardsActivationThreshold
    );

  /**
   * @notice Returns the fee rates of a pool
   * @return establishmentFeeRate Amount of fees paid to the protocol at borrow time
   * @return repaymentFeeRate Amount of fees paid to the protocol at repay time
   **/
  function getPoolFeeRates(bytes32 poolHash)
    external
    view
    returns (uint128 establishmentFeeRate, uint128 repaymentFeeRate);

  /**
   * @notice Returns the state of a pool
   * @param poolHash The identifier of the pool
   * @return active Signals if a pool is active and ready to accept deposits
   * @return defaulted Signals if a pool was defaulted
   * @return closed Signals if a pool was closed
   * @return currentMaturity End timestamp of current loan
   * @return bondsIssuedQuantity Amount of bonds issued, to be repaid at maturity
   * @return normalizedBorrowedAmount Actual amount of tokens that were borrowed
   * @return normalizedAvailableDeposits Actual amount of tokens available to be borrowed
   * @return lowerInterestRate Minimum rate at which a deposit was made
   * @return nextLoanMinStart Cool down period, minimum timestamp after which a new loan can be taken
   * @return remainingAdjustedLiquidityRewardsReserve Remaining liquidity rewards to be distributed to lenders
   * @return yieldProviderLiquidityRatio Last recorded yield provider liquidity ratio
   * @return currentBondsIssuanceIndex Current borrow period identifier of the pool
   **/
  function getPoolState(bytes32 poolHash)
    external
    view
    returns (
      bool active,
      bool defaulted,
      bool closed,
      uint128 currentMaturity,
      uint128 bondsIssuedQuantity,
      uint128 normalizedBorrowedAmount,
      uint128 normalizedAvailableDeposits,
      uint128 lowerInterestRate,
      uint128 nextLoanMinStart,
      uint128 remainingAdjustedLiquidityRewardsReserve,
      uint128 yieldProviderLiquidityRatio,
      uint128 currentBondsIssuanceIndex
    );

  /**
   * @notice Signals whether the early repay feature is activated or not
   * @return earlyRepay Flag that signifies whether the early repay feature is activated or not
   **/
  function isEarlyRepay(bytes32 poolHash) external view returns (bool earlyRepay);

  /**
   * @notice Returns the state of a pool
   * @return defaultTimestamp The timestamp at which the pool was defaulted
   **/
  function getDefaultTimestamp(bytes32 poolHash) external view returns (uint128 defaultTimestamp);

  // GOVERNANCE METHODS

  /**
   * @notice Parameters used for a pool creation
   * @param poolHash The identifier of the pool
   * @param underlyingToken Address of the pool underlying token
   * @param yieldProvider Yield provider of the pool
   * @param minRate Minimum bidding rate for the pool
   * @param maxRate Maximum bidding rate for the pool
   * @param rateSpacing Difference between two tick rates in the pool
   * @param maxBorrowableAmount Maximum amount of tokens a borrower can get from a pool
   * @param loanDuration Duration of a loan i.e. maturity of the issued bonds
   * @param distributionRate Rate at which the liquidity rewards are distributed to unmatched positions
   * @param cooldownPeriod Period of time after a repay during which the borrow cannot take a loan
   * @param repaymentPeriod Period after the end of a loan during which the borrower can repay without penalty
   * @param lateRepayFeePerBondRate Additional fees applied when a borrower repays its loan after the repayment period ends
   * @param establishmentFeeRate Fees paid to Atlendis at borrow time
   * @param repaymentFeeRate Fees paid to Atlendis at repay time
   * @param liquidityRewardsActivationThreshold Amount of tokens the borrower has to lock into the liquidity
   * @param earlyRepay Is early repay activated
   * rewards reserve to activate the pool
   **/
  struct PoolCreationParams {
    bytes32 poolHash;
    address underlyingToken;
    ILendingPool yieldProvider;
    uint128 minRate;
    uint128 maxRate;
    uint128 rateSpacing;
    uint128 maxBorrowableAmount;
    uint128 loanDuration;
    uint128 distributionRate;
    uint128 cooldownPeriod;
    uint128 repaymentPeriod;
    uint128 lateRepayFeePerBondRate;
    uint128 establishmentFeeRate;
    uint128 repaymentFeeRate;
    uint128 liquidityRewardsActivationThreshold;
    bool earlyRepay;
  }

  /**
   * @notice Creates a new pool
   * @param params A struct defining the pool creation parameters
   **/
  function createNewPool(PoolCreationParams calldata params) external;

  /**
   * @notice Allow an address to interact with a borrower pool
   * @param borrowerAddress The address to allow
   * @param poolHash The identifier of the pool
   **/
  function allow(address borrowerAddress, bytes32 poolHash) external;

  /**
   * @notice Remove pool interaction rights from an address
   * @param borrowerAddress The address to disallow
   * @param poolHash The identifier of the borrower pool
   **/
  function disallow(address borrowerAddress, bytes32 poolHash) external;

  /**
   * @notice Flags the pool as closed
   * @param poolHash The identifier of the pool to be closed
   * @param to An address to which the remaining liquidity rewards will be sent
   **/
  function closePool(bytes32 poolHash, address to) external;

  /**
   * @notice Flags the pool as defaulted
   * @param poolHash The identifier of the pool to default
   **/
  function setDefault(bytes32 poolHash) external;

  /**
   * @notice Set the maximum amount of tokens that can be borrowed in the target pool
   **/
  function setMaxBorrowableAmount(uint128 maxTokenDeposit, bytes32 poolHash) external;

  /**
   * @notice Set the pool liquidity rewards distribution rate
   **/
  function setLiquidityRewardsDistributionRate(uint128 distributionRate, bytes32 poolHash) external;

  /**
   * @notice Set the pool establishment protocol fee rate
   **/
  function setEstablishmentFeeRate(uint128 establishmentFeeRate, bytes32 poolHash) external;

  /**
   * @notice Set the pool repayment protocol fee rate
   **/
  function setRepaymentFeeRate(uint128 repaymentFeeRate, bytes32 poolHash) external;

  /**
   * @notice Withdraws protocol fees to a target address
   * @param poolHash The identifier of the pool
   * @param normalizedAmount The amount of tokens claimed
   * @param to The address receiving the fees
   **/
  function claimProtocolFees(
    bytes32 poolHash,
    uint128 normalizedAmount,
    address to
  ) external;

  /**
   * @notice Stops all actions on all pools
   **/
  function freezePool() external;

  /**
   * @notice Cancel a freeze, makes actions available again on all pools
   **/
  function unfreezePool() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IPositionManager.sol";

/**
 * @title IPositionDescriptor
 * @notice Generates the SVG artwork for lenders positions
 **/
interface IPositionDescriptor {
  /**
   * @notice Emitted after the string identifier of a pool has been set
   * @param poolIdentifier The string identifier of the pool
   * @param poolHash The hash identifier of the pool
   **/
  event SetPoolIdentifier(string poolIdentifier, bytes32 poolHash);

  /**
   * @notice Get the pool identifier corresponding to the input pool hash
   * @param poolHash The identifier of the pool
   **/
  function getPoolIdentifier(bytes32 poolHash) external view returns (string memory);

  /**
   * @notice Set the pool string identifier corresponding to the input pool hash
   * @param poolIdentifier The string identifier to associate with the corresponding pool hash
   * @param poolHash The identifier of the pool
   **/
  function setPoolIdentifier(string calldata poolIdentifier, bytes32 poolHash) external;

  /**
   * @notice Returns the encoded svg for positions artwork
   * @param position The address of the position manager contract
   * @param tokenId The tokenId of the position
   **/
  function tokenURI(IPositionManager position, uint128 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IBorrowerPools.sol";

/**
 * @title IPositionManager
 * @notice Contains methods that can be called by lenders to create and manage their position
 **/
interface IPositionManager {
  /**
   * @notice Emitted when #deposit is called and is a success
   * @param lender The address of the lender depositing token on the protocol
   * @param tokenId The tokenId of the position
   * @param amount The amount of deposited token
   * @param rate The position bidding rate
   * @param poolHash The identifier of the pool
   * @param bondsIssuanceIndex The borrow period assigned to the position
   **/
  event Deposit(
    address indexed lender,
    uint128 tokenId,
    uint128 amount,
    uint128 rate,
    bytes32 poolHash,
    uint128 bondsIssuanceIndex
  );

  /**
   * @notice Emitted when #updateRate is called and is a success
   * @param lender The address of the lender updating their position
   * @param tokenId The tokenId of the position
   * @param amount The amount of deposited token plus their accrued interests
   * @param rate The new rate required by lender to lend their deposited token
   * @param poolHash The identifier of the pool
   **/
  event UpdateRate(address indexed lender, uint128 tokenId, uint128 amount, uint128 rate, bytes32 poolHash);

  /**
   * @notice Emitted when #withdraw is called and is a success
   * @param lender The address of the withdrawing lender
   * @param tokenId The tokenId of the position
   * @param amount The amount of tokens withdrawn
   * @param rate The position bidding rate
   * @param poolHash The identifier of the pool
   **/
  event Withdraw(
    address indexed lender,
    uint128 tokenId,
    uint128 amount,
    uint128 remainingBonds,
    uint128 rate,
    bytes32 poolHash
  );

  /**
   * @notice Emitted when #withdraw is called and is a success
   * @param tokenId The tokenId of the position
   * @return poolHash The identifier of the pool
   * @return adjustedBalance Adjusted balance of the position original deposit
   * @return rate Position bidding rate
   * @return underlyingToken Address of the tokens the position contains
   * @return remainingBonds Quantity of bonds remaining in the position after a partial withdraw
   * @return bondsMaturity Maturity of the position's remaining bonds
   * @return bondsIssuanceIndex Borrow period the deposit was made in
   **/
  function position(uint128 tokenId)
    external
    view
    returns (
      bytes32 poolHash,
      uint128 adjustedBalance,
      uint128 rate,
      address underlyingToken,
      uint128 remainingBonds,
      uint128 bondsMaturity,
      uint128 bondsIssuanceIndex
    );

  /**
   * @notice Returns the balance on yield provider and the quantity of bond held
   * @param tokenId The tokenId of the position
   * @return bondsQuantity Quantity of bond held, represents funds borrowed
   * @return normalizedDepositedAmount Amount of deposit placed on yield provider
   **/
  function getPositionRepartition(uint128 tokenId)
    external
    view
    returns (uint128 bondsQuantity, uint128 normalizedDepositedAmount);

  /**
   * @notice Deposits tokens into the yield provider and places a bid at the indicated rate within the
   * respective borrower's order book. A new position is created within the positions map that keeps
   * track of this position's composition. An ERC721 NFT is minted for the user as a representation
   * of the position.
   * @param to The address for which the position is created
   * @param amount The amount of tokens to be deposited
   * @param rate The rate at which to bid for a bonds
   * @param poolHash The identifier of the pool
   * @param underlyingToken The contract address of the token to be deposited
   **/
  function deposit(
    address to,
    uint128 amount,
    uint128 rate,
    bytes32 poolHash,
    address underlyingToken
  ) external returns (uint128 tokenId);

  /**
   * @notice Allows a user to update the rate at which to bid for bonds. A rate is only
   * upgradable as long as the full amount of deposits are currently allocated with the
   * yield provider i.e the position does not hold any bonds.
   * @param tokenId The tokenId of the position
   * @param newRate The new rate at which to bid for bonds
   **/
  function updateRate(uint128 tokenId, uint128 newRate) external;

  /**
   * @notice Withdraws the amount of tokens that are deposited with the yield provider.
   * The bonds portion of the position is not affected.
   * @param tokenId The tokenId of the position
   **/
  function withdraw(uint128 tokenId) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

library Errors {
  // *** Contract Specific Errors ***
  // BorrowerPools
  error BP_BORROW_MAX_BORROWABLE_AMOUNT_EXCEEDED(); // "Amount borrowed is too big, exceeding borrowable capacity";
  error BP_REPAY_NO_ACTIVE_LOAN(); // "No active loan to be repaid, action cannot be performed";
  error BP_BORROW_UNSUFFICIENT_BORROWABLE_AMOUNT_WITHIN_BRACKETS(); // "Amount provided is greater than available amount within min rate and max rate brackets";
  error BP_REPAY_AT_MATURITY_ONLY(); // "Maturity has not been reached yet, action cannot be performed";
  error BP_BORROW_COOLDOWN_PERIOD_NOT_OVER(); // "Cooldown period after a repayment is not over";
  error BP_MULTIPLE_BORROW_AFTER_MATURITY(); // "Cannot borrow again from pool after loan maturity";
  error BP_POOL_NOT_ACTIVE(); // "Pool not active"
  error BP_POOL_DEFAULTED(); // "Pool defaulted"
  error BP_LOAN_ONGOING(); // "There's a loan ongoing, cannot update rate"
  error BP_BORROW_OUT_OF_BOUND_AMOUNT(); // "Amount provided is greater than available amount, action cannot be performed";
  error BP_POOL_CLOSED(); // "Pool closed";
  error BP_OUT_OF_BOUND_MIN_RATE(); // "Rate provided is lower than minimum rate of the pool";
  error BP_OUT_OF_BOUND_MAX_RATE(); // "Rate provided is greater than maximum rate of the pool";
  error BP_UNMATCHED_TOKEN(); // "Token/Asset provided does not match the underlying token of the pool";
  error BP_RATE_SPACING(); // "Decimals of rate provided do not comply with rate spacing of the pool";
  error BP_BOND_ISSUANCE_ID_TOO_HIGH(); // "Bond issuance id is too high";
  error BP_NO_DEPOSIT_TO_WITHDRAW(); // "Deposited amount non-borrowed equals to zero";
  error BP_TARGET_BOND_ISSUANCE_INDEX_EMPTY(); // "Target bond issuance index has no amount to withdraw";
  error BP_EARLY_REPAY_NOT_ACTIVATED(); // "The early repay feature is not activated for this pool";

  // PoolController
  error PC_POOL_NOT_ACTIVE(); // "Pool not active"
  error PC_POOL_DEFAULTED(); // "Pool defaulted"
  error PC_POOL_ALREADY_SET_FOR_BORROWER(); // "Targeted borrower is already set for another pool";
  error PC_POOL_TOKEN_NOT_SUPPORTED(); // "Underlying token is not supported by the yield provider";
  error PC_DISALLOW_UNMATCHED_BORROWER(); // "Revoking the wrong borrower as the provided borrower does not match the provided address";
  error PC_RATE_SPACING_COMPLIANCE(); // "Provided rate must be compliant with rate spacing";
  error PC_NO_ONGOING_LOAN(); // "Cannot default a pool that has no ongoing loan";
  error PC_NOT_ENOUGH_PROTOCOL_FEES(); // "Not enough registered protocol fees to withdraw";
  error PC_POOL_ALREADY_CLOSED(); // "Pool already closed";
  error PC_ZERO_POOL(); // "Cannot make actions on the zero pool";
  error PC_ZERO_ADDRESS(); // "Cannot make actions on the zero address";
  error PC_REPAYMENT_PERIOD_ONGOING(); // "Cannot default pool while repayment period in ongoing"
  error PC_ESTABLISHMENT_FEES_TOO_HIGH(); // "Cannot set establishment fee over 100% of loan amount"

  // PositionManager
  error POS_MGMT_ONLY_OWNER(); // "Only the owner of the position token can manage it (update rate, withdraw)";
  error POS_POSITION_ONLY_IN_BONDS(); // "Cannot withdraw a position that's only in bonds";
  error POS_ZERO_AMOUNT(); // "Cannot deposit zero amount";
  error POS_TIMELOCK(); // "Cannot withdraw or update rate in the same block as deposit";
  error POS_POSITION_DOES_NOT_EXIST(); // "Position does not exist";
  error POS_POOL_DEFAULTED(); // "Pool defaulted";

  // PositionDescriptor
  error POD_BAD_INPUT(); // "Input pool identifier does not correspond to input pool hash";

  //*** Library Specific Errors ***
  // WadRayMath
  error MATH_MULTIPLICATION_OVERFLOW(); // "The multiplication would result in a overflow";
  error MATH_ADDITION_OVERFLOW(); // "The addition would result in a overflow";
  error MATH_DIVISION_BY_ZERO(); // "The division would result in a divzion by zero";
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Scaling library
 * @author Atlendis
 * @dev Scale an arbitrary number to or from WAD precision
 **/
library Scaling {
  uint256 internal constant WAD = 1e18;

  /**
   * @notice Scales an input amount to wad precision
   **/
  function scaleToWad(uint128 a, uint256 precision) internal pure returns (uint128) {
    return uint128((uint256(a) * WAD) / 10**precision);
  }

  /**
   * @notice Scales an input amount from wad to target precision
   **/
  function scaleFromWad(uint128 a, uint256 precision) internal pure returns (uint128) {
    return uint128((uint256(a) * 10**precision) / WAD);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../extensions/AaveILendingPool.sol";

library Types {
  struct PositionDetails {
    uint128 adjustedBalance;
    uint128 rate;
    bytes32 poolHash;
    address underlyingToken;
    uint128 bondsIssuanceIndex;
    uint128 remainingBonds;
    uint128 bondsMaturity;
    uint128 creationTimestamp;
  }

  struct Tick {
    mapping(uint128 => uint128) bondsIssuanceIndexMultiplier;
    uint128 bondsQuantity;
    uint128 adjustedTotalAmount;
    uint128 adjustedRemainingAmount;
    uint128 adjustedWithdrawnAmount;
    uint128 adjustedPendingAmount;
    uint128 normalizedLoanedAmount;
    uint128 lastFeeDistributionTimestamp;
    uint128 atlendisLiquidityRatio;
    uint128 yieldProviderLiquidityRatio;
    uint128 accruedFees;
  }

  struct PoolParameters {
    bytes32 POOL_HASH;
    address UNDERLYING_TOKEN;
    uint8 TOKEN_DECIMALS;
    ILendingPool YIELD_PROVIDER;
    uint128 MIN_RATE;
    uint128 MAX_RATE;
    uint128 RATE_SPACING;
    uint128 MAX_BORROWABLE_AMOUNT;
    uint128 LOAN_DURATION;
    uint128 LIQUIDITY_REWARDS_DISTRIBUTION_RATE;
    uint128 COOLDOWN_PERIOD;
    uint128 REPAYMENT_PERIOD;
    uint128 LATE_REPAY_FEE_PER_BOND_RATE;
    uint128 ESTABLISHMENT_FEE_RATE;
    uint128 REPAYMENT_FEE_RATE;
    uint128 LIQUIDITY_REWARDS_ACTIVATION_THRESHOLD;
    bool EARLY_REPAY;
  }

  struct PoolState {
    bool active;
    bool defaulted;
    bool closed;
    uint128 currentMaturity;
    uint128 bondsIssuedQuantity;
    uint128 normalizedBorrowedAmount;
    uint128 normalizedAvailableDeposits;
    uint128 lowerInterestRate;
    uint128 nextLoanMinStart;
    uint128 remainingAdjustedLiquidityRewardsReserve;
    uint128 yieldProviderLiquidityRatio;
    uint128 currentBondsIssuanceIndex;
    uint128 defaultTimestamp;
  }

  struct Pool {
    PoolParameters parameters;
    PoolState state;
    mapping(uint256 => Tick) ticks;
  }
}