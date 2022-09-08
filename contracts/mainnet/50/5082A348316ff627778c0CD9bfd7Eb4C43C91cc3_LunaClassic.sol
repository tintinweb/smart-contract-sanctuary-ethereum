/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.13;

interface IFactory {
	function createPair(address tokenA, address tokenB)
	external
	returns (address pair);

	function getPair(address tokenA, address tokenB)
	external
	view
	returns (address pair);
}

interface IRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

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

contract LunaClassic is IERC20, Ownable {
	using Address for address;
	using SafeMath for uint256;

	IRouter public uniswapV2Router;
	address public immutable uniswapV2Pair;

	string private constant _name =  "Luna Classic";
	string private constant _symbol = "LUNA";
	uint8 private constant _decimals = 18;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private constant MAX = ~uint256(0);
	uint256 private constant _tTotal = 1000000000000 * 10**18;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	bool public isTradingEnabled;
    uint256 private _tradingPausedTimestamp;

    // max tx is 1.0% of initialSupply
	uint256 public maxTxAmount = _tTotal * 100 / 10000;

	bool private _swapping;

    // max wallet is 0.05% of initialSupply
	uint256 public minimumTokensBeforeSwap = _tTotal * 500 / 1000000;

    address private dead = 0x000000000000000000000000000000000000dEaD;

	address public liquidityWallet;
	address public investmentWallet;

	struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint8 liquidityFeeOnBuy;
		uint8 liquidityFeeOnSell;
        uint8 investmentFeeOnBuy;
		uint8 investmentFeeOnSell;
		uint8 holdersFeeOnBuy;
		uint8 holdersFeeOnSell;
	}

	// Base taxes
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,5,5,5,5,1,1);

    uint256 private _launchTimestamp;
	uint256 private _launchBlockNumber;
    uint256 constant private _blockedTimeLimit = 172800;
    mapping (address => bool) private _isBlocked;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) private _isExcludedFromDividends;
	mapping (address => bool) private _isAllowedToTradeWhenDisabled;
    address[] private _excludedFromDividends;

	uint8 private _liquidityFee;
    uint8 private _investmentFee;
	uint8 private _holdersFee;
	uint8 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event BlockedAccountChange(address indexed holder, bool indexed status);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event WalletChange(string indexed indentifier, address indexed newWallet, address indexed oldWallet);
	event FeeChange(string indexed identifier, uint8 liquidityFee, uint8 investmentFee, uint8 holdersFee);
	event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
	event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
	event ClaimETHOverflow(uint256 amount);
	event FeesApplied(uint8 liquidityFee, uint8 investmentFee, uint8 holdersFee, uint8 totalFee);

	constructor() {
		liquidityWallet = owner();
        investmentWallet = owner();

		IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(
			address(this),
			_uniswapV2Router.WETH()
		);
        uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

		_isAllowedToTradeWhenDisabled[owner()] = true;
		_isAllowedToTradeWhenDisabled[address(this)] = true;

        _isExcludedFromMaxTransactionLimit[address(this)] = true;
		_isExcludedFromMaxTransactionLimit[address(dead)] = true;
		_isExcludedFromMaxTransactionLimit[owner()] = true;

		_rOwned[owner()] = _rTotal;
		emit Transfer(address(0), owner(), _tTotal);
	}

	receive() external payable {}

	// Setters
	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}
	function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
		return true;
	}
	function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
		_approve(_msgSender(),spender,_allowances[_msgSender()][spender].add(addedValue));
		return true;
	}
	function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
		_approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
		return true;
	}
	function _approve(address owner,address spender,uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	function _getNow() private view returns (uint256) {
		return block.timestamp;
	}
	function activateTrading() external onlyOwner {
		isTradingEnabled = true;
        if (_launchTimestamp == 0) {
			_launchTimestamp = block.timestamp;
			_launchBlockNumber = block.number;
		}
	}
	function deactivateTrading() external onlyOwner {
		isTradingEnabled = false;
		_tradingPausedTimestamp = _getNow();
	}
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "LUNA: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}
	function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}
	function excludeFromFees(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "LUNA: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
	function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "LUNA: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}
	function setWallets(address newLiquidityWallet, address newInvestmentWallet) external onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "LUNA: The liquidityWallet cannot be 0");
			emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(investmentWallet != newInvestmentWallet) {
            require(newInvestmentWallet != address(0), "LUNA: The investmentWallet cannot be 0");
			emit WalletChange('investmentWallet', newInvestmentWallet, investmentWallet);
			investmentWallet = newInvestmentWallet;
		}
	}
    // Base fees

	function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "LUNA: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}

	function claimETHOverflow() external onlyOwner {
		require(address(this).balance > 0, "LUNA: Cannot send more than contract balance");
        uint256 amount = address(this).balance;
		(bool success,) = address(owner()).call{value : amount}("");
		if (success){
			emit ClaimETHOverflow(amount);
		}
	}

	// Getters
	function name() external view returns (string memory) {
		return _name;
	}
	function symbol() external view returns (string memory) {
		return _symbol;
	}
	function decimals() external view virtual returns (uint8) {
		return _decimals;
	}
	function totalSupply() external view override returns (uint256) {
		return _tTotal;
	}
	
	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromDividends[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}

	function totalFees() external view returns (uint256) {
		return _tFeeTotal;
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}
    function getBaseBuyFees() external view returns (uint8, uint8, uint8){
		return (_base.liquidityFeeOnBuy, _base.investmentFeeOnBuy, _base.holdersFeeOnBuy);
	}

	function getBaseSellFees() external view returns (uint8, uint8, uint8){
		return (_base.liquidityFeeOnSell, _base.investmentFeeOnSell, _base.holdersFeeOnSell);
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "LUNA: Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount / currentRate;
	}

	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
		require(tAmount <= _tTotal, "LUNA: Amount must be less than supply");
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

	// Main
	function _transfer(
	address from,
	address to,
	uint256 amount
	) internal {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		require(amount <= balanceOf(from), "LUNA: Cannot transfer more than balance");

		if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
			require(isTradingEnabled, "LUNA: Trading is currently disabled.");
            require(!_isBlocked[to], "LUNA: Account is blocked");
			require(!_isBlocked[from], "LUNA: Account is blocked");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "LUNA: Transfer amount exceeds the maxTxAmount.");
            }
		}

		bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

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

		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		_tokenTransfer(from, to, amount, takeFee);
	}

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
		_takeContractFees(rOther, tOther);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _reflectFee(uint256 rFee, uint256 tFee) private {
		_rTotal -= rFee;
		_tFeeTotal += tFee;
	}

	function _getTValues(uint256 tAmount, bool takeFee) private view returns (uint256,uint256,uint256){
		if (!takeFee) {
			return (tAmount, 0, 0);
		}
		else {
			uint256 tFee = tAmount * _holdersFee / 100;
			uint256 tOther = tAmount * (_liquidityFee + _investmentFee) / 100;
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

	function _takeContractFees(uint256 rOther, uint256 tOther) private {
		if (_isExcludedFromDividends[address(this)]) {
			_tOwned[address(this)] += tOther;
		}
		_rOwned[address(this)] += rOther;
	}

	function _swapAndLiquify() private {
		uint256 contractBalance = balanceOf(address(this));
		uint256 initialETHBalance = address(this).balance;

		uint8 totalFeePrior = _totalFee;
        uint8 liquidityFeePrior = _liquidityFee;
        uint8 investmentFeePrior = _investmentFee;
		uint8 holdersFeePrior = _holdersFee;

		uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFee / 2;
		uint256 amountToSwapForETH = contractBalance - amountToLiquify;

		_swapTokensForETH(amountToSwapForETH);

		uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
		uint256 totalETHFee = totalFeePrior - (liquidityFeePrior / 2) - (holdersFeePrior);
		uint256 amountETHLiquidity = ETHBalanceAfterSwap * liquidityFeePrior / totalETHFee / 2;
		uint256 amountETHInvestment = ETHBalanceAfterSwap - amountETHLiquidity;

		payable(investmentWallet).transfer(amountETHInvestment);

		if (amountToLiquify > 0) {
			_addLiquidity(amountToLiquify, amountETHLiquidity);
			emit SwapAndLiquify(amountToSwapForETH, amountETHLiquidity, amountToLiquify);
		}
		_totalFee = totalFeePrior;
        _liquidityFee = liquidityFeePrior;
        _investmentFee = investmentFeePrior;
		_holdersFee = holdersFeePrior;
	}

	function _swapTokensForETH(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
		tokenAmount,
		0, // accept any amount of ETH
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
		0, // slippage is unavoidable
		0, // slippage is unavoidable
		liquidityWallet,
		block.timestamp
		);
    }
}

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