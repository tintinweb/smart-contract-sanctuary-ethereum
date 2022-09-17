/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

 contract JackpotThief {

uint public lastBetAmount;
address public lastPlayer;
uint public lastblockNum;
uint public constant blockDelay = 10;

function betMoney () public payable {

    require (msg.value >= lastBetAmount);
    lastBetAmount = msg.value;
    lastblockNum = block.number;
    lastPlayer = msg.sender;


}

function withdraw () public {

    require(block.number - lastblockNum >= blockDelay);
    payable (lastPlayer).transfer(address(this).balance);
    
    lastBetAmount = 0;
    lastPlayer = address(0);
    lastblockNum = 0;

}

}