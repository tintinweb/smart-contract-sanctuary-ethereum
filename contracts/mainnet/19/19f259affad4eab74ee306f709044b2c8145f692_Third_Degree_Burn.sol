/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: UNLICENSED


pragma solidity =0.8.15;

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

pragma solidity =0.8.15;
contract Third_Degree_Burn is IERC20, Ownable //clientchange
{
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromLimits;
    mapping(address => bool) public excludedFromFees;
    mapping(address=>bool) public isAMM;
    mapping (address => bool) public isBlacklisted;
    mapping(address => User) user;
    mapping(address =>bool) public floorHolder;

    struct User {
        uint256 sold;
        uint256 sellStamp;
        uint256 dailyLimit;
    }
    string private constant _name = 'Third Degree Burn';
    string private constant _symbol = '3DB';
    uint8 private constant _decimals=18;

      uint private constant InitialSupply=333333333333* 10**_decimals;
   uint public buyTax = 40; //10=1% 
    uint public sellTax = 50;
    uint public floorSellerTax = 99;
    uint public transferTax = 0;
    uint public burnTax=249; //burn+liquidity+project must = 1000
    uint public liquidityTax=1;
    uint public projectTax=750;
    uint public swapTreshold=2; //Dynamic Swap Threshold based on price impact. 1=0.1% max 10
    uint public overLiquifyTreshold=100;
    uint public LaunchTimestamp;
    uint public devShare=15; //devShare+buybackShare+marketingShare must = 100
    uint public buybackShare=65;
    uint public marketingShare=20;
    uint constant TAX_DENOMINATOR=1000;
    uint constant MAXTAXDENOMINATOR=10;

    uint256 public maxWalletBalance;
    uint256 public maxTransactionAmount;
    uint256 public percentForLPBurn = 50; // 25 = .25%
    uint256 public lpBurnFrequency = 1 seconds;
    uint256 public lastLpBurnTime;
    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public lastManualLpBurnTime;
    uint256 public dailySellPercent = 1000;
    uint256 public dailySellCooldown = 24 hours;


    bool private _isSwappingContractModifier;
    bool public manualSwap;
    bool public blacklistMode = true;
    bool public lpBurnEnabled = true;
    bool public floorMode = true;
    bool public floorBuyerRound = true;

    IDexRouter private  _DexRouter;

    address private _PairAddress;
    address public marketingWallet;
    address public devWallet;
    address public constant burnWallet = address(0xdead);
    address private constant DexRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; //

    event ManualNukeLP();
    event AutoNukeLP();
    event BlacklistStatusChange(bool status);
    event MaxWalletBalanceUpdated(uint256 percent);
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint project,uint liquidity,uint FloorSellTax);
    event ExcludeAccount(address account, bool exclude);
    event OnEnableTrading();
    event OnReleaseLP();
    event ExcludeFromLimits(address account, bool exclude);
    event MarketingWalletChange(address newWallet);
    event DevWalletChange(address newWallet);
    event SharesUpdated(uint _devShare, uint _marketingShare, uint _buybackShare);
    event AMMadded(address AMM);
    event ManualSwapOn(bool manual);
    event ManualSwapPerformed();
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
        uint ownerBalance=InitialSupply;
        _balances[msg.sender] = ownerBalance;
        emit Transfer(address(0), msg.sender, ownerBalance);

        _DexRouter = IDexRouter(DexRouter);
        _PairAddress = IDexFactory(_DexRouter.factory()).createPair(address(this), _DexRouter.WETH());
        isAMM[_PairAddress]=true;
        
        marketingWallet=0x36385DAA46Aa351E6Cc2533bb76e9cFcC1F40132; //
        devWallet=0x36385DAA46Aa351E6Cc2533bb76e9cFcC1F40132; //

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
    function ManageFloorHolders(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            floorHolder[addresses[i]] = status;
        }
    }
    function ChangeMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet=newWallet;
        emit MarketingWalletChange(newWallet);
    }
    function ChangeDevWallet(address newWallet) external onlyOwner{
        devWallet=newWallet;
        emit DevWalletChange(newWallet);
    }
    function SetFeeShares(uint _devShare, uint _marketingShare, uint _buybackShare, uint _charityShare) external onlyOwner{
        require(_devShare+_marketingShare+_buybackShare+_charityShare<=100);
        devShare=_devShare;
        marketingShare=_marketingShare;
        buybackShare=_buybackShare;
        emit SharesUpdated(_devShare, _marketingShare, _buybackShare);
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
    function ToggleFloorMode(bool onOff) external onlyOwner {
        floorMode=onOff;
    }
    function ToggleFloorBuyerPeriod(bool onOff) external onlyOwner {
        floorBuyerRound=onOff;
    }
    function setDailySellPercent(uint256 percentInHundreds) external onlyOwner {
        require(percentInHundreds >= 100, "Cannot set below 1%.");
        dailySellPercent = percentInHundreds;
    }
    function setDailySellCooldown(uint256 timeInSeconds) external onlyOwner {
        require(timeInSeconds <= 24 hours, "Cannot set above 24 hours.");
        dailySellCooldown = timeInSeconds;
    }
    function getUserInfo(address account) external view returns(uint256, uint256, uint256) {
        User memory _user = user[account];
        return(_user.sold, _user.dailyLimit, _user.sellStamp);
    }
    function getSecondsToNextSellReset(address account) external view returns(uint256) {
        uint256 time = user[account].sellStamp + dailySellCooldown;
        if (time > block.timestamp) {
            return(time - block.timestamp);
        } else {
            return 0;
        }
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
        if (isAMM[sender] &&
            !excludedAccount) {
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
            require(amount <= maxTransactionAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        bool isBuy=isAMM[sender];
        bool isSell=isAMM[recipient];
        uint tax;
        if(isSell){  
            uint SellTaxDuration=1 seconds;      
            if(block.timestamp<LaunchTimestamp+SellTaxDuration){
                tax=_getStartTax(SellTaxDuration,200);
                }
            if(floorMode && floorHolder[sender]){
                        tax=floorSellerTax;
                        if(user[sender].sellStamp + dailySellCooldown > block.timestamp) {
                            uint256 addition = user[sender].sold + amount;
                            require(addition <= user[sender].dailyLimit, "Sell amount exceeds daily limit.");
                            user[sender].sold = addition;
                        } else {
                            user[sender].dailyLimit = (balanceOf(sender) * dailySellPercent) / 10000;
                            require(amount <= user[sender].dailyLimit, "Sell amount exceeds daily limit.");
                            user[sender].sold = amount;
                            user[sender].sellStamp = block.timestamp;
                        }
            }else tax=sellTax;}
        else if(isBuy){
            if(floorBuyerRound){
                require(floorHolder[recipient]);
            }
            uint BuyTaxDuration=1 seconds;
            if(block.timestamp<LaunchTimestamp+BuyTaxDuration){
                tax=_getStartTax(BuyTaxDuration,999);
            }else tax=buyTax;
        }else{ 
            require(!floorMode || !floorHolder[recipient] && !floorHolder[sender], "Cannot send tokens to a floor holder"); 
            tax=transferTax;
        }

        if((sender!=_PairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
            _swapContractToken(false);

        if(!_isSwappingContractModifier && isAMM[recipient] && lpBurnEnabled && block.timestamp >= lastLpBurnTime + lpBurnFrequency){
            autoBurnLPTokens();
        }

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
    function SetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint project,uint liquidity, uint FloorSellTax) external onlyOwner{
        uint maxTax=TAX_DENOMINATOR/MAXTAXDENOMINATOR;
        require(buy<=maxTax&&sell<=maxTax&&transfer_<=maxTax&&FloorSellTax<=maxTax,"Tax exceeds maxTax");
        require(burn+project+liquidity==TAX_DENOMINATOR,"Taxes don't add up to denominator");
        buyTax=buy;
        sellTax=sell;
        floorSellerTax=FloorSellTax;
        transferTax=transfer_;
        projectTax=project;
        liquidityTax=liquidity;
        burnTax=burn;
        emit OnSetTaxes(buy, sell, transfer_, burn, project, liquidity, FloorSellTax);
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
        uint devbalance=address(this).balance * devShare/100;
        uint buybackbalance=address(this).balance * buybackShare/100;
        if(marketbalance>0){
        (bool marketing,)=marketingWallet.call{value:marketbalance}("");
        marketing=true;
        }
        if(devbalance>0){
        (bool dev,)=devWallet.call{value:devbalance}("");
        dev=true;
        }
        if(buybackbalance>0){
            _buybackBurn(buybackbalance);
        }
    }
    function _buybackBurn(uint amount) private {
        address[] memory path = new address[](2);
        path[0] = _DexRouter.WETH();
        path[1] = address(this);
        
        try _DexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            burnWallet,
            block.timestamp
        ){}
        catch{}
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
    function _addLiquidity(uint tokenamount, uint ethamount) private {
        _approve(address(this), address(_DexRouter), tokenamount);
        _DexRouter.addLiquidityETH{value: ethamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
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
        maxWalletBalance = InitialSupply * 10 / 1000;
        maxTransactionAmount = InitialSupply * 100 / 10000;
        emit OnEnableTrading();
    }
    function ReleaseLP() external onlyOwner {
        IERC20 liquidityToken = IERC20(_PairAddress);
        uint amount = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(msg.sender, amount);
        emit OnReleaseLP();
    }
    function setAutoLPBurnSettings(uint256 _frequencyInSeconds, uint256 _percent, bool _Enabled) external onlyOwner {
        require(_frequencyInSeconds >= 600, "cannot set buyback more often than every 10 minutes");
        require(_percent <= 1000 && _percent >= 0, "Must set auto LP burn percent between 0% and 10%");
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }
    
    function autoBurnLPTokens() internal returns (bool){
        lastLpBurnTime = block.timestamp;
        uint256 liquidityPairBalance = this.balanceOf(_PairAddress);
        uint256 amountToBurn = liquidityPairBalance * percentForLPBurn/10000;
        if (amountToBurn > 0){
            _balances[burnWallet]+=amountToBurn;
            emit Transfer(_PairAddress,burnWallet,amountToBurn);
        }
        IDexPair pair = IDexPair(_PairAddress);
        pair.sync();
        emit AutoNukeLP();
        return true;
    }

    function manualBurnLPTokens(uint256 percent) external onlyOwner returns (bool){
        require(block.timestamp > lastManualLpBurnTime + manualBurnFrequency , "Must wait for cooldown to finish");
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        lastManualLpBurnTime = block.timestamp;
        uint256 liquidityPairBalance = this.balanceOf(_PairAddress);
        uint256 amountToBurn = liquidityPairBalance * percent/10000;
        if (amountToBurn > 0){
            _balances[burnWallet]+=amountToBurn;
            emit Transfer(_PairAddress,burnWallet,amountToBurn);
        }
        IDexPair pair = IDexPair(_PairAddress);
        pair.sync();
        emit ManualNukeLP();
        return true;
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