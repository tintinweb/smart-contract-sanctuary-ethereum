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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IChErc20 is IERC20 {
    function underlying() external returns (IERC20);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableSwap {
    /// EVENTS
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event TokenExchange(
        address indexed buyer,
        uint256 soldId,
        uint256 tokensSold,
        uint256 boughtId,
        uint256 tokensBought
    );

    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256[] fees, uint256 tokenSupply);

    event RemoveLiquidityOne(address indexed provider, uint256 tokenIndex, uint256 tokenAmount, uint256 coinAmount);

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    event StopRampA(uint256 A, uint256 timestamp);

    event NewFee(uint256 fee, uint256 adminFee);

    event CollectProtocolFee(address token, uint256 amount);

    event FeeControllerChanged(address newController);

    event FeeDistributorChanged(address newController);

    // pool data view functions
    function getLpToken() external view returns (IERC20 lpToken);

    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokens() external view returns (IERC20[] memory);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getTokenBalances() external view returns (uint256[] memory);

    function getVirtualPrice() external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

    function calculateAmountOut(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 amountIn
    ) external view returns (uint256);

    function calculateAmountIn(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 amountOut
    ) external view returns (uint256);

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
        external
        view
        returns (uint256 availableTokenAmount);

    function getAdminBalances() external view returns (uint256[] memory adminBalances);

    function getAdminBalance(uint8 index) external view returns (uint256);

    function numberOfTokens() external view returns (uint256);

    function useLending(uint256 index) external view returns (bool);

    // state modifying functions
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function swapToExact(
        uint8 i,
        uint8 j,
        uint256 amountOut,
        uint256 maxAmountIn,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function withdrawAdminFee() external;
}

// SPDX-License-Identifier: MIT

// solhint-disable not-rely-on-time
// solhint-disable var-name-mixedcase

pragma solidity 0.8.4;

library AmplificationUtils {
    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    event StopRampA(uint256 A, uint256 timestamp);

    uint256 public constant A_PRECISION = 100;
    uint256 public constant MIN_RAMP_TIME = 1 days;
    uint256 public constant MAX_A = 1e6; // max_a with precision
    uint256 public constant MAX_A_CHANGE = 10;

    struct Amp {
        uint256 initialA;
        uint256 initialATime;
        uint256 futureA;
        uint256 futureATime;
    }

    function getAPrecise(Amp storage self) internal view returns (uint256) {
        uint256 blockTimestamp = block.timestamp;
        if (blockTimestamp >= self.futureATime) {
            return self.futureA;
        }

        if (self.futureA > self.initialA) {
            return
                self.initialA +
                ((self.futureA - self.initialA) * (blockTimestamp - self.initialATime)) /
                (self.futureATime - self.initialATime);
        }

        return
            self.initialA -
            ((self.initialA - self.futureA) * (blockTimestamp - self.initialATime)) /
            (self.futureATime - self.initialATime);
    }

    function getA(Amp storage self) internal view returns (uint256) {
        return getAPrecise(self) / A_PRECISION;
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param futureA the new A to ramp towards
     * @param futureATime timestamp when the new A should be reached
     */
    function rampA(
        Amp storage self,
        uint256 futureA,
        uint256 futureATime
    ) internal {
        require(block.timestamp >= self.initialATime + (1 days), "< rampDelay"); // please wait 1 days before start a new ramping
        require(futureATime >= block.timestamp + (MIN_RAMP_TIME), "< minRampTime");
        require(0 < futureA && futureA < MAX_A, "outOfRange");

        uint256 initialAPrecise = getAPrecise(self);
        uint256 futureAPrecise = futureA * A_PRECISION;

        if (futureAPrecise < initialAPrecise) {
            require(futureAPrecise * (MAX_A_CHANGE) >= initialAPrecise, "> maxChange");
        } else {
            require(futureAPrecise <= initialAPrecise * (MAX_A_CHANGE), "> maxChange");
        }

        self.initialA = initialAPrecise;
        self.futureA = futureAPrecise;
        self.initialATime = block.timestamp;
        self.futureATime = futureATime;

        emit RampA(initialAPrecise, futureAPrecise, block.timestamp, futureATime);
    }

    /**
     * @notice stop ramping immediately and fix the current value
     */
    function stopRampA(Amp storage self) internal {
        require(self.futureATime > block.timestamp, "alreadyStopped");
        uint256 currentA = getAPrecise(self);

        self.initialA = currentA;
        self.futureA = currentA;
        self.initialATime = block.timestamp;
        self.futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable var-name-mixedcase
pragma solidity 0.8.4;

import "./MathUtils.sol";
import "./AmplificationUtils.sol";

/**
 * @notice Helpers for calculating invariant
 */
library InvariantUtils {
    using MathUtils for uint256;
    uint256 public constant MAX_ITERATION = 256;

    /**
     * @notice normalize balances of each tokens with corresponding multipliers
     * @param balances token amount
     * @param multipliers rate to multiplier to reach a same precision
     */
    function calcXp(uint256[] memory balances, uint256[] memory multipliers)
        internal
        pure
        returns (uint256[] memory results)
    {
        results = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            results[i] = multipliers[i] * balances[i];
        }
    }

    /**
     * @notice calculate the D invariant
     * @param balances raw token balances (with their own decimals)
     * @param multipliers the normalize rate
     * @param ampPrecise Amplification coefficient factor (with its precision)
     */
    function getD(
        uint256[] memory balances,
        uint256[] memory multipliers,
        uint256 ampPrecise
    ) internal pure returns (uint256) {
        return getD(calcXp(balances, multipliers), ampPrecise);
    }

    /**
     * Calculate D for *NORMALIZED* balances of each tokens
     * @param xp normalized balances of token
     * @param amp Amplification coefficient factor (with its precision)
     */
    function getD(uint256[] memory xp, uint256 amp) internal pure returns (uint256) {
        uint256 nCoins = xp.length;
        uint256 sum = calcSum(xp);
        if (sum == 0) {
            return 0;
        }

        uint256 Dprev = 0;
        uint256 D = sum;
        uint256 Ann = amp * nCoins;

        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            uint256 D_P = D;
            for (uint256 j = 0; j < xp.length; j++) {
                D_P = (D_P * D) / (xp[j] * nCoins);
            }
            Dprev = D;
            D =
                (((Ann * sum) / AmplificationUtils.A_PRECISION + D_P * nCoins) * D) /
                (((Ann - AmplificationUtils.A_PRECISION) * D) / AmplificationUtils.A_PRECISION + (nCoins + 1) * D_P);
            if (D.within1(Dprev)) {
                return D;
            }
        }

        // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
        // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
        // function which does not rely on D.
        revert("invariantCalculationFailed");
    }

    /**
     * @notice calculate new balance of out token Y with pre computed D
     * @param xp normalized pool tokens balance
     * @param A Amp with precise
     * @param index index of token Y
     * @param D computed invariant
     */
    function getYD(
        uint256[] memory xp,
        uint256 A,
        uint256 index,
        uint256 D
    ) internal pure returns (uint256) {
        uint256 nCoins = xp.length;
        assert(index < nCoins);
        uint256 Ann = A * nCoins;
        uint256 c = D;
        uint256 s = 0;
        uint256 _x = 0;
        uint256 yPrev = 0;

        for (uint256 i = 0; i < nCoins; i++) {
            if (i == index) {
                continue;
            }
            _x = xp[i];
            s += _x;
            c = (c * D) / (_x * nCoins);
        }

        c = (c * D * AmplificationUtils.A_PRECISION) / (Ann * nCoins);
        uint256 b = s + (D * AmplificationUtils.A_PRECISION) / Ann;
        uint256 y = D;

        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            yPrev = y;
            y = (y * y + c) / (2 * y + b - D);
            if (yPrev.within1(y)) {
                return y;
            }
        }
        revert("invariantCalculationFailed");
    }

    /**
     * @notice calculate new balance of when swap
     * Done by solving quadratic equation iteratively.
     *  x_1**2 + x_1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
     *  x_1**2 + b*x_1 = c
     *  x_1 = (x_1**2 + c) / (2*x_1 + b)
     * @param amp A with precise
     * @param inIndex index of token to swap in
     * @param outIndex index of token to swap out
     * @param inBalance new balance (normalized) of input token if the swap success
     * @return NORMALIZED balance of output token if the swap success
     */
    function getY(
        uint256[] memory normalizedBalances,
        uint256 amp,
        uint256 inIndex,
        uint256 outIndex,
        uint256 inBalance
    ) internal pure returns (uint256) {
        require(inIndex != outIndex, "sameToken");
        uint256 nCoins = normalizedBalances.length;
        require(inIndex < nCoins && outIndex < nCoins, "indexOutOfRange");

        uint256 Ann = amp * nCoins;
        uint256 D = getD(normalizedBalances, amp);

        uint256 sum = 0; // sum of new balances except output token
        uint256 c = D;
        for (uint256 i = 0; i < nCoins; i++) {
            if (i == outIndex) {
                continue;
            }

            uint256 x = i == inIndex ? inBalance : normalizedBalances[i];
            sum += x;
            c = (c * D) / (x * nCoins);
        }

        c = (c * D * AmplificationUtils.A_PRECISION) / (Ann * nCoins);
        uint256 b = sum + (D * AmplificationUtils.A_PRECISION) / Ann;

        uint256 lastY = 0;
        uint256 y = D;

        for (uint256 index = 0; index < MAX_ITERATION; index++) {
            lastY = y;
            y = (y * y + c) / (2 * y + b - D);
            if (lastY.within1(y)) {
                return y;
            }
        }

        revert("yCalculationFailed");
    }

    function calcSum(uint256[] memory xp) internal pure returns (uint256 sum) {
        sum = 0;
        for (uint256 i = 0; i < xp.length; i++) {
            sum += xp[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library MathUtils {
    function different(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x - y : y - x;
    }

    function within1(uint x, uint y) internal pure returns(bool) {
        return different(x, y) <= 1;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase
// solhint-disable not-rely-on-time
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IStableSwap.sol";
import "../interfaces/IChErc20.sol";
import "../lib/InvariantUtils.sol";
import "../lib/MathUtils.sol";
import "../lib/AmplificationUtils.sol";
import "./LPToken.sol";
import "./OwnerPausable.sol";

/**
 * modified stable swap which accept ChErc20 token from chai lending
 */
contract ChaiStableSwap is OwnerPausable, ReentrancyGuard, IStableSwap {
    using SafeERC20 for IERC20;
    using MathUtils for uint256;
    using AmplificationUtils for AmplificationUtils.Amp;
    using InvariantUtils for uint256[];

    /// constants
    uint256 private constant MAX_ADMIN_FEE = 1e10; // 100%
    uint256 private constant MAX_SWAP_FEE = 1e8; // 1%
    uint256 private constant LENDING_PRECISION = 1e18;
    uint256 private constant FEE_DENOMINATOR = 1e10;
    uint256 private constant POOL_TOKEN_COMMON_DECIMALS = 18;

    LPToken private lpToken;
    address[] private pooledTokens;
    /// @dev for fast access
    mapping(address => uint8) private tokenIndices;
    /// @dev token i multiplier to reach POOL_TOKEN_COMMON_DECIMALS
    uint256[] public baseMultipliers;
    /// @dev indicate token i is chai market or not
    bool[] public override useLending;
    /// @dev balance of each token, fee excluded
    uint256[] private balances;

    AmplificationUtils.Amp public amplification;

    uint256 public fee;
    uint256 public adminFee;
    /// @notice number of token in pool
    uint256 public override numberOfTokens;
    /// @notice only feeDistributor can withdraw admin fee
    address public feeDistributor;

    // =========== MODIFIERS ============
    modifier deadlineCheck(uint256 deadline) {
        require(block.timestamp <= deadline, ">deadline");
        _;
    }

    /// @param _coins address of tokens
    /// @param _decimals decimal of underlying token if use lending
    /// @param _useLending mark token is chai market or not
    /// @param _lpTokenName name of pool position token
    /// @param _lpTokenSymbol symbol of pool position token
    /// @param _A initial amplification coeffiency
    /// @param _fee fee
    /// @param _adminFee admin fee
    constructor(
        address[] memory _coins,
        uint8[] memory _decimals,
        bool[] memory _useLending,
        string memory _lpTokenName,
        string memory _lpTokenSymbol,
        uint256 _A,
        uint256 _fee,
        uint256 _adminFee
    ) {
        uint256 _numberOfCoins = _coins.length;
        require(
            _decimals.length == _numberOfCoins && _useLending.length == _numberOfCoins,
            "coinsLength != decimalsLength"
        );

        uint256[] memory _baseMultipliers = new uint256[](_numberOfCoins);
        for (uint256 i = 0; i < _numberOfCoins; i++) {
            require(_coins[i] != address(0), "invalidTokenAddress");
            require(_decimals[i] <= POOL_TOKEN_COMMON_DECIMALS, "invalidDecimals");
            _baseMultipliers[i] = 10**(POOL_TOKEN_COMMON_DECIMALS - _decimals[i]);
            tokenIndices[address(_coins[i])] = uint8(i);
        }

        require(_A < AmplificationUtils.MAX_A, "> maxA");
        require(_fee <= MAX_SWAP_FEE, "> maxSwapFee");
        require(_adminFee <= MAX_ADMIN_FEE, "> maxAdminFee");

        lpToken = new LPToken(_lpTokenName, _lpTokenSymbol);
        baseMultipliers = _baseMultipliers;
        balances = new uint256[](_numberOfCoins);
        useLending = _useLending;
        pooledTokens = _coins;
        amplification.initialA = _A * AmplificationUtils.A_PRECISION;
        amplification.futureA = _A * AmplificationUtils.A_PRECISION;
        fee = _fee;
        adminFee = _adminFee;
        numberOfTokens = _numberOfCoins;
    }

    // ============ VIEW FUNCTIONS ============

    function getLpToken() external view override returns (IERC20) {
        return IERC20(lpToken);
    }

    function getAPrecise() public view override returns (uint256) {
        return amplification.getAPrecise();
    }

    function getA() external view override returns (uint256) {
        return amplification.getA();
    }

    function getToken(uint8 index) external view override returns (IERC20) {
        return IERC20(pooledTokens[index]);
    }

    function getTokens() external view override returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](pooledTokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC20(pooledTokens[i]);
        }

        return tokens;
    }

    function getTokenIndex(address tokenAddress) external view override returns (uint8 index) {
        index = tokenIndices[tokenAddress];
        require(address(pooledTokens[index]) == tokenAddress, "tokenNotFound");
    }

    function getTokenBalance(uint8 index) external view override returns (uint256) {
        return balances[index];
    }

    function getTokenBalances() external view override returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](pooledTokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = balances[i];
        }

        return tokens;
    }

    function getVirtualPrice() external view override returns (uint256) {
        uint256 D = balances.getD(_exchangeRatesStored(), getAPrecise());
        uint256 totalSupply = lpToken.totalSupply();
        return (D * 10**POOL_TOKEN_COMMON_DECIMALS) / totalSupply;
    }

    /**
     * Estimate amount of LP token minted or burned at deposit or withdrawal
     * taking fees into account
     */
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        override
        returns (uint256 mintAmount)
    {
        uint256[] memory tokenMultipliers = _exchangeRatesStored();
        require(amounts.length == numberOfTokens, "invalidAmountsLength");
        uint256 amp = getAPrecise();
        uint256[] memory xp = balances.calcXp(tokenMultipliers);
        uint256 D0 = xp.getD(amp);

        uint256[] memory newBalances = balances;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (deposit) {
                newBalances[i] += amounts[i];
            } else {
                newBalances[i] -= amounts[i];
            }
        }

        xp = newBalances.calcXp(tokenMultipliers);
        uint256 D1 = xp.getD(amp);
        uint256 totalSupply = lpToken.totalSupply();

        uint256[] memory fees = new uint256[](numberOfTokens);
        if (totalSupply == 0) {
            return D1; // first depositor take it all
        }

        // calc fee
        uint256 _fee = _feePerToken();
        uint256 diff = 0;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            diff = newBalances[i].different((D1 * balances[i]) / D0);
            fees[i] = (_fee * diff) / FEE_DENOMINATOR;
            newBalances[i] -= fees[i];
        }
        D1 = newBalances.getD(tokenMultipliers, amp);

        diff = deposit ? D1 - D0 : D0 - D1;
        mintAmount = (diff * totalSupply) / D0;
    }

    function calculateAmountOut(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view override returns (uint256 outAmount) {
        (outAmount, ) = _calculateAmountOut(_exchangeRatesStored(), tokenIndexFrom, tokenIndexTo, dx);
    }

    function calculateAmountIn(
        uint8 from,
        uint8 to,
        uint256 dy
    ) external view override returns (uint256 inAmount) {
        (inAmount, ) = _calculateAmountIn(_exchangeRatesStored(), from, to, dy);
    }

    function calculateRemoveLiquidity(uint256 amount) external view override returns (uint256[] memory) {
        return _calculateRemoveLiquidity(amount);
    }

    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
        external
        view
        override
        returns (uint256 outAmount)
    {
        (outAmount, ) = _calculateRemoveLiquidityOneToken(tokenAmount, tokenIndex);
    }

    function getAdminBalance(uint8 index) public view override returns (uint256) {
        return _getAdminBalance(index);
    }

    function getAdminBalances() external view override returns (uint256[] memory adminBalances) {
        adminBalances = new uint256[](numberOfTokens);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            adminBalances[i] = _getAdminBalance(i);
        }
    }

    // ============ MUTATIVE FUNCTIONS ==========

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external override whenNotPaused nonReentrant deadlineCheck(deadline) returns (uint256 mintAmount) {
        require(amounts.length == numberOfTokens, "invalidAmountsLength");
        uint256[] memory fees = new uint256[](pooledTokens.length);
        uint256 _fee = _feePerToken();
        uint256 tokenSupply = lpToken.totalSupply();
        uint256 amp = getAPrecise();
        uint256[] memory tokenMultipliers = _exchangeRatesCurrent();

        uint256 D0 = 0;
        if (tokenSupply > 0) {
            D0 = balances.getD(tokenMultipliers, amp);
        }

        uint256[] memory newBalances = balances;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(tokenSupply != 0 || amounts[i] > 0, "initialDepositRequireAllTokens");
            // get real transfer in amount
            newBalances[i] += _doTransferIn(pooledTokens[i], amounts[i]);
        }

        uint256 D1 = newBalances.getD(tokenMultipliers, amp);
        assert(D1 > D0); // double check

        if (tokenSupply == 0) {
            balances = newBalances;
            mintAmount = D1;
        } else {
            uint256 diff = 0;
            for (uint256 i = 0; i < numberOfTokens; i++) {
                diff = newBalances[i].different((D1 * balances[i]) / D0);
                fees[i] = (_fee * diff) / FEE_DENOMINATOR;
                balances[i] = newBalances[i] - ((fees[i] * adminFee) / FEE_DENOMINATOR);
                newBalances[i] -= fees[i];
            }
            D1 = newBalances.getD(tokenMultipliers, amp);
            mintAmount = (tokenSupply * (D1 - D0)) / D0;
        }

        require(mintAmount >= minToMint, "> slippage");

        lpToken.mint(msg.sender, mintAmount);
        emit AddLiquidity(msg.sender, amounts, fees, D1, mintAmount);
    }

    function swap(
        uint8 i,
        uint8 j,
        uint256 inAmount,
        uint256 minOutAmount,
        uint256 deadline
    ) external override whenNotPaused nonReentrant deadlineCheck(deadline) returns (uint256) {
        uint256[] memory tokenMultipliers = _exchangeRatesCurrent();
        inAmount = _doTransferIn(pooledTokens[i], inAmount);
        (uint256 dy, uint256 dy_fee) = _calculateAmountOut(tokenMultipliers, i, j, inAmount);
        require(dy >= minOutAmount, "> slippage");

        uint256 _adminFee = (dy_fee * adminFee) / FEE_DENOMINATOR / tokenMultipliers[j];

        // update balances
        balances[i] += inAmount;
        balances[j] -= dy + _adminFee;

        _doTransferOut(pooledTokens[j], dy);
        emit TokenExchange(msg.sender, i, inAmount, j, dy);
        return dy;
    }

    function swapToExact(
        uint8 i,
        uint8 j,
        uint256 amountOut,
        uint256 maxAmountIn,
        uint256 deadline
    ) external override whenNotPaused nonReentrant deadlineCheck(deadline) returns (uint256) {
        uint256[] memory tokenMultipliers = _exchangeRatesCurrent();
        // inAmount = _doTransferIn(pooledTokens[i], inAmount);
        (uint256 amountIn, uint256 _fee) = _calculateAmountIn(tokenMultipliers, i, j, amountOut);
        require(amountIn <= maxAmountIn, "> slippage");

        uint256 _adminFee = (_fee * adminFee) / FEE_DENOMINATOR / tokenMultipliers[j];

        // update balances
        balances[i] += amountIn;
        balances[j] -= amountOut + _adminFee;

        _doTransferIn(pooledTokens[i], amountIn);
        _doTransferOut(pooledTokens[j], amountOut);
        emit TokenExchange(msg.sender, i, amountIn, j, amountOut);
        return amountIn;
    }

    function removeLiquidity(
        uint256 lpAmount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external override nonReentrant deadlineCheck(deadline) returns (uint256[] memory amounts) {
        uint256 totalSupply = lpToken.totalSupply();
        uint256[] memory fees = new uint256[](numberOfTokens);
        amounts = _calculateRemoveLiquidity(lpAmount);

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] >= minAmounts[i], "> slippage");
            balances[i] = balances[i] - amounts[i];
            _doTransferOut(pooledTokens[i], amounts[i]);
        }

        lpToken.burnFrom(msg.sender, lpAmount);
        emit RemoveLiquidity(msg.sender, amounts, fees, totalSupply - lpAmount);
    }

    function removeLiquidityOneToken(
        uint256 lpAmount,
        uint8 index,
        uint256 minAmount,
        uint256 deadline
    ) external override nonReentrant deadlineCheck(deadline) returns (uint256) {
        uint256 totalSupply = lpToken.totalSupply();
        require(totalSupply > 0, "totalSupply = 0");
        require(lpAmount <= totalSupply, "> totalSupply");
        require(index < numberOfTokens, "tokenNotFound");

        (uint256 dy, uint256 dyFee) = _calculateRemoveLiquidityOneToken(lpAmount, index);

        require(dy >= minAmount, "> slippage");

        balances[index] -= (dy + (dyFee * adminFee) / FEE_DENOMINATOR);
        lpToken.burnFrom(msg.sender, lpAmount);
        _doTransferOut(pooledTokens[index], dy);

        emit RemoveLiquidityOne(msg.sender, index, lpAmount, dy);
        return dy;
    }

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external override nonReentrant deadlineCheck(deadline) returns (uint256 burnAmount) {
        require(amounts.length == numberOfTokens, "invalidAmountsLength");
        uint256 totalSupply = lpToken.totalSupply();
        require(totalSupply != 0, "totalSupply = 0");
        uint256 _fee = _feePerToken();
        uint256 amp = getAPrecise();

        uint256[] memory newBalances = balances;
        uint256[] memory tokenMultipliers = _exchangeRatesCurrent();
        uint256 D0 = balances.getD(tokenMultipliers, amp);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            newBalances[i] -= amounts[i];
        }

        uint256 D1 = newBalances.getD(tokenMultipliers, amp);
        uint256[] memory fees = new uint256[](numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 idealBalance = (D1 * balances[i]) / D0;
            uint256 diff = newBalances[i].different(idealBalance);
            fees[i] = (_fee * diff) / FEE_DENOMINATOR;
            balances[i] = newBalances[i] - ((fees[i] * adminFee) / FEE_DENOMINATOR);
            newBalances[i] -= fees[i];
        }

        // recalculate invariant with fee charged balances
        D1 = newBalances.getD(tokenMultipliers, amp);
        burnAmount = ((D0 - D1) * totalSupply) / D0;
        assert(burnAmount > 0);
        require(burnAmount <= maxBurnAmount, "> slippage");

        lpToken.burnFrom(msg.sender, burnAmount);

        _doTransferOut(pooledTokens, amounts);

        emit RemoveLiquidityImbalance(msg.sender, amounts, fees, D1, totalSupply - burnAmount);
    }

    // ============= RESTRICTED FUNCIONS =============

    function withdrawAdminFee() external override {
        require(feeDistributor == msg.sender, "Only feeDistributor allowed");
        for (uint256 i = 0; i < pooledTokens.length; i++) {
            IERC20 token = IERC20(pooledTokens[i]);
            uint256 feeAmount = token.balanceOf(address(this)) - (balances[i]);
            if (feeAmount != 0) {
                token.safeTransfer(feeDistributor, feeAmount);
                emit CollectProtocolFee(address(token), feeAmount);
            }
        }
    }

    function rampA(uint256 futureA, uint256 futureATime) external onlyOwner {
        amplification.rampA(futureA, futureATime);
    }

    function stopRampA() external onlyOwner {
        amplification.stopRampA();
    }

    function setFeeDistributor(address _feeDistributor) external onlyOwner {
        require(_feeDistributor != address(0), "zeroAddress");
        feeDistributor = _feeDistributor;
        emit FeeDistributorChanged(_feeDistributor);
    }

    // ======== INTERNAL FUNCTIONS ========

    function _feePerToken() internal view returns (uint256) {
        return (fee * numberOfTokens) / (4 * (numberOfTokens - 1));
    }

    function _calculateTokenAmount(
        uint256[] calldata amounts,
        uint256[] memory tokenMultipliers,
        bool deposit
    )
        internal
        view
        returns (
            uint256 mintAmount,
            uint256[] memory newBalances,
            uint256[] memory fees,
            uint256 D1
        )
    {
        require(amounts.length == numberOfTokens, "invalidAmountsLength");
        uint256 amp = getAPrecise();
        uint256[] memory xp = balances.calcXp(tokenMultipliers);
        uint256 D0 = xp.getD(amp);

        newBalances = balances;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (deposit) {
                newBalances[i] += amounts[i];
            } else {
                newBalances[i] -= amounts[i];
            }
        }

        xp = newBalances.calcXp(tokenMultipliers);
        D1 = xp.getD(amp);
        uint256 totalSupply = lpToken.totalSupply();

        fees = new uint256[](numberOfTokens);
        if (totalSupply == 0) {
            return (D1, newBalances, fees, D1); // first depositor take it all
        }

        // calc fee
        uint256 _fee = _feePerToken();
        uint256 diff = 0;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            diff = newBalances[i].different((D1 * balances[i]) / D0);
            fees[i] = (_fee * diff) / FEE_DENOMINATOR;
            newBalances[i] -= fees[i];
        }
        D1 = newBalances.getD(tokenMultipliers, amp);

        diff = deposit ? D1 - D0 : D0 - D1;
        mintAmount = (diff * totalSupply) / D0;
    }

    function _calculateAmountOut(
        uint256[] memory tokenMultipliers,
        uint256 inIndex,
        uint256 outIndex,
        uint256 inAmount
    ) internal view returns (uint256 outAmount, uint256 _fee) {
        uint256[] memory normalizedBalances = balances.calcXp(tokenMultipliers);
        uint256 newInBalance = normalizedBalances[inIndex] + (inAmount * tokenMultipliers[inIndex]);
        uint256 outBalance = normalizedBalances.getY(getAPrecise(), inIndex, outIndex, newInBalance);
        outAmount = (normalizedBalances[outIndex] - outBalance - 1) / tokenMultipliers[outIndex];
        _fee = (fee * outAmount) / FEE_DENOMINATOR;
        outAmount = outAmount - _fee;
    }

    function _calculateAmountIn(
        uint256[] memory tokenMultipliers,
        uint256 inIndex,
        uint256 outIndex,
        uint256 outAmount
    ) internal view returns (uint256 inAmount, uint256 _fee) {
        _fee = (outAmount * fee) / (FEE_DENOMINATOR - fee);
        uint256 outAmountWithFee = (outAmount * FEE_DENOMINATOR) / (FEE_DENOMINATOR - fee);
        uint256[] memory normalizedBalances = balances.calcXp(tokenMultipliers);
        uint256 newOutBalance = normalizedBalances[outIndex] - ((outAmountWithFee + 1) * tokenMultipliers[outIndex]);
        uint256 inBalance = normalizedBalances.getY(getAPrecise(), outIndex, inIndex, newOutBalance);
        inAmount = (inBalance - normalizedBalances[inIndex]) / tokenMultipliers[inIndex];
    }

    function _calculateRemoveLiquidity(uint256 amount) internal view returns (uint256[] memory amounts) {
        uint256 totalSupply = lpToken.totalSupply();
        require(amount <= totalSupply, "Cannot exceed total supply");

        amounts = new uint256[](numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            amounts[i] = (balances[i] * (amount)) / (totalSupply);
        }
        return amounts;
    }

    function _calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint256 index)
        internal
        view
        returns (uint256 dy, uint256 _fee)
    {
        require(index < numberOfTokens, "indexOutOfRange");
        uint256 amp = getAPrecise();
        uint256[] memory tokenMultipliers = _exchangeRatesStored();
        uint256[] memory xp = balances.calcXp(tokenMultipliers);
        uint256 D0 = xp.getD(amp);
        uint256 D1 = D0 - (tokenAmount * D0) / lpToken.totalSupply();
        uint256 newY = xp.getYD(amp, index, D1);
        uint256[] memory reducedXP = xp;
        _fee = _feePerToken();

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 expectedDx = 0;
            if (i == index) {
                expectedDx = (xp[i] * D1) / D0 - newY;
            } else {
                expectedDx = xp[i] - (xp[i] * D1) / D0;
            }
            reducedXP[i] -= (_fee * expectedDx) / FEE_DENOMINATOR;
        }

        dy = reducedXP[index] - reducedXP.getYD(amp, index, D1);
        dy = (dy - 1) / tokenMultipliers[index];
        _fee = ((xp[index] - newY) / tokenMultipliers[index]) - dy;
    }

    /// @notice estimated exchange rate base on supply rate per block
    function _exchangeRatesStored() internal view returns (uint256[] memory tokenMultipliers) {
        tokenMultipliers = new uint256[](pooledTokens.length);
        for (uint256 i = 0; i < tokenMultipliers.length; i++) {
            if (useLending[i]) {
                IChErc20 market = IChErc20(pooledTokens[i]);
                uint256 rate = market.exchangeRateStored();
                uint256 recentAccured = market.accrualBlockNumber();
                uint256 ratePerBlock = market.supplyRatePerBlock();
                rate += ratePerBlock * (block.number - recentAccured);
                tokenMultipliers[i] = (baseMultipliers[i] * rate) / LENDING_PRECISION;
            } else {
                tokenMultipliers[i] = LENDING_PRECISION * baseMultipliers[i];
            }
        }
    }

    /// @notice fresh exchange rate after interest accrued
    function _exchangeRatesCurrent() internal returns (uint256[] memory tokenMultipliers) {
        tokenMultipliers = new uint256[](pooledTokens.length);
        for (uint256 i = 0; i < tokenMultipliers.length; i++) {
            if (useLending[i]) {
                IChErc20 market = IChErc20(pooledTokens[i]);
                uint256 rate = market.exchangeRateCurrent();
                tokenMultipliers[i] = (baseMultipliers[i] * rate) / LENDING_PRECISION;
            } else {
                tokenMultipliers[i] = LENDING_PRECISION * baseMultipliers[i];
            }
        }
    }

    function _doTransferIn(address token, uint256 amount) internal returns (uint256) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    function _doTransferOut(address token, uint256 amount) internal returns (uint256) {
        IERC20(token).safeTransfer(msg.sender, amount);
        return amount;
    }

    function _doTransferOut(address[] memory tokens, uint256[] memory amounts) internal {
        assert(tokens.length == amounts.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (amounts[i] > 0) {
                _doTransferOut(tokens[i], amounts[i]);
            }
        }
    }

    function _getAdminBalance(uint256 index) internal view returns (uint256) {
        require(index < numberOfTokens, "indexOutOfRange");
        return IERC20(pooledTokens[index]).balanceOf(address(this)) - (balances[index]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStableSwap.sol";

contract LPToken is Ownable, ERC20Burnable {
    IStableSwap public swap;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        swap = IStableSwap(msg.sender);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "zeroMintAmount");
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract OwnerPausable is Ownable, Pausable {
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}