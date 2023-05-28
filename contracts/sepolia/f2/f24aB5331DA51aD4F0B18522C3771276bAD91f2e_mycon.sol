/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


contract mycon{
    uint count=0;

    struct contact {
        uint id;
        string name;
        string phone;
        
    }
    mapping (uint=>contact) contacts;
    
    constructor() {
        createcontact("zac","021");
    }

    function createcontact( string memory _name , string memory _phone) public{
        count++;
        contacts[count]=contact(count,_name,_phone);
        
    }
}