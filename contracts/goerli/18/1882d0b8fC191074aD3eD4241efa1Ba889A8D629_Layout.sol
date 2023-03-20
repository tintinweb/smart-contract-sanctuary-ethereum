/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Layout of a contract
contract Layout {
    // state variables
    address public admin;
    string public titleOfLayout;
    uint public price;
    bool public isActive = false;

    // events
    event priceChanged(uint previousPrice, uint currentPrice);
    event titleIsSet (address setter, uint timestamp);
 
    // function modifiers
    modifier onlyAdmin {
        require(msg.sender == admin, "Only Admin!");
        _;
    }

    // struct, arrays or enums
    enum State { PENDING, RESOLVED, REJECTED }
    struct User {
        string fullName;
        address wallet;
        uint phone;
    }
    mapping(address => uint) balance;
    
    // constructor, initialize state variables within constructor
    constructor(address _admin, uint _price) {
        admin = _admin;
        price = _price;
    }

    // receive - fallback function if exist
    // receive ether function
    receive() external payable {}
    
    // external functions
    function setTitle(string calldata title) external onlyAdmin() {
        titleOfLayout = title;
        emit titleIsSet(admin, block.timestamp);
    }

    // public functions
    function addition(uint a, uint b) public pure returns(uint) {
        return a + b;
    }

    //internal functions
    function internalMesage() internal pure returns(string memory) {
        return "Internal message";
    }

    // private functions
    function makeActive() private {
        isActive = true;
    }
}