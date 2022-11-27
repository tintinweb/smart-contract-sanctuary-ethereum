//This code was influenced by https://learn.figment.io/tutorials/create-a-chat-application-using-solidity-and-react this blog

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error UserDoesNotExist();
error CreateAccount();

contract Chat {

    struct AppUser {
        string name;
    }

    struct Message {
        uint256 timeStamp;
        string message;
    }

    mapping (bytes32 => Message[]) private s_conversation;
    mapping (address => AppUser) private s_userList;

    event NewMessage(address indexed from, address indexed to);

    function checkUser(address walletAddress) public view returns(bool) {
        return bytes(s_userList[walletAddress].name).length > 0;
    }

    function getConversationHash(address myAddress, address friendAddress) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(myAddress, friendAddress));
    }

    function createAccount(string calldata name) external {
        require(checkUser(msg.sender) == false, "Account already exists.");
        require(bytes(name).length > 0, "Username cannot be empty.");
        s_userList[msg.sender].name = name;
    }

    function sendMessage(address walletAddress, string calldata message) external {
        if(checkUser(walletAddress) == false) {
            revert UserDoesNotExist();
        }
        if (checkUser(msg.sender) == false) {
            revert CreateAccount();
        }
        bytes32 conversationHash = getConversationHash(msg.sender, walletAddress);
        Message memory newMessage = Message(block.timestamp, message);
        s_conversation[conversationHash].push(newMessage);
        emit NewMessage(msg.sender, walletAddress);
    }

    function readConversation(address friendAddress) external view returns(Message[] memory) {
        bytes32 conversationHash = getConversationHash(msg.sender, friendAddress);
        return s_conversation[conversationHash];
    } 

    function getUserList() external view returns(AppUser memory) {
        return s_userList[msg.sender];
    }
}