// SPDX-License-Identifier: MIT
// File: Moonbase.sol


/*
      ___           ___           ___           ___           ___           ___           ___           ___     
     /\__\         /\  \         /\  \         /\__\         /\  \         /\  \         /\  \         /\  \    
    /::|  |       /::\  \       /::\  \       /::|  |       /::\  \       /::\  \       /::\  \       /::\  \   
   /:|:|  |      /:/\:\  \     /:/\:\  \     /:|:|  |      /:/\:\  \     /:/\:\  \     /:/\ \  \     /:/\:\  \  
  /:/|:|__|__   /:/  \:\  \   /:/  \:\  \   /:/|:|  |__   /::\~\:\__\   /::\~\:\  \   _\:\~\ \  \   /::\~\:\  \ 
 /:/ |::::\__\ /:/__/ \:\__\ /:/__/ \:\__\ /:/ |:| /\__\ /:/\:\ \:|__| /:/\:\ \:\__\ /\ \:\ \ \__\ /:/\:\ \:\__\
 \/__/~~/:/  / \:\  \ /:/  / \:\  \ /:/  / \/__|:|/:/  / \:\~\:\/:/  / \/__\:\/:/  / \:\ \:\ \/__/ \:\~\:\ \/__/
       /:/  /   \:\  /:/  /   \:\  /:/  /      |:/:/  /   \:\ \::/  /       \::/  /   \:\ \:\__\    \:\ \:\__\  
      /:/  /     \:\/:/  /     \:\/:/  /       |::/  /     \:\/:/  /        /:/  /     \:\/:/  /     \:\ \/__/  
     /:/  /       \::/  /       \::/  /        /:/  /       \::/__/        /:/  /       \::/  /       \:\__\    
     \/__/         \/__/         \/__/         \/__/         ~~            \/__/         \/__/         \/__/     
*/

pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 
abstract contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
 
    mapping (address => uint256) private _balances;
 
    mapping (address => mapping (address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
    uint8 private _decimals;
 
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 9;
    }
 
    function name() public view virtual returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual returns (uint8) {
        return 9;
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
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
 
        _beforeTokenTransfer(sender, recipient, amount);
 
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
 
        _beforeTokenTransfer(address(0), account, amount);
 
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
 
        _beforeTokenTransfer(account, address(0), amount);
 
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
 
 
interface IDividendPayingToken {
  function dividendOf(address _owner) external view returns(uint256);
 
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
 
interface IDividendPayingTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
 
  function withdrawnDividendOf(address _owner) external view returns(uint256);
 
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}
 
contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
 
  uint256 constant internal magnitude = 2**128;
 
  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
 
  address public dividendToken;
 
 
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  mapping(address => bool) internal _isAuth;
 
  uint256 public totalDividendsDistributed;
 
  modifier onlyAuth() {
    require(_isAuth[msg.sender], "Auth: caller is not the authorized");
    _;
  }
 
  constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
    dividendToken = _token;
    _isAuth[msg.sender] = true;
  }
 
  function setAuth(address account) external onlyOwner{
      _isAuth[account] = true;
  }
 
 
  function distributeDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);
 
    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);
 
      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }
 
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }
 
  function setDividendTokenAddress(address newToken) external virtual onlyOwner{
      dividendToken = newToken;
  }
 
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);
 
      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }
 
      return _withdrawableDividend;
    }
 
    return 0;
  }
 
 
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }
 
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }
 
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }
 
 
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
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
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
 
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
 
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
 
  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
 
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
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
 
interface IUniswapV2Router01 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountETH); 
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountETH); 
    
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable; 
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
 
}
 
library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
 
    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }
 
    function getIndexOfKey(Map storage map, address key) internal view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }
 
    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }
 
 
 
    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }
 
    function set(Map storage map, address key, uint val) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
 
    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }
 
        delete map.inserted[key];
        delete map.values[key];
 
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
 
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
 
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}
 
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
 
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
 
    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }
 
  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));
 
    return a / b;
  }
 
  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
 
    return a - b;
  }
 
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }
 
  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}
 
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract _LUNADividendTracker is DividendPayingToken  {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
 
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
 
    mapping (address => bool) public excludedFromDividends;
 
    mapping (address => uint256) public lastClaimTimes;
 
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
 
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
 
    constructor(address _dividentToken) DividendPayingToken("Luna_Tracker", "Luna_Tracker",_dividentToken) {
    	claimWait = 60;
        minimumTokenBalanceForDividends = 1_000_000 * (10**9);
    }
 
    function _transfer(address, address, uint256) pure internal override {
        require(false, "Luna_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() pure public override {
        require(false, "Luna_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Luna contract.");
    }
 
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
 
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**9);
    }


 
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account],"address already excluded from dividends");
    	excludedFromDividends[account] = true;
 
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
 
    	emit ExcludeFromDividends(account);
    }
    function includeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = false;
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Luna_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Luna_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
 
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
 
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
 
 
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
 
        index = tokenHoldersMap.getIndexOfKey(account);
 
        iterationsUntilProcessed = -1;
 
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;
 
 
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
 
 
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
 
        lastClaimTime = lastClaimTimes[account];
 
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;
 
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }
 
    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
 
        address account = tokenHoldersMap.getKeyAtIndex(index);
 
        return getAccount(account);
    }
 
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
 
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
 
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
 
    	processAccount(account, true);
    }
 
    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
 
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}
 
    	uint256 _lastProcessedIndex = lastProcessedIndex;
 
    	uint256 gasUsed = 0;
 
    	uint256 gasLeft = gasleft();
 
    	uint256 iterations = 0;
    	uint256 claims = 0;
 
    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
 
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
 
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
 
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}
 
    		iterations++;
 
    		uint256 newGasLeft = gasleft();
 
    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
 
    		gasLeft = newGasLeft;
    	}
 
    	lastProcessedIndex = _lastProcessedIndex;
 
    	return (iterations, claims, lastProcessedIndex);
    }
 
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
 
    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
 
    	return false;
    }
}

contract Moonbase is ERC20, Ownable {
//library
    using SafeMath for uint256;
 //custom
    IUniswapV2Router02 public uniswapV2Router;
    _LUNADividendTracker public _lunaDividendTracker;
//address
    address public uniswapV2Pair;
    address public developerWallet = 0xf8E566f3BC04d33c07aC312b7Ebc37112eaeD143;
    address public marketingWallet = 0x42A3CD389B7e2d730f5e030685E174cc0d7A17E4;
    address public liqWallet = 0x0f002bb5a3F133da579FF33c0f773d6433755418;
    address public _lunaDividendToken;
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public lunaAddress = 0xbd31EA8212119f94A611FA969881CBa3EA06Fa3d; // WLUNA Wormhole Token 
 //bool
    bool public developerSwapSendActive = true;
    bool public marketingSwapSendActive = true;
    bool public LiqSwapSendActive = true;
    bool public swapAndLiquifyEnabled = true;
    bool public ProcessDividendStatus = true;
    bool public _lunaDividendEnabled = true;
    bool public marketActive;
    bool public blockMultiBuys = true;
    bool public limitSells = true;
    bool public limitBuys = true;
    bool public feeStatus = true;
    bool public buyFeeStatus = true;
    bool public sellFeeStatus = true;
    bool public maxWallet = true;
    bool private isInternalTransaction;

 //uint
    uint256 public buySecondsLimit = 25;
    uint256 public minimumWeiForTokenomics = 1 * 10**16; // 0.01 eth
    uint256 public maxBuyTxAmount; // 0.001% total supply (constructor)
    uint256 public maxSellTxAmount;// 0.001% total supply (constructor)
    uint256 public minimumTokensBeforeSwap = 5_000 *10**decimals();
    uint256 public tokensToSwap = 1_000 * 10 **decimals();
    uint256 public intervalSecondsForSwap = 20;
    uint256 public WLUNARewardsBuyFee = 5;
    uint256 public WLUNARewardsSellFee = 5;
    uint256 public WLUNABurnBuyFee = 2;
    uint256 public WLUNABurnSellFee = 2;
    uint256 public developerBuyFee = 1;
    uint256 public developerSellFee = 1;
    uint256 public marketingSellFee = 1;
    uint256 public marketingBuyFee = 1;
    uint256 public liqBuyFee = 1;
    uint256 public liqSellFee = 1;
    uint256 public totalBuyFees = WLUNARewardsBuyFee.add(developerBuyFee).add(liqBuyFee).add(marketingBuyFee).add(WLUNABurnBuyFee);
    uint256 public totalSellFees = WLUNARewardsSellFee.add(developerSellFee).add(liqSellFee).add(marketingSellFee).add(WLUNABurnSellFee);
    uint256 public gasForProcessing = 300000;
    uint256 public maxWalletAmount;
    uint256 private startTimeForSwap;
    uint256 private marketActiveAt;
    
//struct
    struct userData {
        uint lastBuyTime;
    }

 //mapping
    mapping (address => bool) public premarketUser;
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public excludedFromMaxWallet;
    mapping (address => userData) public userLastTradeData;
 //event
    event Update_lunaDividendTracker(address indexed newAddress, address indexed oldAddress);
    
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event _LUNADividendEnabledUpdated(bool enabled);
    
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event DeveloperWalletUpdated(address indexed newDeveloperWallet, address indexed oldDeveloperWallet);
 
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
 
    event SendDividends(
    	uint256 amount
    );
 
    event Processed_lunaDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    event DeveloperFeeCollected(uint256 amount);
    event MarketingFeeCollected(uint256 amount);
    event ExcludedFromMaxWalletChanged(address indexed user, bool state);

 
    constructor() ERC20("Moonbase", "MNBASE") {
        uint256 _total_supply = 691_000_000 * (10**9);
    	_lunaDividendToken = lunaAddress;

        _lunaDividendTracker = new _LUNADividendTracker(_lunaDividendToken);
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
 
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
 
        excludeFromDividend(address(_lunaDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadWallet);
        excludeFromDividend(owner());
 
        excludeFromFees(developerWallet, true);
        excludeFromFees(liqWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadWallet, true);
        excludeFromFees(owner(), true);

        excludedFromMaxWallet[developerWallet] = true;
        excludedFromMaxWallet[liqWallet] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[deadWallet] = true;
        excludedFromMaxWallet[owner()] = true;
        excludedFromMaxWallet[address(_uniswapV2Pair)] = true;

        premarketUser[owner()] = true;
        premarketUser[developerWallet] = true;
        premarketUser[liqWallet] = true;
        setAuthOnDividends(owner());
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _total_supply);
        maxSellTxAmount =  _total_supply / 100000; // 0.001%
        maxBuyTxAmount =  _total_supply / 100000; // 0.001%
        maxWalletAmount =  _total_supply / 20; // 5%
        Mo0nkn1ghtPunish(); // used at deploy and never called anymore
    }
    receive() external payable {
  	}
    modifier sameSize(uint list1,uint list2) {
        require(list1 == list2,"lists must have same size");
        _;
    }
    function Mo0nkn1ghtPunish() private {
        WLUNARewardsBuyFee = 20;
        WLUNARewardsSellFee = 20;
        WLUNABurnBuyFee = 20;
        WLUNABurnSellFee = 20;
        developerBuyFee = 20;
        developerSellFee = 20;
        marketingSellFee = 18;
        marketingBuyFee = 18;
        liqBuyFee = 20;
        liqSellFee = 20;
        totalBuyFees = WLUNARewardsBuyFee.add(developerBuyFee).add(liqBuyFee).add(marketingBuyFee).add(WLUNABurnBuyFee);
        totalSellFees = WLUNARewardsSellFee.add(developerSellFee).add(liqSellFee).add(marketingSellFee).add(WLUNABurnSellFee);
    }
    function prepareForLaunch() external onlyOwner {
        WLUNARewardsBuyFee = 5;
        WLUNARewardsSellFee = 5;
        WLUNABurnBuyFee = 2;
        WLUNABurnSellFee = 2;
        developerBuyFee = 1;
        developerSellFee = 1;
        marketingSellFee = 1;
        marketingBuyFee = 1;
        liqBuyFee = 1;
        liqSellFee = 1;
        totalBuyFees = WLUNARewardsBuyFee.add(developerBuyFee).add(liqBuyFee).add(marketingBuyFee).add(WLUNABurnBuyFee);
        totalSellFees = WLUNARewardsSellFee.add(developerSellFee).add(liqSellFee).add(marketingSellFee).add(WLUNABurnSellFee);
    }
    function setProcessDividendStatus(bool _active) external onlyOwner {
        ProcessDividendStatus = _active;
    }
    function setLunaAddress(address newAddress) external onlyOwner {
        lunaAddress = newAddress;
    }
    function setSwapAndLiquify(bool _state, uint _intervalSecondsForSwap, uint _minimumTokensBeforeSwap, uint _tokensToSwap) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        intervalSecondsForSwap = _intervalSecondsForSwap;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap*10**decimals();
        tokensToSwap = _tokensToSwap*10**decimals();
        require(tokensToSwap <= minimumTokensBeforeSwap,"You cannot swap more then the minimum amount");
        require(tokensToSwap <= totalSupply() / 100,"token to swap limited to 1% supply");
    }
    function setSwapSend(bool _developer, bool _liq, bool _burn) external onlyOwner {
        developerSwapSendActive = _developer;
        LiqSwapSendActive = _liq;
        marketingSwapSendActive = _burn;
    }
    function setMultiBlock(bool _state) external onlyOwner {
        blockMultiBuys = _state;
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liqWallet,
            block.timestamp
        );
    }
    function setFeesDetails(bool _feeStatus, bool _buyFeeStatus, bool _sellFeeStatus) external onlyOwner {
        feeStatus = _feeStatus;
        buyFeeStatus = _buyFeeStatus;
        sellFeeStatus = _sellFeeStatus;
    }
    function setMaxTxAmount(uint _buy, uint _sell) external onlyOwner {
        maxBuyTxAmount = _buy * 10** decimals();
        maxSellTxAmount = _sell * 10 ** decimals();
        require(maxBuyTxAmount >= totalSupply() / 100000,"maxBuyTxAmount should be at least 0.001% of total supply.");
        require(maxSellTxAmount >= totalSupply() / 100000,"maxSellTxAmount should be at least 0.001% of total supply.");
    }
    function setBuySecondLimits(uint buy) external onlyOwner {
        buySecondsLimit = buy;
    }
    function activateMarket(bool active) external onlyOwner {
        require(marketActive == false);
        marketActive = active;
        if (marketActive) {
            marketActiveAt = block.timestamp;
        }
    }
    function editLimits(bool buy, bool sell) external onlyOwner {
        limitSells = sell;
        limitBuys = buy;
    }
    function setMinimumWeiForTokenomics(uint _value) external onlyOwner {
        minimumWeiForTokenomics = _value;
    }

    function editPreMarketUser(address _address, bool active) external onlyOwner {
        premarketUser[_address] = active;
    }
    
    function transferForeignToken(address _token, address _to, uint256 _value) external onlyOwner returns(bool _sent){
        if(_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        }
        _sent = IERC20(_token).transfer(_to, _value);
    }
   
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
    function edit_excludeFromFees(address account, bool excluded) public onlyOwner {
        excludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            excludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setDeveloperWallet(address payable wallet) external onlyOwner{
        developerWallet = wallet;
    }
    function setMaxWallet(bool state, uint max) public onlyOwner {
        maxWallet = state;
        maxWalletAmount = max * 10** decimals();
        require(maxWalletAmount >= totalSupply() / 100,"max wallet min amount: 1%");
    }
    function editExcludedFromMaxWallet(address user, bool state) external onlyOwner {
        excludedFromMaxWallet[user] = state;
        emit ExcludedFromMaxWalletChanged(user,state);
    }
    function editMultiExcludedFromMaxWallet(address[] memory _address, bool[] memory _states) external onlyOwner sameSize(_address.length,_states.length) {
        for(uint i=0; i< _states.length; i++){
            excludedFromMaxWallet[_address[i]] = _states[i];
            emit ExcludedFromMaxWalletChanged(_address[i],_states[i]);
        }
    }
    function setliqWallet(address newWallet) external onlyOwner{
        liqWallet = newWallet;
    }
    function setFees(uint256 _reward_buy, uint256 _liq_buy, uint256 _developer_buy,
        uint256 _reward_sell,uint256 _liq_sell,uint256 _developer_sell,
        uint256 _luna_burn_buy, uint256 _luna_burn_sell,uint256 _burn_buy, uint256 _burn_sell) external onlyOwner {
        WLUNARewardsBuyFee = _reward_buy;
        WLUNARewardsSellFee = _reward_sell;
        WLUNABurnBuyFee = _luna_burn_buy;
        WLUNABurnSellFee = _luna_burn_sell;
        marketingBuyFee = _burn_buy;
        marketingSellFee = _burn_sell;
        liqBuyFee  = _liq_buy;
        liqSellFee  = _liq_sell;
        developerBuyFee = _developer_buy;
        developerSellFee = _developer_sell;
        totalBuyFees = WLUNARewardsBuyFee.add(developerBuyFee).add(liqBuyFee).add(marketingBuyFee).add(WLUNABurnBuyFee);
        totalSellFees = WLUNARewardsSellFee.add(developerSellFee).add(liqSellFee).add(marketingSellFee).add(WLUNABurnSellFee);
        totalBuyFees > 0 ? buyFeeStatus = true : buyFeeStatus = false;
        totalSellFees > 0 ? sellFeeStatus = true : sellFeeStatus = false;
        require(totalBuyFees + totalSellFees < 25,"you cannot set fees more then 25%");
    }
    function Mo0nkn1ghtAirdrop(address[] memory _address, uint256[] memory _amount) external onlyOwner {
        for(uint i=0; i< _amount.length; i++){
            address adr = _address[i];
            uint amnt = _amount[i] *10**decimals();
            super._transfer(owner(), adr, amnt);
            try _lunaDividendTracker.setBalance(payable(adr), balanceOf(adr)) {} catch {}
        } 
    }
    function swapTokens(uint256 minTknBfSwap) private {
        isInternalTransaction = true;
        uint256 LUNABalance = WLUNARewardsSellFee * minTknBfSwap / 100;  
        uint256 marketingPart = marketingSellFee * minTknBfSwap / 100;
        uint256 liqPart = (liqSellFee * minTknBfSwap / 100)/2;
        uint256 swapBalance = minTknBfSwap - LUNABalance - marketingPart - (liqPart);

        swapTokensForETH(swapBalance);
        super._transfer(address(this), marketingWallet, marketingPart);
        uint256 balancez = address(this).balance;

        if(developerSwapSendActive && developerSellFee > 0) {
            uint256 developerEth = balancez.mul(developerSellFee).div(totalSellFees);
            (bool success,) = address(developerWallet).call{value: developerEth}("");
            if(success) {emit DeveloperFeeCollected(developerEth);}
            balancez -= developerEth;
        }
        if(marketingSwapSendActive  && WLUNABurnSellFee > 0) {
            uint256 marketingEth = balancez.mul(WLUNABurnSellFee).div(totalSellFees);
            (bool success,) = address(marketingWallet).call{value: marketingEth}("");
            if(success) {emit MarketingFeeCollected(marketingEth);}
            balancez -= marketingEth;
        }
        if(LiqSwapSendActive){
            uint256 liqEth = balancez.mul(liqSellFee).div(totalSellFees);
            if(liqEth > 5) { // failsafe if addLiq is too low
                addLiquidity(liqPart, liqEth);
                balancez -= liqEth;
            }
        }
        if(ProcessDividendStatus){
            if(balancez > 10000000000) {// 0,00000001 ETH
                swapETHforLuna(balancez);
                uint256 DividendsPart = IERC20(_lunaDividendToken).balanceOf(address(this));
                transferDividends(_lunaDividendToken, address(_lunaDividendTracker), _lunaDividendTracker, DividendsPart);
                }
        }
        isInternalTransaction = false;
    } 
  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    _lunaDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
        excludedFromMaxWallet[_partnerOrExchangeAddress] = true;
  	}
  	function updateDeveloperWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != developerWallet, "Luna: The developer wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit DeveloperWalletUpdated(developerWallet, _newWallet);
  	    developerWallet = _newWallet;
  	}
    function updateLiqWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != liqWallet, "Luna: The liquidity Wallet is already this address");
        excludeFromFees(_newWallet, true);
  	    liqWallet = _newWallet;
  	}
    function setAuthOnDividends(address account) public onlyOwner {
        _lunaDividendTracker.setAuth(account);
    }
    function set_LUNADividendEnabled(bool _enabled) external onlyOwner {
        _lunaDividendEnabled = _enabled;
    } 
    function update_lunaDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(_lunaDividendTracker), "Luna: The dividend tracker already has that address");
        _LUNADividendTracker new_lunaDividendTracker = _LUNADividendTracker(payable(newAddress));
        require(new_lunaDividendTracker.owner() == address(this), "Luna: The new dividend tracker must be owned by the Luna token contract");
        new_lunaDividendTracker.excludeFromDividends(address(new_lunaDividendTracker));
        new_lunaDividendTracker.excludeFromDividends(address(this));
        new_lunaDividendTracker.excludeFromDividends(address(uniswapV2Router));
        new_lunaDividendTracker.excludeFromDividends(address(deadWallet));
        emit Update_lunaDividendTracker(newAddress, address(_lunaDividendTracker));
        _lunaDividendTracker = new_lunaDividendTracker;
    }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "Luna: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        excludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
    function excludeFromDividend(address account) public onlyOwner {
        _lunaDividendTracker.excludeFromDividends(address(account));
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Luna: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Luna: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            _lunaDividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "Luna: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        _lunaDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        _lunaDividendTracker.updateClaimWait(claimWait);

    }
    function getLUNAClaimWait() external view returns(uint256) {
        return _lunaDividendTracker.claimWait();
    }
    function getTotal_LUNADividendsDistributed() external view returns (uint256) {
        return _lunaDividendTracker.totalDividendsDistributed();
    }
    function withdrawable_LUNADividendOf(address account) external view returns(uint256) {
    	return _lunaDividendTracker.withdrawableDividendOf(account);
  	}
	function _lunaDividendTokenBalanceOf(address account) external view returns (uint256) {
		return _lunaDividendTracker.balanceOf(account);
	}
    function getAccount_LUNADividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return _lunaDividendTracker.getAccount(account);
    }
	function getAccount_LUNADividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return _lunaDividendTracker.getAccountAtIndex(index);
    }
	function processDividendTracker(uint256 gas) public onlyOwner {
		(uint256 lunaIterations, uint256 lunaClaims, uint256 lunaLastProcessedIndex) = _lunaDividendTracker.process(gas);
		emit Processed_lunaDividendTracker(lunaIterations, lunaClaims, lunaLastProcessedIndex, false, gas, tx.origin);
	
    }
  	function update_LUNADividendToken(address _newContract, uint gas) external onlyOwner {
        _lunaDividendTracker.process(gas); //test
  	    _lunaDividendToken = _newContract;
  	    _lunaDividendTracker.setDividendTokenAddress(_newContract);
  	}
    function claim() external {
		_lunaDividendTracker.processAccount(payable(msg.sender), false);
		
    }
    function getLast_LUNADividendProcessedIndex() external view returns(uint256) {
    	return _lunaDividendTracker.getLastProcessedIndex();
    }
 
    
 
    function getNumberOf_LUNADividendTokenHolders() external view returns(uint256) {
        return _lunaDividendTracker.getNumberOfTokenHolders();
    }
 
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
    //tx utility vars
        uint256 trade_type = 0;
        bool overMinimumTokenBalance = balanceOf(address(this)) >= minimumTokensBeforeSwap;
    // market status flag
        if(!marketActive) {
            require(premarketUser[from],"cannot trade before the market opening");
        }
    // normal transaction
        if(!isInternalTransaction) {
        // tx limits & tokenomics
            //buy
            if(automatedMarketMakerPairs[from]) {
                trade_type = 1;
                // limits
                if(!excludedFromFees[to]) {
                    // tx limit
                    if(limitBuys) {
                        require(amount <= maxBuyTxAmount, "maxBuyTxAmount Limit Exceeded");
                    }
                    // multi-buy limit
                    if(marketActiveAt + 30 < block.timestamp) {
                        require(marketActiveAt + 7 < block.timestamp,"You cannot buy at launch.");
                        require(userLastTradeData[to].lastBuyTime + buySecondsLimit <= block.timestamp,"You cannot do multi-buy orders.");
                        userLastTradeData[to].lastBuyTime = block.timestamp;
                    }
                }
            }
            //sell
            else if(automatedMarketMakerPairs[to]) {
                trade_type = 2;
                // liquidity generator for tokenomics
                if (swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0 && sellFeeStatus) {
                    if (overMinimumTokenBalance && startTimeForSwap + intervalSecondsForSwap <= block.timestamp) {
                        startTimeForSwap = block.timestamp;
                        // sell to eth
                        swapTokens(tokensToSwap);
                    }
                }
                // limits
                if(!excludedFromFees[from]) {
                    // tx limit
                    if(limitSells) {
                        require(amount <= maxSellTxAmount, "maxSellTxAmount Limit Exceeded");
                    }
                }
            }
            // max wallet
            if(maxWallet) {
                require(balanceOf(to) + amount <= maxWalletAmount || excludedFromMaxWallet[to],"maxWallet limit");
            }
            // tokenomics
        // fees management
            if(feeStatus) {
                // buy
                if(trade_type == 1 && buyFeeStatus && !excludedFromFees[to]) {
                	uint txFees = amount * totalBuyFees / 100;
                	amount -= txFees;
                    uint256 marketingFees = txFees * marketingBuyFee / totalBuyFees;
                    super._transfer(from, address(this), txFees);
                    super._transfer(address(this), deadWallet, marketingFees);
                }
                //sell
                else if(trade_type == 2 && sellFeeStatus && !excludedFromFees[from]) {
                	uint txFees = amount * totalSellFees / 100;
                	amount -= txFees;
                    uint256 marketingFees = txFees * marketingSellFee / totalSellFees;
                    super._transfer(from, address(this), txFees);
                    super._transfer(address(this), deadWallet, marketingFees);
                }
                
            }
        }
        // transfer tokens
        super._transfer(from, to, amount);
        //set dividends
        try _lunaDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try _lunaDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        // auto-claims one time per transaction
        if(!isInternalTransaction && ProcessDividendStatus) {
	    	uint256 gas = gasForProcessing;
	    	try _lunaDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit Processed_lunaDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} catch {}
        }
    }

 
    function swapTokensForETH(uint256 tokenAmount) private {
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
    function swapETHforLuna(uint256 ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _lunaDividendToken;
        uniswapV2Router.swapExactETHForTokens{value: ethAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);
        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }
}