// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TestChangeState {
    bool public contractStatus;
    address public owner;
    mapping(address => string) public userNames;
    address[] public userList;
    string[] public namesList;

    // struct UserInfo {
    //     string name;
    //     address userAddress;
    // }

    struct UserInfo {
        string userList;
        address namesList;
    }

    mapping(address => UserInfo) public users;
    


    constructor(address _owner) payable {
        contractStatus = false;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    event UserNameUpdated(address indexed userAddress, string newName);

    function changeContractStatus() public onlyOwner {
        contractStatus = !contractStatus;
    }

    function setUserName(string memory name) public {
        users[msg.sender] = UserInfo(name, msg.sender);
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
            // namesList.push(name);
        }
    }

    function getUserName(address userAddress) public view returns (string memory) {
        return userNames[userAddress];
    }

    // function getUserList() public view onlyOwner returns (address[] memory) {
    //     return userList;
    // }

    // function getUserInfo() public view onlyOwner returns (address[] memory,string[] memory) {
    //     return (userList,namesList);
    // }
    function getUserInfo() public view onlyOwner returns (UserInfo[] memory) {
        UserInfo[] memory userListWithNames = new UserInfo[](userList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            userListWithNames[i] = users[userList[i]];
        }
        return userListWithNames;
    }


    // function getUserAddressByName(string memory name) public view onlyOwner returns (address) {
    //     for (uint256 i = 0; i < userList.length; i++) {
    //         if (keccak256(bytes(userNames[userList[i]])) == keccak256(bytes(name))) {
    //             return userList[i];
    //         }
    //     }
    //     revert("User not found.");
    // }

    // function getUserInfo(address userAddress) public view onlyOwner returns (string memory, address) {
    //     return (userNames[userAddress], userAddress);
    // }
}


    // Account[] public accounts;

    // constructor(address _owner) payable {
        
    // function createAccount(address _owner) external payable {
    //     Account account = new Account{value: 111}(_owner);
    //     accounts.push(account);
    // }

// contract Account {
//     address public bank;
//     address public owner;

//     constructor (address _owner) payable {
//         bank = msg.sender;
//         owner = _owner;
//     }
// }