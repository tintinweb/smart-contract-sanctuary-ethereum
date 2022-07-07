/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

//SPDX-License-Identifier: MIT 
//TELEGRAM : https://t.me/AkiraEntryPortal
//WEBSITE : http://Akiraeth.org
pragma solidity 0.8.15;

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

contract AKIRA is IERC20, Auth {
	string constant _name = "Akira";
	string constant _symbol = "Akira";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 100_000 * 10**_decimals;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
	bool private _tradingOpen;
	mapping (address => bool) private _isLiqPool;

	uint8 private fee_taxRateMaxLimit = 10; uint8 private fee_taxRateBuy; 
	uint8 private fee_taxRateSell; uint8 fee_taxRateSubFloorSell;
	uint256 private _tax_tokens_autoLp;

	uint256 private _floorPriceWei;
	uint16 private _floorPercentOfATH;
	uint16 private _floorATHminimalIncreasePercent;

	uint256 private lim_maxTxAmount; uint256 private lim_maxWalletAmount;
	uint256 private lim_taxSwapMin; uint256 private lim_taxSwapMax;

	address payable private wlt_marketing = payable(0xc3F928FDf6DDfA52880d0B3F95257Af116ae4682); //tax wallet where ETH not going to LP is sent
	address payable private wlt_operations = payable(0x54CCc234d567C0291bcD2e50A15FBce7D1F3ABb1); //tax wallet where ETH not going to LP is sent

	address private _liquidityPool;

	mapping(address => bool) private exm_noFees;
	mapping(address => bool) private exm_noLimits;
	
	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address private _wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	IERC20 private wethContract;

	event TokensBurned(address burnedFrom, uint256 tokenAmount);
	event TaxWalletChanged(address marketing, address operations);
	event LimitsIncreased(uint256 maxTransaction, uint256 maxWalletSize);
	event TaxSwapSettingsChanged(uint256 taxSwapMin, uint256 taxSwapMax);
	event WalletExemptionsSet(address wallet, bool noFees, bool noLimits);
	event FloorRaised(uint256 newFloorWeiPricePerToken);

	constructor() Auth(msg.sender) {
		lim_maxTxAmount = _totalSupply;
		lim_maxWalletAmount = _totalSupply;
		lim_taxSwapMin = _totalSupply * 10 / 10000; 
		lim_taxSwapMax = _totalSupply * 50 / 10000;

		exm_noFees[owner] = true;
		exm_noFees[address(this)] = true;
		exm_noFees[_uniswapV2RouterAddress] = true;
		exm_noFees[wlt_marketing] = true;
		exm_noFees[wlt_operations] = true;

		exm_noLimits[owner] = true;
		exm_noLimits[address(this)] = true;
		exm_noLimits[_uniswapV2RouterAddress] = true;
		exm_noLimits[wlt_marketing] = true;
		exm_noLimits[wlt_operations] = true;

		// deployer gets 20% supply
		_balances[owner] = _totalSupply * 215 / 1000;
		emit Transfer(address(0), owner, _balances[owner]);

		//80% stays in contract to add to liquidity
		_balances[address(this)] = _totalSupply * 785 / 1000;
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
		require(_balances[msg.sender] != 0);
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

	function addInitialLiquidity() external onlyOwner {
		require(!_tradingOpen, "trading already open");

		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		_wethAddress = _uniswapV2Router.WETH(); //override the WETH address from router
		wethContract = IERC20(_wethAddress);
		_liquidityPool = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _wethAddress);
		_isLiqPool[_liquidityPool] = true;

		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance > 0, "no eth to add");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		_approveRouter(_contractTokenBalance);
		_addLiquidity(_contractTokenBalance, _contractETHBalance, false);
	}

	function _approveRouter(uint256 _tokenAmount) internal {
		if ( _allowances[address(this)][_uniswapV2RouterAddress] < _tokenAmount ) {
			_allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
			emit Approval(address(this), _uniswapV2RouterAddress, type(uint256).max);
		}
	}

	function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
		address lpTokenRecipient = address(owner);
		if ( !autoburn ) { lpTokenRecipient = owner; }
		_uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function openTrading() external onlyOwner {
		require(!_tradingOpen, "trading already open");
		require(_liquidityPool != address(0), "LP not initialized");
		require( _balances[_liquidityPool] > 0, "Add liquidity first");
		_openTrading();
	}

	function _openTrading() internal {
		lim_maxTxAmount     = 10 * _totalSupply / 1000 + 10**_decimals; //max transaction 1% total supply
		lim_maxWalletAmount = 10 * _totalSupply / 1000 + 10**_decimals; //max wallet size 1% total supply
		fee_taxRateBuy = 6;
		fee_taxRateSell = 6;
		fee_taxRateSubFloorSell = 30;
		_floorPercentOfATH = 40; //floor level percentage of current price when floor is being set
		_floorATHminimalIncreasePercent = 100; // how many percent must price increase since last time floor was changed to trigger another floor raising event: 100 means 100% which means 2x; minimum is 1% (1.01x)
		updateFloorPrice(); //set initial floor price
		_tradingOpen = true;
	}

	function tradingOpen() external view returns (bool) { return _tradingOpen; }

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender!=address(0) && recipient!=address(0), "Zero address not allowed");

		if ( !_inTaxSwap && _isLiqPool[recipient] ) { 
			if (_tradingOpen) { updateFloorPrice(); }
			_swapTaxAndLiquify();
		}

		if ( sender != address(this) && recipient != address(this) && sender != owner ) { require(_checkLimits(sender, recipient, amount), "TX exceeds limits"); }

		(uint256 _taxAmount, bool isSubFloor) = _calculateTax(sender, recipient, amount);
		if (isSubFloor) { _tax_tokens_autoLp += _taxAmount; }	

		uint256 _transferAmount = amount - _taxAmount;
		if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
		_balances[sender] = _balances[sender] - amount;
		_balances[recipient] = _balances[recipient] + _transferAmount;
		emit Transfer(sender, recipient, amount);

		if ( _tradingOpen && _isLiqPool[sender] ) {  updateFloorPrice(); }

		return true;
	}

	function _checkLimits(address sender, address recipient, uint256 transferAmount) internal view returns (bool) {
		bool limitCheckPassed = true;
		if ( _tradingOpen && !exm_noLimits[recipient] && !exm_noLimits[sender] ) {
			if ( transferAmount > lim_maxTxAmount ) { limitCheckPassed = false; }
			else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > lim_maxWalletAmount) ) { limitCheckPassed = false; }
		}
		return limitCheckPassed;
	}

	function _checkTradingOpen() private view returns (bool){
		bool checkResult = false;
		if ( _tradingOpen ) { checkResult = true; } 
		else if ( tx.origin == owner ) { checkResult = true; } 
		return checkResult;
	}

	function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256, bool) {
		uint256 taxAmount;
		bool subFloorSell;
		if ( !_tradingOpen || exm_noFees[sender] || exm_noFees[recipient] ) { taxAmount = 0; }
		else if ( _isLiqPool[sender] ) { taxAmount = amount * fee_taxRateBuy / 100; }
		else if ( _isLiqPool[recipient] ) { 
			subFloorSell = _checkFloor(amount);
			if (subFloorSell) { taxAmount = amount * fee_taxRateSubFloorSell / 100; } 
			else { taxAmount = amount * fee_taxRateSell / 100; }
		}
		else { taxAmount = 0; }
		return (taxAmount, subFloorSell);
	}

	function calculatePrices(uint256 tokenAmountInLP, uint256 wethWeiInLP) private view returns (uint256 weiPricePerToken, uint256 weiCalculatedFloor) {
		uint256 pricePerToken;
		uint256 calculatedFloor;
		if (tokenAmountInLP != 0) {
			pricePerToken = (wethWeiInLP * 10**_decimals) / tokenAmountInLP;
			calculatedFloor = (pricePerToken * _floorPercentOfATH ) / 100;	
		}
		return (pricePerToken, calculatedFloor);
	}

	function getPriceInputData() private view returns (uint256 tokensInLP, uint256 wethWeiInLP) {
		uint256 _tokensInLP = _balances[_liquidityPool];
		uint256 _wethInLP = wethContract.balanceOf(_liquidityPool);
		return (_tokensInLP, _wethInLP);
	}

	function updateFloorPrice() private {
		(uint256 tokensInLP, uint256 wethInLP) = getPriceInputData();
		(, uint256 floor) = calculatePrices(tokensInLP, wethInLP);
 
		if (floor > ((_floorPriceWei * (100+_floorATHminimalIncreasePercent) ) / 100 ) ) { 
			_floorPriceWei = floor; 
			emit FloorRaised(floor);
		}
	}

	function _checkFloor(uint256 amount) private view returns (bool) {
		bool floorBreach;

		(uint256 tokensInLP, uint256 wethInLPWei) = getPriceInputData();
		(uint256 tokenPrice, ) = calculatePrices(tokensInLP, wethInLPWei);

		uint256 wethSellValueWei = (amount * tokenPrice) / (10**_decimals);

		(uint256 newPrice, ) = calculatePrices((tokensInLP + amount), (wethInLPWei - wethSellValueWei));
		if (newPrice < _floorPriceWei) { floorBreach = true; }

		return floorBreach;
	}

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = _balances[address(this)];
		uint256 _taxTokensAutoLP = _tax_tokens_autoLp;
		if (_taxTokensAutoLP > _taxTokensAvailable) { 
			_tax_tokens_autoLp = _taxTokensAvailable;
			_taxTokensAutoLP = _taxTokensAvailable;
		}
		uint256 _taxTokensFees = _taxTokensAvailable - _taxTokensAutoLP;

		if ( _taxTokensAvailable > 0 && _taxTokensAvailable >= lim_taxSwapMin && _tradingOpen ) {
			if ( _taxTokensAvailable >= lim_taxSwapMax ) { 
				uint256 ratio1000x = _taxTokensAvailable * 1000 / lim_taxSwapMax; 
				_taxTokensAutoLP = (_taxTokensAutoLP / ratio1000x) * 1000;
				_taxTokensFees = lim_taxSwapMax - _taxTokensAutoLP;
				_taxTokensAvailable = _taxTokensAutoLP + _taxTokensFees;
			}

			uint256 _tokensForLP_half = (_taxTokensAutoLP / 2); 
			uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP_half ;

			if (_tokensToSwap >= 10**_decimals) {
				uint256 _ethPreSwap = address(this).balance;
				_swapTaxTokensForEth(_tokensToSwap);
				uint256 _ethSwapped = address(this).balance - _ethPreSwap;
				
				if ( _tokensForLP_half > 0 ) {
					uint256 _ethWeiAmount = (_ethSwapped * _tokensForLP_half) / _taxTokensAvailable ;
					_approveRouter(_tokensForLP_half);
					_addLiquidity(_tokensForLP_half, _ethWeiAmount, false);

					_tax_tokens_autoLp -= _taxTokensAutoLP;
				}
			}

			uint256 _contractETHBalance = address(this).balance;			
			if (_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
		}
	}

	function getExemptions(address wallet) external view returns(bool noFees, bool noLimits) {
		return (exm_noFees[wallet], exm_noLimits[wallet]);
	}

	function setExemptions(address wallet, bool noFees, bool noLimits) external onlyOwner {
		exm_noFees[wallet] = noFees;
		exm_noLimits[wallet] = noLimits;
		emit WalletExemptionsSet(wallet, noFees, noLimits);
	}


	function getFloorInfo() external view returns(uint16 floorPercentage, uint16 floorRaiseTriggerPercent, uint256 currentFloorPriceWeiPerToken, uint256 currentTokenPriceWei, bool isPriceBelowFloor) {
		(uint256 tokensInLP, uint256 wethInLP) = getPriceInputData();
		(uint256 weiPricePerToken, ) = calculatePrices(tokensInLP, wethInLP);
        bool _isBelowFloor = weiPricePerToken < _floorPriceWei;
		return (_floorPercentOfATH, _floorATHminimalIncreasePercent, _floorPriceWei, weiPricePerToken, _isBelowFloor);
	}

	function setFloorSettings(uint16 newFloorPercentage, uint16 newFloorRaisingTrigger) external onlyOwner {
		require(newFloorPercentage>0 && newFloorPercentage<=40,"Floor percentage must be 1-40");
		_floorPriceWei * _floorPercentOfATH / newFloorPercentage;
		_floorPercentOfATH = newFloorPercentage;

		require(newFloorRaisingTrigger>0, "Cannot be 0");
		_floorATHminimalIncreasePercent = newFloorRaisingTrigger;
	}

	function getTaxRates() external view returns(uint8 taxRateMaxLimit, uint8 taxRateBuy, uint8 taxRateSell, uint8 taxRateSubFloorSell ) {
		return (fee_taxRateMaxLimit, fee_taxRateBuy, fee_taxRateSell, fee_taxRateSubFloorSell);
	}

	function setTaxRates(uint8 newBuyTax, uint8 newSellTax, uint8 newSubFloorSellTax) external onlyOwner {
		require(newBuyTax <= fee_taxRateMaxLimit && newSellTax <= fee_taxRateMaxLimit, "Tax too high");
		require(newSubFloorSellTax <= 30, "Tax too high");
		fee_taxRateBuy = newBuyTax;
		fee_taxRateSell = newSellTax;
		fee_taxRateSubFloorSell = newSubFloorSellTax;
	}

	function getWallets() external view returns(address contractOwner, address liquidityPool, address marketing, address operations) {
		return (owner, _liquidityPool, wlt_marketing, wlt_operations);
	}

	function setTaxWallets(address newMarketingWallet, address newOperationsWallet) external onlyOwner {
		wlt_marketing = payable(newMarketingWallet);
		exm_noFees[newMarketingWallet] = true;
		exm_noLimits[newMarketingWallet] = true;

		wlt_operations = payable(newOperationsWallet);
		exm_noFees[newOperationsWallet] = true;
		exm_noLimits[newOperationsWallet] = true;

		emit TaxWalletChanged(newMarketingWallet, newOperationsWallet);
	}

	function getLimits() external view returns(uint256 maxTxAmount, uint256 maxWalletAmount, uint256 taxSwapMin, uint256 taxSwapMax) {
		return (lim_maxTxAmount, lim_maxWalletAmount, lim_taxSwapMin, lim_taxSwapMax);
	}

	function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
		uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
		require(newTxAmt >= lim_maxTxAmount, "tx limit too low");
		lim_maxTxAmount = newTxAmt;
		uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
		require(newWalletAmt >= lim_maxWalletAmount, "wallet limit too low");
		lim_maxWalletAmount = newWalletAmt;
		emit LimitsIncreased(lim_maxTxAmount, lim_maxWalletAmount);
	}

	function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
		lim_taxSwapMin = _totalSupply * minValue / minDivider;
		lim_taxSwapMax = _totalSupply * maxValue / maxDivider;
		require(lim_taxSwapMax > lim_taxSwapMin);
		emit TaxSwapSettingsChanged(lim_taxSwapMin, lim_taxSwapMax);
	}

	function _swapTaxTokensForEth(uint256 _tokenAmount) private {
		_approveRouter(_tokenAmount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _wethAddress;
		_uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
	}

	function _distributeTaxEth(uint256 _amount) private {
		uint256 one_third_amount = _amount / 3;
		uint256 two_thirds_amount = one_third_amount*2;
		wlt_marketing.transfer(two_thirds_amount);
		wlt_operations.transfer(one_third_amount);
	}

	function taxManualTrigger(bool swapTaxTokens, bool retrieveTaxETH, uint8 percentTokensToSwap) external onlyOwner lockTaxSwap {
		require( swapTaxTokens || retrieveTaxETH, "No action given");
		if (swapTaxTokens) {
			require(percentTokensToSwap > 0 && percentTokensToSwap<=100, "Swap must be 1-100%");

			uint256 taxTokenBalance = balanceOf(address(this));
			require(taxTokenBalance > 0, "No tokens");
			uint256 swapAmount = (taxTokenBalance * percentTokensToSwap) / 100;
			_swapTaxTokensForEth(swapAmount);
			_tax_tokens_autoLp = 0; 
		}

		if (retrieveTaxETH) { 
			uint256 ethAmount = address(this).balance;
			_distributeTaxEth(ethAmount); 
		}
	}
}