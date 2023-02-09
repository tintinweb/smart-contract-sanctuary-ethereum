/**
 *Submitted for verification at Etherscan.io on 2023-02-09
*/

// SPDX-License-Identifier: MIT

// File: contracts/Peanut/IUniswapV2Router01.sol


pragma solidity ^0.8.4;

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

// File: contracts/Peanut/IUniswapV2Router02.sol


pragma solidity ^0.8.4;


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

// File: contracts/Peanut/IUniswapV2Pair.sol


pragma solidity ^0.8.4;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// File: contracts/Peanut/IUniswapV2Factory.sol


pragma solidity ^0.8.4;

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
// File: contracts/Peanut/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.4;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/Peanut/Address.sol



// Version
pragma solidity ^0.8.4;

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(
		data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
	internal
	view
	returns (bytes memory)
	{
		return
		functionStaticCall(
			target,
			data,
			"Address: low-level static call failed"
		);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return
		functionDelegateCall(
			target,
			data,
			"Address: low-level delegate call failed"
		);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
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
// File: contracts/Peanut/Context.sol



pragma solidity ^0.8.4;

/* Provides information about the current execution context, including the
   sender of the transaction and its data. While these are generally available
   via msg.sender and msg.data, they should not be accessed in such a direct
   manner, since when dealing with meta-transactions the account sending and
   paying for execution may not be the actual sender (as far as an application
   is concerned). */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: contracts/Peanut/Ownable.sol



pragma solidity ^0.8.4;


/* By default, the owner account will be the one that deploys the contract. This
   can later be ch4nged with {transferOwnership} */

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Initializes the contract setting the deployer as the initial owner.
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    //Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    /* Leaves the contract without owner. It will not be possible to call
       `onlyOwner` functions anymore. Can only be called by the current owner.

       Renouncing ownership will leave the contract without an owner,
       thereby removing any functionality that is only available to the owner.*/
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /* Transfers ownership of the contract to a new account (`newOwner`).
       Can only be called by the current owner. */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /*
       Transfers ownership of the contract to a new account (`newOwner`).
       Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
  
    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
// File: contracts/Peanut/Blacklist.sol



pragma solidity ^0.8.4;


abstract contract Blacklist is Ownable {
    mapping (address => bool) _isBlacklisted;
     

    function _blacklistAddress(address account) internal virtual {
        _isBlacklisted[account] = true;
    }
    
    function _unBlacklistAddress(address account) internal virtual {
        _isBlacklisted[account] = false;
    }
    
    function isBlacklisted(address account) public view returns(bool) {
        return _isBlacklisted[account];
    }
}
// File: contracts/Peanut/IERC20.sol



// Version
pragma solidity ^0.8.4;

// Interface
interface IERC20{

    // Returns the amount of tokens in existence
    function totalSupply() external view returns(uint256);

    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    //function burnByLEC(address account, uint256 amount) external;

    /* Moves `amount` tokens from the caller's account to `recipient`.
    Returns a boolean value indicating whether the operation succeeded. 
    Emits a {Transfer} event. */
    function transfer(address to, uint256 amount) external returns (bool);

    /* Returns the remaining number of tokens that `spender` will be
       allowed to spend on behalf of `owner` through {transferFrom}. This is
       zero by default.
       This value changes when {approve} or {transferFrom} are called */
    function allowance(address owner, address spender) external view returns (uint256);

     /* Sets `amount` as the allowance of `spender` over the caller's tokens.
        Returns a boolean value indicating whether the operation succeeded.
        Emits an {Approval} event. */
    function approve(address spender, uint256 amount) external returns (bool);

    /* Moves `amount` tokens from `sender` to `recipient` using the
       allowance mechanism. `amount` is then deducted from the caller's
       allowance.
       Returns a boolean value indicating whether the operation succeeded.
       Emits a {Transfer} event.*/
    function transferFrom( address from, address to, uint256 amount) external returns(bool);


    /* Emitted when `value` tokens are moved from one account (`from`) to
       another (`to`).*/
    event Transfer (address indexed from, address indexed to, uint value);

    /* Emitted when the allowance of a `spender` for an `owner` is set by
       a call to {approve}. `value` is the new allowance. */
    event Approval (address indexed owner, address indexed spender, uint value);
}
// File: contracts/Peanut/ERC20A.sol



// Version
pragma solidity ^0.8.4;











contract ERC20A is Context, IERC20, Ownable {
	using SafeMath for uint256;
    using Address for address;

    // Liquidity pool provider router
    IUniswapV2Router02 public uniswapV2Router;

    // This Token and WETH pair contract address.
    address public immutable uniswapV2Pair;

    // Keeps track of balances for address that are included in receiving reward.
    mapping (address => uint256) private _reflectionBalances;

    // Keeps track of balances for address that are excluded from receiving reward.
    mapping (address => uint256) private _tokenBalances;

    // Keeps track of which address are excluded from reward.
    mapping (address => bool) private _isExcludedFromReward;
    
    // An array of addresses that are excluded from reward.
    address[] private _excludedFromReward;

	string private _name;
	string private _symbol;
	uint8 private constant _decimals = 18;

    mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;

	address public lecProxyContractAddress;

    // ERC20 Token Standard
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 500000000 * 10**18; // Supply
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;
    
    bool public isTradingEnabled;

	// max wallet is 1.5% of _tTotal
	uint256 public maxWalletAmount = _tTotal * 150 / 10000;

    // max buy and sell tx is 0.5% of _tTotal
	uint256 public maxTxAmount = _tTotal * 50 / 10000;

	bool private _swapping;
	uint256 public minimumTokensBeforeSwap = 25000000 * (10**18);

    address public liquidityWallet;
	address public marketingWallet;
	address public buyBackWallet;
	address public charityWallet;
	address public teamWallet;

	address private constant burnAccount = 0x000000000000000000000000000000000000dEaD;

	// Anti Dump //
    mapping (address => uint256) public _lastTrade;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 60 seconds;

	mapping (address => bool) private _isBot;

    struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint8 liquidityFeeOnBuy;
		uint8 liquidityFeeOnSell;
		uint8 marketingFeeOnBuy;
		uint8 marketingFeeOnSell;
		uint8 buyBackFeeOnBuy;
		uint8 buyBackFeeOnSell;
		uint8 charityFeeOnBuy;
		uint8 charityFeeOnSell;
		uint8 teamFeeOnBuy;
		uint8 teamFeeOnSell;
		uint8 burnFeeOnBuy;
		uint8 burnFeeOnSell;
		uint8 holdersFeeOnBuy;
		uint8 holdersFeeOnSell;
	}

    // Base taxes
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,1,1,1,1,2,2,1,1,1,1,2,2,5,5);

    uint256 private _launchStartTimestamp;
	uint256 private _launchBlockNumber;
    uint256 private constant _blockedTimeLimit = 172800;
    mapping (address => bool) private _isBlocked;

    // Keeps track of which address are excluded from fee.
	mapping (address => bool) private _isExcludedFromFee;

    // Keeps track of which address are excluded from max transaction limit.
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;

    // Keeps track of which address are excluded from max wallet limit.
	mapping (address => bool) private _isExcludedFromMaxWalletLimit;

    // Keeps track of which address are allowed to trade when disabled.
	mapping (address => bool) private _isAllowedToTradeWhenDisabled;

    // Keeps track of which address are excluded from dividens.
	mapping (address => bool) private _isExcludedFromDividends;

    mapping (address => bool) private _feeOnSelectedWalletTransfers;
	address[] private _excludedFromDividends;
	mapping (address => bool) public automatedMarketMakerPairs;

	uint8 private _liquidityFee;
	uint8 private _marketingFee;
	uint8 private _buyBackFee;
	uint8 private _holdersFee;
	uint8 private _charityFee;
	uint8 private _teamFee;
	uint8 private _burnFee;
	uint8 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event WalletChange(string indexed walletIdentifier, address indexed newWallet, address indexed oldWallet);
	event FeeChange(string indexed identifier, uint8 liquidityFee, uint8 marketingFee, uint8 buyBackFee, uint8 charityFee, uint8 teamFee, uint8 burnFee, uint8 holdersFee);
	event CustomTaxPeriodChange(uint8 indexed newValue, uint8 indexed oldValue, string indexed taxType, bytes23 period);
	event BlockedAccountChange(address indexed holder, bool indexed status);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
	event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
	event TokenBurn(uint8 _burnFee, uint256 burnAmount);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
	event ClaimEthOverflow(uint256 amount);
	event TradingStatusChange(bool indexed newValue, bool indexed oldValue);
    event Burn(address from, uint256 amount);

    
	constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;

		liquidityWallet = owner();
        marketingWallet = 0xb6b57F814a613575218a922308C3c467548E8089;
		buyBackWallet = owner();
		charityWallet = 0x1CD36c3e1FFC515EF880F3a90668a3fFb35fF685;
		teamWallet = 0x6bdEe3F8C281C199f627602C000217708E8c8EB9;

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
			address(this),
			_uniswapV2Router.WETH()
		);
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

        // exclude this contract from receiving fee dividends.
		excludeFromDividends(address(0), true);
		excludeFromDividends(address(_uniswapV2Router), true);
		excludeFromDividends(address(_uniswapV2Pair), true);

		_isAllowedToTradeWhenDisabled[owner()] = true;

		_isExcludedFromMaxTransactionLimit[address(this)] = true;
		_isExcludedFromMaxTransactionLimit[owner()] = true;
        
		_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
		_isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
		_isExcludedFromMaxWalletLimit[address(this)] = true;
		_isExcludedFromMaxWalletLimit[owner()] = true;

		_rOwned[owner()] = _rTotal;
		emit Transfer(address(0), owner(), _tTotal);
    }


    // allow the contract to receive ETH
    receive() external payable {}

    //==========================================================
    // Setters
    //==========================================================

    // See {IERC20-transfer}.
    function transfer(address to, uint amount) external override returns (bool){
        _transfer(_msgSender(), to, amount);
        return true;
    }

    // See {IERC20-approve}.
    function approve(address spender, uint256 amount) public virtual override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // See {IERC20-transferFrom}.
    function transferFrom(address sender, address to, uint256 amount) external override returns (bool) {
        _transfer(sender, to, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    // Atomically increases the allowance granted to `spender` by the caller
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    // Atomically decreases the allowance granted to `spender` by the caller
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    // Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function activateTrading() external onlyOwner {
		isTradingEnabled = true;
        if (_launchStartTimestamp == 0) {
            _launchStartTimestamp = block.timestamp;
            _launchBlockNumber = block.number;
        }
		emit TradingStatusChange(true, false);
	}

	function deactivateTrading() external onlyOwner {
		isTradingEnabled = false;
		emit TradingStatusChange(false, true);
	}

	function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}

    function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
		require(_feeOnSelectedWalletTransfers[account] != value, "Peanut: The selected wallet is already set to the value ");
		_feeOnSelectedWalletTransfers[account] = value;
		emit FeeOnSelectedWalletTransfersChange(account, value);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "Peanut: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}

    function blockAccount(address account) external onlyOwner {
		require(!_isBlocked[account], "Peanut: Account is already blocked");
		if (_launchStartTimestamp > 0) {
			require((block.timestamp - _launchStartTimestamp) < _blockedTimeLimit, "Peanut: Time to block accounts has expired");
		}
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}

	function unblockAccount(address account) external onlyOwner {
		require(_isBlocked[account], "Peanut: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}

	function excludeFromFees(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "Peanut: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}

	function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "Peanut: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}

	function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "Peanut: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
		emit ExcludeFromMaxWalletChange(account, excluded);
	}

	function excludeFromDividends(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromDividends[account] != excluded, "Peanut: Account is already the value of 'excluded'");
		if(excluded) {
			if(_rOwned[account] > 0) {
				_tOwned[account] = tokenFromReflection(_rOwned[account]);
			}
			_isExcludedFromDividends[account] = excluded;
			_excludedFromDividends.push(account);
		} else {
			for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
				if (_excludedFromDividends[i] == account) {
					_excludedFromDividends[i] = _excludedFromDividends[_excludedFromDividends.length - 1];
					_tOwned[account] = 0;
					_isExcludedFromDividends[account] = false;
					_excludedFromDividends.pop();
					break;
				}
			}
		}
		emit ExcludeFromDividendsChange(account, excluded);
	}

	function setWallets(address newLiquidityWallet, address newMarketingWallet, address newBuyBackWallet, address newCharityWallet, address newTeamWallet) external onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
			require(newLiquidityWallet != address(0), "Peanut: The liquidityWallet cannot be 0");
			emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(marketingWallet != newMarketingWallet) {
			require(newMarketingWallet != address(0), "Peanut: The marketingWallet cannot be 0");
			emit WalletChange('marketingWallet', newMarketingWallet, marketingWallet);
			marketingWallet = newMarketingWallet;
		}
		if(buyBackWallet != newBuyBackWallet) {
			require(newBuyBackWallet != address(0), "Peanut: The buyBackWallet cannot be 0");
			emit WalletChange('buyBackWallet', newBuyBackWallet, buyBackWallet);
			buyBackWallet = newBuyBackWallet;
		}
        if(charityWallet != newCharityWallet) {
			require(newCharityWallet != address(0), "Peanut: The charityWallet cannot be 0");
			emit WalletChange('charityWallet', newCharityWallet, charityWallet);
			charityWallet = newCharityWallet;
		}
		if(teamWallet != newTeamWallet) {
			require(newTeamWallet != address(0), "Peanut: The teamWallet cannot be 0");
			emit WalletChange('teamWallet', newTeamWallet, teamWallet);
			teamWallet = newTeamWallet;
		}
	}

	function setBaseFeesOnBuy(uint8 _liquidityFeeOnBuy, uint8 _marketingFeeOnBuy, uint8 _buyBackFeeOnBuy, uint8 _charityFeeOnBuy, uint8 _teamFeeOnBuy, uint8 _burnFeeOnBuy, uint8 _holdersFeeOnBuy) external onlyOwner {
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _marketingFeeOnBuy, _buyBackFeeOnBuy, _charityFeeOnBuy, _teamFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _buyBackFeeOnBuy, _charityFeeOnBuy, _teamFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
	}

	function setBaseFeesOnSell(uint8 _liquidityFeeOnSell,uint8 _marketingFeeOnSell, uint8 _buyBackFeeOnSell, uint8 _charityFeeOnSell, uint8 _teamFeeOnSell, uint8 _burnFeeOnSell, uint8 _holdersFeeOnSell) external onlyOwner {
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _marketingFeeOnSell, _buyBackFeeOnSell, _charityFeeOnSell, _teamFeeOnSell, _burnFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _buyBackFeeOnSell, _charityFeeOnSell, _teamFeeOnSell, _burnFeeOnSell, _holdersFeeOnSell);
	}
    
	function setUniswapRouter(address newAddress) external onlyOwner {
		require(newAddress != address(uniswapV2Router), "Peanut: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
	}

	function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
		require(newValue != maxTxAmount, "Peanut: Cannot update maxTxAmount to same value");
		emit MaxTransactionAmountChange(newValue, maxTxAmount);
		maxTxAmount = newValue;
	}

	function setMaxWalletAmount(uint256 newValue) external onlyOwner {
		require(newValue != maxWalletAmount, "Peanut: Cannot update maxWalletAmount to same value");
		emit MaxWalletAmountChange(newValue, maxWalletAmount);
		maxWalletAmount = newValue;
	}

	function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "Peanut: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}

	function claimEthOverflow(uint256 amount) external onlyOwner {
		require(amount < address(this).balance, "Peanut: Cannot send more than contract balance");
		(bool success,) = address(owner()).call{value : amount}("");
		if (success){
			emit ClaimEthOverflow(amount);
		}
	}

    //==========================================================
    // Getters
    //==========================================================

    function name() public view returns (string memory) {
		return _name;
	}
	function symbol() public view returns (string memory) {
		return _symbol;
	}
	function decimals() external view virtual returns (uint8) {
		return _decimals;
	}
	function totalSupply() external view virtual override returns (uint256) {
		return _tTotal;
	}

    // See {IERC20-allowance}.
    function allowance (address owner, address spender) public view virtual override returns (uint256){
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromDividends[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function totalFees() external view returns (uint256) {
		return _tFeeTotal;
	}

	function getBaseBuyFees() external view returns (uint8, uint8, uint8, uint8, uint8, uint8, uint8){
		return (_base.liquidityFeeOnBuy, _base.marketingFeeOnBuy, _base.buyBackFeeOnBuy, _base.charityFeeOnBuy, _base.teamFeeOnBuy, _base.burnFeeOnBuy, _base.holdersFeeOnBuy);
	}

	function getBaseSellFees() external view returns (uint8, uint8, uint8, uint8, uint8, uint8, uint8){
		return (_base.liquidityFeeOnSell, _base.marketingFeeOnSell, _base.buyBackFeeOnSell, _base.charityFeeOnSell, _base.teamFeeOnSell, _base.burnFeeOnSell, _base.holdersFeeOnSell);
	}

    // Returns `amount` in reflection.
    function _getRAmount(uint256 amount) private view returns (uint256) {
        uint256 currentRate = _getRate();
        return amount * currentRate;
    }

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "ERC20: Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount / currentRate;
	}

	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
		require(tAmount <= _tTotal, "ERC20: Amount must be less than supply");
		uint256 currentRate = _getRate();
		uint256 rAmount  = tAmount * currentRate;
		if (!deductTransferFee) {
			return rAmount;
		}
		else {
			uint256 rTotalFee  = tAmount * _totalFee / 100 * currentRate;
			uint256 rTransferAmount = rAmount - rTotalFee;
			return rTransferAmount;
		}
	}


    //==========================================================
    // Main
    //==========================================================

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address to, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
		require(amount <= balanceOf(sender), "ERC20: Cannot transfer more than balance");
		require(!_isBot[sender] && !_isBot[to], "ERC20: You are a bot");

		if (coolDownEnabled) {
            uint256 timePassed = block.timestamp - _lastTrade[sender];
            require(timePassed > coolDownTime, "ERC20: You must wait coolDownTime");
        }
        
        if(!_isAllowedToTradeWhenDisabled[sender] && !_isAllowedToTradeWhenDisabled[to]) {
			require(isTradingEnabled, "ERC20: Trading is currently disabled.");
            require(!_isBlocked[to], "ERC20: Account is blocked");
			require(!_isBlocked[sender], "ERC20: Account is blocked");
			if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[sender]) {
				require(amount <= maxTxAmount, "ERC20: Buy amount exceeds the maxTxBuyAmount.");
			}
			if (!_isExcludedFromMaxWalletLimit[to]) {
				require((balanceOf(to) + amount) <= maxWalletAmount, "ERC20: Expected wallet amount exceeds the maxWalletAmount.");
			}
		}

        _adjustTaxes(automatedMarketMakerPairs[sender], automatedMarketMakerPairs[to], to, sender);
		bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

		_lastTrade[sender] = block.timestamp;

		if (
			isTradingEnabled &&
			canSwap &&
			!_swapping &&
			_totalFee > 0 &&
			automatedMarketMakerPairs[to]
		) {
			_swapping = true;
			_swapAndLiquify();
			_swapping = false;
		}

		bool takeFee = !_swapping && isTradingEnabled;

		if(_isExcludedFromFee[sender] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		if (takeFee && _totalFee > 0) {
				uint256 fee = amount * _totalFee / 100;
                uint256 burnAmount = amount * _burnFee / 100;
				amount = amount - fee;
				_transfer(sender, address(this), fee);

                if (burnAmount > 0) {
                    _burn(address(this), burnAmount);
                    emit TokenBurn(_burnFee, burnAmount);
			    }
			}

		_tokenTransfer(sender, to, amount, takeFee);

    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Burn} event indicating the amount burnt.
     * Emits a {Transfer} event with `to` set to the burn address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != burnAccount, "ERC20: burn from the burn address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        uint256 rAmount = _getRAmount(amount);

        // Transfer from account to the burnAccount
        if (_isExcludedFromReward[account]) {
            _tokenBalances[account] -= amount;
        } 
        _reflectionBalances[account] -= rAmount;

        _tokenBalances[burnAccount] += amount;
        _reflectionBalances[burnAccount] += rAmount;

        emit Burn(account, amount);
        emit Transfer(account, burnAccount, amount);
    }

	function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _tTotal = _tTotal + amount;
        _tokenBalances[account] = _tokenBalances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

	function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

	function _tokenTransfer(address sender,address recipient, uint256 tAmount, bool takeFee) private {
		(uint256 tTransferAmount,uint256 tFee, uint256 tOther) = _getTValues(tAmount, takeFee);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rOther) = _getRValues(tAmount, tFee, tOther, _getRate());

		if (_isExcludedFromDividends[sender]) {
			_tOwned[sender] = _tOwned[sender] - tAmount;
		}
		if (_isExcludedFromDividends[recipient]) {
			_tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
		}
		_rOwned[sender] = _rOwned[sender] - rAmount;
		_rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_reflectFee(rFee, tFee, rOther, tOther);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _reflectFee(uint256 rFee, uint256 tFee, uint256 rOther, uint256 tOther) private {
		_rTotal -= rFee;
		_tFeeTotal += tFee;

        if (_isExcludedFromDividends[address(this)]) {
			_tOwned[address(this)] += tOther;
		}
		_rOwned[address(this)] += rOther;
	}

	function _getTValues(uint256 tAmount, bool takeFee) private view returns (uint256,uint256,uint256){
		if (!takeFee) {
			return (tAmount, 0, 0);
		}
		else {
			uint256 tFee = tAmount * _holdersFee / 100;
			uint256 tOther = tAmount * (_liquidityFee + _marketingFee + _charityFee + _teamFee + _buyBackFee) / 100;
			uint256 tTransferAmount = tAmount - (tFee + tOther);
			return (tTransferAmount, tFee, tOther);
		}
	}

	function _getRValues(
		uint256 tAmount,
		uint256 tFee,
		uint256 tOther,
		uint256 currentRate
		) private pure returns ( uint256, uint256, uint256, uint256) {
		uint256 rAmount = tAmount * currentRate;
		uint256 rFee = tFee * currentRate;
		uint256 rOther = tOther * currentRate;
		uint256 rTransferAmount = rAmount - (rFee + rOther);
		return (rAmount, rTransferAmount, rFee, rOther);
	}

	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
			if (
				_rOwned[_excludedFromDividends[i]] > rSupply ||
				_tOwned[_excludedFromDividends[i]] > tSupply
			) return (_rTotal, _tTotal);
			rSupply = rSupply - _rOwned[_excludedFromDividends[i]];
			tSupply = tSupply - _tOwned[_excludedFromDividends[i]];
		}
		if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}

	function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp, address to, address from) private {
		_liquidityFee = 0;
        _marketingFee = 0;
        _charityFee = 0;
		_teamFee = 0;
        _buyBackFee = 0;
		_burnFee = 0;
        _holdersFee = 0;

        if (isBuyFromLp) {
            if (block.number - _launchBlockNumber <= 5) {
                _liquidityFee = 100;
            }
			else {
                _liquidityFee = _base.liquidityFeeOnBuy;
                _marketingFee = _base.marketingFeeOnBuy;
                _buyBackFee = _base.buyBackFeeOnBuy;
                _charityFee = _base.charityFeeOnBuy;
				_teamFee = _base.teamFeeOnBuy;
				_burnFee = _base.burnFeeOnBuy;
                _holdersFee = _base.holdersFeeOnBuy;
            }
		}
		if (isSelltoLp) {
			_liquidityFee = _base.liquidityFeeOnSell;
			_marketingFee = _base.marketingFeeOnSell;
			_buyBackFee = _base.buyBackFeeOnSell;
            _charityFee = _base.charityFeeOnSell;
			_teamFee = _base.teamFeeOnSell;
			_burnFee = _base.burnFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;
		}
		if (!isSelltoLp && !isBuyFromLp && (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to])) {
			_liquidityFee = _base.liquidityFeeOnSell;
			_marketingFee = _base.marketingFeeOnSell;
			_buyBackFee = _base.buyBackFeeOnSell;
            _charityFee = _base.charityFeeOnSell;
			_teamFee = _base.teamFeeOnSell;
			_burnFee = _base.burnFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;
		}
		_totalFee = _liquidityFee + _marketingFee + _buyBackFee + _charityFee + _teamFee + _burnFee + _holdersFee;
	}

	function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint8 _liquidityFeeOnSell,
		uint8 _marketingFeeOnSell,
		uint8 _buyBackFeeOnSell,
        uint8 _charityFeeOnSell,
		uint8 _teamFeeOnSell,
		uint8 _burnFeeOnSell,
		uint8 _holdersFeeOnSell
		) private {
		if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
			emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
			map.liquidityFeeOnSell = _liquidityFeeOnSell;
		}
		if (map.marketingFeeOnSell != _marketingFeeOnSell) {
			emit CustomTaxPeriodChange(_marketingFeeOnSell, map.marketingFeeOnSell, 'marketingFeeOnSell', map.periodName);
			map.marketingFeeOnSell = _marketingFeeOnSell;
		}
		if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
			emit CustomTaxPeriodChange(_buyBackFeeOnSell, map.buyBackFeeOnSell, 'buyBackFeeOnSell', map.periodName);
			map.buyBackFeeOnSell = _buyBackFeeOnSell;
		}
        if (map.charityFeeOnSell != _charityFeeOnSell) {
			emit CustomTaxPeriodChange(_charityFeeOnSell, map.charityFeeOnSell, 'charityFeeOnSell', map.periodName);
			map.charityFeeOnSell = _charityFeeOnSell;
		}
		if (map.teamFeeOnSell != _teamFeeOnSell) {
			emit CustomTaxPeriodChange(_teamFeeOnSell, map.teamFeeOnSell, 'teamFeeOnSell', map.periodName);
			map.teamFeeOnSell = _teamFeeOnSell;
		}
		if (map.burnFeeOnSell != _burnFeeOnSell) {
			emit CustomTaxPeriodChange(_burnFeeOnSell, map.burnFeeOnSell, 'burnFeeOnSell', map.periodName);
			map.burnFeeOnSell = _burnFeeOnSell;
		}
		if (map.holdersFeeOnSell != _holdersFeeOnSell) {
			emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
			map.holdersFeeOnSell = _holdersFeeOnSell;
		}
	}

	function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
		uint8 _liquidityFeeOnBuy,
		uint8 _marketingFeeOnBuy,
		uint8 _buyBackFeeOnBuy,
        uint8 _charityFeeOnBuy,
		uint8 _teamFeeOnBuy,
		uint8 _burnFeeOnBuy,
		uint8 _holdersFeeOnBuy
		) private {
		if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
			emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
			map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
		}
		if (map.marketingFeeOnBuy != _marketingFeeOnBuy) {
			emit CustomTaxPeriodChange(_marketingFeeOnBuy, map.marketingFeeOnBuy, 'marketingFeeOnBuy', map.periodName);
			map.marketingFeeOnBuy = _marketingFeeOnBuy;
		}
		if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
			emit CustomTaxPeriodChange(_buyBackFeeOnBuy, map.buyBackFeeOnBuy, 'buyBackFeeOnBuy', map.periodName);
			map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
		}
        if (map.charityFeeOnBuy != _charityFeeOnBuy) {
			emit CustomTaxPeriodChange(_charityFeeOnBuy, map.charityFeeOnBuy, 'charityFeeOnBuy', map.periodName);
			map.charityFeeOnBuy = _charityFeeOnBuy;
		}
		if (map.teamFeeOnBuy != _teamFeeOnBuy) {
			emit CustomTaxPeriodChange(_teamFeeOnBuy, map.teamFeeOnBuy, 'teamFeeOnBuy', map.periodName);
			map.teamFeeOnBuy = _teamFeeOnBuy;
		}
		if (map.burnFeeOnBuy != _burnFeeOnBuy) {
			emit CustomTaxPeriodChange(_burnFeeOnBuy, map.burnFeeOnBuy, 'burnFeeOnBuy', map.periodName);
			map.burnFeeOnBuy = _burnFeeOnBuy;
		}
		if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
			emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
			map.holdersFeeOnBuy = _holdersFeeOnBuy;
		}
	}

	function _swapAndLiquify() private {
		uint256 contractBalance = balanceOf(address(this));
		uint256 initialEthBalance = address(this).balance;

		uint8 totalFeePrior = _totalFee;
		uint8 liquidityFeePrior = _liquidityFee;
		uint8 marketingFeePrior = _marketingFee;
		uint8 buyBackFeePrior  = _buyBackFee;
        uint8 charityFeePrior = _charityFee;
		uint8 teamFeePrior = _teamFee;
		uint8 burnFeePrior = _burnFee;
		uint8 holdersFeePrior = _holdersFee;

		uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFee / 2;
		uint256 amountToSwap = contractBalance - amountToLiquify;

		_swapTokensForEth(amountToSwap);

		uint256 ethBalanceAfterSwap = address(this).balance - initialEthBalance;
		//uint256 totalEthFee = totalFeePrior - ((liquidityFeePrior / 2) + burnFeePrior + holdersFeePrior);
		//uint256 totalEthFee = totalFeePrior - (liquidityFeePrior / 2) - (holdersFeePrior);
		uint256 totalEthFee = totalFeePrior - (liquidityFeePrior / 2);
		uint256 amountEthLiquidity = ethBalanceAfterSwap * liquidityFeePrior / totalEthFee / 2;
		uint256 amountEthMarketing = ethBalanceAfterSwap * marketingFeePrior / totalEthFee;
		uint256 amountEthCharity = ethBalanceAfterSwap * charityFeePrior / totalEthFee;
		uint256 amountEthTeam = ethBalanceAfterSwap * teamFeePrior / totalEthFee;
		uint256 amountEthBuyBack = ethBalanceAfterSwap * buyBackFeePrior / totalEthFee;

		Address.sendValue(payable(marketingWallet),amountEthMarketing);
        Address.sendValue(payable(buyBackWallet),amountEthBuyBack);
        Address.sendValue(payable(charityWallet),amountEthCharity);
		Address.sendValue(payable(teamWallet),amountEthTeam);

		if (amountToLiquify > 0) {
			_addLiquidity(amountToLiquify, amountEthLiquidity);
			emit SwapAndLiquify(amountToSwap, amountEthLiquidity, amountToLiquify);
		}

		//_totalFee = totalFeePrior;
		_liquidityFee = liquidityFeePrior;
		_marketingFee = marketingFeePrior;
		_buyBackFee = buyBackFeePrior;
        _charityFee = charityFeePrior;
		_teamFee = teamFeePrior;
		_burnFee = burnFeePrior;
		_holdersFee = holdersFeePrior;
	}

	function _swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			1, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.addLiquidityETH{value: ethAmount}(
			address(this),
			tokenAmount,
			1, // slippage is unavoidable
			1, // slippage is unavoidable
			liquidityWallet,
			block.timestamp
		);
	}

	function updateCoolDownSettings(bool _enabled, uint256 _timeInSeconds) external onlyOwner{
        coolDownEnabled = _enabled;
        coolDownTime = _timeInSeconds * 1 seconds;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, 'Peanut: Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner {
        require(accounts.length <= 100, "Peanut: Invalid");
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
}
// File: contracts/Peanut/Peanut.sol



pragma solidity ^0.8.4;





interface Ipeanut is IERC20 {
	function rewards(address) external view returns(uint256);
	function lastUpdate(address) external view returns(uint256);
}

contract Peanut is ERC20A("Peanut", "PNUT") {
	using SafeMath for uint256;

	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
	Ipeanut public ipeanut = Ipeanut(0xc3E304431Bf7227319dFFF633114F38567423041); // Address yieldToken
	address public yieldHub = 0xE06090195B3dEB900cc13326e04530b243c9Eb66; // Address yieldHub

    function setYieldTokenAndYieldHub(address addressYieldToken, address addressYieldHub) public onlyOwner {
        ipeanut = Ipeanut(addressYieldToken);
        yieldHub = addressYieldHub;
    }

	function swap() external {
		swap(ipeanut.balanceOf(msg.sender));
	}

	function swap(uint256 _amount) public {
		_mint(msg.sender, _amount);
		ipeanut.transferFrom(msg.sender, BURN_ADDRESS, _amount);
	}

	function burnFrom(address _from, uint256 _amount) external {
		require(msg.sender == yieldHub, "!hub");
		_burn(_from, _amount);
	}

	function burnFor(address _user, uint256 _amount) external {
		uint256 currentAllowance = allowance(_user, msg.sender);
		_approve(_user, msg.sender, currentAllowance.sub(_amount));
		_burn(_user, _amount);
	}

	function burn(uint256 _amount) external {
		_burn(msg.sender, _amount);
	}

	function mint(address _to, uint256 _amount) external {
		require(msg.sender == yieldHub, "!hub");
		_mint(_to, _amount);
	}
}