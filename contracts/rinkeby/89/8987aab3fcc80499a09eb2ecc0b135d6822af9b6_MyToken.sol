/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;


contract MyToken {
  /// The total supply of tokens
  /// This is constant throughout the lifetime of the contract
  uint256 constant _totalSupply = 1000000;

  /// Stores the balance of the useres
  mapping (address => uint256) balances;

  /// Store the allowances
  /// The first mapping contains the address of the owner of the coins
  /// The second mapping contains the address of the party spending the
  /// coins on the owner's behalf
  /// e.g. allowances[A][B] = 8
  /// allows B to spend 8 coins on behalf of A
  mapping (address => mapping(address => uint256)) allowances;

  /// Event emitted when a transfer is executed
  /// See ERC-20 spec for more details
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /// Event emitted when a certain amount of money is approved to be used
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /// Set the contract creator's balance to the total supply of tokens
  /// i.e. The creator initially owns all the tokens
  constructor() public {
    balances[msg.sender] = _totalSupply;
  }

  /// Returns the total supply of tokens
  function totalSupply() public pure returns (uint256) {
    return _totalSupply;
  }

  /// Returns the balance of `_owner`
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /// Helper function to execute transfer
  /// Assumes that the transfer is valid, so checks should be made by the caller
  function executeTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
    balances[_from] -= _value;
    balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  /// Transfer `_value` from sender to `_to`
  /// Sender must have at least a balance of `_value` or the
  /// transaction will be reverted
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] >= _value, "balance too low");
    return executeTransfer(msg.sender, _to, _value);
  }

  /// Transfer `_value` from `_from` to `_to`
  /// `_from` must have at least a balance of `_value` and
  /// `_to` must be allowed to spend at least `_value` on `_from`'s behalf
  /// or the transaction will be reverted
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(balances[_from] >= _value, "balance too low");
    require(allowances[_from][_to] >= _value, "insufficient allowance");
    allowances[_from][msg.sender] -= _value;
    return executeTransfer(_from, _to, _value);
  }

  /// Allows `_spender` to spend `_value` on the sender's behalf
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /// Returns how much `_spender` is allowed to spend on `_owner`'s behalf
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }
}