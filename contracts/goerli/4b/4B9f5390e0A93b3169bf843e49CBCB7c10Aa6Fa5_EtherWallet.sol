// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
contract EtherWallet{
    address payable public owner;
    event rev(address from, uint amount);
    constructor(){
        owner=payable(msg.sender);
    }
    receive() external payable{
        emit rev(msg.sender,msg.value);
    }
    function getBalance() view public returns(uint){
        return address(this).balance;
    }
    function withdraw(address payable _to,uint amount) external payable{
        require(msg.sender==owner,"!owner");
        require(amount<=address(this).balance,"not enough");
        (bool success,) = _to.call{value:amount}("");

    }
}