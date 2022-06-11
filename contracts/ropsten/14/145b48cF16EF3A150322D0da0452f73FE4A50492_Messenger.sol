/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-28
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
        address reciever;
        string _message;
    }

    struct friends {
        address friend;
    }

    mapping(address => uint256) private users;
    mapping(address => string) private usernames;
    mapping(address => bool) private isRegistered;
    mapping(bytes32 => message[]) allMessages;
    mapping(address => friends[]) allFriends;
    mapping(address => address) activeChats;

    event AccountCreated(
        string indexed _username,
        uint256 indexed UserID,
        address indexed UserAddress
    );

    // constructor(){
    //     owner = msg.sender;
    // }

    function createAccount(string memory _usernames, address newUser) public {
        require(isRegistered[newUser] != true, "User is already registered!");
        users[newUser] = userID;
        userID++;
        usernames[newUser] = _usernames;
        isRegistered[newUser] = true;
        allUsers.push(newUser);
        emit AccountCreated(
            usernames[newUser],
            users[newUser],
            newUser
        );
    }

    function addFriend(address _receiver, address _sender) public {
        require(isRegistered[_receiver]);
        require(isRegistered[_sender]);
        friends memory newFriend = friends(_receiver);
        allFriends[_sender].push(newFriend);
    }

    function getFriends(address _sender)
        public
        view
        returns (friends[] memory)
    {
        require(isRegistered[_sender]);
        return allFriends[_sender];
    }

    function sendMessage(
        address _sender,
        address _receiver,
        string calldata _msg
    ) public {
        require(isRegistered[_sender] == true, "sender is not registered!");
        require(
            isRegistered[_receiver] == true,
            "recipient is not registered!"
        );
        bytes32 chatCode = _ChatCode(_sender, _receiver);
        message memory newMsg = message(_receiver, _msg);
        allMessages[chatCode].push(newMsg);
    }

    function setChatActive (address _sender, address _receiver) public {
        require(isRegistered[_receiver]);
        require(isRegistered[_sender]);
        activeChats[_sender] = _receiver;
    
    }
    
    function delChatActive (address _sender) public {
        delete activeChats[_sender];
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

    function getAllUsers() public view returns (address[] memory) {
        return allUsers;
    }

    function getActiveChat(address _sender) public view returns (address) {
        return activeChats[_sender];
    }
}