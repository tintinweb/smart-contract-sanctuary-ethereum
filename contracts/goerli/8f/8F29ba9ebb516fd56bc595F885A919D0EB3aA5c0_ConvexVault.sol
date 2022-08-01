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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.2;

interface IAutoStakeFor {
    function stakeFor(address _for, uint256 amount) external;
    function rewardsDuration() external view returns(uint256);
    function earned(address _account) external view returns(uint256);

}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function poolInfo(uint256 _index) external view returns (PoolInfo memory);

    function poolLength() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface ICVXRewards {
    function withdraw(uint256 _amount, bool claim) external;
    function getReward(bool _stake) external;
    function stake(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFeeReceiving {
    function feeReceiving(
        address _sender,
        address _token,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IInflation {
    function getToken(address) external;
    function getToken() external;
    function getToken(address[] memory) external;
    function totalMinted() external view returns(uint256);
    function claimable(address) external view returns(uint256);
    function targetMinted() external view returns(uint256);
    function periodicEmission() external view returns(uint256);
    function startInflationTime() external view returns(uint256);
    function periodDuration() external view returns(uint256);
    function sumWeight() external view returns(uint256);
    function weights(address) external view returns(uint256);
    function token() external view returns(address);
    function lastTs() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IReferralProgram {
    struct User {
        bool exists;
        address referrer;
    }

    function users(address wallet)
        external
        returns (User memory user);

    function registerUser(address referrer, address referral) external;

    function rootAddress() external view returns(address);

    function feeReceiving(
        address _for,
        address _token,
        uint256 _amount
    ) external;
}

pragma solidity ^0.8.0;

interface IRewards {
    function stake(address, uint256) external;

    function stake(uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(bool) external;

    function getReward(address, bool) external returns(bool);

    function getReward() external returns (bool);

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external returns (address);

    function withdraw(uint256, bool) external returns(bool);

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function earned(address account) external view returns (uint256);

    function depositAll(bool, address) external;

    function deposit(uint256, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IVeToken {

    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }
    function pointHistory(uint256 index) external view returns(Point memory);

    function createLockFor(address addr, uint256 amount, uint256 lockEnd) external;

    function depositFor(address _addr, uint256 _value) external;

    function increaseAmountFor(address _account, uint256 _value) external;

    function increaseUnlockTimeFor(address _account, uint256 _unlockTime) external;

    function getLastUserSlope(address addr) external view returns (int128);

    function lockedEnd(address addr) external view returns (uint256);

    function lockedAmount(address addr) external view returns (uint256);

    function userPointEpoch(address addr) external view returns (uint256);

    function userPointHistoryTs(address addr, uint256 epoch)
        external
        view
        returns (uint256);

    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function balanceOf(address addr, uint256 timestamp)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);

    function lockedSupply() external view returns (uint256);

    function lockStarts(address addr) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function WEEK() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICurveCrvCvxCrvPool {
  function add_liquidity(
    uint256[2] memory _amounts,
    uint256 _min_mint_amount
  ) external returns(uint256);

  function coins(
    uint256 index
  ) external view returns(address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./base/BaseVault.sol";
import "./../interfaces/IBooster.sol";
import "./../interfaces/IRewards.sol";
import "./../interfaces/ICVXRewards.sol";
import "./../interfaces/curve/ICurveCrvCvxCrvPool.sol";

contract ConvexVault is BaseVault {

    struct ConstructorParams {
        address rewardToken;    // reward token
        IERC20 stakeToken;  // stake token (LP)
        address inflation;  // Inflation address
        string name;    // LP Vault token name
        string symbol;  // LP Vault token symbol
        address referralProgramAddress; // Referral program contract address
        address boosterAddress;
        uint256 poolIndex;
        address crvRewardAddress;   // CRV Rewards contract address
        address curvePool;
        uint256 percentageToBeLocked;
        address veTokenAddress;
    }

    using SafeERC20 for IERC20;

    address public boosterAddress;    // Booster address
    uint256 public poolIndex;   // Pool index
    address public crvRewardAddress;   

    address public curvePool; 

    address[2] public coins;

    /**
    * @param _params ConstructorParams struct 
    */
    constructor(
        ConstructorParams memory _params
    ) BaseVault(
        _params.rewardToken,
        _params.stakeToken,
        _params.inflation,
        _params.name,
        _params.symbol,
        _params.referralProgramAddress,
        _params.percentageToBeLocked,
        _params.veTokenAddress
    ) {
        boosterAddress = _params.boosterAddress;
        poolIndex = _params.poolIndex;
        crvRewardAddress = _params.crvRewardAddress;
        curvePool = _params.curvePool;
        for (uint256 i = 0; i < 2; i++) {
            address coinAddress = ICurveCrvCvxCrvPool(_params.curvePool).coins(i);
            IERC20(coinAddress).approve(_params.curvePool, type(uint256).max);
            coins[i] = coinAddress;
        }
    }

    function _getEarnedAmountFromExternalProtocol(address _user, uint256 _index) internal override returns(uint256 vaultEarned) {
        address crvReward = crvRewardAddress;
        Reward[] memory _rewards = rewards;
        if (_index == 1 || _index == 2 && crvReward != address(0)) { // index == CRV OR index == CVX
            IRewards(crvReward).getReward(address(this), false); // claim CRV and CVX
        }
    }

    function _harvestFromExternalProtocol() internal override {
        require(
            IRewards(crvRewardAddress).getReward(address(this), false),
            "!getRewardsCRV"
        );
    }

    function _depositToExternalProtocol(uint256 _amount, address _from) internal override {
        IERC20 stake = stakeToken;
        address booster = boosterAddress;
        if (_from != address(this)) stake.safeTransferFrom(_from, address(this), _amount);
        if (booster != address(0)) {
            stake.safeApprove(booster, _amount);
            IBooster(booster).depositAll(
                poolIndex,
                true
            );
        }
    }

    function depositUnderlyingTokensFor(
        uint256[2] memory _amounts, 
        uint256 _min_mint_amount, 
        address _to
    ) external {
        for (uint256 i; i < 2; i++) {
            IERC20(coins[i]).transferFrom(_msgSender(), address(this), _amounts[i]);
        }
        uint256 received = ICurveCrvCvxCrvPool(curvePool).add_liquidity(_amounts, _min_mint_amount);
        _depositForFrom(received, _to, address(this));
    }

    function _withdrawFromExternalProtocol(uint256 _amount, address _to) internal override {
        IRewards(crvRewardAddress).withdraw(_amount, true);
        require(
            IBooster(boosterAddress).withdraw(
                poolIndex,
                _amount
            ),
            "!withdraw"
        );
        stakeToken.safeTransfer(_to, _amount);

    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../interfaces/IReferralProgram.sol";
import "../../interfaces/IInflation.sol";
import "../../interfaces/IFeeReceiving.sol";
import "../../interfaces/IAutoStakeFor.sol";
import "../../interfaces/IVeToken.sol";

// Token distribution is very similar to MasterChef's distribution
// logic, but MasterChef's mint is supposed to be unlimited in
// time and has fixed amount of reward per period, so we made some
// changes in the staking logic. In particular, we changed earned()
// and updatePool() functions, so now arbitrary Token portions are
// distributed correctly. Also we make the virtual stake for the
// owner to avoid stacking Token reward on the contract. The virtual
// stake is only 1 wei so it won't affect other users' stakes, but
// there will always be a non-zero stake, so if some Token remains
// on the contract, owner can claim it. Token can remain because
// MasterChef doesn't mint reward if there are no stakers, but
// Inflation mints it in any case.

abstract contract BaseVault is ERC20, Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct Reward {
        address rewardToken;    // Reward token address
        uint128 accRewardPerShare;  // Accumulated reward per share
        uint256 lastBalance;    // Balance of this contract at the last moment when pool was updated
        uint256 payedRewardForPeriod;   // Reward amount payed for all the period
    }

    struct FeeReceiver {
        address receiver;   // Address of fee receiver
        uint256 bps; // Amount of reward token for the receiver (in BPs)
        bool isFeeReceivingCallNeeded;  // Flag if the feeReceiving() call needed or not
        mapping(address => bool) isTokenAllowedToBeChargedOfFees;   // Map if fee will be charged on this token
    }

    address public inflation;    // Inflation contract address
    uint256 public startTime;   // Timestamp when the vault was configured
    IERC20 public immutable stakeToken;   // Stake token address
    IReferralProgram public referralProgram;    // Referral program contract address
    IAutoStakeFor public votingStakingRewards;  // VSR contract address

    Reward[] public rewards;    // Array of reward tokens addresses

    mapping(uint256 => FeeReceiver) public feeReceivers;  // Reward token receivers
    uint256 public feeReceiversLength;  // Reward token receivers count

    bool public isGetRewardFeesEnabled; // Flag if fee distribution on getting reward enabled or not

    uint256 public depositFeeBps;   // On deposit fee amount (in BPs)
    address public depositFeeReceiver;  // On deposit fee receiver

    mapping(address => int256[]) public rewardDebts;  // users' reward debts
    mapping(address => address) public rewardDelegates;  // delegates addresses

    uint256 public percentageToBeLocked;
    address public veToken;

    uint256 internal constant ACC_REWARD_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256[] amounts);
    event LogUpdatePool(uint256 lpSupply, uint256[] rewardsPerPeriod);
    event NewRewardToken(address newToken);
    event Delegated(address delegator, address recipient);

    modifier onlyInflation {
        require(_msgSender() == inflation, "not inflation");
        _;
    }

    /**
    * @param _rewardToken reward token
    * @param _stakeToken stake token (LP)
    * @param _inflation Inflation address
    * @param _name LP Vault token name
    * @param _symbol LP Vault token symbol
    * @param _referralProgramAddress Referral program contract address
    */
    constructor(
        address _rewardToken,
        IERC20 _stakeToken,
        address _inflation,
        string memory _name,
        string memory _symbol,
        address _referralProgramAddress,
        uint256 _percentageToBeLocked,
        address _veToken
    ) ERC20(_name, _symbol) {
        rewards.push(Reward(_rewardToken, 0, 0, 0));
        stakeToken = _stakeToken;
        inflation = _inflation;
        referralProgram = IReferralProgram(_referralProgramAddress);
        percentageToBeLocked = _percentageToBeLocked;
        veToken = _veToken;
        IERC20(_rewardToken).approve(address(veToken), type(uint256).max);
        _pause();
    }

    /**
    * @notice Deletes all fee receivers
    * @dev Can be called only by owner
    */
    function deleteAllFeeReceivers() external onlyOwner {
        feeReceiversLength = 0;
    }


    function setPercentageToBeLocked(uint256 _percentageToBeLocked) external onlyOwner {
        require(_percentageToBeLocked <= 100, "invalid percentage");
        percentageToBeLocked = _percentageToBeLocked;
    }

    function setVeToken(address _veToken) external onlyOwner {
        veToken = _veToken;
    }

    function setVotingStakingRewards(IAutoStakeFor _votingStakingRewards) external onlyOwner {
        votingStakingRewards = _votingStakingRewards;
    }

    /**
    * @notice Adds fee receiver
    * @dev Can be called only by owner
    * @param _receiver New receiver address
    * @param _bps Amount of BPs for the new receiver
    * @param _isFeeReceivingCallNeeded Flag if feeReceiving() call needed
    * @param _rewardsTokens Reward token addresses
    * @param _statuses Flags if vault should pay fee on this token or not
    * @return feeReceiverIndex Index of the new added receiver
    */
    function addFeeReceiver(
        address _receiver,
        uint256 _bps,
        bool _isFeeReceivingCallNeeded,
        address[] calldata _rewardsTokens,
        bool[] calldata _statuses
    )
        external
        onlyOwner
        returns(uint256 feeReceiverIndex)
    {
        require(_rewardsTokens.length == _statuses.length, "invalidLengths");
        feeReceiverIndex = feeReceiversLength++;
        FeeReceiver storage feeReceiver = feeReceivers[feeReceiverIndex];
        feeReceiver.receiver = _receiver;
        feeReceiver.bps = _bps;
        feeReceiver.isFeeReceivingCallNeeded = _isFeeReceivingCallNeeded;
        for (uint256 i; i < _rewardsTokens.length; i++) {
            _setFeeReceiversTokensToBeChargedOfFees(feeReceiverIndex, _rewardsTokens[i], _statuses[i]);
        }
    }

    /**
    * @notice Returns reward token array length
    */
    function rewardsCount() external view returns(uint256) {
        return rewards.length;
    }

    /**
    * @notice Sets fee receiver address
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _receiver New receiver address
    */
    function setFeeReceiverAddress(uint256 _index, address _receiver) external onlyOwner {
        feeReceivers[_index].receiver = _receiver;
    }

    /**
    * @notice Sets BPs for fee receiver
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _bps New receiver BPs
    */
    function setFeeReceiverBps(uint256 _index, uint256 _bps) external onlyOwner {
        feeReceivers[_index].bps = _bps;
    }

    /**
    * @notice Sets isFeeReceivingCallNeeded flag for fee receiver
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _isFeeReceivingCallNeeded New flag
    */
    function setFeeReceiversCallNeeded(uint256 _index, bool _isFeeReceivingCallNeeded) external onlyOwner {
        feeReceivers[_index].isFeeReceivingCallNeeded = _isFeeReceivingCallNeeded;
    }

    /**
    * @notice Sets isTokenAllowedToBeChargedOfFees flag for specified token at specified fee receiver
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _rewardsToken Reward token address to change isTokenAllowedToBeChargedOfFees status
    * @param _status New status for isTokenAllowedToBeChargedOfFees flag
    */
    function setFeeReceiversTokensToBeChargedOfFees(uint256 _index, address _rewardsToken, bool _status) external onlyOwner {
        _setFeeReceiversTokensToBeChargedOfFees(_index, _rewardsToken, _status);
    }

    /**
    * @notice Sets isTokenAllowedToBeChargedOfFees flags for several fee receivers
    * @dev Can be called only by owner
    * @param _indices Receivers indices
    * @param _rewardsTokens Reward tokens addresses to change isTokenAllowedToBeChargedOfFees statuses
    * @param _statuses New statuses for isTokenAllowedToBeChargedOfFees flags
    */
    function setFeeReceiversTokensToBeChargedOfFeesMulti(
        uint256[] calldata _indices,
        address[] calldata _rewardsTokens,
        bool[] calldata _statuses
    ) external onlyOwner {
        require(_indices.length == _rewardsTokens.length, "invalidLengthsOfRewardsTokens");
        require(_indices.length == _statuses.length, "invalidLengthsOfStatuses");
        for (uint256 i; i < _indices.length; i++) {
            _setFeeReceiversTokensToBeChargedOfFees(_indices[i], _rewardsTokens[i], _statuses[i]);
        }
    }

    /**
    * @notice Sets Inflation contract address
    * @dev can be called only by owner
    * @param _inflation new Inflation contract address
    */
    function setInflation(address _inflation) external onlyOwner {
        inflation = _inflation;
    }

    /**
    * @notice Sets Referral program contract address
    * @dev Can be called only by owner
    * @param _refProgram New Referral program contract address
    */
    function setReferralProgram(address _refProgram) external onlyOwner {
        referralProgram = IReferralProgram(_refProgram);
    }

    /**
    * @notice Sets the flag if fee on getting reward is claimed or not
    * @dev Can be called only by owner
    * @param _isEnabled New onGetRewardFeesEnabled status
    */
    function setOnGetRewardFeesEnabled(bool _isEnabled) external onlyOwner {
        isGetRewardFeesEnabled = _isEnabled;
    }

    /**
    * @notice Sets deposit fee BPs
    * @dev can be called only by owner
    * @param _bps New deposit fee BPs
    */
    function setDepositFeeBps(uint256 _bps) external onlyOwner {
        depositFeeBps = _bps;
    }

    /**
    * @notice Sets deposit fee receiver
    * @dev can be called only by owner
    * @param _receiver New deposit fee receiver
    */
    function setDepositFeeReceiver(address _receiver) external onlyOwner {
        depositFeeReceiver = _receiver;
    }

    /**
    * @notice Configures Vault
    * @dev can be called only by Inflation
    */
    function configure() external virtual onlyInflation whenPaused {
        _unpause();
        updatePool();
        address owner_ = owner();
        _mint(owner_, 1 wei);
        _depositFor(1 wei, owner_);
        startTime = block.timestamp;
    }

    /**
    * @notice Returns user's reward debt
    * @param _account User's address
    * @param _index Index of reward token
    */
    function getRewardDebt(address _account, uint256 _index) external view returns(int256) {
        if (_index < rewardDebts[_account].length) return rewardDebts[_account][_index];
        return 0;
    }

    /**
    * @notice Adds reward token
    * @dev Can be called only by owner
    * @param _newToken New reward token
    */

    function addRewardToken(address _newToken) external onlyOwner {
        rewards.push(Reward(_newToken, 0, 0, 0));
        updatePool();
        emit NewRewardToken(_newToken);
    }

    /**
    * @notice Returns user's earned reward
    * @dev Mutability speciefier should be manually switched to 'view'
    * in ABI due to Curve's claimable_tokens function implementation
    * @param _user User's address
    * @param _index Index of reward token
    * @return pending Amount of pending reward
    */
    function earned(address _user, uint256 _index) external virtual returns (uint256 pending) {
        Reward[] memory _rewards = rewards;
        require(_index < _rewards.length, "index exceeds amount of reward tokens");
        uint256 accRewardPerShare_ = _rewards[_index].accRewardPerShare;
        uint256 lpSupply = totalSupply() - balanceOf(address(this));
        uint256 vaultEarned;

        if (_index == 0) {
            vaultEarned = IInflation(inflation).claimable(address(this)); 
        } else {
            vaultEarned = _getEarnedAmountFromExternalProtocol(_user, _index);
        }
        uint256 balance = IERC20(_rewards[_index].rewardToken).balanceOf(address(this));
        uint256 rewardForPeriod = balance + vaultEarned - (_rewards[_index].lastBalance - _rewards[_index].payedRewardForPeriod);
        if (lpSupply != 0) {
            uint256 reward = rewardForPeriod;
            accRewardPerShare_ += reward * ACC_REWARD_PRECISION / lpSupply;
        }
        if (_index < rewardDebts[_user].length) {
            pending = uint256(int256(balanceOf(_user) * accRewardPerShare_ / ACC_REWARD_PRECISION) - rewardDebts[_user][_index]);
        } else {
            pending = balanceOf(_user) * accRewardPerShare_ / ACC_REWARD_PRECISION;
        }

    }

    /**
    * @notice Updates pool
    * @dev Mints Token if available, claims all reward from the gauge
    */
    function updatePool() public virtual whenNotPaused {
        Reward[] memory _rewards = rewards;
        uint256 length = _rewards.length;
        _harvestFromExternalProtocol();
        IInflation(inflation).getToken(address(this));
        uint256[] memory rewardsForPeriod = new uint256[](length);
        uint256 lpSupply = totalSupply() - balanceOf(address(this));
        uint256 multiplier = ACC_REWARD_PRECISION;
        for (uint256 i; i < length; i++) {
            uint256 balance = IERC20(_rewards[i].rewardToken).balanceOf(address(this)); // get the balance after claim/mint
            rewardsForPeriod[i] = balance - (_rewards[i].lastBalance - _rewards[i].payedRewardForPeriod);   // calculate how much reward came from the last time
            rewards[i].lastBalance = balance;
            rewards[i].payedRewardForPeriod = 0;
            if (lpSupply > 0) rewards[i].accRewardPerShare += uint128(rewardsForPeriod[i] * multiplier / lpSupply);
        }

        emit LogUpdatePool(lpSupply, rewardsForPeriod);
    }

    /**
    * @notice Deposits stake tokens for user for reward allocation
    * @param _amount Amount of tokens to deposit
    * @param _to Address of a beneficiary
    */
    function depositFor(uint256 _amount, address _to) public virtual nonReentrant whenNotPaused {
        _depositForFrom(_amount, _to, _msgSender());
    }

    function _depositForFrom(uint256 _amount, address _to, address _from) internal virtual {
        _amount = _chargeFeesOnDeposit(_amount);
        updatePool();
        _mint(_to, _amount);
        _depositFor(_amount, _to);
        _depositToExternalProtocol(_amount, _from);
        IReferralProgram referral = referralProgram;
        if(!referral.users(_to).exists) {
            address rootAddress = referral.rootAddress();
            referral.registerUser(rootAddress, _to);
        }
        emit Deposit(_from, _amount, _to);
    }

    /**
    * @notice Withdraw Vault LP tokens.
    * @dev Withdraws underlying tokens from Gauge, transfers Vault LP to 'to' address
    * @param _amount Vault LP token amount to unwrap.
    * @param _to The receiver of Vault LP tokens.
    */
    function withdraw(uint256 _amount, address _to) public nonReentrant virtual whenNotPaused {
        updatePool();
        _withdraw(_amount, _msgSender());
        _withdrawFromExternalProtocol(_amount, _to);
        _burn(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _amount, _to);
    }

    /**
    * @notice Harvest all available reward for the user.
    * @param _to The receiver of the reward tokens.
    */
    function getReward(address _to) public virtual nonReentrant whenNotPaused {
        _getReward(_msgSender(), _to, false);
    }

    function _getReward(address _for, address _to, bool _hardSend) internal virtual {
        updatePool();
        Reward[] memory _rewards = rewards;
        uint256 rewardsLength = _rewards.length;
        uint256[] memory _pendingRewards = new uint256[](rewardsLength);
        uint256 multiplier = ACC_REWARD_PRECISION;

        // Interactions
        for (uint256 i; i < rewardsLength; i++) {
            int256 accumulatedReward = int256(balanceOf(_for) * _rewards[i].accRewardPerShare / multiplier);
            if (i >= rewardDebts[_for].length) rewardDebts[_for].push(0);
            _pendingRewards[i] = uint256(accumulatedReward - rewardDebts[_for][i]);

            rewardDebts[_for][i] = accumulatedReward;
            if (_pendingRewards[i] > 0) {
                address rewardTokenAddress = _rewards[i].rewardToken;
                uint256 rewardsAmountWithFeesTaken = _chargeFees(_for, rewardTokenAddress, _pendingRewards[i]);
                _transferOrLock(rewardTokenAddress, rewardsAmountWithFeesTaken, _to, _hardSend);
                rewards[i].payedRewardForPeriod += _pendingRewards[i];
                _pendingRewards[i] = rewardsAmountWithFeesTaken;
            }
        }

        emit Harvest(_for, _pendingRewards);
    }

    /**
    * @notice Withdraw tokens from Vault and harvest reward for transaction sender to `_to`
    * @param _amount LP token amount to withdraw
    * @param _to Receiver of the LP tokens and rewards
    */
    function withdrawAndHarvest(uint256 _amount, address _to) public virtual nonReentrant whenNotPaused {
        updatePool();
        address sender = _msgSender();
        Reward[] memory _rewards = rewards;
        uint256 multiplier = ACC_REWARD_PRECISION;
        // Effects

        _withdrawFromExternalProtocol(_amount, _to);
        _burn(sender, _amount);

        uint256 rewardsLength = _rewards.length;
        uint256[] memory _pendingRewards = new uint256[](rewardsLength);

        for (uint256 i; i < rewardsLength; i++) {
            if (i >= rewardDebts[sender].length) {
                rewardDebts[sender].push(-int256(_amount * _rewards[i].accRewardPerShare / multiplier));
            } else {
                rewardDebts[sender][i] -= int256(_amount * _rewards[i].accRewardPerShare / multiplier);
            }
            int256 accumulatedReward = int256(balanceOf(sender) * _rewards[i].accRewardPerShare / multiplier);
            _pendingRewards[i] = uint256(accumulatedReward - rewardDebts[sender][i]);

            rewardDebts[sender][i] = accumulatedReward;
            if (_pendingRewards[i] > 0) {
                address rewardTokenAddress = _rewards[i].rewardToken;
                uint256 rewardsAmountWithFeesTaken = _chargeFees(sender, rewardTokenAddress, _pendingRewards[i]);
                _transferOrLock(rewardTokenAddress, rewardsAmountWithFeesTaken, _to, false);
                rewards[i].payedRewardForPeriod += _pendingRewards[i];
                _pendingRewards[i] = rewardsAmountWithFeesTaken;
            }
        }
        emit Harvest(sender, _pendingRewards);
        emit Withdraw(_msgSender(), _amount, _to);
    }

    function setDelegate(address _baseReceiver, address _delegate) external onlyOwner {
        require(rewardDelegates[_baseReceiver] != _delegate, "!new");
        rewardDelegates[_baseReceiver] = _delegate;
        emit Delegated(_baseReceiver, _delegate);
    }

    function getRewardForDelegator(address _baseReceiver)
        nonReentrant
        virtual 
        external {
        require(_msgSender() == rewardDelegates[_baseReceiver], "unknown sender");
        _getReward(_baseReceiver, _msgSender(), true);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        updatePool();
        _withdraw(amount, sender);
        super._transfer(sender, recipient, amount);
        _depositFor(amount, recipient);
    }

    function _depositFor(uint256 _amount, address _to) internal virtual {
        Reward[] memory _rewards = rewards;
        // Effects
        uint256 multiplier = ACC_REWARD_PRECISION;

        for (uint256 i; i < _rewards.length; i++) {
            if (i >= rewardDebts[_to].length) {
                rewardDebts[_to].push(int256(_amount * _rewards[i].accRewardPerShare / multiplier));
            } else {
                rewardDebts[_to][i] += int256(_amount * _rewards[i].accRewardPerShare / multiplier);
            }
        }

    }

    function _withdraw(uint256 _amount, address _user) internal virtual {
        Reward[] memory _rewards = rewards;
        uint256 multiplier = ACC_REWARD_PRECISION;
        // Effects
        for (uint256 i; i < _rewards.length; i++) {
            if (i >= rewardDebts[_user].length) {
                rewardDebts[_user].push(-int256(_amount * _rewards[i].accRewardPerShare / multiplier));
            } else {
                rewardDebts[_user][i] -= int256(_amount * _rewards[i].accRewardPerShare / multiplier);
            }
        }

    }

    function _chargeFees(
        address _sender,
        address _rewardToken,
        uint256 _amount
    ) internal virtual returns (uint256) {
        if (!isGetRewardFeesEnabled) {
            return _amount;
        }
        uint256 fee;
        uint256 amountAfterFee = _amount;

        for (uint256 i = 0; i < feeReceiversLength; i++) {
            FeeReceiver storage _feeReceiver = feeReceivers[i];
            if (_feeReceiver.isTokenAllowedToBeChargedOfFees[_rewardToken]) {
                fee = _feeReceiver.bps * _amount / 10000;
                IERC20(_rewardToken).safeTransfer(_feeReceiver.receiver, fee);
                amountAfterFee -= fee;
                if (_feeReceiver.isFeeReceivingCallNeeded) {
                    IFeeReceiving(_feeReceiver.receiver).feeReceiving(
                        _sender,
                        _rewardToken,
                        fee
                    );
                }
            }
        }
        return amountAfterFee;
    }

    // function _autoStakeForOrSendTo(
    //     address _token,
    //     uint256 _amount,
    //     address _receiver,
    //     bool _hardSend
    // ) internal virtual {
    //     if (_token != rewards[0].rewardToken || _hardSend) {
    //         IERC20(_token).safeTransfer(_receiver, _amount);
    //     } else {
    //         IERC20(_token).approve(address(votingStakingRewards), 0);
    //         IERC20(_token).approve(address(votingStakingRewards), _amount);
    //         votingStakingRewards.stakeFor(_receiver, _amount);
    //     }
    // }

    function _transferOrLock(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _hardSend
    ) internal {
        if (_token != rewards[0].rewardToken || _hardSend) {
            IERC20(_token).safeTransfer(_receiver, _amount);
        } else {
            uint256 toLock = percentageToBeLocked * _amount / 100;
            uint256 toTransfer = _amount - toLock;
            IVeToken veToken_ = IVeToken(veToken);
            uint256 unlockTime = veToken_.lockedEnd(_receiver);
            if (unlockTime == 0) {
                IVeToken.Point memory initialPoint = veToken_.pointHistory(0);
                uint256 rewardsDuration = votingStakingRewards.rewardsDuration();
                uint256 lockTime = veToken_.MAXTIME();
                uint256 week = veToken_.WEEK();
                if (initialPoint.ts + lockTime + rewardsDuration < block.timestamp) { // reward program is surely over
                    IERC20(_token).safeTransfer(_receiver, _amount);
                } else {
                    IERC20(_token).safeTransfer(_receiver, toTransfer);
                    uint256 unlockDate = 
                        (initialPoint.ts + lockTime) / week * week <= block.timestamp ? // if we are between 100 and 101 week
                        block.timestamp + 2 * rewardsDuration : 
                        initialPoint.ts + lockTime;
                    veToken_.createLockFor(_receiver, toLock, unlockDate);
                }

            } else {
                require(unlockTime > block.timestamp, "withdraw the lock first");
                IERC20(_token).safeTransfer(_receiver, toTransfer);
                veToken_.increaseAmountFor(_receiver, toLock);
            }
        }
    }

    function _chargeFeesOnDeposit(uint256 _amount)
        internal 
        virtual
        returns (uint256 _sumWithoutFee)
    {
        uint256 bps = depositFeeBps;
        if (bps > 0) {
            uint256 _fee = bps * _amount / 10000;
            stakeToken.safeTransferFrom(_msgSender(), depositFeeReceiver, _fee);
            _sumWithoutFee = _amount - _fee;

        } else {
            _sumWithoutFee = _amount;
        }
    }

    function _setFeeReceiversTokensToBeChargedOfFees(uint256 _index, address _rewardsToken, bool _status) internal {
        feeReceivers[_index].isTokenAllowedToBeChargedOfFees[_rewardsToken] = _status;
    }

    function _getEarnedAmountFromExternalProtocol(
        address _user, 
        uint256 _index
    ) internal virtual returns(uint256 vaultEarned);
    function _harvestFromExternalProtocol() internal virtual;
    function _depositToExternalProtocol(uint256 _amount, address _from) internal virtual;
    function _withdrawFromExternalProtocol(uint256 _amount, address _to) internal virtual;

}