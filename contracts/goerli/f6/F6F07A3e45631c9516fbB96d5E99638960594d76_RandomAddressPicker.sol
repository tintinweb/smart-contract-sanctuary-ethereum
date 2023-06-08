/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomAddressPicker {
    event RandomAddressPicked(address indexed pickedAddress, address[] inputAddresses);

    function pickRandomAddress(address[] memory addresses) public {
        require(addresses.length > 0, "Array must contain at least one address");

        uint256 randomIndex = _generateRandomIndex(addresses.length);
        address pickedAddress = addresses[randomIndex];
        
        emit RandomAddressPicked(pickedAddress, addresses);
    }

    function _generateRandomIndex(uint256 length) private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        return seed % length;
    }
}