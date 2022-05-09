/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;





 


 




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


 


 


 






library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


 


 


 



library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "[error][ownable] caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "[error][ownable] new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


 


 


 


abstract contract ReentrancyGuard {
    
    
    
    
    

    
    
    
    
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;

        _;

        
        
        _status = _NOT_ENTERED;
    }
}


 


 


 


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function decimals() external view returns (uint8);
}


 


 


 


abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


 


 


 
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


 


abstract contract RoleBasedAccessControl is Context, Ownable{
    mapping(string => mapping(address => bool)) private _roleToAddress;
    mapping(string => bool) private _role;
    string[] _roles;

    
        modifier onlyRole(string memory pRole){
            require(_roleToAddress[pRole][_msgSender()], "[error][role based access control] only addresses assigned this role can access this function!");
            _;
        }

        modifier onlyRoles(string[] memory pRoles){
            for(uint256 i=0; i<pRoles.length; i++){
                require(_roleToAddress[pRoles[i]][_msgSender()], "[error][role based access control] only addresses assigned this role can access this function!");
            }
            _;
        }

        modifier onlyRolesOr(string[] memory pRoles){
            bool rolePresent = false;
            for(uint256 i=0; i<pRoles.length; i++){
                rolePresent = rolePresent || _roleToAddress[pRoles[i]][_msgSender()];
            }
            require(rolePresent, "[error][role based access control] only addresses assigned this role can access this function!");
            _;
        }

        modifier onlyRoleOrOwner(string memory pRole){
            require(_roleToAddress[pRole][_msgSender()] || owner() == _msgSender(), "[error][role based access control] only addresses assigned this role or the owner can access this function!");
            _;
        }

    

        function registerRole(string memory pRole) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
        }

        function registerRoleAddresses(string memory pRole, address[] memory pMembers) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            for(uint256 i=0; i<pMembers.length; i++){
                _roleToAddress[pRole][pMembers[i]] = true;
            }
        }

        function registerRoleAddress(string memory pRole, address pMember) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            _roleToAddress[pRole][pMember] = true;
        }

        function removeRoleAddress(string memory pRole, address pMember) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            _roleToAddress[pRole][pMember] = false;
        }

    

        function addRoleAddress(string memory pRole, address pMember) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            _roleToAddress[pRole][pMember] = true;
        }

    
    
        function hasRoleAddress(string memory pRole, address pAddress) public virtual returns(bool){
            return(_roleToAddress[pRole][pAddress]);
        }

    

    function _addRole(string memory pRole) private{
        if(!_role[pRole]){
            _role[pRole] = true;
            _roles.push(pRole);
        }
    }
}


contract Util is RoleBasedAccessControl{
    
        using SafeMath for uint256;

    
        ERC20 private _token;

    
        mapping(string => mapping(address => bool)) private _paramForAddressIsBool;
        mapping(string => bytes32) private _stringCompare;
        mapping(string => bool) private _stringCompareList;
        mapping(string => uint256) private _commonStats;

    
        uint256 private _floatingPointPrecision = 10**16;
    

    constructor(address pContract){
        
            _paramForAddressIsBool['burn'][address(0)] = true;
            _paramForAddressIsBool['burn'][address(0xdEaD)] = true;

        
            registerRoleAddress("util", _msgSender());
            registerRoleAddress("util", pContract);
    }

    
    
    
    
    function setParamForAddressBool(string memory pParam, address pAddress, bool pBool) public onlyRole("util"){
        _paramForAddressIsBool[pParam][pAddress] = pBool;
    }

    function setParamForAddressesBool(string memory pParam, address[] memory pAddress, bool pBool) public onlyRole("util"){
        for(uint256 i=0; i<pAddress.length; i++){
            _paramForAddressIsBool[pParam][pAddress[i]] = pBool;
        }
    }

    function addStringCompare(string memory pString) public onlyRole("util") returns(bytes32){
        _stringCompare[pString] = keccak256(bytes(pString));
        _stringCompareList[pString] = true;
        return(_stringCompare[pString]);
    }

    function stringEq(string memory pA, string memory pB) public onlyRole("util") returns(bool){
        bytes32 a = (
            (_stringCompareList[pA]) ? _stringCompare[pA] : addStringCompare(pA)
        );

        bytes32 b = (
            (_stringCompareList[pB]) ? _stringCompare[pB] : addStringCompare(pB)
        );

        if(a == b && b == a){
            return(true);
        }
        return(false);
    }

    
        function statsIncrease(string memory pStats, uint256 pValue) public onlyRole("util"){
            _commonStats[pStats] = _commonStats[pStats].add(pValue);
        }

        function statsDecrease(string memory pStats, uint256 pValue) public onlyRole("util"){
            if(_commonStats[pStats] >= pValue){
                _commonStats[pStats] = _commonStats[pStats].sub(pValue);
            }
        }

    
    
    

    function isAddressBurn(address pAddress) public view returns(bool){
        if(_paramForAddressIsBool['burn'][pAddress]){
            return(true);
        }
        return(false);
    }

    function isAddressParam(string memory pParam, address pAddress) public view returns(bool){
        if(_paramForAddressIsBool[pParam][pAddress]){
            return(true);
        }
        return(false);
    }

    function stats(string memory pStats) public view returns(uint256){
        return(_commonStats[pStats]);
    }

    event UtilError(string error);
    function error(string memory pError) public{
        emit UtilError(pError);
    }
}


contract ITOKEN090941Future{
    function deposit(address, address, uint256) public{}
}


contract TOKEN090941 is IERC20, ReentrancyGuard, RoleBasedAccessControl{
    
        
            using SafeMath for uint256; 
            using Address for address; 

        
            address public ADDRESS_PROJECT = 0xB410178FE1a53Ed1Fda5CD0c44ad584F48Bf9B89; 

        
            address public ADDRESS_ZERO = address(0); 
            address public ADDRESS_BURN = address(0xdEaD); 
            address public ADDRESS_PAIR;
            address public ADDRESS_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 

        
            IUniswapV2Router02 private _router; 
            IUniswapV2Pair private _pair; 
            Util private _util; 

        
            
                uint16 public TAX_BUY = 30;
                uint16 public TAX_SELL = 30;

            
                uint256 public ANTI_FRONTRUN = 100000000000000; 
                uint256 public ANTI_FRONTRUN_INDEXES = 6; 
                uint256 public ANTI_FRONTRUN_TIMEOUT = 111; 

                uint16 public TRANSACTION_LIMIT_MAX_BUY = 10; 
                bool public TRANSACTION_LIMIT_ENABLED = true; 

            bool public ENABLED; 

    
        
            string private _name = "TOKEN090941"; 
            string private _symbol = "TKN090941"; 
            uint8 private _decimals = 0; 
            uint256 private _totalSupply = 5 * (10**15) * (10**0); 

        
            mapping(address => uint256) private _balances; 
            mapping(address => mapping (address => uint256)) private _allowances; 
            mapping(address => bool) private _noTaxes; 
            mapping(uint256 => mapping(address => uint256)) private _historyAmount;
            mapping(string => uint256) private _uint256;
            mapping(uint256 => address) private _history;
            mapping(address => uint256) private _timeout;
            uint256 private _historyIndex;

        
            bool private _swapping; 
            uint256 private _taxes; 

    
        
        event Burn(address indexed from, uint256 amount);
        event TransactionStart(address indexed from, address indexed to, uint256 amount);
            event TransactionBuy(address indexed from, address indexed to, uint256 amount);
            event TransactionSell(address indexed from, address indexed to, uint256 amount);
            event TransactionTransfer(address indexed from, address indexed to, uint256 amount);
            event TransactionNoTaxes(address indexed from, address indexed to, uint256 amount);
            event TransactionTaxes(address indexed from, address indexed to, uint256 amount, uint256 taxes);
            event TransactionFrontrunner(address indexed from, address indexed to, uint256 amount);
            event TransactionTaxesToETH(address indexed from, address indexed to, uint256 tokens, uint256 taxes, uint256 total, uint256 native);
        event TransactionEnd();

    
         modifier onlySwapOnce(){
            _swapping = true;
            _;
            _swapping = false;
        }

    
    
    receive() external nonReentrant payable{
        _util.statsIncrease('ETHReceived', msg.value);
    }

    constructor(){
        
            
            _balances[address(this)] = _totalSupply;

            
                emit Transfer(address(0), address(this), _totalSupply);

        
            _util = new Util(address(this));

        
            _router = IUniswapV2Router02(ADDRESS_ROUTER);
            ADDRESS_PAIR = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
            _pair = IUniswapV2Pair(ADDRESS_PAIR);
            _approve(address(this), address(_router), 2**256 - 1);

        
            _uint256['maxTaxes'] = 30; 
            _uint256['minFrontrunnerETH'] = 1 * (10**18); 
            _uint256['maxFrontrunnerTimeout'] = 600; 
            _uint256['maxFrontrunnerIndexes'] = 10; 
            _uint256['minTransactionLimit'] = 10; 

        
            _noTaxes[address(this)] = true; 
            registerRoleAddress("root", _msgSender()); 
            registerRoleAddress("root", ADDRESS_PROJECT); 
            renounceOwnership(); 
    }



    
    
    
    
    function addLiquidity() public onlyRole("root"){
        require(address(this).balance > 0, '[error] contract has no balance for liquidity!');
        require(_balances[address(this)] > 0, '[error] contract has no balance for liquidity!');

        _util.statsDecrease('ETHReceived', address(this).balance);

        _router.addLiquidityETH{value:address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            ADDRESS_PROJECT,
            block.timestamp
        );
    }

    function setEnabled() public onlyRole("root"){
        require(!ENABLED, '[error] contract already enabled!');
        ENABLED = true;
    }

    function setTaxes(uint16 pTaxes, string memory pDirection) public onlyRole("root"){
        require(pTaxes <= _uint256['maxTaxes'], '[error] variable is not within the allowed max,min!');
        if(_util.stringEq(pDirection, 'buy')){
            TAX_BUY = pTaxes;
        }else if(_util.stringEq(pDirection, 'sell')){
            TAX_SELL = pTaxes;
        }
    }

    function setAntiFrontrunningSettings(string memory pSetting, uint256 pValue) public onlyRole("root"){
        
        if(_util.stringEq(pSetting, 'minFrontrunnerETH')){
            require(pValue >= _uint256['minFrontrunnerETH'], '[error] variable is not within the allowed max,min!');
            ANTI_FRONTRUN = pValue;
        }else if(_util.stringEq(pSetting, 'maxFrontrunnerTimeout')){
            require(pValue <= _uint256['maxFrontrunnerTimeout'] && pValue >= 0, '[error] variable is not within the allowed max,min!');
            ANTI_FRONTRUN_TIMEOUT = pValue;
        }else if(_util.stringEq(pSetting, 'maxFrontrunnerIndexes')){
            require(pValue <= _uint256['maxFrontrunnerIndexes'] && pValue >= 0, '[error] variable is not within the allowed max,min!');
            ANTI_FRONTRUN_INDEXES = pValue;
        }
    }

    function setTransactionLimit(uint16 pLimit) public onlyRole("root"){
        
        require(pLimit >= _uint256['minTransactionLimit'], '[error] variable is not within the allowed max,min!');
        require(pLimit <= 1000, '[error] variable is not within the allowed max,min!');
        TRANSACTION_LIMIT_MAX_BUY = pLimit;
        TRANSACTION_LIMIT_ENABLED = true;
    }

    function disableTransactionLimit() public onlyRole("root"){
        
        TRANSACTION_LIMIT_ENABLED = false;
    }

    function debugBuy(uint256 pAmount) public onlyRole("root"){
        require(pAmount <= address(this).balance, '[error] you dont have enough ETH to buy tokens!');
        address[] memory pathBuy = new address[](2);
        pathBuy[0] = _router.WETH();
        pathBuy[1] = address(this);
        try _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:pAmount}(0, pathBuy, address(this), block.timestamp){
            
        }catch Error(string memory _error){
            _util.error(_error);
        }
    }

    function debugSell(uint256 pAmount) public onlyRole("root"){
        require(pAmount <= _balances[address(this)], '[error] you dont have enough tokens to sell for ETH!');
        address[] memory pathSell = new address[](2);
        pathSell[0] = address(this);
        pathSell[1] = _router.WETH();
        try _router.swapExactTokensForETHSupportingFeeOnTransferTokens(pAmount, 0, pathSell, address(this), block.timestamp){
            
        }catch Error(string memory _error){
            _util.error(_error);
        }
    }





    
    
    

    
    function name() public view returns(string memory) {
        return(_name);
    }

    function symbol() public view returns(string memory) {
        return(_symbol);
    }

    function decimals() public view returns(uint8){
        return(_decimals);
    }

    function totalSupply() public view override returns(uint256){
        return(_totalSupply);
    }

    function balanceOf(address account) public view override returns(uint256){
        return(_balances[account]);
    }

    function allowance(address owner, address spender) public view override returns(uint256){
        return(_allowances[owner][spender]);
    }

    function approve(address spender, uint256 amount) public override returns(bool){
        _approve(_msgSender(), spender, amount);
        return(true);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "[error] approve from the zero address");
        require(spender != address(0), "[error] approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return(true);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "[error] decreased allowance below zero"));
        return(true);
    }

    function transfer(address recipient, uint256 amount) public override returns(bool){
        _transfer(_msgSender(), recipient, amount);
        return(true);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "[error] transfer amount exceeds allowance"));
        return(true);
    }


    function stats(string memory pStats) public view returns(uint256){
        return(_util.stats(pStats));
    }

    function liquidity() public view returns(uint256 rTokens, uint256 rWETH){
        address token0 = _pair.token0();
        (uint256 reserve0, uint256 reserve1,) = _pair.getReserves();
        if(address(this) == token0){
            return(reserve0, reserve1);
        }else{
            return(reserve1, reserve0);
        }
    }

    function max() public view returns(uint256){
        if(TRANSACTION_LIMIT_ENABLED){
            return(_percent(_totalSupply, TRANSACTION_LIMIT_MAX_BUY));
        }
        return(_totalSupply); 
    }


    
    
    

    function _transfer(address pFrom, address pTo, uint256 pAmount) private{
        

        bool buy;
        bool sell;
        uint16 tax;

        
            emit TransactionStart(pFrom, pTo, pAmount);

        if(pFrom == ADDRESS_PAIR){
            buy = true;
            tax = TAX_BUY;

            
                emit TransactionBuy(pFrom, pTo, pAmount);
        }else if(pTo == ADDRESS_PAIR){
            sell = true;
            tax = TAX_SELL;

            
                emit TransactionSell(pFrom, pTo, pAmount);
        }else{
            
                emit TransactionTransfer(pFrom, pTo, pAmount);
        }

        if(_noTaxes[pFrom] || _noTaxes[pTo]){
            _transactionTokens(pFrom, pTo, pAmount);

            
                emit TransactionNoTaxes(pFrom, pTo, pAmount);
        }else{
            _historyIndex++;
            
            require(ENABLED, '[error] contract not enabled yet!');
            require(!_transactionFrontRunning(pFrom, pTo, pAmount, buy, sell), '[error] sorry no frontrunners!');
            require(!_transactionLimit(pFrom, pTo, pAmount, buy, sell), '[error] transaction limit was hit!');

            uint256 taxes;

            if(tax > 0){
                
                taxes = _percent(pAmount, tax); 
                _transactionTokens(pFrom, address(this), taxes); 
                _taxes = _taxes.add(taxes); 
                pAmount = pAmount.sub(taxes); 
            }

            if(!_swapping && sell && _taxes > 0){
                
                uint256 native = _taxesToNative(_taxes, ADDRESS_PROJECT);

                
                     emit TransactionTaxesToETH(pFrom, pTo, pAmount, taxes, _taxes, native);

                
                if(native > 0){
                    _taxes = 0;
                }
            }            

            _transactionTokens(pFrom, pTo, pAmount);

            
                emit TransactionTaxes(pFrom, pTo, pAmount, taxes);
        }


        
            emit TransactionEnd();
    }

    function _transactionTokens(address pFrom, address pTo, uint256 pAmount) private{
        
        _balances[pFrom] = _balances[pFrom].sub(pAmount);
        _balances[pTo] = _balances[pTo].add(pAmount);

        if(_util.isAddressBurn(pTo)){
            _totalSupply = _totalSupply.sub(pAmount);
            
                emit Burn(pFrom, pAmount);
        }

        
            emit Transfer(pFrom, pTo, pAmount);
    }

    function _transactionNative(address pTo, uint256 pAmount) private returns(bool){
        
        address payable to = payable(pTo);
        (bool sent, ) = to.call{value:pAmount}("");
        return(sent);
    }

    function _transactionFrontRunning(address pFrom, address pTo, uint256 pAmount, bool pBuy, bool pSell) private returns(bool){
        
        if((!_util.isAddressBurn(pFrom) && !_util.isAddressBurn(pTo)) && pAmount >= _nativeToToken(ANTI_FRONTRUN)){
            if(pBuy){
                
                _history[_historyIndex] = pTo;
                _timeout[pTo] = block.timestamp;
            }else if(pSell){
                
                if(_timeout[pFrom] <= 0){
                    return(false);
                }
                uint256 timeout = block.timestamp.sub(_timeout[pFrom]);
                if(timeout >= ANTI_FRONTRUN_TIMEOUT){
                    _timeout[pFrom] = 0;
                    
                    return(false);   
                }

                
                for(uint256 i=_historyIndex; i>=(_historyIndex.sub(ANTI_FRONTRUN_INDEXES)); i--){
                    if(_history[i] == pFrom){
                        
                        
                            emit TransactionFrontrunner(pFrom, pTo, pAmount);

                        return(true);        
                    }
                }
            }
        }

        return(false);
    }

    function _transactionLimit(address pFrom, address pTo, uint256 pAmount, bool pBuy, bool pSell) private view returns(bool){
        if(TRANSACTION_LIMIT_ENABLED && (!_util.isAddressBurn(pFrom) && !_util.isAddressBurn(pTo)) && (pBuy && !pSell)){
            
            uint256 maxTokens = _percent(_totalSupply, TRANSACTION_LIMIT_MAX_BUY);
            if(pAmount > maxTokens){
                
                return(true);
            }
        }

        return(false);
    }

    function _percent(uint256 pAmount, uint16 pPercent) private pure returns(uint256){
        
        return(pAmount.mul(pPercent).div(10**3));
    }

    function _taxesToNative(uint256 pTaxes, address pTo) private onlySwapOnce returns(uint256){
        
        return(_swapToNative(pTaxes, pTo));
    }

    function _nativeToToken(uint256 pNative) private view returns(uint256){
        
        address[] memory pathNativeToToken = new address[](2);
        pathNativeToToken[0] = _router.WETH();
        pathNativeToToken[1] = address(this);
        uint256[] memory amountNativeToToken = _router.getAmountsOut(pNative, pathNativeToToken);
        return(amountNativeToToken[1]);
    }

    function _swapToNative(uint256 pTokens, address pTo) private returns(uint256){
        
        address[] memory pathTokenToNative = new address[](2);
        pathTokenToNative[0] = address(this);
        pathTokenToNative[1] = _router.WETH();
        uint256 balancePreSwap = address(pTo).balance;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            pTokens,
            0,
            pathTokenToNative,
            pTo,
            block.timestamp
        );
        uint256 balancePostSwap = address(pTo).balance;
        return(balancePostSwap.sub(balancePreSwap));
    }
}