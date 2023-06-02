/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ipfsPic{
    address public owner;
    string public ipfsHash;

    constructor(){
        ipfsHash="noHashYet";
        owner=msg.sender;



    }

    function changeHash(string memory newHash)public {
        require(msg.sender==owner,"not owner");
        ipfsHash=newHash;
    }
}