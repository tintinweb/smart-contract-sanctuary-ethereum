/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

contract Bank{

    event withdrawRecord(uint);
    event transferRecord(address,uint);

    address owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender==owner,"only owner can operate");
         _;
    }

    mapping(address=>uint) userTransfer;

    receive() external payable{
        userTransfer[msg.sender]+=msg.value;
        emit transferRecord(msg.sender,msg.value);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function withdraw(uint withdrawAmount) public onlyOwner{
        require(withdrawAmount>0,"amount must above zero");
        require(address(this).balance>=withdrawAmount,"account asset is not enough");
        payable(owner).transfer(withdrawAmount);
        emit withdrawRecord(withdrawAmount);
    } 

}