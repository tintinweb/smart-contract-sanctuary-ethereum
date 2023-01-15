/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

/**        "ALPHA CENTAURI LAUNCHPAD"

TELEGRAM ; https://t.me/AlphaCentauriLaunchpad
WEBSITE  ; https://alphacentaurilaunchpad.com/
TWITTER  ; https://twitter.com/AClaunchpad
 *
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.13;


                                

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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

/**
 * ERC20 standard interface.
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

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
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

interface IDividendDistributor {
    function setRewardToken(address newRewardToken) external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
    function getDividendsClaimedOf (address shareholder) external returns (uint256);
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _owner;

    address public RewardToken;


    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalClaimed;
    uint256 public dividendsPerShare;
    uint256 private dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod;
    uint256 public minDistribution;

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

    modifier onlyOwner() {
        require(msg.sender == _owner); _;
    }

    constructor (address owner) {
        _token = msg.sender;
        _owner = owner;
    }

    receive() external payable { }

    function setRewardToken(address newRewardToken) external override onlyToken {
        RewardToken = newRewardToken;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
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

    function deposit(uint256 amount) external override onlyToken {
        
        if (amount > 0) {        
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

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

        uint256 amount = getClaimableDividendOf(shareholder);
        if(amount > 0){
            totalClaimed = totalClaimed.add(amount);
            shares[shareholder].totalClaimed = shares[shareholder].totalClaimed.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            IERC20(RewardToken).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
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

    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }
   
    function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        require (shares[shareholder].amount > 0, "You're not a Proxima shareholder!");
        return shares[shareholder].totalClaimed;
    }
}

contract ALPHACENTAURILAUNCHPAD is IERC20, Auth {
    using SafeMath for uint256;

    address public RewardToken;

    string private constant _name = "ALPHA CENTAURI LAUNCHPAD";
    string private constant _symbol = "$PROXIMA";
    uint8 private constant _decimals = 9;
    
    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) private cooldown;

    address private WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    bool public limitsInEffect = true;
    //bool public antiBot = true;

    //mapping (address => bool) private bots; 
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;

    uint256 public launchedAt;

    uint256 public burnFeeBuy = 10;
    uint256 public rewardFeeBuy = 40;
    uint256 public lpFeeBuy = 0;
    uint256 public marketingFeeBuy = 40;


    uint256 public rewardFeeSell = 40;
    uint256 public lpFeeSell = 0;
    uint256 public marketingFeeSell = 30;
    uint256 public burnFeeSell = 30;
    
    uint public feeDenominator = 1000;

    uint256 public totalFeeBuy = burnFeeBuy.add(lpFeeBuy).add(rewardFeeBuy).add(marketingFeeBuy);
    uint256 public totalFeeSell = burnFeeSell.add(lpFeeSell).add(rewardFeeSell).add(marketingFeeSell); 

    IDEXRouter public router;
    address public pair;

    DividendDistributor public distributor;
    uint256 public distributorGas = 0;

    address payable public marketingWallet = payable(0x59414621a029dB10d97c6d188AA0f0EA619b8242);
    address payable public deadWallet = payable(0x000000000000000000000000000000000000dEaD);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingActive = false;  

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public maxTx = _totalSupply.div(200);
    uint256 public maxWallet = _totalSupply.div(300);
    uint256 public swapThreshold = _totalSupply.div(250);

    constructor (
        address _owner        
    ) Auth(_owner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(_owner);
        
        isFeeExempt[_owner] = true;
        isFeeExempt[marketingWallet] = true;             
        isFeeExempt[deadWallet] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;    


        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;    


        _balances[_owner] = _totalSupply;
    
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function _updateRewardToken(address newRewardToken) internal {
        distributor.setRewardToken(newRewardToken);
    }

    function updateRewardToken(address newRewardToken) external onlyOwner {
        RewardToken = newRewardToken;
        _updateRewardToken(newRewardToken);
    }

    function changeDistributor(DividendDistributor newDistributor) external onlyOwner {
        distributor = newDistributor;
    }

    function changeFees(uint256 newBurnFeeBuy, uint256 newBurnFeeSell, uint256 newRewardFeeBuy, uint256 newRewardFeeSell, uint256 newLpFeeBuy, uint256 newLpFeeSell,
        uint256 newMarketingFeeBuy, uint256 newMarketingFeeSell) external onlyOwner {

        rewardFeeBuy = newRewardFeeBuy;
        lpFeeBuy = newLpFeeBuy;
        marketingFeeBuy = newMarketingFeeBuy;
        burnFeeBuy = newBurnFeeBuy;

        rewardFeeSell = newRewardFeeSell;
        lpFeeSell = newLpFeeSell;
        marketingFeeSell = newMarketingFeeSell;
        burnFeeSell = newBurnFeeSell;

        totalFeeBuy = burnFeeBuy.add(lpFeeBuy).add(rewardFeeBuy).add(marketingFeeBuy);
        totalFeeSell = burnFeeSell.add(lpFeeSell).add(rewardFeeSell).add(marketingFeeSell);

        require(totalFeeBuy <= 20, "don't be greedy dev");
        require(totalFeeSell <= 20, "don't be greedy dev");
    } 

    function changeMaxTx(uint256 newMaxTx) external onlyOwner {
        maxTx = newMaxTx;
    }

    function changeMaxWallet(uint256 newMaxWallet) external onlyOwner {
        maxWallet  = newMaxWallet;
    }

    function removeLimits(bool) external onlyOwner {            
        limitsInEffect = false;
    }
    
    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner {      
        isTxLimitExempt[holder] = exempt;
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
    }

    function setDeadWallet(address payable newDeadWallet) external onlyOwner {
        deadWallet = payable(newDeadWallet);
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        owner = newOwnerWallet;
    }     

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external onlyOwner {
        distributor.setDistributionCriteria(newMinPeriod, newMinDistribution);        
    }

    // function setBots(address[] memory bots_) external onlyOwner {
    //     for (uint i = 0; i < bots_.length; i++) {
    //         bots[bots_[i]] = true;
    //     }
    // }

    // function delBot(address notbot) external onlyOwner {
    //     bots[notbot] = false;
    // }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function changeDistributorGas(uint256 _distributorGas) external onlyOwner {
        distributorGas = _distributorGas;
    }           

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (sender!= owner && recipient!= owner) require(tradingActive, "Trading not yet active."); //transfers disabled before tradingActive
       // require([sender] && [recipient]);

        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

        require(amount <= maxTx || isTxLimitExempt[sender], "tx");

        if(!isTxLimitExempt[recipient])
        {
            require(_balances[recipient].add(amount) <= maxWallet, "wallet");
        }

        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        if (distributorGas > 0) {
            try distributor.process(distributorGas) {} catch {}
        }

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }    

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }  
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeApplicable = pair == recipient ? totalFeeSell : totalFeeBuy;
        uint256 feeAmount = amount.mul(feeApplicable).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal lockTheSwap {
        
        uint256 numTokensToSwap = _balances[address(this)];
        uint256 amountForLp = numTokensToSwap.mul(lpFeeSell).div(totalFeeSell).div(2);
        uint256 amountForRewardToken = numTokensToSwap.mul(rewardFeeSell).div(totalFeeSell);
        uint256 amountForBurnToken = numTokensToSwap.mul(burnFeeSell).div(totalFeeSell);
        uint256 amountToSwapForEth = numTokensToSwap.sub(amountForLp).sub(amountForRewardToken).sub(amountForBurnToken);
        

        swapTokensForEth(amountToSwapForEth);

        if (address(RewardToken) == address(this)) {
            IERC20(RewardToken).transfer(address(distributor), amountForRewardToken);
            distributor.deposit(amountForRewardToken);
        }

        if (address(RewardToken) != address(this)) {
            swapTokensForRewardToken(amountForRewardToken);
        }

    }

    function swapTokensForRewardToken(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = RewardToken;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 dividends = IERC20(RewardToken).balanceOf(address(this));

        bool success = IERC20(RewardToken).transfer(address(distributor), dividends);

        if (success) {
            distributor.deposit(dividends);            
        }     
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;
        uint256 amountToken = address(this).balance;
        uint256 marketingBalance = amountETH.mul(marketingFeeSell).div(totalFeeSell);
        uint256 deadBalance = amountToken.mul(burnFeeSell).div(totalFeeSell);

        uint256 amountEthLiquidity = amountETH.mul(lpFeeSell).div(totalFeeSell).div(2);

        if(amountETH > 0){          
            payable(marketingWallet).transfer(marketingBalance);
        }        
        if(amountToken > 0){          
            payable(deadWallet).transfer(deadBalance); 
            
        }        

        if(amountEthLiquidity > 0){
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountEthLiquidity,
                0,
                0,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp
            );
        }      
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function manualSendEth() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        uint256 contractTokenBalance = address(this).balance;

        uint256 marketingBalanceETH = contractETHBalance.mul(marketingFeeSell).div(totalFeeSell);
        uint256 deadBalanceToken = contractTokenBalance.mul(burnFeeSell).div(totalFeeSell);
        if(contractETHBalance > 0){          
            
            payable(marketingWallet).transfer(marketingBalanceETH);
        }
        if(contractTokenBalance > 0){          
            payable(deadWallet).transfer(deadBalanceToken); 
            
        }
    }

    //once enabled, cannot be reversed
    function openTrading() external onlyOwner {
        launchedAt = block.number;
        tradingActive = true;
    }      

    //dividend functions
    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }
    
    function claimDividend(address holder) external onlyOwner {
        distributor.claimDividend(holder);
    }
    
    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        return distributor.getClaimableDividendOf(shareholder);
    }

    function getTotalDividends() external view returns (uint256) {
        return distributor.totalDividends();
    }    

    function getTotalClaimed() external view returns (uint256) {
        return distributor.totalClaimed();
    }

    function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        return distributor.getDividendsClaimedOf(shareholder);
    }

    function manualProcessGas(uint256 manualGas) external onlyOwner {
        distributor.process(manualGas);
    }
}