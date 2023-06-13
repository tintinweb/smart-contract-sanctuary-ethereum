/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
/*


 /$$$$$$$  /$$$$$$$$ /$$    /$$
| $$__  $$| $$_____/| $$   | $$
| $$  \ $$| $$      | $$   | $$
| $$$$$$$/| $$$$$   |  $$ / $$/
| $$__  $$| $$__/    \  $$ $$/ 
| $$  \ $$| $$        \  $$$/  
| $$  | $$| $$$$$$$$   \  $/   
|__/  |__/|________/    \_/    


 */

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
        return mod(a, b, "SafeMath: modulo by zero");
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
        return payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
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
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(
        Map storage map,
        address key
    ) internal view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(
        Map storage map,
        uint index
    ) internal view returns (address) {
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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousRevOwner;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousRevOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousRevOwner == msg.sender,
            "You don't have permission to unlock the token contract"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousRevOwner);
        _owner = _previousRevOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function FeeTo() external view returns (address);

    function FeeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

contract REVBeta is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    using Address for address;
    using SafeERC20 for IERC20;
    using IterableMapping for IterableMapping.Map;
    address public dead = 0x000000000000000000000000000000000000dEaD;
    uint8 public maxtaxFee = 10;
    mapping(address => uint256) private _rRevOwned;
    mapping(address => uint256) private _tRevOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public _tDividendTotal = 0;
    uint256 internal constant magnitude = 2 ** 128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    uint256 public totalDividendsDistributed;
    IterableMapping.Map private revHoldersMap;
    uint256 public lastProcessedIndex;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;
    uint256 public claimWait = 3600;
    uint256 public minimumTokenBalanceForDividends = 250;
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    event DividendsDistributed(uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas,
        address indexed processor
    );
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) public _isBlacklisted;
    address[] private _excluded;
    //address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //address public router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public router = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
    address public revRewardToken;
    uint256 public _tRevTotal;
    uint256 private _rRevTotal;
    uint256 private _revFeeTotal;
    uint256 private constant MAX = ~uint256(0);
    uint256 private revFeeTotal = _revRewardFee;
    string public _name;
    string public _symbol;
    uint8 private _decimals;
    uint8 public _revTaxFee = 0;
    uint8 private _previousRevTaxFee = _revTaxFee;
    uint8 public _revRewardFee = 0;
    uint8 private _previousRevRewardFee = _revRewardFee;
    IUniswapV2Router02 public pcsV2Router;
    address public pcsV2Pair;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimal,
        uint256 amountOfTokenWei,
        address _revRewardToken
    ) payable {
        require(msg.value >= 0.1 ether, "Insufficient Value Sent");
        transferEth(_msgSender(), 0.1 ether);
        if (msg.value > 0.1 ether) {
            transferEth(_msgSender(), msg.value.sub(0.1 ether));
        }
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = decimal;
        _tRevTotal = amountOfTokenWei;
        _rRevTotal = (MAX - (MAX % _tRevTotal));
        _rRevOwned[_msgSender()] = _rRevTotal;
        revRewardToken = _revRewardToken;
        _isExcludedFromFee[_msgSender()] = true;
        _tRevOwned[_msgSender()] = _tRevTotal;
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[_msgSender()] = true;
        excludedFromDividends[address(pcsV2Router)] = true;
        excludedFromDividends[address(0xdead)] = true;
        excludedFromDividends[address(pcsV2Pair)] = true;
        IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(router);

        pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory()).createPair(
            address(this),
            _pcsV2Router.WETH()
        );
        pcsV2Router = _pcsV2Router;
        emit Transfer(address(0), _msgSender(), _tRevTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function updatePcsV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(pcsV2Router),
            "The router already has that address"
        );
        IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(newAddress);
        pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory()).createPair(
            address(this),
            _pcsV2Router.WETH()
        );
        pcsV2Router = _pcsV2Router;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tRevTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tRevOwned[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return revFeeTotal;
    }

    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= _tRevTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(rAmount <= _rRevTotal, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded from reward");
        if (_rRevOwned[account] > 0) {
            _tRevOwned[account] = tokenFromReflection(_rRevOwned[account]);}
        _isExcluded[account] = true;
        _excluded.push(account);}

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        uint256 i;
        for (i = 0; i < _excluded.length; i++) {
        if (_excluded[i] == account) break;}
        require(i < _excluded.length, "Account not found in excluded list");
        _excluded[i] = _excluded[_excluded.length - 1];
        _tRevOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();}

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function setAllFeePercent(
        uint8 taxFee,
        uint8 rewardFee
    ) external onlyOwner {
        require(taxFee >= 0 && taxFee <= maxtaxFee, "Tax Fee error");
        require(rewardFee >= 0 && rewardFee <= maxtaxFee, "Reward Fee error");
        require(rewardFee == 0 || taxFee == 0, "Cannot change TF & RW");
        _revTaxFee = taxFee;
        _revRewardFee = rewardFee;
    }

    function setMinimumTokenBalanceForDividends(
        uint256 _minimumTokenBalanceForDividends
    ) external onlyOwner {
        require(
            _minimumTokenBalanceForDividends >= 1 &&
                _minimumTokenBalanceForDividends <= totalSupply().div(100),
            "err"
        );
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rRevTotal = _rRevTotal.sub(rFee);
        _revFeeTotal = _revFeeTotal.add(tFee);
    }

    function _getValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            _getRate()
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256) {
        uint256 tFee = calculatetaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rRevSupply, uint256 tRevSupply) = _getCurrentRevSupply();
        return rRevSupply.div(tRevSupply);
    }

   function _getCurrentRevSupply() private view returns (uint256, uint256) {
    uint256 rRevSupply = _rRevTotal;
    uint256 tRevSupply = _tRevTotal; 
    for (uint256 i = 0; i < _excluded.length; i++) {
        require(_rRevOwned[_excluded[i]] <= rRevSupply && _tRevOwned[_excluded[i]] <= tRevSupply, "Invalid supply values");
        rRevSupply = rRevSupply.sub(_rRevOwned[_excluded[i]]);
        tRevSupply = tRevSupply.sub(_tRevOwned[_excluded[i]]);
    }
    if (rRevSupply < _rRevTotal.div(_tRevTotal)) return (_rRevTotal, _tRevTotal);
    return (rRevSupply, tRevSupply);
}


    function calculatetaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_revTaxFee).div(10 ** 2);
    }

    function removeFees() private {
        if (_revTaxFee == 0 && _revRewardFee == 0) return;
        _previousRevTaxFee = _revTaxFee;
        _previousRevRewardFee = _revRewardFee;
        _revTaxFee = 0;
        _revRewardFee = 0;
    }

    function restoreFees() private {
        _revTaxFee = _previousRevTaxFee;
        _revRewardFee = _previousRevRewardFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Blacklisted address");
        if(_revRewardFee != 0){
                uint256 gas = gasForProcessing;
                (uint256 iterations, uint256 claims, uint256 _lastProcessedIndex) = process(gas);
                emit ProcessedDividendTracker(iterations, claims, _lastProcessedIndex, true, gas, _msgSender());}
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else if (from != router && to != router) {
            takeFee = false;
        }
        uint256 currentBalanceFrom = balanceOf(from);
        uint256 currentBalanceTo = balanceOf(to);
        _tokenTransfer(from, to, amount, takeFee);
        setBalance(payable(from), balanceOf(from), currentBalanceFrom);
        setBalance(payable(to), balanceOf(to), currentBalanceTo);
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

    function swapBNBForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = pcsV2Router.WETH();
        path[1] = address(this);
        pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, dead, block.timestamp.add(300));
    }

    function swapTokensForrevRewardToken(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();
        path[2] = revRewardToken;
        _approve(address(this), address(pcsV2Router), tokenAmount);
        pcsV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeFees();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        }
        if (!takeFee) restoreFees();}

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (   uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _rRevOwned[sender] = _rRevOwned[sender].sub(rAmount);
        _rRevOwned[recipient] = _rRevOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (   uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _rRevOwned[sender] = _rRevOwned[sender].sub(rAmount);
        _tRevOwned[recipient] = _tRevOwned[recipient].add(tTransferAmount);
        _rRevOwned[recipient] = _rRevOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (   uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _tRevOwned[sender] = _tRevOwned[sender].sub(tAmount);
        _rRevOwned[sender] = _rRevOwned[sender].sub(rAmount);
        _rRevOwned[recipient] = _rRevOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (   uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _tRevOwned[sender] = _tRevOwned[sender].sub(tAmount);
        _rRevOwned[sender] = _rRevOwned[sender].sub(rAmount);
        _tRevOwned[recipient] = _tRevOwned[recipient].add(tTransferAmount);
        _rRevOwned[recipient] = _rRevOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}

    function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        _rRevOwned[sender] = _rRevOwned[sender].sub(rAmount);
        _rRevOwned[recipient] = _rRevOwned[recipient].add(rAmount);
        if (_isExcluded[sender]) {
            _tRevOwned[sender] = _tRevOwned[sender].sub(amount);}
        if (_isExcluded[recipient]) {
            _tRevOwned[recipient] = _tRevOwned[recipient].add(amount);}
        emit Transfer(sender, recipient, amount);}

    function transferEth(address recipient, uint256 amount) private {
        (bool res, ) = recipient.call{value: amount}("");
        require(res, "ETH TRANSFER FAILED");}

    function distributeDividends(uint256 amount) internal {
        require(_tDividendTotal > 0);
        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / _tDividendTotal
            );
            emit DividendsDistributed(amount);
            totalDividendsDistributed = totalDividendsDistributed.add(amount);}}

    function withdrawDividend() public virtual {
        _withdrawDividendOfUser(payable(msg.sender));}

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            uint256 curBalance = IERC20(revRewardToken).balanceOf(address(this));
            if (curBalance < _withdrawableDividend) {
                return 0;
            }
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(revRewardToken).transfer(
                user,
                _withdrawableDividend
            );
            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend);
                return 0;}
            return _withdrawableDividend;}
        return 0;}

    function dividendOf(address _owner) public view returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(
        address _owner
    ) public view returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(
        address _owner
    ) public view returns (uint256) {
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
        int256 _magCorrection = magnifiedDividendPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    function _dmint(address account, uint256 value) internal {
        _tDividendTotal = _tDividendTotal + value;
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _dburn(address account, uint256 value) internal {
        _tDividendTotal = _tDividendTotal - value;
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(
        address account,
        uint256 newBalance,
        uint256 currentBalance
    ) internal {
        if (newBalance > currentBalance) {
            uint256 minamount = newBalance.sub(currentBalance);
            _dmint(account, minamount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _dburn(account, burnAmount);
        }
    }

    function excludeFromDividends(address account) public onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
        uint256 currentBalance = balanceOf(account);
        if (currentBalance < minimumTokenBalanceForDividends) {
            currentBalance = 0;
        }
        _setBalance(account, 0, currentBalance);
        revHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return revHoldersMap.keys.length;
    }

    function getAccountDividendsInfo(
        address _account
    )
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
        index = revHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;
        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = revHoldersMap.keys.length >
                    lastProcessedIndex
                    ? revHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;
                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
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

    function getAccountDividendsInfoAtIndex(
        uint256 index
    )
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
        if (index >= revHoldersMap.size()) {
            return (address(0), -1, -1, 0, 0, 0, 0, 0);
        }
        address account = revHoldersMap.getKeyAtIndex(index);
        return getAccountDividendsInfo(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(
        address payable account,
        uint256 newBalance,
        uint256 currentBalance
    ) private {
        if (excludedFromDividends[account]) {
            return;
        }
        if (currentBalance < minimumTokenBalanceForDividends) {
            currentBalance = 0;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance, currentBalance);
            revHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0, currentBalance);
            revHoldersMap.remove(account);
        }
        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = revHoldersMap.keys.length;
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
            if (_lastProcessedIndex >= revHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }
            address account = revHoldersMap.keys[_lastProcessedIndex];
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

    function processAccount(
        address payable account,
        bool automatic
    ) internal returns (bool) {
        if (!revHoldersMap.inserted[account]) {
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
        (
            uint256 iterations,
            uint256 claims,
            uint256 _lastProcessedIndex
        ) = process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            _lastProcessedIndex,
            false,
            gas,
            _msgSender()
        );
    }

    function claim() external {
        processAccount(payable(msg.sender), false);
    }
}