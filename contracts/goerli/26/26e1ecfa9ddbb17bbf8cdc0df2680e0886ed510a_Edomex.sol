/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Edomex {

    event ValueChanged(string projectName, string paramName, string oldValue, string newValue);

    function ChangeValue(string memory projectName, string memory paramName, string memory oldValue, string memory newValue) public {
        emit ValueChanged(projectName, paramName, oldValue, newValue);
    }
}