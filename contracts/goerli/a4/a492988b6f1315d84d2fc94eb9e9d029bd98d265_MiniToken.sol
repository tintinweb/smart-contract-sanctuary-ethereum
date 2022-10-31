/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

pragma solidity ^0.5.2;
contract MiniToken {
  string public name = "Chicken";
  string public symbol = "Chicken";
  uint8 public decimals = 18;
  uint public totalSupply = 6666666666666* (10 ** 18);
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256) ) public allowance;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  constructor() public {
    balanceOf[msg.sender] = totalSupply;
  }
  function transfer(address _to, uint256 _value) public returns (bool){
    require(_to != address(0));
    require(balanceOf[msg.sender] >= _value);
    require(balanceOf[_to] + _value >= balanceOf[_to]);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
    require(_to != address(0));
    require(balanceOf[_from] >= _value);
    require(allowance[_from][msg.sender]  >= _value);
    require(balanceOf[_to] + _value >= balanceOf[_to]);
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool){
    require((_value == 0)||(allowance[msg.sender][_spender] == 0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
}