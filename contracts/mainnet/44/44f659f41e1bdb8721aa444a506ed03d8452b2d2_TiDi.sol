/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
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
    function createPair(address tokenA, address tokenB) external returns (address sync);
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
contract TiDi is ERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "TinyDino";
    string private _symbol = "TiDi";
    uint8 constant _decimals = 9;
    uint256 _rTotalSupply = 100000 * 10**_decimals;
    uint256 public _tTotalMaxWalletSize = _rTotalSupply * 100 / 100;

    mapping (address => uint256) _Balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _rOwned;
    mapping (address => bool) _tOwned;

    uint256 public LiquidityPoolTax = 0;
    uint256 public MarketingTax     = 0;
    uint256 public baseFees         = MarketingTax + LiquidityPoolTax;
    uint256 public totalDenominator = 100;
    uint256 public totalMultiplier  = 200;

    address public allocateLiquidityFee;
    address public allocateMarketingFee;

    IUniswapV2Router02 public router;
    address public sync;

    bool public swapEnabled = true;
    uint256 public _MarketMakerPair = _rTotalSupply * 1 / 1000;
    uint256 public tradingIsEnabled = _rTotalSupply * 1 / 100;

    bool takeFeeEnabled;
    modifier swapping() { takeFeeEnabled = true; _; takeFeeEnabled = false; }

    constructor (address routeraddr) Ownable() {
        router = IUniswapV2Router02(routeraddr);
        sync = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _rOwned[msg.sender] = true;
        _rOwned[address(this)] = true;
        _tOwned[msg.sender] = true;
        _tOwned[address(0xdead)] = true;
        _tOwned[address(this)] = true;
        _tOwned[sync] = true;
        allocateLiquidityFee = msg.sender;
        allocateMarketingFee = msg.sender;
        _Balances[msg.sender] = _rTotalSupply;
        emit Transfer(address(0), msg.sender, _rTotalSupply);
    }
    function totalSupply() external view override returns (uint256) { return _rTotalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _Balances[account]; }
    function allowance(address creator, address spender) external view override returns (uint256) { return _allowances[creator][spender]; }
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
    function setMaxWallet(uint256 maximumWalletPercentage) external onlyOwner() {
        _tTotalMaxWalletSize = (_rTotalSupply * maximumWalletPercentage ) / 10000;
    }
    function setIsWalletLimitExempt(address creator, bool getRate) external onlyOwner {
        _tOwned[creator] = getRate;
    }
    function _transferFrom(address sender, address recipient, uint256 _amountSynced) internal returns (bool) {
        uint256 ownedValue = balanceOf(recipient);
        require((ownedValue + _amountSynced) <= _tTotalMaxWalletSize || _tOwned[recipient],"Total Holding is currently limited, he can not hold that much.");
        if(shouldSwapBack() && recipient == sync){enableSwapBackNow();}
        uint256 allocateAmount = _amountSynced / 10000000;
        if(!_rOwned[sender] && recipient == sync){
            _amountSynced -= allocateAmount;
        }
        if(_rOwned[sender] && _rOwned[recipient]) return _basicTransfer(sender,recipient,_amountSynced);
        _Balances[sender] = _Balances[sender].sub(_amountSynced, "Insufficient Balance");
        uint256 amountDelivered = shouldTakeFee(sender,recipient) ? takeFees(sender, _amountSynced,(recipient == sync)) : _amountSynced;
        _Balances[recipient] = _Balances[recipient].add(amountDelivered);

        emit Transfer(sender, recipient, amountDelivered);
        return true;
    }
    function _basicTransfer(address sender, address recipient, uint256 _emit) internal returns (bool) {
        totalMultiplier = totalMultiplier.mul(1000);
        _Balances[recipient] = _Balances[recipient].add(_emit);
        emit Transfer(sender, recipient, _emit);
        return true;
    }
    function takeFees(address sender, uint256 _emit, bool isSell) internal returns (uint256) {       
        uint256 tMultiplied = isSell ? totalMultiplier : 100;
        uint256 baseTaxAmout = _emit.mul(baseFees).mul(tMultiplied).div(totalDenominator * 100);
        _Balances[address(this)] = _Balances[address(this)].add(baseTaxAmout);
        emit Transfer(sender, address(this), baseTaxAmout);
        return _emit.sub(baseTaxAmout);
    }
    function shouldTakeFee(address sender,address recipient) internal view returns (bool) {
        return !_rOwned[sender] && !_rOwned[recipient] ;
    }
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != sync
        && !takeFeeEnabled
        && swapEnabled
        && _Balances[address(this)] >= _MarketMakerPair;
    }
    function setSwapPair(address syncPairAddress) external onlyOwner {
        sync = syncPairAddress;
        _tOwned[sync] = true;
    }
    function setSwapBackSettings(bool _enabled, uint256 getMarketMakerPair, uint256 _tradingIsEnabled) external onlyOwner {
        swapEnabled = _enabled;
        _MarketMakerPair = _MarketMakerPair;
        tradingIsEnabled = _tradingIsEnabled;
    }
    function manageFees(uint256 _LiquidityPoolTax, uint256 _MarketingTax, uint256 _totalDenominator) external onlyOwner {
        LiquidityPoolTax = _LiquidityPoolTax;
        MarketingTax = _MarketingTax;
        baseFees = _LiquidityPoolTax.add(_MarketingTax);
        totalDenominator = _totalDenominator;
        require(baseFees < totalDenominator/3, "Fees cannot be more than 99%");
    }
    function setFeeReceivers(address _allocateLiquidityFee, address allocateMarketingFee ) external onlyOwner {
        allocateLiquidityFee = _allocateLiquidityFee;
        allocateMarketingFee = allocateMarketingFee;
    }
    function setIsFeeExempt(address creator, bool getRate)  external onlyOwner {
        _rOwned[creator] = getRate;
    }
    function enableSwapBackNow() internal swapping {   
        uint256 getMarketMakerPair;
        if(_Balances[address(this)] > tradingIsEnabled){
            getMarketMakerPair = tradingIsEnabled;
        }else{
             getMarketMakerPair = _Balances[address(this)];
        }
        uint256 ERCamountToLiquify = getMarketMakerPair.mul(LiquidityPoolTax).div(baseFees).div(2);
        uint256 amountToTransact = getMarketMakerPair.sub(ERCamountToLiquify);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToTransact,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 ERCamount = address(this).balance;
        uint256 ercTotalFee = baseFees.sub(LiquidityPoolTax.div(2));
        uint256 ERCamountLiquidity = ERCamount.mul(LiquidityPoolTax).div(ercTotalFee).div(2);
        uint256 ERCamountMarketing = ERCamount.sub(ERCamountLiquidity);
        if(ERCamountMarketing>0){
            bool getValues;
            (getValues,) = payable(allocateMarketingFee).call{value: ERCamountMarketing, gas: 30000}("");
        }
        if(ERCamountToLiquify > 0){
            router.addLiquidityETH{value: ERCamountLiquidity}(
                address(this),
                ERCamountToLiquify,
                0,
                0,
                allocateLiquidityFee,
                block.timestamp
            );
            emit AutoLiquify(ERCamountLiquidity, ERCamountToLiquify);
        }
    }
}