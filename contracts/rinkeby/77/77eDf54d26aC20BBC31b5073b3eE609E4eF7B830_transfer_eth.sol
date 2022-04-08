/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.0;



// File: Transaction.sol

contract transfer_eth {
    address public address_sender = msg.sender;
    address payable public address_receiver;

    function rec_add(address payable reciever) public {
        address_receiver = reciever;
    }

    function send_money() public payable {
        address_receiver.transfer(address(this).balance);
    }
}