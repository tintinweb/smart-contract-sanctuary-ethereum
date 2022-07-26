/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.9;

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

interface IDEXFactory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
   function factory() external pure returns (address);
   function WETH() external pure returns (address);
 
   function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity);
 
   function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
 
   function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
   function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable;
   function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
}

interface IDividendDistributor {
   function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
   function setShare(address shareholder, uint256 amount) external;
   function deposit() external payable;
   function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address immutable public _token;
    IDEXRouter constant internal ROUTER = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    //ropsten 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
    //mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    IERC20 constant public USDC = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    address public WETH = ROUTER.WETH();

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10**8);

    uint256 currentIndex; 

    bool initialized;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;
    
    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor() {
        _token = msg.sender;
    }

    //public methods

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    //external methods

    function setDistributionCriteria( uint256 _minPeriod, uint256 _minDistribution ) external override onlyToken { 
        minPeriod = _minPeriod; minDistribution = _minDistribution; 
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }   

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = USDC.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(USDC);

        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, address(this), block.timestamp);

        uint256 amount = USDC.balanceOf(address(this)) - balanceBefore;

        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        require(shareholderCount > 0, 'No shareholders');

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) currentIndex = 0;
            if (shouldDistribute(shareholders[currentIndex])) distributeDividend(shareholders[currentIndex]);

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function claimDividend(address shareholder) external onlyToken {
            distributeDividend(shareholder);
    }

    //internal methods

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }    
    
    function distributeDividend(address shareholder) internal {
        require(shares[shareholder].amount > 0, 'Amount is 0');
        uint256 amount = getUnpaidEarnings(shareholder);

            totalDistributed = totalDistributed + amount;
            
            USDC.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }   

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    } 

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Ownable {
    address public owner;
    mapping(address => bool) public autorized;

    event OwnershipTransferred(address indexed owner, address indexed to, uint timestamp);
    event Authorized(address _autorized, uint timestamp);
    event Unauthorized(address _autorized, uint timestamp);

    constructor(address _owner) {
        owner = _owner;
        autorized[_owner] = true;
    }

    modifier onlyOwner() {
        require(owner==msg.sender , "!OWNER");
        _;
    }

    modifier authorized() {
        require(autorized[msg.sender]==true, "!AUTHORIZED");
        _;
    }

    function authorize(address _address) public onlyOwner {
        autorized[_address] = true;
        emit Authorized(_address, block.timestamp);
    }

    function unauthorize(address _address) public onlyOwner {
        autorized[_address] = false;
        emit Unauthorized(_address, block.timestamp);
    }

    function transferOwnership(address _address) public onlyOwner {
        require(_address!= address(0), 'Use renounce for that');
        owner = _address;
        autorized[_address] = true;
        emit OwnershipTransferred(msg.sender, _address, block.timestamp);
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        autorized[msg.sender] = true;
        emit OwnershipTransferred(msg.sender, address(0), block.timestamp);
    }
}

contract SEGRAINU is IERC20, Ownable {
    event AutoLiquify(uint256 amountETH, uint256 amountSEGRA);
    event BuybackMultiplierActive(uint256 duration);
    //ropsten 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
    //mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    
    address immutable WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = address(0);
    IDEXRouter public immutable router;
    IDEXFactory internal immutable factory;
    address public immutable pair;
    

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    string constant _name = "Segra INU";
    string constant _symbol = "SEGRA";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000000 * (10**_decimals);
    uint256 public _maxTxAmount = _totalSupply / 100; // 1%

    //max wallet holding of 2%
    uint256 public _maxWalletToken = (_totalSupply * 2) / 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) public isBlacklisted;

    // Buy Fees
    uint256 liquidityFeeBuy = 300;
    uint256 buybackFeeBuy = 0;
    uint256 reflectionFeeBuy = 700;
    uint256 marketingFeeBuy = 500;
    uint256 totalFeeBuy = 1500;

    // Sell fees
    uint256 liquidityFeeSell = 300;
    uint256 buybackFeeSell = 0;
    uint256 reflectionFeeSell = 700;
    uint256 marketingFeeSell = 1000;
    uint256 totalFeeSell = 2000;

    uint256 liquidityFee;
    uint256 buybackFee;

    uint256 reflectionFee;
    uint256 marketingFee;
    uint256 totalFee;
    uint256 feeDenominator = 10000;



    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    bool public tradingOpen = false;



    uint256 public deadBlocks = 0;
    uint256 public launchedAt = 0;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    bool public autoBuybackMultiplier = true;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 200; // 0.025%
    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        factory = IDEXFactory(router.factory());
        WETH = router.WETH();
        pair = factory.createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor();

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    
    //ERC20 view methods
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    //ERC20 public methods

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

    function transferFrom( address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
             _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
             }

        return _transferFrom(sender, recipient, amount);
    }

    //Additional methods

    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner {
        _maxWalletToken = (_totalSupply * maxWallPercent) / 100;
    }

    function removeBots(address[] calldata _addresses, bool _value) public authorized {
        for (uint i=0; i<_addresses.length; i++) {
            isBlacklisted[_addresses[i]]=_value;
        }
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + 1 >= block.number) return feeDenominator - 1;
        if ( selling && buybackMultiplierTriggeredAt + buybackMultiplierLength > block.timestamp ) {
            return getMultipliedFee();
        }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 remainingTime = buybackMultiplierTriggeredAt + buybackMultiplierLength - block.timestamp;
        uint256 feeIncrease = totalFee * buybackMultiplierNumerator / buybackMultiplierDenominator - totalFee;
        return totalFee + (feeIncrease * remainingTime / buybackMultiplierLength);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) return _basicTransfer(sender, recipient, amount);
        if (!autorized[sender] && !autorized[recipient]) require(tradingOpen, "Trading not open yet");
        require(!isBlacklisted[recipient] && !isBlacklisted[sender], "Address is blacklisted");

        bool isSell = recipient == pair;
        setCorrectFees(isSell);

        // max wallet code
        if ( !autorized[sender] && recipient != address(this) && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver ) {
            uint256 heldTokens = balanceOf(recipient);
            require( (heldTokens + amount) <= _maxWalletToken, "Total Holding is currently limited, you can not buy that much." );
        }

        checkTxLimit(sender, amount);

        if (shouldSwapBack()) swapBack();
        if (shouldAutoBuyback()) triggerAutoBuyback();
        if (!launched() && recipient == pair) { 
            require(_balances[sender] > 0); 
            launch(); 
            }
        //!
        require(_balances[sender] >= amount, "Not enough funds");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient] + amountReceived;

        if (!isDividendExempt[sender]) { try distributor.setShare(sender, _balances[sender]) {} catch {} } 
        if (!isDividendExempt[recipient]) { try distributor.setShare(recipient, _balances[recipient]) {} catch {} }
        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    // Set the correct fees for buying or selling
    function setCorrectFees(bool isSell) internal {
        if (isSell) {
            liquidityFee = liquidityFeeSell;
            buybackFee = buybackFeeSell;
            reflectionFee = reflectionFeeSell;
            marketingFee = marketingFeeSell;
            totalFee = totalFeeSell;
        } else {
            liquidityFee = liquidityFeeBuy;
            buybackFee = buybackFeeBuy;
            reflectionFee = reflectionFeeBuy;
            marketingFee = marketingFeeBuy;
            totalFee = totalFeeBuy;
        }
    }

    function _basicTransfer( address sender, address recipient, uint256 amount ) internal returns (bool) {
        //!
        require(_balances[sender] >= amount, "Not enough funds");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee( address sender, address receiver, uint256 amount ) internal returns (uint256) {
        uint256 feeAmount = amount * getTotalFee(receiver == pair) / feeDenominator;
        if ((launchedAt + deadBlocks) > block.number) feeAmount = amount / 100 * 99; 
        _balances[address(this)] = _balances[address(this)] + feeAmount;

        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified( targetLiquidity, targetLiquidityDenominator ) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold * dynamicLiquidityFee / totalFee / 2;
        uint256 amountToSwap = swapThreshold - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens( amountToSwap, 0, path, address(this), block.timestamp );
        uint256 amountETH = address(this).balance - balanceBefore;
        uint256 totalETHFee = totalFee - (dynamicLiquidityFee / 2);
        uint256 amountETHLiquidity = amountETH * dynamicLiquidityFee / totalETHFee / 2;
        uint256 amountETHReflection = amountETH * reflectionFee / totalETHFee;
        uint256 amountETHMarketing = (amountETH * marketingFee / totalETHFee) * 4 / 4;

        try distributor.deposit{value: amountETHReflection}() {} catch {}

        (bool success, ) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        require(success, "receiver rejected ETH transfer");

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(address(this), amountToLiquify, 0, 0, autoLiquidityReceiver, block.timestamp);
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair && !inSwap && autoBuybackEnabled && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number && address(this).balance >= autoBuybackAmount;
    }

    function triggerManualBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        if (autoBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator + autoBuybackAmount;
        if (autoBuybackAccumulator > autoBuybackCap) {
            autoBuybackEnabled = false;
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, to, block.timestamp);
    }

    function setAutoBuybackSettings( bool _enabled, uint256 _cap, uint256 _amount, uint256 _period, bool _autoBuybackMultiplier ) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
        autoBuybackMultiplier = _autoBuybackMultiplier;
    }

    function setBuybackMultiplierSettings( uint256 numerator, uint256 denominator, uint256 length ) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function tradingStatus(bool _status, uint256 _deadBlocks) public onlyOwner {
        tradingOpen = _status;
        if (tradingOpen && launchedAt == 0) {
            launchedAt = block.number;
            deadBlocks = _deadBlocks;
        }
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    // Set our buy fees
    function setBuyFees( uint256 _liquidityFeeBuy, uint256 _buybackFeeBuy, uint256 _reflectionFeeBuy, uint256 _marketingFeeBuy, uint256 _feeDenominator ) external authorized {
        liquidityFeeBuy = _liquidityFeeBuy;
        buybackFeeBuy = _buybackFeeBuy;
        reflectionFeeBuy = _reflectionFeeBuy;
        marketingFeeBuy = _marketingFeeBuy;
        totalFeeBuy = _liquidityFeeBuy + _buybackFeeBuy + _reflectionFeeBuy + _marketingFeeBuy;
        feeDenominator = _feeDenominator;
    }

    // Set our sell fees
    function setSellFees( uint256 _liquidityFeeSell, uint256 _buybackFeeSell, uint256 _reflectionFeeSell, uint256 _marketingFeeSell, uint256 _feeDenominator ) external authorized {
        liquidityFeeSell = _liquidityFeeSell;
        buybackFeeSell = _buybackFeeSell;
        reflectionFeeSell = _reflectionFeeSell;
        marketingFeeSell = _marketingFeeSell;
        totalFeeSell = _liquidityFeeSell + _buybackFeeSell + _reflectionFeeSell + _marketingFeeSell;
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers( address _autoLiquidityReceiver, address _marketingFeeReceiver ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }

    function setDistributionCriteria( uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * ( balanceOf(pair) * 2) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
}