// SPDX-License-Identifier: MIT
pragma solidity >=0.1.2;

contract PasswordlessAuthentication {
    mapping(address => mapping(address => uint256)) public givenAccessUntill;

    function giveAccess(address application, uint256 accessValidTime) public {
        require(accessValidTime >= 1, "Shortest access time is 1 second");
        require(accessValidTime <= 3600, "Longest access time is 1 hour");
        require(application != msg.sender, "You can't give access to yourself");
        givenAccessUntill[msg.sender][application] =
            block.timestamp +
            accessValidTime;
    }

    function checkAccess(address user, address application)
        public
        view
        returns (bool)
    {
        if (givenAccessUntill[user][application] >= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function receiveAccess(address user) public {
        require(
            givenAccessUntill[user][msg.sender] >= block.timestamp,
            "access was not given or is expired"
        );
        givenAccessUntill[user][msg.sender] = 0;
    }
}