// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Libraries.sol";
contract ARMST is IERC20Metadata, Ownable
{
  
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedFromLimit;
    mapping(address=>bool) public isAMM;
    //Token Info
    string private constant _name = 'Armstrong Inu';
    string private constant _symbol = 'ARMST';
    uint8 private constant _decimals = 18;
    uint public constant InitialSupply= 100000000*10**_decimals;

    uint private constant DefaultLiquidityLockTime=7 days;
    //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 testnet router
    //0x10ED43C718714eb63d5aA57B78B54704E256024E mainnet router

    address private constant UniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint private _circulatingSupply =InitialSupply;
    
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint public buyTax = 30;
    uint public sellTax = 30;
    uint public transferTax = 0;
    uint public burnTax=0;
    uint public liquidityTax=0;
    uint public marketingTax=1000;
    uint constant TAX_DENOMINATOR=1000;
    uint constant MAXTAXDENOMINATOR=10;
    uint public LimitV = 50;
    uint public LimitSell = 1;
    

    address private _uniswapPairAddress; 
    IUniswapRouter private  _uniswapRouter;
    
    
    //TODO: marketingWallet
    address public marketingWallet;
    //Only marketingWallet can change marketingWallet
    function ChangeMarketingWallet(address newWallet) public{
        require(msg.sender==marketingWallet);
        marketingWallet=newWallet;
    }
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not Team or Owner");
        _;
    }
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==marketingWallet;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        uint deployerBalance=_circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);

        // Uniswap Router
        _uniswapRouter = IUniswapRouter(UniswapRouter);
        //Creates a Uniswap Pair
        _uniswapPairAddress = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        isAMM[_uniswapPairAddress]=true;
        
        //contract creator is by default marketing wallet
        marketingWallet=msg.sender;
        //owner uniswap router and contract is excluded from Taxes
        excludedFromFees[msg.sender]=true;
        excludedFromFees[UniswapRouter]=true;
        excludedFromFees[address(this)]=true;
    }
    




    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");


        //Pick transfer
        if(excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else if(excludedFromLimit[recipient]){ 
            //once trading is enabled, it can't be turned off again
            require(LaunchTimestamp>0,"trading not yet enabled");
            _LimitlessFonctionTransfer(sender,recipient,amount);                  
        }
        else { 
            //once trading is enabled, it can't be turned off again
            require(LaunchTimestamp>0,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount);                  
        }
    }
    
    //applies taxes, checks for limits, locks generates autoLP and stakingETH, and autostakes
    function _taxedTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        uint recipientBalance = _balances[recipient];
        require(senderBalance >= amount, "Transfer exceeds balance");
        require(senderBalance/LimitSell >= amount, "Transfer exceeds authorise sell");
        require((recipientBalance + amount ) <= InitialSupply/LimitV, "Wallet contain more than certain % Total Supply");

        bool isBuy=isAMM[sender];
        bool isSell=isAMM[recipient];

        uint tax;
        if(isSell){  
            uint SellTaxDuration=180 seconds;          
            if(block.timestamp<LaunchTimestamp+SellTaxDuration){
                tax=_getStartTax(SellTaxDuration,999);
                }else tax=sellTax;
            }
        else if(isBuy){
            uint BuyTaxDuration=60 seconds;
            if(block.timestamp<LaunchTimestamp+BuyTaxDuration){
                tax=_getStartTax(BuyTaxDuration,999);
            }else tax=buyTax;
        } else tax=transferTax;

        if((sender!=_uniswapPairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
            _swapContractToken(false);

        //Calculates the exact token amount for each tax
        uint tokensToBeBurnt=_calculateFee(amount, tax, burnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint contractToken=_calculateFee(amount, tax, marketingTax+liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint taxedAmount=amount-(tokensToBeBurnt + contractToken);

        _balances[sender]-=amount;
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply-=tokensToBeBurnt;
        _balances[recipient]+=taxedAmount;
        
        emit Transfer(sender,recipient,taxedAmount);
    }
    //Start tax drops depending on the time since launch, enables bot protection and Dump protection
    function _getStartTax(uint duration, uint maxTax) private view returns (uint){
        uint timeSinceLaunch=block.timestamp-LaunchTimestamp;
        return maxTax-((maxTax-50)*timeSinceLaunch/duration);
    }
    //Calculates the token that should be taxed
    function _calculateFee(uint amount, uint tax, uint taxPercent) private pure returns (uint) {
        return (amount*tax*taxPercent) / (TAX_DENOMINATOR*TAX_DENOMINATOR);
    }


    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;      
        emit Transfer(sender,recipient,amount);
    }
///////////////////////////////YeaaaahBrooooooo//////////addd
    function _LimitlessFonctionTransfer (address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        bool isBuy=isAMM[sender];
        bool isSell=isAMM[recipient];

        uint tax;
        if(isSell){  
            uint SellTaxDuration=180 seconds;          
            if(block.timestamp<LaunchTimestamp+SellTaxDuration){
                tax=_getStartTax(SellTaxDuration,999);
                }else tax=sellTax;
            }
        else if(isBuy){
            uint BuyTaxDuration=60 seconds;
            if(block.timestamp<LaunchTimestamp+BuyTaxDuration){
                tax=_getStartTax(BuyTaxDuration,999);
            }else tax=buyTax;
        } else tax=transferTax;

        if((sender!=_uniswapPairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
            _swapContractToken(false);

        //Calculates the exact token amount for each tax
        uint tokensToBeBurnt=_calculateFee(amount, tax, burnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint contractToken=_calculateFee(amount, tax, marketingTax+liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint taxedAmount=amount-(tokensToBeBurnt + contractToken);

        _balances[sender]-=amount;
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply-=tokensToBeBurnt;
        _balances[recipient]+=taxedAmount;
        
        emit Transfer(sender,recipient,taxedAmount);
    }
    

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens yeaaaaah Broo//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //Sets the permille of uniswap pair to trigger liquifying taxed token
    uint public swapTreshold=2;
    function setSwapTreshold(uint newSwapTresholdPermille) public onlyTeam{
        require(newSwapTresholdPermille<=15);//MaxTreshold= 1.5%
        swapTreshold=newSwapTresholdPermille;
    }
    //Sets the max Liquidity where swaps for Liquidity still happen
    uint public overLiquifyTreshold=150;
    function SetOverLiquifiedTreshold(uint newOverLiquifyTresholdPermille) public onlyTeam{
        require(newOverLiquifyTresholdPermille<=1000);
        overLiquifyTreshold=newOverLiquifyTresholdPermille;
    }
    //Sets the taxes Burn+marketing+liquidity tax needs to equal the TAX_DENOMINATOR (1000)
    //buy, sell and transfer tax are limited by the MAXTAXDENOMINATOR
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing,uint liquidity);
    function SetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing,uint liquidity) public onlyTeam{
        uint maxTax=(TAX_DENOMINATOR/MAXTAXDENOMINATOR)/2;
        require(buy<=maxTax&&sell<=maxTax&&transfer_<=maxTax,"Tax exceeds maxTax");
        require(burn+marketing+liquidity==TAX_DENOMINATOR,"Taxes don't add up to denominator");
        
        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        marketingTax=marketing;
        liquidityTax=liquidity;
        burnTax=burn;
        emit OnSetTaxes(buy, sell, transfer_, burn, marketing,liquidity);
    }
    
    event OnSetLimit(uint LimitV2);
    function SetLimit(uint LimitV2) public onlyTeam{
        require(LimitV2<=50,"Max wallet  can't be under 2% of the total supply");
        LimitV=LimitV2;
       
        emit OnSetLimit(LimitV2);
    }

    event OnSetSell(uint LimitSell2);
    function SetSell(uint LimitSell2) public onlyTeam{
        require(LimitSell2<=2,"Dump measure can't be under 50% of the wallet");
        LimitSell=LimitSell2;
       
        emit OnSetSell(LimitSell2);
    }



    //If liquidity is over the treshold, convert 100% of Token to Marketing ETH to avoid overliquifying
    function isOverLiquified() public view returns(bool){
        return _balances[_uniswapPairAddress]>_circulatingSupply*overLiquifyTreshold/1000;
    }


    //swaps the token on the contract for Marketing ETH and LP Token.
    //always swaps a percentage of the LP pair balance to avoid price impact
    function _swapContractToken(bool ignoreLimits) private lockTheSwap{
        uint contractBalance=_balances[address(this)];
        uint totalTax=liquidityTax+marketingTax;
        //swaps each time it reaches swapTreshold of uniswap pair to avoid large prize impact
        uint tokenToSwap=_balances[_uniswapPairAddress]*swapTreshold/1000;

        //nothing to swap at no tax
        if(totalTax==0)return;
        //only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
        //Ignore limits swaps 100% of the contractBalance
        if(ignoreLimits)
            tokenToSwap=_balances[address(this)];
        else if(contractBalance<tokenToSwap)
            return;

        //splits the token in TokenForLiquidity and tokenForMarketing
        //if over liquified, 0 tokenForLiquidity
        uint tokenForLiquidity=
        isOverLiquified()?0
        :(tokenToSwap*liquidityTax)/totalTax;

        uint tokenForMarketing= tokenToSwap-tokenForLiquidity;

        uint LiqHalf=tokenForLiquidity/2;
        //swaps marktetingToken and the liquidity token half for ETH
        uint swapToken=LiqHalf+tokenForMarketing;
        //Gets the initial ETH balance, so swap won't touch any contract ETH
        uint initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint newETH=(address(this).balance - initialETHBalance);

        //calculates the amount of ETH belonging to the LP-Pair and converts them to LP
        if(tokenForLiquidity>0){
            uint liqETH = (newETH*LiqHalf)/swapToken;
            _addLiquidity(LiqHalf, liqETH);
        }
        //Sends all the marketing ETH to the marketingWallet
        (bool sent,)=marketingWallet.call{value:address(this).balance}("");
        sent=true;
    }
    //swaps tokens on the contract for ETH
    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(_uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();

        try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ){}
        catch{}
    }
    //Adds Liquidity directly to the contract where LP are locked
    function _addLiquidity(uint tokenamount, uint ethamount) private {
        _approve(address(this), address(_uniswapRouter), tokenamount);
        _uniswapRouter.addLiquidityETH{value: ethamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //public functions /////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 
    function getLiquidityReleaseTimeInSeconds() public view returns (uint){
        if(block.timestamp<_liquidityUnlockTime)
            return _liquidityUnlockTime-block.timestamp;
        return 0;
    }
    function getBurnedTokens() public view returns(uint){
        return (InitialSupply-_circulatingSupply)+_balances[address(0xdead)];
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //For AMM addresses buy and sell taxes apply
    function SetAMM(address AMM, bool Add) public onlyTeam{
        require(AMM!=_uniswapPairAddress,"can't change uniswap");
        isAMM[AMM]=Add;
    }
    
    bool public manualSwap;
    //switches autoLiquidity and marketing ETH generation during transfers
    function SwitchManualSwap(bool manual) public onlyTeam{
        manualSwap=manual;
    }
    //manually converts contract token to LP and staking ETH
    function SwapContractToken() public onlyTeam{
    _swapContractToken(true);
    }
    event ExcludeAccount(address account, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function ExcludeAccountFromFees(address account, bool exclude) public onlyTeam{
        require(account!=address(this),"can't Include the contract");
        excludedFromFees[account]=exclude;
        emit ExcludeAccount(account,exclude);
    }

    /////////////moussss///////////
     event ExcludeAccountLimit(address account, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function ExcludedFromLimit(address account, bool exclude) public onlyTeam{
        require(account!=address(this),"can't Include the contract");
        excludedFromLimit[account]=exclude;
        emit ExcludeAccountLimit(account,exclude);
    }



    //Enables trading. Sets the launch timestamp to the given Value
    event OnEnableTrading();
    uint public LaunchTimestamp;
    function SetupEnableTrading() public onlyTeam{
        require(LaunchTimestamp==0,"AlreadyLaunched");
        LaunchTimestamp=block.timestamp;
        emit OnEnableTrading();
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint _liquidityUnlockTime;
    bool public LPReleaseLimitedTo20Percent;
    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release. 
    //That way autoLiquidity can be slowly released 
    function limitLiquidityReleaseTo20Percent() public onlyTeam{
        LPReleaseLimitedTo20Percent=true;
    }
    //Locks Liquidity for seconds. can only be prolonged
    function LockLiquidityForSeconds(uint secondsUntilUnlock) public onlyTeam{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
    }
    event OnProlongLPLock(uint UnlockTimestamp);
    function _prolongLiquidityLock(uint newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
        emit OnProlongLPLock(_liquidityUnlockTime);
    }
    event OnReleaseLP();
    //Release Liquidity Tokens once unlock time is over
    function LiquidityRelease() public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");

        IERC20 liquidityToken = IERC20(_uniswapPairAddress);
        uint amount = liquidityToken.balanceOf(address(this));
        if(LPReleaseLimitedTo20Percent)
        {
            _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
            //regular liquidity release, only releases 50% at a time and locks liquidity for another week
            amount=amount*2/10;
        }
        liquidityToken.transfer(msg.sender, amount);
        emit OnReleaseLP();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
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

    // IERC20 - Helpers

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