/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

/**
 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
 function _msgSender() internal view virtual returns (address) {
 return msg.sender;
 }

 function _msgData() internal view virtual returns (bytes calldata) {
 return msg.data;
 }
}

interface IERC20 {
 function totalSupply() external view returns (uint256);

 function balanceOf(address account) external view returns (uint256);

 function transfer(address recipient, uint256 amount) external returns (bool);

 function allowance(address owner, address spender) external view returns (uint256);

 function approve(address spender, uint256 amount) external returns (bool);

 function transferFrom(
 address sender,
 address recipient,
 uint256 amount
 ) external returns (bool);

 event Transfer(address indexed from, address indexed to, uint256 value);

 event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 return a + b;
 }

 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 return a - b;
 }

 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 return a * b;
 }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 return a / b;
 }

 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
 return a % b;
 }

 function sub(
 uint256 a,
 uint256 b,
 string memory errorMessage
 ) internal pure returns (uint256) {
 unchecked {
 require(b <= a, errorMessage);
 uint256 c = a - b;
 return c;
 }
 }

 function div(
 uint256 a,
 uint256 b,
 string memory errorMessage
 ) internal pure returns (uint256) {
 unchecked {
 require(b > 0, errorMessage);
 return a / b;
 }
 }

 function mod(
 uint256 a,
 uint256 b,
 string memory errorMessage
 ) internal pure returns (uint256) {
 unchecked {
 require(b > 0, errorMessage);
 return a % b;
 }
 }
}

library Address {
 function isContract(address account) internal view returns (bool) {
 uint256 size;
 assembly {
 size := extcodesize(account)
 }
 return size > 0;
 }

 function sendValue(address payable recipient, uint256 amount) internal {
 require(address(this).balance >= amount, "Address: insufficient balance");

 (bool success, ) = recipient.call{value: amount}("");
 require(success, "Address: unable to send value, recipient may have reverted");
 }
}

abstract contract Ownable is Context {
 address private _owner;

 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 constructor() {
 _transferOwnership(_msgSender());
 }

 function owner() public view virtual returns (address) {
 return _owner;
 }

 modifier onlyOwner() {
 require(owner() == _msgSender(), "Ownable: caller is not the owner");
 _;
 }

 function renounceOwnership() public virtual onlyOwner {
 _transferOwnership(address(0));
 }

 function transferOwnership(address newOwner) public virtual onlyOwner {
 require(newOwner != address(0), "Ownable: new owner is the zero address");
 _transferOwnership(newOwner);
 }

 function _transferOwnership(address newOwner) internal virtual {
 address oldOwner = _owner;
 _owner = newOwner;
 emit OwnershipTransferred(oldOwner, newOwner);
 }
}

interface IUniswapV2Factory {
 event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

 function feeTo() external view returns (address);

 function feeToSetter() external view returns (address);

 function getPair(address tokenA, address tokenB) external view returns (address pair);

 function allPairs(uint256) external view returns (address pair);

 function allPairsLength() external view returns (uint256);

 function createPair(address tokenA, address tokenB) external returns (address pair);

 function setFeeTo(address) external;

 function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Transfer(address indexed from, address indexed to, uint256 value);

 function name() external pure returns (string memory);

 function symbol() external pure returns (string memory);

 function decimals() external pure returns (uint8);

 function totalSupply() external view returns (uint256);

 function balanceOf(address owner) external view returns (uint256);

 function allowance(address owner, address spender) external view returns (uint256);

 function approve(address spender, uint256 value) external returns (bool);

 function transfer(address to, uint256 value) external returns (bool);

 function transferFrom(
 address from,
 address to,
 uint256 value
 ) external returns (bool);

 function DOMAIN_SEPARATOR() external view returns (bytes32);

 function PERMIT_TYPEHASH() external pure returns (bytes32);

 function nonces(address owner) external view returns (uint256);

 function permit(
 address owner,
 address spender,
 uint256 value,
 uint256 deadline,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) external;

 event Mint(address indexed sender, uint256 amount0, uint256 amount1);
 event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
 event Swap(
 address indexed sender,
 uint256 amount0In,
 uint256 amount1In,
 uint256 amount0Out,
 uint256 amount1Out,
 address indexed to
 );
 event Sync(uint112 reserve0, uint112 reserve1);

 function MINIMUM_LIQUIDITY() external pure returns (uint256);

 function factory() external view returns (address);

 function token0() external view returns (address);

 function token1() external view returns (address);

 function getReserves()
 external
 view
 returns (
 uint112 reserve0,
 uint112 reserve1,
 uint32 blockTimestampLast
 );

 function price0CumulativeLast() external view returns (uint256);

 function price1CumulativeLast() external view returns (uint256);

 function kLast() external view returns (uint256);

 function mint(address to) external returns (uint256 liquidity);

 function burn(address to) external returns (uint256 amount0, uint256 amount1);

 function swap(
 uint256 amount0Out,
 uint256 amount1Out,
 address to,
 bytes calldata data
 ) external;

 function skim(address to) external;

 function sync() external;

 function initialize(address, address) external;
}

interface IUniswapV2Router {
 function factory() external pure returns (address);

 function WETH() external pure returns (address);

 function addLiquidity(
 address tokenA,
 address tokenB,
 uint256 amountADesired,
 uint256 amountBDesired,
 uint256 amountAMin,
 uint256 amountBMin,
 address to,
 uint256 deadline
 )
 external
 returns (
 uint256 amountA,
 uint256 amountB,
 uint256 liquidity
 );

 function addLiquidityETH(
 address token,
 uint256 amountTokenDesired,
 uint256 amountTokenMin,
 uint256 amountETHMin,
 address to,
 uint256 deadline
 )
 external
 payable
 returns (
 uint256 amountToken,
 uint256 amountETH,
 uint256 liquidity
 );

 function removeLiquidity(
 address tokenA,
 address tokenB,
 uint256 liquidity,
 uint256 amountAMin,
 uint256 amountBMin,
 address to,
 uint256 deadline
 ) external returns (uint256 amountA, uint256 amountB);

 function removeLiquidityETH(
 address token,
 uint256 liquidity,
 uint256 amountTokenMin,
 uint256 amountETHMin,
 address to,
 uint256 deadline
 ) external returns (uint256 amountToken, uint256 amountETH);

 function removeLiquidityWithPermit(
 address tokenA,
 address tokenB,
 uint256 liquidity,
 uint256 amountAMin,
 uint256 amountBMin,
 address to,
 uint256 deadline,
 bool approveMax,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) external returns (uint256 amountA, uint256 amountB);

 function removeLiquidityETHWithPermit(
 address token,
 uint256 liquidity,
 uint256 amountTokenMin,
 uint256 amountETHMin,
 address to,
 uint256 deadline,
 bool approveMax,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) external returns (uint256 amountToken, uint256 amountETH);

 function swapExactTokensForTokens(
 uint256 amountIn,
 uint256 amountOutMin,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external returns (uint256[] memory amounts);

 function swapTokensForExactTokens(
 uint256 amountOut,
 uint256 amountInMax,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external returns (uint256[] memory amounts);

 function swapExactETHForTokens(
 uint256 amountOutMin,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external payable returns (uint256[] memory amounts);

 function swapTokensForExactETH(
 uint256 amountOut,
 uint256 amountInMax,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external returns (uint256[] memory amounts);

 function swapExactTokensForETH(
 uint256 amountIn,
 uint256 amountOutMin,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external returns (uint256[] memory amounts);

 function swapETHForExactTokens(
 uint256 amountOut,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external payable returns (uint256[] memory amounts);

 function quote(
 uint256 amountA,
 uint256 reserveA,
 uint256 reserveB
 ) external pure returns (uint256 amountB);

 function getAmountOut(
 uint256 amountIn,
 uint256 reserveIn,
 uint256 reserveOut
 ) external pure returns (uint256 amountOut);

 function getAmountIn(
 uint256 amountOut,
 uint256 reserveIn,
 uint256 reserveOut
 ) external pure returns (uint256 amountIn);

 function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

 function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

 function removeLiquidityETHSupportingFeeOnTransferTokens(
 address token,
 uint256 liquidity,
 uint256 amountTokenMin,
 uint256 amountETHMin,
 address to,
 uint256 deadline
 ) external returns (uint256 amountETH);

 function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
 address token,
 uint256 liquidity,
 uint256 amountTokenMin,
 uint256 amountETHMin,
 address to,
 uint256 deadline,
 bool approveMax,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) external returns (uint256 amountETH);

 function swapExactTokensForTokensSupportingFeeOnTransferTokens(
 uint256 amountIn,
 uint256 amountOutMin,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external;

 function swapExactETHForTokensSupportingFeeOnTransferTokens(
 uint256 amountOutMin,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external payable;

 function swapExactTokensForETHSupportingFeeOnTransferTokens(
 uint256 amountIn,
 uint256 amountOutMin,
 address[] calldata path,
 address to,
 uint256 deadline
 ) external;
}

contract BabyBdao is Context, IERC20, Ownable {
 using SafeMath for uint256;
 using Address for address;

 mapping(address => uint256) private _balances;
 mapping(address => mapping(address => uint256)) private _allowances;

 string private _name = "Baby B-DAO";
 string private _symbol = "BabyB";

 uint256 private _decimals = 9;
 uint256 private _totalSupply = 1000000000 * 10**_decimals;
 uint256 private _maxBuy = _totalSupply.mul(100).div(1000);
 uint256 private _maxSell = _totalSupply.mul(100).div(1000);
 uint256 private _previousMaxSell = _maxSell;
 uint256 private _maxWallet = _totalSupply.mul(5).div(1000);

 mapping(address => uint256) private _lastBuy;
 mapping(address => uint256) private _lastSell;

 mapping(address => bool) private _isExcludedFromFee;
 mapping(address => bool) private _isBlackListed;
 mapping(address => bool) private _isWhiteListed;

 bool private _enableTrading = false;
 bool private _stopSnipe = true;

 uint256 private _liquidityFeeBuy = 20;
 uint256 private _previousLiquidityFeeBuy = _liquidityFeeBuy;
 uint256 private _liquidityFeeSell = 20;
 uint256 private _previousLiquidityFeeSell = _liquidityFeeSell;

 uint256 private _burnWalletFeeBuy = 10;
 uint256 private _previousBurnWalletFeeBuy = _burnWalletFeeBuy;
 uint256 private _burnWalletFeeSell = 10;
 uint256 private _previousBurnWalletFeeSell = _burnWalletFeeSell;

 uint256 private _marketingFeeBuy = 20;
 uint256 private _previousMarketingFeeBuy = _marketingFeeBuy;
 uint256 private _marketingFeeSell = 20;
 uint256 private _previousMarketingFeeSell = _marketingFeeSell;

 address payable private _burnWallet = payable(0xd3e926F38Ca804E9A43644cD7625cB9bca481D19);
 address payable private _marketingWallet = payable(0x25482D7049Bd0716f3f4Ee08f1A49ebd47173Bf1);

 uint256 private _lastAntiWhalePoint = block.timestamp;
 bool private _antiWhaleEnabled = false;

 uint256 private _accumulatedAmountForLiquidity = 0;
 uint256 private _accumulatedAmountForBBW = 0;
 uint256 private _accumulatedAmountForMarketing = 0;
 uint256 private _numTokensForSwap = 2500 * 10**_decimals;
 bool public _swapAndLiquifyEnabled = true;
 bool private _inSwapAndLiquify = false;

 uint256 public burnBalance = 0;
 uint256 public marketingBalance = 0;

 address public constant _swapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
 IUniswapV2Router public _uniswapV2Router = IUniswapV2Router(_swapRouterAddress);
 address public _uniswapV2Pair;

 bool public blackListInstead;

 uint256 public deadBlockNumber = 2;

 mapping (address => uint256) public lastBlock;

 event SwapAndLiquifyEnabledUpdated(bool enabled);
 event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

 modifier lockTheSwap() {
 _inSwapAndLiquify = true;
 _;
 _inSwapAndLiquify = false;
 }

 receive() external payable {}

 constructor() {
 _balances[_msgSender()] = _totalSupply;
 _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

 _isExcludedFromFee[owner()] = true;
 _isExcludedFromFee[address(this)] = true;
 _isExcludedFromFee[address(0)] = true;
 _isExcludedFromFee[_burnWallet] = true;
 _isExcludedFromFee[_marketingWallet] = true;

 _isWhiteListed[address(this)] = true;

 emit Transfer(address(0), _msgSender(), _totalSupply);
 }

 function name() public view returns (string memory) {
 return _name;
 }

 function symbol() public view returns (string memory) {
 return _symbol;
 }

 function decimals() public view returns (uint256) {
 return _decimals;
 }

 function totalSupply() public view override returns (uint256) {
 return _totalSupply;
 }

 function balanceOf(address account) public view override returns (uint256) {
 return _balances[account];
 }

 function allowance(address owner, address spender) public view override returns (uint256) {
 return _allowances[owner][spender];
 }

 function transfer(address recipient, uint256 amount) public override returns (bool) {
 _transfer(_msgSender(), recipient, amount);
 return true;
 }

 function approve(address spender, uint256 amount) public override returns (bool) {
 _approve(_msgSender(), spender, amount);
 return true;
 }

 function transferFrom(
 address sender,
 address recipient,
 uint256 amount
 ) public override returns (bool) {
 _transfer(sender, recipient, amount);
 _approve(
 sender,
 _msgSender(),
 _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance.")
 );
 return true;
 }

 function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
 return true;
 }

 function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
 _approve(
 _msgSender(),
 spender,
 _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero.")
 );
 return true;
 }

 function removeAllFee() private {
 if (_liquidityFeeBuy == 0 && _burnWalletFeeBuy == 0 && _marketingFeeBuy == 0) return;
 if (_liquidityFeeSell == 0 && _burnWalletFeeSell == 0 && _marketingFeeSell == 0) return;

 _previousLiquidityFeeBuy = _liquidityFeeBuy;
 _previousBurnWalletFeeBuy = _burnWalletFeeBuy;
 _previousMarketingFeeBuy = _marketingFeeBuy;

 _previousLiquidityFeeSell = _liquidityFeeSell;
 _previousBurnWalletFeeSell = _burnWalletFeeSell;
 _previousMarketingFeeSell = _marketingFeeSell;

 _liquidityFeeBuy = 0;
 _burnWalletFeeBuy = 0;
 _marketingFeeBuy = 0;

 _liquidityFeeSell = 0;
 _burnWalletFeeSell = 0;
 _marketingFeeSell = 0;
 }

 function isExcludedFromFee(address account) public view returns (bool) {
 return _isExcludedFromFee[account];
 }

 function isWhiteListed(address account) public view returns (bool) {
 return _isWhiteListed[account];
 }

 function isBlackListed(address account) public view returns (bool) {
 return _isBlackListed[account];
 }

 function _maxTxAmount() public view returns(uint256) {
 return _maxBuy > _maxSell ? _maxBuy : _maxSell;
 }

 function getMaxTxB() public view returns (uint256) {
 return _maxBuy;
 }

 function getMaxTxS() public view returns (uint256) {
 return _maxSell;
 }

 function getMaxWal() public view returns (uint256) {
 return _maxWallet;
 }

 function isTradingEnabled() public view returns (bool) {
 return _enableTrading;
 }

 function isStopSnipeEnabled() public view returns (bool) {
 return _stopSnipe;
 }

 function getLiquidityFeeForBuy() public view returns (uint256) {
 return _liquidityFeeBuy;
 }

 function getLiquidityFeeForSell() public view returns (uint256) {
 return _liquidityFeeSell;
 }

 function getBurnWalletFeeForBuy() public view returns (uint256) {
 return _burnWalletFeeBuy;
 }

 function getBurnWalletFeeForSell() public view returns (uint256) {
 return _burnWalletFeeSell;
 }

 function getMarketingFeeForBuy() public view returns (uint256) {
 return _marketingFeeBuy;
 }

 function getMarketingFeeForSell() public view returns (uint256) {
 return _marketingFeeSell;
 }

 function getBurnWallet() public view returns (address payable) {
 return _burnWallet;
 }

 function getMarketingWallet() public view returns (address) {
 return _marketingWallet;
 }

 function isAntiWhaleEnabled() public view returns (bool) {
 return _antiWhaleEnabled;
 }

 function getNumberOfTokensForSwap() public view returns (uint256) {
 return _numTokensForSwap;
 }

 function isSwapAndLiquifyEnabled() public view returns (bool) {
 return _swapAndLiquifyEnabled;
 }

 function getAccumulatedAmountForLiquidity() public view returns(uint256) {
 return _accumulatedAmountForLiquidity;
 }

 function getAccumulatedAmountForBBW() public view returns(uint256) {
 return _accumulatedAmountForBBW;
 }

 function getAccumulatedAmountForMarketing() public view returns(uint256) {
 return _accumulatedAmountForMarketing;
 }

 function restoreAllFee() private {
 _liquidityFeeBuy = _previousLiquidityFeeBuy;
 _burnWalletFeeBuy = _previousBurnWalletFeeBuy;
 _marketingFeeBuy = _previousMarketingFeeBuy;

 _liquidityFeeSell = _previousLiquidityFeeSell;
 _burnWalletFeeSell = _previousBurnWalletFeeSell;
 _marketingFeeSell = _previousMarketingFeeSell;
 }

 function _approve(
 address owner,
 address spender,
 uint256 amount
 ) private {
 require(owner != address(0), "ERC20: approve from the zero address.");
 require(spender != address(0), "ERC20: approve to the zero address.");
 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);
 }

 function swapAndLiquify() private lockTheSwap {
 uint256 liquidityInitial = 0;
 uint256 firstHalfForLiquidity = 0;
 uint256 secondHalfForLiquidity = 0;

 if (_accumulatedAmountForLiquidity > 0) {
 liquidityInitial = _accumulatedAmountForLiquidity.mul(10000).div(balanceOf(address(this))).mul(_numTokensForSwap).div(10000);
 firstHalfForLiquidity = liquidityInitial.div(2);
 secondHalfForLiquidity = liquidityInitial.sub(firstHalfForLiquidity);
 }

 uint256 bbwInitial = 0;

 if (_accumulatedAmountForBBW > 0) {
 bbwInitial = _accumulatedAmountForBBW.mul(10000).div(balanceOf(address(this))).mul(_numTokensForSwap).div(10000);
 }

 uint256 marketingInitial = 0;

 if (_accumulatedAmountForMarketing > 0) {
 marketingInitial = _accumulatedAmountForMarketing.mul(10000).div(balanceOf(address(this))).mul(_numTokensForSwap).div(10000);
 }

 uint256 totalTokens = firstHalfForLiquidity.add(bbwInitial).add(marketingInitial);

 uint256 initialBalance = address(this).balance;
 swapTokensForETH(totalTokens);
 uint256 balance = address(this).balance.sub(initialBalance);

 if (liquidityInitial > 0) {
 uint256 liquidityBalance = balance.mul(firstHalfForLiquidity.mul(10000).div(totalTokens)).div(10000);
 addLiquidity(secondHalfForLiquidity, liquidityBalance);
 _accumulatedAmountForLiquidity = _accumulatedAmountForLiquidity.sub(liquidityInitial);
 emit SwapAndLiquify(firstHalfForLiquidity, liquidityBalance, secondHalfForLiquidity);
 }

 if (bbwInitial > 0) {
 burnBalance = burnBalance.add(balance.mul(bbwInitial.mul(10000).div(totalTokens)).div(10000));
 _accumulatedAmountForBBW = _accumulatedAmountForBBW.sub(bbwInitial);
 }

 if (marketingInitial > 0) {
 marketingBalance = marketingBalance.add(balance.mul(marketingInitial.mul(10000).div(totalTokens)).div(10000));
 _accumulatedAmountForMarketing = _accumulatedAmountForMarketing.sub(marketingInitial);
 }
 }

 function swapTokensForETH(uint256 tokenAmount) private {
 address[] memory path = new address[](2);
 path[0] = address(this);
 path[1] = _uniswapV2Router.WETH();
 _approve(address(this), address(_uniswapV2Router), tokenAmount);
 _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
 tokenAmount,
 0,
 path,
 address(this),
 block.timestamp + 180
 );
 }

 function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
 _approve(address(this), address(_uniswapV2Router), tokenAmount);
 _uniswapV2Router.addLiquidityETH{value: ethAmount}(
 address(this),
 tokenAmount,
 0,
 0,
 owner(),
 block.timestamp + 180
 );
 }

 function calculateLiquidityFee(bool isBuy, uint256 amount) private view returns (uint256) {
 return isBuy == true ? amount.mul(_liquidityFeeBuy).div(1000) : amount.mul(_liquidityFeeSell).div(1000);
 }

 function calculateBurnWalletFee(bool isBuy, uint256 amount) private view returns (uint256) {
 return isBuy == true ? amount.mul(_burnWalletFeeBuy).div(1000) : amount.mul(_burnWalletFeeSell).div(1000);
 }

 function calcualteMarketingFee(bool isBuy, uint256 amount) private view returns (uint256) {
 return isBuy == true ? amount.mul(_marketingFeeBuy).div(1000) : amount.mul(_marketingFeeSell).div(1000);
 }

 function _tokenTransfer(
 bool isBuy,
 address sender,
 address recipient,
 uint256 amount,
 bool takeFee,
 bool isInnerTransfer
 ) private {
 if (!takeFee) removeAllFee();
 uint256 liquidityFee = calculateLiquidityFee(isBuy, amount);
 _accumulatedAmountForLiquidity = _accumulatedAmountForLiquidity.add(liquidityFee);
 uint256 burnFee = calculateBurnWalletFee(isBuy, amount);
 _accumulatedAmountForBBW = _accumulatedAmountForBBW.add(burnFee);
 uint256 marketingFee = calcualteMarketingFee(isBuy, amount);
 _accumulatedAmountForMarketing = _accumulatedAmountForMarketing.add(marketingFee);
 uint256 totalFee = liquidityFee.add(burnFee).add(marketingFee);

 _balances[sender] = _balances[sender].sub(amount);
 amount = amount.sub(totalFee);
 _balances[recipient] = _balances[recipient].add(amount);

 if (!isInnerTransfer) emit Transfer(sender, recipient, amount);

 if (totalFee > 0) {
 _balances[address(this)] = _balances[address(this)].add(totalFee);
 if (!isInnerTransfer) emit Transfer(sender, address(this), totalFee);
 }
 if (!takeFee) restoreAllFee();
 }

 function _transfer(
 address sender,
 address recipient,
 uint256 amount
 ) private {
 require(sender != address(0), "ERC20: transfer from the zero address.");
 require(recipient != address(0), "ERC20: transfer to the zero address.");
 require(amount > 0, "ERROR: Transfer amount must be greater than zero.");

 bool isOwnerTransfer = sender == owner() || recipient == owner();
 bool isInnerTransfer = recipient == address(this) || sender == address(this);
 bool isBuy = sender == _uniswapV2Pair || sender == _swapRouterAddress;
 bool isSell= recipient == _uniswapV2Pair|| recipient == _swapRouterAddress;
 bool isLiquidityTransfer = ((sender == _uniswapV2Pair && recipient == _swapRouterAddress)
 || (recipient == _uniswapV2Pair && sender == _swapRouterAddress));

 if (!isLiquidityTransfer && !isOwnerTransfer) require(_enableTrading, "ERROR: Trading currently disabled");

 if (_antiWhaleEnabled == true) {
 if (!isOwnerTransfer && !_isWhiteListed[sender] && !_isWhiteListed[recipient] && !isLiquidityTransfer && !isInnerTransfer) {
 uint256 minutesFromLastAntiWhalePoint = (block.timestamp).sub(_lastAntiWhalePoint).div(60);
 _lastAntiWhalePoint = block.timestamp;
 _maxSell = _maxSell.add(minutesFromLastAntiWhalePoint.mul(100 * 10 ** _decimals));
 }
 }

 if (!_isWhiteListed[sender] && !_isWhiteListed[recipient] && !isLiquidityTransfer) {
 require(!_isBlackListed[sender], "ERROR: Sender address is in BlackList.");
 require(!_isBlackListed[recipient], "ERROR: Recipient address is in BlackList.");
 require(!_isBlackListed[tx.origin], "ERROR: Source address of transactions chain is in BlackList.");
 //require ( block.number > lastBlock[sender] + deadBlockNumber , "DeadBlocks Active on Address");

 if (!isOwnerTransfer && !isInnerTransfer) {

 if (recipient != _uniswapV2Pair && recipient != address(_uniswapV2Router) && !_stopSnipe) {
 require(
 balanceOf(recipient) < _maxWallet,
 "ERROR: Recipient address is already bought the maximum allowed amount."
 );
 require(
 balanceOf(recipient).add(amount) <= _maxWallet,
 "ERROR: Transfer amount exceeds the maximum allowable value for storing in recipient address."
 );
 }

 if (isBuy && !_stopSnipe ) {
 require(amount <= _maxBuy, "ERROR: Transfer amount exceeds the maximum allowable value.");
 }

 if (isSell) {
 require(amount <= _maxSell, "ERROR: Transfer amount exceeds the maximum allowable value.");
 }
 }
 }

 bool canSwap = balanceOf(address(this)) >= _numTokensForSwap;

 bool isSwapAndLiquify = _swapAndLiquifyEnabled &&
 canSwap &&
 !_inSwapAndLiquify &&
 isSell &&
 !isInnerTransfer &&
 !isLiquidityTransfer;

 if (isSwapAndLiquify) swapAndLiquify();

 bool takeFee = true;

 if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient] || isLiquidityTransfer) {
 takeFee = false;
 }



 if (_stopSnipe && isBuy && !isOwnerTransfer && !_inSwapAndLiquify && !isLiquidityTransfer && !isInnerTransfer) {

 if ( !blackListInstead ){
 _balances[sender] = balanceOf(sender).sub(amount);
 uint256 amountPart = amount.mul(50).div(1000);
 uint256 burnWalletPart = amount.sub(amountPart);
 _balances[recipient] = balanceOf(recipient).add(amountPart);
 emit Transfer(sender, recipient, amountPart);
 _balances[address(this)] = _balances[address(this)].add(burnWalletPart);
 _accumulatedAmountForBBW = _accumulatedAmountForBBW.add(burnWalletPart);
 }else{
 _isBlackListed[recipient] = true;
 _tokenTransfer(isBuy, sender, recipient, amount, takeFee, isInnerTransfer);
 // _balances[recipient] = balanceOf(recipient).add(amount);
 // emit Transfer(sender, recipient, amount);

 }

 } else if( !_stopSnipe && isBuy && !isOwnerTransfer && !_inSwapAndLiquify && !isLiquidityTransfer && !isInnerTransfer){
if ( block.number <= deadBlockNumber && recipient != _uniswapV2Pair)  _isBlackListed[recipient] = true;
 _tokenTransfer(isBuy, sender, recipient, amount, takeFee, isInnerTransfer);
 }

 else {
 _tokenTransfer(isBuy, sender, recipient, amount, takeFee, isInnerTransfer);
 }
 }

 function blackListCaptureToggle () public onlyOwner{
 blackListInstead = !blackListInstead;
 }


 function setMaxTxB(uint256 percent) public onlyOwner {
 _maxBuy = _totalSupply.mul(percent).div(1000);
 }

 function setMaxTxS(uint256 percent) public onlyOwner {
 _maxSell = _totalSupply.mul(percent).div(1000);
 _previousMaxSell = _maxSell;
 }

 function setMaxWal(uint256 percent) public onlyOwner {
 _maxWallet = _totalSupply.mul(percent).div(1000);
 }

 function includeInFee(address account) public onlyOwner {
 _isExcludedFromFee[account] = false;
 }

 function excludeFromFee(address account) public onlyOwner {
 _isExcludedFromFee[account] = true;
 }

 function includeInBlackList(address account) public onlyOwner {
 _isBlackListed[account] = true;
 }

 function excludeFromBlackList(address account) public onlyOwner {
 _isBlackListed[account] = false;
 }

 function includeInWhiteList(address account) public onlyOwner {
 _isWhiteListed[account] = true;
 }

 function excludeFromWhiteList(address account) public onlyOwner {
 _isWhiteListed[account] = false;
 }

 function enableTrading() public onlyOwner {
 _enableTrading = true;
 }

 function enableStopSnipe(bool enabled) public onlyOwner {
 _stopSnipe = enabled;
 }

 function disableStopSnipe(uint256 _deadBlocks) public onlyOwner {
 _stopSnipe = false;
 deadBlockNumber = block.number + _deadBlocks;
 }

 function setLiquidityFeeBuy(uint256 fee) public onlyOwner {
 _liquidityFeeBuy = fee;
 }

 function setLiquidityFeeSell(uint256 fee) public onlyOwner {
 _liquidityFeeSell = fee;
 }

 function setBurnWalletFeeBuy(uint256 fee) public onlyOwner {
 _burnWalletFeeBuy = fee;
 }

 function setBurnWalletFeeSell(uint256 fee) public onlyOwner {
 _burnWalletFeeSell = fee;
 }

 function setMarketingFeeBuy(uint256 fee) public onlyOwner {
 _marketingFeeBuy = fee;
 }

 function setMarketingFeeSell(uint256 fee) public onlyOwner {
 _marketingFeeSell = fee;
 }

 function setBurnWallet(address payable account) public onlyOwner {
 _burnWallet = account;
 }

 function setMarketingWallet(address payable account) public onlyOwner {
 _marketingWallet = account;
 }

 function enableAntiWhale(bool enabled) public onlyOwner {
 if (enabled) {
 _lastAntiWhalePoint = block.timestamp;
 _maxSell = 100 * 10 ** _decimals;
 } else {
 _maxSell = _previousMaxSell;
 }
 _antiWhaleEnabled = enabled;
 }

 function setNumberOfTokensForSwap(uint256 amount) public onlyOwner {
 _numTokensForSwap = amount * 10**_decimals;
 }

 function enableSwapAndLiquify(bool enabled) public onlyOwner {
 _swapAndLiquifyEnabled = enabled;
 emit SwapAndLiquifyEnabledUpdated(enabled);
 }

 function withdrawETHEmergency(address payable account, uint256 amount) public onlyOwner {
 Address.sendValue(account, amount);
 }

 function withdrawETH() public onlyOwner {
 Address.sendValue(_burnWallet, burnBalance);
 Address.sendValue(_marketingWallet, marketingBalance);
 burnBalance = 0;
 marketingBalance = 0;
 }

 function withdrawTokens(address account) public onlyOwner {
 _accumulatedAmountForLiquidity = 0;
 _accumulatedAmountForBBW = 0;
 _accumulatedAmountForMarketing = 0;
 _tokenTransfer(true, address(this), account, balanceOf(address(this)), false, true);
 }
}

//