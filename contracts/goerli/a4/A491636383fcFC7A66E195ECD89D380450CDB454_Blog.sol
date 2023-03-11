// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



contract Blog {

// Error messages
error BlogNotExists();
error NotBlogOwner();

    enum isPostDeleted { YES, NO }
    struct BlogStruct {
        uint256 postID;
        string title;
        string description;
        address author;
        isPostDeleted deleted;
        uint createdAt;
        uint updatedAt;
    }

    // States vars
    address private blogOwner; // For the owner who deploy the contract
    mapping (uint256 => bool) blogList;
    mapping (uint256 => address) blogOwnerOf;
    BlogStruct[] blogs;
    
    constructor() {
        blogOwner = msg.sender;
    }


    // Function to add a blog
    function createBlog(string memory title, string memory description) public  {
        require(bytes(title).length > 0, "Please enter the title");
        require(bytes(description).length > 0, "Please enter the description");
        uint256 blogID = blogs.length;
        blogList[blogID] = true;
        blogOwnerOf[blogID] = msg.sender;
        BlogStruct memory newblog = BlogStruct(blogID, title, description, msg.sender, isPostDeleted.NO, block.timestamp, block.timestamp);
        blogs.push(newblog);
    }

    // function to delete the blog
    // @dev restriction 
    //    1. IF our blog contains the blogId
    //    2. If the blog owner deleted the blog
    function deleteBlog(uint256 blogID) public {
        if (blogList[blogID] != true) revert BlogNotExists();
        if (blogOwnerOf[blogID] != msg.sender) revert NotBlogOwner();

        blogs[blogID - 1].deleted = isPostDeleted.YES;
    }


    // function to update the blog
    // @dev restriction 
    //    1. IF our blog contains the blogId
    //    2. If the blog owner updated the blog
    function updateBlog(uint256 blogID, string memory title, string memory description) public {
        if (blogList[blogID] != true) revert BlogNotExists();
        if (blogOwnerOf[blogID] != msg.sender) revert NotBlogOwner();

        require(bytes(title).length > 0, "Please enter the title");
        require(bytes(description).length > 0, "Please enter the description");
        blogs[blogID - 1].title = title;
        blogs[blogID - 1].description = description;
        blogs[blogID - 1].updatedAt = block.timestamp;
    }

    // function for the user to get all the tasks
    function getAllActiveBlogs() public view returns (BlogStruct[] memory) {
        BlogStruct[] memory _blogList = new BlogStruct[](blogs.length);
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            if (blogs[i].deleted == isPostDeleted.NO) {
                _blogList[counter] = blogs[i];
                counter++;
            }
        }
        BlogStruct[] memory newBlogList = new BlogStruct[](counter);
        for (uint i = 0; i < counter; i++) {
            newBlogList[i] = _blogList[i];
        }
        return newBlogList;
    }


    // function to get all blogs
    function getAllBlogs() public view  returns (BlogStruct[] memory ) {
        return blogs;
    }

    // function to get archive blogs
    function getAllArchiveBlogs() public view  returns (BlogStruct[] memory) {
        BlogStruct[] memory _blogList = new BlogStruct[](blogs.length);
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            if (blogs[i].deleted == isPostDeleted.YES) {
                _blogList[counter] = blogs[i];
                counter++;
            }
        }
        BlogStruct[] memory newBlogList = new BlogStruct[](counter);
        for (uint i = 0; i < counter; i++) {
            newBlogList[i] = _blogList[i];
        }
        return newBlogList;
    }

    // function to get all active blogs
    function getUserActiveBlogs() public view  returns (BlogStruct[] memory) {
        BlogStruct[] memory _blogList = new BlogStruct[](blogs.length);
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            if (blogOwnerOf[i] == msg.sender && blogs[i].deleted == isPostDeleted.NO) {
                _blogList[counter] = blogs[i];
                counter++;
            }
        }
        BlogStruct[] memory newBlogList = new BlogStruct[](counter);
        for (uint i = 0; i < counter; i++) {
            newBlogList[i] = _blogList[i];
        }
        return newBlogList;
    }
    // function to get all active blogs
    function getUserArchiveBlogs() public view  returns (BlogStruct[] memory) {
        BlogStruct[] memory _blogList = new BlogStruct[](blogs.length);
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            if (blogOwnerOf[i] == msg.sender && blogs[i].deleted == isPostDeleted.YES) {
                _blogList[counter] = blogs[i];
                counter++;
            }
        }
        BlogStruct[] memory newBlogList = new BlogStruct[](counter);
        for (uint i = 0; i < counter; i++) {
            newBlogList[i] = _blogList[i];
        }
        return newBlogList;
    }



    // function for the user to get all the tasks
    function getNumberofActiveBlogs() public view returns (uint256) {
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            if (blogs[i].deleted == isPostDeleted.NO) {
                counter++;
            }
        }
        return counter;
    }
    // function for the user to get all the tasks
    function getNumberofAllBlogs() public view returns (uint256) {
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
                counter++;
        }
        return counter;
    }
}