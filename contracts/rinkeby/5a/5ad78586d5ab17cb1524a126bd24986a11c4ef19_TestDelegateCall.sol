/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// File: testDelegateCall.sol

pragma solidity ^0.8.0;

contract TestDelegateCall {
    uint public number;
    address public owner;
    uint public value;
    function set(uint num) public payable {
        number = 2*num;
        owner = msg.sender;
        value = msg.value;
    }
}