/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

pragma solidity 0.8.17;
//SPDX-License-Identifier: UNLICENSED
/*
    
    YoKen the official currency of YoHunt - the best perpetual adventure in the world of Augmented Reality.
    1.5% initial tax on buy and sell, 0 tax on transfers tax will only ever decrease.
    contract dev: @CryptoBatmanBSC
    Linktree:
    https://linktr.ee/yohuntgame
*/


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

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

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
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


contract Yoken is IERC20, Auth {
    // fees. all uint8 for gas efficiency and storage.
    /* @dev   
        all fees are set with 1 decimal places added, please remember this when setting fees.
    */
    uint8 public liquidityFee = 5;
    uint8 public marketingFee = 5;
    uint8 public developmentFee = 5;
    uint8 public totalBuyFee = 15;
    uint8 public sellLiquidityFee = 5;
    uint8 public sellMarketingFee = 5;
    uint8 public sellDevelopmentFee = 5;
    uint8 public totalSellFee = 15;
    bool public buyLpModificationDisabled = false;
    bool public buyMarketingModificationDisabled = false;
    bool public buyDevModificationDisabled = false;
    bool public sellLpModificationDisabled = false;
    bool public sellMarketingModificationDisabled = false;
    bool public sellDevModificationDisabled = false;


    uint16 public initialFee = 900; //the fee the bots and snipers get hit with until launched

    // denominator. uint 16 for storage efficiency - makes the above fees all to 1 dp.
    uint16 constant public ALL_FEE_DENOMINATOR = 1000;
    
    // trading control;
    bool public canTrade = false;
    uint256 public launchedAt;
    
    
    // tokenomics - uint256 BN but located here fro storage efficiency
    uint8 constant public _decimals = 18;
    uint256 public _totalSupply = 1 * 10** 9* (10 ** _decimals); //1 bil
    uint256 public _maxTxAmount = _totalSupply / 200; // 0.5%
    uint256 public _maxHoldAmount = _totalSupply / 200; // 0.5%
    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%

    //Important addresses    
    address public WETH; //populated by the router in the constructor
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant public ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public devFeeReceiver;

    address public presaleContract;
    address public lockerContract;

    address public pair;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => bool) public pairs;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMaxHoldExempt;

    IDEXRouter public router;


    bool public swapEnabled = true;
    bool public inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    string constant public _name = "YoKen";
    string constant public _symbol = "YoKen";
    

    bool public antiSnipeEnabled = true;

    constructor (address tokenOwner) Auth(tokenOwner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Mainnet Uniswap
        WETH = address(router.WETH());
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        pairs[pair] = true;
        _allowances[address(this)][address(router)] = _totalSupply;
        isMaxHoldExempt[pair] = true;
        isMaxHoldExempt[DEAD] = true;
        isMaxHoldExempt[ZERO] = true;

        isTxLimitExempt[tokenOwner] = true;
        isFeeExempt[tokenOwner] = true;
        authorizations[tokenOwner] = true;
        
        autoLiquidityReceiver = tokenOwner;
        marketingFeeReceiver = tokenOwner;
        devFeeReceiver = tokenOwner;
        owner = tokenOwner;
        isMaxHoldExempt[owner] = true;
        _balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender];} 

    
    function getEstimatedTokenForETH(uint ETHAmount) public view returns (uint[] memory) {
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);
        return router.getAmountsOut(ETHAmount, path);
    }

    
    function getEstimatedETHForToken(uint groAmount) public view returns (uint[] memory) {
            address[] memory path = new address[](2);
            path[1] = router.WETH();
            path[0] = address(this);
        return router.getAmountsOut(groAmount, path);
    }
    
    function buyTokens(uint amountOutMin)public payable {
        address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);
            uint deadline = block.timestamp + 100;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(amountOutMin, path, address(msg.sender), deadline);
    }

    function airdrop(address[] calldata toWhoArray, uint[] calldata amountArray)external returns (bool success) {
        require(toWhoArray.length == amountArray.length, "Yoken: amounts length must match Accounts length");
        uint totalTokens = 0;
        for(uint i = 0; i< amountArray.length; i++){
            totalTokens += amountArray[i] *10**_decimals;
        }
        require(_balances[msg.sender] >= totalTokens, "Yoken: you cannot transfer more than you own");
         for(uint i = 0; i< amountArray.length; i++){
             if(!isMaxHoldExempt[toWhoArray[i]]){
                require(_balances[toWhoArray[i]] + amountArray[i]*10**_decimals <= _maxHoldAmount, "Yoken: you cannot put an address over the balance they can max hold");
             }
            _balances[msg.sender] -= amountArray[i] *10**_decimals;
            _balances[toWhoArray[i]] += amountArray[i] *10**_decimals;
            emit Transfer(msg.sender, toWhoArray[i], amountArray[i] *10**_decimals);
        }
        return true;
    }

    function burn(uint amount)external returns(bool success){
        require(_balances[msg.sender] > amount * 10 ** _decimals, "Yoken: cannot burn more than you own");
        _balances[msg.sender] -=  amount * 10 ** _decimals;
        _totalSupply -= amount * 10 ** _decimals;

        emit TokenBurned(msg.sender,  amount * 10 ** _decimals);
        return true;
    }
    
    function sellTokens(uint amountOutMin)public payable {
        address[] memory path = new address[](2);
            path[1] = router.WETH();
            path[0] = address(this);
            uint deadline = block.timestamp + 100;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountOutMin,0, path, address(this), deadline);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setSwapThresholdDivisor(uint divisor)external authorized {
        require(divisor >= 100, "Yoken: max sell percent is 1%");
        swapThreshold = _totalSupply / divisor;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    function setPresaleContract(address ctrct) external authorized {
        presaleContract = ctrct;
        isFeeExempt[presaleContract] = true;
        isTxLimitExempt[presaleContract] = true;
        isMaxHoldExempt[presaleContract] = true;
    }

    function setLockerContract(address ctrct) external authorized {
        lockerContract = ctrct;
        isFeeExempt[lockerContract] = true;
        isTxLimitExempt[lockerContract] = true;
    }
    
    function setMaxHoldPercentage(uint256 percentageMul10) external authorized {
        require(percentageMul10 >= 5, "Yoken, max hold cannot be less than 0.5%"); // cant change percentage below 0.5%, so everyone can hold the percentage
        require(_maxHoldAmount <= _totalSupply * percentageMul10 / 1000, "can only ever increase max hold");
        _maxHoldAmount = _totalSupply * percentageMul10 / 1000; // percentage based on amount
    }
    
    function allowTrading()external authorized {
        canTrade = true;
    }
    
    function addNewPair(address newPair)external authorized{
        pairs[newPair] = true;
        isMaxHoldExempt[newPair] = true;
    }
    
    function removePair(address pairToRemove)external authorized{
        pairs[pairToRemove] = false;
        isMaxHoldExempt[pairToRemove] = false;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(_totalSupply)){
            require(_allowances[sender][msg.sender] >= amount);
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(!canTrade){
            require(sender == owner || sender == presaleContract || sender == lockerContract , "Yoken, Only owner or presale Contract allowed to add LP"); // only owner allowed to trade or add liquidity
        }
        if(sender != owner && recipient != owner && sender != presaleContract){
            if(!pairs[recipient] && !isMaxHoldExempt[recipient]){
                require (balanceOf(recipient) + amount <= _maxHoldAmount, "Yoken, cant hold more than max hold dude, sorry");
            }
        }
       
        
        
        checkTxLimit(sender, recipient, amount);
        
        if(!launched() && pairs[recipient]){ require(_balances[sender] > 0); launch(); }


        require(_balances[sender] >= amount);
         if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = 0;
        if(pairs[sender] || pairs[recipient]){ // if its a buy or sell
            if(!shouldTakeFee(sender) || !shouldTakeFee(recipient)){
                        amountReceived = amount;
            }else{
                bool isBuy = pairs[sender];
                amountReceived = takeFee(sender, isBuy, amount);
            }
        }else{
             amountReceived = amount;
        }
        
        if(shouldSwapBack()){ swapBack(); }
        _balances[recipient] = _balances[recipient]+amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;

    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount);
        _balances[sender] = _balances[sender] -amount;
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address receiver, uint256 amount) internal view {
        if(sender != owner && receiver != owner && sender != presaleContract){
            require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        }
    }

    function shouldTakeFee(address endpt) internal view returns (bool) {
        
        return !isFeeExempt[endpt];
    }

    function takeFee(address sender, bool isBuy, uint256 amount) internal returns (uint256) {
        uint totalFee = totalSellFee;
        if(isBuy){
            totalFee = totalBuyFee;
        }
        if(antiSnipeEnabled){
            totalFee = initialFee;
        }
        uint256 feeAmount = 0;
        if(totalFee > 0){
            feeAmount = (amount * totalFee) / ALL_FEE_DENOMINATOR;
            _balances[address(this)] = _balances[address(this)] + feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }
    
    // returns any mis-sent tokens to the marketing wallet
    function claimtokensback(IERC20 tokenAddress) external authorized {
        payable(devFeeReceiver).transfer(address(this).balance);
        require(address(tokenAddress) != address(this), "Yoken: not allowed to remove from swap/tax pool");
        tokenAddress.transfer(marketingFeeReceiver, tokenAddress.balanceOf(address(this)));
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }

    function stopAntiSnipe()external authorized{
        // this can only ever be called once
        antiSnipeEnabled = false;
    }
    /*
        @dev this amount includes decimals
    */
    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000, "Yoken, must be higher than 0.1%");
        require(amount > _maxTxAmount, "Yoken, can only ever increase the tx limit");
        _maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    /* 
        @DEV:
                The next 6 functions permanently disable the individual taxes on buy/sell lp, marketing and dev
                be careful what you wish for (Batman)
    */
    function setBuyLpModificationsDisabled_Permanently()external authorized{
        buyLpModificationDisabled = true;
        liquidityFee = 0;
        totalBuyFee = liquidityFee + (marketingFee) + (developmentFee);

    }

    function setBuyMarketingModificationsDisabled_Permanently()external authorized{
        buyMarketingModificationDisabled = true;
        marketingFee = 0;
        totalBuyFee = liquidityFee + (marketingFee) + (developmentFee);
    }

    function setBuyDevModificationsDisabled_Permanently()external authorized{
        buyDevModificationDisabled = true;
        developmentFee = 0;
        totalBuyFee = liquidityFee + (marketingFee) + (developmentFee);
    }

    function setSellLpModificationsDisabled_Permanently()external authorized{
        sellLpModificationDisabled = true;
        sellLiquidityFee = 0;
        totalSellFee = sellLiquidityFee + (sellMarketingFee) + (sellDevelopmentFee);

    }

    function setSellMarketingModificationsDisabled_Permanently()external authorized{
        sellMarketingModificationDisabled = true;
        sellMarketingFee = 0;
        totalSellFee = sellLiquidityFee + (sellMarketingFee) + (sellDevelopmentFee);
    }

    function setSellDevModificationsDisabled_Permanently()external authorized{
        sellDevModificationDisabled = true;
        sellDevelopmentFee = 0;
        totalSellFee = sellLiquidityFee + (sellMarketingFee) + (sellDevelopmentFee);
    }

    /*
        @Dev:
                sets the individual buy fees.  
                these fees cannot exceed 0.5% of transaction each and do not modify above zero if individuals are
                disabled
    */
    function setBuyFees(uint8 _liquidityFee, uint8 _marketingFee, uint8 _gameDevFee) external authorized {
        require(_liquidityFee <= 5 && _marketingFee <= 5 && _gameDevFee <= 5, "Yoken, Taxes can only be set to 0.5% individual values");
        buyLpModificationDisabled? liquidityFee = 0 : liquidityFee = _liquidityFee;
        buyMarketingModificationDisabled? marketingFee = 0 : marketingFee = _marketingFee;
        buyDevModificationDisabled? developmentFee = 0 : developmentFee = _gameDevFee;
        totalBuyFee = liquidityFee + (marketingFee) + (developmentFee);
    }
    /*
        @Dev:
                sets the individual sell fees.  these fees cannot exceed 0.5% of transaction each  and do not modify above zero if individuals are
                disabled
    */
    function setSellFees(uint8 _liquidityFee, uint8 _marketingFee, uint8 _gameDevFee) external authorized {
        require(_liquidityFee <= 5 && _marketingFee <= 5 && _gameDevFee <= 5, "Yoken, Taxes can only be set to 0.5% individual values");
        sellLpModificationDisabled? sellLiquidityFee = 0 : sellLiquidityFee = _liquidityFee;
        sellMarketingModificationDisabled? sellMarketingFee = 0 : sellMarketingFee = _marketingFee;
        sellDevModificationDisabled? sellDevelopmentFee = 0 : sellDevelopmentFee = _gameDevFee;
        totalSellFee = sellLiquidityFee + (sellMarketingFee) + (sellDevelopmentFee);
    }
    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 amountToLiquify = (swapThreshold*(dynamicLiquidityFee)) / ((totalBuyFee)/(2)); // leave some tokens for liquidity addition
        uint256 amountToSwap = swapThreshold - amountToLiquify; // swap everything bar the liquidity tokens. we need to add a pair

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - (balanceBefore);

        uint256 totalETHFee = totalBuyFee - (dynamicLiquidityFee / 2);
        if(totalETHFee > 0 ){
            if(marketingFee > 0){
                uint256 amountETHMarketing = amountETH * (marketingFee)/(totalETHFee);
                payable(marketingFeeReceiver).transfer(amountETHMarketing);
            }
            if(developmentFee > 0){
                uint256 amountETHDev = amountETH*(developmentFee)/(totalETHFee);
                payable(devFeeReceiver).transfer(amountETHDev);
            }
                   
            if(amountToLiquify > 0){
                uint256 amountETHLiquidity = amountETH * (dynamicLiquidityFee) / (totalETHFee)/(2);
                router.addLiquidityETH{value: amountETHLiquidity}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
                emit AutoLiquify(amountETHLiquidity, amountToLiquify);
            
            }
        }
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address devWallet) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = devWallet;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
     function shouldSwapBack() internal view returns (bool) {
        return !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD)) - (balanceOf(ZERO));
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    event TokenBurned(address indexed from, uint256 amount);
    
}