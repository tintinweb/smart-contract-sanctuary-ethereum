// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract BlogList {

    string private topic;
    string private description;
    string private image;
    address private creator;

    struct Blogs{
        string topic;
        string description;
        string image;
        address creator;
    }

    Blogs[] private blogs;

    uint public blogsCount = 0;

    event Blog(Blogs []);

    function addBlog(string memory _topic, string memory _description, string memory _image) external{
        blogs.push(Blogs(_topic, _description, _image, msg.sender));
        emit Blog(blogs);
         blogsCount +=1;
    }

    function viewBlog(uint _index) external view returns(string memory _topic, string memory _description, string memory _image, address _creator){
        Blogs storage blog = blogs[_index];
        return (blog.topic, blog.description, blog.image, blog.creator);
    }

    function viewBlogs() external view returns(Blogs[] memory){
        return (blogs);
    }

    function removeBlog(uint256 index) external {
        if (index >= blogs.length) return;

        for (uint i = index; i<blogs.length-1; i++){
            blogs[i] = blogs[i+1];
        }
        blogs.pop();
        emit Blog(blogs);
        blogsCount -=1;
    }

     function changeBlog(uint256 index, string memory _topic, string memory _description, string memory _image) external {
        if (index >= blogs.length) return;

        blogs[index] = Blogs(_topic, _description, _image, msg.sender);
        
        emit Blog(blogs);
    }
}