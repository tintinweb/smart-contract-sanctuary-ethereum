/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract demo {
    uint num;

    function set(uint _num) public {
        num = _num;
    }

    function get() public view returns(uint) {
        return num;
    }
}