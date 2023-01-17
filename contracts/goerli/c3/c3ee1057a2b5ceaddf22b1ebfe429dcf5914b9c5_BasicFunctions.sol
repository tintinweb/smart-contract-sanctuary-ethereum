/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract BasicFunctions {

    //sETTING THINGS UP
    string coinName = "EPIC Coin";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;     // :"internal" means only accessible by this contract or contracts within it

    // function [NAME](string memory _var1, int _var2) public view/pure returns([TYPE]) {}
        // "memory" used with string type or objects, basically for dynamic memory allocation
        // convention dictates underscores for local variables
        // public/private
        // view/pure; "pure" means everything in the function is done inside only and doesn't interact with anything outside the function; "view" means it does interact with something outside in some way
        // "returns ([TYPE])" states what type of value is expected to be returned (ex bool, uint, etc.)

    function guessNumber(uint _guess) public pure returns (bool) {      // "public" means when viewing on Etherscan the function is interactive
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    // return a string
    function getMyCoinName() public view returns(string memory) {   // "view" because it's interacting with global variable coinName; 
        return coinName;
    }

    // something that can only be called externally
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // function that uses a for loop and multiplies params and string comparison
    function findCoinIndex(string [] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {  // "keccak256(abi.encodePacked([VARIABLE]))" must be used when comparing strings
                return i;
            }
        }
        return 9999;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // function to get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }


}