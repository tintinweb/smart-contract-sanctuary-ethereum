/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicERC20 {
  
  event Transfer (address indexed from, address indexed to, uint256 value); 
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed; // {user: { user2 : amount, user3:amount2 ... }}

  uint public decimals;
  uint public totalSupply_;

  string public name; // Wrapped Bitcoin
  string public symbol; // WBTC

  modifier sufficientBalance(address _spender, uint _value){
    require(_value <= balances[_spender] , "Insufficient Balance for User");
    _;
  }

  modifier sufficientApproval(address _owner, address _spender, uint _value){
    require(_value <= allowed[_owner][_spender], "Insufficient allowance for this User from owner");
    _;
  }

  modifier validAddress(address _address){
    require(_address != address(0), "Invalid address");
    _;
  }

  constructor(uint _totalSupply, uint _decimals, string memory _name, string memory _symbol){
      totalSupply_ = _totalSupply;
      decimals = _decimals;
      name = _name;
      symbol = _symbol;

      balances[msg.sender] = totalSupply_;  
  }
  
  function totalSupply() public view virtual returns(uint256){
    return totalSupply_;
  }

  function balanceOf(address _who) public view virtual returns(uint256){
    return balances[_who];
  }

  function transfer(address to, uint256 value) public virtual sufficientBalance(msg.sender, value) validAddress(to) returns(bool){
    balances[msg.sender] = balances[msg.sender] - value;
    balances[to] = balances[to] + value;
    emit Transfer(msg.sender, to, value);
    
    return true;
  }

  function approve(address spender, uint256 value) public virtual validAddress(spender) returns(bool){
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);

    return true;
  }
  
  function allowance(address owner, address spender) public virtual view returns(uint256){
      return allowed[owner][spender];
  }

  function transferFrom(address from, address to, uint256 value) public virtual sufficientBalance(from, value) sufficientApproval(from, msg.sender, value) validAddress(to) returns(bool){
      allowed[from][msg.sender] = allowed[from][msg.sender] - value; // Reduce your allowance
      balances[from] = balances[from] - value; // Reduce the allocators balance
      balances[to] = balances[to] + value; // We increase the end user/address's balance
      emit Transfer(from, to, value);
      return true;

  } 
  
}