// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Weather {
    uint256 public weatherToday = 20;

    function changeTheWheather(uint256 newWeather) public {
        weatherToday = newWeather;
    }
}