// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract PowerLedgerLegacy {

  string public constant name = 'PowerLedger';
  uint256 public constant decimals = 6;
  string public constant symbol = 'POWR';
  string public constant version = '1.0';
  string public constant note = 'Democratization of Power';

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint256 private constant totalTokens = 1000000000 * (10 ** decimals);

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  constructor() {
    balances[msg.sender] = totalTokens;
  }

  function totalSupply() public pure returns (uint256) {
    return totalTokens;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    if (balances[msg.sender] >= _value) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    }
    return false;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function compareAndApprove(address _spender, uint256 _currentValue, uint256 _newValue) public returns(bool) {
    if (allowed[msg.sender][_spender] != _currentValue) {
      return false;
    }
    return approve(_spender, _newValue);
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}