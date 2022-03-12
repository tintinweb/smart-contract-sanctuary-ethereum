/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.1;

contract HelloWorld {
    mapping(address => Message) blockgameMessages;
    Message[] blockgameMessagesArray;
    address blockGamesAddress;
    uint256 blockgameMessageCount;
    address private _owner;

    event NewMessage(address _address, string message, uint256 messageIndex);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    struct Message {
        string Message;
        uint256 CreateAt;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function sendBlockGameMessage(string memory message) external {
        bytes memory messageByte = bytes(message);
        require(messageByte.length > 0, "Message cannot be empty.");
        blockgameMessagesArray.push(Message(message, block.timestamp));
        blockgameMessages[msg.sender] = Message(message, block.timestamp);
        emit NewMessage(msg.sender, message, blockgameMessageCount);
    }

    function getBlockgameMessage() public view returns (Message memory) {
        return blockgameMessages[msg.sender];
    }

    function setBlockGameAddress(address _address) external onlyOwner {
        blockGamesAddress = _address;
    }

    function readMessages() public view returns (Message[] memory) {
        require(
            msg.sender == blockGamesAddress,
            "Only blockgames can read messages."
        );
        return blockgameMessagesArray;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
}