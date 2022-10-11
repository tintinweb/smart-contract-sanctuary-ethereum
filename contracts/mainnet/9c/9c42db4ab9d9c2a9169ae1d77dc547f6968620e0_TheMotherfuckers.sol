/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

//SPDX-License-Identifier: MIT

//For all the bad ass motherfuckers who read this line! WAGMI
// 0 fucks given about the outcome !

//TG: https://t.me/them0therfuckers
//MEDIUM: https://medium.com/@0xmotherfucker/for-the-motherfuckers-dea1680a1cdf



pragma solidity ^0.8.9;

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

abstract contract Ownable {

    address internal owner;
    address private _previousOwner;
    uint256 private _lockTime;

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


interface Dist {
    function swap() external;
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

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

}

contract TheMotherfuckers is ERC20, Ownable {

    // Events
    event SetMaxWallet(uint256 maxWalletToken);
    event SetFees(uint256 DevFee);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event SetFeeReceiver(address DevWallet);
    event StuckBalanceSent(uint256 amountETH, address recipient);

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;

    // Basic Contract Info
    string constant _name = "MOTHERFUCKERS";
    string constant _symbol = "MOFOS";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1000000000 * (10 ** _decimals); 
    
    // Max wallet
    uint256 public _maxWalletSize = (_totalSupply * 25) / 1000;
    uint256 public _maxTxSize = (_totalSupply * 25) / 1000;

    // Fee receiver    
    uint256 public DevFeeBuy = 10;
    uint256 public MotherfuckerFeeBuy = 10;
    uint256 public LiquidityFeeBuy = 30;

    uint256 public DevFeeSell = 10;
    uint256 public MotherfuckerFeeSell = 10;
    uint256 public LiquidityFeeSell = 30;

    uint256 public TotalBase = DevFeeBuy + DevFeeSell + MotherfuckerFeeBuy + MotherfuckerFeeSell + LiquidityFeeBuy + LiquidityFeeSell;

    // Fee receiver & Dead Wallet
    address public DevWallet;
    address public MotherfuckerWallet;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    // Router
    IDEXRouter public router;
    address public pair;
    address public Liq = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public dist;


    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000 * 3; // 0.3% 

    bool public isTradingEnabled = false;
    address public tradingEnablerRole;
    uint256 public tradingTimestamp;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor(address _dev, address _motherfucker, address _dist) Ownable(msg.sender) {

        router = IDEXRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        DevWallet = _dev;
        MotherfuckerWallet = _motherfucker;
        dist = _dist;

        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;

        isFeeExempt[MotherfuckerWallet] = true;
        isTxLimitExempt[MotherfuckerWallet] = true; 

        isFeeExempt[dist] = true;
        isTxLimitExempt[dist] = true; 

        tradingEnablerRole = _owner;
        tradingTimestamp = block.timestamp;

        _balances[DevWallet] = _totalSupply * 100 / 100;

        emit Transfer(address(0), DevWallet, _totalSupply * 100 / 100);

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
        pair = IDEXFactory(router.factory()).getPair(address(this), Liq);
        if (pair == address(0)) {pair = IDEXFactory(router.factory()).createPair(address(this), Liq);}
    }

    function renounceTradingEnablerRole() public {
        require(tradingEnablerRole == msg.sender, 'incompatible role!');
        tradingEnablerRole = address(0x0);
    }

    function setIsTradingEnabled(bool _isTradingEnabled) public {
        require(tradingEnablerRole == msg.sender, 'incompatible role!');
        isTradingEnabled = _isTradingEnabled;
        tradingTimestamp = block.timestamp;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount);}
                
        require(isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled, "Not authorized to trade yet");

        // Checks max transaction limit
        if (sender != owner && sender != MotherfuckerWallet && recipient != owner && recipient != DEAD && recipient != pair) {           
            require(isTxLimitExempt[recipient] || (amount <= _maxTxSize && _balances[recipient] + amount <= _maxWalletSize), "Transfer amount exceeds the MaxWallet size.");
        }
        
        //Exchange tokens
        if(shouldSwapBack()){swapBack();}

        _balances[sender] = _balances[sender] - amount;

        //Check if should Take Fee
        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

// Internal Functions

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
   
        uint256 feeAmount = 0;

        if (sender == pair && recipient != pair) {
            feeAmount = amount * (DevFeeBuy + MotherfuckerFeeBuy + LiquidityFeeBuy) / 1000;
        } if (sender != pair && recipient == pair) {
            feeAmount = amount * (DevFeeSell + MotherfuckerFeeSell + LiquidityFeeSell) / 1000;
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

    function swapBack() internal swapping {

        uint256 amountToLiq = balanceOf(address(this)) * (LiquidityFeeBuy + LiquidityFeeSell) / (2 * TotalBase);
        uint256 amountToSwap = balanceOf(address(this)) - amountToLiq;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = Liq;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountToSwap, 0, path, dist, block.timestamp + 5 minutes);

        _balances[address(this)] = _balances[address(this)] - amountToLiq;
        _balances[dist] = _balances[dist] + amountToLiq;
        emit Transfer(address(this), dist, amountToLiq);

        Dist(dist).swap();
    
    }


// External Functions

   function setMaxWalletAndTx(uint256 _maxWalletSize_, uint256 _maxTxSize_) external onlyOwner {
        require(_maxWalletSize_ >= _totalSupply / 1000 && _maxTxSize_ >= _totalSupply / 1000, "Can't set MaxWallet or Tx below 0.1%");
        _maxWalletSize = _maxWalletSize_;
        _maxTxSize = _maxTxSize_;
        emit SetMaxWallet(_maxWalletSize);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function setFees(uint256 _DevFeeBuy, uint256 _MotherfuckerFeeBuy, uint256 _LiquidityFeeBuy, 
        uint256 _DevFeeSell, uint256 _MotherfuckerFeeSell, uint256 _LiquidityFeeSell) external onlyOwner {
        
        require(_DevFeeBuy + _MotherfuckerFeeBuy + _LiquidityFeeBuy <= 330 && _DevFeeSell + _MotherfuckerFeeSell + _LiquidityFeeSell <= 330, "Total fees must be equal to or less than 33%");

        DevFeeBuy = _DevFeeBuy;
        MotherfuckerFeeBuy = _MotherfuckerFeeBuy;
        LiquidityFeeBuy = _LiquidityFeeBuy;

        DevFeeSell = _DevFeeSell;
        MotherfuckerFeeSell = _MotherfuckerFeeSell;
        LiquidityFeeSell = _LiquidityFeeSell;

        TotalBase = DevFeeBuy + DevFeeSell + MotherfuckerFeeBuy + MotherfuckerFeeSell + LiquidityFeeBuy + LiquidityFeeSell;
        
        emit SetFees(DevFeeBuy);
    }

    function setFeeReceiver(address _DevWallet, address _MotherfuckerWallet) external onlyOwner {
        DevWallet = _DevWallet;
        MotherfuckerWallet = _MotherfuckerWallet;
        emit SetFeeReceiver(DevWallet);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount >= 1, "Can't set SwapThreshold to ZERO");
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit SetSwapBackSettings(swapEnabled, swapThreshold);
    }

    function initSwapBack() public onlyOwner {

        swapBack();

    }

// Stuck Balance Function

    function ClearStuckBalance() external {

        require(DevWallet == msg.sender, 'not dev wallet');

        uint256 _bal = _balances[address(this)];
        if (_bal > 0) {
            _balances[DevWallet] = _balances[DevWallet] + _bal;
            _balances[address(this)] = 0;
            emit Transfer(address(this), DevWallet, _bal);
        }

        uint256 _ethBal = address(this).balance;

        if (_ethBal > 0) {
            payable(DevWallet).transfer(_ethBal);
            emit StuckBalanceSent(_ethBal, DevWallet);        
        }

    }

    function withdrawToken(address _token) public {
        ERC20(_token).transfer(DevWallet, ERC20(_token).balanceOf(address(this)));
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

}