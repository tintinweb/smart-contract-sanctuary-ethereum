/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier:MIT
pragma solidity >=0.5.0 <0.9.0;

contract DappToken{
    string public name = "Dapp Token";
    string public symbol = "DAPP";
    uint public decimals = 18;
    uint public totalSupply = 1000000000000000000000000;

    mapping(address=>uint) public balance;
    mapping(address=>mapping(address=>uint)) public allowance;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );

    event Approve(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    constructor(){
        balance[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint _value) public returns(bool success){
        require(balance[msg.sender] >= _value);
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns(bool success){
        require(balance[msg.sender] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns(bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }
}