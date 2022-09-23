/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/diamondhands.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;







contract TEAMContract {
    function getPoolAddresses(string memory ticker) public view returns (address) {}
}
contract PerpetualContract {
    function getCurrentPeriod() external view returns (uint256){}
    uint256 public STAKE_START_DAY; // the day when the current stake starts, is updated as each stake starts
    uint256 public STAKE_END_DAY; // the day when the current stake ends, is updated as each stake starts
    uint256 public STAKE_LENGTH;
    function getHexDay() external view returns (uint256){}

}
/*
Diamond Hands Club is a contract that allows holders of the Maximus Perpetual Pool tokens to 
timelock their tokens for the duration of the corresponding HEX stake pool and earn additional rewards. 
This contract is deployed for each of the Perpetual Pools and runs on that pool's stake schedule.
Joining the Diamond Hands Club is fully voluntary and there is a penalty applied to any amount that is unlocked early.
Penalty = amount* 0.0369 * 3696 / stake length

How it works
1. Choose amount you want to lock.
2. Lock in before the Perpetual Pool stake starts by running joinClub(amount) which transfers your Perpetual Pool tokens to the Diamond Hand Contract.
3. If you unlock before the Perpetual Pool stake ends, the penalty applied to the amount early unlocked goes into the Reward Bucket Contract. 
4. After the stake ends, The contents of the Reward Bucket are sent to the Stake Reward Distribution contract and you can reclaim your pool tokens from the DH contract and claim your portion of the rewards from that period from the Stake Reward Distribution Contract containing:
    1. Pool tokens from early unlock penalty
    2. Any TEAM or MAXI that happens to be mysteriously airdropped to the Reward Bucket by motivated TEAM members trying to incentivize perpetual pool participation.


Period 0: Perpetual Pool Minting Phase - ends September 26
What Happens? Users can enter the first timelock period.
Functions available:
- joinClub(amount) commits them into the upcoming stake period
- earlyEndStake(amount) if they have already joined the upcoming stake period

Period 1: Stake Phase
What Happens? Users are locked in, and if they unlock early they experience a penalty that is redistributed to the people that stay locked the whole period.
Functions available:
- joinClub(amount) commits them into the next stake period
- earlyEndStake(amount, stakeID) if they are currently locked into the current stake period or have already joined the upcoming stake period
- extendStake(stakeID) rolls their existing stake into the next stake period

Period 2: Reload Phase
What Happens? After the corresponding perpetual pool stake ends users can reclaim their locked tokens and claim rewards from the prior period. They can also enter the next timelock period.
- joinClub(amount) commits them into the next stake period
- earlyEndStake(amount, stakeID) if they are currently locked into the current stake period or have already joined the upcoming stake period
- restakeExpiredStake(stakeID) rolls their existing stake into the next stake period
- endExpiredStake(stakeID) closes out their existing stake and returns their timelocked tokens.

Period 3:Stake Phase
Period 4: Reload Phase
REPEAT FOREVER

*/
contract DiamondHandsClub is ReentrancyGuard {
    /*
    Post-deployment instructions: 
    1. run deployStakeRewardDistributionContract()
    2. run deployRewardBucketContract()
    */
    event Stake(
        address indexed staker,
        uint256 amount, 
        uint256 current_period,
        uint256 stakeID, 
        bool is_initial);
    event ExtendStake(
        address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    event EarlyEndStake(address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    event EndExpiredStake(address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    event RestakeExpiredStake(address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    address public PERPETUAL_POOL_ADDRESS;
    address public constant TEAM_CONTRACT_ADDRESS=0xB7c9E99Da8A857cE576A830A9c19312114d9dE02;
    TEAMContract TeamContract = TEAMContract(TEAM_CONTRACT_ADDRESS);  
    PerpetualContract PoolContract;
    IERC20 PoolERC;
    uint256 public GLOBAL_AMOUNT_STAKED;  // Running total number of Pool tokens staked by all users. Incremented when any user stakes Pool tokens and decremented when any user end-stakes Pool Tokens.
    mapping (address=> uint256) public USER_AMOUNT_STAKED;// Running total number of Tokens staked per user. Incremented when user stakes Tokens and decremented when user end-stakes Tokens.
    address public STAKE_REWARD_DISTRIBUTION_ADDRESS; // Contract that the reward bucket sends funds to as a staking period ends. Contract that user claims their rewards from.
    address public REWARD_BUCKET_ADDRESS; // Reward Bucket is the address that stores the stake rewards. Penalties are sent from DH Contract to the Reward Bucket. 
    string public TICKER_SYMBOL;
    constructor(string memory ticker) ReentrancyGuard() {
        TICKER_SYMBOL=ticker; // symbol of the Perpetual Pool contract this is deployed for.
        PERPETUAL_POOL_ADDRESS = TeamContract.getPoolAddresses(ticker);
        PoolContract = PerpetualContract(PERPETUAL_POOL_ADDRESS); // used for getCurrentPeriod, etc.
        PoolERC = IERC20(PERPETUAL_POOL_ADDRESS); // used for transfer, balanceOf, etc
    }
    // Supporting Contract Deployment
    // @notice Run this immediately after deployment of the DH Contract.
    function deployStakeRewardDistributionContract() public nonReentrant {
        require(STAKE_REWARD_DISTRIBUTION_ADDRESS==address(0), "already deployed");
        DHStakeRewardDistribution srd = new DHStakeRewardDistribution(address(this));
        STAKE_REWARD_DISTRIBUTION_ADDRESS = address(srd);
    }
    // @notice Run this immediately after deployment of the DH Contract.
    function deployRewardBucketContract() public nonReentrant  {
        require(REWARD_BUCKET_ADDRESS==address(0), "already deployed");
        RewardBucket rb = new RewardBucket(address(this));
        REWARD_BUCKET_ADDRESS = address(rb);
    }
    
   
    /// Staking
    // A StakeRecord is created for each user when they stake into a new period.
    // If a stake record for a user has already been created for a particular period, the existing one will be updated.
    struct StakeRecord {
        address staker; // staker
        uint256 balance; // the remaining balance of the stake.
        uint stakeID; // how a user identifies their stakes. Each period stake increments stakeID.
        uint256 stake_expiry_period; // what period this stake is scheduled to serve through. May be extended to the next staking period during the stake_expiry_period.
        mapping(uint => uint256) stakedTokensPerPeriod; // A record of the number of Tokens that successfully served each staking period during this stake. This number crystallizes as each staking period ends and is used to claim rewards.
        bool initiated;
    }
    mapping (uint => uint256) public globalStakedTokensPerPeriod; // A record of the number of Tokens that are successfully staked for each stake period. Value crystallizes in each period as period ends.
    mapping (address =>mapping(uint => StakeRecord)) public stakes; // Mapping of all users stake records.
    /*
    @notice joinClub(amount) User facing function for staking Tokens. 
    @dev 1) Checks if user balance exceeds input stake amount. 2) Saves stake data via newStakeRecord(). 3) Transfers the staked Tokens to the Diamond Hand Club Contract. 4) Update global and user stake tally.
    @param amount number of Tokens staked, include enough zeros to support 8 decimal units. to stake 1 Token, enter amount = 100000000
    */
    function joinClub(uint256 amount) external nonReentrant {
        require(amount>0, "You must join with more than zero pool tokens");
        require(PoolERC.allowance(msg.sender, address(this))>=amount);
        newStakeRecord(amount); // updates the stake record
        PoolERC.transferFrom(msg.sender, address(this), amount); // sends pool token to Diamond Hand Club contract
        GLOBAL_AMOUNT_STAKED = GLOBAL_AMOUNT_STAKED + amount;
        USER_AMOUNT_STAKED[msg.sender]=USER_AMOUNT_STAKED[msg.sender] + amount;
    }
        /*
        @dev Function that determines which is the next staking period, and creates or updates the users stake record for that period.
        */
        function newStakeRecord(uint256 amount) private {
            uint256 next_staking_period = getNextStakingPeriod(); // the contract period number for each staking period is used as a unique identifier for a stake. 
            StakeRecord storage stake = stakes[msg.sender][next_staking_period]; // retrieves the existing stake record for this upcoming staking period, or render a new one if this is the first time.
            bool is_initial;
            if (stake.initiated==false){ // first time setup. values that should not change if this user stakes again in this period.
                stake.stakeID = next_staking_period;
                stake.initiated = true;
                stake.staker = msg.sender;
                stake.stake_expiry_period = next_staking_period;
                is_initial = true;
            }
            stake.balance = amount + stake.balance;
            stake.stakedTokensPerPeriod[next_staking_period] = amount + stake.stakedTokensPerPeriod[next_staking_period];
            globalStakedTokensPerPeriod[next_staking_period] = amount + globalStakedTokensPerPeriod[next_staking_period];
            emit Stake(msg.sender, amount, getCurrentPeriod(), stake.stakeID, is_initial);
        }
  
    /*
    @notice Calculates the 20% penalty for early end staking an amount.
    */
    function calculatePenalty(uint256 amount) public view returns(uint256) {
        uint256 penalty = amount/5; // 20% penalty = 1/5 of the amount
        return penalty;
    } 
/*
    @notice earlyEndStakeToken(stakeID, amount) User facing function for ending a part or all of a stake either before or during its expiry period. A scaled% penalty is applied to the amount returned to the user and the penalized amount goes to the Reward Bucket.
    @dev checks that they have this stake, updates the stake record via earlyEndStakeRecord() function, updates the global tallies, calculates the early end stake penalty, and returns back the amount requested minus penalty.
    @param stakeID the ID of the stake the user wants to early end stake
    @param amount number of Tokens early end staked, include enough zeros to support 8 decimal units. to end stake 1 Tokens, enter amount = 100000000
    */
    function earlyEndStakeToken(uint256 stakeID, uint256 amount) external nonReentrant {
        earlyEndStakeRecord(stakeID, amount); // update the stake record
        uint256 penalty = calculatePenalty(amount); 
        GLOBAL_AMOUNT_STAKED = GLOBAL_AMOUNT_STAKED - amount;
        USER_AMOUNT_STAKED[msg.sender]=USER_AMOUNT_STAKED[msg.sender] - amount;
        PoolERC.transfer(msg.sender,amount-penalty);
        PoolERC.transfer(REWARD_BUCKET_ADDRESS,penalty);
    }
         /*
        @dev Determines if stake is pending, or in progress and updates the record to reflect the amount of Tokens that remains actively staked from that particular stake.
        @param stakeID the ID of the stake the user wants to early end stake
        @param amount number of Tokens early end staked, include enough zeros to support 8 decimal units. to end stake 1 Tokens, enter amount = 100000000
        */
        function earlyEndStakeRecord(uint256 stakeID, uint256 amount) private {
            uint256 current_period = getCurrentPeriod();
            uint256 next_staking_period = getNextStakingPeriod();
            StakeRecord storage stake = stakes[msg.sender][stakeID];
            require(stake.initiated==true, "You must enter an existing stake period");
            require(stake.stake_expiry_period>=current_period, "The stake period must be active."); // must be before the stake has expired
            require(stake.balance>=amount);
            stake.balance = stake.balance - amount;
            // Decrement staked Tokens from next staking period
            if (stake.stakedTokensPerPeriod[next_staking_period]>0){
                globalStakedTokensPerPeriod[next_staking_period]=globalStakedTokensPerPeriod[next_staking_period]-amount;
                stake.stakedTokensPerPeriod[next_staking_period]=stake.stakedTokensPerPeriod[next_staking_period]-amount;
            }
            // Decrement staked Tokens from current staking period.
            if (stake.stakedTokensPerPeriod[current_period]>0) {
                globalStakedTokensPerPeriod[current_period]=globalStakedTokensPerPeriod[current_period]-amount;
                stake.stakedTokensPerPeriod[current_period]=stake.stakedTokensPerPeriod[current_period]-amount;
            }
            emit EarlyEndStake(msg.sender, amount, stake.stake_expiry_period, stakeID);
        }
    /*
    @notice End a stake which has already served its full staking period. This function updates your stake record and returns your staked Tokens back into your address.
    @param stakeID the ID of the stake the user wants to end stake
    @param amount number of Tokens end staked, include enough zeros to support 8 decimal units. to end stake 1 Tokens, enter amount = 100000000
            
    */
    function endCompletedStake(uint256 stakeID, uint256 amount) external nonReentrant {
        endExpiredStake(stakeID, amount);
        GLOBAL_AMOUNT_STAKED = GLOBAL_AMOUNT_STAKED - amount;
        USER_AMOUNT_STAKED[msg.sender]=USER_AMOUNT_STAKED[msg.sender] - amount;
        PoolERC.transfer(msg.sender, amount);
    }
        function endExpiredStake(uint256 stakeID, uint256 amount) private {
            uint256 current_period=getCurrentPeriod();
            StakeRecord storage stake = stakes[msg.sender][stakeID];
            require(stake.stake_expiry_period<current_period);
            require(stake.balance>=amount);
            stake.balance = stake.balance-amount;
            emit EndExpiredStake(msg.sender, amount, stake.stake_expiry_period, stakeID);
        }

    /*
    @notice This function extends a currently active stake into the next staking period. It can only be run during the expiry period of a stake. This extends the entire stake into the next period.
    @param stakeID the ID of the stake the user wants to extend into the next staking period.
        */
        function extendStake(uint256 stakeID) external nonReentrant {
            uint256 current_period=getCurrentPeriod();
            uint256 next_staking_period = getNextStakingPeriod();
            StakeRecord storage stake = stakes[msg.sender][stakeID];
            require(isStakingPeriod());
            require(stake.stake_expiry_period==current_period);
            stake.stake_expiry_period=next_staking_period;
            stake.stakedTokensPerPeriod[next_staking_period] = stake.stakedTokensPerPeriod[next_staking_period] + stake.balance;
            globalStakedTokensPerPeriod[next_staking_period] = globalStakedTokensPerPeriod[next_staking_period] + stake.balance;
            emit ExtendStake(msg.sender, stake.balance, next_staking_period, stakeID);
        }
    /*
    @notice This function ends and restakes a stake which has been completed (if current period is greater than stake expiry period). It ends the stake but does not return your Tokens, instead it rolls those Tokens into a brand new stake record starting in the next staking period.
    @param stakeID the ID of the stake the user wants to extend into the next staking period.
    */
    function restakeExpiredStake(uint256 stakeID) public nonReentrant {
        uint256 current_period=getCurrentPeriod();
        StakeRecord storage stake = stakes[msg.sender][stakeID];
        require(stake.stake_expiry_period<current_period);
        require(stake.balance > 0);
        newStakeRecord(stake.balance);
        uint256 amount = stake.balance;
        stake.balance = 0;
        emit RestakeExpiredStake(msg.sender, amount, stake.stake_expiry_period, stakeID);
    }
    function getAddressPeriodEndTotal(address staker_address, uint256 period, uint stakeID) public view returns (uint256) {
        StakeRecord storage stake = stakes[staker_address][stakeID];
        return stake.stakedTokensPerPeriod[period]; 
    }
    function getglobalStakedTokensPerPeriod(uint256 period) public view returns(uint256){
        return globalStakedTokensPerPeriod[period];
    }
   
    /// Utilities
    /*
    @notice The current period of the Diamond Hands Contract is the current period of the corresponding Perpetual Pool Contract.
    */
    function getCurrentPeriod() public view returns (uint current_period){
        return PoolContract.getCurrentPeriod(); 
    }
    
    function isStakingPeriod() public view returns (bool) {
        uint remainder = getCurrentPeriod()%2;
        if(remainder==0){
            return false;
        }
        else {
            return true;
        }
    }

    function getNextStakingPeriod() private view returns(uint256) {
        uint256 current_period=getCurrentPeriod();
        uint256 next_staking_period;
        if (isStakingPeriod()==true) {
            next_staking_period = current_period+2;
        }
        else {
            next_staking_period=current_period+1;
        }
        return next_staking_period;
    }
}
contract RewardBucket is ReentrancyGuard {
    /*
    Deployment instructions: 
    1. run activate()
    */
    address public PERPETUAL_POOL_ADDRESS;
    address public constant TEAM_CONTRACT_ADDRESS=0xB7c9E99Da8A857cE576A830A9c19312114d9dE02;
    PerpetualContract PoolContract;
    IERC20 PoolERC;
    TEAMContract TeamContract = TEAMContract(TEAM_CONTRACT_ADDRESS);
    address public STAKE_REWARD_DISTRIBUTION_ADDRESS;
    DiamondHandsClub DHContract;
    constructor(address dhc_address) ReentrancyGuard() {
        DHContract = DiamondHandsClub(dhc_address);
    } 
    /*
    @notice This function must be run right after deployment
    */
    function activate() public nonReentrant {
        require(PERPETUAL_POOL_ADDRESS==address(0)); 
        PERPETUAL_POOL_ADDRESS=DHContract.PERPETUAL_POOL_ADDRESS();
        PoolContract = PerpetualContract(PERPETUAL_POOL_ADDRESS); // used for getCurrentPeriod, etc.
        PoolERC = IERC20(PERPETUAL_POOL_ADDRESS); // used for transfer, balanceOf, etc
        STAKE_REWARD_DISTRIBUTION_ADDRESS=DHContract.STAKE_REWARD_DISTRIBUTION_ADDRESS();
        require(STAKE_REWARD_DISTRIBUTION_ADDRESS!=address(0));
        declareSupportedTokens();
    }
    /// Rewards Allocation   
    // Income received by the TEAM Contract in tokens from the below declared supported tokens list are split up and claimable
    mapping (string => address) supportedTokens;
    /*
    @dev Declares which tokens that will be supported by the reward distribution contract.
    */
    address constant MAXI_ADDRESS = 0x0d86EB9f43C57f6FF3BC9E23D8F9d82503f0e84b;
    address constant HEX_ADDRESS  = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39; // "2b, 5 9 1e? that is the question..."
    address constant HEDRON_ADDRESS = 0x3819f64f282bf135d62168C1e513280dAF905e06; 
    
    function declareSupportedTokens() private {
        supportedTokens["HEX"] = HEX_ADDRESS;
        supportedTokens["MAXI"]=MAXI_ADDRESS;
        supportedTokens["HDRN"]=HEDRON_ADDRESS;
        supportedTokens["BASE"]=TeamContract.getPoolAddresses("BASE");
        supportedTokens["TRIO"]=TeamContract.getPoolAddresses("TRIO");
        supportedTokens["LUCKY"]=TeamContract.getPoolAddresses("LUCKY");
        supportedTokens["DECI"]=TeamContract.getPoolAddresses("DECI");
        supportedTokens["TEAM"]=TEAM_CONTRACT_ADDRESS;
        supportedTokens["ICSA"]=0xfc4913214444aF5c715cc9F7b52655e788A569ed;
        
    }
    mapping (string => mapping (uint => bool)) public didRecordPeriodEndBalance; // didRecordPeriodEndBalance[TICKER][period]
    mapping (string =>mapping (uint => uint256)) public periodEndBalance; //periodEndBalance[TICKER][period]
    mapping (string => mapping (uint => uint256)) public periodRedemptionRates; //periodRedemptionRates[TICKER][period] Number of coins claimable per team staked 
    /*
    @notice This function checks to make sure that a staking period just ended, and then measures and saves the Tokens Contracts balance of the designated token.
    @param ticker is the ticker that is to be 
    */ 
    function prepareClaim(string memory ticker) external nonReentrant {
        require(DHContract.isStakingPeriod()==false);
        uint256 latest_staking_period = DHContract.getCurrentPeriod()-1;
        require(didRecordPeriodEndBalance[ticker][latest_staking_period]==false);
        periodEndBalance[ticker][latest_staking_period] = IERC20(supportedTokens[ticker]).balanceOf(address(this)); //measures how many of the designated token are in the Tokens contract address
        IERC20(supportedTokens[ticker]).transfer(STAKE_REWARD_DISTRIBUTION_ADDRESS, periodEndBalance[ticker][latest_staking_period]);
        didRecordPeriodEndBalance[ticker][latest_staking_period]=true;
        uint256 scaled_rate = periodEndBalance[ticker][latest_staking_period] *(10**8)/DHContract.getglobalStakedTokensPerPeriod(latest_staking_period);
        periodRedemptionRates[ticker][latest_staking_period] = scaled_rate;
    }
    
    function getPeriodRedemptionRates(string memory ticker, uint256 period) public view returns (uint256) {
        return periodRedemptionRates[ticker][period];
    }
    
    function getSupportedTokens(string memory ticker) public view returns(address) {
            return supportedTokens[ticker];
        }

    function getClaimableAmount(address user, uint256 period, string memory ticker, uint stakeID) public view returns (uint256, address) {
        uint256 total_amount_succesfully_staked = DHContract.getAddressPeriodEndTotal(user, period, stakeID);
        uint256 redeemable_amount = getPeriodRedemptionRates(ticker,period) * total_amount_succesfully_staked / (10**8);
        return (redeemable_amount, getSupportedTokens(ticker));
    }
    
}
contract DHStakeRewardDistribution is ReentrancyGuard {
    /*
    Deployment insttructions: 
    1. run activate()
    2. run prepareSupportedTokens()
    */
    address public REWARD_BUCKET_ADDRESS;
    RewardBucket RewardBucketContract;
    address public DHC_ADDRESS;
    DiamondHandsClub DHContract; 
    mapping (string => address) public supportedTokens;
    mapping (address => mapping(uint => mapping(uint => mapping (string => bool)))) public didUserStakeClaimFromPeriod; // log which periods and which tokens a user's stake has claimed rewards from
    constructor(address dhc_address) ReentrancyGuard(){
      DHC_ADDRESS=dhc_address;
      DHContract = DiamondHandsClub(DHC_ADDRESS); 
    }
    /*
    Upon deployment we must collect the Reward bucket address from the DH Contract
    */
    function activate() public nonReentrant {
        require(REWARD_BUCKET_ADDRESS==address(0));
        REWARD_BUCKET_ADDRESS = DHContract.REWARD_BUCKET_ADDRESS();
        require(REWARD_BUCKET_ADDRESS!=address(0));
        RewardBucketContract = RewardBucket(REWARD_BUCKET_ADDRESS);
        
    }
    /*
    @notice Claim Rewards in the designated ticker for a period served by a stake record designated by stake ID. You can only run this function if you have not already claimed and if you have redeemable rewards for that coin from that period.
    @param period is the period you want to claim rewards from
    @param ticker is the ticker symbol for the token you want to claim
    @param stakeID is the stakeID of the stake record that contains Tokens that was succesfully staked during the period you input.
    */
    function claimRewards(uint256 period, string memory ticker, uint stakeID) nonReentrant external {
        (uint256 redeemable_amount, address token_address) = RewardBucketContract.getClaimableAmount(msg.sender,period, ticker, stakeID);
        require(didUserStakeClaimFromPeriod[msg.sender][stakeID][period][ticker]==false, "You must not have already claimed from this stake on this period.");
        require(redeemable_amount>0, "No rewards from this period.");
        IERC20(token_address).transfer(msg.sender, redeemable_amount);
        didUserStakeClaimFromPeriod[msg.sender][stakeID][period][ticker]=true;
    }

    /*
    @notice Run this function to retrieve and save all of the supported token addresses from the Tokens contract into the Stake Reward Distribution contract. This should be run once after the supported tokens are declared in the team contract.
    */
    function prepareSupportedTokens() nonReentrant public {
        collectSupportedTokenAddress("HEX");
        collectSupportedTokenAddress("MAXI");
        collectSupportedTokenAddress("HDRN");
        collectSupportedTokenAddress("BASE");
        collectSupportedTokenAddress("TRIO");
        collectSupportedTokenAddress("LUCKY");
        collectSupportedTokenAddress("DECI");
        collectSupportedTokenAddress("TEAM");
        collectSupportedTokenAddress("ICSA");
    }
    function collectSupportedTokenAddress(string memory ticker) private {
        require(supportedTokens[ticker]==address(0));
        supportedTokens[ticker]=RewardBucketContract.getSupportedTokens(ticker);
    }
}