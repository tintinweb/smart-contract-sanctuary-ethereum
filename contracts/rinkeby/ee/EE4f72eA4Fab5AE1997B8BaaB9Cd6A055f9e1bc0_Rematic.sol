// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IERC20Upgradeable {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity); 
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity); 
    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB); 
    function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountToken, uint amountETH); 
    function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountA, uint amountB); 
    function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountToken, uint amountETH); 
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
 
    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }
 
    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }
 
    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }
 
 
 
    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }
 
    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
 
    function remove(Map storage map, address key) public {
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

library AddressUpgradeable {
    
    function isContract(address account) internal view returns (bool) {
        
        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Initializable {
    
    bool private _initialized;

  
    bool private _initializing;

    
    modifier initializer() {
      
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    uint256[49] private __gap;
}

contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract Rematic is ERC20Upgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    IWETH eth;
 
    address public token1DividendToken;
    address public token2DividendToken;
    address public deadAddress;

    bool private swapping;
    bool public tradingIsEnabled;
    bool public swapEnabled;
 
    Token1DividendTracker public token1DividendTracker;
    Token2DividendTracker public token2DividendTracker;
    
    uint256 public swapTokensAtAmount;
 
    uint256 public liquidityFee;
    uint256 public token1DividendRewardsFee;
    uint256 public token2DividendRewardsFee;
    uint256 public buybackFee;
    uint256 public teamFee;
    uint256 public flexFee;
    uint256 public totalFees;
    uint256 public gasForProcessing;

    address public teamWallet;
    address public flexWallet;
    address public presaleAddress;

    // transaction timelock
    mapping(address => uint) public transactionLockTimeSell;
    mapping(address => uint) public transactionLockTimeBuy;
    uint public timeBetweenSells;
    uint public timeBetweenBuys;

    uint public bnbValueForBuyBurn;
    uint public accumulatedBuybackBNB;

    mapping(address => bool) private _excludedFromAntiWhale;
    uint256 public maxTransferAmountRate;

    mapping (address => bool) private isExcludedFromFees;

    mapping (address => bool) public automatedMarketMakerPairs;

    mapping(address => bool) public isStakingContract;

    event Updatetoken1DividendTracker(address indexed newAddress, address indexed oldAddress);
    event Updatetoken2DividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event token1DividendEnabledUpdated(bool enabled);
    event token2DividendEnabledUpdated(bool enabled);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
 
    event SendDividends(
    	uint256 amount
    );
 
    event Processedtoken1DividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
 
    event Processedtoken2DividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    address private _newOwner;

    function __Rematic_init() internal onlyInitializing {
        __Rematic_init_unchained();
    }

    function __Rematic_init_unchained() internal onlyInitializing {
        __ERC20_init("Rematic", "RMTX");
        __Ownable_init();

        eth = IWETH(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
        deadAddress = 0x000000000000000000000000000000000000dEaD;
        tradingIsEnabled = false;
        swapEnabled = true;

        swapTokensAtAmount = 200_000_000_000 * (10**18);

        liquidityFee = 1;
        token1DividendRewardsFee = 8;
        token2DividendRewardsFee = 2;
        buybackFee = 2;
        teamFee = 2;
        flexFee = 0;
        totalFees = token1DividendRewardsFee + flexFee + token2DividendRewardsFee + liquidityFee + buybackFee + teamFee;
        gasForProcessing = 600000;

        teamWallet = 0x518e8044928AE2d88d33F1ecf56693B42a0023ee;
        flexWallet = 0x9AB1d93C27Ba186e6a7Fc1DfDAd308574027F95e;

        timeBetweenSells = 100; // seconds
        timeBetweenBuys = 100;

        bnbValueForBuyBurn = 1000000000000000;
        accumulatedBuybackBNB = 0;

        maxTransferAmountRate = 50;

        _newOwner = 0x7aE4BC98606AE33d3D464Cd0252Bf8bB0939DAc8;
        
    	token1DividendTracker = new Token1DividendTracker();
    	token2DividendTracker = new Token2DividendTracker();

    	token1DividendToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
        token2DividendToken = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
 
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
 
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
 
        excludeFromDividend(address(token1DividendTracker), true);
        excludeFromDividend(address(token2DividendTracker), true);
        excludeFromDividend(address(this), true);
        excludeFromDividend(address(_uniswapV2Router), true);
        excludeFromDividend(deadAddress, true);
 
        // exclude from paying fees
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(_newOwner, true);

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[deadAddress] = true;
 
        setAuthOnDividends(_newOwner);
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(_newOwner, 1_000_000_000_000_000 * (10**18));
    }
 
    receive() external payable {}

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0 && !automatedMarketMakerPairs[sender] ) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "AntiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(1000);
    }

    function setMaxTransfertAmountRate(uint256 value) public onlyOwner {
        require(value > 0, "fail");
        maxTransferAmountRate = value;
    }

    function excludeFromAntiwhale(address account, bool excluded) public onlyOwner {
        _excludedFromAntiWhale[account] = excluded;
    }

    function isExcludedFromAntiwhale(address ac) public view returns(bool) {
        return _excludedFromAntiWhale[ac];
    }

    function changeTimeSells(uint _value) public onlyOwner {
        require(_value <= 60 * 60 * 60, "Max 1 hour");
        timeBetweenSells = _value;
    }

    function changeTimeBuys(uint _value) public onlyOwner {
        require(_value <= 60 * 60 * 60, "Max 1 hour");
        timeBetweenBuys = _value;
    }

    function setExcludeStakingContract(address acc, bool value) public onlyOwner{
        isStakingContract[acc] = value;
        isExcludedFromFees[acc] = true;
    }

  	function whitelistPreSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        token1DividendTracker.excludeFromDividends(_presaleAddress, true);
        token2DividendTracker.excludeFromDividends(_presaleAddress, true);
        excludeFromFees(_presaleAddress, true);
 
        token1DividendTracker.excludeFromDividends(_routerAddress, true);
        token2DividendTracker.excludeFromDividends(_routerAddress, true);
        excludeFromFees(_routerAddress, true);
  	}
 
  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    token1DividendTracker.excludeFromDividends(_partnerOrExchangeAddress, true);
        token2DividendTracker.excludeFromDividends(_partnerOrExchangeAddress, true);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}
 
  
  	function updatetoken2DividendToken(address _newContract) external onlyOwner {
  	    token2DividendToken = _newContract;
  	    token2DividendTracker.setDividendTokenAddress(_newContract);
  	}
 
  	function updatetoken1DividendToken(address _newContract) external onlyOwner {
  	    token1DividendToken = _newContract;
  	    token1DividendTracker.setDividendTokenAddress(_newContract);
  	}

  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != teamWallet, "Rematic: The marketing wallet is already this address");
  	    teamWallet = _newWallet;
  	}
    
    function updateFlexWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != flexWallet, "Rematic: The marketing wallet is already this address");
  	    flexWallet = _newWallet;
  	}
 
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
  	    swapTokensAtAmount = _swapAmount;
  	}
 
    function setTradingIsEnabled() external onlyOwner {
        tradingIsEnabled = true;
    }
 
    function setAuthOnDividends(address account) public onlyOwner{
        token1DividendTracker.setAuth(account);
        token2DividendTracker.setAuth(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        require(swapEnabled != _enabled, "Can't set flag to same status");
        swapEnabled = _enabled;
    }

    function updatetoken1DividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(token1DividendTracker), "Rematic: The dividend tracker already has that address");
 
        Token1DividendTracker newtoken1DividendTracker = Token1DividendTracker(payable(newAddress));
 
        require(newtoken1DividendTracker.owner() == address(this), "Rematic: The new dividend tracker must be owned by the Rematic token contract");
 
        newtoken1DividendTracker.excludeFromDividends(address(newtoken1DividendTracker), true);
        newtoken1DividendTracker.excludeFromDividends(address(this), true);
        newtoken1DividendTracker.excludeFromDividends(address(uniswapV2Router), true);
        newtoken1DividendTracker.excludeFromDividends(address(deadAddress), true);
 
        emit Updatetoken1DividendTracker(newAddress, address(token1DividendTracker));
 
        token1DividendTracker = newtoken1DividendTracker;
    }
 
    function updatetoken2DividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(token2DividendTracker), "Rematic: The dividend tracker already has that address");
 
       Token2DividendTracker newtoken2DividendTracker = Token2DividendTracker(payable(newAddress));
 
        require(newtoken2DividendTracker.owner() == address(this), "Rematic: The new dividend tracker must be owned by the Rematic token contract");
 
        newtoken2DividendTracker.excludeFromDividends(address(newtoken2DividendTracker), true);
        newtoken2DividendTracker.excludeFromDividends(address(this), true);
        newtoken2DividendTracker.excludeFromDividends(address(uniswapV2Router), true);
        newtoken2DividendTracker.excludeFromDividends(address(deadAddress), true);
 
        emit Updatetoken2DividendTracker(newAddress, address(token2DividendTracker));
 
        token2DividendTracker = newtoken2DividendTracker;
    }
 
    function updateToken1DividendRewardFee(uint8 newFee) external onlyOwner {
        token1DividendRewardsFee = newFee;
        totalFees = token1DividendRewardsFee.add(flexFee).add(token2DividendRewardsFee).add(liquidityFee).add(buybackFee).add(teamFee);
        require(totalFees <= 25, "Total fees cannot be higher than 25%");
    }
 
    function updateToken2DividendRewardFee(uint8 newFee) external onlyOwner {
        token2DividendRewardsFee = newFee;
        totalFees = token2DividendRewardsFee.add(token1DividendRewardsFee).add(flexFee).add(liquidityFee).add(buybackFee).add(teamFee);
        require(totalFees <= 25, "Total fees cannot be higher than 25%");
    }
 
    function updateFlexFee(uint8 newFee) external onlyOwner {
        flexFee = newFee;
        totalFees = flexFee.add(token1DividendRewardsFee).add(token2DividendRewardsFee).add(liquidityFee).add(buybackFee).add(teamFee);
        require(totalFees <= 25, "Total fees cannot be higher than 25%");
    }
 
    function updateLiquidityFee(uint8 newFee) external onlyOwner {
        liquidityFee = newFee;
        totalFees = flexFee.add(token1DividendRewardsFee).add(token2DividendRewardsFee).add(liquidityFee).add(buybackFee).add(teamFee);
        require(totalFees <= 25, "Total fees cannot be higher than 25%");
    }

    function updateBuybackFee(uint fee) external onlyOwner {
        buybackFee = fee;
        totalFees = flexFee.add(token1DividendRewardsFee).add(token2DividendRewardsFee).add(liquidityFee).add(buybackFee).add(teamFee);
        require(totalFees <= 25, "Total fees cannot be higher than 25%");

    }
     function updateTeamFee(uint fee) external onlyOwner {
        teamFee = fee;
        totalFees = flexFee.add(token1DividendRewardsFee).add(token2DividendRewardsFee).add(liquidityFee).add(buybackFee).add(teamFee);
        require(totalFees <= 25, "Total fees cannot be higher than 25%");

    }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "Rematic: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
 
    function excludeFromDividend(address account, bool exclude) public onlyOwner {
        token1DividendTracker.excludeFromDividends(address(account), exclude);
        token2DividendTracker.excludeFromDividends(address(account), exclude);
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
 
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Rematic: The PanadaSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Rematic: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
 
        if(value) {
            token1DividendTracker.excludeFromDividends(pair, true);
            token2DividendTracker.excludeFromDividends(pair, true);
        }
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "Rematic: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
 
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        token1DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        token2DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }
 
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        token1DividendTracker.updateClaimWait(claimWait);
        token2DividendTracker.updateClaimWait(claimWait);
    }
 
    function gettoken1ClaimWait() external view returns(uint256) {
        return token1DividendTracker.claimWait();
    }
 
    function gettoken2ClaimWait() external view returns(uint256) {
        return token2DividendTracker.claimWait();
    }
 
    function getTotaltoken1DividendsDistributed() external view returns (uint256) {
        return token1DividendTracker.totalDividendsDistributed();
    }
 
    function getTotaltoken2DividendsDistributed() external view returns (uint256) {
        return token2DividendTracker.totalDividendsDistributed();
    }
 
    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }
 
    function withdrawabletoken1DividendOf(address account) external view returns(uint256) {
    	return token1DividendTracker.withdrawableDividendOf(account);
  	}
 
  	function withdrawabletoken2DividendOf(address account) external view returns(uint256) {
    	return token2DividendTracker.withdrawableDividendOf(account);
  	}
 
	function token1DividendTokenBalanceOf(address account) external view returns (uint256) {
		return token1DividendTracker.balanceOf(account);
	}
 
	function token2DividendTokenBalanceOf(address account) external view returns (uint256) {
		return token2DividendTracker.balanceOf(account);
	}
 
    function getAccounttoken1DividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return token1DividendTracker.getAccount(account);
    }
 
    function getAccounttoken2DividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return token2DividendTracker.getAccount(account);
    }
 
	function getAccounttoken1DividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return token1DividendTracker.getAccountAtIndex(index);
    }
 
    function getAccounttoken2DividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return token2DividendTracker.getAccountAtIndex(index);
    }
 
	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 token1Iterations, uint256 token1Claims, uint256 token1LastProcessedIndex) = token1DividendTracker.process(gas);
		emit Processedtoken1DividendTracker(token1Iterations, token1Claims, token1LastProcessedIndex, false, gas, tx.origin);
 
		(uint256 token2Iterations, uint256 token2Claims, uint256 token2LastProcessedIndex) = token2DividendTracker.process(gas);
		emit Processedtoken2DividendTracker(token2Iterations, token2Claims, token2LastProcessedIndex, false, gas, tx.origin);
    }
 
    function claim() external {
		token1DividendTracker.processAccount(payable(msg.sender), false);
		token2DividendTracker.processAccount(payable(msg.sender), false);
    }
    
    function getLasttoken1DividendProcessedIndex() external view returns(uint256) {
    	return token1DividendTracker.getLastProcessedIndex();
    }
 
    function getLasttoken2DividendProcessedIndex() external view returns(uint256) {
    	return token2DividendTracker.getLastProcessedIndex();
    }
 
    function getNumberOftoken1DividendTokenHolders() external view returns(uint256) {
        return token1DividendTracker.getNumberOfTokenHolders();
    }
 
    function getNumberOftoken2DividendTokenHolders() external view returns(uint256) {
        return token2DividendTracker.getNumberOfTokenHolders();
    }
    
    function startBuyback(uint valBNB) public payable onlyOwner {
        require(msg.value >= valBNB, "bnb invalid");
        swapETHForTokens(msg.value);
    }
    
    function swapETHForTokens(uint256 bnbAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, // accept any amount of ETH
            path,
            deadAddress,
            block.timestamp
        );
 
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override antiWhale(from,to,amount){
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Rematic: Trading has not started yet");
 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
 
        if (!swapping && 
            canSwap && 
            swapEnabled && 
            from != uniswapV2Pair &&
            totalFees != 0
        )   {
            swapping = true;
            
            uint256 liqTokensToAdd = contractTokenBalance.mul(liquidityFee.div(2)).div(totalFees);
            contractTokenBalance -= liqTokensToAdd;
            
            uint initBalance = address(this).balance;
            swapTokensForBNB(contractTokenBalance);
            uint finalBalance = address(this).balance.sub(initBalance);
            uint bnbFee = totalFees.sub(liquidityFee.div(2));
            
            if (flexFee > 0) {
                uint256 flexBNB = finalBalance.div(bnbFee).mul(flexFee);
                payable(flexWallet).transfer(flexBNB);
            }

            if(teamFee > 0) {
                uint256 teamBNB = finalBalance.div(bnbFee).mul(teamFee);
                payable(teamWallet).transfer(teamBNB);
            }

            if(buybackFee > 0) {
                uint256 buybackBNB = finalBalance.div(bnbFee).mul(buybackFee);
                accumulatedBuybackBNB += buybackBNB;
                if (accumulatedBuybackBNB > bnbValueForBuyBurn) {
                    buyBackAndBurn(accumulatedBuybackBNB);
                    accumulatedBuybackBNB = 0;
                }
            }

            if(liquidityFee > 0) {
                uint256 liqBNB = finalBalance.mul(liquidityFee.div(2)).div(bnbFee);
                addLiquidity(liqTokensToAdd, liqBNB);
            }
 
            if (token1DividendRewardsFee > 0) {
                uint256 token1Tokens = finalBalance.div(bnbFee).mul(token1DividendRewardsFee);
                swapAndSendtoken1Dividends(token1Tokens);
            }
 
            if (token2DividendRewardsFee > 0) {
                uint256 token2Tokens = finalBalance.div(bnbFee).mul(token2DividendRewardsFee);
                swapAndSendtoken2Dividends(token2Tokens);
            }
 
            swapping = false;
        }
 
        bool takeFee = tradingIsEnabled && !swapping;

        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            if(to == uniswapV2Pair) {
                //sell
                if(timeBetweenSells > 0 ){
                    require(block.timestamp - transactionLockTimeSell[from] > timeBetweenSells, "Wait before Sell!" );
                    transactionLockTimeSell[from] = block.timestamp;
                }
                
            }
            if (from == uniswapV2Pair) {
                if (timeBetweenBuys > 0 ) {
                    require( block.timestamp - transactionLockTimeBuy[to] > timeBetweenBuys, "Wait before Buy!");
                    transactionLockTimeBuy[to] = block.timestamp;
                }
            }
        	uint256 fees = amount.mul(totalFees).div(100);

        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }
 
        super._transfer(from, to, amount);
        if(!isStakingContract[from] && !isStakingContract[to]) {
            try token1DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
            try token2DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
            try token1DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
            try token2DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        }
        if(!swapping) {
	    	uint256 gas = gasForProcessing;
 
	    	try token1DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit Processedtoken1DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
 
	    	}
 
	    	try token2DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit Processedtoken2DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
 
	    	}
        }
    }

    function setBnbValueForBuyBurn(uint value) public onlyOwner {
        bnbValueForBuyBurn = value;
    }

    function buyBackAndBurn(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
        0, 
        path, 
        deadAddress, 
        block.timestamp);
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
 
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }
 
    function swapTokensForBNB(uint256 tokenAmount) private {
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
 
    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        if(_dividendAddress != address(0)) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _dividendAddress;
 

 
        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _tokenAmount}(
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp
        );
        } 
    }
 
    function swapAndSendtoken1Dividends(uint256 tokens) private {
        if (token1DividendToken != address(0)) {
          uint init = IERC20Upgradeable(token1DividendToken).balanceOf(address(this));
        swapTokensForDividendToken(tokens, address(this), token1DividendToken);
        uint256 token1Dividends = IERC20Upgradeable(token1DividendToken).balanceOf(address(this)) - init;
        transferDividends(token1DividendToken, address(token1DividendTracker), token1DividendTracker, token1Dividends);
        } else {
              (bool success,) = address(token1DividendTracker).call{value: tokens}("");
 
                if(success) {
                    emit SendDividends(tokens);
                }
        }
    }
 
    function swapAndSendtoken2Dividends(uint256 tokens) private {
        if (token2DividendToken != address(0)) {
              uint init = IERC20Upgradeable(token2DividendToken).balanceOf(address(this));
            swapTokensForDividendToken(tokens, address(this), token2DividendToken);
            uint256 token2Dividends = IERC20Upgradeable(token2DividendToken).balanceOf(address(this)) - init;

            transferDividends(token2DividendToken, address(token2DividendTracker), token2DividendTracker, token2Dividends);
        } else {
          
            (bool success,) = address(token2DividendTracker).call{value: tokens}("");
 
                if(success) {
                    emit SendDividends(tokens);
                }
        }
    }
 
    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private {
        bool success = IERC20Upgradeable(dividendToken).transfer(dividendTracker, amount);
 
        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20Upgradeable ERC20token = IERC20Upgradeable(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }
}

contract DividendPayingToken is ERC20Upgradeable, OwnableUpgradeable, IDividendPayingToken, IDividendPayingTokenOptional {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
 
  uint256 constant internal magnitude = 2**128;
 
  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
 
  address public dividendToken;
 
 
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  mapping(address => bool) _isAuth;
 
  uint256 public totalDividendsDistributed;
 
  modifier onlyAuth() {
    require(_isAuth[msg.sender], "Auth: caller is not the authorized");
    _;
  }

  function __DividendPayingToken_init(string memory _name, string memory _symbol, address _token) internal onlyInitializing {
        __DividendPayingToken_init_unchained(_name,  _symbol, _token);
    }

    function __DividendPayingToken_init_unchained(string memory _name, string memory _symbol, address _token) internal onlyInitializing {
        __ERC20_init(_name, _symbol);
        __Ownable_init();

        dividendToken = _token;
        _isAuth[msg.sender] = true;
    }
 
  function setAuth(address account) external onlyAuth{
      _isAuth[account] = true;
  }

    receive() payable external {
        if(dividendToken == address(0)) {
            distributeDividends(msg.value);
        }
    }
 
  function distributeDividends(uint256 amount) public onlyOwner {
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
 
  function setDividendTokenAddress(address newToken) external virtual onlyAuth{
      dividendToken = newToken;
  }
 
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      if (address(dividendToken) != address(0)) {
        bool success = IERC20Upgradeable(dividendToken).transfer(user, _withdrawableDividend);
    
        if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
        }
      } else {
          (bool success,) = payable(user).call{value: _withdrawableDividend, gas: 5000}("");
          if (!success) {
              withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
              return 0;
          }
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

contract Token1DividendTracker is DividendPayingToken {
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

    function __Token1DividendTracker_init() internal onlyInitializing {
        __Token1DividendTracker_init_unchained();
    }

    function __Token1DividendTracker_init_unchained() internal onlyInitializing {
        __DividendPayingToken_init("Rematic_Token1_Dividend_Tracker", "Rematic_Token1_Dividend_Tracker", 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    	
        claimWait = 3600;
        minimumTokenBalanceForDividends = 5_000_000_000 * (10**18); //must hold 2000000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "Rematic_Token1_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() pure public override {
        require(false, "Rematic_Token1_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Rematic contract.");
    }
 
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
 
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
 
    function excludeFromDividends(address account, bool exclude) external onlyOwner {
      if (exclude = true) {
            require(!excludedFromDividends[account]);
          excludedFromDividends[account] = true;
 
          _setBalance(account, 0);
          tokenHoldersMap.remove(account);
 
          emit ExcludeFromDividends(account);
        } else {
            require(excludedFromDividends[account]);
            excludedFromDividends[account] = false;
                if(balanceOf(account) >= minimumTokenBalanceForDividends) {
                _setBalance(account, balanceOf(account));
    		    tokenHoldersMap.set(account, balanceOf(account));
    	    }
        }
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Rematic_Token1_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Rematic_Token1_Dividend_Tracker: Cannot update claimWait to same value");
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
 
contract Token2DividendTracker is DividendPayingToken {
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

    function __Token2DividendTracker_init() internal onlyInitializing {
        __Token2DividendTracker_init_unchained();
    }

    function __Token2DividendTracker_init_unchained() internal onlyInitializing {
        __DividendPayingToken_init("Rematic_Token2_Dividend_Tracker", "Rematic_Token2_Dividend_Tracker", 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca);
    	
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 5_000_000_000 * (10**18); //must hold 2000000+ tokens
    }
 
    function _transfer(address, address, uint256) pure internal override {
        require(false, "Rematic_Token2_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() pure public override {
        require(false, "Rematic_Token2_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Rematic contract.");
    }
 
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
 
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
 
    function excludeFromDividends(address account, bool exclude) external onlyOwner {
      if (exclude = true) {
            require(!excludedFromDividends[account]);
          excludedFromDividends[account] = true;
 
          _setBalance(account, 0);
          tokenHoldersMap.remove(account);
 
          emit ExcludeFromDividends(account);
        } else {
            require(excludedFromDividends[account]);
            excludedFromDividends[account] = false;
                if(balanceOf(account) >= minimumTokenBalanceForDividends) {
                _setBalance(account, balanceOf(account));
    		    tokenHoldersMap.set(account, balanceOf(account));
    	    }
        }
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Rematic_Token2_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Rematic_Token2_Dividend_Tracker: Cannot update claimWait to same value");
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