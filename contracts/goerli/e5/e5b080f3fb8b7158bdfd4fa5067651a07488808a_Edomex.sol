/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Edomex {

    event ValueChanged(uint projectId, uint parameterId, string oldValue, string newValue);

    function ChangeValue(uint projectId, uint parameterId, string memory oldValue, string memory newValue) public {
        emit ValueChanged(projectId, parameterId, oldValue, newValue);
    }
}