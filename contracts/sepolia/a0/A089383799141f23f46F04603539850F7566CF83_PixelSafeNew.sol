// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract PixelSafeNew {
    mapping(address => string[]) value;
    mapping(address => mapping(address => bool)) ownership;
    address[] users;

    // you need to upload atleast one photo to let other people give access to you

    function add(address sender, string memory url) external {
        value[sender].push(url);

        uint flag = 0;
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == sender) {
                flag = 1;
            }
        }

        if (flag == 0) {
            users.push(sender);
        }
    }

    function getUsers() public view returns (address[] memory) {
        return users;
    }

    function allow(address sender, address user) external {
        ownership[sender][user] = true;
    }

    function deny(address sender, address user) external {
        ownership[sender][user] = false;
    }

    function getAccessList(
        address sender
    ) external view returns (address[] memory) {
        uint size = 0;
        for (uint i = 0; i < users.length; i++) {
            if (ownership[sender][users[i]] == true) {
                size++;
            }
        }

        address[] memory allowedAddr = new address[](size);
        uint push = 0;

        for (uint i = 0; i < users.length; i++) {
            if (ownership[sender][users[i]] == true) {
                allowedAddr[push] = users[i];
                push++;
            }
        }

        return allowedAddr;
    }

    function display(
        address sender,
        address user
    ) external view returns (string[] memory) {
        require(
            user == sender || ownership[user][sender],
            "You dont have access"
        );
        return value[user];
    }

    function getPhotos(address sender) external view returns (string[] memory) {
        return value[sender];
    }
}