/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MultiCall {
    function multiCall(
        address[] calldata _addresses,
        bytes[] calldata _calls
    ) public view returns (bytes[] memory results) {
        require(_addresses.length == _calls.length, "length not the same.");

        results = new bytes[](_addresses.length);

        for (uint i = 0; i < _addresses.length; i++) {
            (bool success, bytes memory result) = _addresses[i].staticcall(_calls[i]);
            require(success, "call failed");
            results[i] = result;
        }
    }
}