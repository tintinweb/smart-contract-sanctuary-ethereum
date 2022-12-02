// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract RandomTingy {
    mapping(address => bool) thingy;

    function random() external {
        uint8 randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%251);

        if (randomNumber < 80) revert();

        thingy[msg.sender] = !thingy[msg.sender];
    }
}