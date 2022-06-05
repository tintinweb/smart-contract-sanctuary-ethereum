/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
// pragma solidity ^0.4.17;

contract Main {

    // Structure to hold details of Bidder
    struct IParticipant {
        // TODO
        address account;
        string fullname;
        string email;
        int nSessions;
        int deviation;
    }

    address public admin;

    int public nParticipants; // number of registered IParticipant
    int public nSessions;

    // TODO: Variables
    address[] public sessions;
    address[] public iParticipants;

    // Participant list maped with their address
    mapping(address => IParticipant) public participants;
    mapping(address => address[]) public joinedSessionsOf;

    constructor() {
        admin = msg.sender;
        nSessions = 0;
        nParticipants = 0;
        
        // for dev only
        nParticipants = 1;
        participants[admin].account = msg.sender;
        participants[admin].fullname = 'admin';
        participants[admin].email = '[email protected]';
        participants[admin].nSessions = 2;
        participants[admin].deviation = 3;
        iParticipants.push(msg.sender);
    }


    // Add a Session Contract address into Main Contract. Use to link Session with Main
    function addSession(address session) public {
        // TODO
        sessions.push(session);
        nSessions++;
    }

    function getAllSession() public view returns(address[] memory) {
        return sessions;
    }

    function getAllParticipants() public view returns(address[] memory) {
        return iParticipants;
    }

    // TODO: Functions

    function register(string memory fullname, string memory email) public {
        // Store participant info
        participants[msg.sender].account = msg.sender;
        participants[msg.sender].fullname = fullname;
        participants[msg.sender].email = email;
        participants[msg.sender].nSessions = 0;
        participants[msg.sender].deviation = 0;

        iParticipants.push(msg.sender);

        nParticipants++;
    }

    function setDeviation(address addr, int _newDeviation) public {
        int d; // new accumulated deviation
        int dc = participants[addr].deviation; // current deviation
        int dn = _newDeviation; // new deviation
        int n = participants[addr].nSessions; // number of session

        d = (dc * n + dn)/(n + 1);

        participants[addr].nSessions++;
        participants[addr].deviation = d;

        joinedSessionsOf[addr].push(msg.sender);
    }
}