// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



contract Certify {
    
     mapping (string => string) public certificateList;

    constructor()  {
     
    }

    function store(string memory _id,string memory _name) public {
        certificateList[_id] = _name;
    }

    function retrieve(string memory _id) public returns (string memory)  {
        return certificateList[_id];
    }
}