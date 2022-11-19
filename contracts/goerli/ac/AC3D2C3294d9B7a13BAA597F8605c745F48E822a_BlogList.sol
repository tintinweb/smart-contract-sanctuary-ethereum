// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract BlogList {

    string private topic;
    string private description;
    string private image;


    struct Blogs{
        string topic;
        string description;
        string image;
    }

    Blogs[] private blogs;

    event NewBlog(uint id,  string topic, string description, string image);
    event DelBlog(uint id);
    mapping (uint => address) public BlogToOwner;

    function addBlog(string memory _topic, string memory _description, string memory _image) external{
        blogs.push(Blogs(_topic, _description, _image));
        uint id = blogs.length - 1;
        BlogToOwner[id] = msg.sender;
        emit NewBlog(id, _topic, _description, _image);
    }

    function removeBlog(uint256 index) external {
        require(index < blogs.length, "Invalid Index");
        require(BlogToOwner[index] == msg.sender, "Invalid Blog Owner");
        for (uint i = index; i<blogs.length-1; i++){
            blogs[i] = blogs[i+1];
        }
        blogs.pop();
        BlogToOwner[index] = 0x0000000000000000000000000000000000000000;
        emit DelBlog(index);
    }

     function changeBlog(uint256 index, string memory _topic, string memory _description, string memory _image) external {
        require(index < blogs.length, "Invalid Index");
        require(BlogToOwner[index] == msg.sender, "Invalid Blog Owner");
        blogs[index] = Blogs(_topic, _description, _image);
        emit NewBlog(index, _topic, _description, _image);
    }
}