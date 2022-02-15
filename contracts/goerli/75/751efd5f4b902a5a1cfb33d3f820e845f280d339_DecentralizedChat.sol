/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DecentralizedChat {
    
    enum Status{
        UNKNOWN,
        CONNECTED, 
        JOINED, 
        AWAITING, 
        REQUESTED
    }

    struct Message { 
      string text;
      address sender;
      address receiver;
      uint256 time;
   }
  
    
    mapping(bytes => uint256) private _conversationLen;
    mapping(bytes => mapping(uint256 => Message)) private _conversation;
    mapping(bytes => Status) private _connection;
    mapping(address => mapping(address => Status)) private _contacts;
    mapping(address => uint256) private _contactsLen;
    mapping(address => mapping(uint256 => address)) private _contactsPointer;
    mapping(address => Status) private _users;
    
    function getConnection(address from, address to) public view returns(Status){
        bytes memory chatId = getChatId(from, to);
        Status connection = _connection[chatId];
        require(connection == Status.CONNECTED , "These address were not connected!");
        return connection;
    }
    
    function sendMessage(address to, string memory message) public onlyJoined() {
        Status connection = getConnection(msg.sender, to);
        require(connection == Status.CONNECTED, "These addresses were not connected!");
        bytes memory chatId = getChatId(msg.sender, to);
        uint256 position = getConversationLen(chatId);

        Message memory text = Message(message, msg.sender, to, block.timestamp);
        _conversation[chatId][position] = text;
        _conversationLen[chatId] = position + 1; 
    }
    
    function acceptConnection(address target) public onlyJoined() {
        Status targetStatus = _users[target];
        require(targetStatus == Status.JOINED, "Target not joined!");

        Status contactStatus = _contacts[target][msg.sender];
        require(contactStatus == Status.REQUESTED, "Connection is not requested by target or already connected!");
        
        _contacts[target][msg.sender] = Status.CONNECTED;
        _contacts[msg.sender][target] = Status.CONNECTED;

        _contactsPointer[msg.sender][_contactsLen[msg.sender]] = target;
        _contactsLen[msg.sender] += 1;

        _contactsPointer[target][_contactsLen[target]] = msg.sender;
        _contactsLen[target] += 1;

        bytes memory chatId = getChatId(msg.sender, target);
        _connection[chatId] = Status.CONNECTED;
    }
    
    modifier onlyJoined {
        require(_users[msg.sender] == Status.JOINED, "Sender is not joined!");
        _;
    }
    
    
    function requestConnection(address target) public onlyJoined() {
        Status contactStatus = _contacts[target][msg.sender];
        
        if (contactStatus == Status.REQUESTED){
            _contacts[target][msg.sender] = Status.CONNECTED;
            _contacts[msg.sender][target] = Status.CONNECTED;

            _contactsPointer[msg.sender][_contactsLen[msg.sender]] = target;
            _contactsLen[msg.sender] += 1;

            _contactsPointer[target][_contactsLen[target]] = msg.sender;
            _contactsLen[target] += 1;
        } else {
            _contacts[target][msg.sender] = Status.AWAITING;
            _contacts[msg.sender][target] = Status.REQUESTED;
        }
        
        bytes memory chatId = getChatId(msg.sender, target);
        _connection[chatId] = Status.CONNECTED;
    }
    
    function getChatId(address a, address b) public pure returns(bytes memory) {
        bytes memory chatId;
        if (a > b){
            chatId = abi.encodePacked(a, b);
        } else {
            chatId = abi.encodePacked(b, a);
        }
        return chatId;
    }
    
    function join() public {
        Status myStatus = _users[msg.sender];
        require(myStatus == Status.UNKNOWN, "Already Joined!");
        _users[msg.sender] = Status.JOINED;
    }
    
    function getStatus(address addr) public view returns (Status){
        Status status = _users[addr];
        return status;
    }
    
    function getMessage(bytes memory chatId, uint256 position) public view returns(Message memory message){
        Status connection = _connection[chatId];
        require(connection == Status.CONNECTED, "These addresses were not connected!");
        uint256 len = getConversationLen(chatId);
        require(position >= 0 && position < len, "Invalid position!");
        return _conversation[chatId][position];
    }
    
    function getConversationLen(bytes memory chatId) public view returns(uint256){
        Status connection = _connection[chatId];
        require(connection == Status.CONNECTED, "These addresses were not connected!");
        return _conversationLen[chatId];
    }

    function getContactsLen(address addr) public view returns (uint256){
        return _contactsLen[addr];
    } 

    function getContacts(address addr, uint256 position) public view returns (address){
        uint256 lastPosition = getContactsLen(addr);
        require(position >= 0 && position < lastPosition, "Invalid position!");
        return _contactsPointer[addr][position];
    }
}