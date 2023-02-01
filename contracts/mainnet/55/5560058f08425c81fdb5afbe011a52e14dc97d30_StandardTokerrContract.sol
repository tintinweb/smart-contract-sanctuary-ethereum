/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

/*

This contract is brought to you by Tokerr Factory

*/

pragma solidity ^0.8.16;

//SPDX-License-Identifier: MIT


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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public onlyOwner() {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
}

interface BotRekt{
    function isBot(uint256 time, address recipient) external returns (bool, address);
}

contract StandardTokerrContract is IERC20, Auth {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    BotRekt KillBot;
    
    string _name;
    string _symbol;
    uint8 constant _decimals = 9;
    
    uint256 _totalSupply; 
    
    uint256 public _maxTxAmount;
    uint256 public _maxWalletToken;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) lpProvider;
    address creator;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 launchTime;
    

    //fees are set with a 10x multiplier to allow for 2.5 etc. Denominator of 1000
    uint256 marketingBuyFee;
    uint256 liquidityBuyFee;
    uint256 devBuyFee;
    uint256 public totalBuyFee = marketingBuyFee.add(liquidityBuyFee).add(devBuyFee);

    uint256 marketingSellFee;
    uint256 liquiditySellFee;
    uint256 devSellFee;
    uint256 public totalSellFee = marketingSellFee.add(liquiditySellFee).add(devSellFee);

    uint256 marketingFee = marketingBuyFee.add(marketingSellFee);
    uint256 liquidityFee = liquidityBuyFee.add(liquiditySellFee);
    uint256 devFee = devBuyFee.add(devSellFee);

    uint256 totalFee = liquidityFee.add(marketingFee).add(devFee);

    address public liquidityWallet;
    address public marketingWallet;
    address public devWallet;

    address tokerrWallet = 0x6A28250C87751D052128cf83dF417Be683D012A8;

    address launchShield;

    uint256 transferCount = 1;

    string telegram;
    string website;

    //one time trade lock
    bool lockTilStart = true;
    bool lockUsed = false;

    bool launch = false;
    uint256 lsTime;

    //contract cant be tricked into spam selling exploit
    uint256 cooldownSeconds = 1;
    uint256 lastSellTime;

    event LockTilStartUpdated(bool enabled);

    bool botEnabled;

    bool limits = true;

    //This is to prevent dev buying more than max wallet and dumping. If max wallet exceeded from a buy, 24h cooldown til transfer. This will only be applicable to owner/authorized
    //the cooldown will allow projects using this in a legit manner to enable staking/buybacks etc
    mapping (address => uint256) devCooldown;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold;
    uint256 swapRatio = 40;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event TradeStarted(bool trading);
    event antiBotDisabled();

    //custom antibot
    bool customBot;
    uint256 earlyWallet;
    uint256 earlyTxn;


    constructor (uint[] memory numbers, address[] memory addresses, string[] memory names, 
                address antiBot, address builder, address _launch) Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));

        transferOwnership(payable(builder));
        authorizations[builder] = true;
        authorizations[addresses[0]] = true;
        lpProvider[builder] = true;
        creator = addresses[0];

        launchShield = _launch;
        authorizations[launchShield] = true;

        KillBot = BotRekt(antiBot);

        _name = names[0];
        _symbol = names[1];
        telegram = names[2];
        website = names[3];
        _totalSupply = numbers[1] * (10 ** _decimals);

        _allowances[address(this)][address(router)] = _totalSupply;

        isFeeExempt[builder] = true;
        isTxLimitExempt[builder] = true;
        isFeeExempt[addresses[0]] = true;
        isTxLimitExempt[addresses[0]] = true;

        swapThreshold = _totalSupply.mul(10).div(100000);

        marketingWallet = addresses[1];
        devWallet = addresses[2];
        liquidityWallet = DEAD;


        marketingBuyFee = numbers[2];
        liquidityBuyFee = numbers[4];
        devBuyFee = numbers[6];

        totalBuyFee = marketingBuyFee.add(liquidityBuyFee).add(devBuyFee).add(5);
        require(totalBuyFee <= 105, "Buy tax too high!"); //10% buy tax

        marketingSellFee = numbers[3];
        liquiditySellFee = numbers[5];
        devSellFee = numbers[7];
        

        totalSellFee = marketingSellFee.add(liquiditySellFee).add(devSellFee).add(5);
        require(totalSellFee <= 105, "Sell tax too high!"); //10% sell tax

        marketingFee = marketingBuyFee.add(marketingSellFee);
        liquidityFee = liquidityBuyFee.add(liquiditySellFee);
        devFee = devBuyFee.add(devSellFee);

        totalFee = liquidityFee.add(marketingFee).add(devFee).add(10);

        _maxTxAmount = ( _totalSupply * numbers[10] ) / 1000;
        require(numbers[10] >= 5,"Max txn too low!"); //0.5% max txn
        require(numbers[10] <= 30,"Max txn too high!"); //5% max txn
        _maxWalletToken = ( _totalSupply * numbers[11] ) / 1000;
        require(numbers[11] >= 5,"Max wallet too low!"); //0.5% max wallet
        require(numbers[11] <= 30,"Max wallet too high!"); //5% max wallet

        botEnabled = numbers[12] != 0 ? true : false;

        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);
        require(95 <= numbers[13] && numbers[13] <= 100, "Too low LP %");

        require(block.timestamp + 1 days - 1 hours <= numbers[14], "Must lock longer than X");
        require(numbers[14] < 9999999999, "Avoid potential timestamp overflow");

        uint256 lpDiv;

        //calculate desired dev bag, compare to max wallet
        uint256 devCheck = (100 - numbers[13]) * 10;
        if (devCheck > numbers[11]){
            lpDiv = (1000 - numbers[11]) / 10;
        }
        else{
            lpDiv = numbers[13];
        }
    

        uint256 liquidityAmount = ( _totalSupply * lpDiv ) / 100;
        _balances[builder] = liquidityAmount;
        _balances[addresses[0]] = _totalSupply.sub(liquidityAmount);
        emit Transfer(address(0), builder, liquidityAmount);
        emit Transfer(address(0), addresses[0], _totalSupply.sub(liquidityAmount));
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function getPair() external view returns (address){return pair;}

    function aboutMe() external view returns (string memory,string memory){
        return (telegram,website);
    }

    function updateAboutMe(string memory _telegram,string memory _website) external authorized{
        telegram = _telegram;
        website = _website;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function antibotEnabled() external view returns (bool){
        return botEnabled;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function assignLPProvider(address add) external{
        //can't be called until after launch, allows ownership to be renounced and still change who can take LP
        require(lpProvider[msg.sender], "Must be LP provider");
        lpProvider[add] = true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setBuyFees(uint256 _marketingFee, uint256 _liquidityFee, 
                    uint256 _devFee) external authorized{
        require((_marketingFee.add(_liquidityFee).add(_devFee)) <= 100);
        marketingBuyFee = _marketingFee;
        liquidityBuyFee = _liquidityFee;
        devBuyFee = _devFee;

        marketingFee = marketingSellFee.add(_marketingFee);
        liquidityFee = liquiditySellFee.add(_liquidityFee);
        devFee = devSellFee.add(_devFee);

        totalBuyFee = _marketingFee.add(_liquidityFee).add(_devFee).add(5);
        totalFee = liquidityFee.add(marketingFee).add(devFee).add(10);
    }
    
    function setSellFees(uint256 _marketingFee, uint256 _liquidityFee, 
                    uint256 _devFee) external authorized{
        require((_marketingFee.add(_liquidityFee).add(_devFee)) <= 100);
        marketingSellFee = _marketingFee;
        liquiditySellFee = _liquidityFee;
        devSellFee = _devFee;

        marketingFee = marketingBuyFee.add(_marketingFee);
        liquidityFee = liquidityBuyFee.add(_liquidityFee);
        devFee = devBuyFee.add(_devFee);

        totalSellFee = _marketingFee.add(_liquidityFee).add(_devFee).add(5);
        totalFee = liquidityFee.add(marketingFee).add(devFee).add(10);
    }

    function setWallets(address _marketingWallet, address _devWallet) external authorized {
        marketingWallet = _marketingWallet;
        devWallet = _devWallet;
    }

    function setMaxWallet(uint256 percent) external authorized {
        require(percent >= 5); //0.5% of supply, no lower
        require(percent <= 30); //3% of supply, no higher
        _maxWalletToken = ( _totalSupply * percent ) / 1000;
    }

    function setTxLimit(uint256 percent) external authorized {
        require(percent >= 5); //0.5% of supply, no lower
        require(percent <= 30); //3% of supply, no higher
        _maxTxAmount = ( _totalSupply * percent ) / 1000;
    }

    function getAddress() external view returns (address){
        return address(this);
    }

    
    function clearStuckBalance(uint256 amountPercentage) external  {
        uint256 amountETH = address(this).balance;
        payable(marketingWallet).transfer(amountETH * amountPercentage / 100);
    }

    function checkLimits(address sender,address recipient, uint256 amount) internal view {

        if ((block.timestamp > launchTime + 5 minutes) || customBot == false){
            if (!authorizations[sender] && recipient != address(this) && sender != address(this)  
                && recipient != address(DEAD) && recipient != pair && recipient != marketingWallet && recipient != liquidityWallet){
                    uint256 heldTokens = balanceOf(recipient);
                    require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
                }

            require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
        }
        else{
            if (!authorizations[sender] && recipient != address(this) && sender != address(this)  
                && recipient != address(DEAD) && recipient != pair && recipient != marketingWallet && recipient != liquidityWallet){
                    uint256 heldTokens = balanceOf(recipient);
                    require((heldTokens + amount) <= earlyWallet,"Total Holding is currently limited, you can not buy that much.");
                }

            require(amount <= earlyTxn || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");           
        }
    }

    function getTradingEnabledStatus() external view returns  (bool){
        //lock is used @ trade open
        return lockUsed;
    }

    function turnOffTokerrAntibot() external onlyOwner{
        botEnabled = false;
        emit antiBotDisabled();
    }

    function customAntibot(uint256 _maxWallet, uint256 _maxTransaction) external onlyOwner{
        customBot = true;
        require(_maxTransaction >= 1 && _maxTransaction <= 30);
        require(_maxWallet >= 1 && _maxWallet <= 30);

        earlyWallet = ( _totalSupply * _maxWallet ) / 1000;
        earlyTxn = ( _totalSupply * _maxTransaction ) / 1000;
    }

    function startTrading() external onlyOwner {
        if(lsTime > 0){
            require(block.timestamp > lsTime + 15 minutes);
        }
        require(lockUsed == false);
        lockTilStart = false;
        launchTime = block.timestamp;
        lockUsed = true;
        lpProvider[creator] = true;

        emit LockTilStartUpdated(lockTilStart);
        emit TradeStarted(true);
    }

    //cant call this til half an hour after launch to prevent prepump
    function liftMax() external  {
        require(lpProvider[msg.sender]);
        require(block.timestamp >= launchTime + 1800);
        limits = false;
    }

    function startTradingLaunchshield() external onlyOwner {
        require(lsTime == 0);
        launch = true;
        lsTime = block.timestamp;
        botEnabled = false;
    }
    
    function tradeCheck() internal view returns (bool){
        if (lockUsed){
            return true;
        }
        else if(lsTime != 0 && block.timestamp >= lsTime + 3600){
            return true;
        }
        else{
            return false;
        }
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function setTokenSwapSettings(bool _enabled, uint256 _threshold, uint256 _ratio) external authorized {
        require(_ratio > 0, "Ratio too low");
        require(_threshold > 0 && _threshold <= _totalSupply.div(10).div(10**9), "Threshold too low/high");
        swapEnabled = _enabled;
        swapThreshold = _threshold * (10 ** _decimals);
        swapRatio = _ratio;

    }
    
    function shouldTokenSwap(uint256 amount, address recipient) internal view returns (bool) {

        bool timeToSell = lastSellTime.add(cooldownSeconds) < block.timestamp;

        return recipient == pair
        && timeToSell
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold
        && _balances[address(this)] >= amount.mul(swapRatio).div(100);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 _totalFee;

        _totalFee = (recipient == pair) ? totalSellFee : totalBuyFee;

        uint256 feeAmount = amount.mul(_totalFee).div(1000);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function tokenSwap(uint256 _amount) internal swapping {

        uint256 amount = _amount.mul(swapRatio).div(100);
        //0.5% buy and sell, both sets of taxes added together in swap
        uint256 tokerr = 10;

        (amount > swapThreshold) ? amount : amount = swapThreshold;

        uint256 amountToLiquify = (liquidityFee > 0) ? amount.mul(liquidityFee).div(totalFee).div(2) : 0;

        uint256 amountToSwap = amount.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        bool tmpSuccess;

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = (liquidityFee > 0) ? totalFee.sub(liquidityFee.div(2)) : totalFee;
        

        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        if (devFee > 0){
            uint256 amountETHDev = amountETH.mul(devFee).div(totalETHFee);
            
            (tmpSuccess,) = payable(devWallet).call{value: amountETHDev, gas: 100000}("");
            tmpSuccess = false;
        }

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityWallet,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
        //after other fees are allocated, tokerrFee is calculated and taken before marketing
        uint256 tokerrFee = amountETH.mul(tokerr).div(totalETHFee);
        (tmpSuccess,) = payable(tokerrWallet).call{value: tokerrFee, gas: 100000}("");
        tmpSuccess = false;

        uint256 amountETHMarketing = address(this).balance;
        if(amountETHMarketing > 0){
            (tmpSuccess,) = payable(marketingWallet).call{value: amountETHMarketing, gas: 100000}("");
            tmpSuccess = false;
        }

        lastSellTime = block.timestamp;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (owner == msg.sender){
            return _basicTransfer(msg.sender, recipient, amount);
        }
        else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if ((sender == launchShield || recipient == launchShield) && launch){
            return _basicTransfer(sender, recipient, amount);
        }
        //this cooldown can NOT trigger on normal buyers who will always have 0 here, this is for devs trying to buy and dump supply
        require(devCooldown[sender] <= block.timestamp);
        if (sender == pair && recipient != pair && recipient != address(this) && balanceOf(recipient) + amount > _maxWalletToken){
            devCooldown[recipient] = (block.timestamp + 24 hours);
        }

        if(!lpProvider[sender] && !lpProvider[recipient]) {
                require(tradeCheck(),"Trading not open yet");
        }

        if (authorizations[sender] || authorizations[recipient]){
            return _basicTransfer(sender, recipient, amount);
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        
        if (sender == pair && recipient != address(this)){

            KillBot.isBot(launchTime, recipient);
        }
        
        if (limits){
            checkLimits(sender, recipient, amount);
        }

        if(shouldTokenSwap(amount, recipient)){ tokenSwap(amount); }
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = (recipient == pair || sender == pair) ? takeFee(sender, recipient, amount) : amount;


        

        _balances[recipient] = _balances[recipient].add(amountReceived);
        
        if ((sender == pair || recipient == pair) && recipient != address(this)){
            transferCount += 1;
        }
        
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountCoin);
}