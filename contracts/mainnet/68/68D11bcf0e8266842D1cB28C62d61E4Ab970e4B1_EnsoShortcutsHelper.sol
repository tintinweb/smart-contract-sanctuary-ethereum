// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract EnsoShortcutsHelper {
    uint256 constant VERSION = 1;

    function getBalance(address balanceAddress) public view returns (uint256 balance) {
        return address(balanceAddress).balance;
    }

    function getBlockTimestamp() public view returns (uint256 timestamp) {
        return block.timestamp;
    }

    function bytesToString(bytes calldata input) public pure returns (string memory) {
        return string(abi.encodePacked(input));
    }

    function bytes32ToUint256(bytes32 input) public pure returns (uint256) {
        return uint256(input);
    }

    function bytes32ToAddress(bytes32 input) public pure returns (address) {
        return address(uint160(uint256(input)));
    }
}