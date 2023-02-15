/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

contract ipfs {
    struct Document {
        bytes32 hashing;
        uint timestamp;
        address owner;
        bool active;
    }

    struct User {
        bytes32[] documents;
        uint[] expiries;
        bool active;
    }

    constructor() {
        admin = msg.sender; 
        fee = 500000000000000;
    }

    uint private fee;
    address private admin;
    mapping(bytes32 => Document) private documents;
    mapping(address => User) private users;

    function upload(bytes32 hash) public payable {
       require(msg.value == fee,"Incorrect fee amount");
       require(!documents[hash].active,"Document already uploaded");
       documents[hash] = Document(hash,block.timestamp,msg.sender,true);
       users[msg.sender].documents.push(bytes32(hash));
       //users[msg.sender].documents.push(users[msg.sender].hash,block.timestamp,msg.sender,true);
       //users[msg.sender].expiries.push(expiry);
    }

    function downloadDocument(bytes32 hash) public view returns(bytes32) {
        require(documents[hash].active,"document does not exist");
        require(documents[hash].owner == msg.sender,"not authorize to download this document");
        return documents[hash].hashing;
    }

    function viewdocument() external view returns (bytes32[] memory)
    {
        return users[msg.sender].documents;
    }

    function viewstatus() external view returns(bool)
    {
        return users[msg.sender].active;
    }

    function change_fees(uint _fees) external {
        require(msg.sender == admin, "Not authorized");
        fee = _fees;
    }

    function checkexpiry() external payable{
        for(uint i=0; i<users[msg.sender].documents.length;i++)
        {
            if(block.timestamp>=users[msg.sender].expiries[i]) {
                users[msg.sender].active = false;
            }
        }
    }
}