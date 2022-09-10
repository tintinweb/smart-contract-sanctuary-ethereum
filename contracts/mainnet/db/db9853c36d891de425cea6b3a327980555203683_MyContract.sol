/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;
contract MyContract {
    string storedData;
    function set(string memory x) public {
        storedData = x;
    }
    function get() public view returns (string memory) {
        return storedData;
    }
}