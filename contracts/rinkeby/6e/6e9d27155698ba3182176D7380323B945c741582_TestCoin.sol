// SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.4.11;
pragma solidity ^0.8.0;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC20 {
  function balanceOf(address who) external  returns (uint);
  function transfer(address to, uint value) external returns (bool success);
  function allowance(address owner, address spender) external returns (uint);
  function transferFrom(address from, address to, uint value)  external returns (bool success);
  function approve(address spender, uint value) external  returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


contract BasicToken is ERC20 {
  using SafeMath for uint;
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  /*
   * Fix for the ERC20 short address attack  
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length < size + 4);
    _;
  }
  function balanceOf(address _owner) public view override returns (uint balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) public override virtual returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view override returns (uint) {
    return allowed[_owner][_spender];
  }
  function transferFrom(address _from, address _to, uint _value) public override virtual returns (bool success){
    uint _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint _value) public override virtual returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
}

contract TestCoin is BasicToken {
  uint public totalSupply;
  string public name = "TestCoin";
  string public symbol = "TestCoin";
  uint public decimals = 18;
  uint constant TOKEN_LIMIT = 10000000000 * 1e18;
  address public owner;
  bool tokensAreFrozen = true;

  constructor () {
    owner = msg.sender;
  }

  function mint(address _holder, uint _value) external{
    require(msg.sender == owner);
    require(_value != 0);
    require(totalSupply + _value <= TOKEN_LIMIT);

    balances[_holder] += _value;
    totalSupply += _value;
    emit Transfer(address(0), _holder, _value);
  }

  function unfreeze() external {
    require(msg.sender == owner);
    tokensAreFrozen = false;
  }
  function freeze() external {
    require(msg.sender == owner);
    tokensAreFrozen = true;
  }
}