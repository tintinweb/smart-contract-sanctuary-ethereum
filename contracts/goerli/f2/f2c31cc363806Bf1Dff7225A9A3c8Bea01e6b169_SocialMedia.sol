// SPDX-License-Identifier: UNLICENSED
// Indicates that this file does not have a license, so it is not licensed under any particular open-source license.
pragma solidity 0.8.15;

// Declares a contract called "SocialMedia".
contract SocialMedia {
    // Defines a struct called "Post" to represent a social media post.
    struct Post {
        string content; // The textual content of the post.
        string ipfsHash; // The IPFS hash of the post, which can be used to retrieve its multimedia content.
    }
    
    // Defines a nested mapping to keep track of each user's posts.
    mapping(uint32 => mapping(address => Post)) public posts;
    // Keeps track of the total number of posts made on the platform.
    uint32 public postCount;
    
    // Defines an event to be emitted every time a new post is added.
    event NewPost(uint32 postId, string content, string ipfsHash, address user);
    
    /**
     * @dev     This function is used to add a new post.
     * @param   _content  The textual content of the post.
     * @param   _ipfsHash The IPFS hash of the post, which can be used to retrieve its multimedia content.
     */
    function addPost(string memory _content, string memory _ipfsHash) public {
        // Ensures that the content of the post and its IPFS hash are not empty.
        require(bytes(_content).length > 0, "Content should not be empty");
        require(bytes(_ipfsHash).length > 0, "IPFS hash should not be empty");
        
        // Increments the total post count and adds the new post to the mapping.
        postCount++;
        posts[postCount][msg.sender] = Post(_content, _ipfsHash);
        // Emits the "NewPost" event to notify listeners of the new post.
        emit NewPost(postCount, _content, _ipfsHash, msg.sender);
    }
}