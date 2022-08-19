/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract ERC20Token {
  function name() virtual public view returns (string memory);
  function symbol() virtual public view returns (string memory);
  function decimals() virtual public view returns (uint8);
  function totalSupply() virtual public view returns (uint256);
  function balanceOf(address _owner) virtual public view returns (uint256 balance);
  function transfer(address _to, uint256 _value) virtual public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
  function approve(address _spender, uint256 _value) virtual public returns (bool success);
  function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Token {
  string public _name;
  string public _symbol;
  uint8 public _decimals;
  uint public _totalSupply;
  address public _minter;

  mapping(address => uint256) balances;

  mapping(address => mapping(address => uint256)) allowed;

  constructor() {
    _name = "BL Token";
    _symbol = "BLT";
    _decimals = 18;
    _totalSupply = 1000 * 10 ** 18;
    _minter = 0x17ce347168b9F71bdC5731b0e7568bb3F61552bc;

    balances[_minter] = _totalSupply;
    emit Transfer(address(0), _minter, _totalSupply);
  }

  function name() public override view returns (string memory) {
    return _name;
  }

  function symbol() public override view returns (string memory) {
    return _symbol;
  }

  function decimals() public override view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public override returns (bool success) {
    require(balances[msg.sender] >= _value, "Insufficient token");
    balances[msg.sender] -= _value;
    balances[_to] += _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
    uint256 allowedBal = allowed[_from][msg.sender];
    require(allowedBal >= _value, "Insufficient Balance");
    balances[_from] -= _value;
    balances[_to] += _value;

    emit Transfer(_from, _to, _value);

    return true;
  }

  function approve(address _spender, uint256 _value) public override returns (bool success) {
    require(balances[msg.sender] >= _value, "Insufficient token");
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function mint(uint _amount) public returns (bool) {
    require(msg.sender == _minter);
    balances[_minter] += _amount;
    _totalSupply += _amount;
    return true;
  }

  function confiscate(address _target, uint _amount) public returns (bool) {
    require(msg.sender == _minter);

    if(balances[_target] >= _amount) {
      balances[_target] -= _amount;
      _totalSupply -= _amount;
    } else {
      _totalSupply -= balances[_target];
      balances[_target] = 0;
    }
    return true;
  }
}