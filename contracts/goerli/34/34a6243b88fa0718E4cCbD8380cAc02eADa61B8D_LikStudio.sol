/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract LikStudio {

    uint256 counter = 0;
    struct Topic {
        uint256 id;
        address from;
        string title;
        string description;
        uint256 timestamp;
    }

    struct Comment {
        address user;
        string message;
        uint256 timestamp;
    }

    struct Like {
        uint256 counter;
        mapping(address => bool) userAddress;
    }

    struct Solution {
        address user;
        string anser;
        uint256 timestamp;
    }
    
    mapping(address => Topic[]) topic;
    mapping(uint256 => Comment[]) public comments;
    mapping(uint256 => Solution[]) public solutions;
    mapping(uint256 => Like) public likes;
    mapping(address => string[]) messages;
    mapping(string => string) getAddressFromMessage;

    function postTopic(string memory title, string memory description) public {
        // topic[msg.sender] = Topic(counter, msg.sender, title, description, block.timestamp);
        // getAddressFromMessage[title] = title;
        counter++;
        Topic memory newTopic = Topic(counter, msg.sender, title, description, block.timestamp);
        topic[msg.sender].push(newTopic);
        getAddressFromMessage[title] = title;
    }

    function readTopicByUser(address Address) public view returns (Topic[] memory) {
        return topic[Address];
    }

    function updateTopic(address Address, uint id, string memory title, string memory description) public {
        require(msg.sender == Address, 'only Owner');
        topic[msg.sender][id] = Topic(id, msg.sender, title, description, block.timestamp);
    }

    function deleteTopic(address Address, uint256 id) public {
        require(msg.sender == Address, 'only Owner');
        delete topic[Address][id];
    }

    function like(uint id) public {
        Like storage newLike = likes[id];
        require(newLike.userAddress[msg.sender] == false, "You already liked this video");
        newLike.counter++;
        newLike.userAddress[msg.sender] = true;
    }

    function comment(string memory message, uint id) public {
        require(bytes(message).length > 0, "Please write the comment");
        comments[id].push(Comment(msg.sender, message, block.timestamp));
    }

    function solution(string memory anser, uint id) public {
        require(bytes(anser).length > 0, "Please write the answer");
        solutions[id].push(Solution(msg.sender, anser, block.timestamp));
    }

    function searchMessage(string memory text) public view returns(string memory){
        return getAddressFromMessage[text];
    }
}