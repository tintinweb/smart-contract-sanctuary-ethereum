/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7 < 0.9;

contract BasicFunctions {

    // Seting thing up
    string coinName = "EPIC Coin";

    uint public myBalance = 100;

    struct Coin  {
        string name;
        string symbol;
        int supply;
    }

    mapping (address => Coin) internal myCoins;


    
    // function (string _variabele1, int _variable2) publuc view/pure return (bool) {}
    function guessNumber(uint _guess) public pure returns  (bool) {
        if (_guess == 5) {
            return true;
        }
        else {
            return false;
        }

    }

    // return a string
    function getMyCoiName () public view returns(string memory) {
        return coinName;
    }

    // that can only be called externally
    function multiplyBalace(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // that uses a for loop and multiplies params and string comparison
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }
        }
        return 9999;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        
    }

    // function get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory){
        return myCoins[msg.sender];
    }

}