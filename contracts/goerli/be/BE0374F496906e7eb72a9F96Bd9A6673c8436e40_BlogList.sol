// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract BlogList {

    //unique identifier for all the blogs
    uint blogid = 1;

    //blog stucture
    struct Blogs{
        uint blogid;
        string topic;
        string description;
        string image;
    }

    
    //event to keep track of created and updated events 
    event Blog(uint id,  string topic, string description, string image, address user);
    //event to keep track of deleted event 
    event DelBlog(uint id);
    
    //mapping each blogid with a blog owner within the contract
    mapping (uint => address) public BlogToOwner;
    //mapping unique blogid with it's blog
    mapping (uint => Blogs) public blogIDToBlog;


    //Adding new blog to the contract 
    function addBlog(string memory _topic, string memory _description, string memory _image) external{
        Blogs memory blog = Blogs(blogid,_topic, _description, _image);
        BlogToOwner[blogid] = msg.sender;
        blogIDToBlog[blogid] = blog;
        emit Blog(blogid, _topic, _description, _image, msg.sender);
        blogid++;
    }
    
    //deleting blogs already exist by it's owner
    function removeBlog(uint256 id) external {
        uint index = blogIDToBlog[id].blogid;
        require(blogIDToBlog[id].blogid > 0, "Invalid Index");
        require(BlogToOwner[id] == msg.sender, "Invalid Blog Owner");
        delete blogIDToBlog[id];
        delete BlogToOwner[id];
        emit DelBlog(index);
    }

    //update blogs already exist by it's owner
    function changeBlog(uint256 id, string memory _topic, string memory _description, string memory _image) external {
        require(blogIDToBlog[id].blogid > 0, "Invalid Index");
        require(BlogToOwner[id] == msg.sender, "Invalid Blog Owner");
        blogIDToBlog[id] = Blogs(id, _topic, _description, _image);
        emit Blog(id, _topic, _description, _image, msg.sender);
    }

}