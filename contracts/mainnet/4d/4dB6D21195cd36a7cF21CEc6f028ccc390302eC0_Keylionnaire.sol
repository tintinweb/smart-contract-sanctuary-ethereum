// SPDX-License-Identifier: KEYS
pragma solidity ^0.8.12;

contract Keylionnaire
{
    uint256 constant public count = 4444;
    address immutable public owner = msg.sender;

    uint256 public randomlyChosenNumber;

    event WinningNumberSeed(uint256 seed);

    function chooseWinners() public {
        require (randomlyChosenNumber == 0, "Seed has already been chosen!");
        require (msg.sender == owner, "Owner only");

        uint256 number = uint256(keccak256(abi.encodePacked(
            block.timestamp, 
            blockhash(block.number - 1), 
            block.coinbase, 
            block.gaslimit, 
            block.difficulty)));

        randomlyChosenNumber = number;

        emit WinningNumberSeed(randomlyChosenNumber);
    }

    /* 
        After chooseWinners() saves a randomly chosen number,
        it becomes a seed (chosen in a provably fair manner)

        Each "winner" is determined by combining that randomly
        chosen number by an "index", and hashing it.

        The largest winner will be index  = 0
        The next 11 winners will be index = 1, 2, 3, 4, ..., 12

        If any team members "win", they're disqualified, so we
        simply ignore them and draw an additional number.
        
        For example: If team member wins on index = 8, then
        largest winner = 0, others = 1 2 3 4 5 6 7 9 10 11 12 13

        For example: If a team member wins the largest prize, then
        largest winner = 1, others = 2 3 4 5 6 7 8 9 10 11 12 13

        For example: If a team member wins 9 10 and 11, then
        largest winner = 0, others = 1 2 3 4 5 6 7 8 12 13 14 15

        If a duplicate number is chosen, it's also disqualified
        and we treat the same way (a person can only win once)

        This returns a number between 0 and 4443
        There are 4444 potential winning mansion ids, and we sort them in
        ascending order
        The lowest potential winner number corresponds to 0
        The highest number corresponds to 4443
    */
    function winner(uint256 index) public view returns (uint16) {
        require(randomlyChosenNumber != 0, "Call chooseWinners first");

        uint256 number = uint256(keccak256(abi.encodePacked(randomlyChosenNumber, index)));

        return (uint16)(number % count);
    }
}