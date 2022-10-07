/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MyContract {

    mapping(uint => List) public list;
    

    struct List {
        string name;
        string addr;
    }


    function addPerson(uint _id, string memory _name, string memory _addr) public {
        list[_id] = List(_name, _addr);
    }

        
}