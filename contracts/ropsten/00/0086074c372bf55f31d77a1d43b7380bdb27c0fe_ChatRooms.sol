pragma solidity >=0.4.0 <0.6.0;

contract ChatRoom {
    bytes32 public name;
    address public owner;
    address[] public members;
    uint public membersTotal;
    
    struct Message {
        uint blocknumber;
        address member;
        string encrypted_texts_ipfs;
        bytes32 decrypted_text_hash;
    }
    Message[] public messages;
    uint public messagesTotal;
    
    constructor (bytes32 _name) public {
        name = _name;
        owner = msg.sender;
        members.push(msg.sender);
        membersTotal = 1;
        messagesTotal = 0;
    }
    
    function addMember (address _addr) public {
        require(msg.sender == owner);
        members.push(_addr);
        membersTotal++;
    }
    
    function createMessage(string memory _encrypted_texts_ipfs, bytes32 _decrypted_text_hash) public {
        messages.push(Message(block.number, msg.sender, _encrypted_texts_ipfs, _decrypted_text_hash));
        messagesTotal++;
    }
}

contract ChatRooms {
    address[] public chatRooms;
    mapping (bytes32 => address) public chatRoomsNames;
    uint public chatRoomsTotal;

    constructor () public {
       chatRoomsTotal = 0;
    }
    
    function createChatRoom (bytes32 _name) public {
        address newContract = address(new ChatRoom(_name));
        chatRoomsNames[_name] = newContract;
        chatRooms.push(newContract);
        chatRoomsTotal++;
    }
}