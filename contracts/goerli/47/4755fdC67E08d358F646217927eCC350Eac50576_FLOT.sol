/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

/**
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Pegasus.sol

//SPDX-License-Identifier: MIT



pragma solidity >=0.8.9 <0.9.0;







library SafeMathInt {

    int256 private constant MIN_INT256 = int256(1) << 255;

    int256 private constant MAX_INT256 = ~(int256(1) << 255);



    function mul(int256 a, int256 b) internal pure returns (int256) {

        int256 c = a * b;



        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));

        require((b == 0) || (c / b == a));

        return c;

    }



    function div(int256 a, int256 b) internal pure returns (int256) {

        require(b != -1 || a != MIN_INT256);



        return a / b;

    }



    function sub(int256 a, int256 b) internal pure returns (int256) {

        int256 c = a - b;

        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;

    }



    function add(int256 a, int256 b) internal pure returns (int256) {

        int256 c = a + b;

        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;

    }



    function abs(int256 a) internal pure returns (int256) {

        require(a != MIN_INT256);

        return a < 0 ? -a : a;

    }

}



interface IDEXFactory {

    function createPair(address tokenA, address tokenB)

        external

        returns (address pair);

}



interface IPair {

    function sync() external;

}



interface IDEXRouter {

    function factory() external pure returns (address);



    function WETH() external pure returns (address);



    function addLiquidity(

        address tokenA,

        address tokenB,

        uint256 amountADesired,

        uint256 amountBDesired,

        uint256 amountAMin,

        uint256 amountBMin,

        address to,

        uint256 deadline

    )

        external

        returns (

            uint256 amountA,

            uint256 amountB,

            uint256 liquidity

        );



    function addLiquidityETH(

        address token,

        uint256 amountTokenDesired,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    )

        external

        payable

        returns (

            uint256 amountToken,

            uint256 amountETH,

            uint256 liquidity

        );



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external;



    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable;



    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external;

}



abstract contract ERC20Detailed is IERC20 {

    string private _name;

    string private _symbol;

    uint8 private _decimals;



    constructor(

        string memory _tokenName,

        string memory _tokenSymbol,

        uint8 _tokenDecimals

    ) {

        _name = _tokenName;

        _symbol = _tokenSymbol;

        _decimals = _tokenDecimals;

    }



    function name() public view returns (string memory) {

        return _name;

    }



    function symbol() public view returns (string memory) {

        return _symbol;

    }



    function decimals() public view returns (uint8) {

        return _decimals;

    }

}



contract FLOT is ERC20Detailed, Ownable {

    using SafeMath for uint256;

    using SafeMathInt for int256;



    uint256 private constant DECIMALS = 18;

    uint256 private constant MAX_SUPPLY = type(uint128).max;

    uint256 private constant MAX_UINT256 = type(uint256).max;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =

        1 * 10**9 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS =

        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);



    uint256 private totalTokenSupply;



    function totalSupply() external view override returns (uint256) {

        return totalTokenSupply;

    }



    uint256 private gonsPerFragment;



    mapping(address => uint256) private gonBalance;

    mapping(address => mapping(address => uint256)) private allowedFragments;



    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address private constant ZERO = 0x0000000000000000000000000000000000000000;



    IDEXRouter public defaultRouter;

    address public defaultPair;



    mapping(address => bool) allowedTransferList;

    mapping(address => bool) feeExemptList;

    mapping(address => bool) blacklist;

    mapping(address => bool) swapPairList;



    function setAllowTransfer(address _addr, bool _value) external onlyOwner {

        allowedTransferList[_addr] = _value;

    }



    function isAllowTransfer(address _addr) public view returns (bool) {

        return allowedTransferList[_addr];

    }



    function setFeeExempt(address _addr, bool _value) public onlyOwner {

        feeExemptList[_addr] = _value;

    }



    function isFeeExempt(address _addr) public view returns (bool) {

        return feeExemptList[_addr];

    }



    function setBlacklist(address _addr, bool _value) external onlyOwner {

        blacklist[_addr] = _value;

    }



    function isBlacklist(address _addr) public view returns (bool) {

        return blacklist[_addr];

    }



    function setSwapPair(address _addr, bool _value) public onlyOwner {

        swapPairList[_addr] = _value;

    }



    function isSwapPair(address _addr) public view returns (bool) {

        return swapPairList[_addr];

    }



    constructor() ERC20Detailed("FLOAT", "FLOAT", uint8(DECIMALS)) {

        defaultRouter = IDEXRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

        defaultPair = IDEXFactory(defaultRouter.factory()).createPair(

            defaultRouter.WETH(),

            address(this)

        );



        allowedFragments[address(this)][address(defaultRouter)] = MAX_UINT256;



        totalTokenSupply = INITIAL_FRAGMENTS_SUPPLY;

        gonsPerFragment = TOTAL_GONS.div(INITIAL_FRAGMENTS_SUPPLY);

        gonBalance[msg.sender] = TOTAL_GONS;



        setFeeExempt(msg.sender, true);

        setFeeExempt(address(this), true);



        setSwapPair(defaultPair, true);



        emit Transfer(address(0x0), msg.sender, totalTokenSupply);

    }



    // Fee actors

    address public buybackReceiver = 0x3b70CEcBb8c788183e16b5abD9BB4f6227687D00;

    address public gamificationReceiver =

        0xDd9f9d19F20F356EB98F028987b485ED04E14C47;

    address public liquidityReceiver =

        0x6C3b0427E579a3B0CdfF4BE89CD1d4F460A2E363;

    address public treasuryReceiver =

        0x617ef56381C700156a87Ea397c96BA280f2dF2a5;



    function setFeeReceivers(

        address _buybackReceiver,

        address _gamificationReceiver,

        address _liquidityReceiver,

        address _treasuryReceiver

    ) external onlyOwner {

        buybackReceiver = _buybackReceiver;

        gamificationReceiver = _gamificationReceiver;

        liquidityReceiver = _liquidityReceiver;

        treasuryReceiver = _treasuryReceiver;

    }



    //Fee parameters

    uint256 private constant FEE_DENOMINATOR = 100;



    uint256 private constant MAX_TOTAL_BUY_FEE = 20;

    uint256 public buyBackBuyFee = 1;

    uint256 public liquidityBuyFee = 3;

    uint256 public treasuryBuyFee = 10;

    uint256 public gamificationBuyFee = 0;

    uint256 public totalBuyFee = 13;



    uint256 private constant MAX_TOTAL_SELL_FEE = 30;

    uint256 public buyBackSellFee = 3;

    uint256 public liquiditySellFee = 5;

    uint256 public treasurySellFee = 10;

    uint256 public gamificationSellFee = 0;

    uint256 public totalSellFee = 18;



    function setBuyFees(

        uint256 _buybackFee,

        uint256 _gamificationFee,

        uint256 _liquidityFee,

        uint256 _treasuryFee

    ) external onlyOwner {

        uint256 _totalFee = _buybackFee

            .add(_gamificationFee)

            .add(_liquidityFee)

            .add(_treasuryFee);

        require(

            _totalFee <= MAX_TOTAL_BUY_FEE,

            "Sum of buy fees exceeds max value"

        );

        buyBackBuyFee = _buybackFee;

        gamificationBuyFee = _gamificationFee;

        liquidityBuyFee = _liquidityFee;

        treasuryBuyFee = _treasuryFee;

        totalBuyFee = _totalFee;

    }



    function setSellFees(

        uint256 _buybackFee,

        uint256 _gamificationFee,

        uint256 _liquidityFee,

        uint256 _treasuryFee

    ) external onlyOwner {

        uint256 _totalFee = _buybackFee

            .add(_gamificationFee)

            .add(_liquidityFee)

            .add(_treasuryFee);

        require(

            _totalFee <= MAX_TOTAL_SELL_FEE,

            "Sum of sell fees exceeds max value"

        );

        buyBackSellFee = _buybackFee;

        gamificationSellFee = _gamificationFee;

        liquiditySellFee = _liquidityFee;

        treasurySellFee = _treasuryFee;

        totalSellFee = _totalFee;

    }



    // Fee collection logic

    function takeFee(

        address sender,

        address recipient,

        uint256 gonAmount

    ) internal returns (uint256) {

        uint256 fee = totalBuyFee;

        if (isSwapPair(recipient)) {

            fee = totalSellFee;

        }



        uint256 feeAmount = gonAmount.mul(fee).div(FEE_DENOMINATOR);



        gonBalance[address(this)] = gonBalance[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount.div(gonsPerFragment));



        return gonAmount.sub(feeAmount);

    }



    // Fee collection parameters

    bool swapBackEnabled = true;

    bool liquidityEnabled = true;

    uint256 gonSwapThreshold = TOTAL_GONS.div(1000).mul(10);



    function setSwapBackSettings(

        bool _swapBackEnabled,

        bool _liquidityEnabled,

        uint256 _num,

        uint256 _denom

    ) external onlyOwner {

        swapBackEnabled = _swapBackEnabled;

        liquidityEnabled = _liquidityEnabled;

        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);

    }



    bool inSwap = false;



    modifier swapping() {

        inSwap = true;

        _;

        inSwap = false;

    }



    // Fee distribution logic

    function shouldSwapBack() internal view returns (bool) {

        return

            !isSwapPair(msg.sender) &&

            swapBackEnabled &&

            !inSwap &&

            gonBalance[address(this)] >= gonSwapThreshold;

    }



    function swapBack() internal swapping {

        uint256 contractTokenBalance = gonBalance[address(this)].div(

            gonsPerFragment

        );



        uint256 totalFee = totalBuyFee.add(totalSellFee);



        uint256 treasuryTransferAmount = contractTokenBalance

            .mul((treasuryBuyFee.add(treasurySellFee)))

            .div(totalFee);

        if (treasuryTransferAmount > 0) {

            _swapAndSend(treasuryTransferAmount, treasuryReceiver);

        }



        uint256 buybackTransferAmount = contractTokenBalance

            .mul((buyBackBuyFee.add(buyBackSellFee)))

            .div(totalFee);

        if (buybackTransferAmount > 0) {

            _swapAndSend(buybackTransferAmount, buybackReceiver);

        }



        uint256 gamificationTransferAmount = contractTokenBalance

            .mul((gamificationBuyFee.add(gamificationSellFee)))

            .div(totalFee);

        if (gamificationTransferAmount > 0) {

            _swapAndSend(gamificationTransferAmount, gamificationReceiver);

        }



        uint256 dynamicLiquidityFee = liquidityEnabled

            ? liquidityBuyFee.add(liquiditySellFee)

            : 0;

        uint256 liquidityTransferAmount = contractTokenBalance

            .mul(dynamicLiquidityFee)

            .div(totalFee);

        if (liquidityTransferAmount > 0) {

            _addLiquidity(liquidityTransferAmount, liquidityReceiver);

        }



        emit SwapBack(

            contractTokenBalance,

            buybackTransferAmount,

            gamificationTransferAmount,

            liquidityTransferAmount,

            treasuryTransferAmount

        );

    }



    function _swapAndSend(uint256 _tokenAmount, address _receiver) private {

        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = defaultRouter.WETH();



        defaultRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(

            _tokenAmount,

            0,

            path,

            _receiver,

            block.timestamp

        );

    }



    function _addLiquidity(uint256 _tokenAmount, address _receiver) private {

        uint256 coinBalance = address(this).balance;

        _swapAndSend(_tokenAmount.div(2), address(this));

        uint256 coinBalanceDifference = address(this).balance.sub(coinBalance);



        defaultRouter.addLiquidityETH{value: coinBalanceDifference}(

            address(this),

            _tokenAmount.div(2),

            0,

            0,

            _receiver,

            block.timestamp

        );

    }



    // Rebase parameters and actors

    uint256 private constant REWARD_YIELD_DENOMINATOR = 10000000000;

    uint256 public rewardYield = 2634548;

    uint256 public rebaseFrequency = 1800;

    uint256 public nextRebase = block.timestamp + rebaseFrequency;



    function setRebaseParameters(

        uint256 _rewardYield,

        uint256 _rebaseFrequency,

        uint256 _nextRebase

    ) external onlyOwner {

        rewardYield = _rewardYield;

        rebaseFrequency = _rebaseFrequency;

        nextRebase = _nextRebase;

    }



    address public rebaseExecutor = 0x484737D1B6A7621dB607c472Ed749A5fE4B004B0;



    function setRebaseExecutor(address _rebaseExecutor) external onlyOwner {

        rebaseExecutor = _rebaseExecutor;

    }



    modifier isExecutor() {

        require(msg.sender == rebaseExecutor);

        _;

    }



    function rebase(uint256 epoch, int256 supplyDelta) external onlyOwner {

        require(!inSwap, "Currently in swap, try again later.");

        _rebase(epoch, supplyDelta);

    }



    function executorRebase() external isExecutor {

        require(!inSwap, "Currently in swap, try again later.");



        uint256 epoch = block.timestamp;

        require(

            nextRebase <= block.timestamp,

            "Too soon since last automatic rebase."

        );



        int256 supplyDelta = int256(

            totalTokenSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR)

        );



        _rebase(epoch, supplyDelta);

    }



    function _rebase(uint256 epoch, int256 supplyDelta) private {

        if (supplyDelta < 0) {

            totalTokenSupply = totalTokenSupply.sub(uint256(-supplyDelta));

        } else {

            totalTokenSupply = totalTokenSupply.add(uint256(supplyDelta));

        }



        if (totalTokenSupply > MAX_SUPPLY) {

            totalTokenSupply = MAX_SUPPLY;

        }



        gonsPerFragment = TOTAL_GONS.div(totalTokenSupply);

        IPair(defaultPair).sync();



        nextRebase = epoch + rebaseFrequency;



        emit LogRebase(epoch, totalTokenSupply);

    }



    // Approval and transfer logic

    function allowance(address owner, address spender)

        external

        view

        override

        returns (uint256)

    {

        return allowedFragments[owner][spender];

    }



    function balanceOf(address who) external view override returns (uint256) {

        return gonBalance[who].div(gonsPerFragment);

    }



    function approve(address spender, uint256 value)

        external

        override

        returns (bool)

    {

        allowedFragments[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;

    }



    function increaseAllowance(address spender, uint256 addedValue)

        external

        returns (bool)

    {

        allowedFragments[msg.sender][spender] = allowedFragments[msg.sender][

            spender

        ].add(addedValue);

        emit Approval(

            msg.sender,

            spender,

            allowedFragments[msg.sender][spender]

        );

        return true;

    }



    function decreaseAllowance(address spender, uint256 subtractedValue)

        external

        returns (bool)

    {

        uint256 oldValue = allowedFragments[msg.sender][spender];

        if (subtractedValue >= oldValue) {

            allowedFragments[msg.sender][spender] = 0;

        } else {

            allowedFragments[msg.sender][spender] = oldValue.sub(

                subtractedValue

            );

        }

        emit Approval(

            msg.sender,

            spender,

            allowedFragments[msg.sender][spender]

        );

        return true;

    }



    modifier validRecipient(address to) {

        require(to != address(0x0));

        _;

    }



    function transfer(address to, uint256 amount)

        external

        override

        validRecipient(to)

        initialDistributionLock

        returns (bool)

    {

        return _transferFrom(msg.sender, to, amount);

    }



    function transferFrom(

        address from,

        address to,

        uint256 value

    )

        external

        override

        validRecipient(to)

        initialDistributionLock

        returns (bool)

    {

        if (allowedFragments[from][msg.sender] != MAX_UINT256) {

            allowedFragments[from][msg.sender] = allowedFragments[from][

                msg.sender

            ].sub(value, "Insufficient Allowance");

        }

        return _transferFrom(from, to, value);

    }



    function _transferFrom(

        address _sender,

        address _recipient,

        uint256 _amount

    ) internal returns (bool) {

        require(!isBlacklist(_sender), "Sender is blacklisted");

        require(!isBlacklist(_recipient), "Recipient is blacklisted");



        if (inSwap) {

            return _basicTransfer(_sender, _recipient, _amount);

        }



        if (shouldSwapBack()) {

            swapBack();

        }



        uint256 _gonAmount = _amount.mul(gonsPerFragment);

        gonBalance[_sender] = gonBalance[_sender].sub(_gonAmount);



        uint256 _gonAmountReceived = (

            ((isSwapPair(_sender) || isSwapPair(_recipient)) &&

                (!isFeeExempt(_sender)))

                ? takeFee(_sender, _recipient, _gonAmount)

                : _gonAmount

        );



        gonBalance[_recipient] = gonBalance[_recipient].add(_gonAmountReceived);

        emit Transfer(

            _sender,

            _recipient,

            _gonAmountReceived.div(gonsPerFragment)

        );

        return true;

    }



    function _basicTransfer(

        address from,

        address to,

        uint256 amount

    ) internal returns (bool) {

        uint256 gonAmount = amount.mul(gonsPerFragment);

        gonBalance[from] = gonBalance[from].sub(gonAmount);

        gonBalance[to] = gonBalance[to].add(gonAmount);

        return true;

    }



    // Utilities

    function sendPresale(

        address[] calldata recipients,

        uint256[] calldata values

    ) external onlyOwner {

        for (uint256 i = 0; i < recipients.length; i++) {

            _transferFrom(msg.sender, recipients[i], values[i]);

        }

    }



    bool initialDistributionFinished = false;



    modifier initialDistributionLock() {

        require(

            initialDistributionFinished ||

                msg.sender == owner() ||

                isAllowTransfer(msg.sender)

        );

        _;

    }



    function setInitialDistributionFinished() external onlyOwner {

        initialDistributionFinished = true;

    }



    function getCirculatingSupply() external view returns (uint256) {

        return

            (TOTAL_GONS.sub(gonBalance[DEAD]).sub(gonBalance[ZERO])).div(

                gonsPerFragment

            );

    }



    function manualSync() external {

        IPair(defaultPair).sync();

    }



    function isInSwap() external view returns (bool) {

        return inSwap;

    }



    function swapPendingAmount() external view returns (uint256) {

        return gonBalance[address(this)].div(gonsPerFragment);

    }



    function swapThreshold() external view returns (uint256) {

        return gonSwapThreshold.div(gonsPerFragment);

    }



    function withdraw(address _receiver, uint256 _amount) external onlyOwner {

        payable(_receiver).transfer(_amount);

    }



    function rescueToken(address _tokenAddress, uint256 _amount)

        external

        onlyOwner

    {

        ERC20Detailed(_tokenAddress).transfer(msg.sender, _amount);

    }



    receive() external payable {}



    event SwapBack(

        uint256 contractTokenBalance,

        uint256 buybackTransferAmount,

        uint256 gamificationTransferAmount,

        uint256 liquidityTransferAmount,

        uint256 treasuryTransferAmount

    );

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

}