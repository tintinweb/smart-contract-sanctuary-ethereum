// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyWallet {
    address payable owner;
    uint salary;

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = payable(msg.sender);
    }

    function deposit() public payable {
        require(msg.value > 0.01 ether);
        salary += msg.value;
    }

    function withdraw() public onlyOwner{
        require(salary != 0);
        require(address(this).balance >= salary);
        owner.transfer(salary);
        salary = 0;
    }

    function checkPaymentStatus() public view returns(bool _status){
        if(address(this).balance > 0){
            return true;
        } 
    } 
}