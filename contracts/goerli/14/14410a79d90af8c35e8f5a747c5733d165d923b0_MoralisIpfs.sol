/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MoralisIpfs{

    address public owner;
    string public ipfshash;

    constructor(){
        owner = msg.sender;
        ipfshash = " No ipfs hash yet";
    }

    function changeHash(string memory _ipfshash) public  returns(string memory) {
        require(owner == msg.sender," Not the owner of the contract");
        ipfshash = _ipfshash;

        return _ipfshash;
    }
}