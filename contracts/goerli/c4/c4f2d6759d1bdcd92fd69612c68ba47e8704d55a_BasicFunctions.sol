/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract BasicFunctions {

    string coinName = "EPIC Coin";
    uint number5 = 5;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    // function (string _variable1) public view/pure returns(type) {}
    function guessNumber(uint _guess) public pure returns (bool) {
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    //returns a string
    function multiplyBy5(uint number) public view returns (uint) {
        return number * number5;
    }

}

contract Child is BasicFunctions {

    uint availableSupply;
    uint maxSupply;

    function getSuper() public view returns (uint) {
        return number5;
    }

    function getAvailableSupply() public view returns (uint) {
        return availableSupply;
    }

    constructor(uint _startingSupply, uint _maxSupply) {
        availableSupply = _startingSupply;
        maxSupply = _maxSupply;
    }

}