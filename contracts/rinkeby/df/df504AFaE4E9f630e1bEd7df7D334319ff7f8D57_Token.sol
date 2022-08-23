//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Token {
    string public name = "GiftCenter Token";
    string public symbol = "GCR";
    uint public totalSupply = 1000000;

    address public owner;

    mapping(address=>uint) balances;

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function transfer(address _to, uint _tokenAmount) external{
        require(balances[msg.sender] >= _tokenAmount, "Not enough tokens");
        balances[msg.sender] -= _tokenAmount;
        balances[_to] += _tokenAmount;
    }

    function balanceOf(address _account) external view returns(uint){
        return balances[_account];
    } 
}