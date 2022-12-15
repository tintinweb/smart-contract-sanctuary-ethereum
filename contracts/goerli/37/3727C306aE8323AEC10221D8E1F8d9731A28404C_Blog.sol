// aaa
pragma solidity ^0.8.17;

contract Blog {
    address[1000] public blogs;

    function purchase(uint256 blogid) public returns (uint256) {

        blogs[blogid] = msg.sender;

        return blogid;
    } 
}