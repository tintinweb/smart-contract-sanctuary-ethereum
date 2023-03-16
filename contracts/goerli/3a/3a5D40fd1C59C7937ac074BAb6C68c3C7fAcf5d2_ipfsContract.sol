/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ipfsContract{
    address public owner;
    string public ipfsHash;
    constructor(){
        ipfsHash = "NoHashStoresYet";
        owner = msg.sender;
    }
    function changeHash(string memory newHash) public{
        require(msg.sender==owner,"Not owner of contract");
        ipfsHash = newHash;
    }
    function fetchHash() public view returns(string memory){
        return ipfsHash;
    }
}