/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: No license
pragma solidity >=0.8.17;

contract CustomError {
    error MyCustomError(uint[] amounts, string message);

    function throws(uint[] calldata amounts, string calldata message) external pure {
        revert MyCustomError(amounts, message);
    }
}