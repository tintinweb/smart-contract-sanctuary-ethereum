/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.11;

library SivicSafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract SivicStandardToken  {
    
    uint256 public constant totalSupply = 10**31;
    string public constant name = "ChainSivic Token";
    uint8 public constant decimals = 18;
    string public constant symbol = "Sivic";

    function SivicStandardToken() public {
         balances[msg.sender] = totalSupply;
    }

    using SivicSafeMath for uint256;
    mapping(address => uint256) balances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    mapping(address => mapping(address => uint256)) allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool) {
        var _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
}