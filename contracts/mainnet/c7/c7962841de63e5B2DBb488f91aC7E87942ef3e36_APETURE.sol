// SPDX-License-Identifier: Unlicensed

/*
 *  
 *  https://www.apeture.org/
 *  https://t.me/Apeture
 */
 

pragma solidity ^0.8.6;

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

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyDeployer() {
        require(isOwner(msg.sender), "!D"); _;
    }

    /**
     * Function modifier to require caller to be owner
     */
    modifier onlyOwner() {
        require(isAuthorized(msg.sender), "!OWNER"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyDeployer {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Deployer only
     */
    function unauthorize(address adr) public onlyDeployer {
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
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyDeployer {
        owner = adr;
        authorizations[adr] = true;
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
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimDividend(address shareholder) external;
    function setDividendToken(address dividendToken) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 dividendToken;
    IDEXRouter router;
    
    address WETH;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    
    address owner;

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
        require(msg.sender == owner); _;
    }
    
    event DividendTokenUpdate(address dividendToken);

    constructor (address _router, address _dividendToken, address _owner) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        dividendToken = IERC20(_dividendToken);
        WETH = router.WETH();
        owner = _owner;
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
        uint256 balanceBefore = dividendToken.balanceOf(address(this));

        // address[] memory path = new address[](2);
        // path[0] = WETH;
        // path[1] = address(dividendToken);

        // router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp
        // );

        IWETH(WETH).deposit{value: msg.value}();

        uint256 amount = dividendToken.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            dividendToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
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
    
    function setDividendToken(address _dividendToken) external override onlyToken {
        dividendToken = IERC20(_dividendToken);
        emit DividendTokenUpdate(_dividendToken);
    }
    
    function getDividendToken() external view returns (address) {
        return address(dividendToken);
    }
    
    function sendDividend(address holder, uint256 amount) external onlyOwner {
        dividendToken.transfer(holder, amount);
    }
}

contract APETURE is IERC20, Auth {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "APETURE";
    string constant _symbol = "ATURE";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);
    uint256 public _maxTxAmountBuy = _totalSupply;
    uint256 public _maxTxAmountSell = _totalSupply / 100;
    
    uint256 _maxWalletToken = 10 * 10**9 * (10**_decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBot;

    uint256 initialBlockLimit = 15;
    
    uint256 reflectionFeeBuy = 4;
    uint256 marketingFeeBuy = 7;
    uint256 devFeeBuy = 4;
    uint256 totalFeeBuy = 15;
    uint256 feeDenominatorBuy = 100;
    
    uint256 reflectionFeeSell = 6;
    uint256 marketingFeeSell = 9;
    uint256 devFeeSell = 5;
    uint256 totalFeeSell = 20;
    uint256 feeDenominatorSell = 100;

    address marketingReceiver;
    address devReceiver;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    DividendDistributor distributor;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 200M
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address _marketing,
        address _dev
    ) Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;
        
       address _token =  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        distributor = new DividendDistributor(address(router), _token, msg.sender);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        marketingReceiver = _marketing;
        devReceiver = _dev;

        _balances[msg.sender] = _totalSupply;
    
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

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
        return _tF(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _tF(sender, recipient, amount);
    }

    function _tF(address s, address r, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(s, r, amount); }
        
        checkTxLimit(s, r, amount);

        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && r == pair){ require(_balances[s] > 0); launch(); }

        _balances[s] = _balances[s].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(s) ? takeFee(s, r, amount) : amount;
        
        if(r != pair && !isTxLimitExempt[r]){
            uint256 contractBalanceRecepient = balanceOf(r);
            require(contractBalanceRecepient + amountReceived <= _maxWalletToken, "Exceeds maximum wallet token amount"); 
        }
        
        _balances[r] = _balances[r].add(amountReceived);

        if(!isDividendExempt[s]){ try distributor.setShare(s, _balances[s]) {} catch {} }
        if(!isDividendExempt[r]){ try distributor.setShare(r, _balances[r]) {} catch {} }

        emit Transfer(s, r, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address receiver, uint256 amount) internal view {
        sender == pair
            ? require(amount <= _maxTxAmountBuy || isTxLimitExempt[receiver], "Buy TX Limit Exceeded")
            : require(amount <= _maxTxAmountSell || isTxLimitExempt[sender], "Sell TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling, bool bot) public view returns (uint256) {
        // Anti-bot, fees as 99% for the first block
        if(launchedAt + initialBlockLimit >= block.number || bot){ return selling ? feeDenominatorSell.sub(1) : feeDenominatorBuy.sub(1); }
        // If selling and buyback has happened in past 30 mins, then get the multiplied fees or otherwise get the normal fees
        return selling ? totalFeeSell : totalFeeBuy;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        // Add all the fees to the contract. In case of Sell, it will be multiplied fees.
        uint256 feeAmount = (receiver == pair) ? amount.mul(getTotalFee(true, isBot[sender])).div(feeDenominatorSell) : amount.mul(getTotalFee(false, isBot[receiver])).div(feeDenominatorBuy);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = swapThreshold;

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
        uint256 amountReflection = amountETH.mul(reflectionFeeSell).div(totalFeeSell);
        uint256 amountDev = amountETH.mul(devFeeSell).div(totalFeeSell);
        uint256 amountMarketing = amountETH.sub(amountReflection.add(amountDev));

        try distributor.deposit{value: amountReflection}() {} catch {}
        
        (bool successDev, /* bytes memory data */) = payable(devReceiver).call{value: amountDev, gas: 30000}("");
        (bool successMarketing, /* bytes memory data */) = payable(marketingReceiver).call{value: amountMarketing, gas: 30000}("");
        require(successDev && successMarketing, "receiver rejected ETH transfer");
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        //To know when it was launched
        launchedAt = block.number;
    }
    
    function setInitialBlockLimit(uint256 blocks) external onlyOwner {
        require(blocks > 0, "Blocks should be greater than 0");
        initialBlockLimit = blocks;
    }

    function setBuyTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmountBuy = amount;
    }
    
    function setSellTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmountSell = amount;
    }
    
    function setMaxWalletToken(uint256 amount) external onlyOwner {
        _maxWalletToken = amount;
    }
    
    function getMaxWalletToken() public view onlyOwner returns (uint256) {
        return _maxWalletToken;
    }
    
    function setBot(address _address, bool toggle) external onlyOwner {
        isBot[_address] = toggle;
        _setIsDividendExempt(_address, toggle);
    }
    
    function isInBot(address _address) public view onlyOwner returns (bool) {
        return isBot[_address];
    }
    
    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsDividendExempt(address holder, bool exempt) public onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setSellFees( uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner {
        reflectionFeeSell = _reflectionFee;
        marketingFeeSell = _marketingFee;
        totalFeeSell = _reflectionFee.add(_marketingFee);
        feeDenominatorSell = _feeDenominator;
        //Total fees has be less than 25%
        require(totalFeeSell < feeDenominatorSell/4);
    }
    
    function setBuyFees(uint256 _reflectionFee, uint256 _marketingFee, uint256 _devFee, uint256 _feeDenominator) external onlyOwner {
        reflectionFeeBuy = _reflectionFee;
        marketingFeeBuy = _marketingFee;
        devFeeBuy = _devFee;
        totalFeeBuy = _reflectionFee.add(_marketingFee).add(_devFee);
        feeDenominatorBuy = _feeDenominator;
        //Total fees has be less than 25%
        require(totalFeeBuy < feeDenominatorBuy/4);
    }

    function setFeeReceivers(address _marketingReceiver) external onlyOwner {
        marketingReceiver = _marketingReceiver;
    }
    
    function fixFeeIssue(uint256 amount) external onlyOwner {
        //Use in case marketing fees or dividends are stuck.
        uint256 contractETHBalance = address(this).balance;
        payable(marketingReceiver).transfer(amount > 0 ? amount.div(2) : contractETHBalance.div(2));
        payable(devReceiver).transfer(amount > 0 ? amount.div(2) : contractETHBalance.div(2));
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }
    
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }
    
    function banMultipleBots(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = excluded;
            isDividendExempt[accounts[i]] = excluded;
            if(excluded){
                distributor.setShare(accounts[i], 0);
            }else{
                distributor.setShare(accounts[i], _balances[accounts[i]]);
            }
        }
    }
    
}