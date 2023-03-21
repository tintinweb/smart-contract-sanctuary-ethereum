// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BlogApp {
    //  Errors Messages
    error BlogTitleNotExist();
    error BlogDescriptionNotExist();
    error BlogNotExist();
    error NotBlogOwner();

    enum isBlogDeleted {
        NO,
        YES
    }

    struct BlogStruct {
        uint256 blogID;
        string title;
        string description;
        address blogOwner;
        isBlogDeleted isDeleted;
        uint createdOn;
        uint updatedOn;
    }

    // State Vars
    address private contractOwner;
    mapping(uint256 => bool) blogExistingList;
    mapping(uint256 => address) blogList;
    BlogStruct[] blogs;

    constructor() {
        contractOwner = msg.sender;
    }

    // function to create the blog
    function createBlog(
        string memory title,
        string memory description
    ) public returns (bool) {
        if (bytes(title).length <= 0) revert BlogTitleNotExist();
        if (bytes(description).length <= 0) revert BlogDescriptionNotExist();
        uint256 blogID = blogs.length;

        // Create the blog structure
        BlogStruct memory newBlog = BlogStruct(
            blogID,
            title,
            description,
            msg.sender,
            isBlogDeleted.NO,
            block.timestamp,
            block.timestamp
        );
        // push in blogs array
        blogs.push(newBlog);

        // now add the blogId in blogExisting mapping
        blogExistingList[blogID - 1] = true;

        // now add the blogId in blogList mapping
        blogList[blogID - 1] = msg.sender;
        return true;
    }

    // function to update the blog
    function updateBlog(
        uint256 blogID,
        string memory title,
        string memory description
    ) public returns (bool) {
        if (blogExistingList[blogID] != true) revert BlogNotExist();
        if (blogList[blogID] != msg.sender) revert NotBlogOwner();
        if (bytes(title).length <= 0) revert BlogTitleNotExist();
        if (bytes(description).length <= 0) revert BlogDescriptionNotExist();

        blogs[blogID].title = title;
        blogs[blogID].description = description;
        blogs[blogID].updatedOn = block.timestamp;
        return true;
    }

    // function to delete the blog
    function deleteBlog(uint256 blogID) public returns (bool) {
        if (blogExistingList[blogID] != true) revert BlogNotExist();
        if (blogList[blogID] != msg.sender) revert NotBlogOwner();
        blogs[blogID].isDeleted = isBlogDeleted.YES;
        return true;
    }

    // function to get all active blogs
    function getAllActiveBlog() public view returns (BlogStruct[] memory) {
        BlogStruct[] memory _blogList = new BlogStruct[](blogs.length);
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            if (blogs[i].isDeleted == isBlogDeleted.NO) {
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

    // function to get number of  active blogs
    function getNumberOfActiveBlog() public view returns (uint256) {
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            if (blogs[i].isDeleted == isBlogDeleted.NO) {
                counter++;
            }
        }
        return counter;
    }


    // function to get all blogs
    function getAllBlog() public view returns (BlogStruct[] memory) {
        BlogStruct[] memory _blogList = new BlogStruct[](blogs.length);
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
            _blogList[counter] = blogs[i];
            counter++;
        }
        BlogStruct[] memory newBlogList = new BlogStruct[](counter);
        for (uint i = 0; i < counter; i++) {
            newBlogList[i] = _blogList[i];
        }
        return newBlogList;
    }

    // function to get number of blogs
    function getNumberOfBlog() public view returns (uint256) {
        uint256 counter = 0;
        for (uint i = 0; i < blogs.length; i++) {
                counter++;
        }
        return counter;
    }


    // function to get blogowner
    function getContractOwner() public view returns (address) {
        return contractOwner;
    }
}