/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

// public/private/internal/external ==> types of scope
contract BasicFunctions {
    // State Variables
    string coinName = "EPIC";
    uint public myBalance = 1;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    // Function Format: function [string memory _variable, uint _variable] public view/pure returns(bool) {}
    function guessNumber(uint _guess) public pure returns (bool) { // "pure" since we don't need to interact with other state variables outisde this function
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    // Returns a string 
    // "view" since we're interacting with "coinName" struct
    function getMyCoinName() public view returns (string memory) { // Whenever there's a string inside function, it is usually followed by "memory"
        return coinName;
    }
    
    // Can only be called externally
    function multiplyBalance(uint _multiplier) external { // Only acccessible outside the smart contract 
        myBalance *= _multiplier; 
    }

    // Functions + For loops + String comparaison
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == (keccak256(abi.encodePacked(_find)))) { // Fixed Error: string memory can't be compared to string memory
                return i;
            }
        }
        return 9999; // Incase the if statement doesn't return anything
    }

    // Updating a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name,_symbol,_supply);
    }

    // Get coin from mapping
    function getCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }
}