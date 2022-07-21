/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: No License
pragma solidity 0.8.9;

contract SimpleStorage {
    string public message;

    function setMessage(string calldata _message) public {
        message = _message;
    }
}