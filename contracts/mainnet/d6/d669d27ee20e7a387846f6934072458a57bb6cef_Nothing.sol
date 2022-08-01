/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

pragma solidity ^0.8.4;
contract Nothing is IERC20, Ownable
{
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromLimits;
    mapping(address => bool) public excludedFromFees;
    mapping(address=>bool) public isAMM;
    mapping (address => bool) public isBlacklisted;
    
    string private constant _name = 'Nothing';
    string private constant _symbol = '0';

    uint8 private constant _decimals=18;

    uint private constant InitialSupply=5*10**6 * 10**_decimals;
    uint private constant DefaultLiquidityLockTime=7 days;
    uint public buyTax = 0;
    uint public sellTax = 20;
    uint public transferTax = 0;
    uint public burnTax=0;
    uint public liquidityTax=500;
    uint public projectTax=0;
    uint public swapTreshold=6;
    uint public overLiquifyTreshold=50;
    uint public LaunchTimestamp;
    uint public communityShare=0;
    uint public marketingShare=500;
    uint _liquidityUnlockTime;
    uint constant TAX_DENOMINATOR=1000;
    uint constant MAXTAXDENOMINATOR=10;

    uint256 public maxWalletBalance;
    uint256 public maxTransactionAmount;

    bool private _isSwappingContractModifier;
    bool public manualSwap;
    bool public blacklistMode = true;

    IDexRouter private  _DexRouter;

    address private _PairAddress;
    address public marketingWallet;
    address public communityWallet;
    address public constant burnWallet = 0x000000000000000000000000000000000000dEaD;
    address private constant DexRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event BlacklistStatusChange(bool status);
    event MaxWalletBalanceUpdated(uint256 percent);
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint project,uint liquidity);
    event ExcludeAccount(address account, bool exclude);
    event OnEnableTrading();
    event OnReleaseLP();
    event OnProlongLPLock(uint UnlockTimestamp);
    event ExcludeFromLimits(address account, bool exclude);
    event MarketingWalletChange(address newWallet);
    event CommunityWalletChange(address newWallet);
    event SharesUpdated(uint _marketingShare, uint _communityShare);
    event AMMadded(address AMM);
    event ManualSwapOn(bool manual);
    event ManualSwapPerformed();
    event LockExtended(uint secondsUntilUnlock);
    event MaxTransactionAmountUpdated(uint256 percent);
    event SwapThresholdChange(uint newSwapTresholdPermille);
    event BlacklistUpdated();
    event OverLiquifiedThresholdChange(uint newOverLiquifyTresholdPermille);

    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    constructor () {
        uint ownerBalance=InitialSupply * 95/100;
        uint team1walletBalance=InitialSupply * 1/100;
        uint team2walletBalance=InitialSupply * 1/100;
        uint team3walletBalance=InitialSupply * 1/100;
        uint team4walletBalance=InitialSupply * 1/100;
        uint team5walletBalance=InitialSupply * 1/100;
        _balances[msg.sender] = ownerBalance;
        _balances[0x1E8043CaA1251Dfe2f93b26E64aB7C2B9d1CF387] = team1walletBalance;
        _balances[0x1E8FDE30151A0537Bd61dBFfA0979E24EEA3D628] = team2walletBalance;
        _balances[0x454350BFEcd39CFe924614F7e3c7175daAc8b698] = team3walletBalance;
        _balances[0xacdF241A66b78F6e0185Ddb25d8908c1B13F0EBB] = team4walletBalance;
	_balances[0x8A4911fFf82049B88575627512742B30400eD565] = team5walletBalance;


        emit Transfer(0x7Ee8771e3D1d84CC447348AEEc847E3eb441B7a9, msg.sender, ownerBalance);
        emit Transfer(0x7Ee8771e3D1d84CC447348AEEc847E3eb441B7a9, 0x1E8043CaA1251Dfe2f93b26E64aB7C2B9d1CF387, team1walletBalance);
        emit Transfer(0x7Ee8771e3D1d84CC447348AEEc847E3eb441B7a9, 0x1E8FDE30151A0537Bd61dBFfA0979E24EEA3D628, team2walletBalance);
        emit Transfer(0x7Ee8771e3D1d84CC447348AEEc847E3eb441B7a9, 0x454350BFEcd39CFe924614F7e3c7175daAc8b698, team3walletBalance);
        emit Transfer(0x7Ee8771e3D1d84CC447348AEEc847E3eb441B7a9, 0xacdF241A66b78F6e0185Ddb25d8908c1B13F0EBB, team4walletBalance);
        emit Transfer(0x7Ee8771e3D1d84CC447348AEEc847E3eb441B7a9, 0x8A4911fFf82049B88575627512742B30400eD565, team5walletBalance);

        _DexRouter = IDexRouter(DexRouter);
        _PairAddress = IDexFactory(_DexRouter.factory()).createPair(address(this), _DexRouter.WETH());
        isAMM[_PairAddress]=true;
        
        marketingWallet=0x1F38502522aa347eF1ff3d570788182239B68bac;
        communityWallet=0x1F38502522aa347eF1ff3d570788182239B68bac;

        excludedFromFees[msg.sender]=true;
        excludedFromFees[DexRouter]=true;
        excludedFromFees[address(this)]=true;
        excludedFromLimits[burnWallet] = true;
        excludedFromLimits[address(this)] = true;
    }
     function BlacklistStatus(bool _status) external onlyOwner {
        blacklistMode = _status;
        emit BlacklistStatusChange (_status);
    }
    function ManageBlacklist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
        emit BlacklistUpdated();
    }
    function ChangeMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet=newWallet;
        emit MarketingWalletChange(newWallet);
    }
    function ChangeCommunityWallet(address newWallet) external onlyOwner{
        communityWallet=newWallet;
        emit CommunityWalletChange(newWallet);
    }
    function SetFeeShares(uint _marketingShare, uint _communityShare) external onlyOwner{
        require(_marketingShare+_communityShare<=100);
        marketingShare=_marketingShare;
        communityShare=_communityShare;
        emit SharesUpdated(_marketingShare, _communityShare);
    }
    function setMaxWalletBalancePercent(uint256 percent) external onlyOwner {
        require(percent >= 10, "min 1%");
        require(percent <= 1000, "max 100%");
        maxWalletBalance = InitialSupply * percent / 1000;
        emit MaxWalletBalanceUpdated(percent);
    }
    function setMaxTransactionAmount(uint256 percent) external onlyOwner {
        require(percent >= 25, "min 0.25%");
        require(percent <= 10000, "max 100%");
        maxTransactionAmount = InitialSupply * percent / 10000;
        emit MaxTransactionAmountUpdated(percent);
    }
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if(blacklistMode){
            require(!isBlacklisted[sender] && !isBlacklisted[recipient],"Blacklisted");    
        }
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
        if (
            isAMM[sender] &&
            !excludedAccount
        ) {
            require(
                amount <= maxTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            );
        } else if (
            isAMM[recipient] &&
            !excludedAccount
        ) {
            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        bool isBuy=isAMM[sender];
        bool isSell=isAMM[recipient];
        uint tax;
        if(isSell){  
            uint SellTaxDuration=3 minutes;      
            if(block.timestamp<LaunchTimestamp+SellTaxDuration){
                tax=_getStartTax(SellTaxDuration,200);
                }else tax=sellTax;
            }
        else if(isBuy){
            uint BuyTaxDuration=8 seconds;
            if(block.timestamp<LaunchTimestamp+BuyTaxDuration){
                tax=_getStartTax(BuyTaxDuration,999);
            }else tax=buyTax;
        } else tax=transferTax;

        if((sender!=_PairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
            _swapContractToken(false);

        uint tokensToBeSentToBurn=_calculateFee(amount, tax, burnTax);
        uint contractToken=_calculateFee(amount, tax, projectTax+liquidityTax);
        uint taxedAmount=amount-(tokensToBeSentToBurn + contractToken);

        _balances[sender]-=amount;
        _balances[address(this)] += contractToken;
        _balances[burnWallet]+=tokensToBeSentToBurn;
        _balances[recipient]+=taxedAmount;
        emit Transfer(sender,burnWallet,tokensToBeSentToBurn);
        emit Transfer(sender,recipient,taxedAmount);
    }
    function _getStartTax(uint duration, uint maxTax) private view returns (uint){
        uint timeSinceLaunch=block.timestamp-LaunchTimestamp;
        return maxTax-((maxTax-50)*timeSinceLaunch/duration);
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
    function SetOverLiquifiedTreshold(uint newOverLiquifyTresholdPermille) external onlyOwner{
        require(newOverLiquifyTresholdPermille<=1000);
        overLiquifyTreshold=newOverLiquifyTresholdPermille;
        emit OverLiquifiedThresholdChange(newOverLiquifyTresholdPermille);
    }
    function SetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint project,uint liquidity) external onlyOwner{
        uint maxTax=TAX_DENOMINATOR/MAXTAXDENOMINATOR;
        require(buy<=maxTax&&sell<=maxTax&&transfer_<=maxTax,"Tax exceeds maxTax");
        require(burn+project+liquidity==TAX_DENOMINATOR,"Taxes don't add up to denominator");
        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        projectTax=project;
        liquidityTax=liquidity;
        burnTax=burn;
        emit OnSetTaxes(buy, sell, transfer_, burn, project, liquidity);
    }
    function isOverLiquified() public view returns(bool){
        return _balances[_PairAddress]>getCirculatingSupply()*overLiquifyTreshold/1000;
    }
    function _swapContractToken(bool ignoreLimits) private lockTheSwap{
        uint contractBalance=_balances[address(this)];
        uint totalTax=liquidityTax+projectTax;
        uint tokenToSwap=_balances[_PairAddress]*swapTreshold/1000;
        if(totalTax==0)return;
        if(ignoreLimits)
            tokenToSwap=_balances[address(this)];
        else if(contractBalance<tokenToSwap)
            return;

        uint tokenForLiquidity=
        isOverLiquified()?0
        :(tokenToSwap*liquidityTax)/totalTax;

        uint tokenForProject= tokenToSwap-tokenForLiquidity;

        uint LiqHalf=tokenForLiquidity/2;
        uint swapToken=LiqHalf+tokenForProject;
        uint initialETHBalance=address(this).balance;
        _swapTokenForETH(swapToken);
        uint newETH=(address(this).balance - initialETHBalance);

        if(tokenForLiquidity>0){
            uint liqETH = (newETH*LiqHalf)/swapToken;
            _addLiquidity(LiqHalf, liqETH);
        }
        uint marketbalance=address(this).balance * marketingShare/100;
        uint communitybalance=address(this).balance * communityShare/100;
        (bool marketing,)=marketingWallet.call{value:marketbalance}("");
        marketing=true;
        (bool community,)=communityWallet.call{value:communitybalance}("");
        community=true;
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
    function _addLiquidity(uint tokenamount, uint ETHamount) private {
        _approve(address(this), address(_DexRouter), tokenamount);
        _DexRouter.addLiquidityETH{value: ETHamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
    function getLiquidityReleaseTimeInSeconds() external view returns (uint){
        if(block.timestamp<_liquidityUnlockTime)
            return _liquidityUnlockTime-block.timestamp;
        return 0;
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
        maxWalletBalance = InitialSupply * 20 / 1000;
        maxTransactionAmount = InitialSupply * 200 / 10000;
        emit OnEnableTrading();
    }
    function LockLiquidityForSeconds(uint secondsUntilUnlock) external onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
        emit LockExtended(secondsUntilUnlock);
    }
    function _prolongLiquidityLock(uint newUnlockTime) private{
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
        emit OnProlongLPLock(_liquidityUnlockTime);
    }
    function LiquidityRelease() external {
        require(msg.sender==marketingWallet);
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        IERC20 liquidityToken = IERC20(_PairAddress);
        uint amount = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(msg.sender, amount);
        emit OnReleaseLP();
    }

    receive() external payable {}

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

}