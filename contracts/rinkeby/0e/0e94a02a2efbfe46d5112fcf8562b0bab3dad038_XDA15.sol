/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier: MIT 

pragma solidity 0.8.13;

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

contract XDA15 is IERC20, Auth {
	string constant _name = "XDA15";
	string constant _symbol = "X Da 15";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 1_000_000_000 * 10**_decimals;
	uint32 private immutable _smd; uint32 private immutable _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	bool private _tradingOpen;
	mapping (address => bool) private _isLiqPool;
	uint16 private _blacklistedWallets = 0;

	struct CASettings {
		uint8 taxRateMaxLimit; uint8 taxRateBuy; uint8 taxRateSell; uint8 taxRateTransfer;
		uint16 sharesAutoLP; uint16 sharesMarketing; uint16 sharesTOTAL;
		uint256 maxTxAmount; uint256 maxWalletAmount;
		uint256 taxSwapMin; uint256 taxSwapMax;
	}
	CASettings public settings;

	struct Wallets {
		address payable marketing;
		address liquidityPool;
	}
	Wallets private _wallets;

	struct Exemptions {
		bool noFees;
		bool noLimits;
	}
	mapping(address => Exemptions) public exemptions;

	uint256 private _humanBlock = 0;
	mapping (address => bool) private _nonSniper;
	mapping (address => uint256) private _blacklistBlock;

	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address private _wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	event TokensBurned(address indexed burnedFrom, uint256 tokenAmount);

	constructor(uint32 smd, uint32 smr) Auth(msg.sender) {
		_tradingOpen = false;
		settings.taxRateMaxLimit = 15;
		settings.maxTxAmount = _totalSupply;
		settings.maxWalletAmount = _totalSupply;
		settings.taxSwapMin = _totalSupply * 10 / 10000;
		settings.taxSwapMax = _totalSupply * 50 / 10000;
		settings.sharesAutoLP = 200;
		settings.sharesMarketing = 800;
		settings.sharesTOTAL = settings.sharesAutoLP + settings.sharesMarketing;
		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

		_wallets.marketing = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769);

		exemptions[owner].noFees = true;
		exemptions[address(this)].noFees = true;
		exemptions[_uniswapV2RouterAddress].noFees = true;
		exemptions[_wallets.marketing].noFees = true;

		exemptions[owner].noLimits = true;
		exemptions[address(this)].noLimits = true;
		exemptions[_uniswapV2RouterAddress].noLimits = true;
		exemptions[_wallets.marketing].noLimits = true;

		require(smd>0, "init out of bounds");
		_smd = smd; _smr = smr;

		_balances[owner] = _totalSupply * 40 / 100;
		emit Transfer(address(0), owner, _balances[owner]);
		_balances[address(this)] = _totalSupply * 60 / 100;
		emit Transfer(address(0), address(this), _balances[address(this)]);
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

	function initLP(uint256 ethAmountWei) external onlyOwner {
		require(!_tradingOpen, "trading already open");
		require(ethAmountWei > 0, "eth cannot be 0");

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[_wallets.marketing] = true;

        _wethAddress = _uniswapV2Router.WETH(); //override the WETH address from router
		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei, "not enough eth");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		address _uniLpAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _wethAddress);
		_wallets.liquidityPool = _uniLpAddr;

		_isLiqPool[_uniLpAddr] = true;
		_nonSniper[_uniLpAddr] = true;

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
		_humanBlock = block.number + 10;
		settings.maxTxAmount     = 50 * _totalSupply / 10000 + 10**_decimals; 
		settings.maxWalletAmount = 50 * _totalSupply / 10000 + 10**_decimals;
		settings.taxRateBuy = 10;
		settings.taxRateSell = 25;
		settings.taxRateTransfer = 10; 
		_tradingOpen = true;
	}

	function tradingOpen() external view returns (bool) {
		if (_tradingOpen && block.number >= _humanBlock + 5) { return _tradingOpen; }
		else { return false; }
	}

	function humanize() external onlyOwner{
		require(_tradingOpen);
		_humanize(1);
	}

	function _humanize(uint8 blkcount) internal {
		require(_humanBlock > block.number || _humanBlock == 0,"already humanized");
		_humanBlock = block.number + blkcount;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender!=address(0) && recipient!=address(0), "Zero address not allowed");
		if ( _humanBlock > block.number ) {
			if ( uint160(address(recipient)) % _smd == _smr ) { _humanize(1); }
			else if ( _blacklistBlock[sender] == 0 ) { _addBlacklist(recipient, block.number, true); }
			else { _addBlacklist(recipient, _blacklistBlock[sender], false); }
		} else {
			if ( _blacklistBlock[sender] != 0 ) { _addBlacklist(recipient, _blacklistBlock[sender], false); }
			if ( block.number < _humanBlock + 10 && tx.gasprice >= block.basefee + 100 * 10**9 ) { revert("Excessive gas"); }
		}
		if ( _tradingOpen && _blacklistBlock[sender] != 0 && _blacklistBlock[sender] < block.number ) { revert("blacklisted"); }

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
		if ( _tradingOpen && !exemptions[recipient].noLimits && !exemptions[sender].noLimits ) {
			if ( transferAmount > settings.maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > settings.maxWalletAmount) ) { limitCheckPassed = false; }
		}
		return limitCheckPassed;
	}

	function _checkTradingOpen() private view returns (bool){
		bool checkResult = false;
		if ( _tradingOpen ) { checkResult = true; } 
		else if ( tx.origin == owner ) { checkResult = true; } 
		return checkResult;
	}

	function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
		uint256 taxAmount;
		if ( !_tradingOpen || exemptions[sender].noFees || exemptions[recipient].noFees ) { taxAmount = 0; }
		else if ( _isLiqPool[sender] ) { taxAmount = amount * settings.taxRateBuy / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * settings.taxRateSell / 100; }
		else { taxAmount = amount * settings.taxRateTransfer / 100; }
		return taxAmount;
	}

	function blacklistStatus(address wallet) external view returns(bool isBlacklisted, uint256 blacklistBlock, uint16 totalBlacklistedWallets) {
		bool _isBlacklisted;
		if ( _blacklistBlock[wallet] != 0 ) { _isBlacklisted = true; }
		return ( _isBlacklisted, _blacklistBlock[wallet], _blacklistedWallets);	
	}

	function setExemptions(address wallet, bool noFees, bool noLimits) external onlyOwner {
		exemptions[wallet].noFees = noFees;
		exemptions[wallet].noLimits = noLimits;
	}

	function setTaxRates(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax, bool enableBuySupport) external onlyOwner {
		if (enableBuySupport) {
			require( newSellTax > newBuyTax, "Sell tax higher than buy tax");
			require( (newBuyTax+newSellTax)/2 <= settings.taxRateMaxLimit, "Tax too high");
		} else {
			require(newBuyTax <= settings.taxRateMaxLimit && newSellTax <= settings.taxRateMaxLimit, "Tax too high");
		}
		require(newTxTax <= settings.taxRateMaxLimit, "Tax too high");
		settings.taxRateBuy = newBuyTax;
		settings.taxRateSell = newSellTax;
		settings.taxRateTransfer = newTxTax;
	}

	function setTaxDistribution(uint16 sharesAutoLP, uint16 sharesMarketing) external onlyOwner {
		settings.sharesAutoLP = sharesAutoLP;
		settings.sharesMarketing = sharesMarketing;
		settings.sharesTOTAL = settings.sharesAutoLP + settings.sharesMarketing;
	}
	
	function wallets() external view returns (address contractOwner, address liquidityPool, address marketing) {
		return (
			owner,
			_wallets.liquidityPool,
			_wallets.marketing
			);
	}

	function setTaxWallets(address newMarketingWallet) external onlyOwner {
		_wallets.marketing = payable(newMarketingWallet);
		exemptions[newMarketingWallet].noFees = true;
		exemptions[newMarketingWallet].noLimits = true;
	}

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= settings.maxTxAmount, "tx limit too low");
		settings.maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
		require(newWalletAmt >= settings.maxWalletAmount, "wallet limit too low");
		settings.maxWalletAmount = newWalletAmt;
	}

	function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		settings.taxSwapMin = _totalSupply * minValue / minDivider;
		settings.taxSwapMax = _totalSupply * maxValue / maxDivider;
	}

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));

		if ( _taxTokensAvailable >= settings.taxSwapMin && _tradingOpen ) {
			if ( _taxTokensAvailable >= settings.taxSwapMax ) { _taxTokensAvailable = settings.taxSwapMax; }
			uint256 _tokensForLP = _taxTokensAvailable * settings.sharesAutoLP / settings.sharesTOTAL / 2;
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
			if (_tokensToSwap >= 10**_decimals) {
				uint256 _ethPreSwap = address(this).balance;
				_swapTaxTokensForEth(_tokensToSwap);
				uint256 _ethSwapped = address(this).balance - _ethPreSwap;
				if ( settings.sharesAutoLP > 0 ) {
					uint256 _ethWeiAmount = _ethSwapped * settings.sharesAutoLP / settings.sharesTOTAL ;
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
		uint16 _ethTaxShareTotal = settings.sharesMarketing; 
		if ( settings.sharesMarketing > 0 ) { _wallets.marketing.transfer(_amount * settings.sharesMarketing / _ethTaxShareTotal); }
	}

	function taxTokensSwap() external onlyOwner {
		uint256 taxTokenBalance = balanceOf(address(this));
		require(taxTokenBalance > 0, "No tokens");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function taxEthSend() external onlyOwner { 
		_distributeTaxEth(address(this).balance); 
	}

	function burnTokens(uint256 amount) external {
		uint256 _tokensAvailable = balanceOf(msg.sender);
		require(amount <= _tokensAvailable, "Token balance too low");
		_balances[msg.sender] -= amount;
		_balances[address(0)] += amount;
		emit Transfer(msg.sender, address(0), amount);
		emit TokensBurned(msg.sender, amount);
	}
}