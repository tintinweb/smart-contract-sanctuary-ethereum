/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract PresetManager {
    uint256 public constant UPLOAD_COOLDOWN = 60 * 60;
    mapping (address => uint256) public lastUploaded;

    event Uploaded(
        address indexed target, 
        bytes4 indexed fcnSignature, 
        string fcnName, 
        string description, 
        bool isCondition    // condition or action
    );

    function upload(
        address target, 
        bytes4 fcnSignature, 
        string calldata fcnName, 
        string calldata description, 
        bool isCondition
    ) external {
        require(
            block.timestamp > lastUploaded[msg.sender] + UPLOAD_COOLDOWN,
            "Too often upload"
        );
        require(target != address(0), "Invalid target");
        require(fcnSignature != bytes4(0), "Invalid signature");
        
        emit Uploaded(
            target, 
            fcnSignature, 
            fcnName, 
            description, 
            isCondition
        );
    }
}