/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Jackpot {
    address payable owner;
    uint256 public minimumBet = 100000000000000000;
    uint256 public maximumBet = 2000000000000000000;

    struct PlayRecord {
        address better;
        uint8 outcome;
        uint256 timestamp;
    }
    
    PlayRecord[] public pastPlays;
    
    constructor() {  
        owner = payable(msg.sender);
    }

    function sweepCommission(uint amount) public {  
        owner.transfer(amount);  
    }

    function bet() payable public returns (bool) {
        if(msg.value < minimumBet) {
            revert("Minimum contribution: 0.1 ETH");
        } else if(msg.value > maximumBet) {
            revert("Maximum contribution: 2 ETH");
        }

        if(spinJackpot()) {
            address payable receiver = payable(msg.sender);
            receiver.transfer(address(this).balance);
            return true;
        }

        return false;
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRandom() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / 1000) * 1000));
    }

    function spinJackpot() private returns(bool) {
        uint8 result = uint8(getRandom());

        pastPlays.push(PlayRecord({
            better: msg.sender,
            outcome: result,
            timestamp: block.timestamp
        }));

        if(result < 100) return false;
        if(result % 10 == result % 100 / 10) {
            if(result % 10 == result % 1000 / 100) return true;
        }
        return false;
    }
}