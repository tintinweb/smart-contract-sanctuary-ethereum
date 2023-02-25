/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract ipfsContract {

    address public owner;
    string public ipfsHash;

    constructor(){
        ipfsHash = 'Nohashyet';
        owner = msg.sender;
    }

    function changeHash(string memory newHash) public{
        require(msg.sender == owner, 'You are not the owner');
        ipfsHash = newHash;
    }
}