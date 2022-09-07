// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Lock {
    bool answerCorrect = true;
    address myaddress = 0xc229c2590B5086254438bD710d24615A6ED5AE77;
    bytes32 mytext = "mycat";
    string hello = "ciao";

    int public favoriteNumber = -10;
    uint favoriteNumber2 = 10;
    uint8 favoriteNumber3 = 10;

    function store(int number) public {
        favoriteNumber = number;
    }

    function getFavNumber() public view returns (int) {
        return favoriteNumber;
    }

    function calc() public pure returns (int) {
        return (1 + 1);
    }
}