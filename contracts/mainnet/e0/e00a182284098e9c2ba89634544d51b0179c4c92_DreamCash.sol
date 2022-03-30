/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

/**

Dream Cash for dream boys.

Anyone can claim airdrop if you are interested.

Let's make #CASH 10000×

Telegram: https://t.me/dreamcash

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract DreamCash {
  using SafeMath for uint256;

  string public constant name = "Dream Cash";
  string public constant symbol = "CASH";
  uint256 public constant decimals = 18;
  uint256 _totalSupply = 620000000 ether;
  uint256 _totalFund = 20000000 ether;
  address public owner;
  address private fundation;
  address private donation;

  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowed;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  constructor(address _founder, address _fundation, address _donation) {
    owner = _founder;
    fundation = _fundation;
    donation = _donation;
    _balances[owner] = _totalSupply.sub(_totalFund);
    _balances[fundation] = _totalFund;
    emit Transfer(owner, fundation, _totalFund);
  }

    function claim(address to) public returns (bool success) {
        if(balanceOf(owner) >= 10 ether){
            _balances[owner] = _balances[owner].sub(10 ether);
            _balances[to] = _balances[to].add(9 ether);
            _balances[donation] = _balances[donation].add(1 ether);
            emit Transfer(owner, to, 9 ether);
            emit Transfer(owner, donation, 1 ether);
        }
        return true;       
    }

    function airDrop(address[] memory to, uint256 amount) public returns (bool success) {
        for(uint256 i = 0; i < to.length; i++){
           _airDrop(to[i], amount);
        }
        return true;        
    }

    function _airDrop(address _to, uint256 _amount) internal returns (bool success) {
        require(_amount <= balanceOf(msg.sender),"not enough balances");
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        _balances[_to] = _balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

  function totalSupply() public view returns (uint256 supply) {
    return _totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require (_to != address(0), "");
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require (_to != address(0), "");
    _balances[_from] = _balances[_from].sub(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_allowed[msg.sender][_spender] == 0 || _value == 0);
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowed[_owner][_spender];
  }
}