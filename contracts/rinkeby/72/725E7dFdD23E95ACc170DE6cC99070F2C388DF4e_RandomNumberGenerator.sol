// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract RandomNumberGenerator {
    constructor(
    )  public
    {
    }
    uint256[] data = [126009, 5533037, 9311954, 5319410, 9952834, 3396771, 5720753, 3437222, 2943607, 1768660, 5293500, 4718982, 9098328, 5960290, 8030194, 9164690, 8416997, 660076, 3930837, 4118553];
    uint256 index = 0;
    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(
        uint256 lotterySize
    ) 
        public 
        returns (uint256 randomness) 
    {
        index++;
        return data[index] % uint256(10) ** lotterySize;
    }
}