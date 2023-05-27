// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract PixelSafe {
    mapping(address => string[]) value;
    mapping(address => mapping(address => bool)) ownership;
    address[] users;

    // you need to upload atleast one photo to let other people give access to you

    function add(string memory url) external {
        value[msg.sender].push(url);

        uint flag = 0;
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == msg.sender) {
                flag = 1;
            }
        }

        if (flag == 0) {
            users.push(msg.sender);
        }
    }

    function getUsers() public view returns (address[] memory) {
        return users;
    }

    function allow(address user) external {
        ownership[msg.sender][user] = true;
    }

    function deny(address user) external {
        ownership[msg.sender][user] = false;
    }

    function getAccessList() external view returns (address[] memory) {
        uint size = 0;
        for (uint i = 0; i < users.length; i++) {
            if (ownership[msg.sender][users[i]] == true) {
                size++;
            }
        }

        address[] memory allowedAddr = new address[](size);
        uint push = 0;

        for (uint i = 0; i < users.length; i++) {
            if (ownership[msg.sender][users[i]] == true) {
                allowedAddr[push] = users[i];
                push++;
            }
        }

        return allowedAddr;
    }

    function display(address user) external view returns (string[] memory) {
        require(
            user == msg.sender || ownership[user][msg.sender],
            "You dont have access"
        );
        return value[user];
    }

    function getPhotos() external view returns (string[] memory) {
        return value[msg.sender];
    }
}