/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomAddressPicker {
    function pickRandomAddress(address[] memory addresses) public view returns (address) {
        require(addresses.length > 0, "Array must contain at least one address");

        uint256 randomIndex = _generateRandomIndex(addresses.length);
        return addresses[randomIndex];
    }

    function _generateRandomIndex(uint256 length) private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        return seed % length;
    }
}