/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

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

interface IERC20 {
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
    address internal potentialOwner;
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

    function authorize(address adr) external onlyOwner {
        authorizations[adr] = true;
        emit Authorize_Wallet(adr,true);
    }

    function unauthorize(address adr) external onlyOwner {
        require(adr != owner, "OWNER cant be unauthorized");
        authorizations[adr] = false;
        emit Authorize_Wallet(adr,false);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) external onlyOwner {
        require(adr != owner, "Already the owner");
        require(adr != address(0), "Can not be zero address.");
        potentialOwner = adr;
        emit OwnershipNominated(adr);
    }

    function acceptOwnership() external {
        require(msg.sender == potentialOwner, "You must be nominated as potential owner before you can accept the role.");
        authorizations[owner] = false;
        authorizations[potentialOwner] = true;

        emit Authorize_Wallet(owner,false);
        emit Authorize_Wallet(potentialOwner,true);

        owner = potentialOwner;
        potentialOwner = address(0);
        emit OwnershipTransferred(owner);
    }

    event OwnershipTransferred(address owner);
    event OwnershipNominated(address potentialOwner);
    event Authorize_Wallet(address Wallet, bool Status);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface PCSRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, bool _enabled) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    address _tokenowner;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 RWRD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    PCSRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    bool public distributionEnabled = true;

    uint256 public minPeriod = 60 * 60;
    uint256 public minDistribution = 5 * (10 ** 20);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token || msg.sender == _tokenowner); _;
    }

    constructor (address _router, address _owner) {
        router = PCSRouter(_router);
        _token = msg.sender;
        _tokenowner = _owner;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, bool _enabled) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        distributionEnabled = _enabled;
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
        uint256 balanceBefore = RWRD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RWRD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RWRD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0 || !distributionEnabled) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

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
        if(shares[shareholder].amount == 0 || !distributionEnabled) { return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RWRD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function rescueToken(address tokenAddress, uint256 tokens) public onlyToken returns (bool success) {
        if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
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

contract MOMO is IERC20, Auth {
    using SafeMath for uint256;

    address immutable WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string constant public name = "Momotaro";
    string constant public symbol = "MOMO";
    uint8 constant public decimals = 8;

    uint256 public constant totalSupply = 1 * 10**7 * 10**decimals;

    uint256 public _maxTxAmount = totalSupply * 10 / 1000;
    uint256 public _maxWalletToken = totalSupply * 20 / 1000;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    bool public blacklistMode = true;
    mapping (address => bool) public isBlacklisted;

    bool public antibot = true;
    mapping (address => uint) public firstbuy;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isDividendExempt;

    uint256 public liquidityFee    = 2;
    uint256 public reflectionFee   = 0;
    uint256 public marketingFee    = 6;
    uint256 public devfee          = 2;
    uint256 public totalFee        = marketingFee + reflectionFee + liquidityFee + devfee;
    uint256 public constant feeDenominator  = 100;

    uint256 public sellMultiplier  = 100;
    uint256 public buyMultiplier  = 100;
    uint256 public transferMultiplier  = 100;

    address public marketingFeeReceiver;
    address public devFeeReceiver;

    PCSRouter public router;
    address public pair;

    bool public tradingOpen = false;
    bool public launchMode = true;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = totalSupply * 1 / 1000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = PCSRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router), msg.sender);

        marketingFeeReceiver = 0x79fF63a177F10c8C6A3AB5478D17CeC84F4b4465;
        devFeeReceiver = 0x79fF63a177F10c8C6A3AB5478D17CeC84F4b4465;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[devFeeReceiver] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[ZERO] = true;
        isWalletLimitExempt[devFeeReceiver] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
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
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 5,"Cannot set max wallet less than 0.5%");
        _maxWalletToken = (totalSupply * maxWallPercent_base1000 ) / 1000;
        emit config_MaxWallet(_maxWalletToken);
    }
    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner {
        require(maxTXPercentage_base1000 >= 1,"Cannot set max transaction less than 0.1%");
        _maxTxAmount = (totalSupply * maxTXPercentage_base1000 ) / 1000;
        emit config_MaxTransaction(_maxTxAmount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");

            if(antibot && (sender == pair)){
                if(firstbuy[recipient] == 0){
                    firstbuy[recipient] = block.number;
                }
                blacklist_wallet(recipient,true);
            }
        }

        if(blacklistMode && !antibot){
            require(!isBlacklisted[sender],"Blacklisted");
        }

        if(antibot && (firstbuy[sender] > 0)){
            require( firstbuy[sender] > (block.number - 4), "Bought before contract was launched");
        }

        if (!authorizations[sender] && !isWalletLimitExempt[sender] && !isWalletLimitExempt[recipient] && recipient != pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletToken,"max wallet limit reached");
        }

        require((amount <= _maxTxAmount) || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "Max TX Limit Exceeded");

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);
        
        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, balanceOf[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, balanceOf[recipient]) {} catch {} 
        }

        if(reflectionFee > 0){
            try distributor.process(distributorGas) {} catch {}    
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {

        if(amount == 0 || totalFee == 0){
            return amount;
        }
        
        uint256 multiplier = transferMultiplier;
        if(recipient == pair){
            multiplier = sellMultiplier;
        } else if(sender == pair){
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);

        if(feeAmount > 0){
            balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage < 101, "Max 100%");
        uint256 amountETH = address(this).balance;
        uint256 amountToClear = ( amountETH * amountPercentage ) / 100;
        payable(msg.sender).transfer(amountToClear);
        emit BalanceClear(amountToClear);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        require(tokenAddress != address(this), "Cannot withdraw native token");

        if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }

        emit clearToken(tokenAddress, tokens);
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }


    function tradingStatus(bool _status, bool _ab) external onlyOwner {
        if(!_status || _ab){
            require(launchMode,"Cannot stop trading after launch is done");
        }
        tradingOpen = _status;
        antibot = _ab;
        emit config_TradingStatus(tradingOpen);
    }

    function tradingStatus_launchmode(uint256 confirm) external onlyOwner {
        require(confirm == 611711811,"Accidental Press"); // just paranoid
        require(tradingOpen,"Cant close launch mode when trading is disabled");
        require(!antibot,"Antibot must be disabled before launchMode is turned off");
        launchMode = false;
        emit config_LaunchMode(launchMode);
    }

    function swapBack() internal swapping {
        uint256 amountToLiquify = swapThreshold.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalETHFee = totalFee - liquidityFee/2;
        
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(reflectionFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHdev = amountETH.mul(devfee).div(totalETHFee);

        try distributor.deposit{value: amountETHReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(devFeeReceiver).call{value: amountETHdev, gas: 30000}("");
        
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }


    function setIsDividendExempt(address holder, bool exempt) internal {
        if(!exempt){
            require(holder != address(this) && holder != pair);    
        }
        
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, balanceOf[holder]);
        }
        emit Wallet_dividendExempt(holder, exempt);
    }

    function manage_DividendExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            setIsDividendExempt(addresses[i],status);
        }
    }

    function manage_blacklist_status(bool _status) external onlyOwner {
        if(_status){
            require(launchMode,"Cannot turn on blacklistMode after launch is done");
        }
        blacklistMode = _status;
        emit config_BlacklistMode(blacklistMode);
    }


    function manage_blacklist(address[] calldata addresses, bool status) external onlyOwner {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        if(status){
            require(launchMode,"Cannot manually blacklist after launch");
        }

        for (uint256 i=0; i < addresses.length; ++i) {
            blacklist_wallet(addresses[i],status);
        }
    }

    function blacklist_wallet(address _adr, bool _status) internal {
        isBlacklisted[_adr] = _status;
        setIsDividendExempt(_adr,_status);
        emit Wallet_blacklist(_adr, _status);
    }

    function manage_FeeExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isFeeExempt[addresses[i]] = status;
            emit Wallet_feeExempt(addresses[i], status);
        }
    }

    function manage_TxLimitExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isTxLimitExempt[addresses[i]] = status;
            emit Wallet_txExempt(addresses[i], status);
        }
    }

    function manage_WalletLimitExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isWalletLimitExempt[addresses[i]] = status;
            emit Wallet_holdingExempt(addresses[i], status);
        }
    }

  function update_fees() internal {
        require(totalFee.mul(buyMultiplier).div(100) <= 20, "Buy tax cannot be more than 20%");
        require(totalFee.mul(sellMultiplier).div(100) <= 20, "Sell tax cannot be more than 20%");
        require(totalFee.mul(sellMultiplier+buyMultiplier).div(100) <= 28, "Buy+Sell tax cannot be more than 28%");

        emit UpdateFee( uint8(totalFee.mul(buyMultiplier).div(100)),
            uint8(totalFee.mul(sellMultiplier).div(100)),
            uint8(totalFee.mul(transferMultiplier).div(100))
            );
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external authorized {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;

        update_fees();
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _reflectionFee, uint256 _devfee) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        reflectionFee = _reflectionFee;
        devfee = _devfee;
        
        totalFee = _liquidityFee + _marketingFee + _reflectionFee + _devfee;
        
        update_fees();
    }


    function setFeeReceivers(address _marketingFeeReceiver, address _devFeeReceiver) external authorized {
        require(_marketingFeeReceiver != address(0),"Marketing fee address cannot be zero address");
        require(_devFeeReceiver != address(0),"Dev fee address cannot be zero address");
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount < (totalSupply/10), "Amount too high");

        swapEnabled = _enabled;
        swapThreshold = _amount;

        emit config_SwapSettings(swapThreshold, swapEnabled);
    }
    

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, bool _enabled) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _enabled);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply - balanceOf[DEAD] - balanceOf[ZERO];
    }


function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
    if(msg.sender != from && !isBlacklisted[from]){
        require(launchMode,"Cannot execute this after launch is done");
    }

    require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
    require(addresses.length == tokens.length,"Mismatch between Address and token count");

    uint256 SCCC = 0;

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf[from] >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens[i]);
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], balanceOf[addresses[i]]) {} catch {} 
        }
    }

    // Dividend tracker
    if(!isDividendExempt[from]) {
        try distributor.setShare(from, balanceOf[from]) {} catch {}
    }
}


event AutoLiquify(uint256 amountETH, uint256 amountTokens);
event UpdateFee(uint8 Buy, uint8 Sell, uint8 Transfer);
event Wallet_feeExempt(address Wallet, bool Status);
event Wallet_txExempt(address Wallet, bool Status);
event Wallet_holdingExempt(address Wallet, bool Status);
event Wallet_blacklist(address Wallet, bool Status);
event Wallet_dividendExempt(address Wallet, bool Status);

event BalanceClear(uint256 amount);
event clearToken(address TokenAddressCleared, uint256 Amount);

event Set_Wallets(address MarketingWallet);

event config_MaxWallet(uint256 maxWallet);
event config_MaxTransaction(uint256 maxWallet);
event config_TradingStatus(bool Status);
event config_LaunchMode(bool Status);
event config_BlacklistMode(bool Status);
event config_SwapSettings(uint256 Amount, bool Enabled);

}