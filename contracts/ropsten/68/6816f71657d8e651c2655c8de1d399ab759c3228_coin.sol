/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity >=0.7.0 <9.0.0;
//SPDX-License-Identifier: GPL-3.0
// contract All_in_one{

//     uint Ether;
//     function Set(uint input) public{

//         Ether=input;
//     }
//     function get()public view returns(uint){
//         return Ether;
//     }

// }

contract coin{
    address public minter;
    mapping (address=>uint) public balances;
    
    event Sent(address from ,address to, uint amount);

    constructor(){
        minter=msg.sender;
    }
    function mint(address reciver,uint amount)public {
        require(msg.sender==reciver,"Not the owner");
        require(amount<10000000,"amount is to high to mint");
        balances[reciver]+=amount;
    }
    function send(address reciver,uint amount)public{
        require(balances[msg.sender]>amount,"Insufficent balances");
        balances[reciver]+=amount;
        balances[msg.sender]-=amount;
        emit Sent(msg.sender,reciver,amount);
    }

}