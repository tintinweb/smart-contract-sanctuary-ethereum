// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchMint {
    function mint(address contractAddr, address receipt, uint count) external {
        bytes memory data = abi.encodePacked(hex"6a627842000000000000000000000000", abi.encodePacked(receipt));
        for (uint i = 0; i < count; i++) {
            (bool success, ) = contractAddr.call{value: 0, gas: gasleft()}(data);
            require(success, "batch mint failed");
        }
    }
}