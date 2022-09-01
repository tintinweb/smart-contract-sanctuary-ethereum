// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }   
	function _msgData() internal view virtual returns (bytes memory) {
		this; 
		return msg.data;
	}
}

abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract MessageEncryption is  Ownable{
	string public Name = "Message Encryption";
	struct SenderMessage {
		address		to;
		string 		message;
		uint		time;
	}
	struct RecipientMessage{
		address 	from;
		string 		message;
		uint		time;
	}
	
	address[] public  users = new address[](0);
	mapping(address => string) private publicKeys;
	
	mapping(address => SenderMessage[])  private  senderMessages;
	mapping(address => RecipientMessage[]) private recipientMessages;
	
	event EncryptMessage(address indexed senderAddress, address indexed recipientAddress, string message);
	event StoreKey(address indexed account, string indexed publicKey,  uint date);

	constructor () {
	}
	
	function storePublicKey(string memory _key) public {
		publicKeys[msg.sender] = _key;
		bool flag = true;
		uint length = users.length;
        for (uint i = 0; i < length; i++) {
            if(users[i] == msg.sender) flag = false;
        }
		if(flag) users.push(msg.sender);
		emit StoreKey(msg.sender, _key, block.timestamp);
	}
	
	function getPublicKey(address _user) public view returns (string memory){
		return publicKeys[_user];
	}

	function getUsers() public view returns (address[] memory){
		return users;
	}

	function sendMessage(address target, string memory message) public {
		require(target != msg.sender, "Encryption: recipient same as sender");
		uint time = block.timestamp;
		//sender message
		SenderMessage[] storage _senderMsgs =  senderMessages[msg.sender];
		RecipientMessage[] storage _recipientMsgs =  recipientMessages[msg.sender];
		
		SenderMessage memory newSenderMessage = SenderMessage({
			to:			target,
			message:	message,
			time:		time
		});
		_senderMsgs.push(newSenderMessage);
		senderMessages[msg.sender] = _senderMsgs;

		// //recipient message
		RecipientMessage memory newRecipientMessage = RecipientMessage({
			from:		msg.sender,
			message:	message,
			time:		time
		});
		_recipientMsgs.push(newRecipientMessage);
		recipientMessages[target] = _recipientMsgs;
		emit EncryptMessage(msg.sender, target, message);
	}
	
	function getSentMessages(address sender) public view returns (SenderMessage[] memory ){
		return senderMessages[sender];
	}

	function getReceiveMessages(address recipient) public view returns (RecipientMessage[] memory){
		return recipientMessages[recipient];
	}
	
	receive() external payable {}
}