/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// File: Rolluper.sol

//SPDX-License-Identifier: MIT"

pragma solidity ^0.8.7;

error Insufficient_Account_Balance();

contract Rolluper { 
    // L1Addr, L2Addr, amount
    event newUserEnrolled(address, uint256, uint256);

    // Default accounts (Optimizable)
    uint256 public constant MINT_ACC = 0;
    uint256 public constant BURN_ACC = 1;
    uint256 public constant AUCTION_ACC = 2;

    // stateRoot
    uint256 public stateRoot;

    // A value for assign L2Addr for new user
    uint256 public idCounter = 3;

    // Addresses mapping table (L2 <--> L1)
    mapping(uint256 => address) public L2ToL1Addr;
    mapping(address => uint256) public L1ToL2Addr;

    // Tokens mapping table
    mapping(uint256 => address) private L2ToL1TokenAddr;
    mapping(address => uint256) private L1ToL2TokenAddr;

    // Transaction roots
    uint256[] public txRoot;

    // 
    struct Receipt {
        uint256 L2Addr;
        uint256 amount;
    }

    // An array to record who and how much they deposit (New user only)
    Receipt[] private regArray;

    // An array to record who and how much they deposit
    uint256[] private depArray;

    // Check Balance modifier
    modifier checkBalance() {
        if ((msg.sender).balance < msg.value) {
            revert Insufficient_Account_Balance();
        }
        _;
    }

    constructor() {}

    receive() external payable checkBalance() {
        deposit();
    }

    function deposit() internal {
        if (L1ToL2Addr[msg.sender] == 0) {
            // Update mapping table (L2 => L1)
            L2ToL1Addr[idCounter] = msg.sender;
            
            // Update mapping table (L1 => L2)
            L1ToL2Addr[msg.sender] = idCounter;
            
            // Update new user's L2Addr and amount to regArray, waiting for rollup
            regArray.push(Receipt(idCounter, msg.value));

            // Emit an event (newUserEnrolled)
            emit newUserEnrolled(msg.sender, idCounter, msg.value);
        } else {
            
        }
    }

    function checkUserBalance() public view returns (uint256) {
        return (msg.sender).balance;
    }

    function getContractAddr() public view returns (address) {
        return address(this);
    } 
    
}