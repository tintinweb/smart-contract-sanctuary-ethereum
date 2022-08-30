/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;

struct FactionData {
    address owner;
    uint8 mysteriesSolvedCount;
    mapping(address => bool) members;
}

contract Core {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(uint16 => FactionData) public factions;
    uint16 private _nextFactionId = 0;
    mapping(address => uint16) public addressToFactionId;

    function createFaction(address[] calldata members) public {
        FactionData storage factionData = factions[_nextFactionId];
        factionData.owner = msg.sender;
        factionData.members[msg.sender] = true;
        factionData.mysteriesSolvedCount = 0;

        addressToFactionId[msg.sender] = _nextFactionId;

        for (uint8 i = 0; i < members.length; i++) {
            factionData.members[members[i]] = true;
            addressToFactionId[members[i]] = _nextFactionId;
        }

        _nextFactionId += 1;
    }

    function addMembers(address[] calldata members) public {
        uint16 factionId = addressToFactionId[msg.sender];

        FactionData storage factionData = factions[factionId];

        require(
            factionData.owner == msg.sender,
            "Caller's wallet doesn't have own faction"
        );

        for (uint8 i = 0; i < members.length; i++) {
            factionData.members[members[i]] = true;
            addressToFactionId[members[i]] = factionId;
        }
    }
}