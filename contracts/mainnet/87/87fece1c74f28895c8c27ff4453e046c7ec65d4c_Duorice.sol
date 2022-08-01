/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity 0.8.0;


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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
contract ERC20 is Context, IERC20, IERC20Metadata, ReentrancyGuard {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name = "Duorice";
    string private _symbol = "LAVAE";

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    // constructor(string memory name_, string memory symbol_) {
    //     _name = name_;
    //     _symbol = symbol_;
    // }

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}


contract Duorice is ERC20, Ownable {
    using SafeMath for uint256;

    event UserStake(
        address indexed addr,
        uint256 timestamp,
        uint256 rawAmount,
        uint256 duration
    );

    event UserStakeCollect(
        address indexed addr,
        uint256 timestamp,
        uint256 rawAmount
    );

    event UserLobby(
        address indexed addr,
        uint256 timestamp,
        uint256 rawAmount
    );

    event UserLobbyCollect(
        address indexed addr,
        uint256 timestamp,
        uint256 rawAmount
    );

    event stake_sell_request(
        address indexed addr,
        uint256 timestamp,
        uint256 price,
        uint256 rawAmount,
        uint256 stakeId
    );

    event stake_loan_request(
        address indexed addr,
        uint256 timestamp,
        uint256 rawAmount,
        uint256 duration,
        uint256 stakeId
    );

    event stake_lend(
        address indexed addr,
        uint256 timestamp,
        uint256 stakeId
    );

    event stake_loan(
        address indexed addr,
        uint256 timestamp,
        uint256 stakeId,
        uint256 value
    );

    event day_lobby_entry(
        uint256 timestamp,
        uint256 day,
        uint256 value
    );

				   
										  
	 
	

    /* Address of flush accs */
    address internal constant avariceTeam_addr = 0x8136046f7eCbaAEB675A658772Aa2594A8D4b254; // 
																									 
																																																 
    address internal marketing_addr = 0x7D8C5B47F8227568Be66237031E0b398fF702c48;
    address internal buyBack_addr = 0x90F85C51CCE45b5bcE6A8036e1D23ce9BBEdea81;

																															  
												  

    /* % from every day's lobby entry dedicated to avarice team, marketing and buy back */
    uint256 internal constant DM_avariceTeam_percentage = 5;      
    uint256 internal constant DM_marketing_percentage = 1;      
    uint256 internal constant DM_buyBack_percentage = 1;      

															   
																   

														   
													   

    /* Max staking days */
    uint256 internal constant max_stake_days = 300;  

    /* Ref bonus NR, ex. 20 = 5% */
    uint256 internal constant ref_bonus_NR = 20;  

    /* Refered person bonus NR, ex. 100 = 1% */
    uint256 internal constant ref_bonus_NRR = 100;  

    /* dividends pool caps at 60 days, meaning that the lobby entery of days > 60 will only devide for next 60 days and no more */
    uint256 internal constant dividendsPoolCapDays = 60;  

    /* Allowing the dev to flush the first lobby day */
    bool public firstDayFlushed = false;  

    /* Loaning feature is paused? */
    bool public loaningIsPaused = true; 

    /* Stake selling feature is paused? */
    bool public stakeSellingIsPaused = true; 

    uint256 public constant defaultLobby = 3000000 * 1e18;

    /* ------------------ for the sake of UI statistics ------------------ */
    // lobby memebrs overall data 
    struct memberLobby_overallData{
        uint256 overall_collectedTokens;
        uint256 overall_lobbyEnteries;
        uint256 overall_stakedTokens;
        uint256 overall_collectedDivs;
    }
    // new map for every user's overall data  
    mapping(address => memberLobby_overallData) public mapMemberLobby_overallData;
    // total lobby entry  
    uint256 public overall_lobbyEntry;
    // total staked tokens  
    uint256 public overall_stakedTokens;
    // total lobby token collected  
    uint256 public overall_collectedTokens;
    // total stake divs collected  
    uint256 public overall_collectedDivs;
    // total bonus token collected  
    uint256 public overall_collectedBonusTokens;
    // total referrer bonus paid to an address  
    mapping(address => uint256) public referrerBonusesPaid;
    // counting unique (unique for every day only) lobby enteries for each day
    mapping(uint256 => uint256) public usersCountDaily;
    // counting unique (unique for every day only) users
    uint256 public usersCount = 0;
    /* Total ever entered as stake tokens */ 
    uint256 public saveTotalToken;
    /* ------------------ for the sake of UI statistics ------------------ */


    /* lobby memebrs data */ 
    struct memberLobby{
        uint256 memberLobbyValue;
									
        bool hasCollected;
        address referrer;
    }

    /* new map for every entry (users are allowed to enter multiple times a day) */ 
    mapping(address => mapping(uint256 => memberLobby)) public mapMemberLobby;

    /* day's total lobby entry */ 
    mapping(uint256 => uint256) public lobbyEntry;          


    /* User stakes struct */ 
    struct memberStake {
        address userAddress;
        uint256 tokenValue;
        uint256 startDay;
        uint256 endDay;
        uint256 stakeId;
        uint256 price; // use: sell stake
        uint256 loansReturnAmount; // total of the loans return amount that have been taken on this stake 
        bool stakeCollected;
        bool stake_hasSold; // stake been sold ?
        bool stake_forSell; // currently asking to sell stake ?
        bool stake_hasLoan; // is there an active loan on stake ?
        bool stake_forLoan; // currently asking for a loan on the stake ?
    }

    /* A map for each user */ 
    mapping(address => mapping(uint256 => memberStake)) public mapMemberStake;

    /* Total active tokens in stake for a day */ 
    mapping(uint256 => uint256) public daysActiveInStakeTokens;
    mapping(uint256 => uint256) public daysActiveInStakeTokensIncrese;
    mapping(uint256 => uint256) public daysActiveInStakeTokensDecrase;

    /* Time of contract launch */
    uint256 public LAUNCH_TIME;   
    uint256 currentDay;
    bool public launched;

    constructor() {
        _mint(msg.sender, defaultLobby);
        LAUNCH_TIME = block.timestamp.add(180 days);
        launched = false;
    }

    function launch() public onlyOwner(){
        require(launched == false,"contract already launched!");
		LAUNCH_TIME = block.timestamp.sub(1 days);
        launched = true;
    } 

    /* Owner switching the loaning feature status */
    function switchLoaningStatus() external onlyOwner() {
        if (loaningIsPaused == true) {
            loaningIsPaused = false;
        } 
        else if (loaningIsPaused == false) {
            loaningIsPaused = true;
        }
    }
    
    /* Owner switching the stake selling feature status */
    function switchStakeSellingStatus() external onlyOwner() {
        if (stakeSellingIsPaused == true) {
            stakeSellingIsPaused = false;
        } 
        else if (stakeSellingIsPaused == false) {
            stakeSellingIsPaused = true;
        }
    }

    /* Flushed the 1st day's lobby entry to dev address (since there could be no users with tokens on day 1 and therefor no active stakes) */ 
    function flushFirstDayLobbyEntry(uint256 at) external onlyOwner() nonReentrant {
        require(firstDayFlushed == false);
        firstDayFlushed = true;

        payable(avariceTeam_addr).transfer((lobbyEntry[at] * 93) /100);  
    }

    /* turning off the first day flush functionality */ 
      function flushFirstDayLobbyEntrySwitch() external onlyOwner() {
        if (firstDayFlushed == true) {
            firstDayFlushed = false;
        } 
        else if (firstDayFlushed == false) {
            firstDayFlushed = true;
        }
    }
      
    
    /* change marketing wallet address % */ 
    function do_changeMarketingAddress(address adr) external onlyOwner() {
        marketing_addr = adr;
    }

    /**
     * @dev flushes the dev share from stake sells
     */
    function flushdevShareOfStakeSells() external onlyOwner() nonReentrant {
        require(devShareOfStakeSellsAndLoanFee > 0);
        
        payable(marketing_addr).transfer(devShareOfStakeSellsAndLoanFee);
        devShareOfStakeSellsAndLoanFee = 0;
    }


								 
														  
					   

    function _clcDay() public view returns (uint256) {
        return (block.timestamp - LAUNCH_TIME) / (1 days);
    }

    function _updateDaily() public {
        if(currentDay == _clcDay()){
            return;
        }
        // this is true once a day
        
        if (currentDay < dividendsPoolCapDays) {
            for(uint256 _day = currentDay + 1 ; _day <= currentDay * 2 ; _day++){
                dayBNBPool[_day] += (lobbyEntry[currentDay] * 93 ) / (currentDay * 100);
            }

													
																					 
																							
				 

        } else {
            for(uint256 _day = currentDay + 1 ; _day <= currentDay + dividendsPoolCapDays ; _day++){
                dayBNBPool[_day] += (lobbyEntry[currentDay] * 93 ) / (dividendsPoolCapDays * 100);
				 
            }
        }
								   
							   

        currentDay = _clcDay();
							
								  
								  
											   
									

        // total of 7% from every day's lobby entry goes to:
        _sendDevShare();
        // 1% marketing share 
        _sendMarketingShare();
        // 1% buy back to current lobby day
        _buyLobbyBuybackShare();
	 

        emit day_lobby_entry(
            block.timestamp,
            currentDay,
            lobbyEntry[currentDay -1]
        );
        
    }

    /* Gets called once a day and withdraws avarice team's share for the privious day of lobby */ 
    function _sendDevShare() internal nonReentrant {
        require(currentDay > 0);

        // avariceTeamPercentage = 5% of every day's lobby entry
        uint256 avariceTeamPercentage = (lobbyEntry[currentDay - 1] * DM_avariceTeam_percentage) /100;
    
								
        payable(avariceTeam_addr).transfer(avariceTeamPercentage);
																				
																				
																				
    }

    /* Gets called once a day and withdraws marketing's share for the privious day of lobby */ 
    function _sendMarketingShare() internal nonReentrant {
        require(currentDay > 0);

        // marketing share = 1% of every day's lobby entry
        payable(marketing_addr).transfer((lobbyEntry[currentDay - 1] * DM_marketing_percentage) /100);
    }

    /* Gets called once a day and withdraws buy back share for the privious day of lobby */ 
    function _buyLobbyBuybackShare() internal nonReentrant {
        require(currentDay > 0);

        // buyback share = 1% of every day's lobby entry
        payable(buyBack_addr).transfer((lobbyEntry[currentDay - 1] * DM_buyBack_percentage) /100);
    }




    /**
     * @dev External function for entering the auction lobby for the current day
     * @param referrerAddr address of referring user (optional; 0x0 for no referrer)
     */
    function EnterLobby(address referrerAddr) external payable {
        uint256 rawAmount = msg.value;
        require(rawAmount > 0, "ERR: Amount required");

        _updateDaily();
        require(currentDay > 0);
    
        if (mapMemberLobby[msg.sender][currentDay].memberLobbyValue == 0) {
            usersCount++;
            usersCountDaily[currentDay]++;
        }

        mapMemberLobby_overallData[msg.sender].overall_lobbyEnteries += rawAmount;
        lobbyEntry[currentDay] += rawAmount;
        overall_lobbyEntry += rawAmount;

																				  
        mapMemberLobby[msg.sender][currentDay].memberLobbyValue += rawAmount; 
																				
        mapMemberLobby[msg.sender][currentDay].hasCollected = false;

        if (referrerAddr != msg.sender) {
            /* No Self-referred */
            mapMemberLobby[msg.sender][currentDay].referrer = referrerAddr;
        } else {
            mapMemberLobby[msg.sender][currentDay].referrer = address(0);
        }
        
        emit UserLobby(
            msg.sender, 
            block.timestamp,
            rawAmount
        );
    }
    

    /**
     * @dev External function for leaving the lobby / collecting the tokens
     * @param targetDay Target day of lobby to collect 
     */
    function ExitLobby(uint256 targetDay) external {
        require(mapMemberLobby[msg.sender][targetDay].hasCollected == false, "ERR: Already collected");
        _updateDaily();
        require(targetDay < currentDay);

        uint256 tokensToPay = _clcTokenValue(msg.sender, targetDay);

        _mint(msg.sender, tokensToPay);
        mapMemberLobby[msg.sender][targetDay].hasCollected = true;
        
        overall_collectedTokens += tokensToPay;
        mapMemberLobby_overallData[msg.sender].overall_collectedTokens += tokensToPay;

        address referrerAddress = mapMemberLobby[msg.sender][targetDay].referrer;
        if (referrerAddress != address(0)) {
            /* there is a referrer, pay their % ref bonus of tokens */ 
            uint256 refBonus = tokensToPay /ref_bonus_NR;

            _mint(referrerAddress, refBonus);  
            referrerBonusesPaid[referrerAddress] += refBonus;

            /* pay the referred user bonus */
            _mint(msg.sender, tokensToPay /ref_bonus_NRR); 
        }

        emit UserLobbyCollect(
            msg.sender, 
            block.timestamp,
            tokensToPay
        );
    }


    /**
     * @dev Calculating user's share from lobby based on their entry value
     * @param _Day The lobby day
     */
    function _clcTokenValue (address _address, uint256 _Day) public view returns (uint256) {
        require(_Day != 0, "ERR");
        uint256 _tokenVlaue;
																			  


        if(_Day != 0 && _Day < currentDay) {
            _tokenVlaue = (tokenForDay(_Day) / lobbyEntry[_Day]) * mapMemberLobby[_address][_Day].memberLobbyValue; 
        }else{
            _tokenVlaue = 0;
        }
        
        return _tokenVlaue;
    }

    function tokenForDay(uint256 _day) public view returns (uint256 value_) {
        if(_day < 1){
            value_ = 0;
        } else{
            _day = _day - 1;
            if(_day > max_stake_days){
                _day = max_stake_days;
            }
            value_ = defaultLobby;
            for(uint i=0;i<_day;i++){
                value_ = value_.add(value_.mul(2).div(100));
            }
        }
    }

    mapping(uint256 => uint256)public dayBNBPool;
    mapping(uint256 => uint256)public enterytokenMath;
    mapping(uint256 => uint256)public totalTokensInActiveStake;
   
    /**
     * @dev External function for users to create a stake
     * @param amount Amount of AVC tokens to stake
     * @param stakingDays Stake duration in days
     */

    
    function EnterStake(uint256 amount, uint256 stakingDays) external {
        require(stakingDays >= 1, 'Staking: Staking days < 1');
        require(stakingDays <= max_stake_days, 'Staking: Staking days > max_stake_days');
        require(amount > 0, "Staking: Amount required");
        require(balanceOf(msg.sender) >= amount, 'Not enough balance');
        
        _updateDaily();
        uint256 stakeId = calcStakeCount(msg.sender);

        overall_stakedTokens += amount;
        mapMemberLobby_overallData[msg.sender].overall_stakedTokens += amount;

        mapMemberStake[msg.sender][stakeId].stakeId = stakeId;
        mapMemberStake[msg.sender][stakeId].userAddress = msg.sender;
        mapMemberStake[msg.sender][stakeId].tokenValue = amount;
        mapMemberStake[msg.sender][stakeId].startDay = currentDay + 1 ;
        mapMemberStake[msg.sender][stakeId].endDay = currentDay + 1 + stakingDays;
        mapMemberStake[msg.sender][stakeId].stakeCollected = false;
        mapMemberStake[msg.sender][stakeId].stake_hasSold = false;
        mapMemberStake[msg.sender][stakeId].stake_hasLoan = false;
        mapMemberStake[msg.sender][stakeId].stake_forSell = false;
        mapMemberStake[msg.sender][stakeId].stake_forLoan = false;
        // stake calcs for days: X >= startDay && X < endDay
        // startDay included / endDay not included

        for (uint256 i = currentDay + 1; i <= currentDay + stakingDays; i++) {
            totalTokensInActiveStake[i] += amount;
        }

        saveTotalToken += amount;
        daysActiveInStakeTokensIncrese[currentDay + 1] += amount;
        daysActiveInStakeTokensDecrase[currentDay + stakingDays + 1] += amount;

        /* On stake AVC tokens get burned */
        _burn(msg.sender, amount);

        emit UserStake (
            msg.sender, 
            block.timestamp,
            amount, 
            stakingDays
        );
    }

    
    /**
     * @dev Counting user's stakes to be usead as stake id for a new stake
     * @param _address address of the user
     */
    function calcStakeCount(address _address) public view returns (uint256) {
        uint256 stakeCount = 0;

        for (uint256 i = 0; mapMemberStake[_address][i].userAddress == _address; i++) {
            stakeCount += 1;
        }

        return(stakeCount);
    }
    

    /**
     * @dev External function for collecting a stake
     * @param stakeId Id of the target stake
     */
    function EndStake(uint256 stakeId) external nonReentrant {
        require(mapMemberStake[msg.sender][stakeId].endDay <= currentDay, 'Stakes end day not reached yet');
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender,'invalid sender');
        require(mapMemberStake[msg.sender][stakeId].stakeCollected == false,'has collected');
        require(mapMemberStake[msg.sender][stakeId].stake_hasLoan == false,'has loan');
        require(mapMemberStake[msg.sender][stakeId].stake_hasSold == false,'has sold');

        _updateDaily();

        /* if the stake is for sell, set it false since it's collected */
        mapMemberStake[msg.sender][stakeId].stake_forSell = false;
        mapMemberStake[msg.sender][stakeId].stake_forLoan = false;

        /* clc BNB divs */
        uint256 profit = calcStakeCollecting(msg.sender, stakeId);
        overall_collectedDivs += profit;
        mapMemberLobby_overallData[msg.sender].overall_collectedDivs += profit;

        mapMemberStake[msg.sender][stakeId].stakeCollected = true;
        payable(msg.sender).transfer(profit);
        
        uint256 stakeReturn = mapMemberStake[msg.sender][stakeId].tokenValue;

        /* Pay the bonus token and stake return, if any, to the staker */
        if (stakeReturn != 0) {
            uint256 bonusAmount = calcBonusToken(mapMemberStake[msg.sender][stakeId].endDay, mapMemberStake[msg.sender][stakeId].startDay, stakeReturn);

            overall_collectedBonusTokens += bonusAmount;

            _mint(msg.sender, stakeReturn + bonusAmount);
        }

        emit UserStakeCollect(
            msg.sender, 
            block.timestamp,
            profit
        );
    }


    /**
     * @dev Calculating a stakes BNB divs payout value by looping through each day of it 
     * @param _address User address
     * @param _stakeId Id of the target stake
     */
    function calcStakeCollecting(address _address , uint256 _stakeId) public view returns (uint256) {
        uint256 userDivs;
        uint256 _endDay = mapMemberStake[_address][_stakeId].endDay;
        uint256 _startDay = mapMemberStake[_address][_stakeId].startDay;
        uint256 _stakeValue = mapMemberStake[_address][_stakeId].tokenValue;

        for (uint256 _day = _startDay ; _day < _endDay && _day < currentDay; _day++) { 
            userDivs += (dayBNBPool[_day] * _stakeValue) / totalTokensInActiveStake[_day]  ;
        }

        return (userDivs - mapMemberStake[_address][_stakeId].loansReturnAmount);
    }


    /**
     * @dev Calculating a stakes Bonus AVC tokens based on stake duration and stake amount
											
     * @param StakeAmount The stake's AVC tokens amount
     */
    function calcBonusToken (uint256 endDay ,uint256 startDay, uint256 StakeAmount) public view returns (uint256) {        
        require(endDay>startDay,'Staking: startDay > endDay');
        require(startDay > 0,'Staking: startDay < 1');
        uint256 StakeDuration = endDay - startDay;
        require(StakeDuration <= max_stake_days, 'Staking: Staking days > max_stake_days');
        uint256 startAmount = tokenForDay(startDay);
        uint256 endAmount = tokenForDay(endDay);

        uint256 _bonusAmount = endAmount.mul(1e18).div(startAmount);
        _bonusAmount = _bonusAmount.sub(1e18).mul(120).div(100);
        _bonusAmount = StakeAmount.mul(_bonusAmount).div(1e18);
        return _bonusAmount;
    }

																						   
																			
									 

						 

												
																	   
								 
				
			
						
		
	


    /**
     * @dev calculating user dividends for a specific day
     */
    
    
    uint256 public devShareOfStakeSellsAndLoanFee;
    uint256 public totalStakesSold;
    uint256 public totalTradeAmount;

    /* withdrawable funds for the stake seller address */
    mapping(address => uint256) public soldStakeFunds;
    mapping(address => uint256) public totalStakeTradeAmount;

    /**
     * @dev User putting up their stake for sell or user changing the previously setted sell price of their stake
     * @param stakeId stake id
     * @param price sell price for the stake
     */
    function sellStakeRequest(uint256 stakeId , uint256 price) external {
        _updateDaily();

        require(stakeSellingIsPaused == false, 'functionality is paused');
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender, 'auth failed');
        require(mapMemberStake[msg.sender][stakeId].stake_hasLoan == false, 'Target stake has an active loan on it');
        require(mapMemberStake[msg.sender][stakeId].stake_hasSold == false, 'Target stake has been sold');
        require(mapMemberStake[msg.sender][stakeId].endDay > currentDay, 'Target stake is ended');

        /* if stake is for loan, remove it from loan requests */
        if (mapMemberStake[msg.sender][stakeId].stake_forLoan == true) {
            cancelStakeLoanRequest(stakeId);
        }

        require(mapMemberStake[msg.sender][stakeId].stake_forLoan == false);

        mapMemberStake[msg.sender][stakeId].stake_forSell = true;
        mapMemberStake[msg.sender][stakeId].price = price;

        emit stake_sell_request (
            msg.sender, 
            block.timestamp,
            price,
            mapMemberStake[msg.sender][stakeId].tokenValue,
            stakeId
        );
    } 
 

    /**
     * @dev A user buying a stake
     * @param sellerAddress stake seller address (current stake owner address)
     * @param stakeId stake id
     */
    function buyStakeRequest(address sellerAddress , uint256 stakeId) external payable {
        _updateDaily();

        require(stakeSellingIsPaused == false, 'functionality is paused');
        require(mapMemberStake[sellerAddress][stakeId].userAddress != msg.sender, 'no self buy'); 
        require(mapMemberStake[sellerAddress][stakeId].userAddress == sellerAddress, 'auth failed'); 
        require(mapMemberStake[sellerAddress][stakeId].stake_hasSold == false, 'Target stake has been sold');
        require(mapMemberStake[sellerAddress][stakeId].stake_forSell == true, 'Target stake is not for sell');
        uint256 priceP = msg.value;
        require(mapMemberStake[sellerAddress][stakeId].price == priceP, 'not enough funds');
        require(mapMemberStake[sellerAddress][stakeId].endDay > currentDay);

        /* 10% stake sell fee ==> 2% dev share & 8% buy back to the current day's lobby */
        lobbyEntry[currentDay] += (mapMemberStake[sellerAddress][stakeId].price * 8) / 100;
        devShareOfStakeSellsAndLoanFee += (mapMemberStake[sellerAddress][stakeId].price * 2) / 100;

        /* stake seller gets 90% of the stake's sold price */
        soldStakeFunds[sellerAddress] += (mapMemberStake[sellerAddress][stakeId].price * 90) / 100 ;
 
        /* setting data for the old owner */
        mapMemberStake[sellerAddress][stakeId].stake_hasSold = true;
        mapMemberStake[sellerAddress][stakeId].stake_forSell = false;
        mapMemberStake[sellerAddress][stakeId].stakeCollected = true;

        totalStakeTradeAmount[msg.sender] += msg.value;
        totalStakeTradeAmount[sellerAddress] += msg.value;

        totalStakesSold += 1;
        totalTradeAmount += msg.value;

        /* new stake & stake ID for the new stake owner (the stake buyer) */
        uint256 newStakeId = calcStakeCount(msg.sender);
        mapMemberStake[msg.sender][newStakeId].userAddress = msg.sender;
        mapMemberStake[msg.sender][newStakeId].tokenValue = mapMemberStake[sellerAddress][stakeId].tokenValue ;
        mapMemberStake[msg.sender][newStakeId].startDay = mapMemberStake[sellerAddress][stakeId].startDay ;
        mapMemberStake[msg.sender][newStakeId].endDay = mapMemberStake[sellerAddress][stakeId].endDay;
        mapMemberStake[msg.sender][newStakeId].loansReturnAmount = mapMemberStake[sellerAddress][stakeId].loansReturnAmount;
        mapMemberStake[msg.sender][newStakeId].stakeId = newStakeId;
        mapMemberStake[msg.sender][newStakeId].stakeCollected = false;
        mapMemberStake[msg.sender][newStakeId].stake_hasSold = false;
        mapMemberStake[msg.sender][newStakeId].stake_hasLoan = false;
        mapMemberStake[msg.sender][newStakeId].stake_forSell = false;
        mapMemberStake[msg.sender][newStakeId].stake_forLoan = false;
        mapMemberStake[msg.sender][newStakeId].price = 0;
    } 

    /**
     * @dev User asking to withdraw their funds from their sold stake
     */
    function withdrawSoldStakeFunds() external nonReentrant {
        require(soldStakeFunds[msg.sender] > 0, 'No funds to withdraw');

        uint256 toBeSend = soldStakeFunds[msg.sender];
        soldStakeFunds[msg.sender] = 0;

        payable(msg.sender).transfer(toBeSend);
    }







    struct loanRequest {
        address loanerAddress; // address
        address lenderAddress; // address (sets after loan request accepted by a lender)
        uint256 stakeId;       // id of the stakes that is being loaned on
        uint256 loanAmount;    // requesting loan BNB amount
        uint256 returnAmount;  // requesting loan BNB return amount
        uint256 duration;      // duration of loan (days)
        uint256 lend_startDay; // lend start day (sets after loan request accepted by a lender)
        uint256 lend_endDay;   // lend end day (sets after loan request accepted by a lender)
        bool hasLoan;
        bool loanIsPaid;       // gets true after loan due date is reached and loan is paid
    }

    struct lendInfo {
        address lenderAddress;
        address loanerAddress;
        uint256 stakeId;
        uint256 loanAmount;
        uint256 returnAmount;
        uint256 endDay;
        bool loanIsPaid;
    }
        

    /* withdrawable funds for the loaner address */
    mapping(address => uint256) public LoanedFunds;
    
    uint256 public totalLoanedAmount;
    uint256 public totalLoanedCount;

    mapping(address => mapping(uint256 => loanRequest)) public mapRequestingLoans;
    mapping(address => mapping(uint256 => lendInfo)) public mapLenderInfo;
    mapping(address => uint256) public lendersPaidAmount; // total amounts of paid to lender
    
    /**
     * @dev User submiting a loan request on their stake or changing the previously setted loan request data
     * @param stakeId stake id
     * @param loanAmount amount of requesting BNB loan
     * @param returnAmount amount of BNB loan return
     * @param loanDuration duration of requesting loan
     */
    function getLoanOnStake(uint256 stakeId ,uint256 loanAmount , uint256 returnAmount , uint256 loanDuration) external {
        _updateDaily();

        require(loaningIsPaused == false, 'functionality is paused');
        require(loanAmount < returnAmount, 'loan return must be higher than loan amount');
        require(loanDuration >= 4, 'lowest loan duration is 4 days'); 
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender, 'auth failed');
        require(mapMemberStake[msg.sender][stakeId].stake_hasLoan == false, 'Target stake has an active loan on it');
        require(mapMemberStake[msg.sender][stakeId].stake_hasSold == false, 'Target stake has been sold');
        require(mapMemberStake[msg.sender][stakeId].endDay - loanDuration > currentDay); 
    
        /* calc stake divs */
        uint256 stakeDivs = calcStakeCollecting(msg.sender, stakeId);

        /* max amount of possible stake return can not be higher than stake's divs */
        require(returnAmount <= stakeDivs); 

        /* if stake is for sell, remove it from sell requests */
        if (mapMemberStake[msg.sender][stakeId].stake_forSell == true) {
            cancelSellStakeRequest(stakeId);
        }

        require(mapMemberStake[msg.sender][stakeId].stake_forSell == false);

        mapMemberStake[msg.sender][stakeId].stake_forLoan = true;

        /* data of the requesting loan */
        mapRequestingLoans[msg.sender][stakeId].loanerAddress = msg.sender;
        mapRequestingLoans[msg.sender][stakeId].stakeId = stakeId;
        mapRequestingLoans[msg.sender][stakeId].loanAmount = loanAmount;
        mapRequestingLoans[msg.sender][stakeId].returnAmount = returnAmount;
        mapRequestingLoans[msg.sender][stakeId].duration = loanDuration;
        mapRequestingLoans[msg.sender][stakeId].loanIsPaid = false;

        emit stake_loan_request (
            msg.sender, 
            block.timestamp,
            loanAmount,
            loanDuration,
            stakeId
        );
    }


    /**
     * @dev Canceling loan request
     * @param stakeId stake id
     */
    function cancelStakeLoanRequest(uint256 stakeId) public {
        require(mapMemberStake[msg.sender][stakeId].stake_hasLoan == false);
        mapMemberStake[msg.sender][stakeId].stake_forLoan = false;
    }


    /**
     * @dev User asking to their stake's sell request
     */
    function cancelSellStakeRequest(uint256 _stakeId) internal {
        require(mapMemberStake[msg.sender][_stakeId].userAddress == msg.sender);
        require(mapMemberStake[msg.sender][_stakeId].stake_forSell == true);
        require(mapMemberStake[msg.sender][_stakeId].stake_hasSold == false);

        mapMemberStake[msg.sender][_stakeId].stake_forSell = false;
    }


    /**
     * @dev User filling loan request (lending)
     * @param loanerAddress address of loaner aka the person who is requesting for loan
     * @param stakeId stake id
     */
    function lendOnStake(address loanerAddress , uint256 stakeId) external payable nonReentrant {
        _updateDaily();

        require(loaningIsPaused == false, 'functionality is paused');
        require(mapMemberStake[loanerAddress][stakeId].userAddress != msg.sender, 'no self lend'); 
        require(mapMemberStake[loanerAddress][stakeId].stake_hasLoan == false, 'Target stake has an active loan on it');
        require(mapMemberStake[loanerAddress][stakeId].stake_forLoan == true, 'Target stake is not requesting a loan');
        require(mapMemberStake[loanerAddress][stakeId].stake_hasSold == false, 'Target stake is sold');
        require(mapMemberStake[loanerAddress][stakeId].endDay > currentDay, 'Target stake duration is finished');
        
        uint256 loanAmount = mapRequestingLoans[loanerAddress][stakeId].loanAmount;
        uint256 returnAmount = mapRequestingLoans[loanerAddress][stakeId].returnAmount;
        uint256 rawAmount = msg.value;

        require(rawAmount == mapRequestingLoans[loanerAddress][stakeId].loanAmount);
        
        /* 2% loaning fee, taken from loaner's stake dividends, 1% buybacks to current day's lobby, 1% dev fee */
        uint256 theLoanFee = (rawAmount * 2) /100;  
        devShareOfStakeSellsAndLoanFee += theLoanFee /2;     
        lobbyEntry[currentDay] += theLoanFee /2;

        mapMemberStake[loanerAddress][stakeId].loansReturnAmount += returnAmount;
        mapMemberStake[loanerAddress][stakeId].stake_hasLoan = true;
        mapMemberStake[loanerAddress][stakeId].stake_forLoan = false;

        mapRequestingLoans[loanerAddress][stakeId].hasLoan = true;
        mapRequestingLoans[loanerAddress][stakeId].loanIsPaid = false;
        mapRequestingLoans[loanerAddress][stakeId].lenderAddress = msg.sender;
        mapRequestingLoans[loanerAddress][stakeId].lend_startDay = currentDay + 1;
        mapRequestingLoans[loanerAddress][stakeId].lend_endDay = currentDay + 1 + mapRequestingLoans[loanerAddress][stakeId].duration;

        uint256 LenderStakeId = clcLenderStakeId(msg.sender);
        mapLenderInfo[msg.sender][LenderStakeId].lenderAddress = msg.sender;
        mapLenderInfo[msg.sender][LenderStakeId].loanerAddress = loanerAddress;
        mapLenderInfo[msg.sender][LenderStakeId].stakeId = LenderStakeId; // not same with the stake id on "mapRequestingLoans"
        mapLenderInfo[msg.sender][LenderStakeId].loanAmount = loanAmount;
        mapLenderInfo[msg.sender][LenderStakeId].returnAmount = returnAmount;
        mapLenderInfo[msg.sender][LenderStakeId].endDay = mapRequestingLoans[loanerAddress][stakeId].lend_endDay;

        LoanedFunds[loanerAddress] += (rawAmount * 98) /100;
        totalLoanedAmount += (rawAmount * 98) /100;
        totalLoanedCount += 1;

        emit stake_lend(
            msg.sender, 
            block.timestamp,
            LenderStakeId
        );

        emit stake_loan(
            loanerAddress,
            block.timestamp,
            stakeId,
            (rawAmount * 98) /100
        );
    }


    /**
     * @dev User asking to withdraw their loaned funds
     */
    function withdrawLoanedFunds() external nonReentrant {
        require(LoanedFunds[msg.sender] > 0, 'No funds to withdraw');

        uint256 toBeSend = LoanedFunds[msg.sender];
        LoanedFunds[msg.sender] = 0;

        payable(msg.sender).transfer(toBeSend);
    }


    /**
     * @dev returns a unique id for the lend by lopping through the user's lends and counting them
     * @param _address the lender user address
     */
    function clcLenderStakeId(address _address) public view returns (uint256) {
        uint256 stakeCount = 0;

        for (uint256 i = 0; mapLenderInfo[_address][i].lenderAddress == _address; i++) {
            stakeCount += 1;
        }

        return stakeCount;
    }
  
  
    /* 
        after a loan's due date is reached there is no automatic way in contract to pay the lender and set the lend data as finished (for the sake of performance and gas)
        so either the lender user calls the "collectLendReturn" function or the loaner user automatically call the  "updateFinishedLoan" function by trying to collect their stake 
    */

    /**
     * @dev Lender requesting to collect their return amount from their finished lend
     * @param stakeId stake id 
     */
    function collectLendReturn(uint256 stakeId, uint256 lenderStakeId) external {
        updateFinishedLoan(msg.sender, mapLenderInfo[msg.sender][stakeId].loanerAddress, lenderStakeId, stakeId);
    }

    /**
     * @dev Checks if the loan on loaner's stake is finished
     * @param lenderAddress lender address
     * @param loanerAddress loaner address
     * @param lenderStakeId lenderStakeId (different from stakeId)
     * @param stakeId stake id
     */
    function updateFinishedLoan(address lenderAddress, address loanerAddress, uint256 lenderStakeId, uint256 stakeId) internal nonReentrant {
        _updateDaily();

        require(mapMemberStake[loanerAddress][stakeId].stake_hasLoan == true, 'Target stake does not have an active loan on it');
        require(currentDay >= mapRequestingLoans[loanerAddress][stakeId].lend_endDay, 'Due date not yet reached');
        require(mapLenderInfo[lenderAddress][lenderStakeId].loanIsPaid == false);
        require(mapRequestingLoans[loanerAddress][stakeId].loanIsPaid == false);
        require(mapRequestingLoans[loanerAddress][stakeId].hasLoan == true);

        mapMemberStake[loanerAddress][stakeId].stake_hasLoan = false;
        mapLenderInfo[lenderAddress][lenderStakeId].loanIsPaid = true;
        mapRequestingLoans[loanerAddress][stakeId].hasLoan = false;
        mapRequestingLoans[loanerAddress][stakeId].loanIsPaid = true;


        uint256 toBePaid = mapRequestingLoans[loanerAddress][stakeId].returnAmount;
        lendersPaidAmount[lenderAddress] += toBePaid;

        mapRequestingLoans[loanerAddress][stakeId].returnAmount = 0;

        payable(lenderAddress).transfer(toBePaid);
    }

}