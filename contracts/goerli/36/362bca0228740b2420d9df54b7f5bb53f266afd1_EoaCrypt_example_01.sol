/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract EoaCrypt_example_01{

    event MessageCreated (address indexed from, address indexed to, uint indexed timestamp, string cid);
    event Registerd(address indexed user, bytes32 publicKey);
    
    mapping(address => bytes32) public publicKeys;

    function sendMessage(address[] calldata _tos, string calldata _cid) external {
        require(publicKeys[msg.sender] != 0x00 ,"Registration required");
        uint256 len = _tos.length;
        uint timestamp = block.timestamp;
        for(uint256 i; i < len;){
                emit MessageCreated(msg.sender, _tos[i], timestamp, _cid);
                unchecked{ i++; }
        }
    }

    function registerPublicKey(bytes32 _publicKey) external {
        require(publicKeys[msg.sender] == 0x00 ,"Registerd Already");
        publicKeys[msg.sender] = _publicKey;
        emit Registerd(msg.sender, _publicKey);
    } 
}