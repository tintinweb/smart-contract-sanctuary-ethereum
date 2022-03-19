/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

contract donationExample {

    address payable owner;

    constructor () {
        owner = payable(msg.sender);
    }

    event Donate (
        address from,
        uint256 amount,
        string message
    );

    function newDonation ( string memory note) public payable{
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed");
        emit Donate(
        msg.sender, 
        msg.value, 
        note);
    }
    
}