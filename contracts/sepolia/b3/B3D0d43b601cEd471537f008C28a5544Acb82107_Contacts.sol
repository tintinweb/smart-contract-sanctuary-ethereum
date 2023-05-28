/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


contract Contacts{
    uint public count=0;

    struct contact {
        uint id;
        string name;
        string phone;
        
    }
    mapping (uint=>contact) public contacts;
    
    constructor() {
        createContact("zac","021");
    }

    function createContact( string memory _name , string memory _phone) public{
        count++;
        contacts[count]=contact(count,_name,_phone);

    }
}