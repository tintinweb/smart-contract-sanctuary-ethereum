pragma solidity ^0.8.0;

contract TestPost {
    string[] public post;
    address public owner;
    uint public lastPost = 0;

    constructor() {
        owner = msg.sender;
    }

    function addPost(string memory _post) public {
        post.push(_post);
        lastPost++;
    }
}