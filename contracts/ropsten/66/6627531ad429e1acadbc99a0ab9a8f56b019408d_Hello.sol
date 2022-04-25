/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Hello {

    string public name;
    
    constructor() {
        name = "I am a smart contact 2!";
    }
    
    function setName(string memory _name) public {
        name = _name;
    }
}