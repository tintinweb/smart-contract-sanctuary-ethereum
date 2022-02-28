// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract DogCoin {

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event HolderChange(address indexed _owner, bool _isActive);

  string public name;
  string public symbol;
  
  uint public decimals;

  uint public totalSupply;

  mapping(address => uint) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  address[] private _holders;
  address public immutable deployer;

  constructor(
    string memory _name,
    string memory _symbol,
    uint _decimals,
    uint _totalSupply
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

    deployer = msg.sender;
    _balances[msg.sender] = _totalSupply; // All DogCoin to deployer
    _addHolder(msg.sender); // Zero-index to deployer
    totalSupply = _totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowances[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_balances[msg.sender] >= _value, "No funds!");
    return _transfer(msg.sender, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_balances[msg.sender] >= _value, "No funds!");
    _allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    success = true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_to == msg.sender, "Not spender");
    require( _value <= _allowances[_from][_to], "Not enough allowance!");
    return _transfer(_from, _to, _value);
  }

  function _transfer(address _from, address _to, uint amount) internal returns (bool success){
    _balances[_from] -= amount;
    _balances[_to] += amount;

    if (_to != deployer) {
      if (!_isholder(_to)) {
        _addHolder(_to);
      }
    }

    if (_balances[_from] == 0) {
      _removeHolder(_from);
    }

    emit Transfer(_from, _to, amount);
    success = true;
  }

  function holders() public view returns(address[] memory) {
    return _holders;
  }

  function _isholder(address user) internal view returns (bool holder) {
    if (user != deployer) {
      if (_holderIndex(user) > 0) {
        holder = true;
      }
    } 

  }

  function _holderIndex(address user) internal view returns (uint index) {
    for (uint256 i = 0; i < _holders.length; i++) {
      if (_holders[i] == user) {
        index = i;
      }
    }
  }

  function _addHolder(address user) private {
    require(_balances[user] > 0);
    _holders.push(user);
    emit HolderChange(user, true);
  }

  function _removeHolder(address user) private {
    require(_balances[user] == 0);
    uint index = _holderIndex(user);
    delete _holders[index];
    _shuffleHolders(index);
    emit HolderChange(user, false);
  }

  function _shuffleHolders(uint _startingIndex) private {
    bool islastIndexinArray = _startingIndex == _holders.length - 1;
    if (islastIndexinArray) {
      _holders.pop();
    } else {
      for (uint256 index = _startingIndex; index < _holders.length; index++) {
        if(index + 1 < _holders.length) {
          _holders[index] = _holders[index + 1];
          delete _holders[index + 1];
        } else {
          _holders.pop();
        }
      }
    }
  }

}