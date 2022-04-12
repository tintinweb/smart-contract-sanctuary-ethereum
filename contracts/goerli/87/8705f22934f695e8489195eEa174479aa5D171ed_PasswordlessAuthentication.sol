// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PasswordlessAuthentication {
    mapping(address => mapping(address => uint256)) public givenAccessUntill;

    function giveAccess(address website, uint256 accessValidTime) public {
        givenAccessUntill[msg.sender][website] =
            block.timestamp +
            accessValidTime;
    }

    function checkAccess(address user, address website)
        public
        view
        returns (bool)
    {
        if (givenAccessUntill[user][website] >= block.timestamp) {
            return true;
        }
        return false;
    }

    function receiveAccess(address user) public {
        require(
            givenAccessUntill[user][msg.sender] >= block.timestamp,
            "access was not given or is expired"
        );
        givenAccessUntill[user][msg.sender] = 0;
    }
}