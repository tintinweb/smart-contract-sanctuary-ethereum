/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

//SPDX-License-Identifier: MIT 
//Note: SafeMath is not used because it is redundant since solidity 0.8

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
	function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner; emit OwnershipTransferred(newOwner); }
	event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract T91 is IERC20, Auth {
	string constant _name = "Tel91";
	string constant _symbol = "T91";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 10_000_000_000_000 * 10**_decimals;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	mapping (address => bool) public excludedFromFees;
	mapping (address => bool) public excludedFromLimits;
	bool public tradingOpen;
	uint256 public maxTxAmount; uint256 public maxWalletAmount;
	uint256 public taxSwapMin; uint256 public taxSwapMax;
	mapping (address => bool) private _isLiqPool;
	uint8 constant _defTaxRate = 5; 
	uint8 public buyTaxRate; uint8 public sellTaxRate;

	bool public antiBotEnabled = true;
	mapping (address => uint256) _lastTxBlock;
	mapping (address => bool) public antiBotExcluded;

	address payable private taxWallet = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769);

	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // UniswapV2 for ETH
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	constructor () Auth(msg.sender) {      
		// tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
		taxSwapMin = _totalSupply * 10 / 10000;
		taxSwapMax = _totalSupply * 50 / 10000;
		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		excludedFromFees[_uniswapV2RouterAddress] = true;

		antiBotExcluded[owner] = true;
		antiBotExcluded[address(this)] = true;

		excludedFromFees[owner] = true;
		excludedFromFees[address(this)] = true;
		excludedFromFees[taxWallet] = true;

		excludedFromLimits[owner] = true;
		excludedFromLimits[address(this)] = true;
		excludedFromLimits[taxWallet] = true;
		
		_balances[address(this)] = _totalSupply * 250 / 1000;
		emit Transfer(address(0), address(this), _balances[address(this)]);
		_balances[owner] = _totalSupply - _balances[address(this)];
		emit Transfer(address(0), address(owner), _balances[owner]);
	}
	
	receive() external payable {}
	
	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
	function getOwner() external view override returns (address) { return owner; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

	function approve(address spender, uint256 amount) public override returns (bool) {
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		require(_checkTradingOpen(), "Trading not open");
		return _transferFrom(msg.sender, recipient, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		require(_checkTradingOpen(), "Trading not open");
		if (_allowances[sender][msg.sender] != type(uint256).max){
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
		}
		return _transferFrom(sender, recipient, amount);
	}

	function initLP(uint256 ethAmountWei) external onlyOwner {
		require(!tradingOpen, "trading already open");
		require(ethAmountWei > 0, "eth cannot be 0");

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei, "not enough eth");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		address _uniLpAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		_isLiqPool[_uniLpAddr] = true;

		_approveRouter(_contractTokenBalance);
		_addLiquidity(_contractTokenBalance, ethAmountWei, false);

		_openTrading();
	}

	function _approveRouter(uint256 _tokenAmount) internal {
		if ( _allowances[address(this)][_uniswapV2RouterAddress] < _tokenAmount ) {
			_allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
			emit Approval(address(this), _uniswapV2RouterAddress, type(uint256).max);
		}
	}

	function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
		address lpTokenRecipient = address(0);
		if ( !autoburn ) { lpTokenRecipient = owner; }
		_uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function _openTrading() internal {
		maxTxAmount     = 50 * _totalSupply / 1000 + 10**_decimals; 
		maxWalletAmount = 50 * _totalSupply / 1000 + 10**_decimals;
		buyTaxRate = 3;
		sellTaxRate = 3;
		tradingOpen = true;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		if ( tradingOpen ) {
			if ( antiBotEnabled ) { checkAntiBot(sender, recipient); }
			if ( !_inTaxSwap && _isLiqPool[recipient] ) { _swapTaxAndDistributeEth(); }
		}

		require(_checkLimits(sender, recipient, amount), "TX exceeds limits");
		uint256 _taxAmount = _calculateTax(sender, recipient, amount);
		uint256 _transferAmount = amount - _taxAmount;
		_balances[sender] = _balances[sender] - amount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _checkLimits(address sender, address recipient, uint256 transferAmount) internal view returns (bool) {
		bool limitCheckPassed = true;

		if ( 
			//if any of the condition is false, no limits will be imposed on the transfer
			sender != address(this) && 
			recipient != address(this) && 
			sender != owner && 
			recipient != owner &&
			tradingOpen && 
			!excludedFromLimits[recipient] && 
			!excludedFromLimits[sender] 
		) {
			if ( transferAmount > maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > maxWalletAmount) ) { limitCheckPassed = false; }
		}	
	
		return limitCheckPassed;
	}

	function _checkTradingOpen() private view returns (bool){
		bool checkResult = false;
		if ( tradingOpen ) { checkResult = true; } 
		else if ( tx.origin == owner ) { checkResult = true; } 
		return checkResult;
	}

	function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
		uint256 taxAmount;
		if ( !tradingOpen || excludedFromFees[sender] || excludedFromFees[recipient] ) { taxAmount = 0; }
		else if ( _isLiqPool[sender] ) { taxAmount = amount * buyTaxRate / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * sellTaxRate / 100; }
		else { taxAmount = 0; }
		return taxAmount;
	}


	function checkAntiBot(address sender, address recipient) internal {
		if ( _isLiqPool[sender] && !antiBotExcluded[recipient] ) { //buy transactions
			require(_lastTxBlock[recipient] < block.number, "AntiBot triggered");
			_lastTxBlock[recipient] = block.number;
		} else if ( _isLiqPool[recipient] && !antiBotExcluded[sender] ) { //sell transactions
			require(_lastTxBlock[sender] < block.number, "AntiBot triggered");
			_lastTxBlock[sender] = block.number;
		}
	}

	function enableAntiBot(bool enabled) external onlyOwner {
		antiBotEnabled = enabled;
	}

	function excludeFromAntiBot(address wallet, bool excluded) external onlyOwner {
		require(wallet != address(this), "Contract must be excluded from anti-bot");
		antiBotExcluded[wallet] = excluded;
	}

	function disableFees(address wallet, bool toggle) external onlyOwner {
		if (wallet == address(this)) { require(toggle, "Contract cannot impose tax on itself"); }
		else if (wallet == owner) { require(toggle, "Cannot impose tax on contract owner"); }
		excludedFromFees[ wallet ] = toggle;
	}

	function disableLimits(address wallet, bool toggle) external onlyOwner {
		if (wallet == address(this)) { require(toggle, "Contract cannot impose limits on itself"); }
		else if (wallet == owner) { require(toggle, "Cannot impose limits on contract owner"); }
		excludedFromLimits[ wallet ] = toggle;
	}

	function adjustTaxRate(uint8 newBuyTax, uint8 newSellTax) external onlyOwner {
		require(newBuyTax <= _defTaxRate && newSellTax <= _defTaxRate, "Tax too high");
		//set new tax rate percentage - cannot be higher than the default rate 5%
		buyTaxRate = newBuyTax;
		sellTaxRate = newSellTax;
	}
  
	function setTaxWallet(address newTaxWallet) external onlyOwner {
		taxWallet = payable(newTaxWallet);
		excludedFromFees[newTaxWallet] = true;
	}

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= maxTxAmount, "tx limit too low");
		maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
		require(newWalletAmt >= maxWalletAmount, "wallet limit too low");
		maxWalletAmount = newWalletAmt;
	}

	function taxSwapSettings(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		taxSwapMin = _totalSupply * minValue / minDivider;
		taxSwapMax = _totalSupply * maxValue / maxDivider;
		require(taxSwapMax>=taxSwapMin, "MinMax error");
		require(taxSwapMax>_totalSupply / 10000, "Upper threshold too low");
		require(taxSwapMax<_totalSupply / 10, "Upper threshold too high");
	}

	function _swapTaxAndDistributeEth() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));
		if ( _taxTokensAvailable >= taxSwapMin && tradingOpen ) {
			if ( _taxTokensAvailable >= taxSwapMax ) { _taxTokensAvailable = taxSwapMax; }
			_swapTaxTokensForEth(_taxTokensAvailable);
			uint256 _contractETHBalance = address(this).balance;
			if (_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
		}
	}

	function _swapTaxTokensForEth(uint256 _tokenAmount) private {
		_approveRouter(_tokenAmount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _uniswapV2Router.WETH();
		_uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
	}

	function _distributeTaxEth(uint256 _amount) private {
		taxWallet.transfer(_amount);
	}

	function taxTokensSwap() external onlyOwner {
		uint256 taxTokenBalance = balanceOf(address(this));
		require(taxTokenBalance > 0, "No tokens");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function taxEthSend() external onlyOwner { 
		uint256 _contractEthBalance = address(this).balance;
		require(_contractEthBalance > 0, "No ETH in contract to distribute");
		_distributeTaxEth(_contractEthBalance); 
	}
}