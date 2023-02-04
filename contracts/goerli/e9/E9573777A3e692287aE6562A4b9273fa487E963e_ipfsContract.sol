/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ipfsContract{
    address public owner;
    string public ipfsHash;

    constructor(){
        ipfsHash = "NoHashStoredYet";
        owner = msg.sender;
    }

    function changeHash(string memory _newHash) public {
        require(msg.sender == owner, "Not Owner of Contract");
        ipfsHash = _newHash;
    }

    function fetchHash() public view returns (string memory) {
        return ipfsHash;
    }
}