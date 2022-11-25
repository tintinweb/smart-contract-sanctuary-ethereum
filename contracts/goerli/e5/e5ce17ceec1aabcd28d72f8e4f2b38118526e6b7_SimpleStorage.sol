/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SimpleStorage {

    uint256 storedValue;

    function getValue() public view returns (uint256) {
        return storedValue;
    }

    function setValue(uint256 newValue) public {
        storedValue = newValue;
    }

}