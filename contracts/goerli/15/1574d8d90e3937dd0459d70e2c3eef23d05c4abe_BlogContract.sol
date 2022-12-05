/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract BlogContract {
    struct Blog {
        uint256 id;
        string title;
        string description;
        string imageUrl;
        string tags;
        string category;
        string author;
    }
    mapping(address => mapping(uint256 => Blog)) public blogs;
    mapping(address => uint256) public blogCount;

    function addBlog(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        string memory _tags,
        string memory _category,
        string memory _author
    ) public {
        blogs[msg.sender][blogCount[msg.sender]] = Blog(
            blogCount[msg.sender],
            _title,
            _description,
            _imageUrl,
            _tags,
            _category,
            _author
        );

        blogCount[msg.sender]++;
    }

    function getAllBlogs() public view returns (Blog[] memory) {
        Blog[] memory blogsdata = new Blog[](blogCount[msg.sender]);

        for (uint256 i = 0; i < blogCount[msg.sender]; i++) {
            blogsdata[i] = blogs[msg.sender][i];
        }
        return blogsdata;
    }

    function getBlogsByid(uint256 _id) public view returns (Blog memory) {
        require(blogCount[msg.sender] > _id, "sorry data is not there");
        return blogs[msg.sender][_id];
    }

    function deleteBlogById(uint256 _id) public {
        require(blogCount[msg.sender] > _id, "sorry data is not there");
        delete blogs[msg.sender][_id];
    }

    function editBlogsById(
        uint256 _id,
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        string memory _tags,
        string memory _category,
        string memory _author
    ) public {
        require(blogCount[msg.sender] > _id, "sorry data is not there");
        Blog storage blog = blogs[msg.sender][_id];
        blog.title = _title;
        blog.description = _description;
        blog.imageUrl = _imageUrl;
        blog.tags = _tags;
        blog.author = _author;
        blog.category = _category;
    }
}