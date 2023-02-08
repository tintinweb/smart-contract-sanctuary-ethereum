/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract ipfsContract{

    address public owner;
    string public ipfsHash;

    constructor(){
        ipfsHash= "QmQLSakVtDU4iDnqreDP6beWPLMvHvEppTAawK3GBXu36B/modello.py";
        owner = msg.sender;
    }

    function changeHash(string memory newHash) public{
        require(msg.sender == owner, "You are not allowed to modify the hash");
        ipfsHash = newHash;
    }
    function fetchHash() public view returns (string memory){
        return ipfsHash;
    }
    
}