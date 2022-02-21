/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.8 <0.9.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
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

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;
    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256), "SafeMathInt: Mul Error 1");
    require((b == 0) || (c / b == a), "SafeMathInt: Mul Error 2");
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != - 1 || a != MIN_INT256, "SafeMathInt: Div Error 1");
    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SafeMathInt: Sub Error 1");
    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMathInt: Add Error 1");
    return c;
  }

  function abs(int256 a) internal pure returns (int256) {
    require(a != MIN_INT256, "SafeMathInt: Abs Error 1");
    return a < 0 ? - a : a;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0, "SafeMathInt: toUint256Safe Error 1");
    return uint256(a);
  }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0, "SafeMathUint: toInt256Safe Error 1");
    return b;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

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

contract ERC20 is Context, IERC20, IERC20Metadata {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 private _totalSupply;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: Transfer amount exceeds allowance"));
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: Transfer from the zero address");
    require(recipient != address(0), "ERC20: Transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: Transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: Mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: Burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: Burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: Approve from the zero address");
    require(spender != address(0), "ERC20: Approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

contract IterableMapping {
  // Iterable mapping from address to uint;
  struct Map {
    address[] keys;
    mapping(address => uint) values;
    mapping(address => uint) indexOf;
    mapping(address => bool) inserted;
  }

  Map internal iterableMap;

  constructor() {}

  function iterableMapGet(address key) public view returns (uint) {
    return iterableMap.values[key];
  }

  function iterableMapGetIndexOfKey(address key) public view returns (int) {
    if (!iterableMap.inserted[key]) {
      return - 1;
    }
    return int(iterableMap.indexOf[key]);
  }

  function iterableMapGetKeyAtIndex(uint index) public view returns (address) {
    return iterableMap.keys[index];
  }

  function iterableMapSize() public view returns (uint) {
    return iterableMap.keys.length;
  }

  function iterableMapSet(address key, uint val) public {
    if (iterableMap.inserted[key]) {
      iterableMap.values[key] = val;
    } else {
      iterableMap.inserted[key] = true;
      iterableMap.values[key] = val;
      iterableMap.indexOf[key] = iterableMap.keys.length;
      iterableMap.keys.push(key);
    }
  }

  function iterableMapRemove(address key) public {
    if (!iterableMap.inserted[key]) {
      return;
    }

    delete iterableMap.inserted[key];
    delete iterableMap.values[key];

    uint index = iterableMap.indexOf[key];
    uint lastIndex = iterableMap.keys.length - 1;
    address lastKey = iterableMap.keys[lastIndex];

    iterableMap.indexOf[lastKey] = index;
    delete iterableMap.indexOf[key];

    iterableMap.keys[index] = lastKey;
    iterableMap.keys.pop();
  }
}

interface DividendPayingTokenOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns (uint256);

  function withdrawnDividendOf(address _owner) external view returns (uint256);

  function accumulativeDividendOf(address _owner) external view returns (uint256);
}

interface DividendPayingTokenInterface {
  function dividendOf(address _owner) external view returns (uint256);

  function distributeDividends() external payable;

  function withdrawDividend() external;

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2 ** 128;

  uint256 internal magnifiedDividendPerShare;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {
  }

  receive() external payable {distributeDividends();}

  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
      emit DividendsDistributed(_msgSender(), msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(_msgSender()));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value : _withdrawableDividend, gas : 3000}("");

      if (!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) public view override returns (uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns (uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) public view override returns (uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns (uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
    .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
    .sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
    .add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if (newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if (newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract DividendTracker is DividendPayingToken, IterableMapping, Ownable {
  using SafeMath for uint256;
  using SafeMathInt for int256;

  uint256 public lastProcessedIndex;

  mapping(address => bool) public excludedFromDividends;

  mapping(address => uint256) public lastClaimTimes;

  uint256 public claimWait;
  uint256 public immutable minimumTokenBalanceForDividends;

  event ExcludeFromDividends(address indexed account);
  event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

  event Claim(address indexed account, uint256 amount, bool indexed automatic);

  constructor(string memory _symbol, uint8 _decimals, uint256 _minimumTokenBalanceForDividends)
  DividendPayingToken(_symbol, _symbol, _decimals) {
    claimWait = 180;
    minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends * (10 ** decimals());
    // Must hold minimum tokens to receive dividends
  }

  function _transfer(address, address, uint256) internal pure override {
    require(false, "No transfers allowed");
  }

  function withdrawDividend() public pure override {
    require(false, "withdrawDividend disabled. Use the 'claim' function on the main contract.");
  }

  function excludeFromDividends(address account) external onlyOwner {
    require(!excludedFromDividends[account]);
    excludedFromDividends[account] = true;

    _setBalance(account, 0);
    iterableMapRemove(account);

    emit ExcludeFromDividends(account);
  }

  function updateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(newClaimWait >= 180 && newClaimWait <= 86400, "claimWait must be updated to between 1 and 24 hours");
    require(newClaimWait != claimWait, "Cannot update claimWait to same value");
    emit ClaimWaitUpdated(newClaimWait, claimWait);
    claimWait = newClaimWait;
  }

  function getLastProcessedIndex() external view returns (uint256) {
    return lastProcessedIndex;
  }

  function getNumberOfTokenHolders() external view returns (uint256) {
    return iterableMap.keys.length;
  }

  function getAccount(address _account) public view returns (
    address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends,
    uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable) {

    account = _account;
    index = iterableMapGetIndexOfKey(account);
    iterationsUntilProcessed = - 1;

    if (index >= 0) {
      if (uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
      }
      else {
        uint256 processesUntilEndOfArray = iterableMap.keys.length > lastProcessedIndex ? iterableMap.keys.length.sub(lastProcessedIndex) : 0;
        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
      }
    }

    withdrawableDividends = withdrawableDividendOf(account);
    totalDividends = accumulativeDividendOf(account);
    lastClaimTime = lastClaimTimes[account];
    nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
  }

  function getAccountAtIndex(uint256 index) public view returns (
    address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    if (index >= iterableMapSize()) {return (address(0), - 1, - 1, 0, 0, 0, 0, 0);}

    address account = iterableMapGetKeyAtIndex(index);
    return getAccount(account);
  }

  function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    if (lastClaimTime > block.timestamp) {return false;}

    return block.timestamp.sub(lastClaimTime) >= claimWait;
  }

  function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    if (excludedFromDividends[account]) {return;}

    if (newBalance >= minimumTokenBalanceForDividends) {
      _setBalance(account, newBalance);
      iterableMapSet(account, newBalance);
    } else {
      _setBalance(account, 0);
      iterableMapRemove(account);
    }

    processAccount(account, true);
  }

  function process(uint256 gas) public returns (uint256, uint256, uint256) {
    uint256 numberOfTokenHolders = iterableMap.keys.length;
    if (numberOfTokenHolders == 0) {return (0, 0, lastProcessedIndex);}

    uint256 currentProcessingIndex = lastProcessedIndex;
    uint256 iterations = 0;
    uint256 claims = 0;
    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();

    while (gasUsed < gas && iterations < numberOfTokenHolders) {
      currentProcessingIndex++;
      if (currentProcessingIndex >= iterableMap.keys.length) {currentProcessingIndex = 0;}
      address account = iterableMap.keys[currentProcessingIndex];

      if (canAutoClaim(lastClaimTimes[account]) && processAccount(payable(account), true)) {claims++;}
      iterations++;

      uint256 newGasLeft = gasleft();
      if (gasLeft > newGasLeft) {
        gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
      }
      gasLeft = newGasLeft;
    }

    lastProcessedIndex = currentProcessingIndex;
    return (iterations, claims, lastProcessedIndex);
  }

  function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
    uint256 amount = _withdrawDividendOfUser(account);

    if (amount > 0) {
      lastClaimTimes[account] = block.timestamp;
      emit Claim(account, amount, automatic);
      return true;
    }

    return false;
  }
}

contract BNBDividendPayingERC20Token is ERC20, Ownable {
  using SafeMath for uint256;

  IUniswapV2Router02 public uniswapV2Router;
  address public immutable uniswapV2Pair;

  bool private swapping;

  DividendTracker public dividendTracker;

  bool public isSwappingEnabled = true;
  uint256 public swapTokensAtAmount;

  struct FeeSet {
    uint256 burnFee;
    uint256 holderFee;
    uint256 liquidityFee;
  }

  FeeSet[] public weeklyFee;
  uint256 immutable oneWeek = 300;

  uint256 availableLiquidityFee;
  uint256 availableHolderFee;

  mapping(address => uint256) public effectiveObtainTime;

  uint256 public gasForProcessing = 300000;

  bool public isTradingEnabled = false;
  mapping(address => bool) private canTransferBeforeTradingIsEnabled;

  mapping(address => bool) private _isExcludedFromFees;

  // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping(address => bool) public automatedMarketMakerPairs;

  event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

  event ExcludeFromFees(address indexed account, bool isExcluded);

  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

  event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

  event FeeChargedAfterHoldingFor(address indexed account, uint256 numOfWeeks, uint256 fromTimestamp, uint256 toTimestamp);

  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  event SendDividends(
    uint256 tokensSwapped,
    uint256 amount
  );

  event ProcessedDividendTracker(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  constructor(string memory _tokenName, string memory _tokenSymbol, uint8 _decimals) ERC20(_tokenName, _tokenSymbol, _decimals) {
    // Week 0
    weeklyFee.push(FeeSet(12, 15, 3));
    // Week 1
    weeklyFee.push(FeeSet(12, 14, 3));
    // Week 2
    weeklyFee.push(FeeSet(12, 13, 3));
    // Week 3
    weeklyFee.push(FeeSet(11, 13, 3));
    // Week 4
    weeklyFee.push(FeeSet(10, 13, 3));
    // Week 5
    weeklyFee.push(FeeSet(10, 12, 3));
    // Week 6
    weeklyFee.push(FeeSet(10, 12, 2));
    // Week 7
    weeklyFee.push(FeeSet(10, 11, 2));
    // Week 8
    weeklyFee.push(FeeSet(9, 11, 2));
    // Week 9
    weeklyFee.push(FeeSet(9, 10, 2));
    // Week 10
    weeklyFee.push(FeeSet(8, 10, 2));
    // Week 11
    weeklyFee.push(FeeSet(7, 10, 2));
    // Week 12
    weeklyFee.push(FeeSet(7, 9, 2));
    // Week 13
    weeklyFee.push(FeeSet(7, 9, 1));
    // Week 14
    weeklyFee.push(FeeSet(7, 8, 1));
    // Week 15
    weeklyFee.push(FeeSet(6, 7, 1));
    // Week 16
    weeklyFee.push(FeeSet(5, 7, 1));
    // Week 17
    weeklyFee.push(FeeSet(5, 6, 1));
    // Week 18
    weeklyFee.push(FeeSet(4, 6, 1));
    // Week 19
    weeklyFee.push(FeeSet(4, 5, 1));

    dividendTracker = new DividendTracker(appendString(_tokenSymbol, "-DT"), decimals(), 10000);

    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    _setAutomatedMarketMakerPair(uniswapV2Pair, true);

    dividendTracker.excludeFromDividends(address(dividendTracker));
    dividendTracker.excludeFromDividends(address(this));
    dividendTracker.excludeFromDividends(address(0));
    dividendTracker.excludeFromDividends(owner());
    dividendTracker.excludeFromDividends(address(uniswapV2Router));

    excludeFromFees(address(this), true);
    excludeFromFees(owner(), true);
    canTransferBeforeTradingIsEnabled[owner()] = true;

    swapTokensAtAmount = 200000 * (10 ** decimals());
    _mint(owner(), 1000000000 * (10 ** decimals()));
  }

  receive() external payable {
  }

  function appendString(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    require(_isExcludedFromFees[account] != excluded, "Account is already excluded");
    _isExcludedFromFees[account] = excluded;

    emit ExcludeFromFees(account, excluded);
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function setIsSwappingEnabled(bool shouldEnable) external onlyOwner() {
    isSwappingEnabled = shouldEnable;
  }

  function setTradingEnabled() external onlyOwner() {
    require(!isTradingEnabled, "Trading already enabled");
    isTradingEnabled = true;
  }

  function subTransfer(address from, address to, uint256 amount) internal {
    require(amount > 0, "Transfer amount cannot be 0");
    uint256 timeCenterOfAmount = (balanceOf(to).mul(effectiveObtainTime[to])).add((amount.mul(block.timestamp)));
    super._transfer(from, to, amount);
    effectiveObtainTime[to] = timeCenterOfAmount.div(balanceOf(to));
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), "Transfer from the zero address");

    if (!isTradingEnabled) {
      require(canTransferBeforeTradingIsEnabled[from], "This account cannot send tokens until trading is enabled");
    }

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    uint256 contractTokenBalance = balanceOf(address(this));
    bool canSwap = contractTokenBalance >= swapTokensAtAmount && isTradingEnabled && !swapping &&
    !automatedMarketMakerPairs[from] && isSwappingEnabled && from != owner() && to != owner();

    if (canSwap) {
      swapping = true;

      swapAndLiquify(availableLiquidityFee);
      availableLiquidityFee = 0;

      swapAndSendDividends(availableHolderFee);
      availableHolderFee = 0;

      swapping = false;
    }

    bool takeFee = !(swapping || _isExcludedFromFees[from] || _isExcludedFromFees[to] || !isTradingEnabled);

    if (takeFee) {
      uint256 holdWeeks = (block.timestamp.sub(effectiveObtainTime[from])).div(oneWeek);
      if (holdWeeks > weeklyFee.length) {
        holdWeeks = weeklyFee.length - 1;
      }
      FeeSet storage currentFeeSet = weeklyFee[holdWeeks];

      uint256 burnFees = amount.mul(currentFeeSet.burnFee).div(100);
      uint256 liquidityFees = amount.mul(currentFeeSet.liquidityFee).div(100);
      uint256 holderFees = amount.mul(currentFeeSet.holderFee).div(100);

      availableHolderFee = availableHolderFee.add(holderFees);
      availableLiquidityFee = availableLiquidityFee.add(liquidityFees);

      amount = amount.sub(burnFees).sub(liquidityFees).sub(holderFees);
      subTransfer(from, address(0), burnFees);
      subTransfer(from, address(this), liquidityFees.add(holderFees));

      emit FeeChargedAfterHoldingFor(from, holdWeeks, effectiveObtainTime[from], block.timestamp);
    }
    subTransfer(from, to, amount);

    try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
    try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

    if (!swapping) {
      try dividendTracker.process(gasForProcessing) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gasForProcessing, tx.origin);
      } catch {}
    }
  }

  // -----------------------------Dividend Related------------------------------------- //

  function updateDividendTracker(address newAddress) public onlyOwner {
    require(newAddress != address(dividendTracker), "The dividend tracker already has that address");

    DividendTracker newDividendTracker = DividendTracker(payable(newAddress));

    require(newDividendTracker.owner() == address(this), "The new dividend tracker has wrong owner");

    newDividendTracker.excludeFromDividends(address(newDividendTracker));
    newDividendTracker.excludeFromDividends(address(this));
    dividendTracker.excludeFromDividends(address(0));
    newDividendTracker.excludeFromDividends(owner());
    newDividendTracker.excludeFromDividends(address(uniswapV2Router));

    emit UpdateDividendTracker(newAddress, address(dividendTracker));

    dividendTracker = newDividendTracker;
  }

  function updateGasForProcessing(uint256 newValue) public onlyOwner {
    require(newValue >= 200000 && newValue <= 500000, "gasForProcessing must be between 200,000 and 500,000");
    require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
    emit GasForProcessingUpdated(newValue, gasForProcessing);
    gasForProcessing = newValue;
  }

  function updateClaimWait(uint256 claimWait) external onlyOwner {
    dividendTracker.updateClaimWait(claimWait);
  }

  function getClaimWait() external view returns (uint256) {
    return dividendTracker.claimWait();
  }

  function getTotalDividendsDistributed() external view returns (uint256) {
    return dividendTracker.totalDividendsDistributed();
  }

  function withdrawableDividendOf(address account) public view returns (uint256) {
    return dividendTracker.withdrawableDividendOf(account);
  }

  function dividendTokenBalanceOf(address account) public view returns (uint256) {
    return dividendTracker.balanceOf(account);
  }

  function getAccountDividendsInfo(address account) external view returns (
    address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    return dividendTracker.getAccount(account);
  }

  function getAccountDividendsInfoAtIndex(uint256 index) external view returns (
    address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    return dividendTracker.getAccountAtIndex(index);
  }

  function processDividendTracker(uint256 gas) external {
    (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
    emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
  }

  function claim() external {
    dividendTracker.processAccount(payable(_msgSender()), false);
  }

  function getLastProcessedIndex() external view returns (uint256) {
    return dividendTracker.getLastProcessedIndex();
  }

  function getNumberOfDividendTokenHolders() external view returns (uint256) {
    return dividendTracker.getNumberOfTokenHolders();
  }

  function swapAndSendDividends(uint256 tokens) private {
    swapTokensForEth(tokens);
    uint256 dividends = address(this).balance;
    (bool success,) = address(dividendTracker).call{value : dividends}("");

    if (success) {
      emit SendDividends(tokens, dividends);
    }
  }

  // -------------------------- AMM Related ------------------------------- //

  function updateUniswapV2Router(address newAddress) public onlyOwner {
    require(newAddress != address(uniswapV2Router), "The router already has that address");
    emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router02(newAddress);
  }

  function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
    require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

    _setAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
    automatedMarketMakerPairs[pair] = value;

    if (value) {
      dividendTracker.excludeFromDividends(pair);
    }

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function swapAndLiquify(uint256 tokens) private {
    uint256 half = tokens.div(2);
    uint256 otherHalf = tokens.sub(half);

    uint256 initialBalance = address(this).balance;

    swapTokensForEth(half);
    uint256 newBalance = address(this).balance.sub(initialBalance);

    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );

  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.addLiquidityETH{value : ethAmount}(
      address(this),
      tokenAmount,
      0,
      0,
      address(0),
      block.timestamp
    );

  }
}