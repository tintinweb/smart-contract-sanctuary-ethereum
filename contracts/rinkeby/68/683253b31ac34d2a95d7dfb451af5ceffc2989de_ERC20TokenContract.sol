/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity 0.4.24;

contract ERC20TokenContract {
  
  uint256 _totalSupply;
  mapping(address => uint256) balances;
  
  constructor(uint256 _initialSupply) public {
    _totalSupply = _initialSupply;
    balances[msg.sender] = _initialSupply;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    return true;
  }

}