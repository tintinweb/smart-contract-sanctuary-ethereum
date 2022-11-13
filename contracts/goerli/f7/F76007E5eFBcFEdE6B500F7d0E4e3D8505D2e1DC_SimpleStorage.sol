/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SimpleStorage {
    // State variable to store a number
    string name;

    // You need to send a transaction to write to a state variable.
    function set(string memory _name) public {
        name =_name;
    }

    // You can read from a state variable without sending a transaction.
     function get() public view returns (string memory) {
         return name;
     }
}