/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// language is SOLIDITY
// it's like javascript


//store a string
//retreive a string

pragma solidity ^0.8.7;

contract SimpleStorage {

    string _storedData;

    function set(string memory data) public{
        _storedData = data;
    }

    function get() public view returns (string memory){
        return _storedData;
    }
}