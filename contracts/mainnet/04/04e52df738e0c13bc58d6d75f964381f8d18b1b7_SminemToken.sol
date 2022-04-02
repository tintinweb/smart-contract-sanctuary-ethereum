/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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

// File: token/SminemToken.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;





contract SminemToken is IERC20, Ownable {
	using SafeMath for *;

	string private constant _name = unicode"Sminem Token";
	string private constant _symbol = unicode"SMNM";
	uint8 private constant _decimals = 18;
	
	uint256 private constant _totalSupply = 10**12 * 1e18;
	uint256 private _marketingFee = 35000000000 * 1e18;
	uint256 private _sminemFee = 13000000000 * 1e18;
	uint256 private _devFee = 35000000000 * 1e18;
	uint256 private _totalFeePercent = _getTotalFeePercent();
	uint256 private _maxAmountInTx = _totalSupply;

	address private _marketingAddress;
	address private _sminemAddress;
	address private _devAddress;
	uint256 private _previousMarketingFee;
	uint256 private _previousSminemFee;
	uint256 private _previousDevFee;
	uint256 private _maxOwnedTokensPercent = 2;
	uint256 private _maxTokensInWalletPercent = 5;
	uint256 private _floor = 0;


	mapping(address => bool) private _botList;

	mapping(address => uint256) private _balanceOf;
	mapping (address => mapping(address => uint256)) private _allowance;
	mapping (address => bool) private _isExcludedFromFee;

	IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

	bool private isOpen = false;
	bool private inSwap = false;


	modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

	constructor(address payable devAddress, address payable marketingAddress, address payable sminemAddress) {
		_balanceOf[_msgSender()] = _totalSupply;
	
		_marketingAddress = marketingAddress;
		_sminemAddress = sminemAddress;
		_devAddress = devAddress;

		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_msgSender()] = true;
		_isExcludedFromFee[_marketingAddress] = true;
		_isExcludedFromFee[_sminemAddress] = true;
		_isExcludedFromFee[_devAddress] = true;

		emit Transfer(address(0), _msgSender(), _totalSupply);
	}

	function open() external onlyOwner {
		require(!isOpen,"trading is already open");
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
		_approve(address(this), address(uniswapV2Router), _totalSupply);
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router.addLiquidityETH{value: address(this).balance}
			(address(this),
			balanceOf(address(this)),
			0,
			0,
			owner(),
			block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

		isOpen = true;
	}

	receive() external payable {}

	function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

	function totalSupply() public pure returns (uint256) {
		return _totalSupply;
	}

	function transfer(address recipient, uint amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function approve(address spender, uint amount) public override returns (bool) {
		require(_msgSender() != address(0));
		require(spender != address(0));
		_allowance[_msgSender()][spender] = amount;
		emit Approval(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
		require(_msgSender() != address(0));
		require(sender != address(0));
		_transfer(sender, recipient, amount);
		_allowance[sender][_msgSender()] = _allowance[sender][_msgSender()].sub(amount);		
		return true;
	}

    function balanceOf(address account) public view returns (uint256) {
    	return _balanceOf[account];
    }

	function allowance(address owner, address spender) public view returns (uint256) {
		return _allowance[owner][spender];
	}

	function _transfer(address sender, address recipient, uint amount) private {
		require(sender != address(0), "[sminem]: transfer from the zero address");
        require(recipient != address(0), "[sminem]: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		

		if(sender != owner() && recipient != owner()) {
            if(!_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender] ) {
                require(amount <= _maxAmountInTx, "Transfer amount exceeds the maxTxAmount.");
            }
			require(!_botList[sender] && !_botList[recipient], "Bot detected");
        
			if(sender == uniswapV2Pair && recipient != address(uniswapV2Router) && !_isExcludedFromFee[recipient]) {
				require(isOpen, "[sminem]: Trading not started yet.");
				uint walletBalance = balanceOf(address(recipient));
				require(amount.add(walletBalance) <= _totalSupply.mul(_maxOwnedTokensPercent).div(100));
			}

			uint256 contractTokenBalance = balanceOf(address(this));

			if(!inSwap && sender != uniswapV2Pair && isOpen) {
				if(contractTokenBalance > 0) {
					if(contractTokenBalance > balanceOf(uniswapV2Pair).mul(_maxTokensInWalletPercent).div(100)) {
						contractTokenBalance = balanceOf(uniswapV2Pair).mul(_maxTokensInWalletPercent).div(100);
					}
					swapTokensForEth(contractTokenBalance);
				}
				uint256 contractETHBalance = address(this).balance;
				if(contractETHBalance > _floor) {
					sendETHToFee(address(this).balance.sub(_floor));
				}
			}
		}


		bool takeFee = true;
		if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) takeFee = false;

		if(!takeFee)
            removeAllFee();
        _transferRegular(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
	}

	function _transferRegular(address sender, address recipient, uint256 amount) private {
		_balanceOf[sender] = _balanceOf[sender].sub(amount);
		uint256 fee = getFee(amount);
		_balanceOf[recipient] = _balanceOf[recipient].add(amount).sub(fee);
		_balanceOf[address(this)] = _balanceOf[address(this)].add(fee);

		emit Transfer(sender, recipient, amount);
	}

	function getFee(uint256 amount) private view returns(uint256) {
		uint256 fee = amount.mul(_totalFeePercent).div(_totalSupply);
		return fee;
	}

	function _getTotalFeePercent() private view returns(uint256) {
		return _sminemFee.add(_marketingFee).add(_devFee);
	}

	function splitFee(uint256 sum) private view returns(uint256, uint256, uint256) {
		uint split1 = sum.mul(_sminemFee).div(_totalFeePercent);
		uint split2 = sum.mul(_marketingFee).div(_totalFeePercent);
		uint split3 = sum.mul(_devFee).div(_totalFeePercent);
		return (split1, split2, split3);
	}

	function _approve(address owner, address spender, uint amount) private {
		require(owner != address(0), "[sminem]: approve from the zero address");
        require(spender != address(0), "[sminem]: approve to the zero address");
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
	}

	function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

	function sendETHToFee(uint256 amount) private {
		(uint256 split1, uint256 split2, uint256 split3) = splitFee(amount);
		bool success = false;
		(success, ) = _sminemAddress.call{value: split1}("");
		require(success);
        (success, ) = _marketingAddress.call{value: split2}("");
		require(success);
        (success, ) = _devAddress.call{value: split3}("");
		require(success);
    }

	function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

	function includeToFee (address payable account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

	function setMarketingWallet (address payable marketingWalletAddress) external onlyOwner {
        _isExcludedFromFee[_marketingAddress] = false;
        _marketingAddress = marketingWalletAddress;
        _isExcludedFromFee[marketingWalletAddress] = true;
    }

	function setSminemWallet (address payable sminemWalletAddress) external onlyOwner {
        _isExcludedFromFee[_sminemAddress] = false;
        _sminemAddress = sminemWalletAddress;
        _isExcludedFromFee[sminemWalletAddress] = true;
    }

	function setDevWallet (address payable devWalletAddress) external onlyOwner {
        _isExcludedFromFee[_devAddress] = false;
        _devAddress = devWalletAddress;
        _isExcludedFromFee[devWalletAddress] = true;
    }

	function setMarketingFee(uint256 fee) external onlyOwner {
        _marketingFee = fee;
		_totalFeePercent = _getTotalFeePercent();
    }

	function setSminemFee(uint256 fee) external onlyOwner {
        _sminemFee = fee;
		_totalFeePercent = _getTotalFeePercent();
    }

	function setDevFee(uint256 fee) external onlyOwner {
        _devFee = fee;
		_totalFeePercent = _getTotalFeePercent();
    }

	function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _devFee = _previousDevFee;
        _sminemFee = _previousSminemFee;

		_totalFeePercent = _getTotalFeePercent();
    }

	function removeAllFee() private {
		_previousMarketingFee = _marketingFee;
		_previousDevFee = _devFee;
		_previousSminemFee = _sminemFee;

        _marketingFee = 0;
        _devFee = 0;
        _sminemFee = 0;
		
		_totalFeePercent = _getTotalFeePercent();
    }

	function setBots(address[] memory bots) public onlyOwner {
		for (uint i = 0; i < bots.length; i++) {
            if (bots[i] != uniswapV2Pair && bots[i] != address(uniswapV2Router)) {
                _botList[bots[i]] = true;
            }
        }
    }

	function manualswap(uint256 amount) external onlyOwner {
        require(amount <= balanceOf(address(this)));
        swapTokensForEth(amount);
    }
    
    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

	function setMaxTxPercent(uint256 val) external onlyOwner {
        _maxAmountInTx = val;
    }

	function setMaxOwnedPercent(uint256 per) external onlyOwner {
        _maxOwnedTokensPercent = per;
    }

	function setTokensInWalletPercent(uint256 per) external onlyOwner {
        _maxTokensInWalletPercent = per;
    }

	function setFloor(uint256 floor) external onlyOwner {
        _floor = floor;
    }


	function unbot(address notbot) public onlyOwner {
        _botList[notbot] = false;
    }
    
    function isBot(address party) public view returns (bool) {
        return _botList[party];
    }


}