/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

/**
GTFO.vip
*/


pragma solidity 0.8.9;

interface IUniswapV2Factory {
 function createPair(address tokenA, address tokenB) external returns(address pair);
}

interface IERC20 {

 function totalSupply() external view returns(uint256);

 function balanceOf(address account) external view returns(uint256);

 function transfer(address recipient, uint256 amount) external returns(bool);

 function allowance(address owner, address spender) external view returns(uint256);

 function approve(address spender, uint256 amount) external returns(bool);

 function transferFrom(
 address sender,
 address recipient,
 uint256 amount
 ) external returns(bool);

 event Transfer(address indexed from, address indexed to, uint256 value);

 event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
 function name() external view returns(string memory);

 function symbol() external view returns(string memory);

 function decimals() external view returns(uint8);
}

abstract contract Context {
 function _msgSender() internal view virtual returns(address) {
 return msg.sender;
 }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
 using SafeMath for uint256;

 mapping(address => uint256) private _balances;
 mapping(address => mapping(address => uint256)) private _allowances;
 uint256 private _totalSupply;
 
 string private _name;
 string private _symbol;

 constructor(string memory name_, string memory symbol_) {
 _name = name_;
 _symbol = symbol_;
 }

 function name() public view virtual override returns(string memory) {
 return _name;
 }

 function symbol() public view virtual override returns(string memory) {
 return _symbol;
 }

 function decimals() public view virtual override returns(uint8) {
 return 18;
 }

 function totalSupply() public view virtual override returns(uint256) {
 return _totalSupply;
 }

 function balanceOf(address account) public view virtual override returns(uint256) {
 return _balances[account];
 }

 function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
 _transfer(_msgSender(), recipient, amount);
 return true;
 }

 function allowance(address owner, address spender) public view virtual override returns(uint256) {
 return _allowances[owner][spender];
 }

 function approve(address spender, uint256 amount) public virtual override returns(bool) {
 _approve(_msgSender(), spender, amount);
 return true;
 }

 function transferFrom(
 address sender,
 address recipient,
 uint256 amount
 ) public virtual override returns(bool) {
 _transfer(sender, recipient, amount);
 _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
 return true;
 }

 function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
 return true;
 }

 function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased cannot be below zero"));
 return true;
 }

 function _transfer(
 address sender,
 address recipient,
 uint256 amount
 ) internal virtual {
 
 _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
 _balances[recipient] = _balances[recipient].add(amount);
 emit Transfer(sender, recipient, amount);
 }

 function _mint(address account, uint256 amount) internal virtual {
 require(account != address(0), "ERC20: mint to the zero address");

 _totalSupply = _totalSupply.add(amount);
 _balances[account] = _balances[account].add(amount);
 emit Transfer(address(0), account, amount);
 }

 function _approve(
 address owner,
 address spender,
 uint256 amount
 ) internal virtual {
 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);
 }
}
 
library SafeMath {
 
 function add(uint256 a, uint256 b) internal pure returns(uint256) {
 uint256 c = a + b;
 require(c >= a, "SafeMath: addition overflow");

 return c;
 }

 function sub(uint256 a, uint256 b) internal pure returns(uint256) {
 return sub(a, b, "SafeMath: subtraction overflow");
 }

 function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
 require(b <= a, errorMessage);
 uint256 c = a - b;

 return c;
 }

 function mul(uint256 a, uint256 b) internal pure returns(uint256) {
 
 if (a == 0) {
 return 0;
 }
 
 uint256 c = a * b;
 require(c / a == b, "SafeMath: multiplication overflow");

 return c;
 }

 function div(uint256 a, uint256 b) internal pure returns(uint256) {
 return div(a, b, "SafeMath: division by zero");
 }

 function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
 require(b > 0, errorMessage);
 uint256 c = a / b;

 return c;
 }
}
 
contract Ownable is Context {
 address private _owner;
 
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 constructor() {
 address msgSender = _msgSender();
 _owner = msgSender;
 emit OwnershipTransferred(address(0), msgSender);
 }

 function owner() public view returns(address) {
 return _owner;
 }

 modifier onlyOwner() {
 require(_owner == _msgSender(), "Ownable: caller is not the owner");
 _;
 }

 function renounceOwnership() public virtual onlyOwner {
 emit OwnershipTransferred(_owner, address(0));
 _owner = address(0);
 }

 function transferOwnership(address newOwner) public virtual onlyOwner {
 require(newOwner != address(0), "Ownable: new owner is the zero address");
 emit OwnershipTransferred(_owner, newOwner);
 _owner = newOwner;
 }
}
 
library SafeMathInt {
 int256 private constant MIN_INT256 = int256(1) << 255;
 int256 private constant MAX_INT256 = ~(int256(1) << 255);

 function mul(int256 a, int256 b) internal pure returns(int256) {
 int256 c = a * b;

 require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
 require((b == 0) || (c / b == a));
 return c;
 }

 function div(int256 a, int256 b) internal pure returns(int256) {
 require(b != -1 || a != MIN_INT256);

 return a / b;
 }

 function sub(int256 a, int256 b) internal pure returns(int256) {
 int256 c = a - b;
 require((b >= 0 && c <= a) || (b < 0 && c > a));
 return c;
 }

 function add(int256 a, int256 b) internal pure returns(int256) {
 int256 c = a + b;
 require((b >= 0 && c >= a) || (b < 0 && c < a));
 return c;
 }

 function abs(int256 a) internal pure returns(int256) {
 require(a != MIN_INT256);
 return a < 0 ? -a : a;
 }

 function toUint256Safe(int256 a) internal pure returns(uint256) {
 require(a >= 0);
 return uint256(a);
 }
}
 
library SafeMathUint {
 function toInt256Safe(uint256 a) internal pure returns(int256) {
 int256 b = int256(a);
 require(b >= 0);
 return b;
 }
}

interface IUniswapV2Router01 {
 function factory() external pure returns(address);
 function WETH() external pure returns(address);

 function addLiquidity(
 address tokenA,
 address tokenB,
 uint amountADesired,
 uint amountBDesired,
 uint amountAMin,
 uint amountBMin,
 address to,
 uint deadline
 ) external returns(uint amountA, uint amountB, uint liquidity);
 function addLiquidityETH(
 address token,
 uint amountTokenDesired,
 uint amountTokenMin,
 uint amountETHMin,
 address to,
 uint deadline
 ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
 function removeLiquidity(
 address tokenA,
 address tokenB,
 uint liquidity,
 uint amountAMin,
 uint amountBMin,
 address to,
 uint deadline
 ) external returns(uint amountA, uint amountB);
 function removeLiquidityETH(
 address token,
 uint liquidity,
 uint amountTokenMin,
 uint amountETHMin,
 address to,
 uint deadline
 ) external returns(uint amountToken, uint amountETH);
 function removeLiquidityWithPermit(
 address tokenA,
 address tokenB,
 uint liquidity,
 uint amountAMin,
 uint amountBMin,
 address to,
 uint deadline,
 bool approveMax, uint8 v, bytes32 r, bytes32 s
 ) external returns(uint amountA, uint amountB);
 function removeLiquidityETHWithPermit(
 address token,
 uint liquidity,
 uint amountTokenMin,
 uint amountETHMin,
 address to,
 uint deadline,
 bool approveMax, uint8 v, bytes32 r, bytes32 s
 ) external returns(uint amountToken, uint amountETH);
 function swapExactTokensForTokens(
 uint amountIn,
 uint amountOutMin,
 address[] calldata path,
 address to,
 uint deadline
 ) external returns(uint[] memory amounts);
 function swapTokensForExactTokens(
 uint amountOut,
 uint amountInMax,
 address[] calldata path,
 address to,
 uint deadline
 ) external returns(uint[] memory amounts);
 function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
 external
 payable
 returns(uint[] memory amounts);
 function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
 external
 returns(uint[] memory amounts);
 function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
 external
 returns(uint[] memory amounts);
 function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
 external
 payable
 returns(uint[] memory amounts);

 function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
 function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
 function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
 function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
 function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
 function removeLiquidityETHSupportingFeeOnTransferTokens(
 address token,
 uint liquidity,
 uint amountTokenMin,
 uint amountETHMin,
 address to,
 uint deadline
 ) external returns(uint amountETH);
 function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
 address token,
 uint liquidity,
 uint amountTokenMin,
 uint amountETHMin,
 address to,
 uint deadline,
 bool approveMax, uint8 v, bytes32 r, bytes32 s
 ) external returns(uint amountETH);

 function swapExactTokensForTokensSupportingFeeOnTransferTokens(
 uint amountIn,
 uint amountOutMin,
 address[] calldata path,
 address to,
 uint deadline
 ) external;
 function swapExactETHForTokensSupportingFeeOnTransferTokens(
 uint amountOutMin,
 address[] calldata path,
 address to,
 uint deadline
 ) external payable;
 function swapExactTokensForETHSupportingFeeOnTransferTokens(
 uint amountIn,
 uint amountOutMin,
 address[] calldata path,
 address to,
 uint deadline
 ) external;
}
 
contract GTFO is ERC20, Ownable {
 using SafeMath for uint256;

 IUniswapV2Router02 public immutable router;
 address public immutable uniswapV2Pair;

 // addresses
 address public devWallet;
 address private marketingWallet;

 // limits 
 uint256 private maxBuyAmount;
 uint256 private maxSellAmount; 
 uint256 private maxWalletAmount;
 
 uint256 private thresholdSwapAmount;

 // status flags
 bool private isTrading = false;
 bool public swapEnabled = false;
 bool public isSwapping;

 struct Fees {
 uint8 buyTotalFees;
 uint8 buyMarketingFee;
 uint8 buyDevFee;
 uint8 buyLiquidityFee;

 uint8 sellTotalFees;
 uint8 sellMarketingFee;
 uint8 sellDevFee;
 uint8 sellLiquidityFee;
 } 

 Fees public _fees = Fees({
 sellTotalFees: 0,
 sellMarketingFee: 0,
 sellDevFee:0,
 sellLiquidityFee: 0,

 buyTotalFees: 0,
 buyMarketingFee: 0,
 buyDevFee:0,
 buyLiquidityFee: 0
 });
 
 mapping(address => bool) private _isExcludedFromFees;
 mapping(address => bool) public _isExcludedMaxTransactionAmount;
 mapping(address => bool) public _isExcludedMaxWalletAmount;

 uint256 public tokensForMarketing;
 uint256 public tokensForLiquidity;
 uint256 public tokensForDev;
 uint256 private taxTill;

 mapping(address => bool) public marketPair;
 mapping(address => bool) public _isBlacklisted;
 
 event SwapAndLiquify(
 uint256 tokensSwapped,
 uint256 ethReceived
 );

 constructor() ERC20("GTFO", "GTFO") {
 
 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
 uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

 //Wallets
 devWallet = address(0xf1761b6FB3CC5d2a4B8406c1a0b96D98BA179157);
 marketingWallet = address(0x84d84B2A5BA6D4B60B271D417278AFE72bc18E40);

//Fees
 _fees.buyMarketingFee = 2;
 _fees.buyLiquidityFee = 2;
 _fees.buyDevFee = 0;
 _fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;

 _fees.sellMarketingFee = 2;
 _fees.sellLiquidityFee = 2;
 _fees.sellDevFee = 1 ;
 _fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;

// Lists
 _isExcludedMaxWalletAmount[owner()] = true;
 _isExcludedMaxWalletAmount[address(this)] = true;
 _isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;
 
 _isExcludedMaxTransactionAmount[address(router)] = true;
 _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true; 
 _isExcludedMaxTransactionAmount[owner()] = true;
 _isExcludedMaxTransactionAmount[address(this)] = true;

 _isExcludedFromFees[owner()] = true;
 _isExcludedFromFees[address(this)] = true;

 marketPair[address(uniswapV2Pair)] = true;
 approve(address(router), type(uint256).max);
 
 //Supply
 uint256 totalSupply = 100000000000 * 10**18;

//Limits
 maxBuyAmount = totalSupply * 5 / 100;
 maxSellAmount = totalSupply * 5 / 100;
 maxWalletAmount = totalSupply * 5 / 100;
 thresholdSwapAmount = totalSupply * 2 / 10000;

 _mint(msg.sender, totalSupply);
 }

 receive() external payable {
 }

 function swapTrading() external onlyOwner {
 isTrading = true;
 swapEnabled = true;
 taxTill = block.number + 2;
 }

 function updateThresholdSwapAmount(uint256 newAmount) external onlyOwner returns(bool){
 thresholdSwapAmount = newAmount;
 return true;
 }

 function updateMaxTxnAmount(uint256 newMaxBuy, uint256 newMaxSell) external onlyOwner {
 require(((totalSupply() * newMaxBuy) / 1000) >= (totalSupply() / 100), "maxBuyAmount must be higher than 1%");
 require(((totalSupply() * newMaxSell) / 1000) >= (totalSupply() / 100), "maxSellAmount must be higher than 1%");
 maxBuyAmount = (totalSupply() * newMaxBuy) / 1000;
 maxSellAmount = (totalSupply() * newMaxSell) / 1000;
 }

 function updateMaxWalletAmount(uint256 newPercentage) external onlyOwner {
 require(((totalSupply() * newPercentage) / 1000) >= (totalSupply() / 100), "Cannot set maxWallet lower than 1%");
 maxWalletAmount = (totalSupply() * newPercentage) / 1000;
 }

 function toggleSwapEnabled(bool enabled) external onlyOwner(){
 swapEnabled = enabled;
 }

 function blacklistAddress(address account, bool value) external onlyOwner{
 _isBlacklisted[account] = value;
 }

 function updateFees(uint8 _marketingFeeBuy, uint8 _liquidityFeeBuy,uint8 _devFeeBuy,uint8 _marketingFeeSell, uint8 _liquidityFeeSell,uint8 _devFeeSell) external onlyOwner{
 _fees.buyMarketingFee = _marketingFeeBuy;
 _fees.buyLiquidityFee = _liquidityFeeBuy;
 _fees.buyDevFee = _devFeeBuy;
 _fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;

 _fees.sellMarketingFee = _marketingFeeSell;
 _fees.sellLiquidityFee = _liquidityFeeSell;
 _fees.sellDevFee = _devFeeSell;
 _fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;
 require(_fees.buyTotalFees <= 40, "Must keep fees at 40% or less"); 
 require(_fees.sellTotalFees <= 40, "Must keep fees at 40% or less");
 
 }
 
 function excludeFromFees(address account, bool excluded) public onlyOwner {
 _isExcludedFromFees[account] = excluded;
 }
 function excludeFromWalletLimit(address account, bool excluded) public onlyOwner {
 _isExcludedMaxWalletAmount[account] = excluded;
 }
 function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
 _isExcludedMaxTransactionAmount[updAds] = isEx;
 }

 function setMarketPair(address pair, bool value) public onlyOwner {
 require(pair != uniswapV2Pair, "Must keep uniswapV2Pair");
 marketPair[pair] = value;
 }

 function setWallets(address _marketingWallet,address _devWallet) external onlyOwner{
 marketingWallet = _marketingWallet;
 devWallet = _devWallet;
 }

 function isExcludedFromFees(address account) public view returns(bool) {
 return _isExcludedFromFees[account];
 }

 function _transfer(
 address sender,
 address recipient,
 uint256 amount
 
 ) internal override {
 
 if (amount == 0) {
 super._transfer(sender, recipient, 0);
 return;
 }

 if (
 sender != owner() &&
 recipient != owner() &&
 !isSwapping
 ) {

 if (!isTrading) {
 require(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "Trading is not active.");
 }
 if (marketPair[sender] && !_isExcludedMaxTransactionAmount[recipient]) {
 require(amount <= maxBuyAmount, "buy transfer over max amount");
 } 
 else if (marketPair[recipient] && !_isExcludedMaxTransactionAmount[sender]) {
 require(amount <= maxSellAmount, "Sell transfer over max amount");
 }

 if (!_isExcludedMaxWalletAmount[recipient]) {
 require(amount + balanceOf(recipient) <= maxWalletAmount, "Max wallet exceeded");
 }
 require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "Blacklisted address");
 }
 
 uint256 contractTokenBalance = balanceOf(address(this));
 
 bool canSwap = contractTokenBalance >= thresholdSwapAmount;

 if (
 canSwap &&
 swapEnabled &&
 !isSwapping &&
 marketPair[recipient] &&
 !_isExcludedFromFees[sender] &&
 !_isExcludedFromFees[recipient]
 ) {
 isSwapping = true;
 swapBack();
 isSwapping = false;
 }
 
 bool takeFee = !isSwapping;

 if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
 takeFee = false;
 }
 
 if (takeFee) {
 uint256 fees = 0;
 if(block.number < taxTill) {
 fees = amount.mul(99).div(100);
 tokensForMarketing += (fees * 94) / 99;
 tokensForDev += (fees * 5) / 99;
 } else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
 fees = amount.mul(_fees.sellTotalFees).div(100);
 tokensForLiquidity += fees * _fees.sellLiquidityFee / _fees.sellTotalFees;
 tokensForMarketing += fees * _fees.sellMarketingFee / _fees.sellTotalFees;
 tokensForDev += fees * _fees.sellDevFee / _fees.sellTotalFees;
 }
 // on buy
 else if (marketPair[sender] && _fees.buyTotalFees > 0) {
 fees = amount.mul(_fees.buyTotalFees).div(100);
 tokensForLiquidity += fees * _fees.buyLiquidityFee / _fees.buyTotalFees;
 tokensForMarketing += fees * _fees.buyMarketingFee / _fees.buyTotalFees;
 tokensForDev += fees * _fees.buyDevFee / _fees.buyTotalFees;
 }

 if (fees > 0) {
 super._transfer(sender, address(this), fees);
 }

 amount -= fees;

 }

 super._transfer(sender, recipient, amount);
 }

 function swapTokensForEth(uint256 tAmount) private {

 address[] memory path = new address[](2);
 path[0] = address(this);
 path[1] = router.WETH();

 _approve(address(this), address(router), tAmount);

 router.swapExactTokensForETHSupportingFeeOnTransferTokens(
 tAmount,
 0, // accept any amount of ETH!
 path,
 address(this),
 block.timestamp
 );
 }

 function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
 _approve(address(this), address(router), tAmount);

 router.addLiquidityETH{ value: ethAmount } (address(this), tAmount, 0, 0 , address(this), block.timestamp);
 }

 function swapBack() private {
 uint256 contractTokenBalance = balanceOf(address(this));
 uint256 toSwap = tokensForLiquidity + tokensForMarketing + tokensForDev;
 bool success;

 if (contractTokenBalance == 0 || toSwap == 0) { return; }

 if (contractTokenBalance > thresholdSwapAmount * 20) {
 contractTokenBalance = thresholdSwapAmount * 20;
 }

 uint256 liquidityTokens = contractTokenBalance * tokensForLiquidity / toSwap / 2;
 uint256 amountToSwapForETH = contractTokenBalance.sub(liquidityTokens);
 
 uint256 initialETHBalance = address(this).balance;

 swapTokensForEth(amountToSwapForETH); 
 
 uint256 newBalance = address(this).balance.sub(initialETHBalance);
 
 uint256 ethForMarketing = newBalance.mul(tokensForMarketing).div(toSwap);
 uint256 ethForDev = newBalance.mul(tokensForDev).div(toSwap);
 uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForDev);

 tokensForLiquidity = 0;
 tokensForMarketing = 0;
 tokensForDev = 0;

 if (liquidityTokens > 0 && ethForLiquidity > 0) {
 addLiquidity(liquidityTokens, ethForLiquidity);
 emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
 }

 (success,) = address(devWallet).call{ value: (address(this).balance - ethForMarketing) } ("");
 (success,) = address(marketingWallet).call{ value: address(this).balance } ("");
 }

}