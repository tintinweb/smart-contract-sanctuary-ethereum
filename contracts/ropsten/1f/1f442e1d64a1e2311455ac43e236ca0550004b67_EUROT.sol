/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity ^0.5.17;

/**
Symbol          : EUT
Name            : EUROT
Total supply    : 1000000000
Decimals        : 6
Website 		: https://www.eurot.org
*/
   
contract EUROT {
    
     string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address private owner;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _address, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowed;
  mapping (address => bool) public isOwners;
 
    constructor() public{
    name = "EUROT";
    symbol = "EUT";
    decimals = 6;
    totalSupply = 1000000000 * 10 ** uint256(decimals);
    _balances[msg.sender] = totalSupply;
    owner = msg.sender;
    isOwners[msg.sender] = true;
    }
 
    function balanceOf(address _address) public view returns (uint256 balance) {
    return _balances[_address];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowed[_from][msg.sender]); 
    _allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _address, address _spender) public view returns (uint256 remaining) {
    return _allowed[_address][_spender];
  }

  function burn(uint256 _value) public returns (bool success) {
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

  function  changeOwner (address payable _newAdress) public {
    require (isOwners[msg.sender]);
    isOwners[msg.sender] = false;
    isOwners[_newAdress] = true;

    if(msg.sender == owner){
      owner = _newAdress;
      return;
    }
    
  }


  function _transfer(address _from, address _to, uint _value) internal {
    require(_to != address(0x0));
    require(_balances[_from] >= _value);
    require(_balances[_to] + _value > _balances[_to]);
    uint previousBalances = _balances[_from] + _balances[_to];
    _balances[_from] -= _value;
    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    assert(_balances[_from] + _balances[_to] == previousBalances);
  }

}