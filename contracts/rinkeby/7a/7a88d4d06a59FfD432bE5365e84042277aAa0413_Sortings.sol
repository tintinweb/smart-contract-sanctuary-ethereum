// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Sortings {

    // @DIIMIIM: quick sort algorithm
    function rankPlayers(
        uint256[] memory power, 
        uint256[] memory players, 
        uint256 left, 
        uint256 right
    ) 
        public 
        pure 
    returns(
        uint256[] memory, 
        uint256[] memory
    ) {
        uint256 i = left;
        uint256 j = right;
        if (i == j) return (players,power);
        uint256 pivot = power[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (power[uint(i)] > pivot) i++;
            while (pivot > power[uint(j)]) j--;
            if (i <= j) {
                (power[uint(i)], power[uint(j)]) = (power[uint(j)], power[uint(i)]);
                (players[uint(i)], players[uint(j)]) = (players[uint(j)], players[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            rankPlayers(power, players, left, j);
        if (i < right)
            rankPlayers(power, players, i, right);
        return (players,power);
    }

}