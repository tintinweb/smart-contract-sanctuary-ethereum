// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotUser();

contract ChatMessage {
    string public data = "test";
    bytes32 dataBytes = "test";

    function getResult() public pure returns (string memory) {
        return "420";
    }

    function getLength(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        return b.length;
    }

    struct MessageKind {
        string name;
        string content;
    }

    struct Message {
        address sender;
        string id;
        uint256 messageGroupId;
        string sent;
        bool isRead;
        MessageKind kind;
    }

    struct MessageGroup {
        uint256 id;
        string displayName;
        address[] groupMembers;
    }

    mapping(address => mapping(address => MessageGroup))
        public directMessageGroups;

    MessageGroup[] groups;
    mapping(address => mapping(address => uint256)) public messageGroupIndex;
    mapping(address => MessageGroup[]) public messageGroupsBySender;
    mapping(uint256 => Message[]) public messagesByGroup;

    function groupsFor() public view returns (MessageGroup[] memory) {
        return messageGroupsBySender[msg.sender];
    }

    function groupWith(address _receiver)
        public
        returns (MessageGroup memory, Message[] memory)
    {
        uint256 groupIndex = messageGroupIndex[msg.sender][_receiver];
        if (groupIndex == 0) {
            groupIndex = messageGroupIndex[_receiver][msg.sender];
        }
        if (groupIndex > 0) {
            MessageGroup memory currentGroup = groups[groupIndex];
            Message[] memory messages = messagesForGroup(currentGroup.id);
            return (currentGroup, messages);
        } else {
            // //we got here, none exist create new
            address[] memory addresses = new address[](2);
            addresses[0] = _receiver;
            addresses[1] = msg.sender;
            MessageGroup memory currentGroup = MessageGroup(
                1,
                "test",
                addresses
            );
            Message[] memory messages = new Message[](0);
            groups.push(currentGroup);
            uint256 index = groups.length;
            messageGroupIndex[msg.sender][_receiver] = index;
            messageGroupIndex[_receiver][msg.sender] = index;
            messageGroupsBySender[_receiver].push(currentGroup);
            messageGroupsBySender[msg.sender].push(currentGroup);
            return (currentGroup, messages);
        }
    }

    function addUserToGroup(address _user, uint256 _groupID) public {
        //iterate through groups and find the matching id
        MessageGroup memory targetGroup = groups[_groupID];
        // targetGroup.groupMembers.push(_user);
        // add user and save
        // messageGroupsBySender
        // messageGroupIndex
    }

    function messagesForGroup(uint256 _messageGroupID)
        public
        view
        returns (Message[] memory)
    {
        return messagesByGroup[_messageGroupID];
    }

    function sendMessage(
        address _sender,
        string memory _id,
        uint256 _messageGroupId,
        string memory _sent,
        string memory _name,
        string memory _content,
        bool _isRead
    ) public {
        MessageKind memory kind = MessageKind({name: _name, content: _content});
        Message memory message = Message(
            _sender,
            _id,
            _messageGroupId,
            _sent,
            _isRead,
            kind
        );
        messagesByGroup[_messageGroupId].push(message);
    }
}

// struct Message: Identifiable {
//     var id: String
//     var sender: Address
//     var messageGroupId: String
//     var sent: Date
//     var kind: MessageKind
//     var isRead: Bool
// }

// struct MessageGroup: Identifiable {
//     var id: String
//     var displayName: String
//     var groupMembers: [Address]
// }

// enum MessageKind {
//     case text(String)
//     case custom(Codable?)
// }

//MessageGroup
//      get all messages for group
//      send message to group
//      register user into group
//Message
//  mapping MessageGroup to array of messages
//test CRUD for each object type
// ================================================================
//open chat app
// - first, will have no conversations
//      user search does nothing, can send to any address
//      enters an address
//  -   second, user has conversations
//      user search first looks through user sharing MessageGroup
//          if no group create a new one
//  -   next
//      loads chat view
//          chat view is a MessageGroup
//              MessageGroup has users
//              need to retrieve messsages for MessageGroup
//      send message
//          save message and tag with MessageGroup
//======================================================================
//==============================Modifiers===============================
// address[] users;
// modifier onlyUsers() {
// if (!contains(users, msg.sender)) {
//     revert NotUser();
// }
//     require(contains(users, msg.sender), "sender is not a user");
//     _;
// }

//==============================Array===============================
// MessageGroup first = userGroups[0];
// uint256 count = userGroups.length;
// userGroups.push
// userGroups.pop()
// delete userGroupsp[index];

//==============================storage===============================
//variable storage:
//memory: temp data that can be modified
//calldata: temp data that cannot be modified
//storage: perminant data that can be modified
// mapping(address => MessageSender) public addressToSender;
// MessageSender[] senders;
// function addUser(string memory _id, string memory _displayName) public {
//     MessageSender memory sender = MessageSender({
//         id: _id,
//         displayName: _displayName
//     });
//     // MessageSender memory sender = MessageSender( _id, _displayName);
//     senders.push(sender);
//     // senders.push(MessageSender(_id, _displayName));

//     addressToSender[msg.address] = sender
// }