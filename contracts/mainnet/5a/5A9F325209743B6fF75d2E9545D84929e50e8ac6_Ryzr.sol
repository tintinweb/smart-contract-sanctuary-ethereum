/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminRole}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 */
contract Administration is Context {
  address private _admin;

  event AdminRoleTransferred(address indexed previousAdmin, address indexed newAdmin);

  /**
   * @dev Initializes the contract setting the deployer as the initial admin.
   */
  constructor () {
    address msgSender = _msgSender();
    _admin = msgSender;
    emit AdminRoleTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current admin.
   */
  function admin() public view returns (address) {
    return _admin;
  }

  /**
   * @dev Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    require(_admin == _msgSender(), "Administration: caller is not the admin");
    _;
  }

  /**
   * @dev Leaves the contract without admin. It will not be possible to call
   * `onlyAdmin` functions anymore. Can only be called by the current admin.
   *
   * NOTE: Renouncing admin role will leave the contract without an admin,
   * thereby removing any functionality that is only available to the admin.
   */
  function renounceAdminRole() public onlyAdmin {
    emit AdminRoleTransferred(_admin, address(0));
    _admin = address(0);
  }

  function transferAdminRole(address newAdmin) public onlyAdmin {
    _transferAdminRole(newAdmin);
  }

  function _transferAdminRole(address newAdmin) internal {
    require(newAdmin != address(0), "Administration: new admin is the zero address");
    emit AdminRoleTransferred(_admin, newAdmin);
    _admin = newAdmin;
  }
}

contract Ryzr is Context, IERC20, Administration {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  address public _burnAddress = 0x000000000000000000000000000000000000dEaD;
  address public _bridge;
  address internal _administrator;

  modifier onlyBridge() {
    require(msg.sender == _bridge, "MUST_BE_BRIDGE"); _;
    }

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  

  bool tradingOpen = false;
  uint256 public launchedAt;
  uint256 public unlockTime = 9999999999;
  mapping (address => bool) public isExempt;

  constructor() {
    _name = "Ryzr Token";
    _symbol = "RYZR";
    _decimals = 9;
    _totalSupply = 1000000 * 10**_decimals; // 1 Million tokens
    _balances[msg.sender] = _totalSupply;
    _administrator = msg.sender;

    isExempt[msg.sender] = true;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  function name() external view override returns (string memory) {
    return _name;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function exemptAddress(address _address) external onlyAdmin {
    isExempt[_address] = true;
  }

  function includeAddress(address _address) external onlyAdmin {
    isExempt[_address] = false;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if(block.timestamp < unlockTime){ 
      if(!isExempt[sender] || !isExempt[recipient]){
        require(sender == _administrator || recipient == _administrator, "Trading not open yet.");
      }
    }
    
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function setBridgeAddress(address bridge) external onlyAdmin {
    _bridge = bridge;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    if(block.timestamp < unlockTime){ 
      if(!isExempt[sender] || !isExempt[recipient]){
        require(sender == _administrator || recipient == _administrator, "Trading not open yet.");
      }
    }

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

    function mint(address receiver, uint256 amount) external onlyBridge {
      require(msg.sender != address(0));
      require(amount < _totalSupply.div(50), "MINT: EXCEEDS_MAX");
      _totalSupply = _totalSupply.add(amount);
      _balances[receiver] += amount;
      emit Transfer(msg.sender, receiver, amount);
  }

  function burn(uint256 amount) public {
      require(_totalSupply > 0, "BURN: TOTAL_SUPPLY_ZERO");
      require(amount < _totalSupply, "BURN: TOTAL_SUPPLY_EXCEEDED");
      _totalSupply = _totalSupply.sub(amount);
      _transfer(msg.sender, _burnAddress, amount);
  }

  function openTrading(uint256 _unlockTime) external onlyAdmin {
      require(!tradingOpen);
      unlockTime = _unlockTime;
      launchedAt = block.timestamp;
      tradingOpen = true;
  }
}