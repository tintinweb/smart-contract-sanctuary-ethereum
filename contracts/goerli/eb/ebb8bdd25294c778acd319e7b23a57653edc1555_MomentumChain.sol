/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// File: contracts/SimpleStorage.sol


pragma solidity ^0.8.4;

contract MomentumChain {
    struct Record {
        uint256 timestamp;
        string link;
    }
    int public recordIndex = -1;
    address public challenger;
    address[] public registeredAddresses;
    Record[] public records;
    uint256 public endDate;
    uint public threeTimesBreakCounter; 
    mapping (address => uint) public balances;

    event Register(address);
    event UploadProgress(string link);
    event Distribute(address receiver, uint amount);
    event Sent(address to, uint amount);

    constructor() {
        challenger = msg.sender;
        endDate = block.timestamp + 21 days;
    }

    function register(address watcherAddress) public {
        registeredAddresses.push(watcherAddress);
    }

    function uploadProgress(string memory link) public {
        recordIndex++; 
        records.push(Record(block.timestamp, link));
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