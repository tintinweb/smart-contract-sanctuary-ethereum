// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.17;

contract Blog {
    address[1000] public blogs;

    // Purchase blog
    function purchase(uint16 blogId) public returns (uint16) {
        // require(blogId >= 0 && blogId <= 1000, "Wrong blog Id");

        blogs[blogId] = msg.sender;

        return blogId;
    }

    // Retrieving the blogs
    function getBlogs() public view returns (address[1000] memory) {
        return blogs;
    }

    // get blog
    function getBlog(uint16 blogId) public view returns (address) {
        return blogs[blogId];
    }
}