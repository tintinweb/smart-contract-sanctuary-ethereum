/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Assignment 1
 */
contract Storage {

    string[3] strings;
    uint256 index = 0;

    function savestring(string calldata str) public {
       strings[index] = str;
       index = index+1;
       if (index==3){ index = 0;}
    }

    function getstring() public view returns(string[3] memory strings_){
        return strings;
    }

}