// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./EpigeonInterfaces_080.sol";

//----------------------------------------------------------------------------------------------------
contract SharedPigeon{
    
    mapping (address => address[]) internal toAddressToSender;
    mapping (address => uint256) internal senderToToAddressIndex;
    mapping (address => bool) internal senderToAddressExists;
    
    event PigeonSent(address sender, address toAddress);

    uint256 private _factoryId = 0;  
    address private _owner;
    mapping (address => string) private _message;
    mapping (address => bytes32) private _message_hash;
    mapping (address => string) private _answer;
    mapping (address => uint256) private _messageTimestamp;
    mapping (address => uint256) private _answerTimestamp;
    mapping (address => address) private _toAddress;
    mapping (address => bool) private _hasFlown;
    mapping (address => bool) private _isRead;
    ILockable public lockable;
    uint256 public price;

    event AnswerSent(address sender, string _message, uint256 _messageTimestamp);  
    event MessageSent(address sender, string rmessage, address toAddress, uint256 _messageTimestamp);
    event ValueClaimed(address sender, address receiver);
    
    constructor (address coinAddress){
        _owner = msg.sender;
        lockable = ILockable(coinAddress);
        _factoryId = 0;
    }
    
    function answer(address sender) public view returns(string memory panswer){
        return _answer[sender];
    }
    
    function answerTimestamp(address sender) public view returns(uint ts){
        return _answerTimestamp[sender];
    }
    
    function changeToAddress(address sender, address newToAddress, address oldToAddress) internal {
        require(senderToAddressExists[sender] == true, "Sender has no recipient entry to change");
        
        //Delete old to address
        address senderToRemove = sender;
        uint256 senderToRemoveIndex = senderToToAddressIndex[sender];
        uint256 lastIdIndex = toAddressToSender[oldToAddress].length - 1;
        if (toAddressToSender[oldToAddress][lastIdIndex] != senderToRemove)
        {
          address lastSender = toAddressToSender[oldToAddress][lastIdIndex];
          toAddressToSender[oldToAddress][senderToToAddressIndex[senderToRemove]] = lastSender;
          senderToToAddressIndex[lastSender] = senderToRemoveIndex;
        }
        delete toAddressToSender[oldToAddress][lastIdIndex];
        toAddressToSender[oldToAddress].pop();
        
        //Push new to address
        toAddressToSender[newToAddress].push(sender);
        senderToToAddressIndex[sender] = toAddressToSender[newToAddress].length-1;
        
        emit PigeonSent(sender, newToAddress);
    }
    
    function deleteToAddress(address sender, address oldToAddress) internal {
        
        //Delete old to address 
        address senderToRemove = sender;
        uint256 senderToRemoveIndex = senderToToAddressIndex[sender];
        uint256 lastIdIndex = toAddressToSender[oldToAddress].length - 1;
        if (toAddressToSender[oldToAddress][lastIdIndex] != senderToRemove)
        {
          address lastSender = toAddressToSender[oldToAddress][lastIdIndex];
          toAddressToSender[oldToAddress][senderToToAddressIndex[senderToRemove]] = lastSender;
          senderToToAddressIndex[lastSender] = senderToRemoveIndex;
        }
        delete toAddressToSender[oldToAddress][lastIdIndex];
        toAddressToSender[oldToAddress].pop();
        
        senderToAddressExists[sender] = false;
    }

    function getValueForMessage(address sender, string memory textMessage) public {
        require(msg.sender == _toAddress[sender]);
        require(keccak256(bytes(textMessage)) == keccak256(bytes(_message[sender])));
        lockable.operatorUnlock(_toAddress[sender], _message[sender], "", "");
        delete _message_hash[sender];
        _isRead[sender] = true;
        emit ValueClaimed(sender, _toAddress[sender]);
    }
    
    function isRead(address sender) public view returns(bool read){
        return _isRead[sender];
    }
    
    function message(address sender) public view returns(string memory pmessage){
        return _message[sender];
    }
    
    function messageTimestamp(address sender) public view returns(uint ts){
        return _messageTimestamp[sender];
    }
    
    function payout() public {
        require(msg.sender == _owner, "Only owner");
        payable (_owner).transfer(address(this).balance);
    }
    
    function recallValue() public {
        require(_message_hash[msg.sender] != 0);
        lockable.operatorReclaim(msg.sender, _toAddress[msg.sender], _message[msg.sender], "", "");
        delete _message_hash[msg.sender];
    }
    
    function sendAnswer(address sender, string memory textMessage) public {
        require(msg.sender == _toAddress[sender]);
        _answer[sender] = textMessage;
        _answerTimestamp[sender] = block.timestamp;
        emit AnswerSent(msg.sender, _answer[sender], _answerTimestamp[sender]);
    }
    
    function senderToAddressByIndex(address to, uint index) public view returns (address sender){
        return toAddressToSender[to][index];
    }
    
    function senderToAddressLenght(address to) public view returns (uint256 length){
        return toAddressToSender[to].length;
    }
    
    function sendMessage(string memory textMessage, address addressee) public payable {
        require(msg.value >= price);
        //clear balances
        if (_message_hash[msg.sender] != 0){
            lockable.operatorReclaim(msg.sender, _toAddress[msg.sender], _message[msg.sender], "", "");
            delete _message_hash[msg.sender];
        }
        
        if (addressee != _toAddress[msg.sender]){
            //Need to tell for the mailboxes
            if (_hasFlown[msg.sender]){
                changeToAddress(msg.sender, addressee, _toAddress[msg.sender]);
            }
            else{
                _hasFlown[msg.sender] = true;
                setToAddress(msg.sender, addressee);
            }
            _toAddress[msg.sender] = addressee;
            delete _answer[msg.sender];
            delete _answerTimestamp[msg.sender];
        }
        
        _message[msg.sender] = textMessage;
        _messageTimestamp[msg.sender] = block.timestamp;
        _isRead[msg.sender] = false;
        payable(_owner).transfer(address(this).balance);
        
        emit MessageSent(msg.sender, _message[msg.sender], _toAddress[msg.sender], _messageTimestamp[msg.sender]);
    }
    
    function sendMessagewithLockable(string memory textMessage, address addressee, uint256 amount) public payable {
        require(msg.value >= price);
        require(amount > 0);
        require(IERC777(address(lockable)).balanceOf(msg.sender) > amount);
        
        if (addressee != _toAddress[msg.sender]){
            //Need to tell for the mailboxes
            if (_hasFlown[msg.sender]){
                changeToAddress(msg.sender, addressee, _toAddress[msg.sender]);
            }
            else{
                _hasFlown[msg.sender] = true;
                setToAddress(msg.sender, addressee);
            }
            _toAddress[msg.sender] = addressee;
            delete _answer[msg.sender];
            delete _answerTimestamp[msg.sender];
        }
        
        if (_message_hash[msg.sender] != 0){
            //clear balances
            lockable.operatorReclaim(msg.sender, _toAddress[msg.sender], _message[msg.sender], "", "");
        }
        
        //lock value
        bytes32 hash = keccak256(bytes(textMessage));
        lockable.operatorLock(msg.sender, addressee, amount, hash, "", "");
        
        _message[msg.sender] = textMessage;
        _message_hash[msg.sender] = hash;
        _messageTimestamp[msg.sender] = block.timestamp;
        _isRead[msg.sender] = false;
        payable(_owner).transfer(address(this).balance);
        
        emit MessageSent(msg.sender, _message[msg.sender], _toAddress[msg.sender], _messageTimestamp[msg.sender]);
    }
    
    function setMessageRead(address sender) public returns (string memory rmessage){
        require(_toAddress[sender] == msg.sender);       
        _isRead[sender] = true;
        rmessage = _message[sender];
    }
    
    function setPrice(uint256 amount) public {
        require(_owner == msg.sender, "Only owner");
        price = amount;
    }
    
    function setToAddress(address sender, address newToAddress) internal {
        
        //Push new to address
        require(senderToAddressExists[msg.sender] != true, "Sender already has recipient entry");
        toAddressToSender[newToAddress].push(sender);
        senderToToAddressIndex[sender] = toAddressToSender[newToAddress].length-1;
        
        senderToAddressExists[sender] = true;
        emit PigeonSent(sender, newToAddress);
    }
    
    function transferOwnership(address newOwner) public {    
        require(_owner == msg.sender, "Only _owner");
        require(newOwner != address(0), "Zero address");
        payable(newOwner).transfer(address(this).balance);
        _owner = newOwner;
    }
    
    function toAddress(address sender) public view returns(address to){
        return _toAddress[sender];
    }
    
    function viewValue(address sender) public view returns (uint256 value){
        return lockable.lockedAmount(sender, _message_hash[sender]);
    }
}
//----------------------------------------------------------------------------------------------------