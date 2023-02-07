/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

//SPDX-License-Identifier: MIT
/*
https://t.me/AI_INU_Entry 
https://ai-inu.org
THE LEADER OF ALL AI's & INU's
*/


pragma solidity 0.8.17;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address __owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed _owner, address indexed spender, uint256 value);
}

abstract contract Auth {
	address internal _owner;
	constructor(address creatorOwner) { _owner = creatorOwner; }
	modifier onlyOwner() { require(msg.sender == _owner, "Only contract _owner can call this function"); _; }
	function transferOwnership(address payable newOwner) external onlyOwner { _owner = newOwner; emit OwnershipTransferred(newOwner); }
	event OwnershipTransferred(address _owner);
}

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract AINU is IERC20, Auth {
	uint8 private constant _decimals      = 9;
	uint256 private constant _totalSupply = 100_000_000 * (10**_decimals);
	string private constant _name         = "AI INU";
	string private constant _symbol       = "AINU";

	uint8 private _buyTaxRate  = 1;
	uint8 private _sellTaxRate = 1;

	uint16 private _taxSharesMarketing   = 8;
	uint16 private _taxSharesDevelopment = 2;
	uint16 private _taxSharesBurn        = 0;
	uint16 private _taxSharesLP          = 0;
	uint16 private _totalTaxShares = _taxSharesMarketing + _taxSharesDevelopment + _taxSharesBurn + _taxSharesLP;

	address payable private _walletMarketing = payable(0xE968F0c14df44554eEE3a1Ef692db7bfeCD24e30); 
	address payable private _walletDevelopment = payable(0x4A5227de47f43f312b96Ecd16AC39A5bc77f75f3); 

	uint256 private _maxTxAmount     = _totalSupply; 
	uint256 private _maxWalletAmount = _totalSupply;
	uint256 private _taxSwapMin = _totalSupply * 10 / 100000;
	uint256 private _taxSwapMax = _totalSupply * 85 / 100000;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _noFees;
	mapping (address => bool) private _noLimits;

	address constant private _burnWallet = address(0);
	address private _lpOwner;

	address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //uniswap v2 router
	IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
	address private _primaryLP;
	mapping (address => bool) private _isLP;

	bool private _tradingOpen;

	bool private _inTaxSwap = false;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);
	event TokensBurned(address indexed burnedByWallet, uint256 tokenAmount);

	constructor() Auth(msg.sender) {
		_lpOwner = msg.sender;

		_balances[address(this)] =  90_000_000 * (10 ** _decimals);
		emit Transfer(address(0), address(this), _balances[address(this)]);

		_balances[_owner] = _totalSupply - _balances[address(this)];
		emit Transfer(address(0), _owner, _balances[_owner]);

		_noFees[_owner] = true;
		_noFees[address(this)] = true;
		_noFees[_swapRouterAddress] = true;
		_noFees[_walletMarketing] = true;
		_noFees[_walletDevelopment] = true;
		_noFees[_burnWallet] = true;
		_noLimits[_owner] = true;
		_noLimits[address(this)] = true;
		_noLimits[_swapRouterAddress] = true;
		_noLimits[_walletMarketing] = true;
		_noLimits[_walletDevelopment] = true;
		_noLimits[_burnWallet] = true;	
	}

	receive() external payable {}
	
	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
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
		require(!_tradingOpen, "trading already open");
		_openTrading();
	}

	function _approveRouter(uint256 _tokenAmount) internal {
		if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
			_allowances[address(this)][_swapRouterAddress] = type(uint256).max;
			emit Approval(address(this), _swapRouterAddress, type(uint256).max);
		}
	}

	function addInitialLiquidity() external onlyOwner lockTaxSwap {
		require(_primaryLP == address(0), "LP exists");
		require(address(this).balance>0, "No ETH in contract");
		require(_balances[address(this)]>0, "No tokens in contract");
		_primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
		_addLiquidity(_balances[address(this)], address(this).balance, false);
		_isLP[_primaryLP] = true;
	}

	function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
		address lpTokenRecipient = _lpOwner;
		if ( autoburn ) { lpTokenRecipient = address(0); }
		_approveRouter(_tokenAmount);
		_primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function _openTrading() internal {
		_maxTxAmount     = _totalSupply * 1 / 100; 
		_maxWalletAmount = _totalSupply * 1 / 100;
		_tradingOpen = true;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender != address(0), "No transfers from Zero wallet");
		if (!_tradingOpen) { require(_noFees[sender] && _noLimits[sender], "Trading not open"); }
		if ( !_inTaxSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }
		
		if ( sender != address(this) && recipient != address(this) && sender != _owner ) { require(_checkLimits(sender, recipient, amount), "TX exceeds limits"); }
		uint256 _taxAmount = _calculateTax(sender, recipient, amount);
		uint256 _transferAmount = amount - _taxAmount;
		_balances[sender] = _balances[sender] - amount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _checkLimits(address sender, address recipient, uint256 transferAmount) internal view returns (bool) {
		bool limitCheckPassed = true;
		if ( _tradingOpen && !_noLimits[sender] && !_noLimits[recipient] ) {
			if ( transferAmount > _maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) { limitCheckPassed = false; }
		}
		return limitCheckPassed;
	}

	function _checkTradingOpen(address sender) private view returns (bool){
		bool checkResult = false;
		if ( _tradingOpen ) { checkResult = true; } 
		else if (_noFees[sender] && _noLimits[sender]) { checkResult = true; } 

		return checkResult;
	}

	function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
		uint256 taxAmount;
		if ( !_tradingOpen || _noFees[sender] || _noFees[recipient] ) { taxAmount = 0; }
		else if ( _isLP[sender] ) { taxAmount = amount * _buyTaxRate / 100; }
		else if ( _isLP[recipient] ) { taxAmount = amount * _sellTaxRate / 100; }
		return taxAmount;
	}


	function getExemptions(address wallet) external view returns (bool noFees, bool noLimits) {
		return ( _noFees[wallet], _noLimits[wallet] );
	}
	function setExemptions(address wallet, bool noFees, bool noLimits) external onlyOwner {
		if (noLimits || noFees) { require(!_isLP[wallet], "Cannot exempt LP"); }
		_noFees[ wallet ] = noFees;
		_noLimits[ wallet ] = noLimits;
	}
	function setExtraLP(address lpContractAddress, bool isLiquidityPool) external onlyOwner { 
		require(lpContractAddress != _primaryLP, "Cannot change the primary LP");
		_isLP[lpContractAddress] = isLiquidityPool; 
		if (isLiquidityPool) { 
			_noFees[lpContractAddress] = false; 
			_noLimits[lpContractAddress] = false; 
		}
	}
	function isLP(address wallet) external view returns (bool) {
		return _isLP[wallet];
	}

	function getTaxInfo() external view returns (uint8 buyTax, uint8 sellTax, uint16 sharesMarketing, uint16 sharesDevelopment, uint16 sharesLP, uint16 sharesTokenBurn ) {
		return ( _buyTaxRate, _sellTaxRate, _taxSharesMarketing, _taxSharesDevelopment, _taxSharesLP, _taxSharesBurn);
	}
	function setTaxRates(uint8 newBuyTax, uint8 newSellTax) external onlyOwner {
		require(newBuyTax + newSellTax <= 98, "Roundtrip too high");
		_buyTaxRate = newBuyTax;
		_sellTaxRate = newSellTax;
	}  
	function setTaxDistribution(uint16 sharesTokenBurn, uint16 sharesAutoLP, uint16 sharesMarketing, uint16 sharesDevelopment) external onlyOwner {
		_taxSharesLP = sharesAutoLP;
		_taxSharesMarketing = sharesMarketing;
		_taxSharesDevelopment = sharesDevelopment;
		_totalTaxShares = sharesTokenBurn + sharesAutoLP + sharesMarketing + sharesDevelopment;
	}

	function getAddresses() external view returns (address owner, address primaryLP, address marketing, address development, address LPowner ) {
		return ( _owner, _primaryLP, _walletMarketing, _walletDevelopment, _lpOwner);
	}
	function setTaxWallets(address newMarketing, address newDevelopment, address newLpOwner) external onlyOwner {
		require(!_isLP[newMarketing] && !_isLP[newDevelopment] && !_isLP[newLpOwner], "LP cannot be tax wallet");
		_walletMarketing = payable(newMarketing);
		_walletDevelopment = payable(newDevelopment);
		_lpOwner = newLpOwner;
		_noFees[newMarketing] = true;
		_noFees[newDevelopment] = true;
		_noLimits[newMarketing] = true;
		_noLimits[newDevelopment] = true;
	}

	function getLimitsInfo() external view returns (uint256 maxTX, uint256 maxWallet, uint256 taxSwapMin, uint256 taxSwapMax ) {
		return ( _maxTxAmount, _maxWalletAmount, _taxSwapMin, _taxSwapMax);
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
		require(_taxSwapMax>=_taxSwapMin, "MinMax error");
		require(_taxSwapMax>_totalSupply / 100000, "Upper threshold too low");
		require(_taxSwapMax<_totalSupply / 100, "Upper threshold too high");
	}

	function _burnTokens(address fromWallet, uint256 amount) private {
		if ( amount > 0 ) {
			_balances[fromWallet] -= amount;
			_balances[_burnWallet] += amount;
			emit Transfer(fromWallet, _burnWallet, amount);
		}
	}

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));

		if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
			if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

			uint256 _tokensForLP = _taxTokensAvailable * _taxSharesLP / _totalTaxShares / 2;
			uint256 _tokensToBurn = _taxTokensAvailable * _taxSharesBurn / _totalTaxShares;
			_burnTokens(address(this), _tokensToBurn);
			
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP - _tokensToBurn;
			if( _tokensToSwap > 10**_decimals ) {
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
			if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
		}
	}

	function _swapTaxTokensForEth(uint256 tokenAmount) private {
		_approveRouter(tokenAmount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _primarySwapRouter.WETH();
		_primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
	}

	function _distributeTaxEth(uint256 amount) private {
		uint16 _taxShareTotal = _taxSharesMarketing + _taxSharesDevelopment;
		if (_taxShareTotal > 0) {
			uint256 marketingAmount = amount * _taxSharesMarketing / _taxShareTotal;
			uint256 developmentAmount = amount * _taxSharesDevelopment / _taxShareTotal;
			if ( marketingAmount > 0 ) { _walletMarketing.transfer(marketingAmount); }
			if ( developmentAmount > 0 ) { _walletDevelopment.transfer(developmentAmount); }
		}
	}

	function manualTaxSwapAndSend(bool swapTokens, bool sendEth) external onlyOwner {
		if (swapTokens) {
			uint256 taxTokenBalance = balanceOf(address(this));
			require(taxTokenBalance > 0, "No tokens");
			_swapTaxTokensForEth(taxTokenBalance);
		}
		if (sendEth) { 
			uint256 ethBalance = address(this).balance;
			require(ethBalance > 0, "No tokens");
			_distributeTaxEth(address(this).balance); 
		}
	}

	function burnTokens(uint256 amount) external {
		uint256 _tokensAvailable = balanceOf(msg.sender);
		require(amount <= _tokensAvailable, "Token balance too low");
		_burnTokens(msg.sender, amount);
		emit TokensBurned(msg.sender, amount);
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