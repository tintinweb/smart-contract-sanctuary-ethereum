/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract StayWithUkraine {

    address public owner;
    string public memo = '';

    mapping (address=>uint) public payment;

    constructor(){
        owner = msg.sender;
        memo = 'StayWithUkraine';
    }

    event donatenow(
        address indexed from,
        uint256 value,
        string memo
    );

function DonateNow() public payable{
    payment[msg.sender] = msg.value;
    emit donatenow(msg.sender, msg.value, memo);
}

function GetAll() public {
    address payable _to = payable(owner);
    address _thisContract = address(this);
    _to.transfer(_thisContract.balance);
}

}