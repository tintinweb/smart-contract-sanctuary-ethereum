/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// File: contracts/ERC20/utils/Context.sol
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
// File: contracts/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// File: contracts/ERC20/extensions/IERC20Metadata.sol


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
// File: contracts/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
// File: contracts/ERC20/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
}

// File: contracts/ERC20/Ownable.sol

/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/


pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,"Caller is Not owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// File: contracts/MEMAG.sol


pragma solidity ^0.8.0;




contract MEMAG is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private _totalSupply = 1000000000 * 1e18;
    uint256 public timestampDeployment;

    address public ECO_SYSTEM;//20%
    address public COMPANY_RESERVE;//21.5%
    address public TEAM_ADDRESS;//5%
    address public MARKETPLACE;//30%
    address public LIQUIDITY;//15%

    struct Phase{
        uint256 _startDate;
        uint256 _endDate;
        uint256 _totalAllocation;
        uint256 _remainingAllocation;
        uint256 _exchangeRate;
    }

    mapping(string => Phase) public phaseDetails;
    string[] public phaseLiterals = ["PRIVATE"];

    struct LockIn{
        uint256 lockInStart;
        uint256 lockInEnd;
        uint256 balance;
    }
    // (owner => (lockInStart,lockInEnd))
    mapping(address => LockIn) private lockInPeriod;

    event PhaseDateUpdated(string phaseLiteral, uint256 startDate, uint256 endDate);
    event TokenBuy(address indexed owner, uint256 payableAmount, uint256 tokens, string activePhase);
    event TokenLocked(address indexed owner, uint256 tokens, uint256 lockInStart, uint256 lockInEnd, uint256 lockInBalance);
   
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address _ECO_SYSTEM,
                address _COMPANY_RESERVE,
                address _TEAM_ADDRESS,
                address _MARKETPLACE,
                address _LIQUIDITY) ERC20("Meta Masters Guild","MEMAG"){

        timestampDeployment = block.timestamp;
        // Total Supply;
        _mint(address(this), _totalSupply);

        ECO_SYSTEM = _ECO_SYSTEM;
        COMPANY_RESERVE = _COMPANY_RESERVE;
        TEAM_ADDRESS = _TEAM_ADDRESS;
        MARKETPLACE = _MARKETPLACE;
        LIQUIDITY = _LIQUIDITY;

        // ECO_SYSTEM = 20%
        _transfer(address(this),ECO_SYSTEM,200000000 * 1e18);

        // COMPANY_RESERVE = 21.5%
        _transfer(address(this),COMPANY_RESERVE,215000000 * 1e18);

        // TEAM_ADDRESS = 5%
        _transfer(address(this),TEAM_ADDRESS,50000000 * 1e18);

        // MARKETPLACE = 30%
        _transfer(address(this),MARKETPLACE,300000000 * 1e18);

        // LIQUIDITY = 15%
        _transfer(address(this),LIQUIDITY,150000000 * 1e18);


        // Set Phase Details.      
                                // 8% & Price/Token = 0.2 MATIC
        phaseDetails["PRIVATE"] = Phase(0,0, 80000000 * 1e18, 80000000 * 1e18, 200000000000000000);

    }

    function updatePhaseExchangeRate(uint256 _exchangeRate)
    external
    onlyOwner{
        string memory phaseLiteral = "PRIVATE";
        require(_exchangeRate != 0,"Error: Exchange rate should not be zero!");
        phaseDetails[phaseLiteral]._exchangeRate = _exchangeRate;
    }

    function updatePhaseDates(uint256 _uStartDate,
                              uint256 _uEndDate)
    external
    onlyOwner{
        string memory phaseLiteral = "PRIVATE";
        if(phaseDetails[phaseLiteral]._startDate != 0 && phaseDetails[phaseLiteral]._endDate != 0){
            require(phaseDetails[phaseLiteral]._startDate > block.timestamp,"Error: Phase has already been started and can't update phase dates.");
        }

        require(_uStartDate != 0 && _uEndDate != 0,"Error: Invalid start and end date!");
        require(_uStartDate < _uEndDate,"Error: End date should be greater than Start date!");

        phaseDetails[phaseLiteral]._startDate = _uStartDate;
        phaseDetails[phaseLiteral]._endDate = _uEndDate;

        emit PhaseDateUpdated(phaseLiteral, _uStartDate, _uEndDate);
    }   

    // Get Active Phase
    function getActivePhase() view public returns (string memory){

        uint256 _currentLength = phaseLiterals.length;
        // uint256 _currentTimestamp = block.timestamp;

        for(uint8 idx = 0; idx < _currentLength; idx++){
            string memory _phaseLiteral = phaseLiterals[idx];
            Phase memory _currentPhase =  phaseDetails[_phaseLiteral];

            if(block.timestamp >= _currentPhase._startDate && block.timestamp <= _currentPhase._endDate)
            {
                return _phaseLiteral;
            }
        }

        return "NO_ACTIVE_PHASE";
    }  

    function buyMEMAGToken()
    public
    payable{
        // Get Active Phase
        string memory _phaseLiteral = getActivePhase();

        // Check if Any Active Phase ongoing
        require(strCompare(_phaseLiteral, "NO_ACTIVE_PHASE") == false,"Currently no active phase found");
        require(strCompare(_phaseLiteral, "PRIVATE") == true,"Only allowed for Private Sale");
        require(msg.value > 0,"Error: This action is payable");

        uint256 _paybleAmt = msg.value;
        uint256 _userTransfer = _paybleAmt.div(phaseDetails[_phaseLiteral]._exchangeRate);
        _userTransfer = _userTransfer * 1e18;// convert into wei

        /*Private Sale Buy Limit
         2% of Private Sale(80000000) is 1600000
         Each individual cannot buy more than 2% of the total private round*/

        uint256 _privateSaleUserBought = (lockInPeriod[_msgSender()].balance).add(_userTransfer);

        if(strCompare(_phaseLiteral, "PRIVATE") && (_privateSaleUserBought > 1600000000000000000000000)){
            revert("Each individual cannot buy more than 2% of the total Private Sale!");
        }
        
        uint256 _uRemainingAmt = phaseDetails[_phaseLiteral]._remainingAllocation.sub(_userTransfer);

        // Transfer token to user
        _transfer(address(this),_msgSender(),_userTransfer);

        phaseDetails[_phaseLiteral]._remainingAllocation = _uRemainingAmt;
        emit TokenBuy(_msgSender(), _paybleAmt, _userTransfer, _phaseLiteral);

        // Lock-in for private Sale Buy
        if(strCompare(_phaseLiteral, "PRIVATE")){

            uint256 _lockInStart = block.timestamp;
            
            if(lockInPeriod[_msgSender()].lockInStart > 0){
                _lockInStart = lockInPeriod[_msgSender()].lockInStart;
            }
            
            uint256 _lockInEnd = _lockInStart;
            uint256 _lockInBalance = lockInPeriod[_msgSender()].balance;

            _lockInBalance = _lockInBalance.add(_userTransfer);
            
            /*
                Private Sale Token Price = $0.1
                Limit = 
                1) $10000 to $25000 = (10000 * 0.1) to (25000 * 0.1) = 1000 MEMAG to 2500 MEMAG
                2) $25000 to $50000 = (25000 * 0.1) to (50000 * 0.1) = 2500 MEMAG to 5000 MEMAG
                3) $50000 to $100000 = (50000 * 0.1) to (100000 * 0.1) = 5000 MEMAG to 10000 MEMAG
                3) more than $100000 = (100000 * 0.1) =  10000 MEMAG
            */

            uint256 _priceAmtA = 1000 * 1e18;
            uint256 _priceAmtB = 2500 * 1e18;
            uint256 _priceAmtC = 5000 * 1e18;
            uint256 _priceAmtD = 10000 * 1e18;

            if(_userTransfer > _priceAmtA && _userTransfer <= _priceAmtB){
                _lockInEnd = _lockInEnd.add(7776000);// 7776000 = for 90 days
            }
            else if(_userTransfer > _priceAmtB && _userTransfer <= _priceAmtC){
                _lockInEnd = _lockInEnd.add(15552000);// 15552000 = for 180 days
            }
            else if(_userTransfer > _priceAmtC && _userTransfer <= _priceAmtD){
                _lockInEnd = _lockInEnd.add(23328000);// 23328000 = for 270 days
            }
            else if(_userTransfer > _priceAmtD){
                _lockInEnd = _lockInEnd.add(31104000);// 31104000 = for 360 days
            }


            lockInPeriod[_msgSender()].lockInStart = _lockInStart;
            lockInPeriod[_msgSender()].balance = _lockInBalance;

            if(_lockInEnd > lockInPeriod[_msgSender()].lockInEnd){
                lockInPeriod[_msgSender()].lockInEnd = _lockInEnd;
            }

            emit TokenLocked(_msgSender(), _userTransfer, _lockInStart, _lockInEnd, _lockInBalance);
        }   
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
        if(lockInPeriod[_msgSender()].lockInStart != 0  && lockInPeriod[_msgSender()].lockInEnd != 0){
            require(!((lockInPeriod[_msgSender()].lockInStart < block.timestamp) && (lockInPeriod[_msgSender()].lockInEnd > block.timestamp)),"Error: Can not withdraw with in lock-in period");
        }

        _transfer(_msgSender(), recipient, amount);

        if(lockInPeriod[_msgSender()].lockInStart != 0  && lockInPeriod[_msgSender()].lockInEnd != 0){
            lockInPeriod[_msgSender()].balance = (lockInPeriod[_msgSender()].balance).sub(amount);
        }

        if(lockInPeriod[_msgSender()].balance <= 0){
            delete lockInPeriod[_msgSender()].lockInStart;
            delete lockInPeriod[_msgSender()].lockInEnd;
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if(lockInPeriod[_msgSender()].lockInStart != 0  && lockInPeriod[_msgSender()].lockInEnd != 0){
            require(!((lockInPeriod[from].lockInStart < block.timestamp) && (lockInPeriod[from].lockInEnd > block.timestamp)),"Error: Can not transfer with in lock-in period");
        }

        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        if(lockInPeriod[_msgSender()].lockInStart != 0  && lockInPeriod[_msgSender()].lockInEnd != 0){
            lockInPeriod[from].balance = (lockInPeriod[from].balance).sub(amount);
        }
        
        if(lockInPeriod[from].balance <= 0){
            delete lockInPeriod[from].lockInStart;
            delete lockInPeriod[from].lockInEnd;
        }

        return true;
    }

    function strCompare(string memory a, string memory b) pure internal returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    } 
    
    function burn(address account, uint256 amount) external returns (bool){
        require(account == _msgSender(),"Error: Only token owner can call this method!");

        _burn(account, amount);

        if(lockInPeriod[_msgSender()].balance <= 0){
            delete lockInPeriod[_msgSender()].lockInStart;
            delete lockInPeriod[_msgSender()].lockInEnd;
        }

        return true;
    }
}