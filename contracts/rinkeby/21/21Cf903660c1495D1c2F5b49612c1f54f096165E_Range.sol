// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Range {

    uint256 private constant BP = 1e18;
    uint16 public s_houseEdge; // Minimum winning percentage for the casino
    uint16 public constant MAX_NUMBER = 10000;
    uint16 public constant MIN_NUMBER = 0;
    
    constructor () {}

    function calculateBet(
        uint16 lowerNumber,
        uint16 upperNumber,
        uint256 betAmount
    )
        public
        view
        returns (
            uint256 winningChance,
            uint256 multiplier,
            uint256 prizeAmount
        )
    {
        require(
            lowerNumber <= MAX_NUMBER &&
                upperNumber <= MAX_NUMBER &&
                lowerNumber <= upperNumber,
            "DiceGame: Invalid range"
        );
    
        // All possibilities the amount of numbers used
        uint16 leftOver = lowerNumber == upperNumber
            ? (MAX_NUMBER + 1) - 1
            : lowerNumber + MAX_NUMBER - upperNumber;
        require(leftOver >= s_houseEdge, "DiceGame: Invalid boundaries");

        winningChance = (MAX_NUMBER + 1) - leftOver;
        multiplier = (((MAX_NUMBER + 1) - s_houseEdge) * BP) / winningChance;
        prizeAmount = (betAmount * multiplier) / BP;
    }

    function editHouseEdge(uint16 houseEdge) external {
        require(
            houseEdge >= 100 && houseEdge < MAX_NUMBER,
            "DiceGame: Invalid house edge"
        );
        s_houseEdge = houseEdge;
    }

}