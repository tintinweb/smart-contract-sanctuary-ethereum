/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract hp {
    uint public start;
    uint public end;
    uint public available_credit;
    address public owner;

    constructor(uint alive_time) payable{
        start=block.timestamp;
        end=start+alive_time;
        owner=payable(msg.sender);
        available_credit=msg.value;
    }



    modifier onlyowner(){
        require(msg.sender == owner,"You are not the owner.");
        _;
    }

    modifier topublic(){
        require(block.timestamp<end,"The contract is closed to public.");
        _;
    }

    modifier minMoneyIn(){
        require(msg.value>0,"Send mo money bro.");
        _;
    }

    function deposit() public payable minMoneyIn{
        available_credit+=msg.value;
    }

    function transact() public payable minMoneyIn {
        available_credit+=msg.value;
        if(end < block.timestamp){
            payable(msg.sender).transfer(available_credit);
            available_credit=0;
        }
        
    }

    function safewithdraw() public payable onlyowner returns(uint){
        payable(owner).transfer(available_credit);
        available_credit=0;
        return available_credit;
    }
    function kill() public onlyowner {
        end=0;
    }
    function prolong(uint extratime) public onlyowner returns(uint){
        end=end+extratime;
        return end;
    }

    function current_time() public view returns(uint){
        return block.timestamp;
    }


 

}