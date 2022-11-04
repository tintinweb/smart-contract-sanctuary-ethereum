/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract GM {
    uint256 numberOfGm;

    function sayGM(string memory gm) public {
        require(
            keccak256(bytes(gm)) == keccak256(bytes("GM")) ||
                keccak256(bytes(gm)) == keccak256(bytes("gm")),
            "Need to say gm!"
        );

        numberOfGm++;
    }

    function getGm() public view returns (uint256) {
        return numberOfGm;
    }
}