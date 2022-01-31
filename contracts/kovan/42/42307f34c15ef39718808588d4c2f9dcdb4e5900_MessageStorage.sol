/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


/**
 * @title MessageStorage
 * @dev Post & get twitter-like statuses.
 */
contract MessageStorage {
    event MessagePosted(address author, string message);
    
    address public owner;

    mapping (address => string) private messages;

    constructor () {
        owner = msg.sender;
    }

    /**
     * @dev Post twitter-like status in behalf of the caller.
     * @param message Status message.
     */
    function postStatus(string memory message) public {
        require(bytes(message).length <= 1024);
        messages[msg.sender] = message;

        emit MessagePosted(msg.sender, message);
    }

    /**
     * @dev Get status by author's address.
     * @return message - Status message.
     */
    function getStatus(address author) public view returns (string memory message) {
        return messages[author];
    }
}