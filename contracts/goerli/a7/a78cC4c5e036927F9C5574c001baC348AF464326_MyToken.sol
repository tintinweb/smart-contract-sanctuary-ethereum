/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
  // total supply of token
  uint256 constant supply = 1000000;//假设了币数量

  // event to be emitted on transfer
  event Transfer(address indexed _from, address indexed _to, uint256 _value);//广播信息：谁给了谁多少币

  // event to be emitted on approval
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );//广播信息：币的

  // TODO: create mapping for balances
  mapping(address=>uint256) public balances;

  // TODO: create mapping for allowances
  mapping(address=>mapping (address=>uint256)) public allowances;
  constructor() {
    // TODO: set sender's balance to total supply
    balances[msg.sender]= supply;//你爸妈现在有的钱
  }

  function totalSupply() public pure returns (uint256) {
    // TODO: return total supply
    return supply;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    // TODO: return the balance of _owner
    return balances[_owner];//币的所有者现在有多少钱
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from sender to `_to`
    // NOTE: sender needs to have enough tokens
    require(balances[msg.sender] >= _value);//你要有这么多钱
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);// 把信息传播出去，msg sender是你
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
  require(balances[_from]>= _value);//make sure enough money in owner's acct
  require(allowances[_from][msg.sender]>= _value);//人家同意我帮他转的钱的数量够不够这个value
  balances[_from] -= _value;
  balances[_to] += _value;
  allowances[_from][msg.sender]-= _value;
  emit Transfer(_from,_to,_value);
  return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    // TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten
  allowances[msg.sender][_spender] = _value;
  emit Approval(msg.sender, _spender, _value);
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