/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
	address internal owner;
	constructor(address _owner) { owner = _owner; }
	modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
	function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner;	emit OwnershipTransferred(newOwner); }
	event OwnershipTransferred(address owner);
}

interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract TinyPredator is IERC20, Auth {
	string _name = "Tiny Predator";
	string _symbol = "TINYP";
	uint8 constant _decimals = 18;
	uint256 constant _totalSupply = 696_969_969_969_969 * 1e18;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	mapping (address => bool) public noFees;
	mapping (address => bool) public noLimits;
    mapping (address => bool) private _isLiqPool;
	mapping (address => address) private _liqPoolRouterCA;
	mapping (address => address) private _liqPoolPairedCA;
    address constant _burnWallet = address(0);
	bool public tradingOpen;
    uint256 private openBlock;
	uint256 public maxTxAmount; 
    uint256 public maxWalletAmount;
	uint256 private taxSwapMin; 
    uint256 private taxSwapMax; 
	uint8 private constant _maxTaxRate = 3; 
    uint8 public taxRateSell = _maxTaxRate;
    uint8 public taxRateTX = _maxTaxRate;
	uint16 private _autoLPShares = 300; // 3% TAX TO LP 
	uint16 private _totalTaxShares = _autoLPShares;

	bool private _inTaxSwap = false;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	constructor () Auth(msg.sender) {      
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
		taxSwapMin = _totalSupply * 10 / 10000;
		taxSwapMax = _totalSupply * 50 / 10000;
		noFees[owner] = true;
		noFees[address(this)] = true;
		noLimits[owner] = true;
		noLimits[address(this)] = true;
		noLimits[_burnWallet] = true;

		_balances[address(owner)] = _totalSupply;
		emit Transfer(address(0), address(owner), _totalSupply);
	}

	receive() external payable {}
	
	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external view override returns (string memory) { return _symbol; }
	function name() external view override returns (string memory) { return _name; }
	function getOwner() external view override returns (address) { return owner; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

	function approve(address spender, uint256 amount) public override returns (bool) {
		require(balanceOf(msg.sender) > 0);
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		require(_checkTradingOpen(msg.sender), "Trading not open");
		return _transferFrom(msg.sender, recipient, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		require(_checkTradingOpen(sender), "Trading not open");
		if(_allowances[sender][msg.sender] != type(uint256).max) { _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount; }
		return _transferFrom(sender, recipient, amount);
	}


	function setLiquidityPair(address liqPoolAddress, address swapRouterCA, address wethPairedCA, bool enabled) external onlyOwner {
		if (tradingOpen) { require(block.number < openBlock, "The token is live and the liquidity pair has already been set"); } 
        require(liqPoolAddress!=address(this) && swapRouterCA!=address(this) && wethPairedCA!=address(this));
        _isLiqPool[liqPoolAddress] = enabled;
		_liqPoolRouterCA[liqPoolAddress] = swapRouterCA;
		_liqPoolPairedCA[liqPoolAddress] = wethPairedCA;
		noLimits[liqPoolAddress] = false;
		noFees[liqPoolAddress] = false;

	}

	function _approveRouter(address routerAddress, uint256 _tokenAmount) internal {
		if ( _allowances[address(this)][routerAddress] < _tokenAmount ) {
			_allowances[address(this)][routerAddress] = type(uint256).max;
			emit Approval(address(this), routerAddress, type(uint256).max);
		}
	}

	function _addLiquidity(address routerAddress, uint256 _tokenAmount, uint256 _ethAmountWei) internal {
		address lpTokenRecipient = address(0);
		IUniswapV2Router02 dexRouter = IUniswapV2Router02(routerAddress);
		dexRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function LFG() external onlyOwner {
		require(!tradingOpen, "Trading is already open");
		openBlock =  block.number;
		maxTxAmount = 6_969_699_699_699 * 1e18;
		maxWalletAmount = maxTxAmount * 2;
		tradingOpen = true;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender != address(0), "No transfers from zero wallet");

		if (!tradingOpen) { require(noFees[sender] && noLimits[sender], "Trading not open"); }

		if ( !_inTaxSwap && _isLiqPool[recipient] ) {
			_swapTaxAndLiquify(recipient);
		}
		if ( sender != address(this) && recipient != address(this) && sender != owner ) { require(_checkLimits(recipient, amount), "Transaction exceeds limits"); }
		uint256 _taxAmount = _calculateTax(sender, recipient, amount);
		uint256 _transferAmount = amount - _taxAmount;
		_balances[sender] = _balances[sender] - amount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _checkLimits(address recipient, uint256 transferAmount) internal view returns (bool) {
		bool limitCheckPassed = true;
		if ( tradingOpen && !noLimits[recipient] ) {
			if ( transferAmount > maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > maxWalletAmount) ) { limitCheckPassed = false; }
		}
		return limitCheckPassed;
	}

	function _checkTradingOpen(address sender) private view returns (bool){
		bool checkResult = false;
		if ( tradingOpen ) { checkResult = true; } 
		else if ( tx.origin == owner ) { checkResult = true; } 
		else if (noFees[sender] && noLimits[sender]) { checkResult = true; } 

		return checkResult;
	}

	function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
		uint256 taxAmount;
		if ( !tradingOpen || noFees[sender] || noFees[recipient] ) { taxAmount = 0; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * taxRateSell / 100; }
		else { taxAmount = amount * taxRateTX / 100; }
		return taxAmount;
	}

	function setExemptFromTax(address wallet, bool toggle) external onlyOwner {
		noFees[ wallet ] = toggle;
	}

	function setExemptFromLimits(address wallet, bool setting) external onlyOwner {
		noLimits[ wallet ] = setting;
	}

	function removeLimits() external onlyOwner {
		uint256 newTxAmt = _totalSupply;
        uint256 newWalletAmt = _totalSupply;
		maxTxAmount = newTxAmt;
		maxWalletAmount = newWalletAmt;
	}

	function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		taxSwapMin = _totalSupply * minValue / minDivider;
		taxSwapMax = _totalSupply * maxValue / maxDivider;
		require(taxSwapMax>=taxSwapMin, "MinMax error");
		require(taxSwapMax>_totalSupply / 100000, "Upper threshold too low");
		require(taxSwapMax<_totalSupply / 100, "Upper threshold too high");
	}

	function _swapTaxAndLiquify(address _liqPoolAddress) private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));

		if ( _taxTokensAvailable >= taxSwapMin && tradingOpen ) {
			if ( _taxTokensAvailable >= taxSwapMax ) { _taxTokensAvailable = taxSwapMax; }
			uint256 _tokensForLP = _taxTokensAvailable * _autoLPShares / _totalTaxShares / 2;
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
			if( _tokensToSwap > 10**_decimals ) {
				uint256 _ethPreSwap = address(this).balance;
				_swapTaxTokensForEth(_liqPoolRouterCA[_liqPoolAddress], _liqPoolPairedCA[_liqPoolAddress], _tokensToSwap);
				uint256 _ethSwapped = address(this).balance - _ethPreSwap;
				if ( _autoLPShares > 0 ) {
					uint256 _ethWeiAmount = _ethSwapped * _autoLPShares / _totalTaxShares ;
					_approveRouter(_liqPoolRouterCA[_liqPoolAddress], _tokensForLP);
					_addLiquidity(_liqPoolRouterCA[_liqPoolAddress], _tokensForLP, _ethWeiAmount);
				}
			}

		}
	}

	function _swapTaxTokensForEth(address routerAddress, address pairedCA, uint256 _tokenAmount) private {
		_approveRouter(routerAddress, _tokenAmount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = pairedCA;
		IUniswapV2Router02 dexRouter = IUniswapV2Router02(routerAddress);
		dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
	}

	function taxTokensSwap(address liqPoolAddress) external onlyOwner {
		uint256 taxTokenBalance = balanceOf(address(this));
		require(taxTokenBalance > 0, "No tokens");
		require(_isLiqPool[liqPoolAddress], "Invalid liquidity pool");
		_swapTaxTokensForEth(_liqPoolRouterCA[liqPoolAddress], _liqPoolPairedCA[liqPoolAddress], taxTokenBalance);
	}

}