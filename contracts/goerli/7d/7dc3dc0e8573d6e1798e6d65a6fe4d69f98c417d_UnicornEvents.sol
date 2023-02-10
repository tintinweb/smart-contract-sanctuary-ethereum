// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract UnicornEvents {

    event Tweet(address from, string tweet);
    event UnicornSent(address from, address to, uint price);

    function tweet(string memory _tweet) public {
        emit Tweet(msg.sender, _tweet);
    }

    function sendUnicorn(address _to, uint _price) public {
        emit UnicornSent(msg.sender, _to, _price);
    }

}