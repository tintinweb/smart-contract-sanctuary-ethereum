/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.8.7;

contract SimpleStorage {

    string _storedDataOnChain;

    function set(string memory data) public {
        _storedDataOnChain = data;
    }

    function get() public view returns (string memory){
        return _storedDataOnChain;
    }
}