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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

enum PositionStatus {
    AVAILABLE,
    BORROWED,
    UNAVAILABLE
}

/**
 * @title IPositionManager
 * @author Atlendis Labs
 * @notice Interface of a Position Manager
 */
interface IPositionManager is IERC721 {
    /**
     * @notice Retrieve a position
     * @param positionId ID of the position
     * @return owner Address of the position owner
     * @return rate Value of the position rate
     * @return depositedAmount Deposited amount of the position
     * @return status Status of the position
     */
    function getPosition(uint256 positionId)
        external
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        );

    /**
     * @notice Update a position rate
     * @param positionId The ID of the position
     * @param rate The new rate of the position
     */
    function updateRate(uint256 positionId, uint256 rate) external;

    /**
     * @notice Retrieve the current maturity
     * @return maturity The current maturity
     */
    function getMaturity() external view returns (uint256 maturity);

    /**
     * @notice Retrieve the loan duration
     * @return loanDuration The loan duration
     */
    function LOAN_DURATION() external view returns (uint256 loanDuration);

    /**
     * @notice Retrieve one in the pool token precision
     * @return one One in the pool token precision
     */
    function ONE() external view returns (uint256 one);

    /**
     * @notice Retrieve the address of the custodian
     * @return custodian Address of the custodian
     */
    function CUSTODIAN() external view returns (address custodian);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {FixedPointMathLib as SolmateFixedPointMathLib} from 'lib/solmate/src/utils/FixedPointMathLib.sol';

/**
 * @title FixedPointMathLib library
 * @author Atlendis Labs
 * @dev Overlay over Solmate FixedPointMathLib
 *      Results of multiplications and divisions are always rounded down
 */
library FixedPointMathLib {
    using SolmateFixedPointMathLib for uint256;

    struct LibStorage {
        uint256 denominator;
    }

    function libStorage() internal pure returns (LibStorage storage ls) {
        bytes32 position = keccak256('diamond.standard.library.storage');
        assembly {
            ls.slot := position
        }
    }

    function setDenominator(uint256 denominator) internal {
        LibStorage storage ls = libStorage();
        ls.denominator = denominator;
    }

    function mul(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(y, libStorage().denominator);
    }

    function div(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(libStorage().denominator, y);
    }

    // TODO to be removed once denominator is set at SBI deployment
    function mul(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(y, denominator);
    }

    // TODO to be removed once denominator is set at SBI deployment
    function div(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(denominator, y);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';
import '../../interfaces/IPositionManager.sol';

/**
 * @title IRewardsManager
 * @author Atlendis Labs
 * @notice Interface of the Rewards Manager contract
 *         It allows users to stake their positions and earn rewards associated to it.
 *         When a position is staked, a NFT associated to the staked position is minted to the owner.
 *         The staked position NFT can be burn in order to unlock the original position.
 */
interface IRewardsManager is IERC721 {
    /**
     * @notice Thrown when the minimum value position is zero
     */
    error INVALID_ZERO_MIN_POSITION_VALUE();

    /**
     * @notice Thrown when the min locking duration parameter is given as 0
     */
    error INVALID_ZERO_MIN_LOCKING_DURATION();

    /**
     * @notice Thrown when the max locking duration parameter is too low with respect to the minimum duration
     * @param minLockingDuration Value of the min locking duration
     * @param receivedValue Received value for the max locking duration
     */
    error INVALID_TOO_LOW_MAX_LOCKING_DURATION(uint256 minLockingDuration, uint256 receivedValue);

    /**
     * @notice Thrown when an invalid locking duration is given
     * @param minLockingDuration Value of the min locking duration
     * @param maxLockingDuration Value of the max locking duration
     * @param receivedValue Received value for the locking duration
     */
    error INVALID_LOCKING_DURATION(uint256 minLockingDuration, uint256 maxLockingDuration, uint256 receivedValue);

    /**
     * @notice Thrown when the sender is not the expected one
     * @param actualAddress Address of the sender
     * @param expectedAddress Expected address
     */
    error UNAUTHORIZED(address actualAddress, address expectedAddress);

    /**
     * @notice Thrown when the position value is below the minimum
     * @param value Value of the position
     * @param minimumValue Minimum value required for the position
     */
    error POSITION_VALUE_TOO_LOW(uint256 value, uint256 minimumValue);

    /**
     * @notice Thrown when a module is already added
     * @param module Address of the module
     */
    error MODULE_ALREADY_ADDED(address module);

    /**
     * @notice Thrown when a position is unavailable
     */
    error POSITION_UNAVAILABLE();

    /**
     * @notice Thrown when a position is not borrowed or is borrowed but already signalled as exit
     * @param actualStatus Actual position status
     */
    error POSITION_NOT_BORROWED(PositionStatus actualStatus);

    /**
     * @notice Thrown when a term rewards is pending and unlocked after a maximum required term
     * @param actualTerm Actual term
     * @param maximumRequiredTerm Maximum required term
     */
    error TOO_LONG_TERM_PENDING(uint256 actualTerm, uint256 maximumRequiredTerm);

    /**
     * @notice Thrown when the rewards module is disabled
     */
    error DISABLED_REWARDS_MANAGER();

    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     * @param lockingDuration Locking durations related to term rewards modules
     */
    event PositionStaked(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    );

    /**
     * @notice Emitted when a staked position has been updated
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     * @param lockingDuration Locking durations related to term rewards modules
     */
    event StakeUpdated(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    );

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     */
    event RewardsClaimed(uint256 indexed positionId, address indexed owner);

    /**
     * @notice Emitted when locking duration limits have been updated
     * @param minLockingDuration Minimum locking duration allowed for term rewards
     * @param maxLockingDuration Maximum locking duration allowed for term rewards
     */
    event LockingDurationLimitsUpdated(uint256 minLockingDuration, uint256 maxLockingDuration);

    /**
     * @notice Emitted when the minimum position value has been updated
     * @param minPositionValue Minimum position value
     */
    event MinPositionValueUpdated(uint256 minPositionValue);

    /**
     * @notice Emitted when the delta exit locking duration value has been updated
     * @param deltaExitLockingDuration Delta exit locking duration
     */
    event DeltaExitLockingDurationUpdated(uint256 deltaExitLockingDuration);

    /**
     * @notice Emitted when a module is activated
     * @param module Address of the module
     * @param asContinuous True if the module has been activated as a continuous rewards module, false if it has been activated as a term rewards module
     */
    event ModuleAdded(address indexed module, bool indexed asContinuous);

    /**
     * @notice Emitted when the rewards manager is disabled
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     */
    event RewardsManagerDisabled(address unallocatedRewardsRecipient);

    /**
     * @notice Update a staked position in the contract
     * @param positionId ID of the position
     * @param lockingDuration Locking duration related to term rewards modules, a value of 0 will not update the term rewards
     *
     * Emits a {StakeUpdated} event
     */
    function updateStake(uint256 positionId, uint256 lockingDuration) external;

    /**
     * @notice Update a batch of staked positions in the contract
     * @param positionIds Array of IDs of the positions
     * @param lockingDuration Locking duration related to term rewards modules, a value of 0 will not update the term rewards
     *
     * Emits a {StakeUpdated} event for each staked position
     */
    function batchUpdateStake(uint256[] calldata positionIds, uint256 lockingDuration) external;

    /**
     * @notice Unstake a position in the contract
     *         The assiocated staked position NFT is burned
     *         The position is transferred to the owner of the staked position NFT
     * @param positionId ID of the position
     *
     * Emits a {PositionUnstaked} event
     */
    function unstake(uint256 positionId) external;

    /**
     * @notice Unstake a batch of positions in the contract
     *         The assiocated staked positions NFT are burned
     *         The positions are transferred to the owner of the staked positions NFTs
     * @param positionIds Array of IDs of the positions
     *
     * Emits a {PositionUnstaked} event for each unstaked position
     */
    function batchUnstake(uint256[] calldata positionIds) external;

    /**
     * @notice Claim the rewards earned for a staked position without burning it
     * @param positionId ID of the position
     *
     * Emits a {RewardsClaimed} event
     */
    function claimRewards(uint256 positionId) external;

    /**
     * @notice Claim the rewards earned for a batch of staked positions without burning them
     * @param positionIds Array of IDs of the positions
     *
     * Emits a {RewardsClaimed} event for each reward claimed
     */
    function batchClaimRewards(uint256[] calldata positionIds) external;

    /**
     * @notice Update the rate of the staked position
     * @param positionId The ID of the position
     * @param rate The new rate of the position
     */
    function updatePositionRate(uint256 positionId, uint256 rate) external;

    /**
     * @notice Update the locking durations limits for term rewards
     * @param minLockingDuration Value of the new allowed minimum locking duration
     * @param maxLockingDuration Value of the new allowed maximum locking duration
     *
     * Emits a {LockingDurationLimitsUpdated} event
     */
    function updateLockingDurationLimits(uint256 minLockingDuration, uint256 maxLockingDuration) external;

    /**
     * @notice Update the allowed delta locking duration for signalled exit position
     * @param deltaExitLockingDuration Value of the new delta exit locking duration
     *
     * Emits a {DeltaExitLockingDurationUpdated} event
     */
    function updateDeltaExitLockingDuration(uint256 deltaExitLockingDuration) external;

    /**
     * @notice Update the minimum position value
     * @param minPositionValue Value of the new minimum position value
     *
     * Emits a {MinPositionValueUpdated} event
     */
    function updateMinPositionValue(uint256 minPositionValue) external;

    /**
     * @notice Add a module
     * @param module Address of the module
     * @param asContinuous True if the module is a continuous rewards module, false if it is a term rewards module
     *
     * Emits a {ModuleAdded} event
     */
    function addModule(address module, bool asContinuous) external;

    /**
     * @notice Disable the rewards manager
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     *
     * Emits a {RewardsManagerDisabled} event
     */
    function disable(address unallocatedRewardsRecipient) external;

    /**
     * @notice Retrieve if a position is staked with respect to a module
     * @param positionId ID of the position
     * @return _ True if the position is staked with respect to the module, false otherwise
     */
    function isStaked(uint256 positionId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IContinuousERC20Rewards.sol';
import '../../libraries/FixedPointMathLib.sol';
import './RewardsModule.sol';

/**
 * @title ContinuousERC20Rewards
 * @author Atlendis Labs
 * @notice Implementation of the IContinuousERC20Rewards
 */
contract ContinuousERC20Rewards is IContinuousERC20Rewards, RewardsModule {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct StakedPosition {
        uint256 positionValue;
        uint256 startEarningsPerDeposit;
    }

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private constant SECONDS_PER_YEAR = 365 days;

    ERC20 public immutable TOKEN;

    uint256 public distributionRate;

    uint256 public deposits;

    uint256 public pendingRewards;
    uint256 public earningsPerDeposit;
    uint256 public lastUpdateTimestamp;

    uint256 constant RAY = 1e27;

    // position ID -> staked position liquid staking
    mapping(uint256 => StakedPosition) public stakedPositions;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev constructor
     * @param governance Address of the governance
     * @param rewardsManager Address of the rewards manager contract
     * @param token Address of the ERC20 token contract
     * @param _distributionRate Value of the rate of rewards distribution
     */
    constructor(
        address governance,
        address rewardsManager,
        address token,
        uint256 _distributionRate
    ) RewardsModule(governance, rewardsManager) {
        if (_distributionRate == 0) revert INVALID_ZERO_RATE();
        distributionRate = _distributionRate;
        TOKEN = ERC20(token);
    }

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IContinuousERC20Rewards
     */
    function updateDistributionRate(uint256 _distributionRate) public onlyOwner rewardsCollector {
        if (_distributionRate == 0) revert INVALID_ZERO_RATE();
        distributionRate = _distributionRate;

        emit DistributionRateUpdated(_distributionRate);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IContinuousRewardsModule
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];
        if (stakedPosition.positionValue == positionValue) return;

        bool isAlreadyStaked = isStaked(positionId);

        uint256 positionValueIncrease = positionValue - stakedPosition.positionValue;

        uint256 startEarningsPerDeposit = (stakedPosition.positionValue *
            stakedPosition.startEarningsPerDeposit +
            positionValueIncrease *
            earningsPerDeposit) / positionValue;

        stakedPosition.positionValue = positionValue;
        stakedPosition.startEarningsPerDeposit = startEarningsPerDeposit;
        deposits += positionValueIncrease;

        if (isAlreadyStaked) {
            emit StakeUpdated(positionId, owner, rate, positionValue, startEarningsPerDeposit);
        } else {
            emit PositionStaked(positionId, owner, rate, positionValue);
        }
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function unstake(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.positionValue.mul(
            earningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        deposits -= stakedPosition.positionValue;
        pendingRewards -= positionRewards;

        delete stakedPositions[positionId];

        TOKEN.safeTransfer(owner, positionRewards);

        emit PositionUnstaked(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function claimRewards(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.positionValue.mul(
            earningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        pendingRewards -= positionRewards;
        stakedPosition.startEarningsPerDeposit = earningsPerDeposit;

        TOKEN.safeTransfer(owner, positionRewards);

        emit RewardsClaimed(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function collectRewards() public override(IRewardsModule, RewardsModule) {
        if (disabled) return;

        if (deposits == 0) {
            lastUpdateTimestamp = block.timestamp;
            return;
        }
        uint256 maximumRewardsSinceLastUpdate = (distributionRate * (block.timestamp - lastUpdateTimestamp)) /
            SECONDS_PER_YEAR;

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        uint256 rewardsSinceLastUpdate = pendingRewards + maximumRewardsSinceLastUpdate <= contractBalance
            ? maximumRewardsSinceLastUpdate
            : contractBalance - pendingRewards;

        earningsPerDeposit += rewardsSinceLastUpdate.div(deposits, RAY);
        pendingRewards += rewardsSinceLastUpdate;
        lastUpdateTimestamp = block.timestamp;

        emit RewardsCollected(pendingRewards, earningsPerDeposit);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function isStaked(uint256 positionId) public view override returns (bool) {
        return stakedPositions[positionId].positionValue > 0;
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function getRewards(uint256 positionId) public view returns (uint256 positionRewards) {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        if (deposits == 0) return 0;

        uint256 maximumRewardsSinceLastUpdate = (distributionRate * (block.timestamp - lastUpdateTimestamp)) /
            SECONDS_PER_YEAR;

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        uint256 rewardsSinceLastUpdate = pendingRewards + maximumRewardsSinceLastUpdate <= contractBalance
            ? maximumRewardsSinceLastUpdate
            : contractBalance - pendingRewards;

        uint256 currentEarningsPerDeposit = earningsPerDeposit + rewardsSinceLastUpdate.div(deposits, RAY);

        positionRewards = stakedPosition.positionValue.mul(
            currentEarningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        return positionRewards;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the method according to RewardsModule specifications
     */
    function transferUnallocatedRewards(address unallocatedRewardsRecipient) internal override returns (uint256) {
        uint256 contractBalance = TOKEN.balanceOf(address(this));

        uint256 unallocatedRewards = contractBalance - pendingRewards;
        if (unallocatedRewards > 0) {
            TOKEN.safeTransfer(unallocatedRewardsRecipient, unallocatedRewards);
        }
        return unallocatedRewards;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IContinuousRewardsModule.sol';

/**
 * @title IContinuousERC20Rewards
 * @author Atlendis Labs
 * @notice Interface of the Continuous ERC20 Rewards module contract
 *         This module is controlled by a rewards manager.
 *         It allows to generate rewards of ERC20 tokens based on a configured rate and continuously distribute the rewards to staked positions.
 */
interface IContinuousERC20Rewards is IContinuousRewardsModule {
    /**
     * @notice Thrown when a value of zero has been given for the rate
     */
    error INVALID_ZERO_RATE();

    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     */
    event PositionStaked(uint256 indexed positionId, address indexed owner, uint256 rate, uint256 positionValue);

    /**
     * @notice Emitted when a stake has been updated
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     * @param updatedEarningsPerDeposit Updated value of the start earnings per deposit
     */
    event StakeUpdated(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 updatedEarningsPerDeposit
    );

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event RewardsClaimed(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards are colleted
     * @param pendingRewards Amount of rewards to be collected
     * @param earningsPerDeposit Value of the computed earning per deposit ratio
     */
    event RewardsCollected(uint256 pendingRewards, uint256 earningsPerDeposit);

    /**
     * @notice Emitted when the distributiona rate has been updated
     * @param distributionRate Value of the new distribution rate
     */
    event DistributionRateUpdated(uint256 distributionRate);

    /**
     * @notice Update the distribution rate
     * @param distributionRate Value of the new distribution rate
     *
     * Emits a {DistributionRateUpdated} event
     */
    function updateDistributionRate(uint256 distributionRate) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRewardsModule.sol';

/**
 * @title IContinuousRewardsModule
 * @author Atlendis Labs
 * @notice Interface of a Continuous Rewards module contract
 *         A module implementing this interface is meant to be controlled by a rewards manager.
 *         It allows to retrieve rewards and continuously distribute them to staked positions.
 *         The way to retrieve the rewards is specific for each module type.
 */
interface IContinuousRewardsModule is IRewardsModule {
    /**
     * @notice Stake or the update a stake of a position at the module level
     *         Apart from the emitted event, the method is idempotent
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the staked position
     * @param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @param positionValue Value of the underlying position
     *
     * Emits a {PositionStaked} or a {StakeUpdated} event. The params of the event varies according to the module type.
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRewardsModule
 * @author Atlendis Labs
 * @notice Interface of a Rewards module contract
 *         A module implementing this interface is meant to be controlled by a rewards manager.
 *         It allows to retrieve rewards and distribute them to staked positions.
 *         The way to retrieve the rewards is specific for each module type.
 */
interface IRewardsModule {
    /**
     * @notice Thrown when the sender is not the expected one
     * @param actualAddress Address of the sender
     * @param expectedAddress Expected address
     */
    error UNAUTHORIZED(address actualAddress, address expectedAddress);

    /**
     * @notice Thrown when the module is already disabled
     */
    error ALREADY_DISABLED();

    /**
     * @notice Emitted when the module is disabled
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     * @param unallocatedRewards Amount of unallocated rewards
     */
    event ModuleDisabled(address unallocatedRewardsRecipient, uint256 unallocatedRewards);

    /**
     * @notice Disable the module
     *         Only the Rewards Manager is able to trigger this method
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     *
     * Emits a {ModuleDisabled} event
     */
    function disable(address unallocatedRewardsRecipient) external;

    /**
     * @notice Return wheter or not the module is disabled
     * @return _ True if the module is disabled, false otherwise
     */
    function disabled() external view returns (bool);

    /**
     * @notice Forward the unstaking of a position at the module level
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the position
     * @param owner Owner of the staked position
     *
     * Emits a {PositionUnstaked} event. The params of the event varies according to the module type.
     */
    function unstake(uint256 positionId, address owner) external;

    /**
     * @notice Forward the rewards claim associated to a staked position at the module level
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the position
     * @param owner Owner of the staked position
     *
     * Emits a {RewardsClaimed} event. The params of the event varies according to the module type.
     */
    function claimRewards(uint256 positionId, address owner) external;

    /**
     * @notice Collect the rewards since last update and distribute them to staked positions
     *
     * Emits a {RewardsCollected} event. The params of the event varies according to the module type.
     */
    function collectRewards() external;

    /**
     * @notice Retrieve if a position is staked with respect to a module
     * @param positionId ID of the position
     * @return _ True if the position is staked with respect to the module, false otherwise
     */
    function isStaked(uint256 positionId) external view returns (bool);

    /**
     * @notice Retrieve the rewards associated to a staked position
     * @param positionId ID of the position
     * @return positionRewards Rewards associated to the staked position
     */
    function getRewards(uint256 positionId) external view returns (uint256 positionRewards);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRewardsModule.sol';

/**
 * @title ITermRewardsModule
 * @author Atlendis Labs
 * @notice Interface of a Term Rewards module contract
 *         A module implementing this interface is meant to be controlled by a rewards manager.
 *         It allows to retrieve rewards and distribute them to staked positions after a configured duration.
 *         The way to retrieve the rewards is specific for each module type.
 */
interface ITermRewardsModule is IRewardsModule {
    /**
     * @notice Stake or the update a stake of a position at the module level
     *         Apart from the emitted event, the method is idempotent
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the staked position
     * @param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @param positionValue Value of the underlying position
     * @param lockingDuration Duration of the locking
     *
     * Emits a {PositionStaked} or {LockRenewed} event. The params of the event varies according to the module type.
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    ) external;

    /**
     * @notice Estimate the rewards associated to a position for a locking duration
     * @param positionId ID of the staked position
     * @param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @param positionValue Value of the underlying position
     * @param lockingDuration Duration of the locking
     * @return positionRewards Rewards associated to the position and the locking duration if staked
     */
    function estimateRewards(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    ) external view returns (uint256 positionRewards);

    /**
     * @notice Retrieve the term at which the reward is unlocked
     * @param positionId ID of the staked position
     * @return term The term at whcih the reward is unlocked
     */
    function getTerm(uint256 positionId) external view returns (uint256 term);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import '../RewardsManager.sol';
import './interfaces/IRewardsModule.sol';

abstract contract RewardsModule is IRewardsModule, Ownable {
    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable REWARDS_MANAGER;

    bool public disabled;
    uint256 public disabledAt;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev constructor
     * @param governance Address of the governance
     * @param rewardsManager Address of the rewards manager contract
     */
    constructor(address governance, address rewardsManager) {
        REWARDS_MANAGER = rewardsManager;
        _transferOwnership(governance);
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict sender to Rewards Manager contract
     */
    modifier onlyRewardsManager() {
        if (msg.sender != REWARDS_MANAGER) revert UNAUTHORIZED(msg.sender, REWARDS_MANAGER);
        _;
    }

    /**
     * @dev Trigger the collection of rewards
     */
    modifier rewardsCollector() {
        collectRewards();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsModule
     */
    function disable(address unallocatedRewardsRecipient) public onlyRewardsManager rewardsCollector {
        if (disabled) revert ALREADY_DISABLED();

        disabled = true;
        disabledAt = block.timestamp;

        uint256 unallocatedRewards = transferUnallocatedRewards(unallocatedRewardsRecipient);

        emit ModuleDisabled(unallocatedRewardsRecipient, unallocatedRewards);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Transfer the unallocated rewards to a recipient
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     * @return unallocatedRewards Amount of transferred unallocated rewards
     */
    function transferUnallocatedRewards(address unallocatedRewardsRecipient)
        internal
        virtual
        returns (uint256 unallocatedRewards);

    /**
     * @inheritdoc IRewardsModule
     */
    function collectRewards() public virtual {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import './interfaces/IRewardsManager.sol';
import './modules/interfaces/IContinuousRewardsModule.sol';
import './modules/interfaces/ITermRewardsModule.sol';
import './modules/interfaces/IRewardsModule.sol';

/**
 * @title Rewards Manager
 * @author Atlendis Labs
 * @notice Implementation of the IRewardsManager
 */
abstract contract RewardsManager is IRewardsManager, ERC721, Ownable {
    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/
    IPositionManager public immutable POSITION_MANAGER;

    uint256 public minPositionValue;
    uint256 public minLockingDuration;
    uint256 public maxLockingDuration;
    uint256 public deltaExitLockingDuration;

    address[] public continuousRewardsModules;
    address[] public termRewardsModules;
    // address -> module added
    mapping(address => bool) public addedModules;

    bool public disabled;
    uint256 public disabledAt;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param governance Address of the governance
     * @param positionManager Address of the position manager contract
     * @param _minPositionValue Minimum position required value
     * @param _minLockingDuration Minimum locking duration allowed for term rewards
     * @param _maxLockingDuration Maximum locking duration allowed for term rewards
     * @param _deltaExitLockingDuration Allowed delta duration for locking for term rewards in case of signalled exit position
     * @param name ERC721 name of the staked position NFT
     * @param symbol ERC721 symbol of the staked position NFT
     */
    constructor(
        address governance,
        address positionManager,
        uint256 _minPositionValue,
        uint256 _minLockingDuration,
        uint256 _maxLockingDuration,
        uint256 _deltaExitLockingDuration,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        if (_minPositionValue == 0) revert INVALID_ZERO_MIN_POSITION_VALUE();
        validateLockingDurationLimits(_minLockingDuration, _maxLockingDuration);

        minPositionValue = _minPositionValue;
        minLockingDuration = _minLockingDuration;
        maxLockingDuration = _maxLockingDuration;
        deltaExitLockingDuration = _deltaExitLockingDuration;

        POSITION_MANAGER = IPositionManager(positionManager);

        _transferOwnership(governance);
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict actions if rewards manager is disabled
     */
    modifier onlyEnabled() {
        if (disabled) revert DISABLED_REWARDS_MANAGER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsManager
     */
    function addModule(address module, bool asContinuous) public onlyOwner onlyEnabled {
        if (addedModules[module]) revert MODULE_ALREADY_ADDED(module);

        address[] storage moduleList = asContinuous ? continuousRewardsModules : termRewardsModules;
        moduleList.push(module);
        addedModules[module] = true;

        emit ModuleAdded(module, asContinuous);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function disable(address unallocatedRewardsRecipient) public onlyOwner onlyEnabled {
        disabled = true;
        disabledAt = block.timestamp;

        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IRewardsModule module = IRewardsModule(continuousRewardsModules[i]);
            module.disable(unallocatedRewardsRecipient);
        }

        for (uint256 i = 0; i < termRewardsModules.length; i++) {
            IRewardsModule module = IRewardsModule(termRewardsModules[i]);
            module.disable(unallocatedRewardsRecipient);
        }

        emit RewardsManagerDisabled(unallocatedRewardsRecipient);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updateLockingDurationLimits(uint256 _minLockingDuration, uint256 _maxLockingDuration)
        public
        onlyOwner
        onlyEnabled
    {
        validateLockingDurationLimits(_minLockingDuration, _maxLockingDuration);

        minLockingDuration = _minLockingDuration;
        maxLockingDuration = _maxLockingDuration;

        emit LockingDurationLimitsUpdated(minLockingDuration, maxLockingDuration);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updateMinPositionValue(uint256 _minPositionValue) public onlyOwner {
        if (_minPositionValue == 0) revert INVALID_ZERO_MIN_POSITION_VALUE();

        minPositionValue = _minPositionValue;

        emit MinPositionValueUpdated(minPositionValue);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updateDeltaExitLockingDuration(uint256 _deltaExitLockingDuration) public onlyOwner {
        deltaExitLockingDuration = _deltaExitLockingDuration;

        emit DeltaExitLockingDurationUpdated(deltaExitLockingDuration);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsManager
     */
    function updateStake(uint256 positionId, uint256 lockingDuration) public onlyEnabled {
        _updateStake(positionId, lockingDuration);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function batchUpdateStake(uint256[] calldata positionIds, uint256 lockingDuration) public onlyEnabled {
        for (uint256 i; i < positionIds.length; i++) {
            _updateStake(positionIds[i], lockingDuration);
        }
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function unstake(uint256 positionId) public {
        _unstake(positionId);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function batchUnstake(uint256[] calldata positionIds) public {
        for (uint256 i; i < positionIds.length; i++) {
            _unstake(positionIds[i]);
        }
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function claimRewards(uint256 positionId) public {
        _claimRewards(positionId);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function batchClaimRewards(uint256[] calldata positionIds) public {
        for (uint256 i; i < positionIds.length; i++) {
            _claimRewards(positionIds[i]);
        }
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updatePositionRate(uint256 positionId, uint256 rate) public {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        POSITION_MANAGER.updateRate(positionId, rate);
    }

    /**
     * @dev Retrieve the list of continuous rewards module
     * @return _ The list of addresses of continuous rewards module
     */
    function getContinuousRewardsModules() public view returns (address[] memory) {
        return continuousRewardsModules;
    }

    /**
     * @dev Retrieve the list of term rewards module
     * @return _ The list of addresses of term rewards module
     */
    function getTermRewardsModules() public view returns (address[] memory) {
        return termRewardsModules;
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function isStaked(uint256 positionId) public view returns (bool) {
        return _exists(positionId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    function _stake(uint256 positionId, uint256 lockingDuration) internal {
        (address owner, uint256 rate, uint256 positionValue, PositionStatus status) = POSITION_MANAGER.getPosition(
            positionId
        );
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);
        if (positionValue < minPositionValue) revert POSITION_VALUE_TOO_LOW(positionValue, minPositionValue);
        if (status == PositionStatus.UNAVAILABLE) revert POSITION_UNAVAILABLE();

        bool withLockRewards = lockingDuration != 0;
        if (withLockRewards) validateLockingDuration(lockingDuration);

        POSITION_MANAGER.transferFrom(owner, address(this), positionId);

        propagateStakeToModules({
            positionId: positionId,
            owner: owner,
            rate: rate,
            positionValue: positionValue,
            lockingDuration: lockingDuration,
            withLockRewards: withLockRewards
        });

        _mint(owner, positionId);

        emit PositionStaked(positionId, owner, rate, positionValue, lockingDuration);
    }

    function _updateStake(uint256 positionId, uint256 lockingDuration) internal {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        (, , , PositionStatus status) = POSITION_MANAGER.getPosition(positionId);
        if (status == PositionStatus.UNAVAILABLE) revert POSITION_UNAVAILABLE();

        bool withLockRewards = lockingDuration != 0;
        if (withLockRewards) validateLockingDuration(lockingDuration);

        (, uint256 rate, uint256 positionValue, ) = POSITION_MANAGER.getPosition(positionId);

        propagateStakeToModules({
            positionId: positionId,
            owner: owner,
            rate: rate,
            positionValue: positionValue,
            lockingDuration: lockingDuration,
            withLockRewards: withLockRewards
        });

        emit StakeUpdated(positionId, owner, rate, positionValue, lockingDuration);
    }

    function _unstake(uint256 positionId) internal {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        _burn(positionId);

        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IContinuousRewardsModule(continuousRewardsModules[i]).unstake(positionId, owner);
        }
        for (uint256 i = 0; i < termRewardsModules.length; i++) {
            ITermRewardsModule(termRewardsModules[i]).unstake(positionId, owner);
        }

        POSITION_MANAGER.transferFrom(address(this), owner, positionId);

        emit PositionUnstaked(positionId, owner);
    }

    function _claimRewards(uint256 positionId) internal {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IContinuousRewardsModule(continuousRewardsModules[i]).claimRewards(positionId, owner);
        }
        for (uint256 i = 0; i < termRewardsModules.length; i++) {
            ITermRewardsModule(termRewardsModules[i]).claimRewards(positionId, owner);
        }

        emit RewardsClaimed(positionId, owner);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    function validateLockingDurationLimits(uint256 min, uint256 max) private pure {
        if (min == 0) revert INVALID_ZERO_MIN_LOCKING_DURATION();
        if (max < min) revert INVALID_TOO_LOW_MAX_LOCKING_DURATION(min, max);
    }

    function propagateStakeToModules(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration,
        bool withLockRewards
    ) private {
        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IContinuousRewardsModule(continuousRewardsModules[i]).stake(positionId, owner, rate, positionValue);
        }
        if (withLockRewards) {
            for (uint256 i = 0; i < termRewardsModules.length; i++) {
                ITermRewardsModule(termRewardsModules[i]).stake(
                    positionId,
                    owner,
                    rate,
                    positionValue,
                    lockingDuration
                );
            }
        }
    }

    function validateLockingDuration(uint256 lockingDuration) private view {
        if (lockingDuration < minLockingDuration || lockingDuration > maxLockingDuration)
            revert INVALID_LOCKING_DURATION(minLockingDuration, maxLockingDuration, lockingDuration);
    }
}