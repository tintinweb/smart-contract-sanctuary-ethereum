/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: No License
pragma solidity ^0.6.0;

   

contract coins {

    string public  name ="ERest";
    string public symbol ="PVS";
    uint public decimals = 2;

    uint public _totalSupply = 100000;

    mapping(address => uint) balances;
    mapping(address =>mapping(address=>uint)) allowed;

    constructor() public {
        balances[msg.sender]=_totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function totalSupply() public view returns(uint){
        return _totalSupply;
    }

    function approve(address deligate, uint _value) public returns(bool success){
        allowed[msg.sender][deligate]=_value;
        emit Approval(msg.sender, deligate, _value);
        return true;
    }

    function allowance(address owner,address deligate ) public view returns(uint){
        return allowed[owner][deligate];
    }


    function transfer(address _to, uint _amount) public  returns(bool success){
        require(_amount <= balances[msg.sender], "Wow,sorry but owner dont have this amount token");
        balances[msg.sender] -=_amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    } 

    function transferFrom(address _from, address _to, uint _amount) public returns(bool success){
        require(_amount <= balances[_from], "Wow,sorry but owner dont have this amount token");
        require(_amount <= allowed[_from][msg.sender], "amount more allowed");
        balances[_from]-=_amount;
        allowed[_from][msg.sender] -=_amount;
        balances[_to] -= _amount;
        emit Transfer(_from,_to,_amount);
        return true;
    }  

    function balanceOf(address account) public view returns(uint){
        return balances[account]; 
        }


}