pragma solidity ^0.4.11;

//   _____ _____ _____ 
//  | __  |   __|     |
//  | __ -|   __| | | |
//  |_____|_____|_|_|_|

//  The Bitcoin Empire contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20)
//  It follows the optional extras intended for use by humans https://github.com/consensys/tokens

import './IERC20.sol';
import './SafeMath.sol';

contract BitcoinEmpireToken is IERC20 {

  using SafeMath for uint256;
  
  string public constant symbol = "BEM";
  string public constant name = "Bitcoin Empire";
  uint8 public constant decimals = 18;
  uint public _totalSupply = 15000000000000000000000000; // 15,000,000 BEM initial supply assigned to Bitcoin Empire for distribution
  uint public _totalAvailable = 5000000000000000000000000; // 5,000,000 BEM available to create
  uint256 public constant MAXTOKENS = 20000000000000000000000000; // 20,000,000 BEM maximum limit
  uint256 public constant RATE = 8000; // 1 ETH = 8000 BEM

  address public owner;
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  function () payable {
    createTokens();
  }

  function BitcoinEmpireToken() {
    balances[msg.sender] = _totalSupply;
    owner = msg.sender;
  }

  function createTokens() payable returns (bool success) {
    uint256 tokens = msg.value.mul(RATE);
    require(
      msg.value > 0
      && _totalAvailable >= tokens
    );
    balances[msg.sender] = balances[msg.sender].add(tokens);
    _totalSupply = _totalSupply.add(tokens);
    _totalAvailable = _totalAvailable.sub(tokens);
    owner.transfer(msg.value);
    return true;
  }

  function totalSupply() constant returns (uint256 totalSupply) {
    return _totalSupply;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    require(
      _value > 0
      && balances[msg.sender] >= _value
    );
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(
      allowed[_from][msg.sender] >= _value
      && balances[_from] >= _value
      && _value > 0
    );
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}