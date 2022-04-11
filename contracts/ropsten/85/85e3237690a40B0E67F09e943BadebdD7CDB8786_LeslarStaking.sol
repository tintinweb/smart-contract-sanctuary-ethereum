pragma solidity ^0.8.4;

import "./dependency/LESLAR.sol";

contract LeslarStaking {

  string public name = 'Leslar Staking';
  address public owner;
  LESLAR public leslar;

  address[] public stakers;

  mapping(address => uint) public stakingBalance;
  mapping(address => bool) public hasStaked;
  mapping(address => bool) public isStaking;

  constructor(LESLAR _leslar){ 
    leslar = _leslar;
  }

  //staking function
  function depositTokens(uint _amount) public {
    require(_amount > 0, 'Amount cannot be 0');
    //transfer leslar token to this contract address for staking
    leslar.transferFrom(msg.sender, address(this), _amount);

    //update staking balance
    stakingBalance[msg.sender] += _amount;

    if(!hasStaked[msg.sender]){
      stakers.push(msg.sender);
    }

    //update staking balance
    isStaking[msg.sender] = true;
    hasStaked[msg.sender] = true;
    
  }

  //unstake tokens
  function unstakeTokens() public{
    uint256 balance = stakingBalance[msg.sender];
    require(balance > 0, 'Staking balance cannot be less than zero');
    uint256 unstakeFee = balance * 10 / 100;
    uint256 unstakeBalance = balance - unstakeFee;
    //transfer the token to specified contract address from our bank
    leslar.transfer(msg.sender, unstakeBalance);
    //reset staking balance
    stakingBalance[msg.sender] = 0;

    //update staking status
    isStaking[msg.sender] = false;
  }
  
  //issue rewards
  
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//    __   __________   ___   ___ 
//   / /  / __/ __/ /  / _ | / _ \
//  / /__/ _/_\ \/ /__/ __ |/ , _/
// /____/___/___/____/_/ |_/_/|_| 
// LESLAR METAVERSE

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./abstracts/core/Tokenomics.sol";
import "./abstracts/core/RFI.sol";
import "./abstracts/features/Expensify.sol";
import "./abstracts/features/TxPolice.sol";
import "./abstracts/core/Pancake.sol";
import "./abstracts/helpers/Helpers.sol";

contract LESLAR is 
	IERC20Metadata, 
	Context, 
	Ownable,
	Tokenomics, 
	RFI,
	TxPolice,
	Expensify
{
	using SafeMath for uint256;

	constructor() {
		// Set special addresses
		specialAddresses[owner()] = true;
		specialAddresses[address(this)] = true;
		specialAddresses[deadAddr] = true;
		// Set limit exemptions
		LimitExemptions memory exemptions;
		exemptions.all = true;
		limitExemptions[owner()] = exemptions;
		limitExemptions[address(this)] = exemptions;
	}

/* ------------------------------- IERC20 Meta ------------------------------ */

	function name() external pure override returns(string memory) { return NAME;}
	function symbol() external pure override returns(string memory) { return SYMBOL;}
	function decimals() external pure override returns(uint8) { return DECIMALS; }	

/* -------------------------------- Overrides ------------------------------- */

	function beforeTokenTransfer(address from, address to, uint256 amount) 
		internal 
		override 
	{
		// Make sure max transaction and wallet size limits are not exceeded.
		TransactionLimitType[2] memory limits = [
			TransactionLimitType.TRANSACTION, 
			TransactionLimitType.WALLET
		];
		guardMaxLimits(from, to, amount, limits);
		enforceCyclicSellLimit(from, to, amount);
		// Try to execute all our accumulator features.
		triggerFeatures(from);
	}

	function takeFee(address from, address to) 
		internal 
		view 
		override 
		returns(bool) 
	{
		return canTakeFee(from, to);
	}

/* -------------------------- Accumulator Triggers -------------------------- */

	// Will keep track of how often each trigger has been called already.
	uint256 internal triggerCount = 0;
	// Will keep track of trigger indexes, which can be triggered during current tx.
	uint8 internal canTrigger = 0;

	/**
	* @notice Convenience wrapper function which tries to trigger our custom 
	* features.
	*/
	function triggerFeatures(address from) private {
		uint256 contractTokenBalance = balanceOf(address(this));
		// First determine which triggers can be triggered.
		if (!liquidityPools[from]) {
			if (canTax(contractTokenBalance)) {
				canTrigger = 1;
			}
		}

		// Avoid falling into a tx loop.
		if (!inTriggerProcess) {
			if (canTax(contractTokenBalance)) {
				_triggerTax();
				delete canTrigger;
			}
		}
	}

/* ---------------------------- Internal Triggers --------------------------- */

	/**
	* @notice Triggers tax and updates triggerLog
	*/
	function _triggerTax() internal {
		taxify(accumulatedForTax);
		triggerCount = triggerCount.add(1);
	}

/* ---------------------------- External Triggers --------------------------- */

	/**
	* @notice Allows to trigger tax manually.
	*/
	function triggerTax() external onlyOwner {
		uint256 contractTokenBalance = balanceOf(address(this));
		require(canTax(contractTokenBalance), "Not enough tokens accumulated.");
		_triggerTax();
	}
}

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Tokenomics is IERC20, Ownable {
	using SafeMath for uint256;
    mapping (address => bool) private _isBot;

/* ---------------------------------- Token --------------------------------- */

	string internal constant NAME = "LESLAR Metaverse";
	string internal constant SYMBOL = "LESLAR";

	uint8 internal constant DECIMALS = 9;
	uint256 internal constant ZEROES = 10 ** DECIMALS;

	uint256 private constant MAX = ~uint256(0);
	uint256 internal constant _tTotal = 1000000000000 * ZEROES;
	uint256 internal _rTotal = (MAX - (MAX % _tTotal));

	address public deadAddr = 0x000000000000000000000000000000000000dEaD;

/* ---------------------------------- Fees ---------------------------------- */

	// To be collected for tax
	uint256 public _taxFee = 3;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousTaxFee = _taxFee;
	// Will keep tabs on the amount which should be taken from wallet for taxes.
	uint256 public accumulatedForTax = 0;

	/**
	 * @notice Allows setting Tax fee.
	 */
	function setTaxFee(uint256 fee)
		external 
		onlyOwner
		sameValue(_taxFee, fee)
	{
		_taxFee = fee;
	}

	/**
	 * @notice Allows temporarily set all feees to 0. 
	 * It can be restored later to the previous fees.
	 */
	function disableAllFeesTemporarily()
		external
		onlyOwner
	{
		removeAllFee();
	}

	/**
	 * @notice Restore all fees from previously set.
	 */
	function restoreAllFees()
		external
		onlyOwner
	{
		restoreAllFee();
	}

	/**
	 * @notice Temporarily stops all fees. Caches the fees into secondary variables,
	 * so it can be reinstated later.
	 */
	function removeAllFee() internal {
		if (_taxFee == 0) return;

		_previousTaxFee = _taxFee;

		_taxFee = 0;
	}

	/**
	 * @notice Restores all fees removed previously, using cached variables.
	 */
	function restoreAllFee() internal {
		_taxFee = _previousTaxFee;
	}

	function calculateTaxFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_taxFee).mul(multiplier).div(10 ** 2);
	}

/* --------------------------- Triggers and limits -------------------------- */

	// One contract accumulates 0.01% of total supply, trigger tax wallet sendout.
	uint256 public minToTax = _tTotal.mul(1).div(10000);

	/**
	@notice External function allowing to set minimum amount of tokens which trigger
	* tax send out.
	*/
	function setMinToTax(uint256 minTokens) 
		external 
		onlyOwner 
		supplyBounds(minTokens)
	{
		minToTax = minTokens * 10 ** 5;
	}

/* --------------------------------- IERC20 --------------------------------- */
	function totalSupply() external pure override returns(uint256) {
		return _tTotal;
	}

	function totalFees() external view returns(uint256) { 
		return _taxFee; 
	}

/* ---------------------------- Anti Bot System --------------------------- */

    function setAntibot(address account, bool _bot) external onlyOwner{
        require(_isBot[account] != _bot, "Value already set");
        _isBot[account] = _bot;
    }

    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }

/* -------------------------------- Modifiers ------------------------------- */

    // Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function rescueBEP20Tokens(address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

/* -------------------------------- Modifiers ------------------------------- */

	modifier supplyBounds(uint256 minTokens) {
		require(minTokens * 10 ** 5 > 0, "Amount must be more than 0");
		require(minTokens * 10 ** 5 <= _tTotal, "Amount must be not bigger than total supply");
		_;
	}

	modifier sameValue(uint256 firstValue, uint256 secondValue) {
		require(firstValue != secondValue, "Already set to this value.");
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/Tokenomics.sol";
import "../core/Pancake.sol";

abstract contract RFI is IERC20, Ownable, Tokenomics, Pancake {
	using SafeMath for uint256;

	mapping(address => uint256) internal _rOwned;
	mapping(address => uint256) internal _tOwned;
	mapping(address => mapping(address => uint256)) private _allowances;

	struct TValues {
		uint256 tTransferAmount;
		uint256 tFee;
	}

	struct RValues {
		uint256 rAmount;
		uint256 rTransferAmount;
		uint256 rFee;
	}

	constructor() {
		// Assigns all reflected tokens to the deployer on creation
		_rOwned[_msgSender()] = _rTotal;

		emit Transfer(address(0), _msgSender(), _tTotal);
	}

	/**
	 * @notice Calculates all values for "total" and "reflected" states.
	 * @param tAmount Token amount related to which, all values are calculated.
	 */
	function _getValues(
		uint256 tAmount
	) private view returns(
		TValues memory tValues, RValues memory rValues
	) {
		TValues memory tV = _getTValues(tAmount);
		RValues memory rV = _getRValues(
			tAmount,
			tV.tFee,
			_getRate()
		);
		return (tV, rV);
	}

	/**
	 * @notice Calculates values for "total" states.
	 * @param tAmount Token amount related to which, total values are calculated.
	 */
	function _getTValues(
		uint256 tAmount
	) private view returns(TValues memory tValues) {
		TValues memory tV;
		tV.tFee = calculateTaxFee(tAmount, 1);

		uint256 fees = tV.tFee;
		tV.tTransferAmount = tAmount.sub(fees);
		return tV;
	}

	/**
	 * @notice Calculates values for "reflected" states.
	 * @param tAmount Token amount related to which, reflected values are calculated.
	 * @param tFee Total fee related to which, reflected values are calculated.
	 * @param currentRate Rate used to calculate reflected values.
	 */
	function _getRValues(
		uint256 tAmount,
		uint256 tFee,
		uint256 currentRate
	) private pure returns(RValues memory rValues) {
		RValues memory rV;
		rV.rAmount = tAmount.mul(currentRate);
		uint256 rFee = tFee.mul(currentRate);
		uint256 fees = rFee;
		rV.rTransferAmount = rV.rAmount.sub(fees);
		return rV;
	}

	/**
	 * @notice Calculates the rate of total suply to reflected supply.
	 */
	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	/**
	 * @notice Returns totals for "total" supply and "reflected" supply.
	 */
	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}

	function tokenFromReflection(
		uint256 rAmount
	) public view returns(uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		uint256 currentRate = _getRate();
		return rAmount.div(currentRate);
	}

/* --------------------------------- Custom --------------------------------- */

	/**
	 * @notice ERC20 token transaction approval with allowance.
	 */
	function rfiApprove(
		address ownr,
		address spender,
		uint256 amount
	) internal {
		require(ownr != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[ownr][spender] = amount;
		emit Approval(ownr, spender, amount);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");

		// Override this in the main contract to plug your features inside transactions.
		beforeTokenTransfer(from, to, amount);

		// Transfer amount, it will take tax, liquidity fee
		bool take = takeFee(from, to);
		_tokenTransfer(from, to, amount, take);
	}

	/**
	 * @notice Performs token transfer with fees.
	 * @param sender Address of the sender.
	 * @param recipient Address of the recipient.
	 * @param amount Amount of tokens to send.
	 * @param take Toggle on/off fees.
	 */
	function _tokenTransfer(
		address sender,
		address recipient,
		uint256 amount,
		bool take
	) private {

		// Remove fees for this transaction if needed.
		if (!take)
			removeAllFee();

		// Calculate all reflection magic...
		(TValues memory tV, RValues memory rV) = _getValues(amount);

		// Adjust reflection states
		_rOwned[sender] = _rOwned[sender].sub(rV.rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rV.rTransferAmount);

		// Calcuate fees. If above fees were removed, then these will obviously
		// not take any fees.
		_takeTax(tV.tFee);

		emit Transfer(sender, recipient, tV.tTransferAmount);

		// Reinstate fees if they were removed for this transaction.
		if (!take)
			restoreAllFee();
	}

	/**
	* @notice Override this function to intercept the transaction and perform 
	* additional checks or perform certain functions before allowing transaction
	* to complete. You can prevent transaction to complete here too.
	*/
	function beforeTokenTransfer(
		address from, 
		address to, 
		uint256 amount
	) virtual internal {


	}

	function takeFee(address from, address to) virtual internal returns(bool) {


		return true;
	}

/* ------------------------------- Custom fees ------------------------------ */
	/**
	* @notice Collects tokens from tax fee. Accordingly adjusts "reflected" 
	amounts. 
	*/
	function _takeTax(
		uint256 tFee
	) private {
		uint256 currentRate = _getRate();
		uint256 rFee = tFee.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rFee);
		// Keep tabs, so when processing is triggered, we know how much should we take.
		accumulatedForTax = accumulatedForTax.add(tFee);
	}

/* --------------------------------- IERC20 --------------------------------- */

	function balanceOf(
		address account
	) public view override returns(uint256) {
		return tokenFromReflection(_rOwned[account]);
	}

	function transfer(
		address recipient,
		uint256 amount
	) public override returns(bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(
		address ownr,
		address spender
	) public view override returns(uint256) {
		return _allowances[ownr][spender];
	}

	function approve(
		address spender,
		uint256 amount
	) public override returns(bool) {
		rfiApprove(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override returns(bool) {
		_transfer(sender, recipient, amount);
		rfiApprove(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"ERC20: transfer amount exceeds allowance"
			)
		);
		return true;
	}

	function increaseAllowance(
		address spender,
		uint256 addedValue
	) public virtual returns(bool) {
		rfiApprove(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}

	function decreaseAllowance(
		address spender,
		uint256 subtractedValue
	) public virtual returns(bool) {
		rfiApprove(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender]
			.sub(subtractedValue, "ERC20: decreased allowance below zero")
		);
		return true;
	}

/* -------------------------------- Modifiers ------------------------------- */

	modifier onlyOwnerOrHolder {
		require(
			owner() == _msgSender() || balanceOf(_msgSender()) > 0, 
			"Only the owner and the holder can use this feature."
			);
		_;
	}

	modifier onlyHolder {
		require(
			balanceOf(_msgSender()) > 0, 
			"Only the holder can use this feature."
			);
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../helpers/Helpers.sol";
import "../core/Pancake.sol";
import "../core/Tokenomics.sol";
import "../features/TxPolice.sol";

abstract contract Expensify is Ownable, Helpers, Tokenomics, Pancake, TxPolice {
	using SafeMath for uint256;
	address public productDevWallet;
	address public devWallet;
	address public marketingWallet;
	// Expenses fee accumulated amount will be divided using these.
	uint256 public productDevShare = 30; // 30%
	uint256 public devShare = 30; // 30%
	uint256 public marketingShare = 40; // 40%

	/**
	* @notice External function allowing to set/change product dev wallet.
	* @param wallet: this wallet will receive product dev share.
	* @param share: multiplier will be divided by 100. 30 -> 30%, 3 -> 3% etc.
	*/
	function setProductDevWallet(address wallet, uint256 share) 
		external onlyOwner legitWallet(wallet) 
	{
		productDevWallet = wallet;
		productDevShare = share;
		swapExcludedFromFee(wallet, productDevWallet);
	}

	/**
	* @notice External function allowing to set/change dev wallet.
	* @param wallet: this wallet will receive dev share.
	* @param share: multiplier will be divided by 100. 30 -> 30%, 3 -> 3% etc.
	*/
	function setDevWallet(address wallet, uint256 share) 
		external onlyOwner legitWallet(wallet)
	{
		devWallet = wallet;
		devShare = share;
		swapExcludedFromFee(wallet, devWallet);
	}

	/**
	* @notice External function allowing to set/change marketing wallet.
	* @param wallet: this wallet will receive marketing share.
	* @param share: multiplier will be divided by 100. 30 -> 30%, 3 -> 3% etc.
	*/
	function setMarketingWallet(address wallet, uint256 share) 
		external onlyOwner legitWallet(wallet)
	{
		marketingWallet = wallet;
		marketingShare = share;
		swapExcludedFromFee(wallet, marketingWallet);
	}

	/** 
	* @notice Checks if all required prerequisites are met for us to trigger 
	* taxes send out event.
	*/
	function canTax(
		uint256 contractTokenBalance
	) 
		internal 
		view
		returns(bool) 
	{
		return contractTokenBalance >= accumulatedForTax
            && accumulatedForTax >= minToTax;
	}

	/**
	* @notice Splits tokens into pieces for product dev, dev and marketing wallets 
	* and sends them out.
	* Note: Shares must add up to 100, otherwise tax fee will not be 
		distributed properly. And that can invite many other issues.
		So we can't proceed. You will see "Taxify" event triggered on 
		the blockchain with "0, 0, 0" then. This will guide you to check and fix
		your share setup.
		Wallets must be set. But we will not use "require", so not to trigger 
		transaction failure just because someone forgot to set up the wallet 
		addresses. If you see "Taxify" event with "0, 0, 0" values, then 
		check if you have set the wallets.
		@param tokenAmount amount of tokens to take from balance and send out.
	*/
	function taxify(
		uint256 tokenAmount
	) internal lockTheProcess {
		uint256 productDevPiece;
		uint256 devPiece;
		uint256 marketingPiece;

		if (
			productDevShare.add(devShare).add(marketingShare) == 100
			&& productDevWallet != address(0) 
			&& devWallet != address(0)
			&& marketingWallet != address(0)
		) {
			productDevPiece = tokenAmount.mul(productDevShare).div(100);
			devPiece = tokenAmount.mul(devShare).div(100);
			// Make sure all tokens are distributed.
			marketingPiece = tokenAmount.sub(productDevPiece).sub(devPiece);
			_transfer(address(this), productDevWallet, productDevPiece);
			_transfer(address(this), devWallet, devPiece);
			_transfer(address(this), marketingWallet, marketingPiece);
			// Reset the accumulator, only if tokens actually sent, otherwise we keep
			// acumulating until above mentioned things are fixed.
			accumulatedForTax = 0;
		}
		
 		emit TaxifyDone(productDevPiece, devPiece, marketingPiece);
	}

/* --------------------------------- Events --------------------------------- */
	event TaxifyDone(
		uint256 tokensSentToProductDev,
		uint256 tokensSentToDev,
		uint256 tokensSentToMarketing
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../core/Pancake.sol";
import "../core/Tokenomics.sol";
import "../core/RFI.sol";
import "../core/Supply.sol";

abstract contract TxPolice is Tokenomics, Pancake, RFI, Supply {
	using SafeMath for uint256;
	// Wallet hard cap 2% of total supply
	uint256 public maxWalletSize = _tTotal.mul(2).div(100);
	// Can transfer wallet-to-wallet 100%
	uint256 public maxTxAmount = _tTotal.mul(100).div(100);
	// Convenience enum to differentiate transaction limit types.
	enum TransactionLimitType { TRANSACTION, WALLET, SELL }
	// Convenience enum to differentiate transaction types.
	enum TransactionType { REGULAR, SELL, BUY }

	// Global toggle to avoid trigger loops
	bool internal inTriggerProcess;
	modifier lockTheProcess {
		inTriggerProcess = true;
		_;
		inTriggerProcess = false;
	}

	// Sometimes you just have addresses which should be exempt from any 
	// limitations and fees.
	mapping(address => bool) public specialAddresses;

	// Toggle multiple exemptions from transaction limits.
	struct LimitExemptions {
		bool all;
		bool transaction;
		bool wallet;
		bool sell;
		bool fees;
	}

	// Keeps a record of addresses with limitation exemptions
	mapping(address => LimitExemptions) internal limitExemptions;

/* --------------------------- Exemption Utilities -------------------------- */

	/**
	* @notice External function allowing owner to toggle various limit exemptions
	* for any address.
	*/
	function toggleLimitExemptions(
		address addr, 
		bool allToggle, 
		bool txToggle, 
		bool walletToggle, 
		bool sellToggle,
		bool feesToggle
	) 
		public 
		onlyOwner
	{
		LimitExemptions memory ex = limitExemptions[addr];
		ex.all = allToggle;
		ex.transaction = txToggle;
		ex.wallet = walletToggle;
		ex.sell = sellToggle;
		ex.fees = feesToggle;
		limitExemptions[addr] = ex;
	}

	/**
	* @notice External function allowing owner toggle any address as special address.
	*/
	function toggleSpecialWallets(address specialAddr, bool toggle) 
		external 
		onlyOwner 
	{
		specialAddresses[specialAddr] = toggle;
	}

/* ------------------------------- Sell Limit ------------------------------- */
	// Toggle for sell limit feature
	bool public isSellLimitEnabled = true;
	// Sell limit cycle period
	uint256 public sellCycleHours = 24;
	// Hour multiplier
	uint256 private hour = 60 * 60;
	// Changing this you can increase/decrease decimals of your maxSellAllowancePerCycle 
	uint256 public maxSellAllowanceMultiplier = 100;
	// (address => amount)
	mapping(address => uint256) private cycleSells;
	// (address => lastTimestamp)
	mapping(address => uint256) private lastSellTimestamp;

	/**
	* @notice Tracks and limits sell transactions per user per cycle set.
	* Unless user is a special address or has exemptions.
	*/
	function enforceCyclicSellLimit(address from, address to, uint256 amount) 
		internal 
	{
		// Identify if selling... otherwise quit.
		bool isSell = getTransactionType(from, to) == TransactionType.SELL;

		// Guards
		// Get exemptions if any for tx sender and receiver.
		if (
			limitExemptions[from].all
			|| limitExemptions[from].sell
			|| specialAddresses[from] 
			|| !isSellLimitEnabled
		) { 

			return; 
		}

		if (!isSell) { return; }

		// First check if sell amount doesn't exceed total max allowance.
		uint256 maxAllowance = maxSellAllowancePerCycle();

		require(amount <= maxAllowance, "Can't sell more than cycle allowance!");

		// Then check if sell cycle has passed. If so, just update the maps and quit.
		if (hasSellCycleEnded(from)) {
			lastSellTimestamp[from] = block.timestamp;
			cycleSells[from] = amount;
			return;
		}

		// If cycle has not yet passed... check if combined amount doesn't excceed the max allowance.
		uint256 combinedAmount = amount.add(cycleSells[from]);

		require(combinedAmount <= maxAllowance, "Combined cycle sell amount exceeds cycle allowance!");

		// If all good just increment sells map. (don't update timestamp map, cause then 
		// sell cycle will never end for this poor holder...)
		cycleSells[from] = combinedAmount;
		return;
	}

	/**
	 * @notice Calculates current maximum sell allowance per day based on the 
	 * total circulating supply.
	 */
	function maxSellAllowancePerCycle() public view returns(uint256) {
		// 1% of total circulating supply.
		return totalCirculatingSupply().mul(1).div(maxSellAllowanceMultiplier);
	}

	/**
	* @notice Allows to adjust your maxSellAllowancePerCycle.
	* 100 = 1% 
	*/
	function setMaxSellAllowanceMultiplier(uint256 mult) external onlyOwner {
		require(mult > 0, "Multiplier can't be 0.");
		maxSellAllowanceMultiplier = mult;
	}

	function hasSellCycleEnded(address holderAddr) 
		internal 
		view  
		returns(bool) 
	{
		uint256 lastSell = lastSellTimestamp[holderAddr];
		uint256 timeSinceLastSell = block.timestamp.sub(lastSell);
		bool cycleEnded = timeSinceLastSell >= sellCycleHours.mul(hour);

		return cycleEnded;
	}

	/**
	* @notice External functions which allows to set selling limit period.
	*/
	function setSellCycleHours(uint256 hoursCycle) external onlyOwner {
		require(hoursCycle >= 0, "Hours can't be 0.");
		sellCycleHours = hoursCycle;
	}

	/**
	* @notice External functions which allows to disable selling limits.
	*/
	function disableSellLimit() external onlyOwner {
		require(isSellLimitEnabled, "Selling limit already enabled.");
		isSellLimitEnabled = false;
	}

	/**
	* @notice External functions which allows to enable selling limits.
	*/
	function enableSellLimit() external onlyOwner {
		require(!isSellLimitEnabled, "Selling limit already disabled.");
		isSellLimitEnabled = true;
	}

	/**
	* @notice External function which can be called by a holder to see how much 
	* sell allowance is left for the current cycle period.
	*/
	function sellAllowanceLeft() external view returns(uint256) {
		address sender = _msgSender();
		bool isSpecial = specialAddresses[sender];
		bool isExemptFromAll = limitExemptions[sender].all;
		bool isExemptFromSell = limitExemptions[sender].sell;
		bool isExemptFromWallet = limitExemptions[sender].wallet;

		// First guard exemptions
		if (
			isSpecial || isExemptFromAll 
			|| (isExemptFromSell && isExemptFromWallet)) 
		{
			return balanceOf(sender);
		} else if (isExemptFromSell && !isExemptFromWallet) {
			return maxWalletSize;
		}

		// Next quard toggle and check cycle
		uint256 maxAllowance = maxWalletSize;
		if (isSellLimitEnabled) {
			maxAllowance = maxSellAllowancePerCycle();
			if (!hasSellCycleEnded(sender)) {
				maxAllowance = maxAllowance.sub(cycleSells[sender]);
			}
		} else if (isExemptFromWallet) {
			maxAllowance = balanceOf(sender);
		}
		return maxAllowance;
	}

/* --------------------------------- Guards --------------------------------- */

	/**
	* @notice Checks passed multiple limitTypes and if required enforces maximum
	* limits.
	* NOTE: extend this function with more limit types if needed.
	*/
	function guardMaxLimits(
		address from, 
		address to, 
		uint256 amount,
		TransactionLimitType[2] memory limitTypes
	) internal view {
		// Get exemptions if any for tx sender and receiver.
		LimitExemptions memory senderExemptions = limitExemptions[from];
		LimitExemptions memory receiverExemptions = limitExemptions[to];

		// First check if any special cases
		if (
			senderExemptions.all && receiverExemptions.all 
			|| specialAddresses[from] 
			|| specialAddresses[to] 
			|| liquidityPools[to]
		) { return; }

		// If no... then go through each limit type and apply if no exemptions.
		for (uint256 i = 0; i < limitTypes.length; i += 1) {
			if (
				limitTypes[i] == TransactionLimitType.TRANSACTION 
				&& !senderExemptions.transaction
			) {
				require(
					amount <= maxTxAmount,
					"Transfer amount exceeds the maxTxAmount."
				);
			}
			if (
				limitTypes[i] == TransactionLimitType.WALLET 
				&& !receiverExemptions.wallet
			) {
				uint256 toBalance = balanceOf(to);
				require(
					toBalance.add(amount) <= maxWalletSize,
					"Exceeds maximum wallet size allowed."
				);
			}
		}
	}

/* ---------------------------------- Fees ---------------------------------- */

function canTakeFee(address from, address to) 
	internal view returns(bool) 
{	
	bool take = true;
	if (
		limitExemptions[from].all 
		|| limitExemptions[to].all
		|| limitExemptions[from].fees 
		|| limitExemptions[to].fees 
		|| specialAddresses[from] 
		|| specialAddresses[to]
	) { take = false; }

	return take;
}

	/**
	* @notice Updates old and new wallet fee exemptions.
	*/
	function swapExcludedFromFee(address newWallet, address oldWallet) internal {
		if (oldWallet != address(0)) {
			toggleLimitExemptions(oldWallet, false, false, false, false, false);
		}
		toggleLimitExemptions(newWallet, false, false, false, true, true);
	}

/* --------------------------------- Helpers -------------------------------- */

	/**
	* @notice Helper function to determine what kind of transaction it is.
	* @param from transaction sender
	* @param to transaction receiver
	*/
	function getTransactionType(address from, address to) 
		internal view returns(TransactionType)
	{
		if (liquidityPools[from] && !liquidityPools[to]) {
			// LP -> addr
			return TransactionType.BUY;
		} else if (!liquidityPools[from] && liquidityPools[to]) {
			// addr -> LP
			return TransactionType.SELL;
		}
		return TransactionType.REGULAR;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Pancake is Ownable {
	using SafeMath for uint256;
	// Using Uniswap lib, because Pancakeswap forks are trash ATM...
	IUniswapV2Router02 internal uniswapV2Router;
	// We will call createPair() when we decide. To avoid snippers and bots.
	address internal uniswapV2Pair;
	// This will be set when we call initDEXRouter().
	address internal routerAddr;
	// To keep track of all LPs.
	mapping(address => bool) public liquidityPools;

	// To receive BNB from pancakeV2Router when swaping
	receive() external payable {}

	/**
	* @notice Initialises PCS router using the address. In addition creates a pair.
	* @param router Pancakeswap router address
	*/
	function initDEXRouter(address router) 
		external
		onlyOwner
	{
		// In case we already have set uniswapV2Pair before, remove it from LPs mapping.
		if (uniswapV2Pair != address(0)) {
			removeAddressFromLPs(uniswapV2Pair);
		}
		routerAddr = router;
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
			address(this), 
			_uniswapV2Router.WETH()
		);
		uniswapV2Router = _uniswapV2Router;
		addAddressToLPs(uniswapV2Pair);
		emit RouterSet(router, uniswapV2Pair);
	}

	/**
	 * @notice Swaps passed tokens for BNB using Pancakeswap router and returns 
	 * actual amount received.
	 */
	function swapTokensForBnb(
		uint256 tokenAmount
	) internal returns(uint256) {
		uint256 initialBalance = address(this).balance;
		// generate the pancake pair path of token -> wbnb
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		// Make the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of BNB
			path,
			address(this),
			block.timestamp
		);

		uint256 bnbReceived = address(this).balance.sub(initialBalance);
		return bnbReceived;
	}

	/**
	* @notice Adds address to a liquidity pool map. Can be called externaly.
	*/
	function addAddressToLPs(address lpAddr) public onlyOwner {
		liquidityPools[lpAddr] = true;
	}

	/**
	* @notice Removes address from a liquidity pool map. Can be called externaly.
	*/
	function removeAddressFromLPs(address lpAddr) public onlyOwner {
		liquidityPools[lpAddr] = false;
	}

/* --------------------------------- Events --------------------------------- */
	event RouterSet(address indexed router, address indexed pair);

/* -------------------------------- Modifiers ------------------------------- */
	modifier pcsInitialized {
		require(routerAddr != address(0), 'Router address has not been set!');
		require(uniswapV2Pair != address(0), 'PCS pair not created yet!');
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Helpers {

/* -------------------------------- Modifiers ------------------------------- */

	modifier legitWallet(address wallet) {
		require(wallet != address(0), "Wallet address must be set!");
		require(wallet != address(this), "Wallet address can't be this contract.");
		_;
	}
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
pragma solidity ^0.8.4;

import "./Tokenomics.sol";
import "./RFI.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Supply is Tokenomics, RFI {
	using SafeMath for uint256;
	/**
	 * @notice Calculates current total circulating supply by substracting "burned"
	 * tokens.
	 */
	function totalCirculatingSupply() public view returns(uint256) {
		return _tTotal.sub(balanceOf(deadAddr));
	}
}