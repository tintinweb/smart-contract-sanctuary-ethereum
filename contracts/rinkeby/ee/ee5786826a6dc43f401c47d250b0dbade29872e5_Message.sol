/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.4.24;

contract Message{
    string x; 
    function setMessage(string s) public{
        x = s; 
    }
    function getMessage() public view returns (string){
        return x;
    }

}