//SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.9.0;

contract GalazToken {
  // Variables
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  // Eventos
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // Modificadores

  // Constructor
  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;
    balanceOf[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  // Métodos
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(allowance[_from][msg.sender] >= _value, 'No tienes permiso');
    require(balanceOf[_from] >= _value, 'Not enough funds');
    balanceOf[_from] -= _value;
    allowance[_from][msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
  }
}