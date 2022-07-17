// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title Ledger workshop
/// @notice This contract is a chatbox, you can post/like message and fetch the last 10 messages
/**  @dev This contract is unnecessary and completely overkill. If you want to develop something similar, 
          do not use this contact as an example
 */
/// @custom:experimental Do not use this contract in production!
contract ChatRoom {
    // avoid dealing with a cold word
    uint256 public nextId = 1;
    mapping(uint256 => Message) messages;

    struct Message {
        uint256 timestamp;
        uint256 likes;
        uint256 id;
        string content;
        address author;
    }

    error EmptyMessage();
    error MessageDoesntExist();

    event MessageSent(uint256 indexed id, address indexed author);
    event MessageLiked(
        uint256 indexed id,
        address indexed likedBy,
        address indexed author
    );

    /// @notice Allow anyone to send a message
    /**  @dev Right now the signature isn't verified because there is an issue 
              with the way Ledger signs 712 compliant messages. 
              Please verify it as soon as it is possible.
    */
    /// @param content The content of the message
    /// @param signature The signature done by the author (unused right now)
    function sendMessage(string calldata content, bytes calldata signature)
        external
    {
        if (bytes(content).length == 0) revert EmptyMessage();
        uint256 currentId = nextId;

        Message memory message = Message(
            block.timestamp,
            0,
            currentId,
            content,
            msg.sender
        );

        messages[currentId] = message;

        // increse the global id by 1
        ++nextId;

        emit MessageSent(currentId, msg.sender);
    }

    /// @notice Allow anyone to like a message
    /// @param _id The id of the message
    function likeMessage(uint256 _id) external {
        Message memory message = messages[_id];

        if (message.author == address(0)) revert MessageDoesntExist();

        ++message.likes;

        // save the updated message
        messages[_id] = message;

        emit MessageLiked(message.id, msg.sender, message.author);
    }

    /// @notice Fetch the last 10 messages
    /// @return up to 10 messages
    function getLast10Messages() public view returns (Message[10] memory) {
        Message[10] memory bulkMessages;

        // Don't process when there is no message
        if (nextId == 1) return bulkMessages;

        // Calculate the number of messages that would be returned
        // * if there are less messages than the number requested, all the messages would be returned
        // * else the number of message requested will be returned
        uint256 numberOfMessages = nextId - 1 < 10 ? nextId - 1 : 10;

        for (uint256 i; i < numberOfMessages; ) {
            bulkMessages[i] = messages[nextId - 1 - i];

            unchecked {
                ++i;
            }
        }

        return bulkMessages;
    }
}