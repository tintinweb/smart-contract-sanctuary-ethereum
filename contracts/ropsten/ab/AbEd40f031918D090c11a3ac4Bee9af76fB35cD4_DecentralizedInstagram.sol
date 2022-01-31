/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity ^0.8.10;

contract DecentralizedInstagram{
    Post[] public posts;
    uint nextPostId = 0;

    struct Post{
        uint id;
        string ipfsHash;
        string text;
        address user;

    }
    event PostCreated(
        uint id,
        string ipfsHash,
        string text,
        address user
    );

    function createPost(string memory ipfsHash, string memory text) public{
        address user = msg.sender;
        Post memory newPost = Post(nextPostId, ipfsHash,text,user);
        posts.push(newPost);
        nextPostId += 1;
        emit PostCreated(nextPostId -1,  ipfsHash, text, user);
    }
    function getPosts() public view returns(Post[] memory){
        return posts;
    }
}