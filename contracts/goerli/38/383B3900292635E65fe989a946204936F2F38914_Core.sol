/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Core {
    address payable winner;

    function select_winner(address new_winner) external {
        winner = payable(new_winner);
    }

    function view_winner() view public returns(address winner_address) {
        return winner;
    }
}