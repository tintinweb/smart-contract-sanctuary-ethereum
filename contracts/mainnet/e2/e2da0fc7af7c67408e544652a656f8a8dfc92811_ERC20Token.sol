/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract OWNED {
	address internal _owner;
	event OwnershipTransferred(address owner);
	constructor(address contractOwner) { _owner = contractOwner; }
	modifier onlyOwner() { require(msg.sender == _owner, "Not the owner"); _; }
	function owner() external view returns (address) { return _owner; }
	function renounceOwnership() external onlyOwner { _transferOwnership(address(0)); }
	function transferOwnership(address newOwner) external onlyOwner { _transferOwnership(newOwner); }
	function _transferOwnership(address _newOwner) internal {
		_owner = _newOwner; 
		emit OwnershipTransferred(_newOwner); 
	}
}

contract ERC20Token is OWNED {
	bool internal launched = false;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	uint8 private _decimals;
	uint256 private _totalSupply;
	string private _name;
	string private _symbol;

	mapping(address => bool) private _excluded;

	uint8 private _taxDevAndMarketing; uint8 private _taxLiquidity; uint8 _taxTokenBurn; uint8 private _totalTaxPct;
	address payable private _walletDevAndMarketing;
	uint256 private _maxTx; uint256 private _maxWallet;
	uint256 private _swapThreshold;
	uint256 private _swapLimit;

	address private constant primarySwapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	IUniswapV2Router02 private swapRouter;
	address private WETH; 
	address private LPOwner;
	address private primaryLP;
	mapping(address => bool) private _isLP;

	bool private swapLocked;
	modifier lockSwap { swapLocked = true; _; swapLocked = false; }
	modifier postLaunch { require(launched, "Not launched"); _; }

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	constructor() OWNED(msg.sender)  {
        swapRouter = IUniswapV2Router02(primarySwapRouterAddress);
        WETH = swapRouter.WETH();
        LPOwner = msg.sender;
    }
	receive() external payable {}

	function launch(
		string memory tokenName, string memory tokenSymbol, uint256 tokenSupply, uint8 tokenDecimals,
		uint8 taxForDevAndMarketing, uint8 taxForLiquidity, uint8 taxForBurn, address walletForDevAndMarketing, 
		uint16 maxTxPermille, uint16 maxWalletPermille,
		uint8 tokenSupplyPercentageForLP
		) external payable onlyOwner {
			require(!launched, "Already launched");
			launched = true;
			_decimals = tokenDecimals;
			_totalSupply = tokenSupply * (10**_decimals);
			_name = tokenName;
			_symbol = tokenSymbol;

			require(tokenSupplyPercentageForLP > 0 && tokenSupplyPercentageForLP <= 100, "LP supply must be 1-100%");
			_balances[address(this)] = _totalSupply * tokenSupplyPercentageForLP / 100;
			emit Transfer(address(0), address(this), _balances[address(this)]);
			if (_balances[address(this)] != _totalSupply) {
				_balances[_owner] = _totalSupply - _balances[address(this)];
				emit Transfer(address(0), _owner, _balances[_owner]);
			}

			_taxDevAndMarketing = taxForDevAndMarketing; 
			_taxLiquidity = taxForLiquidity; 
			_taxTokenBurn = taxForBurn;
			_totalTaxPct = taxForDevAndMarketing + _taxLiquidity + taxForBurn;
			require(_totalTaxPct<=100,"Tax error");
			_walletDevAndMarketing = payable(walletForDevAndMarketing);

			_maxTx = _totalSupply * maxTxPermille / 1000;
			_maxWallet = _totalSupply * maxWalletPermille / 1000;
			_swapThreshold = _totalSupply * 10 / 100000;
			_swapLimit = _totalSupply * 85 / 100000;

			_excluded[_owner] = true;
			_excluded[address(this)] = true;
			_excluded[primarySwapRouterAddress] = true;
			_excluded[_walletDevAndMarketing] = true;

			require(msg.value>0, "Cannot add liquidity if message value is 0 ETH");
			require(primaryLP == address(0), "LP exists");
			primaryLP = IUniswapV2Factory(swapRouter.factory()).createPair(address(this), WETH);
			_isLP[primaryLP] = true;
			_addLiquidity(_balances[address(this)], msg.value);
	}

	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		require(address(this).balance >= ethAmount, "Not enough ETH");
		require(_balances[address(this)] >= tokenAmount, "Not enough tokens");
		_checkAndApproveRouter(tokenAmount);
		swapRouter.addLiquidityETH{value: ethAmount} ( address(this), tokenAmount, 0, 0, LPOwner, block.timestamp );
	}

	function name() public view postLaunch returns (string memory) { return _name; }
	function symbol() public view postLaunch returns (string memory) { return _symbol; }
	function decimals() public view postLaunch returns (uint8) { return _decimals; }
	function totalSupply() public view postLaunch returns (uint256) { return _totalSupply; }
	function balanceOf(address account) public view postLaunch returns (uint256) { return _balances[account]; }
	function allowance(address owner, address spender) public view postLaunch returns (uint256) { return _allowances[owner][spender]; }
	
	function approve(address spender, uint256 amount) public postLaunch returns (bool) {
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
		if (_allowances[address(this)][primarySwapRouterAddress] < tokenAmount) { 
			_approve(address(this), primarySwapRouterAddress, type(uint256).max);
		}
	}

	function transfer(address to, uint256 amount) public postLaunch returns (bool) {
		_transfer(msg.sender, to, amount);
		return true;
	}
	function transferFrom(address from, address to, uint256 amount) public postLaunch returns (bool) {
		require(_allowances[from][msg.sender] >= amount,"ERC20: amount exceeds allowance");
		_allowances[from][msg.sender] -= amount;
		_transfer(from, to, amount);
		return true;
	}
	function _transfer(address from, address to, uint256 amount) private {
		require(from != address(0) && to != address(0), "ERC20: Zero address"); 
		require(_balances[from] >= amount, "ERC20: amount exceeds balance"); 
		require(_limitCheck(from, to, amount), "Limits exceeded");

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
		uint256 taxTokens = 0;
		if (_isLP[from] && !_excluded[to]) { taxTokens = amount * _totalTaxPct / 100; }
		else if (_isLP[to] && !_excluded[from]) { taxTokens = amount * _totalTaxPct / 100; }
		else { taxTokens = 0; }	
		return taxTokens;
	}

	function tax() external view postLaunch returns (uint8 taxDevAndMarketing, uint8 taxLiquidity, uint8 taxBurn, address walletDevAndMarketing) { return (_taxDevAndMarketing, _taxLiquidity, _taxTokenBurn, _walletDevAndMarketing); }
	function limits() external view postLaunch returns (uint256 maxTransaction, uint256 maxWallet) { return (_maxTx, _maxWallet); }
	function excluded(address wallet) external view postLaunch returns (bool) { return _excluded[wallet]; }

	function changeLimits(uint16 maxTxPermille, uint16 maxWalletPermille) external postLaunch onlyOwner {
		uint256 newMaxTx = _totalSupply * maxTxPermille / 1000;
		uint256 newMaxWallet = _totalSupply * maxWalletPermille / 1000; 
		require(newMaxTx >= _maxTx && newMaxWallet >= _maxWallet, "Cannot decrease limits");
		_maxTx = newMaxTx;
		_maxWallet = newMaxWallet;
	}

	function changeTaxRates(uint8 taxDevAndMarketing, uint8 taxLiquidity, uint8 taxBurn) external postLaunch onlyOwner {
		uint8 newTotalTaxPct = taxDevAndMarketing +  taxLiquidity + taxBurn;
		if (_totalTaxPct > 15) { require(newTotalTaxPct < _totalTaxPct, "Tax must decrease"); } 
		else { require(newTotalTaxPct <= 15, "Tax cannot exceed 15%"); }
		_taxDevAndMarketing = taxDevAndMarketing;
		_taxLiquidity = taxLiquidity;
		_taxTokenBurn = taxBurn;
		_totalTaxPct = newTotalTaxPct;
	}

	function changeTaxWallets(address payable walletDevAndMarketing) external postLaunch onlyOwner {
		require(!_isLP[walletDevAndMarketing] && walletDevAndMarketing != primarySwapRouterAddress && walletDevAndMarketing != address(this) && walletDevAndMarketing != address(0));
		_excluded[walletDevAndMarketing] = true;
		_walletDevAndMarketing = walletDevAndMarketing;
	}	
	
	function burn(uint256 amount) external postLaunch {
		_burn(msg.sender, amount);
	}

	function _burn(address from, uint256 amount) private {
		require(_balances[from] >= amount, "Low balance");
		_balances[from] -= amount;
		_balances[address(0)] += amount;
		emit Transfer(from, address(0), amount);
	}

	function _processTaxTokens() private lockSwap {
		uint256 swapAmount = balanceOf(address(this));
		uint256 swapLimit = _swapLimit;
		uint8 totalTaxPercent = _totalTaxPct;
		uint8 burnTax = _taxTokenBurn;
		if (burnTax > 0 && burnTax < totalTaxPercent) {	swapLimit = _swapLimit * totalTaxPercent / (totalTaxPercent-burnTax); }
		if (swapAmount >= _swapThreshold) {
			if (swapAmount >= swapLimit) { swapAmount = swapLimit; }	
			if (_taxTokenBurn > 0) { 
				uint256 burnAmount = swapAmount * _taxTokenBurn / totalTaxPercent;
				_burn(address(this), burnAmount);
				totalTaxPercent -= _taxTokenBurn;
				swapAmount -= burnAmount;
			}
			uint256 lpTokens = swapAmount * _taxLiquidity / totalTaxPercent / 2;
			uint256 swapTokens = swapAmount - lpTokens;
			if (swapTokens >= 10**_decimals) {
				uint256 ethBalanceBeforeSwap = address(this).balance;
				_swapTokensForEth(swapTokens);
				if (_taxLiquidity > 0) {
					uint256 ethFromSwap = address(this).balance - ethBalanceBeforeSwap;
					_checkAndApproveRouter(lpTokens);
					_addLiquidity(lpTokens, ethFromSwap);
				}
			}
		}
		_sendTaxEth();
	}
	function _swapTokensForEth(uint256 tokenAmount) private {
		_checkAndApproveRouter(tokenAmount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = WETH;
		swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
	}
	function _sendTaxEth() private {
		uint256 ethBalance = address(this).balance;
		if (ethBalance > 0) { _walletDevAndMarketing.transfer(ethBalance); }
	}

	function manualSwap() external postLaunch onlyOwner { _swapTokensForEth(_balances[address(this)]); }
	function manualSend() external postLaunch onlyOwner { _sendTaxEth(); }
	function setExcluded(address wallet, bool isExcluded) external postLaunch onlyOwner { _excluded[wallet] = isExcluded; }
	function setExtraLP(address lpContractAddress, bool isLiquidityPool) external postLaunch onlyOwner { 
		require(lpContractAddress != primaryLP, "Cannot change the primary LP");
		_isLP[lpContractAddress] = isLiquidityPool; 
	}
}