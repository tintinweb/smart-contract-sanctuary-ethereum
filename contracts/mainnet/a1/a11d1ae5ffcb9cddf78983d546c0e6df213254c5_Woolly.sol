// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";

import './DividendToken.sol';

contract Woolly is Context, IERC20, IERC20Metadata, DividendToken {

    string private constant NAME = 'Woolly';
    string private constant SYMBOL = 'WOOL';
    uint8 private constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1000000000000000000000000000000000; // in smallest unit of token
    uint internal inceptionTimestamp_;
    uint internal constant DIVIDEND_PAY_PERIOD = 30 days;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor() {

        _totalSupply = INITIAL_SUPPLY;
        dividendSupply_ = INITIAL_SUPPLY/2;
        inceptionTimestamp_ = block.timestamp;

        // add contract creator to dividend blacklist
        updateDividendBlacklist(msg.sender, true);

        _balances[msg.sender] = INITIAL_SUPPLY/2;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY/2);

    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address ownerAddress, address spenderAddress) external view virtual override returns (uint256) {
        return _allowances[ownerAddress][spenderAddress];
    }

   /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

   /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `ownerAddress` cannot be the zero address.
     * - `spenderAddress` cannot be the zero address.
     */
    function _approve(address ownerAddress, address spenderAddress, uint256 amount) internal virtual {
        require(ownerAddress != address(0), "ERC20: approve from the zero address");
        require(spenderAddress != address(0), "ERC20: approve to the zero address");
        _allowances[ownerAddress][spenderAddress] = amount;
        emit Approval(ownerAddress, spenderAddress, amount);
    }

    /**
    * @dev Returns the account balance of another account with the address owner
    * @param ownerAddress - the address of the account owner
    */
    function balanceOf(address ownerAddress) external view virtual override returns (uint256) {
        return _balances[ownerAddress];
    }

    /**
    * @dev Burn tokens into Dividend Supply
    * @param value - amount of tokens to burn to the dividend supply
    * @return bool
    */
    function burnToDividendSupply(uint256 value) external returns (bool)
    {
        // validate that sender has sufficent balance
        require(value <= _balances[msg.sender]);

        // deduct from the sender's balance
        _balances[msg.sender] = _balances[msg.sender] - value;

        // add value to dividend supply
        return addToDividendSupply(msg.sender, value);
    }

    /**
    * @dev calculate the dividend for the supplied address and periods
    * @param targetAddress - address of the dividend recipient
    * @param dividendPeriods - number of periods on which the dividend should be calculated
    * @return uint256
    * NOTE: Dividend rate of ~ 0.578% per period simulated by /173
    *       This supports a monthly dividend payment for 10 years
    */
    function calculateDividend(address targetAddress, uint dividendPeriods) public view returns (uint256) {
        uint256 newBalance = _balances[targetAddress];
        uint256 currentDividend = 0;
        uint256 totalDividend = 0;
        for (uint i=0; i<dividendPeriods; i++) {
            currentDividend = newBalance / 173;
            totalDividend = totalDividend + currentDividend;
            newBalance = newBalance + currentDividend;
        }
        return totalDividend;
    }

    /**
    * @dev Collect Dividend
    * @param targetAddress - the address of the recipient of the dividends
    * @param isCollected - boolean indicator of whether the dividend is collected or sent
    */
    function collectDividend(address targetAddress, bool isCollected) public returns (bool) {

        // if the lastPaymentTimestamp is greater than a month, then calculate the number of months since the lastPaymentTimestamp and transfer that amount * (user token balance) to the user accounts.
        // Issue: The tokens could have been added recently, so the user should only receive dividend for those coins, not the entire balance.
        // This might require a monthly balance sheet for each user. That's a lot of storage and/or operations if performed on the chain
        // To avoid extra complexities the collectDividend function is called for both sender and receiver
        // Any changes to the balances should trigger collectDividend to avoid fraud

        // no dividend for blacklisted addresses
        if (dividendBlacklist[targetAddress]) {
            return false;
        }

        // Sets the Last Payment Timestamp for a new account
        if (lastPaymentTimestamp[targetAddress] == 0) {
            initializeNewAccount(targetAddress);
            return false;
        }

        if (_balances[targetAddress] > 0 && block.timestamp >= lastPaymentTimestamp[targetAddress] + DIVIDEND_PAY_PERIOD) {

            // calculate how many dividend periods have passed since the lastPayment
            uint currentPeriodTimestamp;
            uint dividendPeriods;
            (currentPeriodTimestamp, dividendPeriods) = getCurrentDividendPeriodAndTimestamp(lastPaymentTimestamp[targetAddress]);

            // compute total dividend
            uint totalDividend = calculateDividend(targetAddress, dividendPeriods);

            // validate totalDividend and update balances
            if (totalDividend > 0 && dividendSupply_ >= totalDividend) {
                updateBalances(targetAddress, totalDividend, isCollected, currentPeriodTimestamp, dividendPeriods);
                return true;
            }
        }

        return false;

    }

     /**
     * @dev Returns the number of decimals the token uses
     */
     function decimals() external view virtual override returns (uint8) {
        return DECIMALS;
     }

    /**
    * @dev Returns the Last Dividend Timestamp and number of dividend periods passed since a given timestamp
    * @param lastTimestamp - The last dividend payment timestamp as an argument for calculating number of dividend periods passed along with a new timestamp
    * @return tuple
    */
    function getCurrentDividendPeriodAndTimestamp(uint lastTimestamp) public view returns (uint, uint) {

        // the time passed since the inceptionTimestamp, divided by the period size and then rounded to months
        require (block.timestamp > lastTimestamp);
        uint numberOfPeriodsPassed = (block.timestamp - lastTimestamp) / DIVIDEND_PAY_PERIOD; // # of periods passed since the last payment
        return (lastTimestamp + (numberOfPeriodsPassed * DIVIDEND_PAY_PERIOD), numberOfPeriodsPassed);

    }

    /**
    * @dev Returns the InceptionTimestamp
    * @return uint
    */
    function getInceptionTimestamp() external view returns (uint) {
        return inceptionTimestamp_;
    }

     /**
     * @dev initialize a new account
     * @param targetAddress - address at which to initialize new account
     */
     function initializeNewAccount(address targetAddress) public {
         uint _period;
         (lastPaymentTimestamp[targetAddress], _period) = getCurrentDividendPeriodAndTimestamp(inceptionTimestamp_);
         emit DividendTimeStampInitialized(targetAddress, lastPaymentTimestamp[targetAddress], _period);
     }

     /**
     * @dev Returns the name of the token
     */
     function name() external view virtual override returns (string memory) {
        return NAME;
     }

     /**
     * @dev Returns the symbol of the token
     */
     function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
     }

     /**
     * @dev Returns the total token supply
     */
     function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
     }

    /**
    * @dev Transfer token for a specified address
    * @param to - The address to transfer to.
    * @param value - The amount to be transferred.
    * @return bool
    */
    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Transfer token for a specified address
    * @param from - The address to transfer from.
    * @param to - The address to transfer to.
    * @param value - The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal virtual {

        require(to != address(0), "ERC20: transfer to the zero address");

        // validate balance
        require(value <= _balances[from], 'ERC20: insufficient balance');

        // collect dividends
        collectDividend(from, true);
        collectDividend(to, false);

        // update balances and emit transfer event
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(from, to, value);
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
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
    * @dev Update all balances from dividend collection
    * @param targetAddress - the address at which to update values
    * @param totalDividend - the total dividend amount
    * @param isCollected - boolean indicator of whether the dividend is collected or sent
    * @param currentPeriodTimestamp - current period timestamp value to update lastPaymentTimestamp
    * @param dividendPeriods - number of periods on which the dividend should be calculated
    */
    function updateBalances(address targetAddress, uint256 totalDividend, bool isCollected, uint currentPeriodTimestamp, uint dividendPeriods) public {

        // update balances
        dividendSupply_ = dividendSupply_ - totalDividend;
        _balances[targetAddress] = _balances[targetAddress] + totalDividend;

        // emit event
        if (isCollected) {
            emit DividendCollected(targetAddress, totalDividend, dividendPeriods);
        } else {
            emit DividendSent(targetAddress, totalDividend, dividendPeriods);
        }

        // set last payment timestamp for address
        lastPaymentTimestamp[targetAddress] = currentPeriodTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title DividendBasic
 * @dev DividendToken interface
 */
interface IDividendToken {
  function totalDividendSupply() external view returns (uint256); 
  function addToDividendSupply(address _from, uint256 value) external returns (bool);
  function updateDividendBlacklist(address _address, bool isBlacklisted) external;

  event DividendBlacklistUpdated(address indexed _newAddress, bool isBlacklisted);
  event DividendTimeStampInitialized(address indexed _who, uint timestamp, uint currentPeriodNumber);
  event DividendCollected(address indexed _by, uint256 value, uint dividendPeriods);
  event DividendSent(address indexed _to, uint256 value, uint dividendPeriods);
  event BurnToDividend(address indexed _from, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDividendToken.sol";
import '../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol';
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract DividendToken is Ownable, IDividendToken {

    using SafeMath for uint256;
    mapping(address => uint256) internal lastPaymentTimestamp;
    mapping(address => bool) internal dividendBlacklist;
    uint256 internal dividendSupply_;

    /**
    * @dev Total dividend supply left
    */
    function totalDividendSupply() external view returns (uint256) {
        return dividendSupply_;
    }

    /**
    * @dev Returns the last payment timestamp of msg sender
    */
    function getLastPaymentTimestamp() external view returns (uint256) {
        return lastPaymentTimestamp[msg.sender];
    }

    /**
    * @dev Transfer tokens to Dividend Supply
    */
    function addToDividendSupply(address from, uint256 value) public returns (bool) {
        dividendSupply_ = dividendSupply_.add(value);
        emit BurnToDividend(from, value);
        return true;
    }

    /**
    * @dev Add to DividendBlacklist
    */
    function updateDividendBlacklist(address targetAddress, bool isBlacklisted) public onlyOwner {
        dividendBlacklist[targetAddress] = isBlacklisted;
        emit DividendBlacklistUpdated(targetAddress, isBlacklisted);
    }
}