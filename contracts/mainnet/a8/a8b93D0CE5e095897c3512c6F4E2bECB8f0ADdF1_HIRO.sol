/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
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

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract HIRO is IERC20, Auth {
	string constant _name = "Hiroshima"; 
	string constant _symbol = "HIRO"; 
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 1_000_000 * 10**_decimals;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	uint256 private _tradingOpenBlock;
	mapping (address => bool) private _isLiqPool;
	uint16 private _blacklistedWallets = 0;

	uint8 private fee_taxRateMaxLimit; uint8 private fee_taxRateBuy; uint8 private fee_taxRateSell; uint8 private fee_taxRateTransfer;
	uint16 private fee_sharesAutoLP; uint16 private fee_sharesBurn; uint16 private fee_sharesDevelopment; uint16 private fee_sharesTOTAL;

	uint256 private lim_maxTxAmount; uint256 private lim_maxWalletAmount;
	uint256 private lim_taxSwapMin; uint256 private lim_taxSwapMax;

	address payable private wlt_development;
	address private _liquidityPool;

	mapping(address => bool) private exm_noFees;
	mapping(address => bool) private exm_noLimits;
	
	uint256 private _humanBlock = 0;
	mapping (address => bool) private _nonSniper;
	mapping (address => uint256) private _blacklistBlock;

	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address private _wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	event TokensBurned(address burnedFrom, uint256 tokenAmount);
	event TaxRatesChanged(uint8 taxRateBuy, uint8 taxRateSell, uint8 taxRateTransfer);
	event TaxWalletChanged(address development);
	event TaxDistributionChanged(uint16 autoLP, uint16 burn, uint16 development);
	event LimitsIncreased(uint256 maxTransaction, uint256 maxWalletSize);
	event TaxSwapSettingsChanged(uint256 taxSwapMin, uint256 taxSwapMax);
	event WalletExemptionsSet(address wallet, bool noFees, bool noLimits);


	constructor() Auth(msg.sender) {
		_tradingOpenBlock = type(uint256).max; 
		fee_taxRateMaxLimit = 8;
		lim_maxTxAmount = _totalSupply;
		lim_maxWalletAmount = _totalSupply;
		lim_taxSwapMin = _totalSupply * 1 / 10000;
		lim_taxSwapMax = _totalSupply * 50 / 10000;
		fee_sharesAutoLP = 400;
		fee_sharesBurn = 600;
		fee_sharesDevelopment = 300;
		fee_sharesTOTAL = fee_sharesAutoLP + fee_sharesBurn + fee_sharesDevelopment;
		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

		wlt_development = payable(0x3446B47aE8C571A25B79F7195aB331DD99b84664);

		exm_noFees[owner] = true;
		exm_noFees[address(this)] = true;
		exm_noFees[_uniswapV2RouterAddress] = true;
		exm_noFees[wlt_development] = true;

		exm_noLimits[owner] = true;
		exm_noLimits[address(this)] = true;
		exm_noLimits[_uniswapV2RouterAddress] = true;
		exm_noLimits[wlt_development] = true;

		_balances[address(this)] = _totalSupply;
		emit Transfer(address(0), address(this), _totalSupply);
	}
	
	receive() external payable {}
	
	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

	function approve(address spender, uint256 amount) public override returns (bool) {
		if ( _humanBlock > block.number && !_nonSniper[msg.sender] ) {
			_addBlacklist(msg.sender, block.number, true);
		}

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

	function addLP() external onlyOwner {
		require(!_tradingOpen(), "trading already open");
		require(_liquidityPool == address(0), "LP already added");

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[wlt_development] = true;

		_wethAddress = _uniswapV2Router.WETH();
		_liquidityPool = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _wethAddress);

		_isLiqPool[_liquidityPool] = true;
		_nonSniper[_liquidityPool] = true;

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= 0, "no eth");		
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");

		_approveRouter(_contractTokenBalance);
		_addLiquidity(_contractTokenBalance, _contractETHBalance, false);
		uint256 _blks = 14;
		_openTrading(_blks);
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

	function _openTrading(uint256 blks) internal {
		lim_maxTxAmount     = 100 * _totalSupply / 10000 + 10**_decimals; 
		lim_maxWalletAmount = 100 * _totalSupply / 10000 + 10**_decimals;
		fee_taxRateBuy = 5;
		fee_taxRateSell = 8;
		fee_taxRateTransfer = 0; 
		_tradingOpenBlock = block.number + blks;
		_humanBlock = _tradingOpenBlock + 9;
	}

	function tradingOpen() external view returns (bool) {
		if (_tradingOpen() && block.number >= _humanBlock + 10) { return _tradingOpen(); }
		else { return false; }
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender!=address(0) && recipient!=address(0), "Zero address not allowed");
		if ( _humanBlock > block.number ) {
			if ( _blacklistBlock[sender] == 0 ) { _addBlacklist(recipient, block.number, true); }
			else { _addBlacklist(recipient, _blacklistBlock[sender], false); }
		} else {
			if ( _blacklistBlock[sender] != 0 ) { _addBlacklist(recipient, _blacklistBlock[sender], false); }
		}

		if ( _tradingOpen() && _blacklistBlock[sender] != 0 && _blacklistBlock[sender] < block.number ) { revert("blacklisted"); }

		if ( !_inTaxSwap && _isLiqPool[recipient] ) { _swapTaxAndLiquify();	}

		if ( sender != address(this) && recipient != address(this) && sender != owner ) { require(_checkLimits(sender, recipient, amount), "TX exceeds limits"); }
		uint256 _taxAmount = _calculateTax(sender, recipient, amount);
		uint256 _transferAmount = amount - _taxAmount;
		_balances[sender] = _balances[sender] - amount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _addBlacklist(address wallet, uint256 blackBlockNum, bool addSniper) internal {
		if ( !_nonSniper[wallet] && _blacklistBlock[wallet] == 0 ) { 
			_blacklistBlock[wallet] = blackBlockNum; 
			if ( addSniper) { _blacklistedWallets ++; }
		}
	}
	
	function _checkLimits(address sender, address recipient, uint256 transferAmount) internal view returns (bool) {
		bool limitCheckPassed = true;
		if ( _tradingOpen() && !exm_noLimits[recipient] && !exm_noLimits[sender] ) {
			if ( transferAmount > lim_maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > lim_maxWalletAmount) ) { limitCheckPassed = false; }
		}
		return limitCheckPassed;
	}

	function _tradingOpen() private view returns (bool) {
		bool result = false;
		if (block.number >= _tradingOpenBlock) { result = true; }
		return result;
	}

	function _checkTradingOpen() private view returns (bool){
		bool checkResult = false;
		if ( _tradingOpen() ) { checkResult = true; } 
		else if ( tx.origin == owner ) { checkResult = true; } 
		return checkResult;
	}

	function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
		uint256 taxAmount;
		if ( !_tradingOpen() || exm_noFees[sender] || exm_noFees[recipient] ) { taxAmount = 0; }
		else if ( _isLiqPool[sender] ) { taxAmount = amount * fee_taxRateBuy / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * fee_taxRateSell / 100; }
		else { taxAmount = amount * fee_taxRateTransfer / 100; }
		return taxAmount;
	}

	function getBlacklistStatus(address wallet) external view returns(bool isBlacklisted, uint256 blacklistBlock, uint16 totalBlacklistedWallets) {
		bool _isBlacklisted;
		if ( _blacklistBlock[wallet] != 0 ) { _isBlacklisted = true; }
		return ( _isBlacklisted, _blacklistBlock[wallet], _blacklistedWallets);	
	}

	function getExemptions(address wallet) external view returns(bool noFees, bool noLimits) {
		return (exm_noFees[wallet], exm_noLimits[wallet]);
	}

	function setExemptions(address wallet, bool noFees, bool noLimits) external onlyOwner {
		exm_noFees[wallet] = noFees;
		exm_noLimits[wallet] = noLimits;
		emit WalletExemptionsSet(wallet, noFees, noLimits);
	}

	function getFeeSettings() external view returns(uint8 taxRateMaxLimit, uint8 taxRateBuy, uint8 taxRateSell, uint8 taxRateTransfer, uint16 sharesAutoLP, uint16 sharesBurn, uint16 sharesDevelopment ) {
		return (fee_taxRateMaxLimit, fee_taxRateBuy, fee_taxRateSell, fee_taxRateTransfer, fee_sharesAutoLP, fee_sharesBurn, fee_sharesDevelopment);
	}

	function setTaxRates(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax) external onlyOwner {
		require(newBuyTax+newSellTax <= 2*fee_taxRateMaxLimit, "Avg tax too high");
		require(newTxTax <= fee_taxRateMaxLimit, "Tax too high");
		fee_taxRateBuy = newBuyTax;
		fee_taxRateSell = newSellTax;
		fee_taxRateTransfer = newTxTax;
		emit TaxRatesChanged(newBuyTax, newSellTax, newTxTax);
	}

	function setTaxDistribution(uint16 sharesAutoLP, uint16 sharesBurn, uint16 sharesDevelopment) external onlyOwner {
		fee_sharesAutoLP = sharesAutoLP;
		fee_sharesBurn = sharesBurn;
		fee_sharesDevelopment = sharesDevelopment;
		fee_sharesTOTAL = fee_sharesAutoLP + fee_sharesBurn + fee_sharesDevelopment;
		emit TaxDistributionChanged(sharesAutoLP, sharesBurn, sharesDevelopment);
	}
	
	function getWallets() external view returns(address contractOwner, address liquidityPool, address development) {
		return (owner, _liquidityPool, wlt_development);
	}

	function setTaxWallets(address newDevelopmentWallet) external onlyOwner {
		wlt_development = payable(newDevelopmentWallet);
		exm_noFees[newDevelopmentWallet] = true;
		exm_noLimits[newDevelopmentWallet] = true;
		emit TaxWalletChanged(newDevelopmentWallet);
	}

	function getLimits() external view returns(uint256 maxTxAmount, uint256 maxWalletAmount, uint256 taxSwapMin, uint256 taxSwapMax) {
		return (lim_maxTxAmount, lim_maxWalletAmount, lim_taxSwapMin, lim_taxSwapMax);
	}

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= lim_maxTxAmount, "tx limit too low");
		lim_maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
		require(newWalletAmt >= lim_maxWalletAmount, "wallet limit too low");
		lim_maxWalletAmount = newWalletAmt;
		emit LimitsIncreased(lim_maxTxAmount, lim_maxWalletAmount);
	}

	function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		lim_taxSwapMin = _totalSupply * minValue / minDivider;
		lim_taxSwapMax = _totalSupply * maxValue / maxDivider;
		require(lim_taxSwapMax > lim_taxSwapMin);
		emit TaxSwapSettingsChanged(lim_taxSwapMin, lim_taxSwapMax);
	}

	function _burnTokens(uint256 amount, address burnedFrom) private {
		if ( amount > 0 ) {
			_balances[burnedFrom] -= amount;
			_balances[address(0)] += amount;
			emit Transfer(burnedFrom, address(0), amount);
			emit TokensBurned(burnedFrom, amount);
		}
	}

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));

		if ( _taxTokensAvailable >= lim_taxSwapMin && _tradingOpen() ) {
			if ( _taxTokensAvailable >= lim_taxSwapMax ) { _taxTokensAvailable = lim_taxSwapMax; }
			
			uint256 _tokensForLP = _taxTokensAvailable * fee_sharesAutoLP / fee_sharesTOTAL / 2;
			
			uint256 _tokensToBurn = _taxTokensAvailable * fee_sharesBurn / fee_sharesTOTAL;
			_burnTokens(_tokensToBurn, address(this));

			uint256 _tokensToSwap = _taxTokensAvailable - _tokensToBurn - _tokensForLP;
			if (_tokensToSwap >= 10**_decimals) {
				uint256 _ethPreSwap = address(this).balance;
				_swapTaxTokensForEth(_tokensToSwap);
				uint256 _ethSwapped = address(this).balance - _ethPreSwap;
				if ( fee_sharesAutoLP > 0 ) {
					uint256 _ethWeiAmount = _ethSwapped * fee_sharesAutoLP / fee_sharesTOTAL ;
					_approveRouter(_tokensForLP);
					_addLiquidity(_tokensForLP, _ethWeiAmount, false);
				}
			}
			uint256 _contractETHBalance = address(this).balance;			
			if (_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
		}
	}

	function _swapTaxTokensForEth(uint256 _tokenAmount) private {
		_approveRouter(_tokenAmount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _wethAddress;
		_uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
	}

	function _distributeTaxEth(uint256 _amount) private {
		if ( fee_sharesDevelopment > 0 ) { wlt_development.transfer(_amount); }
	}

	function taxManualSwapSend(bool swapTokens, bool sendEth) external onlyOwner {
		if (swapTokens) {
			uint256 taxTokenBalance = balanceOf(address(this));
			require(taxTokenBalance > 0, "No tokens");
			_swapTaxTokensForEth(taxTokenBalance);
		}
		
		if (sendEth) {
			_distributeTaxEth(address(this).balance); 
		}
	}

	function burnTokens(uint256 amount) external {
		uint256 _tokensAvailable = balanceOf(msg.sender);
		require(amount <= _tokensAvailable, "Token balance too low");
		_burnTokens(amount, msg.sender);
	}
}