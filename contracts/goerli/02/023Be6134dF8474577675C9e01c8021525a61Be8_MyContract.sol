// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MyContract {

    uint256 recordsNum;
    address admin;

    struct record{ //IDK what is usually written in the medical records
        string name;
        string surname;
        string dob; //date of birth
        string ipfsid;
        address owner;
        address[] authUsers;
    }

    record[] records;
    address[] registry;
    address[] staffregistry;

    constructor() {
        recordsNum = 0;
        admin = msg.sender;
        staffregistry.push(admin);
    }

    //adds new staff address, admin only
    function addstaff(address staff) public {
        require(msg.sender == admin, "Access Denied");
        staffregistry.push(staff);
    }

    //removes staff address, admin only
    function removestaff(address staff) public {
        require(msg.sender == admin, "Access Denied");
        uint256 removal_id;
        for (uint256 i = 0; i < staffregistry.length-1; i++) {
            if (staffregistry[i] == staff) {
                removal_id = i;
            }
        }
        staffregistry[removal_id] = staffregistry[staffregistry.length-1];
        staffregistry.pop();
    }

    function access(address addr, address[] memory addrs) private pure returns (bool) {
        for (uint i = 0; i < addrs.length-1; i++) {
            if (addrs[i] == addr) {
                return true;
            }
        }
        return false;
    }

    //creates record, 1 record per address
    function createRecord(string calldata name, string calldata surname, string calldata dob) public returns(uint256 id) {
        require(!access(msg.sender, registry), "You Already Have a Record");
        registry.push(msg.sender);
        uint256 newrecordid = recordsNum;
        recordsNum = recordsNum + 1;
        records[newrecordid] = record(name, surname, dob, '0', msg.sender, new address[](0));
        return newrecordid;
    }

    //returns record data, onwer and trusted medical staff access only
    function veiwrecord(uint256 id) public view returns(string memory name, string memory surname, string memory ipfsid) {
        require(records[id].owner == msg.sender || access(msg.sender, records[id].authUsers), "Access Denied");
        return (records[id].name, records[id].surname, records[id].ipfsid); 
    }

    //adds address from authorized list, onwer access only
    function addauthuser(uint256 id, address user) public {
        require(msg.sender == records[id].owner, "Access Denied");
        require(access(user, staffregistry), "You Can Not Add Non-staff Addresses");
        require(!access(user, records[id].authUsers), "User Already Authorized");
        records[id].authUsers.push(user);
    }

    //removes address from authorized list, onwer access only
    function removeauthuser(uint256 id, address user) public {
        require(msg.sender == records[id].owner, "Access Denied");
        require(access(user, records[id].authUsers), "User Does Not Have Authorization");
        uint256 removal_id;
        for (uint256 i = 0; i < records[id].authUsers.length-1; i++) {
            if (records[id].authUsers[i] == user) {
                removal_id = i;
            }
        }
        records[id].authUsers[removal_id] = records[id].authUsers[records[id].authUsers.length-1];
        records[id].authUsers.pop();
    }

    //updates a link to IPFS record when the record is changed and uploaded to IPFS, trusted medical staff access only
    function addnewipfsrecord(uint256 id, string calldata ipfsid) public {
        require(msg.sender != records[id].owner, "You Are Not Allowed To Modify Your Own Record");
        require(access(msg.sender, records[id].authUsers), "Access Denied");
        records[id].ipfsid = ipfsid;
    }

    //updates record with new name and surname in case the client changed them, trusted medical staff access only
    function updaterecord(uint id, string calldata name, string calldata surname) public {
        require(msg.sender != records[id].owner, "You Are Not Allowed To Modify Your Own Record");
        require(access(msg.sender, records[id].authUsers), "Access Denied");
        records[id].name = name;
        records[id].surname = surname;
    }
}