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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IXToken.sol";
import "./interfaces/IYToken.sol";
import "./interfaces/IYTokenReserve.sol";
import "./interfaces/IMasterOracle.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ISwapStrategy.sol";
import "./libs/WethUtils.sol";

contract Pool is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using SafeERC20 for IWETH;
    using SafeERC20 for IXToken;
    using SafeERC20 for IYToken;

    struct UserInfo {
        uint256 xTokenBalance;
        uint256 yTokenBalance;
        uint256 ethBalance;
        uint256 lastAction;
    }

    /* ========== ADDRESSES ================ */

    IMasterOracle public oracle;
    IXToken public xToken;
    IYToken public yToken;
    IYTokenReserve public yTokenReserve;
    ISwapStrategy public swapStrategy;
    address public treasury;

    /* ========== STATE VARIABLES ========== */

    mapping(address => UserInfo) public userInfo;

    uint256 public unclaimedEth;
    uint256 public unclaimedXToken;
    uint256 public unclaimedYToken;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e18;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    uint256 private constant PRECISION = 1e6;

    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;

    // Collateral ratio
    uint256 public collateralRatio = 1e6;
    uint256 public lastRefreshCrTimestamp;
    uint256 public refreshCooldown = 3600; // = 1 hour
    uint256 public ratioStepUp = 2000; // = 0.002 or 0.2% -> ratioStep when CR increase
    uint256 public ratioStepDown = 1000; // = 0.001 or 0.1% -> ratioStep when CR decrease
    uint256 public priceTarget = 1e18; // = 1; 1 XToken pegged to the value of 1 ETH
    uint256 public priceBand = 5e15; // = 0.005; CR will be adjusted if XToken > 1.005 ETH or XToken < 0.995 ETH
    uint256 public minCollateralRatio = 1e6;
    uint256 public yTokenSlippage = 100000; // 10%
    bool public collateralRatioPaused = false;

    // fees
    uint256 public redemptionFee = 5000; // 6 decimals of precision, .5%
    uint256 public constant REDEMPTION_FEE_MAX = 9000; // 0.9%
    uint256 public mintingFee = 3000; // 6 decimals of precision, .3%
    uint256 public constant MINTING_FEE_MAX = 5000; // 0.5%

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _xToken,
        address _yToken,
        address _yTokenReserve
    ) {
        require(_xToken != address(0), "Pool::initialize: invalidAddress");
        require(_yToken != address(0), "Pool::initialize: invalidAddress");
        require(_yTokenReserve != address(0), "Pool::initialize: invalidAddress");
        xToken = IXToken(_xToken);
        xToken.setMinter(address(this));
        yToken = IYToken(_yToken);
        yTokenReserve = IYTokenReserve(_yTokenReserve);
        yTokenReserve.setPool(address(this));
    }

    /* ========== VIEWS ========== */

    function info()
        external
        view
        returns (
            uint256 _collateralRatio,
            uint256 _lastRefreshCrTimestamp,
            uint256 _mintingFee,
            uint256 _redemptionFee,
            bool _mintingPaused,
            bool _redemptionPaused,
            uint256 _collateralBalance
        )
    {
        _collateralRatio = collateralRatio;
        _lastRefreshCrTimestamp = lastRefreshCrTimestamp;
        _mintingFee = mintingFee;
        _redemptionFee = redemptionFee;
        _mintingPaused = mintPaused;
        _redemptionPaused = redeemPaused;
        _collateralBalance = usableCollateralBalance();
    }

    function usableCollateralBalance() public view returns (uint256) {
        uint256 _balance = WethUtils.weth.balanceOf(address(this));
        return _balance > unclaimedEth ? (_balance - unclaimedEth) : 0;
    }

    function getXSupplyAndUnclaimed() public view returns (uint256) {
        return ((xToken.totalSupply()) + (unclaimedXToken));
    }

    function realCollateralRatio () public view returns (uint256) {
        return ((usableCollateralBalance()) * (1000000)) / (getXSupplyAndUnclaimed());
    }

    /// @notice Calculate the expected results for zap minting
    /// @param _ethIn Amount of Collateral token input.
    /// @return _xTokenOut : the amount of XToken output.
    /// @return _yTokenOutTwap : the amount of YToken output by swapping based on Twap price
    /// @return _ethFee : the fee amount in Collateral token.
    /// @return _ethSwapIn : the amount of Collateral token to swap
    function calcMint(uint256 _ethIn)
        public
        view
        returns (
            uint256 _xTokenOut,
            uint256 _yTokenOutTwap,
            uint256 _ethFee,
            uint256 _ethSwapIn
        )
    {
        uint256 _yTokenTwap = oracle.getYTokenTWAP();
        require(_yTokenTwap > 0, "Pool::calcMint: Invalid YToken price");
        _ethSwapIn = (_ethIn * (COLLATERAL_RATIO_MAX - collateralRatio)) / COLLATERAL_RATIO_MAX;
        _yTokenOutTwap = (_ethSwapIn * PRICE_PRECISION) / _yTokenTwap;
        _ethFee = (_ethIn * mintingFee * collateralRatio) / COLLATERAL_RATIO_MAX / PRECISION;
        _xTokenOut = _ethIn - ((_ethIn * mintingFee) / PRECISION);
    }

    /// @notice Calculate the expected results for redemption
    /// @param _xTokenIn Amount of XToken input.
    /// @return _ethOut : the amount of Eth output
    /// @return _yTokenOutSpot : the amount of YToken output based on Spot prrice
    /// @return _yTokenOutTwap : the amount of YToken output based on TWAP
    /// @return _ethFee : the fee amount in Eth
    /// @return _requiredEthBalance : required Eth balance in the pool
    function calcRedeem(uint256 _xTokenIn)
        public
        view
        returns (
            uint256 _ethOut,
            uint256 _yTokenOutSpot,
            uint256 _yTokenOutTwap,
            uint256 _ethFee,
            uint256 _requiredEthBalance
        )
    {
        uint256 _yTokenPrice = oracle.getYTokenPrice();
        uint256 _yTokenTWAP = oracle.getYTokenTWAP();
        require(_yTokenPrice > 0, "Pool::calcRedeem: Invalid YToken price");

        _requiredEthBalance = (_xTokenIn * collateralRatio) / PRECISION;
        if (collateralRatio < COLLATERAL_RATIO_MAX) {
            _yTokenOutSpot = (_xTokenIn * (COLLATERAL_RATIO_MAX - collateralRatio) * (PRECISION - redemptionFee) * PRICE_PRECISION) / COLLATERAL_RATIO_MAX / PRECISION / _yTokenPrice;
            _yTokenOutTwap = (_xTokenIn * (COLLATERAL_RATIO_MAX - collateralRatio) * (PRECISION - redemptionFee) * PRICE_PRECISION) / COLLATERAL_RATIO_MAX / PRECISION / _yTokenTWAP;
        }

        if (collateralRatio > 0) {
            _ethOut = (_xTokenIn * collateralRatio * (PRECISION - redemptionFee)) / COLLATERAL_RATIO_MAX / PRECISION;
            _ethFee = (_xTokenIn * collateralRatio * redemptionFee) / COLLATERAL_RATIO_MAX / PRECISION;
        }
    }

    /// @notice Calculate the excess collateral balance
    function calcExcessCollateralBalance() public view returns (uint256 _delta, bool _exceeded) {
        uint256 _requiredCollateralBal = (xToken.totalSupply() * collateralRatio) / COLLATERAL_RATIO_MAX;
        uint256 _usableCollateralBal = usableCollateralBalance();
        if (_usableCollateralBal >= _requiredCollateralBal) {
            _delta = _usableCollateralBal - _requiredCollateralBal;
            _exceeded = true;
        } else {
            _delta = _requiredCollateralBal - _usableCollateralBal;
            _exceeded = false;
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /// @notice Update collateral ratio and adjust based on the TWAP price of XToken
    function refreshCollateralRatio() public {
        require(collateralRatioPaused == false, "Pool::refreshCollateralRatio: Collateral Ratio has been paused");
        require(block.timestamp - lastRefreshCrTimestamp >= refreshCooldown, "Pool::refreshCollateralRatio: Must wait for the refresh cooldown since last refresh");

        uint256 _xTokenPrice = oracle.getXTokenTWAP();
        if (_xTokenPrice > priceTarget + priceBand) {
            if (collateralRatio <= ratioStepDown) {
                collateralRatio = 0;
            } else {
                uint256 _newCR = collateralRatio - ratioStepDown;
                if (_newCR <= minCollateralRatio) {
                    collateralRatio = minCollateralRatio;
                } else {
                    collateralRatio = _newCR;
                }
            }
        } else if (_xTokenPrice < priceTarget - priceBand) {
            if (collateralRatio + ratioStepUp >= COLLATERAL_RATIO_MAX) {
                collateralRatio = COLLATERAL_RATIO_MAX;
            } else {
                collateralRatio = collateralRatio + ratioStepUp;
            }
        }

        lastRefreshCrTimestamp = block.timestamp;
        emit NewCollateralRatioSet(collateralRatio);
    }

    /// @notice fallback for payable -> required to unwrap WETH
    receive() external payable {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint256 _minXTokenOut) external payable nonReentrant {
        require(!mintPaused, "Pool::mint: Minting is paused");
        uint256 _ethIn = msg.value;
        address _sender = msg.sender;

        (uint256 _xTokenOut, uint256 _yTokenOutTwap, uint256 _fee, uint256 _wethSwapIn) = calcMint(_ethIn);
        require(_xTokenOut >= _minXTokenOut, "Pool::mint: > slippage");

        WethUtils.wrap(_ethIn);
        if (_yTokenOutTwap > 0 && _wethSwapIn > 0) {
            WethUtils.weth.safeIncreaseAllowance(address(swapStrategy), _wethSwapIn);
            swapStrategy.execute(_wethSwapIn, _yTokenOutTwap);
        }

        if (_xTokenOut > 0) {
            userInfo[_sender].xTokenBalance = userInfo[_sender].xTokenBalance + _xTokenOut;
            unclaimedXToken = unclaimedXToken + _xTokenOut;
        }

        transferToTreasury(_fee);

        emit Mint(_sender, _xTokenOut, _ethIn, _fee);
    }

    function redeem(
        uint256 _xTokenIn,
        uint256 _minYTokenOut,
        uint256 _minEthOut
    ) external nonReentrant {
        require(!redeemPaused, "Pool::redeem: Redeeming is paused");

        address _sender = msg.sender;
        (uint256 _ethOut, uint256 _yTokenOutSpot, uint256 _yTokenOutTwap, uint256 _fee, uint256 _requiredEthBalance) = calcRedeem(_xTokenIn);

        // Check if collateral balance meets and meet output expectation
        require(_requiredEthBalance <= usableCollateralBalance(), "Pool::redeem: > ETH balance");

        // Prevent price manipulation to get more yToken
        checkPriceFluctuation(_yTokenOutSpot, _yTokenOutTwap);

        require(_minEthOut <= _ethOut && _minYTokenOut <= _yTokenOutSpot, "Pool::redeem: >slippage");

        if (_ethOut > 0) {
            userInfo[_sender].ethBalance = userInfo[_sender].ethBalance + _ethOut;
            unclaimedEth = unclaimedEth + _ethOut;
        }

        if (_yTokenOutSpot > 0) {
            userInfo[_sender].yTokenBalance = userInfo[_sender].yTokenBalance + _yTokenOutSpot;
            unclaimedYToken = unclaimedYToken + _yTokenOutSpot;
        }

        userInfo[_sender].lastAction = block.number;

        // Move all external functions to the end
        xToken.burnFrom(_sender, _xTokenIn);
        transferToTreasury(_fee);

        emit Redeem(_sender, _xTokenIn, _ethOut, _yTokenOutSpot, _fee);
    }

    /**
     * @notice collect all minting and redemption
     */
    function collect() external nonReentrant {
        address _sender = msg.sender;
        require(userInfo[_sender].lastAction < block.number, "Pool::collect: <minimum_delay");

        bool _sendXToken = false;
        bool _sendYToken = false;
        bool _sendEth = false;
        uint256 _xTokenAmount;
        uint256 _yTokenAmount;
        uint256 _ethAmount;

        // Use Checks-Effects-Interactions pattern
        if (userInfo[_sender].xTokenBalance > 0) {
            _xTokenAmount = userInfo[_sender].xTokenBalance;
            userInfo[_sender].xTokenBalance = 0;
            unclaimedXToken = unclaimedXToken - _xTokenAmount;
            _sendXToken = true;
        }

        if (userInfo[_sender].yTokenBalance > 0) {
            _yTokenAmount = userInfo[_sender].yTokenBalance;
            userInfo[_sender].yTokenBalance = 0;
            unclaimedYToken = unclaimedYToken - _yTokenAmount;
            _sendYToken = true;
        }

        if (userInfo[_sender].ethBalance > 0) {
            _ethAmount = userInfo[_sender].ethBalance;
            userInfo[_sender].ethBalance = 0;
            unclaimedEth = unclaimedEth - _ethAmount;
            _sendEth = true;
        }

        if (_sendXToken) {
            xToken.mint(_sender, _xTokenAmount);
        }

        if (_sendYToken) {
            yTokenReserve.transfer(_sender, _yTokenAmount);
        }

        if (_sendEth) {
            WethUtils.unwrap(_ethAmount);
            Address.sendValue(payable(_sender), _ethAmount);
        }
    }

    /// @notice Function to recollateralize the pool by receiving ETH
    function recollateralize() external payable {
        uint256 _amount = msg.value;
        require(_amount > 0, "Pool::recollateralize: Invalid amount");
        WethUtils.wrap(_amount);
        emit Recollateralized(msg.sender, _amount);
    }

     function checkPriceFluctuation(uint256 _yAmountSpotPrice, uint256 _yAmountTwap) internal view {
        uint256 _diff;
        if (_yAmountSpotPrice > _yAmountTwap) {
            _diff = _yAmountSpotPrice - _yAmountTwap;
        } else {
            _diff = _yAmountTwap - _yAmountSpotPrice;
        }
        require(_diff <= ((_yAmountTwap * yTokenSlippage) / PRECISION), "Pool::checkPriceFluctuation: > yTokenSlippage");
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Turn on / off minting and redemption
    /// @param _mintPaused Paused or NotPaused Minting
    /// @param _redeemPaused Paused or NotPaused Redemption
    function toggle(bool _mintPaused, bool _redeemPaused) public onlyOwner {
        mintPaused = _mintPaused;
        redeemPaused = _redeemPaused;
        emit Toggled(_mintPaused, _redeemPaused);
    }

    /// @notice Configure variables related to Collateral Ratio
    /// @param _ratioStepUp Step which Collateral Ratio will be increased each updates
    /// @param _ratioStepDown Step which Collateral Ratio will be decreased each updates
    /// @param _priceBand The collateral ratio will only be adjusted if current price move out of this band
    /// @param _refreshCooldown The minimum delay between each Collateral Ratio updates
    function setCollateralRatioOptions(
        uint256 _ratioStepUp,
        uint256 _ratioStepDown,
        uint256 _priceBand,
        uint256 _refreshCooldown
    ) public onlyOwner {
        ratioStepUp = _ratioStepUp;
        ratioStepDown = _ratioStepDown;
        priceBand = _priceBand;
        refreshCooldown = _refreshCooldown;
        emit NewCollateralRatioOptions(_ratioStepUp, _ratioStepDown, _priceBand, _refreshCooldown);
    }

    /// @notice Pause or unpause collateral ratio updates
    /// @param _collateralRatioPaused `true` or `false`
    function toggleCollateralRatio(bool _collateralRatioPaused) public onlyOwner {
        if (collateralRatioPaused != _collateralRatioPaused) {
            collateralRatioPaused = _collateralRatioPaused;
            emit UpdateCollateralRatioPaused(_collateralRatioPaused);
        }
    }

    /// @notice Set the protocol fees
    /// @param _mintingFee Minting fee in percentage
    /// @param _redemptionFee Redemption fee in percentage
    function setFees(uint256 _mintingFee, uint256 _redemptionFee) public onlyOwner {
        require(_mintingFee <= MINTING_FEE_MAX, "Pool::setFees:>MINTING_FEE_MAX");
        require(_redemptionFee <= REDEMPTION_FEE_MAX, "Pool::setFees:>REDEMPTION_FEE_MAX");
        redemptionFee = _redemptionFee;
        mintingFee = _mintingFee;
        emit FeesUpdated(_mintingFee, _redemptionFee);
    }

    /// @notice Set the minimum Collateral Ratio
    /// @param _minCollateralRatio value of minimum Collateral Ratio in 1e6 precision
    function setMinCollateralRatio(uint256 _minCollateralRatio) external onlyOwner {
        require(_minCollateralRatio <= COLLATERAL_RATIO_MAX, "Pool::setMinCollateralRatio: >COLLATERAL_RATIO_MAX");
        minCollateralRatio = _minCollateralRatio;
        emit MinCollateralRatioUpdated(_minCollateralRatio);
    }

    /// @notice Transfer the excess balance of WETH to FeeReserve
    /// @param _amount amount of WETH to reduce
    function reduceExcessCollateral(uint256 _amount) external onlyOwner {
        (uint256 _excessWethBal, bool exceeded) = calcExcessCollateralBalance();
        if (exceeded && _excessWethBal > 0) {
            require(_amount <= _excessWethBal, "Pool::reduceExcessCollateral: The amount is too large");
            transferToTreasury(_amount);
        }
    }

    /// @notice Set the address of Swapper utils
    /// @param _swapStrategy address of Swapper utils contract
    function setSwapStrategy(ISwapStrategy _swapStrategy) external onlyOwner {
        require(address(_swapStrategy) != address(0), "Pool::setSwapStrategy: invalid address");
        swapStrategy = _swapStrategy;
        emit SwapStrategyChanged(address(_swapStrategy));
    }

    /// @notice Set new oracle address
    /// @param _oracle address of the oracle
    function setOracle(IMasterOracle _oracle) external onlyOwner {
        require(address(_oracle) != address(0), "Pool::setOracle: invalid address");
        oracle = _oracle;
        emit OracleChanged(address(_oracle));
    }

    /// @notice Set yTokenSlipage
    function setYTokenSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= 300000, "Pool::setYTokenSlippage: yTokenSlippage cannot be more than 30%");
        yTokenSlippage = _slippage;
        emit YTokenSlippageSet(_slippage);
    }

    /// @notice Set the address of Treasury
    /// @param _treasury address of Treasury contract
    function setTreasury(address _treasury) external {
        require(treasury == address(0), "Pool::setTreasury: not allowed");
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    /// @notice Move weth to treasury
    function transferToTreasury(uint256 _amount) internal {
        require(treasury != address(0), "Pool::transferToTreasury:Invalid address");
        if (_amount > 0) {
            WethUtils.weth.safeTransfer(treasury, _amount);
        }
    }

    // Arber only
    IUniswapV2Router02 public uniswapV2Router02; 
    mapping (address => bool) public arbers; 
    address[] public xTokenWethPath;
    address[] public wethXTokenPath;
    address[] public yTokenWethPath;

    function setRouter (address _uniswapV2Router02) public onlyOwner () {
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
    }

    function approveArber (address _arber) public onlyOwner () {
        arbers[_arber] = true;
    }

    function revokeArber (address _arber) public onlyOwner () {
        arbers[_arber] = false;
    }

    function setXTokenWethPath (address[] memory _xTokenWethPath) public onlyOwner () {
        delete xTokenWethPath;
        for (uint256 i = 0; i < _xTokenWethPath.length; i++) {
            xTokenWethPath.push(_xTokenWethPath[i]);
        }
    }

    
    function setWethXTokenPath (address [] memory _wethXTokenPath) public onlyOwner () {
        delete wethXTokenPath;
        for (uint256 i = 0; i < _wethXTokenPath.length; i++) {
            wethXTokenPath.push(_wethXTokenPath[i]);
        }
    }


    function setYTokenWethPath (address [] memory _yTokenWethPath) public onlyOwner () {
        delete yTokenWethPath;
        for (uint256 i = 0; i < _yTokenWethPath.length; i++) {
            yTokenWethPath.push(_yTokenWethPath[i]);
        }
    }


    modifier onlyArber () {
        require (arbers[msg.sender], "Pool::onlyArber: only approved arber can call this");
        _;
    }


    /** @notice Calculate the expected results for redemption by approved arber
        @param _xTokenIn Amount of XToken input.
        @return _ethOut : the amount of Eth output
        @return _yTokenOutSpot : the amount of YToken output based on Spot price
        @return _requiredEthBalance : required Eth balance in the pool
    */
    function arberCalcRedeem(uint256 _xTokenIn)
        public
        view
        returns (
            uint256 _ethOut,
            uint256 _yTokenOutSpot,
            uint256 _requiredEthBalance
        )
    {
        uint256 _yTokenPrice = oracle.getYTokenPrice();
        require(_yTokenPrice > 0, "Pool::calcRedeem: Invalid YToken price");
        
        uint256 _realCollateralRatio = realCollateralRatio();
        if (_realCollateralRatio > COLLATERAL_RATIO_MAX) {
            _realCollateralRatio = COLLATERAL_RATIO_MAX;
        }

        _requiredEthBalance = (_xTokenIn * _realCollateralRatio) / PRECISION;
        if (_realCollateralRatio < COLLATERAL_RATIO_MAX) { // COLLATERAL_RATIO_MAX == 100%
            _yTokenOutSpot = (_xTokenIn * (COLLATERAL_RATIO_MAX - _realCollateralRatio) * (PRECISION) * PRICE_PRECISION) / COLLATERAL_RATIO_MAX / PRECISION / _yTokenPrice;
        }

        if (_realCollateralRatio > 0) {
            _ethOut = (_xTokenIn * _realCollateralRatio * (PRECISION)) / COLLATERAL_RATIO_MAX / PRECISION;
        }
    }

    /** 
        @notice mint and sell xTokens when over peg, requires that >= 1 WETH per minted xToken is recieved.
        @param _xTokenAmount amount of xTokens to mint and sell
    */
    function arberMint(uint256 _xTokenAmount) external onlyArber {
        uint256 _startWethBalance = WethUtils.weth.balanceOf(address(this));
        uint256[] memory _amountsOut = uniswapV2Router02.getAmountsOut(_xTokenAmount, xTokenWethPath);
        uint256 _ethOut = _amountsOut[_amountsOut.length - 1];
        require(_ethOut >= _xTokenAmount, "Pool::arberMint: mint must result in atleast 100% collateralisation of new xTokens");
        xToken.mint(address(this), _xTokenAmount);
        xToken.safeIncreaseAllowance(address(uniswapV2Router02), _xTokenAmount);
        uniswapV2Router02.swapExactTokensForTokens(_xTokenAmount, _ethOut, xTokenWethPath, address(this), block.timestamp);
        uint256 _wethGained = (WethUtils.weth.balanceOf(address(this))) - (_startWethBalance);
        require (_wethGained >= _ethOut, "Pool::arberMint: mint did not result in 100% collateralization of new xTokens");
        emit ArberMint(block.timestamp, _xTokenAmount, _wethGained);
    }

    function arberBuybackRedeem(uint256 _wethBorrow) external onlyArber {
        require(_wethBorrow <= usableCollateralBalance(), "Pool::arberBuyBackRedeem: borrow exceeds weth balance");
        uint256 _startWethBalance = usableCollateralBalance();
        uint256 _startCR = realCollateralRatio();

        uint256[] memory _amountsOut = uniswapV2Router02.getAmountsOut(_wethBorrow, wethXTokenPath);
        uint256 _xTokenIn = _amountsOut[_amountsOut.length - 1];
        (uint256 _ethOut, uint256 _yTokenOutSpot, uint256 _requiredEthBalance) = arberCalcRedeem(_xTokenIn);
        
        uint256 _wethRecievedFromYSwap;
        if (_yTokenOutSpot > 0) {
            _amountsOut = uniswapV2Router02.getAmountsOut(_yTokenOutSpot, yTokenWethPath);
            _wethRecievedFromYSwap = _amountsOut[_amountsOut.length - 1];
        } else {
            _wethRecievedFromYSwap = 0;
        }

        uint256 _projectedEndWeth = (_startWethBalance - (_wethBorrow)) + (_wethRecievedFromYSwap);
        uint256 _projectedEndXSupply = (getXSupplyAndUnclaimed()) - (_xTokenIn);
        uint256 _projectedCR = (_projectedEndWeth * (1000000)) / (_projectedEndXSupply);
        require(_projectedCR >= _startCR, "Pool::arberBuyBackRedeem: must maintain or improve collateral ratio");

        // Move all external functions to the end
        WethUtils.weth.safeIncreaseAllowance(address(uniswapV2Router02), _wethBorrow);
        uniswapV2Router02.swapExactTokensForTokens(_wethBorrow, _xTokenIn, wethXTokenPath, address(this), block.timestamp);
        
        xToken.burn(_xTokenIn);
        
        if (_yTokenOutSpot > 0) {
            yTokenReserve.transfer(address(this), _yTokenOutSpot);
            yToken.safeIncreaseAllowance(address(uniswapV2Router02), _yTokenOutSpot);
            uniswapV2Router02.swapExactTokensForTokens(_yTokenOutSpot, _wethRecievedFromYSwap, yTokenWethPath, address(this), block.timestamp);
        }
        uint256 _endCR = realCollateralRatio();
        require(_endCR >= _startCR, "Pool::arberBuyBackRedeem: did not maintain or improve collateral ratio");
        emit ArberBuybackRedeemed(block.timestamp, _endCR);
    }


    /**
        @notice Transfer the excess balance of WETH to arber
        @param _amount amount of WETH to reduce
    */
    function arberWithdrawExcessCollateral(uint256 _amount) external onlyArber {
        (uint256 _excessWethBal, bool exceeded) = calcExcessCollateralBalance();
        if (exceeded && _excessWethBal > 0) {
            require(_amount <= _excessWethBal, "Pool::arberWithdrawExcessCollateral: The amount exceeds surplus");
            WethUtils.transfer(msg.sender, _amount);
        }
    }

    // EVENTS
    event OracleChanged(address indexed _oracle);
    event Toggled(bool _mintPaused, bool _redeemPaused);
    event Mint(address minter, uint256 amount, uint256 ethIn, uint256 fee);
    event Redeem(address redeemer, uint256 amount, uint256 ethOut, uint256 yTokenOut, uint256 fee);
    event UpdateCollateralRatioPaused(bool _collateralRatioPaused);
    event NewCollateralRatioOptions(uint256 _ratioStepUp, uint256 _ratioStepDown, uint256 _priceBand, uint256 _refreshCooldown);
    event MinCollateralRatioUpdated(uint256 _minCollateralRatio);
    event NewCollateralRatioSet(uint256 _cr);
    event FeesUpdated(uint256 _mintingFee, uint256 _redemptionFee);
    event Recollateralized(address indexed _sender, uint256 _amount);
    event SwapStrategyChanged(address indexed _swapper);
    event TreasurySet(address indexed _treasury);
    event YTokenSlippageSet(uint256 _slippage);
    event ArberMint(uint256 _timestamp, uint256 _xTokenMinted, uint256 _wethGained);
    event ArberBuybackRedeemed(uint256 _timestamp, uint256 _newCR);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMasterOracle {
    function getXTokenPrice() external view returns (uint256);

    function getYTokenPrice() external view returns (uint256);

    function getYTokenTWAP() external view returns (uint256);

    function getXTokenTWAP() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISwapStrategy {
    function execute(uint256 _wethIn, uint256 _yTokenOut) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXToken is IERC20 {
    function burnFrom(address account, uint256 amount) external;

    function burn(uint256 _amount) external;

    function mint(address _address, uint256 _amount) external;

    function setMinter(address _minter) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYToken is IERC20 {
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IYTokenReserve {
    function transfer(address _address, uint256 _amount) external;

    function setRewarder(address _rewarder) external returns (bool);

    function setPool(address _pool) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWETH.sol";

library WethUtils {
    using SafeERC20 for IWETH;

    IWETH public constant weth = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); //WETH GOERLI

    function isWeth(address token) internal pure returns (bool) {
        return address(weth) == token;
    }

    function wrap(uint256 amount) internal {
        weth.deposit{value: amount}();
    }

    function unwrap(uint256 amount) internal {
        weth.withdraw(amount);
    }

    function transfer(address to, uint256 amount) internal {
        weth.safeTransfer(to, amount);
    }
}