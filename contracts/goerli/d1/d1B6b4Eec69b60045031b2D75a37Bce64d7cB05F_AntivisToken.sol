/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

pragma solidity ^ 0.8.17;
//SPDX-License-Identifier: MIT.

contract AntivisToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public decimal = 18;
    string public name = "virusToken";
    string public symbol = "VT";
    uint public totalSupply = 100000000000;

    event transfer(address indexed from, address indexed to, uint value);
    event approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transferto(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender)>= value, "insufficient balance");
        balances[to] += value;
        balances[msg.sender] -= value;
    
        emit transfer(msg.sender, to, value);
        return true;

    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
    require(balanceOf(from) >= value, "not enough balance");
    require(allowance[from][msg.sender] >= value, "allowance is too low");
    balances[to] += value;
    balances[from] -= value;
    emit transfer(from, to, value);
    return true;    
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit approval(msg.sender, spender, value);
        return true;
    }


}