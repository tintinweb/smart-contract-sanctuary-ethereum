// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract Random {
    uint private nonce = 0;

    function getRandom() external returns(uint) {
        nonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
    }
}