/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SimpleStorage {
    uint _number;

    function set(uint number) public {
        _number = number;
    }

    function get() public view returns(uint) {
        return _number;
    }
}