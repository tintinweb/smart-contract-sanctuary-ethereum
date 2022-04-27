/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

abstract contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public override returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract HigasasuToken is StandardToken {

    // metadata
    string public constant name = "Higasasu Token";
    string public constant symbol = "HGSS";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public tokenFundDeposit;      // deposit address for HigasasuToken International use and HGSS User Fund

    // crowdsale parameters
    uint256 public constant tokenFund = 1 * (10**3) * 10**decimals;   // 1000 HGSS reserved for HigasasuToken Intl use

    // events
    event CreateHigasasuToken(address indexed _to, uint256 _value);

    // constructor
    constructor(address _tokenFundDeposit)
    {
      tokenFundDeposit = _tokenFundDeposit;
      totalSupply = tokenFund;
      balances[tokenFundDeposit] = tokenFund;    // Deposit HigasasuToken Intl share
      emit CreateHigasasuToken(tokenFundDeposit, tokenFund);  // logs HigasasuToken Intl fund
    }
}