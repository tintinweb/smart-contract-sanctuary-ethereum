// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title The Golden Ticket
/// @author https://twitter.com/AlanRacciatti
/// @notice Mint your ticket to the EKOparty, if you are patient and lucky enough.
/// @custom:url https://www.ctfprotocol.com/tracks/eko2022/the-golden-ticket
contract GoldenTicket {
    mapping(address => uint40) public waitlist;
    mapping(address => bool) public hasTicket;

    function joinWaitlist() external {
        require(waitlist[msg.sender] == 0, "Already on waitlist");
        unchecked {
            ///@dev 10 years wait list
            waitlist[msg.sender] = uint40(block.timestamp + 10 * 365 days);
        }
    }

    function updateWaitTime(uint256 _time) external {
        require(waitlist[msg.sender] != 0, "Join waitlist first");
        unchecked {
            waitlist[msg.sender] += uint40(_time);
        }
    }

    function joinRaffle(uint256 _guess) external {
        require(waitlist[msg.sender] != 0, "Not in waitlist");
        require(waitlist[msg.sender] <= block.timestamp, "Still have to wait");
        require(!hasTicket[msg.sender], "Already have a ticket");
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        if (randomNumber == _guess) {
            hasTicket[msg.sender] = true;
        }
        delete waitlist[msg.sender];
    }

    function giftTicket(address _to) external {
        require(hasTicket[msg.sender], "Yoy dont own a ticket");
        hasTicket[msg.sender] = false;
        hasTicket[_to] = true;
    }
}