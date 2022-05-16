// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.3 <0.9.0;

import "./Ownable.sol";

contract Messages is Ownable {
    // Messages array
    string[] public messagesArray;

    // state variable that counts message id
    uint256 public messageId; 

    // mapping for addresses and messages
    mapping(uint256 => address) public messageIdToAddress;

    // mapping for addresses and amount of messages written
    mapping(address => uint256) public addressToAmountOfMessages;

    // event to emit to if the message is created
    event newMessage(address _sender, uint256 _messageId, string _message);
    event messageEdited(address _sender, uint256 _messageId, string _newMessage);
    event messageRemoved(address _sender, uint256 _messageId);
    event allMessagesRemoved(address _sender, uint256[] _messageIdArray);
    event donationSent(address _sender, uint256 _amount);
    event withdrawalTriggered(address _recipient, uint256 _amount);

    // write message to the blockchain
    function writeMessage(string calldata _message) public {
        // save the messageId corresponding to the message sender
        messageIdToAddress[messageId] = msg.sender;

        // save the message in the messages array
        messagesArray.push(_message);

        // increment the count of messages an address has
        addressToAmountOfMessages[msg.sender]++;

        // emit event that a new message has been saved
        emit newMessage(msg.sender, messageId, _message);

        // increment the Id of the message
        messageId++;
    }

    // view messageIds corresponding to an address
    function viewAddressMessageIds(address _address) public view returns (uint256[] memory) {
        // create an array to add the messageIds to
        uint256[] memory messageIdArray = new uint256[](addressToAmountOfMessages[_address]);

        // create a looping variable to index messageIdArray
        uint256 count = 0;

        // add the message Ids to the array
        for (uint256 i; i < messagesArray.length; i++) {

            if (_address == messageIdToAddress[i]) {
                // add messageId to array
                messageIdArray[count] = i;
                
                // add to count
                count++;
            }
        }

        // return the array
        return messageIdArray;
    }

    // view all messages corresponding to an address
    function viewAddressMessages(address _address) public view returns (string[] memory) {
        // get the array of messageIds corresponding to an address
        uint256[] memory messageIdArray = viewAddressMessageIds(_address);

        // create an empty array which will contain _address' messages
        string[] memory userMessagesArray = new string[](messageIdArray.length);

        // add the message Ids to the array
        for (uint256 i; i < messageIdArray.length; i++) {
            // add message to userMessagesArray
            userMessagesArray[i] = messagesArray[messageIdArray[i]];
        }

        // return messages
        return userMessagesArray;
    }

    // view all messages 
    function viewAllMessages() public view returns (string[] memory) {
        return messagesArray;
    }

    // view all authors
    function viewAllAuthors() public view returns (address[] memory) {
        // all addresses
        address[] memory messageAuthors = new address[](messagesArray.length);

        // add authors to messageAuthors
        for (uint i; i < messagesArray.length; i++) {
            // add author after checking who wrote the message
            messageAuthors[i] = messageIdToAddress[i];
        }

        // return all addresses
        return messageAuthors;
    }

    // modify individual message by msg.sender
    function modifyIndividualMessage(uint256 _messageId, string calldata _newMessage) external {
        // check that msg.sender is the person that actually wrote the message
        require(messageIdToAddress[_messageId] == msg.sender);

        // emit event that a message was edited
        emit messageEdited(msg.sender, _messageId, _newMessage);

        // remove the message content
        messagesArray[_messageId] = _newMessage;
    }


    // remove individual message by msg.sender
    function removeIndividualMessage(uint256 _messageId) external {
        // check that msg.sender is the person that actually wrote the message
        require(messageIdToAddress[_messageId] == msg.sender);

        // emit event that a message was removed
        emit messageRemoved(msg.sender, _messageId);

        // remove the message content
        messagesArray[_messageId] = "";
    }

    // remove all of the messages sent by a specific user
    function removeAllMessages() external {
        // get all messages by msg.sender
        uint256[] memory userMessagesToDelete = viewAddressMessageIds(msg.sender);

        // emit event that all messages from msg.sender were removed
        emit allMessagesRemoved(msg.sender, userMessagesToDelete);

        // remove all messages by said user iterating over them
        for (uint i; i < userMessagesToDelete.length; i++) {
            messagesArray[userMessagesToDelete[i]] = "";
        }
    }

    // DONATE function
    function donate() external payable {
        // emit event that donation was sent
        emit donationSent(msg.sender, msg.value);
    }

    // ADMIN/OWNER ONLY FUNCTIONS
    // Remove individual message by Id
    function removeIndividualUserMessage(uint256 _messageId) external onlyOwner {
        messagesArray[_messageId] = "";

        // emit event that a message was removed
        emit messageRemoved(messageIdToAddress[_messageId], _messageId);
    }

    // Remove all messages of a specific address
    function removeAllMessagesOfSpecificUser(address _address) external onlyOwner {
        // obtain all messages sent by user
        uint256[] memory userMessagesToDelete = viewAddressMessageIds(_address);

        // emit event that all messages from msg.sender were removed
        emit allMessagesRemoved(_address, userMessagesToDelete);

        // remove all messages by said user iterating over them
        for (uint i; i < userMessagesToDelete.length; i++) {
            messagesArray[userMessagesToDelete[i]] = "";
        }
    }

    // Withdraw donations
    function withdrawDonations(address payable _to) external onlyOwner {
        // current contract balance
        uint256 contractBalance = address(this).balance;
        
        // transfer money to address _to
        _to.transfer(contractBalance);

        // emit event that the money was transferred to _to
        emit withdrawalTriggered(_to, contractBalance);
    }
}