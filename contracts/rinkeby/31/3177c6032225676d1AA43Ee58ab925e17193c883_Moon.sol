//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//https://www.youtube.com/watch?v=cUUlrJ9Y9Z4&list=PLxBQKTwGKNkM_pyg1XerSWx17_9V3aLoU
contract Moon{

    mapping(address =>uint) public balances;
    mapping(address => mapping(address=>uint)) public allowance;

    // Coin infomation
    uint public toltalSupply =100 * 10 ** 18;
    string public name="MoonCoin";
    string public symbol="MC";
    uint public decimals=18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed Owner, address indexed sender, uint value);
    // Run when it is deployed
    constructor (){
        balances[msg.sender]=toltalSupply;
    }
    function balanceOf(address Owner) public view returns(uint){
        return balances[Owner];
    }

    function transfer(address to, uint value) public returns(bool){
        require(balances[msg.sender]>value,"insufficient funds");
        balances[to] +=value;
        balances[msg.sender] -=value;
        emit Transfer(msg.sender, to,value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balances[from]>value,"insufficient funds");
        balances[to] +=value;
        balances[from] -=value;
        emit Transfer(from, to,value);
        return true;
    }
    function approval(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
        return true;

    }

}