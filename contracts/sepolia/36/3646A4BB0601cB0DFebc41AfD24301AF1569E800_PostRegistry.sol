// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUserRegistry {
    struct User {
        uint256 level;
        bool registered;
        uint256 appreciationBalance;
        uint256 contributionBalance;
        uint256 appreciationsTaken;
        uint256 appreciationsGiven;
        uint256 takenAmt;
        uint256 givenAmt;
        bool tokenHolder;
    }

    function getUserDetails(address user) external view returns (User memory);
}

interface IHandler {
    function receiveAmount(address creator, address appreciator) external payable returns (bool); 
}

contract PostRegistry {
    address owner;

    struct Post {
        uint256 id;
        address creator;
        string content;
        uint256 timestamp;
        uint256 appreciationsCnt;
    }

    uint256 public postCount;
    mapping(uint256 => Post) public posts;

    IUserRegistry public userRegistry;
    IHandler public handler;

    event PostCreated(uint256 indexed postId, address indexed creator, string content);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Only owner can access");
        _;       
    }

    function setHandler(address _handlerAddr) external onlyOwner {
        handler = IHandler(_handlerAddr);
    }

    function setUserRegistry(address _userRegistryAddr) external onlyOwner {
        userRegistry = IUserRegistry(_userRegistryAddr);
    }

    function createPost(string memory content) public returns (uint256) {
        IUserRegistry.User memory user = userRegistry.getUserDetails(msg.sender);
        require(user.registered, "Post: register to post");
        postCount++;
        posts[postCount] = Post(postCount, msg.sender, content, block.timestamp, 0);
        emit PostCreated(postCount, msg.sender, content);

        return postCount;
    }

    function appreciate(uint256 postId) public payable returns (bool) {
        IUserRegistry.User memory user = userRegistry.getUserDetails(msg.sender);
        require(user.registered, "Appreciate: register to appreciate");
        require(msg.sender != posts[postId].creator, "Self appreciation detected");
        address creator = posts[postId].creator;
        require(creator != address(0), "Appreciate: Invalid post_id");
        require(msg.value <= user.contributionBalance, "insufficient contribution balance");
        posts[postId].appreciationsCnt++;
        bool sent = handler.receiveAmount{value: msg.value}(creator, msg.sender);
        require(sent, "Post: appreciation failed");
        return true;
    }

    function getPost(uint256 postId) public view returns (Post memory) {
        return posts[postId];
    }
}