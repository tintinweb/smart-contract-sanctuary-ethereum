/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract MomentumChain {
    address public challenger;
    address[] public registeredAddresses;
    uint256 public endDate;
    uint public threeTimesBreakCounter; 
    mapping (address => uint) public balances;
    mapping (uint256 => string) public records;

    event Register(address);
    event UploadProgress(string link);
    event Distribute(address receiver, uint amount);
    event Sent(address to, uint amount);

      struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

    constructor() {
        challenger = msg.sender;
        endDate = block.timestamp + 21 days;
    }

    function register(address watcherAddress) public {
        registeredAddresses.push(watcherAddress);
    }

    function uploadProgress(string memory link) public {
        records[block.timestamp] = link;
    }


    error InsufficientBalance(uint requested, uint available);


    function distribute(address receiver, uint amount) public {
        if (block.timestamp < endDate ) 
            revert("Challenge has not been ended yet.");
        
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        for (uint i = 0; i < registeredAddresses.length-1; i++) {
            balances[msg.sender] -= amount;
            balances[receiver] += amount;
            emit Sent(receiver, amount);
        }   
    } 
}