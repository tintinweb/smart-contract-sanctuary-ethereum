/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ipfsContract{

    address public owner;
    string public ipfsHashAnonim;
    string public ipfsHashExcluded;
    string public ipfsHashReport;

    constructor(){
        ipfsHashAnonim = "Hash Not Stored";
        ipfsHashExcluded = "Hash Not Stored";
        ipfsHashReport = "Hash Not Stored";
        owner = msg.sender;
    }

    function changeHashAnonim (string memory newHash) public{
        require(msg.sender == owner, "You are not the owner of this contract!");
        ipfsHashAnonim = newHash;
    }

    function changeHashExcluded (string memory newHash) public{
        require(msg.sender == owner, "You are not the owner of this contract!");
        ipfsHashExcluded = newHash;
    }

    function changeHashReport (string memory newHash) public{
        require(msg.sender == owner, "You are not the owner of this contract!");
        ipfsHashReport = newHash;
    }

    function fetchHashAnonim() public view returns (string memory){
        return(ipfsHashAnonim);
    }

    function fetchHashExluded() public view returns (string memory){
        return(ipfsHashExcluded);
    }
    function fetchHashReport() public view returns (string memory){
        return(ipfsHashReport);
    }

}