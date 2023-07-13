/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

//SPDX-License-Identifier: MIT

// Official token contract for MVP: Most Valuable Protocol, first ever ERC-20 treasury rotation protocol
// Site: https://mvpeth.com
// Telegram: https://t.me/MVPeth
// Twitter: https://twitter.com/MVPERC
// Chart: https://dexscreener.com/ethereum/0x230156068A72C63710f156df4B82dD180b56f84F
// Buy: https://app.uniswap.org/#/swap?outputCurrency=0xa3CA9254729C976E9034943593c801d9b76a1A87


pragma solidity ^0.8.17;

interface ERC20 {

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

interface Engine {

    function trigger() external returns (bool);
    function log(address, address, uint256, uint256) external returns (bool);
    function totalRewardDue(address user) external view returns(uint256);

}

abstract contract Ownable {

    address internal owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner"); 
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract MVP is ERC20, Ownable {

    // Events
    event SetMaxWallet(uint256 maxWalletToken);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event StuckBalanceSent(uint256 amountETH, address recipient);
    event Triggered(bool result);
    event Logged(bool result);

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;

    // Token info
    string constant _name = "Most Valuable Protocol";
    string constant _symbol = "MVP";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 420000000000 * (10 ** _decimals); 

    // Max wallet
    uint256 public _maxWalletSize = (_totalSupply * 20) / 1000;
    uint256 public _maxTxSize = (_totalSupply * 20) / 1000;

    // Tax amounts
    uint256 public TreasuryFee = 15;
    uint256 public DevFee = 8;
    uint256 public LiquidityFee = 10;
    uint256 public MarketingFee = 7;
    uint256 public TotalTax = TreasuryFee + DevFee + MarketingFee + LiquidityFee;

    // Tax wallets
    address DevWallet;
    address MarketingWallet;
    address TreasuryWallet;

    address Distro;
    address MVPLogger;

    // Contracts
    IDEXRouter public router;
    address public pair;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 2 / 10000;

    bool public isTradingEnabled = false;
    uint256 public tradingTimestamp;
    uint256 public cooldown = 1800;
    uint256 public globalMode = 4;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor(address _router, address _TreasuryWallet, address _MarketingWallet, address _MVPLogger, address _Distro) Ownable(msg.sender) {

        router = IDEXRouter(_router);
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        DevWallet = msg.sender;
        TreasuryWallet = _TreasuryWallet;
        MarketingWallet = _MarketingWallet;
        MVPLogger = _MVPLogger;
        Distro = _Distro;

        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;

        isFeeExempt[TreasuryWallet] = true;
        isTxLimitExempt[TreasuryWallet] = true;

        isFeeExempt[MarketingWallet] = true;
        isTxLimitExempt[MarketingWallet] = true;

        isFeeExempt[Distro] = true;
        isTxLimitExempt[Distro] = true;

        _balances[msg.sender] = _totalSupply * 500 / 1000;
        _balances[MarketingWallet] = _totalSupply * 50 / 1000;
        _balances[Distro] = _totalSupply * 450 / 1000;

        emit Transfer(address(0), msg.sender, _totalSupply * 500 / 1000);
        emit Transfer(address(0), MarketingWallet, _totalSupply * 50 / 1000);
        emit Transfer(address(0), Distro, _totalSupply * 450 / 1000);

    }

    receive() external payable { }

// Basic Internal Functions

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
        return _transferFrom(msg.sender, recipient, amount);
    }

    ////////////////////////////////////////////////
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function getPair() public onlyOwner {
        pair = IDEXFactory(router.factory()).getPair(address(this), router.WETH());
        if (pair == address(0)) {pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());}
    }

    function setIsTradingEnabled(bool _isTradingEnabled) public onlyOwner {
        require(!isTradingEnabled);
        isTradingEnabled = _isTradingEnabled;
        tradingTimestamp = block.timestamp;
    }

    function logger(address sender, address recipient, uint256 amount, uint256 amountReceived) internal {
        if (globalMode > 3) {
            try Engine(MVPLogger).log(sender, recipient, amount, amountReceived) {emit Logged(true);}
            catch {emit Logged(false);}
        }
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount);}
        require(isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled, "trading not live");

        if (sender != owner && recipient != owner && recipient != DEAD && recipient != pair && sender != TreasuryWallet) {
            require(isTxLimitExempt[recipient] || (amount <= _maxTxSize && 
                _balances[recipient] + amount <= _maxWalletSize), "tx limit");
        }

        if(shouldSwapBack()){swapBack();}

        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = receivedAmount(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        logger(sender, recipient, amount, amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;

        logger(sender, recipient, amount, amount);
        
        emit Transfer(sender, recipient, amount);
        return true;
    }

// Internal Functions

    function isFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getMult() internal view returns(uint256) {
        return block.timestamp <= tradingTimestamp + cooldown ? 11 : 1;
    }

    function receivedAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
   
        if (!isFee(sender) || !isFee(recipient)) return amount; 
        
        uint256 feeAmount = 0;
        
        if (sender != pair && recipient == pair) {
            feeAmount = amount * (TotalTax * getMult()) / 1000;    
        }

        if (sender == pair && recipient != pair) {
            feeAmount = amount * TotalTax / 1000;
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + (feeAmount);
            emit Transfer(sender, address(this), feeAmount);            
        }

        return amount - (feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function addLiquidity(uint256 _tokenBalance, uint256 _ETHBalance) private {
        if(_allowances[address(this)][address(router)] < _tokenBalance){_allowances[address(this)][address(router)] = _tokenBalance;}
        router.addLiquidityETH{value: _ETHBalance}(address(this), _tokenBalance, 0, 0, DevWallet, block.timestamp + 5 minutes);
    }

    function getFeeRates() view internal returns(uint256 devFee, uint256 treasuryFee, uint256 marketingFee) {

        uint256 currentBalance = address(this).balance;
        uint256 totalFees = TotalTax - LiquidityFee;
        devFee = currentBalance * (DevFee) / totalFees;
        treasuryFee = currentBalance * (TreasuryFee) / totalFees;
        marketingFee = currentBalance * (MarketingFee) / totalFees;

    }

    function sendOut() internal {

        (uint256 devFee, uint256 treasuryFee, uint256 marketingFee) = getFeeRates();

        payable(DevWallet).transfer(devFee);
        payable(MarketingWallet).transfer(marketingFee);
        if (globalMode == 1) payable(DevWallet).transfer(treasuryFee);
        if (globalMode > 1) payable(TreasuryWallet).transfer(treasuryFee);
        if (globalMode > 2) {
            try Engine(TreasuryWallet).trigger() {emit Triggered(true);}
            catch {emit Triggered(false);}          
        }

    }

    function swapBack() internal swapping {

        uint256 totalTax = TotalTax * getMult();
        uint256 amountToLiq = balanceOf(address(this)) * (LiquidityFee) / (2 * totalTax);
        uint256 amountToSwap = balanceOf(address(this)) - amountToLiq;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

        if (amountToLiq > 0) {
            addLiquidity(amountToLiq, address(this).balance * (LiquidityFee) / (2 * totalTax - LiquidityFee));
        }

        if (globalMode > 0) sendOut();

    }


// Tax and Tx functions
    function setGlobalMode(uint256 _globalMode) public {
        require(msg.sender == owner || msg.sender == DevWallet);
        globalMode = _globalMode;
    }

    function setMax(uint256 _maxWalletSize_, uint256 _maxTxSize_) external onlyOwner {
        require(_maxWalletSize_ >= _totalSupply / 1000 && _maxTxSize_ >= _totalSupply / 1000, "max");
        _maxWalletSize = _maxWalletSize_;
        _maxTxSize = _maxTxSize_;
        emit SetMaxWallet(_maxWalletSize);
    }

    function setTaxExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setTxExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function setFees(uint256 _TreasuryFee, uint256 _LiquidityFee, uint256 _DevFee, 
        uint256 _MarketingFee) external onlyOwner {

        TotalTax = _TreasuryFee + _LiquidityFee + _DevFee + _MarketingFee;
        require(TotalTax <= 495, 'too high');

        TreasuryFee = _TreasuryFee;
        LiquidityFee = _LiquidityFee;
        DevFee = _DevFee;
        MarketingFee = _MarketingFee;

    }

    function setWallets(address _DevWallet, address _MarketingWallet, address _TreasuryWallet, address _MVPLogger) external {
        require(msg.sender == owner || msg.sender == DevWallet);
        DevWallet = _DevWallet;
        MarketingWallet = _MarketingWallet;
        TreasuryWallet = _TreasuryWallet;
        MVPLogger = _MVPLogger;
    }

    function getWallets() view public returns(address,address,address,address) {
        return (DevWallet, MarketingWallet, TreasuryWallet, MVPLogger);
    }

    function totalRewardDue(address user) public view returns(uint256) {
        return Engine(MVPLogger).totalRewardDue(user);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount >= 1, "zero");
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit SetSwapBackSettings(swapEnabled, swapThreshold);
    }

    function initSwapBack() public onlyOwner {
        swapBack();
    }

    function clearContractETH() external {
        require(DevWallet == msg.sender, 'dev');
        uint256 _ethBal = address(this).balance;
        if (_ethBal > 0) payable(DevWallet).transfer(_ethBal);
    }

    function clearContractTokens(address _token) external {
        require(DevWallet == msg.sender, 'dev');
        ERC20(_token).transfer(DevWallet, ERC20(_token).balanceOf(address(this)));
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

}