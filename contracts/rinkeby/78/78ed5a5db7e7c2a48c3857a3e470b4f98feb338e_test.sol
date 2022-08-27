/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;

contract test {
    uint storedData;
    function set(uint x) public {
        storedData = x;
    }
    function get() public view returns (uint) {
        return storedData;
    }
}