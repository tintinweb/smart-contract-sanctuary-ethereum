/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

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

pragma solidity =0.8.17;
contract NIHON is IERC20, Ownable  
{
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromLimits;
    mapping(address => bool) public excludedFromFees;
    mapping(address=>bool) public isAMM;
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;
    
    string private constant _name = 'Nihon Inu';
    string private constant _symbol = 'NINU';

    uint8 private constant _decimals=18;

    uint private constant InitialSupply=10**9 * 10**_decimals;
    uint public buyTax = 50; //10=1%  
    uint public sellTax = 350;
    uint public transferTax = 0;
    uint public liquidityTax= 0;
    uint public Tax= 1000; // lp+tax must equal 1000 // 1000=100%
    uint public swapTreshold=10; //Dynamic Swap Threshold based on price impact. 1=0.1% max 10
    uint public overLiquifyTreshold=100;
    uint public LaunchTimestamp;
    uint private devFee=100; //devfee+marketingfee must = 100 
    uint private marketingFee= 0;
    uint constant TAX_DENOMINATOR=1000;
    uint constant MAXTAXDENOMINATOR=10;

    uint256 public maxWalletBalance;
    uint256 public maxTransactionAmount;
    uint256 public percentForLPBurn = 25; // 25 = .25%
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;
    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public lastManualLpBurnTime;

    bool private _isSwappingContractModifier;
    bool public manualSwap;
    bool public lpBurnEnabled = true;

    IDexRouter private  _DexRouter;

    address private _PairAddress; 
    address public marketingWallet;
    address public devWallet; 
    address public constant burnWallet=address(0xdead);
    address private constant DexRouter= 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
    
    event ManualNukeLP();
    event AutoNukeLP();
    event MaxWalletBalanceUpdated(uint256 percent);
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint project,uint liquidity);
    event ExcludeAccount(address account, bool exclude);
    event OnEnableTrading();
    event OnReleaseLP();
    event ExcludeFromLimits(address account, bool exclude);
    event MarketingWalletChange(address newWallet);
    event DevWalletChange(address newWallet);
    event SharesUpdated(uint _devShare, uint _marketingShare);
    event AMMadded(address AMM);
    event ManualSwapOn(bool manual);
    event ManualSwapPerformed();
    event MaxTransactionAmountUpdated(uint256 percent);
    event SwapThresholdChange(uint newSwapTresholdPermille);
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
        
        marketingWallet= msg.sender; // address(0xdead)
        devWallet= msg.sender; // msg.sendger

        excludedFromFees[msg.sender]=true;
        excludedFromFees[DexRouter]=true;
        excludedFromFees[address(this)]=true;
        excludedFromLimits[burnWallet] = true;
        excludedFromLimits[address(this)] = true;
    }
    function ChangeMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet=newWallet;
        emit MarketingWalletChange(newWallet);
    }
    function ChangeDevWallet(address newWallet) external onlyOwner{
        devWallet=newWallet;
        emit DevWalletChange(newWallet);
    }
    function SetFeeShares(uint _devFee, uint _marketingFee) external onlyOwner{
        require(_devFee+_marketingFee<=100);
        devFee=_devFee;
        marketingFee=_marketingFee;
        emit SharesUpdated(_devFee, _marketingFee);
    }
    function setRestrictionPercents(uint256 WALpercent, uint256 TXNpercent) external onlyOwner {
        require(WALpercent >= 10, "min 1%"); // 10=1%
        require(WALpercent <= 1000, "max 100%");
        maxWalletBalance = InitialSupply * WALpercent / 1000;
        require(TXNpercent >= 25, "min 0.25%");
        require(TXNpercent <= 10000, "max 100%"); // 100=1%
        maxTransactionAmount = InitialSupply * TXNpercent / 10000;
        emit MaxWalletBalanceUpdated(WALpercent);
        emit MaxTransactionAmountUpdated(TXNpercent);
    }

    function removeAllRestrictions() external onlyOwner {
        maxWalletBalance = InitialSupply;
        maxTransactionAmount = InitialSupply;
        transferDelayEnabled = false;
    }
    function removetransferdelay() external onlyOwner {
        transferDelayEnabled = false;
    }    
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
         if (transferDelayEnabled){
                    if (recipient != owner() && recipient != DexRouter && recipient != _PairAddress){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
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
            tax=sellTax;
        }else if(isBuy){
            tax=buyTax;
        }else{
            tax=transferTax;
        }

        if((sender!=_PairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
            _swapContractToken(false);

        if(!_isSwappingContractModifier && isAMM[recipient] && lpBurnEnabled && block.timestamp >= lastLpBurnTime + lpBurnFrequency){
            autoBurnLPTokens();
        }

        uint contractToken=_calculateFee(amount, tax, Tax+liquidityTax);
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
    function SetOverLiquifiedTreshold(uint newOverLiquifyTresholdPermille) external onlyOwner{
        require(newOverLiquifyTresholdPermille<=1000);
        overLiquifyTreshold=newOverLiquifyTresholdPermille;
        emit OverLiquifiedThresholdChange(newOverLiquifyTresholdPermille);
    }
    function SetTaxes(uint buy, uint sell, uint transfer_, uint tax,uint liquidity) external onlyOwner{
        uint maxTax=400; // 10= 1%
        require(buy<=maxTax&&sell<=maxTax&&transfer_<=maxTax,"Tax exceeds maxTax");
        require(tax+liquidity==TAX_DENOMINATOR,"Taxes don't add up to denominator");
        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        Tax=tax;
        liquidityTax=liquidity;
        emit OnSetTaxes(buy, sell, transfer_, tax, liquidity);
    }
    function isOverLiquified() public view returns(bool){
        return _balances[_PairAddress]>getCirculatingSupply()*overLiquifyTreshold/1000;
    }
    function _swapContractToken(bool ignoreLimits) private lockTheSwap{
        uint contractBalance=_balances[address(this)];
        uint totalTax=liquidityTax+Tax;
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
        uint marketbalance=address(this).balance * marketingFee/100;
        uint devbalance=address(this).balance * devFee/100;
        if(marketbalance>0){
        (bool marketing,)=marketingWallet.call{value:marketbalance}("");
        marketing=true;
        }
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
        require(AMM!=_PairAddress,"can't change uniswap");
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
        maxWalletBalance = InitialSupply * 20 / 1000;// 10=1%  
        maxTransactionAmount = InitialSupply * 150 / 10000;// 100=1%  
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
            _balances[_PairAddress]-=amountToBurn;
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
            _balances[_PairAddress]-=amountToBurn;
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