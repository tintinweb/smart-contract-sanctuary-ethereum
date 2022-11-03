/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**SaneTest2 TOKEN

/**
 * IERC20 standard interface.
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

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
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

interface Rewards {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function myRewards(address shareholder) external;
    function changeReward(address newReward, string calldata newTicker, uint8 newDecimals) external;
}


contract SaneDispenser is Rewards {

    address _token;
    address private rewardToken;
    string private rewardTicker;
    uint8 private rewardDecimals;

    IDEXRouter router;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 0 * (10 ** 9);

    uint256 public currentIndex;
    bool initialized;

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        rewardToken = 0xe48975C57ca9B6Dd397767cC9D3491B8Eee4e4f8;
	rewardTicker = "CRT38";
        rewardDecimals = 18;
    }
    
    receive() external payable {
        deposit();
    }

    function changeReward(address newReward, string calldata newTicker, uint8 newDecimals) external override onlyToken {
        rewardToken = newReward;
        rewardTicker = newTicker;
	rewardDecimals = newDecimals;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    } 

    function setShare(address shareholder, uint256 amount) external override onlyToken {

        if(shares[shareholder].amount > 0){
            distributeReward(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares - (shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeRewards(shares[shareholder].amount);
    }

    function deposit() public payable override {

        uint256 balanceBefore = IERC20(rewardToken).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = IERC20(rewardToken).balanceOf(address(this)) - balanceBefore;
        totalRewards = totalRewards + amount;
        rewardsPerShare = rewardsPerShare + (rewardsPerShareAccuracyFactor * amount / totalShares);
    }
    
    function process(uint256 gas) external override {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while(gasUsed < gas && iterations < shareholderCount) {

            if(currentIndex >= shareholderCount){ currentIndex = 0; }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeReward(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) public view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeReward(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed + amount;
            IERC20(rewardToken).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeRewards(shares[shareholder].amount);
        }
    }
    
    function myRewards(address shareholder) external override onlyToken {
        distributeReward(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalRewards = getCumulativeRewards(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalRewards <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalRewards - shareholderTotalExcluded;
    }

    function getCumulativeRewards(uint256 share) internal view returns (uint256) {
        return share * rewardsPerShare / rewardsPerShareAccuracyFactor;
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

contract SaneTest is IERC20, Auth {

    address private WETH;
    address private rewardToken = 0xe48975C57ca9B6Dd397767cC9D3491B8Eee4e4f8;
    string private rewardTicker = "CRT38";
    uint8 private rewardDecimals = 18;

    string private constant _name = "SaneTest2";
    string private constant _symbol = "STD2";
    uint8 private constant _decimals = 9;
    
    uint256 _totalSupply = 10 * 10**6 * (10 ** _decimals);
    uint256 maxTx = 1 * 10**5 * (10 ** _decimals);
    uint256 maxWallet = 3 * 10**5 * (10 ** _decimals);

    uint256 public swapThreshold = 1 * 10**5 * (10 ** _decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private cooldown;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    bool public antiBot = true;

    mapping (address => bool) private bots;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isWltExempt;

    uint256 public launchedAt;
    address private lpWallet = DEAD;

    uint256 public buyFee = 6;
    uint256 public sellFee = 9;

    uint256 public toReflections = 30;
    uint256 public toLiquidity = 30;
    uint256 public toMarketing = 30;
    uint8 public preLaunch = 0;

    IDEXRouter public router;
    address public pair;
    address public factory;
    address public developmentWallet = payable(0xE7e2749203941CD4FdC8cC4C3C97C77DC866bB4A);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;
    
    SaneDispenser public saneDispenser;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address _owner) Auth(_owner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        saneDispenser = new SaneDispenser();
        
        isFeeExempt[_owner] = true;
        isFeeExempt[developmentWallet] = true;          

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[developmentWallet] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[developmentWallet] = true;   

	isWltExempt[_owner] = true;
    	isWltExempt[DEAD] = true;
    	isWltExempt[ZERO] = true;
    	isWltExempt[developmentWallet] = true;

        _balances[_owner] = _totalSupply;
    
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function setBots(address[] memory bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
        for (uint i = 0; i < bots_.length; i++) {
            isDividendExempt[bots_[i]] = true;
        }
    }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            saneDispenser.setShare(holder, 0);
        }else{
           saneDispenser.setShare(holder, _balances[holder]);
        }
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function changeIsWltExempt(address holder, bool exempt) external onlyOwner {
        isWltExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner {      
        isTxLimitExempt[holder] = exempt;
    }

    function preLaunchSequence() external onlyOwner {
    	require(preLaunch == 0, "Already launched");
    	tradingOpen = true;
    	preLaunch = 1;
    }

    function endPrelaunch() external onlyOwner {
    	require(preLaunch == 1);
    	tradingOpen = false;
    	preLaunch = 2;
    }

    function fullLaunch() external onlyOwner {
	require(preLaunch == 2);
        launchedAt = block.number;
        tradingOpen = true;
	preLaunch = 3;
    }

    function changeReward(address newReward, string calldata newTicker, uint8 newDecimals) external onlyOwner {
       saneDispenser.changeReward(newReward, newTicker, newDecimals);
        rewardToken = newReward;
        rewardTicker = newTicker;
        rewardDecimals = newDecimals;
    }

    function changeTotalFees(uint256 newBuyFee, uint256 newSellFee) external onlyOwner {

        buyFee = newBuyFee;
        sellFee = newSellFee;

        require(buyFee <= 10, "too high");
        require(sellFee <= 10, "too high");
    } 
    
    function changeFeeAllocation(uint256 newRewardFee, uint256 newLpFee, uint256 newMarketingFee) external onlyOwner {
        toReflections = newRewardFee;
        toLiquidity = newLpFee;
        toMarketing = newMarketingFee;
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        maxTx = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }

    function setDevelopmentWallet(address payable newDevelopmentWallet) external onlyOwner {
        developmentWallet = payable(newDevelopmentWallet);
    }

    function setLpWallet(address newLpWallet) external onlyOwner {
        lpWallet = newLpWallet;
    }    

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external onlyOwner {
        saneDispenser.setDistributionCriteria(newMinPeriod, newMinDistribution);        
    }

    function delBot(address notbot) external onlyOwner {
        bots[notbot] = false;
        isDividendExempt[notbot] = false;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function rewardTokenInfo() external view returns (address, string memory, uint8) 
        {return (rewardToken, rewardTicker, rewardDecimals);}
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (sender!= owner && recipient!= owner) require(tradingOpen, "Trading not active");
        require(!bots[sender] && !bots[recipient], "No");

        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

        require(amount <= maxTx || isTxLimitExempt[sender], "tx");

        if(!isTxLimitExempt[recipient] && antiBot)
        {
            require(_balances[recipient] + amount <= maxWallet || isWltExempt[sender], "wallet");
        }

        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;
        
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + finalAmount;

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try saneDispenser.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try saneDispenser.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }    

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }  
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeApplicable = pair == recipient ? sellFee : buyFee;
        uint256 feeAmount = amount * feeApplicable / 100;

        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(this), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpWallet,
            block.timestamp
        );
    }

    function swapBack() internal lockTheSwap {
    
        uint256 tokenBalance = _balances[address(this)]; 
        uint256 tokensForLiquidity = tokenBalance * toLiquidity / 90 / 2;     
        uint256 amountToSwap = tokenBalance - tokensForLiquidity;

        swapTokensForEth(amountToSwap);

        uint256 totalEthBalance = address(this).balance;
        uint256 ethForRewardToken = totalEthBalance * toReflections / 90;
        uint256 ethForCampaignWallet = totalEthBalance * toMarketing / 90;
        uint256 ethForLiquidity = totalEthBalance * toLiquidity / 90 / 2;
      
        if (totalEthBalance > 0){
            payable(developmentWallet).transfer(ethForCampaignWallet);
        }
        
        try saneDispenser.deposit{value: ethForRewardToken}() {} catch {}
        
        if (tokensForLiquidity > 0){
            addLiquidity(tokensForLiquidity, ethForLiquidity);
        }
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function clearStuckETH() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0){          
            payable(developmentWallet).transfer(contractETHBalance);
        }
    }

    function manualProcessGas(uint256 manualGas) external onlyOwner {
        saneDispenser.process(manualGas);
    }

    function checkPendingReflections(address shareholder) external view returns (uint256) {
        return saneDispenser.getUnpaidEarnings(shareholder);
    }

    function getRewards() external {
	require(!bots[msg.sender], "You get nothing");
        saneDispenser.myRewards(msg.sender);
    }
}