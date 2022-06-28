/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity ^0.5.0;
/*
noob-ctf-challenges week 2
TWITTER:@definoobdao
alpha/dev/blockchain_security
gtihub: https://github.com/definoobdao/noob-ctf-challenges
*/
interface Inoobpoint  {
    function sendpotion(address recipient, uint256 amount) external;
    function getnickname(address challenger) external returns(string memory);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  string public name = "Noob-Ctf-week2-Vlun-Token";
  string public symbol = "vlun";
  uint256 public totalSupply;
  function balanceOf(address who) public view  returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ctf{
  mapping (address => bool) public isComplete;
  event CompleteCtflog(address indexed challenger, string nickname, string message);
}

contract NoobCtfChallengesWeek2 is ERC20Basic, ctf{
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    using SafeMath for uint256;
    Inoobpoint public pointcontract;
    
  constructor(address payable _pointcontract) public {
    pointcontract =  Inoobpoint(_pointcontract); 
  }

  function balanceOf(address _owner) public view  returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function batchTransfer(address[] memory _receivers, uint256 _value) public  returns (bool) {
    uint num = _receivers.length;
    uint256 amount = uint256(num) * _value;
    require(num > 0 && num <= 20);
    require(_value > 0 && balances[msg.sender] >= amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    for (uint i = 0; i < num; i++) {
        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
        emit Transfer(msg.sender, _receivers[i], _value);
    }
    return true;
  }
  
  function CompleteCtf() public {
    require(balanceOf(msg.sender) > 10000000000000000000 && !isComplete[msg.sender]);
    isComplete[msg.sender] = true;
    pointcontract.sendpotion(msg.sender, 30);
    emit CompleteCtflog(msg.sender, pointcontract.getnickname(msg.sender) , "Complete Week 2 Challenge");
  }

}