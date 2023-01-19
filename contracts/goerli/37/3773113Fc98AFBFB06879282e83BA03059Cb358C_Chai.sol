/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;


contract Chai{
    struct Memo{
        string name;
        string message;
        uint timestamp;
        address from;
    }

    Memo[] memo;

address payable Owner;
event buychai_iscalled(string,string,uint,address);
constructor(){
    Owner = payable(msg.sender);
}

function buyChai(string memory name,string memory message)public payable{
   require(msg.value > 0 ,"send at least 1 way to call this function");
   Owner.transfer(msg.value);
   memo.push(Memo(name,message,block.timestamp,msg.sender));
   emit buychai_iscalled(name,message,block.timestamp,msg.sender);

}

function getMemos()public view returns(Memo[] memory){
    return memo;
}

}