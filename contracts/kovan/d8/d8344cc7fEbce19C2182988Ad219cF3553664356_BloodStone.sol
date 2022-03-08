//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        require(adr!=address(0));
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

interface ITaxHandler {
    function process() external;
    function setRewardPool(address _address) external;
    function setLiquidityPool(address _address) external;
    function setDevPool(address _address) external;
    function setMinPeriod(uint256 _minPeriod) external;
    function setRewardpoolTax(uint256 _rewardTax) external;
    function setLiquidityTax(uint256 _liquidityTax) external;
    function setDevTax(uint256 _devTax) external;
}

contract BuyTaxHandler is ITaxHandler,Auth {
    address constant BUSD = 0x07de306FF27a2B630B1141956844eB1552B956B5;
    address public rewardPool;
    address public liquidityPool;
    IERC20 public token;
    uint256 public taxToReward;
    uint256 public taxToLiquidity;
    uint256 public minPeriod = 1 hours;
    uint256 public lastDistributeTime;
    IDEXRouter public router;

    constructor(address _router) Auth(msg.sender){
        token = IERC20(msg.sender);
        router = IDEXRouter(_router);
    }
    function process() external override {
        uint256 amount = token.balanceOf(address(this));
        if(amount>0 && shouldDistribute()) {
            lastDistributeTime = block.timestamp;
            uint256 amountForReward = amount*taxToReward/(taxToLiquidity+taxToReward);
            uint256 amountForLiquidity = amount - amountForReward;
            token.transfer(rewardPool, amountForReward);
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = BUSD;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountForLiquidity,
                0,
                path,
                liquidityPool,
                block.timestamp
            );
        }
        
    }

    function setRewardPool(address _address) external override authorized {
        rewardPool = _address;
    }
    function setLiquidityPool(address _address) external override authorized {
        liquidityPool = _address;
    }
    function setDevPool(address _address) external override {}

    function shouldDistribute() internal view returns(bool) {
        return lastDistributeTime + minPeriod < block.timestamp;
    }
    function setMinPeriod(uint256 _minPeriod) external override authorized {
        minPeriod = _minPeriod;
    }
    function setRewardpoolTax(uint256 _rewardTax) external override authorized {
        taxToReward = _rewardTax;
    }
    function setLiquidityTax(uint256 _liquidityTax) external override authorized {
        taxToLiquidity = _liquidityTax;
    }
    function setDevTax(uint256 _devTax) external override {}
}

contract SellTaxHandler is ITaxHandler,Auth {
    address constant BUSD = 0x07de306FF27a2B630B1141956844eB1552B956B5;
    address public rewardPool;
    address public liquidityPool;
    address public devPool;
    IERC20 public token;
    uint256 public taxToReward;
    uint256 public taxToLiquidity;
    uint256 public taxToDev;
    uint256 public lastDistributeTime;

    IDEXRouter public router;
    uint256 public minPeriod = 1 hours;

    constructor(address _router) Auth(msg.sender){
        token = IERC20(msg.sender);
        router = IDEXRouter(_router);
    }
    function process() external override {
        uint256 amount = token.balanceOf(address(this));
        if(amount>0&&shouldDistribute()) {
            lastDistributeTime = block.timestamp;
            uint256 amountForReward = amount * taxToReward / (taxToLiquidity+taxToReward+taxToDev);
            uint256 amountForLiquidity = amount*taxToLiquidity/(taxToLiquidity+taxToReward+taxToDev);
            uint256 amountForDev = amount - (amountForReward+amountForLiquidity);
            token.transfer(rewardPool, amountForReward);
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = BUSD;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountForLiquidity,
                0,
                path,
                liquidityPool,
                block.timestamp
            );
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountForDev,
                0,
                path,
                devPool,
                block.timestamp
            );
        }
    }

    function setRewardPool(address _address) external override authorized {
        rewardPool = _address;
    }

    function setLiquidityPool(address _address) external override authorized {
        liquidityPool = _address;
    }
    function setDevPool(address _address) external override authorized {
        devPool = _address;
    }
    function shouldDistribute() internal view returns(bool) {
        return lastDistributeTime + minPeriod < block.timestamp;
    }
    function setMinPeriod(uint256 _minPeriod) external override authorized {
        minPeriod = _minPeriod;
    }
    function setRewardpoolTax(uint256 _rewardTax) external override authorized {
        taxToReward = _rewardTax;
    }
    function setLiquidityTax(uint256 _liquidityTax) external override authorized {
        taxToLiquidity = _liquidityTax;
    }
    function setDevTax(uint256 _devTax) external override authorized {
        taxToDev = _devTax;
    }
}


contract BloodStone is IERC20, Auth {
    address constant BUSD = 0x07de306FF27a2B630B1141956844eB1552B956B5;
    
    string constant _name = "Crypto Legions Bloodstone";
    string constant _symbol = "BLST";
    uint8 constant _decimals = 18;
    
    uint256 constant _totalSupply = 5000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 public sellTaxReward = 300;
    uint256 public sellTaxLiquidity = 400;
    uint256 public sellTaxDev = 100;
    uint256 public buyTaxLiquidity = 100;
    uint256 public buyTaxReward = 100;
    uint256 public feeDenominator = 10000;
    
    IDEXRouter public router;
    address public pair;
    bool public addingLiquidity;
    bool processing = false;
    mapping (address => bool) isTxLimitExempt;
    uint256 public _maxTxAmount = 4500 * (10 ** _decimals);
    bool public antiBotEnabled = true;
    uint256 public cooldownTime = 30 seconds;
    mapping(address => uint256) public purchasedTime;

    ITaxHandler public buyTaxHandler;
    ITaxHandler public sellTaxHandler;

    modifier process() {
        processing = true; _; processing = false;
    }

    constructor (
        address _dexRouter
    ) Auth(msg.sender) {
        router = IDEXRouter(_dexRouter);
        addingLiquidity = true;
        pair = IDEXFactory(router.factory()).createPair(BUSD, address(this));

        buyTaxHandler = new BuyTaxHandler(_dexRouter);
        sellTaxHandler = new SellTaxHandler(_dexRouter);

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(buyTaxHandler)][address(router)] = _totalSupply;
        _allowances[address(sellTaxHandler)][address(router)] = _totalSupply;

        isTxLimitExempt[msg.sender] = true;

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
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
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(sender==address(buyTaxHandler)||sender==address(sellTaxHandler)) {
            return _basicTransfer(sender, recipient, amount);
        }

        if(sender==address(pair)) { // When buying BLST in BUSD
            if(antiBotEnabled) {
                checkBot(sender, recipient, amount);
            }
            purchasedTime[recipient] = block.timestamp;
            _balances[sender] = _balances[sender] - amount;
            uint256 amountReceived = takeBuyTax(sender, amount);
            _balances[recipient] = _balances[recipient] + amountReceived;
            emit Transfer(sender, recipient, amountReceived);
            return true;
        } else if(!addingLiquidity && recipient==address(pair)) { //When selling token
            _balances[sender] = _balances[sender] - amount;
            uint256 amountReceived = takeSellTax(sender, amount);
            _balances[recipient] = _balances[recipient] + amountReceived;
            emit Transfer(sender, recipient, amountReceived);
            return true;
        } else {
            if(shouldProcess()) {
                processFee();
            }
            return _basicTransfer(sender, recipient, amount);
        }
    }

    function checkBot(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        require(block.timestamp>purchasedTime[recipient]+cooldownTime, "You can make another purchase after cooldown time");
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function shouldProcess() internal view returns (bool) {
        return msg.sender != pair
        && !processing;
    }

    function processFee() internal process {
        try buyTaxHandler.process() {} catch {}
        try sellTaxHandler.process() {} catch {}
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeBuyTax(address sender, uint256 amount) internal returns (uint256) {
        uint256 buyTaxAmount = amount*(buyTaxReward+buyTaxLiquidity)/feeDenominator;
        _balances[address(buyTaxHandler)] = _balances[address(buyTaxHandler)] + buyTaxAmount;
        emit Transfer(sender, address(buyTaxHandler), buyTaxAmount);
        return amount - buyTaxAmount;
    }

    function takeSellTax(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount* (sellTaxDev+sellTaxLiquidity+sellTaxReward) / feeDenominator;
        _balances[address(sellTaxHandler)] = _balances[address(sellTaxHandler)] + feeAmount;
        emit Transfer(sender, address(sellTaxHandler), feeAmount);
        return amount - feeAmount;
    }

    function setTaxs(uint256 _buyReward, uint256 _buyLiquidity, uint256 _sellReward, uint256 _sellLiquidity, uint256 _sellDev, uint256 _feeDenominator) external onlyOwner {
        require(_feeDenominator<=10000, "Fee denominator can not be set over 100%");
        require((_buyReward+_buyLiquidity)<=_feeDenominator/50, "Buy tax can not exceed 2%"); /// setting Maximum buy tax 2%
        require((_sellReward+_sellLiquidity+_sellDev)<=_feeDenominator/4, "Sell tax can not exceed 25%"); /// setting Maximum sell tax 25%
        buyTaxReward = _buyReward;
        buyTaxLiquidity = _buyLiquidity;
        sellTaxReward = _sellReward;
        sellTaxLiquidity = _sellLiquidity;
        sellTaxDev = _sellDev;
        feeDenominator = _feeDenominator;
        buyTaxHandler.setRewardpoolTax(_buyReward);
        buyTaxHandler.setLiquidityTax(_buyLiquidity);
        sellTaxHandler.setRewardpoolTax(_sellReward);
        sellTaxHandler.setLiquidityTax(_sellLiquidity);
        sellTaxHandler.setDevTax(_sellDev);
    }

    function setAddingLiquidity(bool _addingLiquidity) external onlyOwner {
        addingLiquidity = _addingLiquidity;
    }

    function setRewadPool(address _address) external onlyOwner {
        buyTaxHandler.setRewardPool(_address);
        sellTaxHandler.setRewardPool(_address);
    }
    function setLiquidityPool(address _address) external onlyOwner {
        buyTaxHandler.setLiquidityPool(_address);
        sellTaxHandler.setLiquidityPool(_address);
    }
    function setDevPool(address _address) external onlyOwner {
        sellTaxHandler.setDevPool(_address);
    }
    function setMinPeriod(uint256 _minPeriod) external onlyOwner {
        buyTaxHandler.setMinPeriod(_minPeriod);
        sellTaxHandler.setMinPeriod(_minPeriod);
    }
    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount > 4000);
        _maxTxAmount = amount * (10**_decimals);
    }
    function setAntibot(bool _enable) external onlyOwner {
        antiBotEnabled = _enable;
    }
    function setCooldownTime(uint256 _time) external onlyOwner {
        cooldownTime = _time;
    }
    function withdrawETH(address payable _addr, uint256 amount) public onlyOwner {
        _addr.transfer(amount);
    }
}