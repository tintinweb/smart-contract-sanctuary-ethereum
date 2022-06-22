/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// File: contracts/DataTypes2.sol


pragma solidity ^0.8.7;

contract MyContract {
    // State and Local Variable

    // String Variables
    string public myString = "Hello World";

    bytes32 public myBytes32 = "Hello World";

    // Addresses
    address public myAddress = 0x1E14EDAEcD90FA055178dD0008465D4E83F5afd2;

    // State (working with numbers)
    uint public myUint = 1; // you can access anywhere
    int public myInt = 1;
    uint256 public myUint256 = 1;
    uint8 public myUint8 = 1;

    // Building custom DataStructures - model any arbitrary data
    struct MyVote {
        uint id;
        string ballot;
    }

    MyVote public myVote = MyVote(1, "John Doe");

    // Local (can only access inside of this function)
    function getValue() public pure returns(uint) {
        uint value = 1;
        return value;
    }
}