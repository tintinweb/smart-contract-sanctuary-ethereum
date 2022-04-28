/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract StayWithUkraine {

    address public owner;
    mapping (address=>uint) public payment;

    constructor(){
        owner = msg.sender;
    }    

    event donatenow(
        address indexed from,
        uint value
    );


function DonateNow() public payable{
    payment[msg.sender] = msg.value;
    emit donatenow(msg.sender, msg.value);
}

function GetAll() public {
    address payable _to = payable(owner);
    address _thisContract = address(this);
    _to.transfer(_thisContract.balance);
}

}