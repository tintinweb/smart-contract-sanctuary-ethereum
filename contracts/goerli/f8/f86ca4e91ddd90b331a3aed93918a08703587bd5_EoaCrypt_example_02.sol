/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract EoaCrypt_example_02{

    event MessageCreated (address indexed from, address indexed to, uint indexed timestamp, string cid);
    event Registerd(address indexed user, bytes publicKey);
    

    function sendMessage(address[] calldata _tos, string calldata _cid) external {
        uint256 len = _tos.length;
        uint timestamp = block.timestamp;
        for(uint256 i; i < len;){
                emit MessageCreated(msg.sender, _tos[i], timestamp, _cid);
                unchecked{ i++; }
        }
    }

    function registerPublicKey(bytes calldata _publicKey) external {
        emit Registerd(msg.sender, _publicKey);
    } 
}