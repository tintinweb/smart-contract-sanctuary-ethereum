/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Game {
    uint256 public totalGamesPlayerWon = 0;
    uint256 public totalGamesPlayerLost = 0;

    event BetPlaced(address player, uint256 value, bool hasWon);

    function placeBet() external payable {
        bool hasWon = _evaluateBetForPlayer();

        if (hasWon) {
            (bool success, ) = msg.sender.call{value: msg.value * 2}("");
            require(success, "Transfer failed");
            totalGamesPlayerWon++; // not required with The Graph
        } else {
            totalGamesPlayerLost++; // not required with The Graph
        }

        emit BetPlaced(msg.sender, msg.value, hasWon);
    }

    function _evaluateBetForPlayer() private view returns (bool) {
        // unsafe fake randomness
        return uint256(blockhash(block.number - 1)) % 2 == 0;
    }
}