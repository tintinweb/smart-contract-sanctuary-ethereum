// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Token{
    string public  name="MYTOKEN";
    string public symbol="TOK";

    uint256 public  totalSupply=100000;

    address public owner;

    mapping(address=>uint256) balances;

    constructor(){
        owner=msg.sender;
        balances[msg.sender]=totalSupply;
    }

    //event

    event Transfer(address indexed _from,address indexed _to,uint256 _value);


    //transfer functions

    function transfer(address _to,uint256 _amount) external {
           require(balances[msg.sender] >= _amount,"Insuffient balances");
           balances[msg.sender] -= _amount;
           balances[_to]=_amount;

           emit Transfer(msg.sender, _to, _amount);
    }

    //check balances

    function balanceOf(address _address) public view returns(uint256 _balance){
        return balances[_address];
    }


}