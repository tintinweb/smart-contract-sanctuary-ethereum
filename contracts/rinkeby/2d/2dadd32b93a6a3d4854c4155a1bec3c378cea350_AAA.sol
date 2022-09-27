/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract AAA {

    mapping(uint => string) doobuhouse;

    
    function push(uint piority, string memory name) public {
        doobuhouse[piority] = name;
    }


    function get(uint piority) public view returns(string memory) {
        return doobuhouse[piority];
    }

}