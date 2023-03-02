// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TigerToken {
  // Since these constants are public, get methods are automatically generated.
  // Fill out these constants to personalize your token!
  string public constant name = "TigerToken";
  string public constant symbol = "TT";
  uint8 public constant decimals = 8;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  // ... other constants / variables here.

  using SafeMath for uint256;

  constructor(uint256 _initialSupply) {
    _totalSupply = _initialSupply;
    _balances[msg.sender] = _initialSupply;
  }

  // You must emit these events when certain triggers occur (see the ERC-20 spec).
  event Approval(address indexed _from, address indexed _to, uint256 _value);
  event Transfer(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint) {
    return _balances[_owner];
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_balances[_from] >= _value, "TigerToken: transfer value exceeds sender balance");

    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);

    emit Transfer(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    _transfer(from, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_allowances[_from][msg.sender] >= _value, "TigerToken: transfer value greater than allowance");
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value)  public returns (bool) {
    _allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint) {
    return _allowances[_owner][_spender];
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 sum = a + b;
    assert(sum >= a);
    return sum;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}