/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract dev5 {
    string public str = "";
    function get() public view returns (string memory) {
        return str;
    }

    function set(string memory _str) public {
        str = _str;
    }
}