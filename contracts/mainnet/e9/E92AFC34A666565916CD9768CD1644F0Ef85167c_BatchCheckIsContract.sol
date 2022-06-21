// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BatchCheckIsContract {
    function isContract(address[] calldata addresses) public view returns (bool[] memory) {
        bool[] memory result = new bool[](addresses.length);

        for (uint i = 0; i < addresses.length; i++) {
            result[i] = addresses[i].code.length > 0;
        }

        return result;
    }
}