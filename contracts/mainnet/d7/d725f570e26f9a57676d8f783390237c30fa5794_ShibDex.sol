/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

/**
The DEX for the memes.
Twitter - @ShibDexSD
Tax - 4/8 (Usual, may change, check for updates on our socials.)
(Bots rekt on launch)
(Eth 2.0 and ShibDex, Hand in hand.)
*/



//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
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

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface InterfaceLP {
    function sync() external;
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function setToken(address token) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 25;

    uint256 public minPeriod = 45 * 60;
    uint256 public minDistribution = 1 * (10 ** 16);

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 public REWARD_TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 currentIndex;
    bool initialized;

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function getTotalShares() external view returns (uint256) { return totalShares; }
    function getUsers() external view returns (address[] memory) { return shareholders; }
    function getUserShare(address user) external view returns (uint256) { return shares[user].amount; }

    function setToken(address token) external override onlyToken {
        REWARD_TOKEN = IERC20(token);
        WETH = router.WETH();
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = REWARD_TOKEN.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(REWARD_TOKEN);
        
        if(address(REWARD_TOKEN) != WETH) {
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        
        uint256 amount = REWARD_TOKEN.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){ currentIndex = 0; }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            REWARD_TOKEN.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
   
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract ShibDex is IERC20, Auth {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "ShibDex";
    string constant _symbol = "SD";
    uint8 constant _decimals = 9;

    //mapping (address => uint256) _balances;
    mapping (address => uint256) _rBalance;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isTimelockExempt;
    mapping (address => bool) public isDividendExempt;

    bool public blacklistMode = true;
    mapping (address => bool) public isBlacklisted;

    uint256 public deadBlocks = 2;
    uint256 public launchedAt = 0;

    //5% on Buy
    uint256 public liquidityFee    = 1;
    uint256 public rewardFee   = 0;
    uint256 public marketingFee    = 2;
    uint256 public DevelopmentFee      = 1;
    uint256 public totalFee = marketingFee + rewardFee + liquidityFee + DevelopmentFee;
    uint256 public feeDenominator  = 100;

    uint256 public sellMultiplier  = 200; //2.5x i.e 4x2= 8% on Sell

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public DevelopmentFeeReceiver;

    IDEXRouter public router;
    address public pair;

    InterfaceLP public pairContract; 

    bool public tradingOpen = false;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 15;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    bool public zeroBuyTaxMode = false;
    
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 75 * 10**7 * 10**_decimals;
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 public rate;
    uint256 public _totalSupply;
    uint256 private constant rSupply = INITIAL_FRAGMENTS_SUPPLY;
    uint256 public swapThreshold = rSupply * 10 / 10000;

    // Max wallet & Transaction
    uint256 public _maxTxAmount = rSupply.div(50);      //1%
    uint256 public _maxWalletToken = rSupply.div(25);    //2%

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = uint256(-1);

        pairContract = InterfaceLP(pair);
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        rate = rSupply.div(_totalSupply);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0x15736d3561C0C8c93e764fa0C67a4aBcc34BC7b1;
        DevelopmentFeeReceiver = 0x9450Ade82352eD9ac05d5901D78a3a6943d36F9e;

        _rBalance[msg.sender] = rSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }

    function balanceOf(address account) public view override returns (uint256) {
        return _rBalance[account].div(rate);
    }
    
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function isNotInSwap() external view returns (bool) { return !inSwap; }
    function checkSwapThreshold() external view returns (uint256) { return swapThreshold.div(rate); }
    function checkMaxWalletToken() external view returns (uint256) { return _maxWalletToken.div(rate); }
    function checkMaxTxAmount() external view returns (uint256) { return _maxTxAmount.div(rate); }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(!authorizations[sender]){ require(tradingOpen,"Trading not open yet"); }

        uint256 rAmount = amount.mul(rate);

        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != DevelopmentFeeReceiver  && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + rAmount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }
        
        if (sender == pair &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"buy Cooldown exists");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        // Blacklist
        if(blacklistMode){ require(!isBlacklisted[sender] && !isBlacklisted[recipient],"Blacklisted"); }

        // Checks max transaction limit
        checkTxLimit(sender, rAmount);

        if(shouldSwapBack()){ swapBack(); }

        //Exchange tokens
        _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");

        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? rAmount : takeFee(sender, rAmount,(recipient == pair));
        _rBalance[recipient] = _rBalance[recipient].add(amountReceived);

        // Dividend tracker
        if(!isDividendExempt[sender]) { try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]) { try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
        try distributor.process(distributorGas) {} catch {}
        emit Transfer(sender, recipient, amountReceived.div(rate));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 rAmount = amount.mul(rate);
        _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");
        _rBalance[recipient] = _rBalance[recipient].add(rAmount);
        emit Transfer(sender, recipient, rAmount.div(rate));
        return true;
    }

    function checkTxLimit(address sender, uint256 rAmount) internal view {
        require(rAmount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 rAmount, bool isSell) internal returns (uint256) {
        uint256 multiplier = 100;
        if(isSell){ multiplier = sellMultiplier; }
        if(zeroBuyTaxMode && !isSell){ multiplier = 0; }

        uint256 feeAmount = rAmount.div(feeDenominator * 100).mul(totalFee).mul(multiplier);

        if(!isSell && (launchedAt + deadBlocks) > block.number){ feeAmount = rAmount.div(100).mul(90); }

        _rBalance[address(this)] = _rBalance[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount.div(rate));
        return rAmount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _rBalance[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 tokensToSell = swapThreshold.div(rate);

        uint256 amountToLiquify = tokensToSell.div(totalFee).mul(dynamicLiquidityFee).div(2);
        uint256 amountToSwap = tokensToSell.sub(amountToLiquify);

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

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(rewardFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHDevelopment = amountETH.mul(DevelopmentFee).div(totalETHFee);

        try distributor.deposit{value: amountETHReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(DevelopmentFeeReceiver).call{value: amountETHDevelopment, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify.div(rate));
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized { isFeeExempt[holder] = exempt; }
    function setZeroBuyTaxMode(bool _zeroBuyTaxMode) external authorized { zeroBuyTaxMode=_zeroBuyTaxMode; }
    function setIsTxLimitExempt(address holder, bool exempt) external authorized { isTxLimitExempt[holder] = exempt; }
    function setIsTimelockExempt(address holder, bool exempt) external authorized { isTimelockExempt[holder] = exempt; }
    function manualSync() external { InterfaceLP(pair).sync(); }
    function changeRewardToken(address newRewardToken)  external onlyOwner()  { distributor.setToken(newRewardToken); }
    function launchStatus(uint256 _launchblock) public onlyOwner { launchedAt = _launchblock; }
    function enable_blacklist(bool _status) public onlyOwner { blacklistMode = _status; }
    function set_sell_multiplier(uint256 Multiplier) external onlyOwner{ sellMultiplier = Multiplier; }

    // switch Trading
    function tradingStatus(bool _status, uint256 _deadBlocks) public onlyOwner {
        tradingOpen = _status;
        if(tradingOpen && launchedAt == 0){
            launchedAt = block.number;
            deadBlocks = _deadBlocks;
        }
    }

    function manage_blacklist(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) { isBlacklisted[addresses[i]] = status; }
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountETH * amountPercentage / 100);
    }

    function clearStuckBalance_sender(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }

    function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        require (address(tokenAddress) != address(this));
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function multiTransfer(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {
        require(owner == from,"Aidrops only from owner");
        require(addresses.length < 2001,"GAS Error: max airdrop limit is 2000 addresses"); // to prevent overflow

        uint256 SCCC = tokens** (10**_decimals) * addresses.length;
        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens * (10**_decimals));
            if(!isDividendExempt[addresses[i]]) { try distributor.setShare(addresses[i], balanceOf(addresses[i])) {} catch {} }
        }

        // Dividend tracker
        if(!isDividendExempt[from]) { try distributor.setShare(from, balanceOf(from)) {} catch {} }
    }

    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function setFees(uint256 _liquidityFee, uint256 _rewardFee, uint256 _marketingFee, uint256 _DevelopmentFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        rewardFee = _rewardFee;
        marketingFee = _marketingFee;
        DevelopmentFee = _DevelopmentFee;
        totalFee = _liquidityFee.add(_rewardFee).add(_marketingFee).add(_DevelopmentFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4, "Fees cannot be more than 25%");
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){ distributor.setShare(holder, 0); }
        else{ distributor.setShare(holder, balanceOf(holder)); }
    }
    
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _DevelopmentFeeReceiver ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        DevelopmentFeeReceiver = _DevelopmentFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentage_base100000) external authorized {
        swapEnabled = _enabled;
        swapThreshold = rSupply.div(100000).mul(_percentage_base100000);
    }
    
    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        isFeeExempt[_address];
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 10000000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (rSupply.sub(_rBalance[DEAD]).sub(_rBalance[ZERO])).div(rate);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        _maxWalletToken = rSupply.mul(maxWallPercent_base1000).div(1000);
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner() {
        _maxTxAmount = rSupply.mul(maxTXPercentage_base1000).div(1000);
    }

    event AutoLiquify(uint256 amountETH, uint256 amountTokens);
}