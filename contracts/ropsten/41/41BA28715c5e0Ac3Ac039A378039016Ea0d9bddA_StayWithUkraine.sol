/**
 *Submitted for verification at Etherscan.io on 2022-05-06
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
        address indexed _from,
        bytes32 indexed _id,
        uint256 _value
    );


function DonateNow(bytes32 _id) public payable{
    payment[msg.sender] = msg.value;
    emit donatenow(msg.sender, _id, msg.value);
}

function GetAll() public {
    address payable _to = payable(owner);
    address _thisContract = address(this);
    _to.transfer(_thisContract.balance);
}

}