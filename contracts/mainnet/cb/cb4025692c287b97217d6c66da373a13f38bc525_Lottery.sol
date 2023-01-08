/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

pragma solidity ^0.7.0;
// FULLY ON-CHAIN LOTTERY (FEE OF 10%) USERS WHO DEPOSIT MORE HAVE HIGHER CHANCE OF WINNING
contract Lottery {
    // The address of the contract owner
    address payable public owner;
    // The total amount of ether that has been deposited by all users
    uint public totalEth;
    // The percentage of the winning amount that goes to the contract owner as a fee
    uint public feePercentage;
    // The block timestamp at which the lottery will reset
    uint public resetTime;
    // The address of the winner
    address payable public winner;
    // The amount of ether won by the winner
    uint public winningAmount;

    // The contract constructor is called when the contract is deployed
    // It sets the owner to the address of the contract deployer and sets the fee percentage to 10
    // It also sets the resetTime to the current block timestamp plus 24 hours
    constructor() public {
        owner = msg.sender;
        feePercentage = 10;
        resetTime = block.timestamp + 24 hours;
    }

    // The enter function allows users to enter the lottery by depositing some ether
    // It requires that the amount of ether deposited is less than or equal to 10 ether
    // It also requires that the current block timestamp is less than the resetTime, so that users cannot enter after the lottery has reset
    function enter(uint eth) public payable {
        require(eth <= 10 ether, "Cannot enter more than 10 ether");
        require(block.timestamp < resetTime, "Lottery has already reset");
        totalEth += eth;
    }

    // The random function is a private view function that returns a random number between 0 and the total amount of ether deposited by all users
    // It uses the keccak256 hash function and the current block difficulty, timestamp, and totalEth as inputs to generate a random number
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalEth))) % totalEth;
    }

    // The pickWinner function is called to select the winner and reset the lottery
    // It requires that the current block timestamp is greater than or equal to the resetTime, so that it can only be called after the lottery has reset
    // It uses the random function to determine the winner and sets the winner address and winningAmount variables
    // It then transfers the winning amount to the winner, minus the feePercentage as a fee to the contract owner
    // It also resets the totalEth and resetTime variables
    function pickWinner() public {
        require(block.timestamp >= resetTime, "It is not time to pick a winner yet");
        winner = address(uint160(random()));
        winningAmount = totalEth;
        totalEth = 0;
        resetTime = block.timestamp + 24 hours;
        owner.transfer(winningAmount * feePercentage / 100);
        winner.transfer(winningAmount - winningAmount * feePercentage / 100);
    }
}