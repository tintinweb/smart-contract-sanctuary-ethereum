// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// contract Account {
//     address public bank;
//     address public owner;

//     constructor (address _owner) payable {
//         bank = msg.sender;
//         owner = _owner;
//     }
// }

contract TestChangeState {
    bool public contractStatus;
    address public owner;
    mapping(address => string) public userNames;
    address[] public userList;
    // Account[] public accounts;

    // constructor(address _owner) payable {
    constructor(address _owner) payable {
        contractStatus = false;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    event UserNameUpdated(address indexed userAddress, string newName);

    // function createAccount(address _owner) external payable {
    //     Account account = new Account{value: 111}(_owner);
    //     accounts.push(account);
    // }


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

    function getUserList() public view onlyOwner returns (address[] memory) {
        return userList;
    }

    function getUserAddressByName(string memory name) public view onlyOwner returns (address) {
        for (uint256 i = 0; i < userList.length; i++) {
            if (keccak256(bytes(userNames[userList[i]])) == keccak256(bytes(name))) {
                return userList[i];
            }
        }
        revert("User not found.");
    }

    function getUserInfo(address userAddress) public view onlyOwner returns (string memory, address) {
        return (userNames[userAddress], userAddress);
    }
}