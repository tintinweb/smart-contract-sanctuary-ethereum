// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TestChangeState {
    bool public contractStatus;
    address public owner;
    mapping(address => string) public userNames;
    address[] public userList;

    constructor(address _owner) payable {
        contractStatus = false;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyOwnerOrAuthorized() {
        require(msg.sender == owner || isAuthorized(msg.sender), "Only contract owner or authorized user can call this function");
        _;
    }

    event UserNameUpdated(address indexed userAddress, string newName);

    function changeContractStatus() public onlyOwner {
        contractStatus = !contractStatus;
    }

    function setUserName(string memory name) public {
        userNames[msg.sender] = name;
        emit UserNameUpdated(msg.sender, name);

        bool isExistingUser = false;
        for (uint256 i = 0; i < userList.length; i++) {
            if (userList[i] == msg.sender) {
                isExistingUser = true;
                break;
            }
        }
        if (!isExistingUser) {
            userList.push(msg.sender);
        }
    }

    function getUserName(address userAddress) public view returns (string memory) {
        return userNames[userAddress];
    }

    function getUserList() public view onlyOwnerOrAuthorized returns (address[] memory) {
        return userList;
    }

    function getUserAddressByName(string memory name) public view onlyOwnerOrAuthorized returns (address) {
        for (uint256 i = 0; i < userList.length; i++) {
            if (keccak256(bytes(userNames[userList[i]])) == keccak256(bytes(name))) {
                return userList[i];
            }
        }
        revert("User not found.");
    }

    function getUserInfo(address userAddress) public view onlyOwnerOrAuthorized returns (string memory, address) {
        return (userNames[userAddress], userAddress);
    }

    function authorizeUser(address userAddress) public onlyOwner {
        require(!isAuthorized(userAddress), "User is already authorized");
        userList.push(userAddress);
    }

    function revokeUser(address userAddress) public onlyOwner {
        require(isAuthorized(userAddress), "User is not authorized");
        for (uint256 i = 0; i < userList.length; i++) {
            if (userList[i] == userAddress) {
                userList[i] = userList[userList.length - 1];
                userList.pop();
                break;
            }
        }
    }

    function isAuthorized(address userAddress) internal view returns (bool) {
        for (uint256 i = 0; i < userList.length; i++) {
            if (userList[i] == userAddress) {
                return true;
            }
        }
        return false;
    }
}