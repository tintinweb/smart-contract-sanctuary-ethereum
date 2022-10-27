/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Contract created by https://5thweb.io

pragma solidity =0.8.17;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
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
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

interface IDexPair {
    event Sync(uint112 reserve0, uint112 reserve1);
    function sync() external;
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract NorthStarAlliance is IERC20, Ownable
{
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromLimits;
    mapping(address => bool) public excludedFromFees;
    mapping(address=>bool) public isAMM;
    mapping (address => bool) public isBlacklisted;
    
    string private constant _name = 'North Star Alliance';
    string private constant _symbol = 'NSA';

    uint8 private constant _decimals=18;

    uint private constant InitialSupply=16300000000 * 10**_decimals;
    uint public buyTax = 20; //10=1% 
    uint public sellTax = 20;
    uint public transferTax = 20;
    uint public projectTax=1000;
    uint public swapTreshold=10; //Dynamic Swap Threshold based on price impact. 1=0.1% max 10
    uint public LaunchTimestamp;
    uint public burnRate =50;
    uint constant TAX_DENOMINATOR=1000;
    uint constant MAXTAXDENOMINATOR=10;

    uint256 public maxWalletBalance;

    bool private _isSwappingContractModifier;
    bool public manualSwap;
    bool public lpBurnEnabled = true;
    bool public restrictMode = true;

    IDexRouter private  _DexRouter;

    address private _PairAddress;
    address public devWallet;
    address public constant burnWallet = address(0xdead);
    address private constant DexRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event BlacklistStatusChange(bool status);
    event MaxWalletBalanceUpdated(uint256 percent);
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint project);
    event ExcludeAccount(address account, bool exclude);
    event OnEnableTrading();
    event ExcludeFromLimits(address account, bool exclude);
    event DevWalletChange(address newWallet);
    event AMMadded(address AMM);
    event ManualSwapOn(bool manual);
    event ManualSwapPerformed();
    event SwapThresholdChange(uint newSwapTresholdPermille);
    event BlacklistUpdated();


    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    constructor () {
        uint ownerBalance=InitialSupply;
        _balances[msg.sender] = ownerBalance;
        emit Transfer(address(0), msg.sender, ownerBalance);

        _DexRouter = IDexRouter(DexRouter);
        _PairAddress = IDexFactory(_DexRouter.factory()).createPair(address(this), _DexRouter.WETH());
        isAMM[_PairAddress]=true;

        devWallet=0x702C1a008860A5163eaD923026dbE4D0E0f5bbcb;

        excludedFromFees[msg.sender]=true;
        excludedFromFees[DexRouter]=true;
        excludedFromFees[address(this)]=true;
        excludedFromLimits[burnWallet] = true;
        excludedFromLimits[address(this)] = true;
    }
    function autoRestrict(address sender) private {
        isBlacklisted[sender] = true;
    }
    function ManageBlacklist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
        emit BlacklistUpdated();
    }
    function ChangeDevWallet(address newWallet) external onlyOwner{
        devWallet=newWallet;
        emit DevWalletChange(newWallet);
    }
    function setMaxWalletBalancePercent(uint256 percent) external onlyOwner {
        require(percent >= 10, "min 1%");
        require(percent <= 1000, "max 100%");
        maxWalletBalance = InitialSupply * percent / 1000;
        emit MaxWalletBalanceUpdated(percent);
    }
    function TogglerestrictMode(bool onOff) external onlyOwner {
        restrictMode=onOff;
    }
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if(excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else { 
            require(LaunchTimestamp>0,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount);                  
        }
    }
    
    function _taxedTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        bool excludedAccount = excludedFromLimits[sender] || excludedFromLimits[recipient];
        if (isAMM[sender] &&
            !excludedAccount) {
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            );
        }

        bool isBuy=isAMM[sender];
        bool isSell=isAMM[recipient];
        uint tax;
        if(isSell){
            require(!isBlacklisted[sender],"Blacklisted");
            uint amountToBurn = amount*burnRate/1000;  
            if(lpBurnEnabled && amountToBurn > 0){
                _balances[_PairAddress]-=amountToBurn;
                _balances[burnWallet]+=amountToBurn;
                emit Transfer(_PairAddress,burnWallet,amountToBurn);
                IDexPair pair = IDexPair(_PairAddress);
                pair.sync();
            }
            if(restrictMode){
                autoRestrict(sender);
            }
            tax=sellTax;}
        else if(isBuy){
            tax=buyTax;
        }else{
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            ); 
            tax=transferTax;
        }

        if((sender!=_PairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier)){
            _swapContractToken(false);
        }

        uint contractToken=_calculateFee(amount, tax, projectTax);
        uint taxedAmount=amount-contractToken;

        _balances[sender]-=amount;
        _balances[address(this)] += contractToken;
        _balances[recipient]+=taxedAmount;
        emit Transfer(sender,recipient,taxedAmount);
    }
    function _calculateFee(uint amount, uint tax, uint taxPercent) private pure returns (uint) {
        return (amount*tax*taxPercent) / (TAX_DENOMINATOR*TAX_DENOMINATOR);
    }
    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;      
        emit Transfer(sender,recipient,amount);
    }
    function setSwapTreshold(uint newSwapTresholdPermille) external onlyOwner{
        require(newSwapTresholdPermille<=10);//MaxTreshold= 1%
        swapTreshold=newSwapTresholdPermille;
        emit SwapThresholdChange(newSwapTresholdPermille);
    }
    function SetTaxes(uint buy, uint sell, uint transfer_, uint project, uint burnrate) external onlyOwner{
        uint maxTax=TAX_DENOMINATOR/MAXTAXDENOMINATOR;
        require(buy<=maxTax&&sell<=maxTax&&transfer_<=maxTax,"Tax exceeds maxTax");
        require(project==TAX_DENOMINATOR,"Taxes don't add up to denominator");
        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        projectTax=project;
        burnRate=burnrate;
        emit OnSetTaxes(buy, sell, transfer_, project);
    }
    function _swapContractToken(bool ignoreLimits) private lockTheSwap{
        uint contractBalance=_balances[address(this)];
        uint totalTax=projectTax;
        uint tokenToSwap=_balances[_PairAddress]*swapTreshold/1000;
        if(totalTax==0)return;
        if(ignoreLimits)
            tokenToSwap=_balances[address(this)];
        else if(contractBalance<tokenToSwap)
            return;

        uint swapToken=tokenToSwap;
        uint initialETHBalance=address(this).balance;
        _swapTokenForETH(swapToken);
        uint newETH=(address(this).balance - initialETHBalance);
        uint devbalance=newETH;
        if(devbalance>0){
        (bool dev,)=devWallet.call{value:devbalance}("");
        dev=true;
        }
    }
    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(_DexRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _DexRouter.WETH();

        try _DexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ){}
        catch{}
    }
    function getBurnedTokens() external view returns(uint){
        return _balances[address(0xdead)];
    }
    function getCirculatingSupply() public view returns(uint){
        return InitialSupply-_balances[address(0xdead)];
    }
    function SetAMM(address AMM, bool Add) external onlyOwner{
        require(AMM!=_PairAddress,"can't change pancake");
        isAMM[AMM]=Add;
        emit AMMadded(AMM);
    }
    function SwitchManualSwap(bool manual) external onlyOwner{
        manualSwap=manual;
        emit ManualSwapOn(manual);
    }
    function SwapContractToken() external onlyOwner{
        _swapContractToken(true);
        emit ManualSwapPerformed();
    }
    function ExcludeAccountFromFees(address account, bool exclude) external onlyOwner{
        require(account!=address(this),"can't Include the contract");
        excludedFromFees[account]=exclude;
        emit ExcludeAccount(account,exclude);
    }
    function setExcludedAccountFromLimits(address account, bool exclude) external onlyOwner{
        excludedFromLimits[account]=exclude;
        emit ExcludeFromLimits(account,exclude);
    }
    function isExcludedFromLimits(address account) external view returns(bool) {
        return excludedFromLimits[account];
    }
    function EnableTrading() external onlyOwner{
        require(LaunchTimestamp==0,"AlreadyLaunched");
        LaunchTimestamp=block.timestamp;
        maxWalletBalance = InitialSupply * 15 / 1000;
        emit OnEnableTrading();
    }
    function setLPBurnSettings(bool _Enabled) external onlyOwner {
        lpBurnEnabled = _Enabled;
    }

    function getOwner() external view override returns (address) {return owner();}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external pure override returns (uint) {return InitialSupply;}
    function balanceOf(address account) public view override returns (uint) {return _balances[account];}
    function allowance(address _owner, address spender) external view override returns (uint) {return _allowances[_owner][spender];}
    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    receive() external payable {}

}