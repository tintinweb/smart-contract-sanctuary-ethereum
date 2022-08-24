/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Hello {
    string public name;
    
    constructor() public {
        name = "I'm contract!";
    }
    
    function setName(string memory _name) public {
        name = _name;
    }
}