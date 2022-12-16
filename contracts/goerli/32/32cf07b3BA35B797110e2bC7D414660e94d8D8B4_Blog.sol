pragma solidity ^0.8.17;

contract Blog{
    address[1000] public blogs;

    function purchaseBlog(uint256 _blogId) public returns (uint256) {
        require(_blogId >= 0 && _blogId <= 1000, "_blogId must be equals between 0 ~ 1000");

        blogs[_blogId] = msg.sender;

        return _blogId;
    }

    function getBlogs() public view returns (address[1000] memory) {
        return blogs;
    }

}