pragma solidity ^0.8.17;

contract Blog {
    address[100] public blogs;

    function buy(uint256 blogId) public {
        require(blogId >= 0 && blogId < 100);

        blogs[blogId] = msg.sender;
        
    }

    
}