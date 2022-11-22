/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
	function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function factory() external pure returns (address);
	function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

abstract contract OWNED {
	address internal _owner;
	event OwnershipTransferred(address owner);
	constructor(address contractOwner) { _owner = contractOwner; }
	modifier onlyOwner() { require(msg.sender == _owner, "Not the owner"); _; }
	// function owner() external view returns (address) { return _owner; }  // moved into addressList() function
	function renounceOwnership() external onlyOwner { _transferOwnership(address(0)); }
	function transferOwnership(address newOwner) external onlyOwner { _transferOwnership(newOwner); }
	function _transferOwnership(address _newOwner) internal {
		_owner = _newOwner; 
		emit OwnershipTransferred(_newOwner); 
	}
}

contract BLOOD is IERC20, OWNED {
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	uint8 private constant _decimals = 9;
	uint256 private constant _totalSupply = 100_000_000 * 10**_decimals;
	string private constant _name = "Blood Bank";
	string private constant _symbol = "BLOOD";

	uint256 private _maxTx; 
	uint256 private _maxWallet;

	uint256 private _swapThreshold = _totalSupply;
	uint256 private _swapLimit = _totalSupply;

	uint8 private _taxRateBuy;
	uint8 private _taxRateSell;

	mapping(address => bool) private _excluded;
	address private _treasuryWallet = address(0x35E6b861DbE175F64dEf1FAC5E2853e5613Eb764);
	address private constant _usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	
	address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uniswap V2 Router
	IUniswapV2Router02 private constant _swapRouter = IUniswapV2Router02(_swapRouterAddress);
	address private _primaryLP;
	mapping(address => bool) private _isLP;
	bool private _initialLiquidityAdded;
	
	uint256 private _openAt;
	uint256 private _protected;

	bool private swapLocked;
	modifier lockSwap { swapLocked = true; _; swapLocked = false; }

	constructor() OWNED(msg.sender)  {
		_balances[address(msg.sender)] = _totalSupply;
		emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);

		_changeLimits(3,6); //set max TX to 0.3%, max wallet 0.6%

		_excluded[_owner] = true;
		_excluded[address(this)] = true;
		_excluded[_swapRouterAddress] = true;
		_excluded[_treasuryWallet] = true;

		_primaryLP = IUniswapV2Factory(_swapRouter.factory()).createPair(address(this), _usdc);
		_isLP[_primaryLP] = true;
	}

	function addressList() external view returns (address owner, address treasury, address usdc, address swapRouter, address primaryLP) {
		return (_owner, _treasuryWallet, _usdc, _swapRouterAddress, _primaryLP);
	}

	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
	function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
	function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }
	function approve(address spender, uint256 amount) public override returns (bool) {
		require(_balances[msg.sender] > 0,"ERC20: Zero balance");
		_approve(msg.sender, spender, amount);
		return true;
	}
	function _approve(address owner, address spender, uint256 amount ) private {
		require(owner != address(0) && spender != address(0), "ERC20: Zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	function _checkAndApproveRouter(uint256 tokenAmount) private {
		if (_allowances[address(this)][_swapRouterAddress] < tokenAmount) { 
			_approve(address(this), _swapRouterAddress, type(uint256).max);
		}
	}

	function _checkAndApproveRouterForToken(address _token, uint256 amount) internal {
		uint256 tokenAllowance;
		if (_token == address(this)) {
			tokenAllowance = _allowances[address(this)][_swapRouterAddress];
			if (amount > tokenAllowance) {
				_allowances[address(this)][_swapRouterAddress] = type(uint256).max;
			}
		} else {
			tokenAllowance = IERC20(_token).allowance(address(this), _swapRouterAddress);
			if (amount > tokenAllowance) {
				IERC20(_token).approve(_swapRouterAddress, type(uint256).max);
			}
		}
    }

	function transfer(address to, uint256 amount) public returns (bool) {
		_transfer(msg.sender, to, amount);
		return true;
	}
	function transferFrom(address from, address to, uint256 amount) public returns (bool) {
		require(_allowances[from][msg.sender] >= amount,"ERC20: amount exceeds allowance");
		_allowances[from][msg.sender] -= amount;
		_transfer(from, to, amount);
		return true;
	}
	function _transfer(address from, address to, uint256 amount) private {
		require(from != address(0) && to != address(0), "ERC20: Zero address"); 
		require(_balances[from] >= amount, "ERC20: amount exceeds balance"); 
		require(_limitCheck(from, to, amount), "Limits exceeded");
		require(block.timestamp>_openAt, "Not enabled");

		if (block.timestamp>=_openAt && block.timestamp<_protected && tx.gasprice>block.basefee) {
			uint256 _gpb = tx.gasprice - block.basefee;
			uint256 _gpm = 10 * (10**9);
			require(_gpb<_gpm,"Not enabled");
		}

		if ( !swapLocked && !_excluded[from] && _isLP[to] ) { _processTaxTokens(); }

		uint256 taxTokens = _getTaxTokens(from, to, amount);
		_balances[from] -= amount;
		_balances[address(this)] += taxTokens;
		_balances[to] += (amount - taxTokens);
		emit Transfer(from, to, amount);
	}
	function _limitCheck(address from, address to, uint256 amount) private view returns (bool) {
		bool txSize = true;
		if ( amount > _maxTx && !_excluded[from] && !_excluded[to] ) { txSize = false; }
		bool walletSize = true;
		uint256 newBalanceTo = _balances[to] + amount;
		if ( newBalanceTo > _maxWallet && !_excluded[from] && !_excluded[to] && !_isLP[to] ) { walletSize = false; } 
		return (txSize && walletSize);
	}

	function _getTaxTokens(address from, address to, uint256 amount) private view returns (uint256) {
		uint256 _taxTokensAmount;
		if ( (_isLP[from] && !_excluded[to]) ) { 
            if (block.timestamp > _openAt + 120) { _taxTokensAmount = amount * _taxRateBuy / 100; }
            else if (block.timestamp > _openAt) { _taxTokensAmount = amount * 99 / 100; } //antisnipe 99% tax for 120 seconds after trading opens
		} else if (_isLP[to] && !_excluded[from]) { 
			_taxTokensAmount = amount * _taxRateSell / 100; 
		}
		return _taxTokensAmount;
	}


	function addInitialLiquidity(uint256 val) external onlyOwner {
		require(IERC20(_usdc).balanceOf(address(this))>0, "No USDC");
		require(!_initialLiquidityAdded, "Liquidity already added");
		_addLiquidity(address(this), _balances[address(this)], IERC20(_usdc).balanceOf(address(this)), false);
		_initialLiquidityAdded = true;

		_swapThreshold = _totalSupply * 5 / 10000;
		_swapLimit = _totalSupply * 25 / 10000;

		_taxRateBuy = 10;
		_taxRateSell = 15; //anti-dump sell tax at launch

		_openAt = block.timestamp + (val * 7 / 10) + 1662;
		_protected = _openAt + 600;
	}

	function _addLiquidity(address _token, uint256 tokenAmount, uint256 usdcAmount, bool burnLpTokens) internal {
		require(IERC20(_token).balanceOf(address(this)) >= tokenAmount, "Not enough tokens");
		require(IERC20(_usdc).balanceOf(address(this)) >= usdcAmount, "Not enough USDC");
		_checkAndApproveRouterForToken(_token, tokenAmount);
		_checkAndApproveRouterForToken(_usdc, usdcAmount);
		address lpRecipient = _owner;
		if (burnLpTokens) { lpRecipient = address(0); }

		_swapRouter.addLiquidity(_usdc, _token, usdcAmount, tokenAmount, 0, 0, lpRecipient, block.timestamp);
	}

	function setPreLaunch(uint256 t1, uint256 t2) external onlyOwner {
		require(_openAt > block.timestamp, "already live");
		_openAt = block.timestamp + (t1 / t2) + 462;
		_protected = _openAt + 600;
	}

	function tax() external view returns (uint8 buyTax, uint8 sellTax) { return (_taxRateBuy, _taxRateSell); }
	function limits() external view returns (uint256 maxTransaction, uint256 maxWallet) { return (_maxTx, _maxWallet); }
	function isExcluded(address wallet) external view returns (bool) { return _excluded[wallet]; }

	function changeLimits(uint16 maxTxPermille, uint16 maxWalletPermille) external onlyOwner { _changeLimits(maxTxPermille, maxWalletPermille); }
	function _changeLimits(uint16 _maxTxPermille, uint16 _maxWalletPermille) private {
		uint256 newMaxTx = (_totalSupply * _maxTxPermille / 1000) + (10 * 10**_decimals); //add 10 tokens to avoid rounding issues
		uint256 newMaxWallet = (_totalSupply * _maxWalletPermille / 1000) + (10 * 10**_decimals); //add 10 tokens to avoid rounding issues
		require(newMaxTx >= _maxTx && newMaxWallet >= _maxWallet, "Cannot decrease limits");
		if (newMaxTx > _totalSupply) { newMaxTx = _totalSupply; }
		if (newMaxWallet > _totalSupply) { newMaxWallet = _totalSupply; }
		_maxTx = newMaxTx;
		_maxWallet = newMaxWallet;
	}

	function changeTaxWallet(address walletTreasury) external onlyOwner {
		require(!_isLP[walletTreasury] && walletTreasury != _swapRouterAddress && walletTreasury != address(this) && walletTreasury != address(0));
		_excluded[walletTreasury] = true;
		_treasuryWallet = walletTreasury;
	}	

	function changeTaxRates(uint8 newTaxRateBuy, uint8 newTaxRateSell) external onlyOwner {
		require( (newTaxRateBuy+newTaxRateSell) <= 20, "Max roundtrip is 20%" );
		_taxRateBuy = newTaxRateBuy;
		_taxRateSell = newTaxRateSell;
	}
	
	function _processTaxTokens() private lockSwap {
		uint256 tokensToSwap = _balances[address(this)];
		if (tokensToSwap >= _swapThreshold) {
			if (tokensToSwap > _swapLimit) { tokensToSwap = _swapLimit; }
			if (tokensToSwap >= 10**_decimals) {
				_swapTokens(address(this), _usdc, tokensToSwap, _treasuryWallet);
			}
		}
	}

	function _swapTokens(address inputToken, address outputToken, uint256 inputAmount, address recipient) private {		
		_checkAndApproveRouterForToken(inputToken, inputAmount);
		address[] memory path = new address[](2);
		path[0] = inputToken;
		path[1] = outputToken;
		_swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			inputAmount,
			0,
			path,
			recipient,
			block.timestamp
		);
	}

	function recoverTokens(address tokenCa) external onlyOwner {
		require(tokenCa != address(this),"Not allowed");
		uint256 tokenBalance = IERC20(tokenCa).balanceOf(address(this));
		IERC20(tokenCa).transfer(msg.sender, tokenBalance);
	}

	function manualSwap() external onlyOwner { _processTaxTokens(); }

	function setExcluded(address wallet, bool exclude) external onlyOwner { 
		string memory notAllowedError = "Not allowed";
		require(!_isLP[wallet], notAllowedError);
		require(wallet != address(this), notAllowedError);
		require(wallet != _swapRouterAddress, notAllowedError);
	 	_excluded[wallet] = exclude; 
	}

	function changeSwapThresholds(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		_swapThreshold = _totalSupply * minValue / minDivider;
		_swapLimit = _totalSupply * maxValue / maxDivider;
		require(_swapLimit > _swapThreshold);
		require(_swapLimit <= _totalSupply * 5 / 1000); // limit must be less than 0.5% supply
	}

	function burn(uint256 amount) external {
		require(_balances[msg.sender] >= amount, "Low balance");
		_balances[msg.sender] -= amount;
		_balances[address(0)] += amount;
		emit Transfer(msg.sender, address(0), amount);
	}
	function setAdditionalLP(address lpAddress, bool isLiqPool) external onlyOwner {
		string memory notAllowedError = "Not allowed";
		require(!_excluded[lpAddress], notAllowedError);
		require(lpAddress != _primaryLP, notAllowedError);
		require(lpAddress != address(this), notAllowedError);
		require(lpAddress != _swapRouterAddress, notAllowedError);
		_isLP[lpAddress] = isLiqPool;
	}
	function isLP(address ca) external view returns (bool) { return _isLP[ca]; }
}