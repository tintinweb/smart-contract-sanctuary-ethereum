/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Alpha{
    string public name ;
    string public symbol;
    uint public total;
    uint public decimal = 18;
    address public owner;

    mapping(address=>uint) balances;

    event Transfer(address owner,address user,uint value);

    constructor(){
        name = "Alpha";
        symbol = "AIP";
        total = 5000000000000000000000;
        owner = msg.sender;
        balances[owner] = total;
    }

    function check(address _user) public view returns(uint){
       return balances[_user];
    }
    
    function mint(address _user, uint _value) public {
        require(_value > 0,"atleast 1 token");
        balances[_user] = _value;
        total+=_value;
    }
    function _transfer(address _user,uint _value) public {
        require(_value > 0,"atleast 1 token");
        require(msg.sender == owner,"only owner");
        balances[owner] -= _value;
        balances[_user] += _value;
        total-= _value;
        emit Transfer(msg.sender,_user,_value);
    }
   

}