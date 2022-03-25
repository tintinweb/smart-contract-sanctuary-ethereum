/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity ^0.8.0;

contract example{

    function helloWorld() public returns (string memory){
        return "Hello World!";
    }

    function checkBalance() public payable returns (uint256){
        return(msg.value);
    }
}