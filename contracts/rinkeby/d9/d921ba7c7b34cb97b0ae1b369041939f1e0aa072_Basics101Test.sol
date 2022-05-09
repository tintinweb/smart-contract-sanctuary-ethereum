/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Basics101Test {

    // General Variables
    uint public myBalance = 15;
    int private txAmount = -2; // can only be called from the contract
    string internal coinName = "RMIB Coin"; // can only be called from the contract and or other contracts within it
    bool isValid = true;

    // Global Variables
    uint blockTime = block.timestamp;
    address sender = msg.sender;

    // Arrays
    string[] public tokenNames = ["Chainlink", "Ethereum", "Dodge"];
    uint[5] levels = [1, 2, 3, 4, 5];

    // Datetime
    uint timeNow1Sec = 1 seconds;
    uint timeNow1Min = 1 minutes;
    uint timeNow1Hour = 1 hours;
    uint public timeNow1Day = 1 days;
    uint timeNow1Week = 1 weeks;
    
    // Struct
    struct User {
        address userAddress;
        string name;
        bool hasTraded;
    }
     
    // Store a Struct in an array
    User[] public users;

    // Mapping
    mapping(address => string) public accountNameMap;

    // Mapping and Structs - Nested
    mapping(address => mapping(string => User)) private userNestedMap;

    // Enums
    enum coinRanking {STRONG, CAUTION, DODGY}
    coinRanking trustLevel;
    coinRanking public defaultTrustLevel = coinRanking.CAUTION;
    
}