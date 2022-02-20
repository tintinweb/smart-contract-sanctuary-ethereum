/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

pragma solidity ^0.8.7;
 
contract SimpleStorage {
 
 string _storedData;
 
 function set(string memory data) public {
 _storedData = data;
 }
 
 function get() public view returns (string memory){
 return _storedData;
 }
}