/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-30
*/

/** 
Token Name: Kroco
Symbol: Kroc
Decimals: 8
Total Supply: 100 Billion
Blockchain: BNB Chain

Tokenomics:
7% Buy Tax
2% Reflection to Holders (Kroc) | 3% Marketing | 2% Liquidity pool

8% Sell Tax
2% Reflection to Holders (Kroc) | 4% Marketing & Development | 2% Liquidity pool
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; 
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;
  address private _multiSig;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(
      _owner == _msgSender() || _multiSig == _msgSender(),
      'Ownable: caller is not the owner'
    );
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function setMultisigOwnership(address newMultisig) public virtual onlyOwner {
    require(
      newMultisig != address(0),
      "Ownable: can't add the 0 address as a multisig component!"
    );
    _multiSig = newMultisig;
  }

  function getMultisigAddress() public view returns (address) {

    return _multiSig;
  }


  function geUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  function unlock() public virtual {
    require(
      _previousOwner == msg.sender,
      "You don't have permission to unlock"
    );
    require(block.timestamp > _lockTime, 'Contract is locked until 7 days');
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }
}

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

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

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
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

interface IUniswapV2Router01 {
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

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract Kroco is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcluded; //from reflections
  address[] private _excluded;

  mapping(address => bool) private _isExcludedFromTxLimit; //Adding this for the dxsale/unicrypt presale, the router needs to be exempt from max tx amount limit.

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 100 * 10**9 * 10**8; // 100 Billion Tokens
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;
  uint256 public maxWalletAmount = 5 * 10**9 * 10**8;
  string private _name = 'Kroco';
  string private _symbol = 'Kroc';
  uint8 private _decimals = 8;
  bool public antiwhaleEnabled = false;
  bool private antiSniping_failsafe = true;

  uint256 public _taxFee = 0;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _liquidityFee = 0;
  uint256 private _previousLiquidityFee = _liquidityFee;

  uint256 public _marketingFee = 0;
  uint256 private _previousMarketingFee = _marketingFee;

  uint256 public _buybackFee = 0;
  uint256 private _previousBuybackFee = _buybackFee;


  uint256 public buybackFeeBuy = 0;
  uint256 public buybackFeeSell = 0;

 uint256 public marketingFeeBuy = 3;
 uint256 public marketingFeeSell = 4;

 uint256 public liquidityFeeBuy = 2;
 uint256 public liquidityFeeSell = 2;

 uint256 public reflectFeeBuy = 2;
 uint256 public reflectFeeSell = 2;

  address private _marketingWalletAddress = 0xc7A991Af62B362c509B614bad4529C188AC46eD5; 
  address public _buybackWallet = 0xc7A991Af62B362c509B614bad4529C188AC46eD5;

  uint256 private launchedAt; //Stores the block.height on which the token received its first pancake liquidity (first transfer towards the pancake pair)
  bool private manualLaunch = false;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable KrocoUniswapV2Pair;
  mapping(address => bool) _isExcludedFromMaxWalletLimit;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 public _maxTxAmount = 5 * 10**9 * 10**8; // 5%
  uint256 private numTokensSellToAddToLiquidity = 5000 * 10**8; 

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );
  event AntiSnipingFailsafeSetTo(bool toggle);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor() {
      address _newOwner = 0x161ae882fFB43D89C93d70472f1204Ce055158d3; // Kroco Owner
    _rOwned[_newOwner] = _rTotal;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    ); //PancakeSwap's V2 Router.
    //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Pancakeswap testnet
    //Create a new uniswap pair for this new token and set the local pair pointer
    KrocoUniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());

    //Set the local router pointer
    uniswapV2Router = _uniswapV2Router;

    //Exclude owner and this contract from fee
    _isExcludedFromFee[_newOwner] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromMaxWalletLimit[_newOwner] = true;
    _isExcludedFromMaxWalletLimit[address(this)] = true;
    _isExcludedFromTxLimit[_newOwner] = true;
    _isExcludedFromTxLimit[address(this)] = true;

    emit Transfer(address(0), _newOwner, _tTotal);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function setMaxWalletAmount(uint val) public onlyOwner {
      maxWalletAmount = val * 10**8;
  }

  function launch() internal {
    launchedAt = block.number;
  }

  function launched() internal view returns (bool) {
    return launchedAt != 0;
  }




  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
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
      _allowances[sender][_msgSender()].sub(
        amount,
        'ERC20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

 
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }





  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, 'Amount must be less than total reflections');
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }





  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    //Deprecated
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(tAmount); 
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function setIsExcludedFromTXLimit(address account, bool isExcluded)
    public
    onlyOwner
  {
    _isExcludedFromTxLimit[account] = isExcluded;
  }

  function isExcludedFromTXLimit(address account) public view returns (bool) {
    return _isExcludedFromTxLimit[account];
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }
  function setBuyFees() private {

      _previousBuybackFee = _buybackFee;
      _buybackFee = buybackFeeBuy;
      _previousLiquidityFee = _liquidityFee;
      _liquidityFee = liquidityFeeBuy;
      _previousMarketingFee = _marketingFee;
      _marketingFee = marketingFeeBuy;
      _previousTaxFee = _taxFee;
      _taxFee = reflectFeeBuy;

  }

 function setSellFees() private {

      _previousBuybackFee = _buybackFee;
      _buybackFee = buybackFeeSell;
      _previousLiquidityFee = _liquidityFee;
      _liquidityFee = liquidityFeeSell;
      _previousMarketingFee = _marketingFee;
      _marketingFee = marketingFeeSell;
      _previousTaxFee = _taxFee;
      _taxFee = reflectFeeSell;

  }



  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  struct tVector {
    uint256 tTransferAmount;
    uint256 tFee;
    uint256 tLiquidity;
    uint256 tMarketing;
  }

  struct rVector {
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rFee;
  }

  function _getValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    tVector memory my_tVector;
    rVector memory my_rVector;
    {
      (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(
        tAmount
      );
      my_tVector.tTransferAmount = tTransferAmount;
      my_tVector.tFee = tFee;
      my_tVector.tLiquidity = tLiquidity;
    }
    {
      (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
        tAmount,
        my_tVector.tFee,
        my_tVector.tLiquidity,
        _getRate()
      );
      my_rVector.rAmount = rAmount;
      my_rVector.rTransferAmount = rTransferAmount;
      my_rVector.rFee = rFee;
    }
    return (
      my_rVector.rAmount,
      my_rVector.rTransferAmount,
      my_rVector.rFee,
      my_tVector.tTransferAmount,
      my_tVector.tFee,
      my_tVector.tLiquidity
    );
  }

  function _getTValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee);
    tTransferAmount = tTransferAmount.sub(tLiquidity);
    return (tTransferAmount, tFee, tLiquidity);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tLiquidity,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rTransferAmount;
    uint256 rFee;
    {
      rFee = tFee.mul(currentRate);
      uint256 rLiquidity = tLiquidity.mul(currentRate);
      rTransferAmount = rAmount.sub(rFee);
      rTransferAmount = rTransferAmount.sub(rLiquidity);
    }
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcluded[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    uint256 this_taxFee = _taxFee;
    return _amount.mul(this_taxFee).div(100);
  }

  function calculateLiquidityFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    return _amount.mul(_liquidityFee.add(_marketingFee).add(_buybackFee)).div(100);
  }





  function removeAllFee() private {

  }

  function restoreAllFee() private {

  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }



  //MARKER: This is our bread and butter.
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');

    if ((!launched() && to == KrocoUniswapV2Pair) || manualLaunch) {
      require(
        balanceOf(from) > 0,
        'Are you trying to launch without actually having tokens? WTF?'
      );
      launch();
    }

    if (antiwhaleEnabled && ((from != owner() && to != owner()) || !(_isExcludedFromTxLimit[from]))) {
      require(
        amount <= _maxTxAmount,
        'Kroco: Transfer amount exceeds the maxTxAmount.'
      );
    }
    if(!_isExcludedFromMaxWalletLimit[from] && !_isExcludedFromMaxWalletLimit[to] && to != KrocoUniswapV2Pair) {
        uint balance = balanceOf(to);
        require(balance + amount <= maxWalletAmount," max wallet reached");
    }
    uint256 contractTokenBalance = balanceOf(address(this));

    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }
    bool overMinTokenBalance = (contractTokenBalance >=
      numTokensSellToAddToLiquidity);
    if (
      overMinTokenBalance &&
      !inSwapAndLiquify &&
      from != KrocoUniswapV2Pair &&
      swapAndLiquifyEnabled
    ) {
        setSellFees();
        inSwapAndLiquify = true;
      contractTokenBalance = numTokensSellToAddToLiquidity;
      //add liquidity
      swapAndLiquify(contractTokenBalance);
      restoreAllFee();
      inSwapAndLiquify = false;
    }

    bool takeFee = true;
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }



    _tokenTransfer(from, to, amount, takeFee);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    uint256 marketingBalance = contractTokenBalance.mul(_marketingFee).div(
      _marketingFee.add(_liquidityFee).add(_buybackFee)
    );
    uint buybackBal = contractTokenBalance.mul(_buybackFee).div(_marketingFee.add(_liquidityFee).add(_buybackFee));
    uint256 liquidityBalance = contractTokenBalance.sub(marketingBalance).sub(buybackBal);

    uint256 half = liquidityBalance.div(2);
    uint256 otherHalf = liquidityBalance.sub(half);
    uint256 tokensToSwapForETH = half.add(marketingBalance).add(buybackBal);

    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(tokensToSwapForETH); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    uint256 marketingETHBalance = newBalance.mul(marketingBalance).div(
      tokensToSwapForETH
    );
        uint buybackBalanceETH = newBalance.mul(buybackBal).div(tokensToSwapForETH);
    uint256 liquidityETHBalance = newBalance.sub(marketingETHBalance).sub(buybackBalanceETH);



    // add liquidity to uniswap
   

    // send ETH to marketing wallet


    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(0),
      block.timestamp
    );
  }


  function setSellFee(uint buyback, uint marketing, uint liquidity, uint reflect) public onlyOwner {
      buybackFeeSell = buyback;
      marketingFeeSell = marketing;
      liquidityFeeSell = liquidity;
      reflectFeeSell = reflect;
      require(buyback + marketing + liquidity + reflect <= 25, "max 25%");
  }

    function setBuyFees(uint buyback, uint marketing, uint liquidity, uint reflect) public onlyOwner {
      buybackFeeBuy = buyback;
      marketingFeeBuy = marketing;
      liquidityFeeBuy = liquidity;
      reflectFeeBuy = reflect;
      require(buyback + marketing + liquidity + reflect <= 25, "max 25%");
  }

  function isExcludedFromMaxWallet(address ac) public view returns(bool) {
      return _isExcludedFromMaxWalletLimit[ac];
  }
  //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {

  }

  function setNumTokensell(uint value ) public onlyOwner 
{
numTokensSellToAddToLiquidity = value;
}

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {

  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    //Deprecated
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(tAmount); 
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    //Deprecated

    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(tAmount); 
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }


}