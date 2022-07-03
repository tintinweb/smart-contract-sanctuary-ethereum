/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

   
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }


    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
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


library Address {
  
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock the token contract");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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


contract CD3FiToken is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    using Address for address;
    using SafeERC20 for IERC20;
    using IterableMapping for IterableMapping.Map;
    
    address immutable dead = 0x000000000000000000000000000000000000dEaD;
    address immutable zero = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    /* Dividend Trackers */
    uint256 public _tDividendTotal = 0;
    uint256 internal constant magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    uint256 public totalDividendsDistributed;
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait = 3600;
    uint256 public minimumTokenBalanceForDividends = 1 * 10**6;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    event DividendsDistributed(uint256 weiAmount);  
    event DividendWithdrawn(address indexed to, uint256 weiAmount);

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    /* Dividend end*/


    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    //Pancake Mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    //Pancake Testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3

    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //BUSD Mainnet : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    //BUSD Testnet : 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7

    address public rewardToken = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    
    uint256 private constant MAX = ~uint256(0);
    
    uint256 private _tFeeTotal;
    bool public isTaxBracketEnabled = true;

    string public constant _name ="mr";
    string public constant _symbol = "mr";
    uint8 private constant _decimals = 6;
    uint256 public _tTotal = 80_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public numTokensSellToAddToLiquidity = 100 * 10**_decimals;
    uint256 private buyBackUpperLimit = 1 * 10**18;
    
    uint256 private maxBracketTax = 10;                       // max bracket is holding 75%
    uint256 private taxBracketMultiplier = 25;
    uint256 private divider = 100;

    uint256 private _taxFee = 0;                           
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _rewardFee = 0;
    uint256 private _previousRewardFee = _rewardFee;
    
    uint256 private _stabilityFee = 0;
    uint256 private _previousStabilityFee = _stabilityFee;

    uint256 private _MarketingFee = 0;
    uint256 private _previousMarketingFee = _MarketingFee;

    uint256 private _buybackburnFee = 0;
    uint256 private _previousBuybackburnFee = _buybackburnFee;

    uint256 public AmountForReward;
    uint256 public AmountForStability;
    uint256 public AmountForMarketing;
    uint256 public AmountForBuyBackBurn;

    uint256 public lastTrigger;
    bool public stabilityEnabler = true;

    IUniswapV2Router02 public pcsV2Router;
    address public pcsV2Pair;

    address public MarketingWallet = address(0xe92d0a76B04D3d89fC199060a229D50e78355238);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;    
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    struct BuyFee{
        uint256 setTaxFee;
        uint256 setRewardFee;
        uint256 setStabilityFee;
        uint256 setMarketingFee;
        uint256 setBuyBackBurnFee;       
    }

    struct SellFee{
        uint256 setTaxFee;
        uint256 setRewardFee;
        uint256 setStabilityFee;
        uint256 setMarketingFee;
        uint256 setBuyBackBurnFee; 
    }

    BuyFee public buyFee;
    SellFee public sellFee;


    constructor ()  {       
        
        _rOwned[_msgSender()] = _rTotal;

        buyFee.setTaxFee = 30;
        buyFee.setRewardFee = 30;
        buyFee.setStabilityFee = 50;
        buyFee.setMarketingFee = 0;
        buyFee.setBuyBackBurnFee = 40;  

        sellFee.setTaxFee = 30;
        sellFee.setRewardFee = 30;
        sellFee.setStabilityFee = 50;
        sellFee.setMarketingFee = 30;
        sellFee.setBuyBackBurnFee = 40; 
                
        IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(router);
            // Create a uniswap pair for this new token
        pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory())
            .createPair(address(this), _pcsV2Router.WETH());

        // set the rest of the contract variables
        pcsV2Router = _pcsV2Router;
        
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0xdead)] = true;

        excludedFromDividends[address(this)] = true;
        excludedFromDividends[_msgSender()] = true;
        excludedFromDividends[address(pcsV2Router)] = true;
        excludedFromDividends[address(0xdead)] = true;
        excludedFromDividends[address(pcsV2Pair)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function updatePcsV2Router(address newAddress) public onlyOwner {
        require(
        newAddress != address(pcsV2Router),
        "The router already has that address"
        );
        IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(newAddress);
            // Create a uniswap pair for this new token
        pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory())
            .createPair(address(this), _pcsV2Router.WETH());

        // set the rest of the contract variables
        pcsV2Router = _pcsV2Router;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public returns(uint256) {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded from reward");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function excludeFromFee(address account) public  {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public  {
        _isExcludedFromFee[account] = false;
    }

    function setStabilizer(bool _status) public  {
        stabilityEnabler = _status;
    }

    function setBuyFeePercent(uint8 taxFee, uint8 buybackburnFee, uint8 stabilityFee, uint8 rewardFee) external onlyOwner() {   
        buyFee.setTaxFee = taxFee;
        buyFee.setRewardFee = rewardFee;
        buyFee.setStabilityFee = stabilityFee;
        buyFee.setBuyBackBurnFee = buybackburnFee;  
    }

    function setSellFeePercent(uint8 taxFee, uint8 buybackburnFee, uint8 marketingFee, uint8 stabilityFee, uint8 rewardFee) external onlyOwner() {
        sellFee.setTaxFee = taxFee;
        sellFee.setRewardFee = rewardFee;
        sellFee.setStabilityFee = stabilityFee;
        sellFee.setMarketingFee = marketingFee;
        sellFee.setBuyBackBurnFee = buybackburnFee; 
    }
    
    function buyBackUpperLimitAmount() public view returns (uint256) {
        return buyBackUpperLimit;
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setFeeWallet(address payable newFeeWallet) external onlyOwner {
        require(newFeeWallet != address(0), "ZERO ADDRESS");
        MarketingWallet = newFeeWallet;
    }

    function setMinimumTokenBalanceForDividends(uint256 _minimumTokenBalanceForDividends) external onlyOwner() {
        require(_minimumTokenBalanceForDividends >= 1 && _minimumTokenBalanceForDividends <= totalSupply().div(100),"err");
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }
    
    //to recieve ETH from pcsV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);

    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**3
        );
    }

    function setter(uint mTax, uint MB, uint Div) public {
        maxBracketTax = mTax;                    
        taxBracketMultiplier = MB;
        divider = Div;
    }

    function getCurrentTaxBracket(address _address)
    public
    view
    returns (uint256)
    {
        //gets the total balance of the user
        uint256 userTotal = balanceOf(_address);

        //calculate the percentage
        uint256 totalCap = (userTotal * (divider)) / (getTokensInLPCirculation());

        //calculate what is smaller, and use that
        uint256 _bracket = totalCap < maxBracketTax ? totalCap : maxBracketTax;

        //multiply the bracket with the multiplier
        _bracket *= taxBracketMultiplier;

        return _bracket;
    }

    function getTokensInLPCirculation() public view returns (uint256) {
        uint256 LPTotal;
        LPTotal += balanceOf(pcsV2Pair);
        return LPTotal;
    }

    function triggerLp(uint _amount) public view returns (bool) {
        uint256 LPTotal;
        LPTotal += balanceOf(pcsV2Pair);
        if(LPTotal == 0) return false;
        bool fire = _amount >= LPTotal.mul(5).div(100);
        return fire;
    }


    function calculateLiquidityFee(uint256 _amount) private returns (uint256) {

        AmountForReward += _amount.mul(_rewardFee).div(10**3);
        AmountForStability += _amount.mul(_stabilityFee).div(10**3);
        AmountForMarketing += _amount.mul(_MarketingFee).div(10**3);
        AmountForBuyBackBurn += _amount.mul(_buybackburnFee).div(10**3);

        return _amount.mul(_rewardFee + _stabilityFee + _MarketingFee + _buybackburnFee).div(
            10**3
        );
    }

    //marketing check
    
    function removeAllFee() private {
        if(_taxFee == 0 && _rewardFee == 0 && _stabilityFee == 0 && _buybackburnFee == 0 && _MarketingFee == 0) return;  //_MarketingFee == 0
        
        _previousTaxFee = _taxFee;
        _previousRewardFee = _rewardFee;
        _previousStabilityFee = _stabilityFee;
        _previousMarketingFee = _MarketingFee;
        _previousBuybackburnFee = _buybackburnFee;

        _taxFee = 0;
        _rewardFee = 0;
        _stabilityFee = 0;
        _MarketingFee = 0;
        _buybackburnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _rewardFee = _previousRewardFee;
        _stabilityFee = _previousStabilityFee;
        _MarketingFee = _previousMarketingFee;
        _buybackburnFee = _previousBuybackburnFee;
    }

    function setBuy () private {
        _taxFee = buyFee.setTaxFee;
        _rewardFee = buyFee.setRewardFee;
        _stabilityFee = buyFee.setStabilityFee;
        _MarketingFee = buyFee.setMarketingFee;
        _buybackburnFee = buyFee.setBuyBackBurnFee;
    }
    
    function setSell() private {
        _taxFee = sellFee.setTaxFee;
        _rewardFee = sellFee.setRewardFee;
        _stabilityFee = sellFee.setStabilityFee;
        _MarketingFee = sellFee.setMarketingFee;
        _buybackburnFee = sellFee.setBuyBackBurnFee;
    }

    function setDynamicTax(uint _addTax) private {   

        uint256 adder = _addTax.mul(250).div(1000);           
        
        _taxFee = sellFee.setTaxFee  + adder; 
        _rewardFee = sellFee.setRewardFee + adder;
        _stabilityFee = sellFee.setStabilityFee + adder;
        _MarketingFee = sellFee.setMarketingFee;
        _buybackburnFee = sellFee.setBuyBackBurnFee + adder;

    }

    bool a;
    bool b;
    bool c;
    bool d; 
    bool e;

    function seting(bool aa,bool bb,bool cc,bool dd, bool ee) public {
        a = aa;
        b=bb;
        c=cc;
        d=dd;
        e =ee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            !inSwapAndLiquify &&
            to == pcsV2Pair &&
            swapAndLiquifyEnabled
        ) {
            if(overMinTokenBalance){

                swapAndLiquify();
            }

            if(_rewardFee != 0 && a){
                uint256 gas = gasForProcessing;

                (uint256 iterations, uint256 claims, uint256 _lastProcessedIndex) = process(gas);
                emit ProcessedDividendTracker(iterations, claims, _lastProcessedIndex, true, gas, tx.origin);
            }
        }

        bool fire = triggerLp(amount);
        bool timer = block.timestamp >= (lastTrigger + 60 minutes);

        if((fire || timer) && stabilityEnabler) {
            stabilitySwap();
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        uint256 currentBalanceFrom = balanceOf(from);
        uint256 currentBalanceTo = balanceOf(to);

        _tokenTransfer(from,to,amount,takeFee);

        if(b) {
        setBalance(payable(from), balanceOf(from), currentBalanceFrom);
        setBalance(payable(to), balanceOf(to), currentBalanceTo);
        }
    }

    function swapForDividend(uint _token) private {
        uint256 initialBalance = IERC20(rewardToken).balanceOf(address(this));
        swapTokensForRewardToken(_token);
        uint256 newBalance = (IERC20(rewardToken).balanceOf(address(this))).sub(initialBalance);
        distributeDividends(newBalance);
        AmountForReward = AmountForReward.sub(_token);
    }

    function sendToMarketing(uint _token) private {
        uint currentBalance = balanceOf(MarketingWallet);
        _tokenTransferNoFee(address(this), MarketingWallet, _token);                
        setBalance(payable(MarketingWallet), balanceOf(MarketingWallet), currentBalance);
        AmountForMarketing = AmountForMarketing.sub(_token);
    }

    function swapBNBandBurn(uint _token) private {
        uint initalBalance = address(this).balance;
        swapTokensForBNB(_token);
        uint RecieveBalance = address(this).balance.sub(initalBalance);
        swapBNBForTokensBurn(RecieveBalance);
        AmountForBuyBackBurn = AmountForBuyBackBurn.sub(_token);
    }

    function swapAndLiquify() private lockTheSwap {
       
        if(AmountForReward > 0 && c) swapForDividend(AmountForReward);
        if(AmountForMarketing > 0 && d) sendToMarketing(AmountForMarketing);
        if(AmountForBuyBackBurn > 0 && e) swapBNBandBurn(AmountForBuyBackBurn);

    }

    function stabilitySwap() public {
        if(AmountForStability > 0) triggerStability(AmountForStability);
    }


    function triggerStability(uint _token) private lockTheSwap {
        if(_token == 0) return;

        uint256 splithalf = _token.div(2);
        uint256 otherhalf = _token.sub(splithalf);

        // uint256 initialBnB = address(this).balance;
        // swapTokensForBNB(splithalf);
        // uint256 recieveBnb = address(this).balance.sub(initialBnB);
        // uint256 initialBalance = IERC20(rewardToken).balanceOf(address(this));
       
        // swapBnbForReward(bal);
        // uint256 newBalance = (IERC20(rewardToken).balanceOf(address(this))).sub(initialBalance);
        // distributeDividends(newBalance);

        AmountForReward += splithalf;

        uint ref = otherhalf.mul(_getRate());

        _rOwned[address(this)] = _rOwned[address(this)].sub(ref);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].sub(otherhalf);
        _rTotal = _rTotal.sub(ref);
        _tFeeTotal = _tFeeTotal.add(otherhalf);
        

        AmountForStability = AmountForStability.sub(_token);
        lastTrigger = block.timestamp;
    }

    
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        _approve(address(this), address(pcsV2Router), tokenAmount);

        // make the swap
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBnbForReward(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pcsV2Router.WETH();
        path[1] = rewardToken;

      // make the swap
        pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            address(this), // Burn address
            block.timestamp.add(300)
        );
    }

    function swapBNBForTokensBurn(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pcsV2Router.WETH();
        path[1] = address(this);

      // make the swap
        pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            dead, // Burn address
            block.timestamp.add(300)
        );        
    }
    

    function swapTokensForRewardToken(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();
        path[2] = rewardToken;

        _approve(address(this), address(pcsV2Router), tokenAmount);

        // make the swap
        pcsV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pcsV2Router), tokenAmount);

        // add the liquidity
        pcsV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        
            removeAllFee();

            if (takeFee){

                if (sender == pcsV2Pair) {
                    setBuy();
                }
                if (recipient == pcsV2Pair) {

                    uint additionFee = getCurrentTaxBracket(sender);

                    //calculate Tax
                    if (isTaxBracketEnabled) {
                        setDynamicTax(additionFee);                        
                    }
                    else {
                        setSell();
                    }

                }
            } 
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
        uint256 currentRate =  _getRate();  
        uint256 rAmount = amount.mul(currentRate);   

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount); 
        
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        } 
        emit Transfer(sender, recipient, amount);
    }

    function recoverFunds() public onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        // do not allow recovering self token
        require(tokenAddress != address(this), "Self withdraw");
        require(tokenAddress != rewardToken, "reward withdraw");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function enableTaxBracket(bool _status) public onlyOwner {
        isTaxBracketEnabled = _status;
    }

    /* Dividend management functions*/
    function distributeDividends(uint256 amount) internal {
        require(_tDividendTotal > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / _tDividendTotal
        );
        emit DividendsDistributed(amount);

        totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function withdrawDividend() public virtual {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            //check if contract has balance to pay out rewards
            uint256 curBalance = IERC20(rewardToken).balanceOf(address(this));
            if(curBalance < _withdrawableDividend){
                return 0;
            }

            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(rewardToken).transfer(user, _withdrawableDividend);

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns (uint256) {
        return
        magnifiedDividendPerShare
            .mul(balanceOf(_owner))
            .toInt256Safe()
            .add(magnifiedDividendCorrections[_owner])
            .toUint256Safe() / magnitude;
    }

    
    function _dtransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

 
    function _dmint(address account, uint256 value) internal {
        _tDividendTotal = _tDividendTotal + value;
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub(
        (magnifiedDividendPerShare.mul(value)).toInt256Safe()
        );
        
    }
  
    function _dburn(address account, uint256 value) internal {
        _tDividendTotal = _tDividendTotal - value;
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add(
        (magnifiedDividendPerShare.mul(value)).toInt256Safe()
        );
        
    }

    function _setBalance(address account, uint256 newBalance, uint256 currentBalance) internal {
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _dmint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _dburn(account, burnAmount);
        }
    }


    function excludeFromDividends(address account) public onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        uint256 currentBalance = balanceOf(account);
        if(currentBalance < minimumTokenBalanceForDividends){
            //if existing balance was less than min, the entry is not there
            currentBalance = 0;
        }
        _setBalance(account, 0, currentBalance);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
        newClaimWait >= 3600 && newClaimWait <= 86400,
        "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(newClaimWait != claimWait, "Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccountDividendsInfo(address _account)
        public
        view
        returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
                ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                : 0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
        ? nextClaimTime.sub(block.timestamp)
        : 0;
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        public
        view
        returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (address(0), -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccountDividendsInfo(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance, uint256 currentBalance) private {
        if (excludedFromDividends[account]) {
            return;
        }
        if(currentBalance < minimumTokenBalanceForDividends){
            //if existing balance was less than min, the entry is not there
            currentBalance = 0;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {            
            _setBalance(account, newBalance, currentBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0, currentBalance);
            tokenHoldersMap.remove(account);
        }
        processAccount(account, true);
    }


    function process(uint256 gas)
        public
        returns (
        uint256,
        uint256,
        uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                claims++;
                }
            }
            iterations++;
            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }
            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) internal returns (bool) {
        if (!tokenHoldersMap.inserted[account]){
            return false;
        }
        
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
        newValue >= 200000 && newValue <= 5000000,
        "gasForProcessing must be between 200,000 and 5,000,000"
        );
        gasForProcessing = newValue;
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 _lastProcessedIndex) = process(gas);
        emit ProcessedDividendTracker(iterations, claims, _lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        processAccount(payable(msg.sender), false);
    }

}