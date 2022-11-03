// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Like {
    mapping(address => bool) public liked;
    address[] public users;

    event LikeEvent(address user, bool liked);

    function like() public {
        require(!liked[msg.sender], "only like once");

        liked[msg.sender] = true;
        add(msg.sender);

        emit LikeEvent(msg.sender, true);
    }

    function unlike() public {
        require(liked[msg.sender], "no need unlike");
        delete liked[msg.sender];
        remove(msg.sender);

        emit LikeEvent(msg.sender, false);
    }

    function count() public view returns (uint256) {
        return users.length;
    }

    function add(address addr) private {
        users.push(addr);
    }

    function remove(address addr) private
    {
        bool start = false;
        for (uint256 i = 0; i < users.length - 1; i++) {
            if (users[i] == addr) {
                start = true;
            }
            if (start) {
                users[i] = users[i + 1];
            }
        }
        users.pop();
    }
}