/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

pragma solidity ^0.8.17;

/* 
This contract stores a data string 
and makes it available for anyone to read
*/

contract MessageStore{
    string private data;

    constructor (string memory initialData) {
        data = initialData;
    }

    function viewdata() public view returns(string memory) {
        return data;
    }
}