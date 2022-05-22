/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// 0x757b63AF4D9811Fb8C6d26c5901c743BE392135e
contract sendether{
    address payable public owner;

    constructor() payable {
     owner = payable(msg.sender);   
    }
   
    uint public contractbalance;//contract value 
    uint public ownerbalance;
    uint public balanceto;
    
    function sendviacall(address payable _to,uint _value)public payable{//returns(bool sent,byte memory data) {
        (bool sent,)=_to.call{value: _value}("");
        ownerbalance=owner.balance;
        balanceto=_to.balance;
        contractbalance = address(this).balance;
        require(sent,"failed to send");
    }
}