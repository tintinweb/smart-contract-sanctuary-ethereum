// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

contract SocialApp {
    // Struct to store user profiles
    struct Profile {
        address userAddress;
        string name;
        uint age;
        string location;
        string imageHash;
    }

    // Struct to store posts
    struct Post {
        address userAddress;
        string text;
        string fileHash;
        uint timestamp;
    }
    // Struct to store message
    struct Message {
        address sender;
        address receiver;
        string text;
    }

    mapping(address => Profile) profiles;
    mapping(address => uint) public postCounts;
    mapping(address => Post[]) posts;
    mapping(address => Message[]) messages;
    Post[] public allPosts;

    event NewProfile(
        address userAddress,
        string name,
        uint age,
        string location,
        string imageHash
    );

    function createProfile(
        string memory _name,
        uint _age,
        string memory _location,
        string memory _imageHash
    ) public {
        // Check if the user already has a profile
        require(profiles[msg.sender].userAddress == address(0));

        // Create a new profile for the user
        profiles[msg.sender] = Profile(
            msg.sender,
            _name,
            _age,
            _location,
            _imageHash
        );

        emit NewProfile(msg.sender, _name, _age, _location, _imageHash);
    }

    function editProfile(
        string memory _name,
        uint _age,
        string memory _location,
        string memory _imageHash
    ) public {
        // Check if the user already has a profile
        require(profiles[msg.sender].userAddress != address(0));

        // Update the user's profile
        profiles[msg.sender].name = _name;
        profiles[msg.sender].age = _age;
        profiles[msg.sender].location = _location;
        profiles[msg.sender].imageHash = _imageHash;
    }

    // Function to retrieve a user's profile
    function getProfile(
        address user
    ) public view returns (string memory, string memory) {
        Profile storage profile = profiles[user];
        return (profile.name, profile.imageHash);
    }

    function createPost(string memory _text, string memory fileHash) public {
        // Check if the user already has a profile
        require(
            profiles[msg.sender].userAddress != address(0),
            "Profile does not exist"
        );

        // Create a new post
        Post memory newPost = Post(
            msg.sender,
            _text,
            fileHash,
            block.timestamp
        );
        posts[msg.sender].push(newPost);
        allPosts.push(newPost);
        postCounts[msg.sender]++;
    }

    function editPost(uint _postId, string memory _text) public {
        // Check if the user already has a profile
        require(profiles[msg.sender].userAddress != address(0));
        // Check if the post id exist
        require(_postId < postCounts[msg.sender]);
        // Update the post
        posts[msg.sender][_postId].text = _text;
    }

    function deletePost(uint _postId) public {
        // Check if the user already has a profile
        require(profiles[msg.sender].userAddress != address(0));
        // Check if the post id exist
        require(_postId < postCounts[msg.sender]);
        // Delete the post
        delete posts[msg.sender][_postId];
        postCounts[msg.sender]--;
    }

    function getUserPosts(
        address _userAddress
    ) public view returns (Post[] memory) {
        // Check if the user already has a profile
        require(profiles[_userAddress].userAddress != address(0));
        return posts[_userAddress];
    }

    function message(address _receiver, string memory _text) public {
        // Check if the user already has a profile
        require(profiles[msg.sender].userAddress != address(0));
        // Check if the receiver already has a profile
        require(profiles[_receiver].userAddress != address(0));
        // Create a new message
        Message memory newMessage = Message(msg.sender, _receiver, _text);
        messages[_receiver].push(newMessage);
    }

    function getSentMessages() public view returns (Message[] memory) {
        // Check if the user already has a profile
        require(profiles[msg.sender].userAddress != address(0));
        return messages[msg.sender];
    }

    function getReceivedMessages() public view returns (Message[] memory) {
        // Check if the user already has a profile
        require(profiles[msg.sender].userAddress != address(0));
        return messages[msg.sender];
    }

    function getAllPosts() public view returns (Post[] memory) {
        return allPosts;
    }
}