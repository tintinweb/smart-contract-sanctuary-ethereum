/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

//SPDX-License-Identifier: MIT 

pragma solidity 0.8.17;

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

contract KNDX is IERC20, Auth {
	string constant _name = "Kondux";
	string constant _symbol = "KNDX";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 1_000_000_000 * 10**_decimals;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	mapping (address => bool) public excludedFromFees;
	bool public tradingOpen;
	uint256 public taxSwapMin; uint256 public taxSwapMax;
	mapping (address => bool) private _isLiqPool;
	uint8 constant _maxTaxRate = 5; 
	uint8 public taxRateBuy; uint8 public taxRateSell;

	bool public antiBotEnabled;
	mapping (address => bool) public excludedFromAntiBot;
	mapping (address => uint256) private _lastSwapBlock;

	address payable private taxWallet = payable(0x79BD02b5936FFdC5915cB7Cd58156E3169F4F569);

	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);
	event TokensBurned(address indexed burnedByWallet, uint256 tokenAmount);
	event TaxWalletChanged(address newTaxWallet);
	event TaxRateChanged(uint8 newBuyTax, uint8 newSellTax);

	constructor () Auth(msg.sender) {      
		taxSwapMin = _totalSupply * 10 / 10000;
		taxSwapMax = _totalSupply * 50 / 10000;
		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		excludedFromFees[_uniswapV2RouterAddress] = true;

		excludedFromAntiBot[owner] = true;
		excludedFromAntiBot[address(this)] = true;

		excludedFromFees[owner] = true;
		excludedFromFees[address(this)] = true;
		excludedFromFees[taxWallet] = true;
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

	function _distributeInitialBalances() internal {
		//holder airdrops 27.965%, 1556 wallets
		uint256 airdropTokensAmount = 279_646_010 * 10**_decimals;
		_balances[owner] = airdropTokensAmount;
		emit Transfer(address(0), owner, airdropTokensAmount ); 

		// Treasury 25%: 0x1D0A105F0cED39b207AE444957cc70483c04C767
		uint256 treasuryAmount = 250_000_000 * 10**_decimals;
		_balances[address(0x1D0A105F0cED39b207AE444957cc70483c04C767)] = treasuryAmount;
		emit Transfer(address(0), address(0x1D0A105F0cED39b207AE444957cc70483c04C767), treasuryAmount );

		// Dev Fund 19.462% : 0xac5c6FDd4F32977eec56C48978bAe86CE08968e0 
		uint256 devFundAmount = 194_620_743 * 10**_decimals;
		_balances[address(0xac5c6FDd4F32977eec56C48978bAe86CE08968e0)] = devFundAmount;
		emit Transfer(address(0), address(0xac5c6FDd4F32977eec56C48978bAe86CE08968e0), devFundAmount );

		// Rewards pool 15%: 0x94baCbCceE5c16520Ab8545c35e89eCE7017a34D 
		uint256 rewardsPoolAmount = 150_000_000 * 10**_decimals;
		_balances[address(0x94baCbCceE5c16520Ab8545c35e89eCE7017a34D)] = rewardsPoolAmount;
		emit Transfer(address(0), address(0x94baCbCceE5c16520Ab8545c35e89eCE7017a34D), rewardsPoolAmount );

		// Marketing 44076978.428271124 : 0xCbE59E5967B80Ad18764d49c9184E6249aFe2D28 
		uint256 marketingAmount = 44_076_978 * 10**_decimals;
		_balances[address(0xCbE59E5967B80Ad18764d49c9184E6249aFe2D28)] = marketingAmount;
		emit Transfer(address(0), address(0xCbE59E5967B80Ad18764d49c9184E6249aFe2D28), marketingAmount );

		//liquidity pool is 2.507%
		uint256 liquidityPoolAmount = 25_066_478 * 10**_decimals; 
		_balances[address(this)] = liquidityPoolAmount;
		emit Transfer(address(0), address(this), liquidityPoolAmount );

		// Burn amount (diff between total supply and the above, ~ 5.659%
		uint256 burnAmount = _totalSupply - (airdropTokensAmount+treasuryAmount+devFundAmount+rewardsPoolAmount+marketingAmount+liquidityPoolAmount);
		_balances[address(0)] = burnAmount;
		emit Transfer(address(0), address(0), burnAmount );
		emit TokensBurned(address(0), burnAmount);
	}

	function initLP() external onlyOwner {
		require(!tradingOpen, "trading already open");

		_distributeInitialBalances();

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance > 0, "no eth in contract");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		address _uniLpAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		_isLiqPool[_uniLpAddr] = true;

		_approveRouter(_contractTokenBalance);
		_addLiquidity(_contractTokenBalance, _contractETHBalance, false);

		// _openTrading(); //trading will be open manually through enableTrading() function
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

    function enableTrading() external onlyOwner {
        _openTrading();
    }

	function _openTrading() internal {
        require(!tradingOpen, "trading already open");
		taxRateBuy = 3;
		taxRateSell = 3;
		tradingOpen = true;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender != address(0) || recipient != address(0), "Zero wallet cannot do transfers.");
		if ( tradingOpen ) {
			if ( antiBotEnabled ) { checkAntiBot(sender, recipient); }
			if ( !_inTaxSwap && _isLiqPool[recipient] ) { _swapTaxAndDistributeEth(); }
		}

		uint256 _taxAmount = _calculateTax(sender, recipient, amount);
		uint256 _transferAmount = amount - _taxAmount;
		_balances[sender] = _balances[sender] - amount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);
		return true;
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
		else if ( _isLiqPool[sender] ) { taxAmount = amount * taxRateBuy / 100; }
		else if ( _isLiqPool[recipient] ) { taxAmount = amount * taxRateSell / 100; }
		else { taxAmount = 0; }
		return taxAmount;
	}


	function burnTokens(uint256 amount) external {
		//burns tokens from the msg.sender's wallet
		uint256 _tokensAvailable = balanceOf(msg.sender);
		require(amount <= _tokensAvailable, "Token balance too low");
		_balances[msg.sender] -= amount;
		_balances[address(0)] += amount;
		emit Transfer(msg.sender,address(0), amount);
		emit TokensBurned(msg.sender, amount);
	}


	function checkAntiBot(address sender, address recipient) internal {
		if ( _isLiqPool[sender] && !excludedFromAntiBot[recipient] ) { //buy transactions
			require(_lastSwapBlock[recipient] < block.number, "AntiBot triggered");
			_lastSwapBlock[recipient] = block.number;
		} else if ( _isLiqPool[recipient] && !excludedFromAntiBot[sender] ) { //sell transactions
			require(_lastSwapBlock[sender] < block.number, "AntiBot triggered");
			_lastSwapBlock[sender] = block.number;
		}
	}

	function enableAntiBot(bool isEnabled) external onlyOwner {
		antiBotEnabled = isEnabled;
	}

	function excludeFromAntiBot(address wallet, bool isExcluded) external onlyOwner {
		if (!isExcluded) { require(wallet != address(this) && wallet != owner, "This address must be excluded" ); }
		excludedFromAntiBot[wallet] = isExcluded;
	}

	function excludeFromFees(address wallet, bool isExcluded) external onlyOwner {
		if (isExcluded) { require(wallet != address(this) && wallet != owner, "Cannot enforce fees for this address"); }
		excludedFromFees[wallet] = isExcluded;
	}

	function adjustTaxRate(uint8 newBuyTax, uint8 newSellTax) external onlyOwner {
		require(newBuyTax <= _maxTaxRate && newSellTax <= _maxTaxRate, "Tax too high");
		//set new tax rate percentage - cannot be higher than the default rate 5%
		taxRateBuy = newBuyTax;
		taxRateSell = newSellTax;
		emit TaxRateChanged(newBuyTax, newSellTax);
	}
  
	function setTaxWallet(address newTaxWallet) external onlyOwner {
		taxWallet = payable(newTaxWallet);
		excludedFromFees[newTaxWallet] = true;
		emit TaxWalletChanged(newTaxWallet);
	}

	function taxSwapSettings(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		taxSwapMin = _totalSupply * minValue / minDivider;
		taxSwapMax = _totalSupply * maxValue / maxDivider;
		require(taxSwapMax>=taxSwapMin, "MinMax error");
		require(taxSwapMax>_totalSupply / 10000, "Upper threshold too low");
		require(taxSwapMax<_totalSupply * 2 / 100, "Upper threshold too high");
	}

	function _swapTaxAndDistributeEth() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));
		if ( _taxTokensAvailable >= taxSwapMin && tradingOpen ) {
			if ( _taxTokensAvailable >= taxSwapMax ) { _taxTokensAvailable = taxSwapMax; }
			if ( _taxTokensAvailable > 10**_decimals) {
				_swapTaxTokensForEth(_taxTokensAvailable);
				uint256 _contractETHBalance = address(this).balance;
				if (_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
			}
			
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

	function airdrop(address[] calldata addresses, uint256[] calldata tokenAmounts) external onlyOwner {
        require(addresses.length <= 250,"Wallet count over 250 (gas risk)");
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