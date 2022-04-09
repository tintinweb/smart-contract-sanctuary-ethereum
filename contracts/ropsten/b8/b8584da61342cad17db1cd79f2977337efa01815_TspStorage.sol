/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TspStorage {

    struct Ticket {
        uint256 idNumber;
        string userName;
        string otherInfo;
        string signature;
        address holder;
    }

    // Tickets storage
    mapping(address => Ticket) ticketIdByAddress;

    function retrieveIdByAddress(address _addr) public view returns(string memory, uint256, string memory) {
        return (ticketIdByAddress[_addr].otherInfo, ticketIdByAddress[_addr].idNumber, ticketIdByAddress[_addr].signature);
    }

    function addTicket(uint256 _id, string memory _userName, string memory _otherInfo, string memory _signature, address _holder) public { 
        //Push tickets to the storage
        ticketIdByAddress[_holder] = Ticket(_id, _userName, _otherInfo, _signature, _holder);
    }

    /*
        TODO:
            Burn Tickets,
            Validate Ticket,
            Strict calling
    */
}