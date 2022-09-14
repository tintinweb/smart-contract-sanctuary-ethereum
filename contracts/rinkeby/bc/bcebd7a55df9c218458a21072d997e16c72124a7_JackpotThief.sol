/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract JackpotThief {
    uint public constant blocksUntilWithdrawalAllowed = 10;

    uint public costToStealJackpot;
    address public winner;
    uint public lastBlockNumber;

    // players bet money by adding it to the jackpot
    function makeBet() public payable {
        // players must match or raise previous bet
        require(msg.value >= costToStealJackpot);
        
        // update game with most recent bet
        costToStealJackpot = msg.value;
        winner = msg.sender;
        lastBlockNumber = block.number;
    }

    // the jackpot can be withdrawn a certain number of blocks after the last bet
    function withdrawJackpot() public {
        // ensure enough blocks have been mined
        require(lastBlockNumber + blocksUntilWithdrawalAllowed <= block.number);

        // transfer the jackpot to the winner
        payable(winner).transfer(address(this).balance);

        // reset the game
        costToStealJackpot = 0;
        winner = address(0);
        lastBlockNumber = 0;
    }
}