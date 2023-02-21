/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract DeveloperWeekDemo {
    address payable public owner;
    uint256 public unlockTime;

    event Withdrawal(uint256 amount, uint256 timestamp);
    event Registration(string name, uint256 numberOfPets, uint256 timestamp);

    struct WorkshopAttendee {
        string name;
        uint256 numberOfPets;
        bool attended;
    }

    mapping(address => WorkshopAttendee) public workshopAttendees;

    constructor() payable {
        owner = payable(msg.sender);
        unlockTime = block.timestamp + 3 minutes;
    }

    function withdrawHalf() public {
        require(
            block.timestamp >= unlockTime,
            "Unlock time is still in the future, cannot withdraw just yet"
        );
        require(msg.sender == owner, "You are not the owner of this contract");

        emit Withdrawal(address(this).balance / 2, block.timestamp);
        owner.transfer(address(this).balance / 2);
    }

    function markAttendance(string memory name, uint256 numberOfPets) public {
        workshopAttendees[msg.sender] = WorkshopAttendee(
            name,
            numberOfPets,
            true
        );
        emit Registration(name, numberOfPets, block.timestamp);
    }

    function getAttendeeName() public view returns (string memory) {
        require(
            workshopAttendees[msg.sender].attended,
            "Sender did not attend"
        );
        return workshopAttendees[msg.sender].name;
    }
}