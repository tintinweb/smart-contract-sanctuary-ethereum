/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface Winner {
    function attempt() external;
}

contract Win {

    Winner winnerContract;
    
    constructor(address contractAddress){
        winnerContract = Winner(contractAddress);
    }
    
    function win() external {
        winnerContract.attempt();
    }
}