/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract StayWithUkraine {

    address public owner;
    string public about = '';

    mapping (address=>uint) public payment;

    constructor(){
        owner = msg.sender;
        about = 'StayWithUkraine';
    }

    event donatenow(
        address _from,
        uint256 _value,
        string _memo
    );

    function DonateNow(string memory Note) public payable{
        payment[msg.sender] = msg.value;
        emit donatenow(msg.sender, msg.value, Note);
    }

    function GetAll() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

}