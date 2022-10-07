/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

contract Random {
    event RandomNumberEvent(
        string title,
        uint256 number,
        address indexed requestedBy
    );

    function newRandomEvent(uint256 maxNumber, string calldata title) public {
        uint256 number = randomNumber(maxNumber);
        emit RandomNumberEvent(title, number, msg.sender);
    }

    function randomNumber(uint256 maxNumber) public view returns (uint256) {
        uint256 number = (uint256(
            keccak256(abi.encode(block.difficulty, block.timestamp, msg.sender))
        ) % maxNumber) + 1;
        return number;
    }
}