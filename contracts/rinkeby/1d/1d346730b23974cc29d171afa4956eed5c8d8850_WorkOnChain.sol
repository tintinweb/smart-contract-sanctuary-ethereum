/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WorkOnChain {
    mapping (address => bool) public isAdmin;
    mapping (uint256 => Member) public members;
    mapping (string => uint256) public name2ids;
    uint256 public memberCount;
    uint256 public allRecordCount;
    address public owner;
    mapping (string => bool) nameExists;

    struct Member {
        string name;
        uint256 recordCount;
        address memberAddress;
        mapping (uint256 => string) records; // time action event
    }

    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        memberCount = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
   }

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "You are not admin");
        _;
    }

    event newMember(string name, address memberAddress);
    event newAdmin(address adminAddress);
    event deleteAdmin(address adminAddress);
    event newRecord(string name, string record);

    function addAdmin(address adminAddress) public onlyOwner {
        isAdmin[adminAddress] = true;
        emit newAdmin(adminAddress);
    }

    function removeAdmin(address adminAddress) public onlyOwner {
        isAdmin[adminAddress] = false;
        emit deleteAdmin(adminAddress);
    }

    function addMember(string calldata name, address memberAddress) public onlyAdmin {
        require(!nameExists[name], "name exists");
        Member storage m = members[memberCount];
        m.name = name;
        m.memberAddress = memberAddress;
        name2ids[name] = memberCount;
        nameExists[name] = true;
        memberCount++;
        emit newMember(name, memberAddress);
    }

    function addRecordByName(string calldata name, string calldata record) public onlyAdmin {
        require(nameExists[name], "name does not exist");
        members[name2ids[name]].records[members[name2ids[name]].recordCount++] = record;
        allRecordCount++;
        emit newRecord(name, record);
    }

    function getRecordsOfMember(string calldata name) public view returns (string[] memory){
        string[] memory result = new string[](members[name2ids[name]].recordCount);
        for(uint256 i = 0; i < members[name2ids[name]].recordCount; i++){
            result[i] = members[name2ids[name]].records[i];
        }
        return result;
    }
}