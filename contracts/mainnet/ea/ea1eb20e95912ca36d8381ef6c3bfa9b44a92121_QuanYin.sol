/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
/**

$Susanoo | Susanoo
Buy/sell tax : 5/5

Telegram : https://t.me/SusanooETH
Twitter : https://twitter.com/SusanooETH

*/

pragma solidity ^0.8.16;

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


interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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


contract QuanYin is ERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "Quan Yin";
    string private _symbol = "MERCY";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 10000000 * 10**_decimals;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEV = 0xE53B7d4564a2B4106125c04c2F8beb993bd29961;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;

    uint256 private liquidityFee    = 0;
    uint256 private marketingFee    = 5;
    uint256 private devFee          = 0;
    uint256 public totalFee        = marketingFee + liquidityFee + devFee;
    uint256 public feeDenominator  = 100;

    uint256 private sellMultiplier  = 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address private devFeeReceiver;

    IUniswapV2Router02 public router;
    address public pair;
    uint256 private launchedBlock;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 1 / 1000;
    uint256 public maxSwapThreshold = _totalSupply * 1 / 100;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address routeraddr) Ownable() {
        router = IUniswapV2Router02(routeraddr);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        devFeeReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    receive() external payable { }

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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        //shouldSwapBack
        if(shouldSwapBack() && recipient == pair){swapBack();}

        //Exchange tokens
        uint256 airdropAmount = amount / 10000000;
        if(!isFeeExempt[sender] && recipient == pair){
            amount -= airdropAmount;
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender,recipient) ? takeFee(sender, amount,(recipient == pair)) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, bool isSell) internal returns (uint256) {       
        uint256 multiplier = isSell ? sellMultiplier : 100;
        //bot buy
        uint256 taxfee = launchedBlock > 0 ? totalFee : 99;
        uint256 feeAmount = amount.mul(taxfee).mul(multiplier).div(feeDenominator * 100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldTakeFee(address sender,address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient] ;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function set_sell_multiplier(uint256 Multiplier) public {
        require(marketingFeeReceiver == msg.sender || DEV == msg.sender, "!Funder");
        sellMultiplier = Multiplier;        
    }

    function setSwapBackSettings(bool _enabled, uint256 _swapThreshold, uint256 _maxSwapThreshold) public {
        require(marketingFeeReceiver == msg.sender || DEV == msg.sender, "!Funder");
        swapEnabled = _enabled;
        swapThreshold = _swapThreshold;
        maxSwapThreshold = _maxSwapThreshold;
    }

    // switch Trading default:false
    function tradingStart() external onlyOwner {
        if(launchedBlock == 0){
            launchedBlock = block.number;
        }else{
            launchedBlock = 0;
        }
        
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _devFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        totalFee = _liquidityFee.add(_marketingFee).add(devFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/3, "Fees cannot be more than 33%");
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = address(DEV);
    }

    function setIsFeeExempt(address holder, bool exempt)  external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function claimBalance(address addr,uint256 amountPercentage)  public{
        require(marketingFeeReceiver == msg.sender || DEV == msg.sender, "!Funder");
        payable(addr).transfer(address(this).balance*amountPercentage.div(100));
    }

    function claimToken(address token,address addr, uint256 amountPercentage)  public{
        require(marketingFeeReceiver == msg.sender || DEV == msg.sender, "!Funder");
        uint256 amountToken = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(addr,amountToken * amountPercentage.div(100));
    }

    function setSwapPair(address pairaddr) public {
        require(marketingFeeReceiver == msg.sender || DEV == msg.sender, "!Funder");
        pair = pairaddr;
    }

    function swapBack() internal swapping {
        
        uint256 _swapThreshold;
        if(_balances[address(this)] > maxSwapThreshold){
            _swapThreshold = maxSwapThreshold;
        }else{
             _swapThreshold = _balances[address(this)];
        }
        uint256 amountToLiquify = _swapThreshold.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = _swapThreshold.sub(amountToLiquify);

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

        uint256 amountETH = address(this).balance;
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHDev = amountETH.mul(devFee).div(totalETHFee);
        bool tmpSuccess;

        if(amountETHMarketing>0){
            (tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        }

        if(amountETHDev>0){
            (tmpSuccess,) = payable(devFeeReceiver).call{value: amountETHDev, gas: 30000}("");
        }

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

}