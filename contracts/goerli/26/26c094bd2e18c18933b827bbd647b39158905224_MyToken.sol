/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
  // total supply of token
  uint256 constant supply = 1000000;

  // event to be emitted on transfer
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // event to be emitted on approval
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  // TODO: create mapping for balances
mapping(address => uint256) public balances;

  // TODO: create mapping for allowances
mapping(address => mapping(address => uint256)) public allowances;

  constructor() {
    // TODO: set sender's balance to total supply
    balances[msg.sender]= supply;
  }

  function totalSupply() public pure returns (uint256) {
    // TODO: return total supply
    return supply;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    // TODO: return the balance of _owner
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from sender to `_to`
    // NOTE: sender needs to have enough tokens
    // NOTE: you want to transfer the funds from the sender to _to basically.
    require(balances[msg.sender] >= _value);
    balances[msg.sender] -=_value;
    balances[_to]+=_value;
    // NOTE: publish the message of approval, execute transfer from sender to to with the set value.
    emit Transfer(msg.sender,_to,_value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    require(balances[_from] >=_value);
    require(allowances[_from][msg.sender]>=_value);
    balances[_from] -=_value;
    balances[_to] +=_value;
    // NOTE: allowances always takes 2 variables so where from through msg.sender. 
    allowances[_from][msg.sender] -=_value;
    emit Transfer(_from,_to,_value);
    // NOTE: _from is the asset owner and the to is the party that recieves the amount set. 
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    // TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten
    allowances[msg.sender][_spender]=_value;
    emit Approval(msg.sender,_spender,_value);
    return true;
  }

  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256 remaining)
  {
    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    return allowances[_owner][_spender];
  }
}