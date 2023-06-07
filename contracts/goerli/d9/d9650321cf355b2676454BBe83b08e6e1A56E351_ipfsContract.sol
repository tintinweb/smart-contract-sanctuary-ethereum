/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ipfsContract{
    address public owner;
    string public ipfsHash;


    constructor(){
        ipfsHash = "NoHashGiven";
        owner = msg.sender;
    }

    function changeHash(string memory newhash) public {
        require(msg.sender == owner, "No Access");
        ipfsHash = newhash;
    }

    function fetchHash () public  view returns (string memory) {
        return (ipfsHash);
    }
}