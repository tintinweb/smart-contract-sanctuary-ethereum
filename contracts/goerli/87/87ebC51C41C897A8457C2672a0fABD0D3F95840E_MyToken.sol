/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// NOTE: msg.sender = god variable, those who send it

contract MyToken {
  // NOTE: defined: total supply of token
  uint256 constant supply = 1000000;

  // event to be emitted on transfer
  // NOTE: use "emit" in a function to create a log in the blockchain
  event Transfer(
    address indexed _from,
    address indexed _to, 
    uint256 _value
  ); // note the variables: _from, _to, _values to be used later

  // event to be emitted on approval
  // NOTE: use "emit" to create a log
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  ); // note the variables: _owner, _spender, _values

  // TODO: create mapping for balances
  // NOTE: its like a dictionary, every address should have a balance variable.
  // NOTE: address corresp. "_from" "_to"; balance corresp. "_value"
  mapping(address => uint256) public balances;

  // TODO: create mapping for allowances
  // NOTE: another dictionary, every user has a specific allowance for another user!
  mapping(
    address => mapping(address => uint256)
  ) public allowances;

  constructor() {
    // TODO: set sender's balance to total supply
    // NOTE: 
    balances[msg.sender] = supply;
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
    require(balances[msg.sender] >= _value);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    require(balances[_from] >= _value);
    require(allowances[_from][msg.sender] >= _value);
    balances[_from] -= _value;
    balances[_to] += _value;
    allowances[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    // TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten
    // the interaction with the blockchain is to send a message
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value); // creates an event log in the blockchain
    return true;
    // this is required by the return(bool)
    // note that after return, any code after that will be ignored
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