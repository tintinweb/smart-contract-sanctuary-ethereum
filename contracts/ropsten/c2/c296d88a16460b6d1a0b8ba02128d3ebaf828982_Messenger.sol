/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

//SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.12;

contract Messenger {
    address private owner;
    address private sender;
    address private reciever;
    uint256 private userID = 1;
    uint256 private Members;
    address[] allUsers;

    struct message {
        address recipient;
        string _message;
    }

    mapping(address => uint256) private users;
    mapping(address => string) private usernames;
    mapping(address => bool) private isRegistered;
    mapping(bytes32 => message[]) allMessages;

    event AccountCreated(
        string indexed _username,
        uint256 indexed UserID,
        address indexed UserAddress
    );

    // constructor(){
    //     owner = msg.sender;
    // }

    function createAccount(string calldata _usernames, address newUser) public {
        require(isRegistered[newUser] != true, "User is already registered!");
        address currentUser;
        currentUser = newUser;
        users[currentUser] = userID;
        userID++;
        usernames[currentUser] = _usernames;
        isRegistered[newUser] = true;
        allUsers.push(newUser);
        emit AccountCreated(
            usernames[currentUser],
            users[currentUser],
            currentUser
        );
    }

    function sendMessage(
        address _sender,
        address _recipient,
        string calldata _msg
    ) public {
        require(isRegistered[_sender] == true, "sender is not registered!");
        require(
            isRegistered[_recipient] == true,
            "recipient is not registered!"
        );
        bytes32 chatCode = _ChatCode(_sender, _recipient);
        message memory newMsg = message(_recipient, _msg);
        allMessages[chatCode].push(newMsg);
    }

    function _ChatCode(address pubkey1, address pubkey2)
        internal
        pure
        returns (bytes32)
    {
        if (pubkey1 < pubkey2)
            return keccak256(abi.encodePacked(pubkey1, pubkey2));
        else return keccak256(abi.encodePacked(pubkey2, pubkey1));
    }

    function getChatCode(address friend, address friend2)
        public
        pure
        returns (bytes32)
    {
        return _ChatCode(friend, friend2);
    }

    function getAccountInfo(address account)
        public
        view
        returns (
            string memory,
            uint256,
            address
        )
    {
        require(isRegistered[account] == true, "Please create an account");
        return (usernames[account], users[account], account);
    }

    function readMessage(bytes32 friend_key)
        external
        view
        returns (message[] memory)
    {
        return allMessages[friend_key];
    }

    function getAllUsers() public view returns (address []memory){
        return allUsers;
    }
}