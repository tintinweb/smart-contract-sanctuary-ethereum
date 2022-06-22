/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BasicFunctions {
    // Setting things up
    string coinName = "EPIC Coin";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }
    mapping(address => Coin) internal myCoins;

    // Function
    function guessNumber(uint _guess) public pure returns(bool) {
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }
    // Return a string
    function getMyCoinName() public view returns(string memory) {
        return coinName;

    }
    // that can be called external
    function multiplyBalance(uint _multiflier) external {
        myBalance = myBalance * _multiflier;
    }
    // for loop and multiflier params and string comparision
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }
        }
        return 9999;
    }
    // update mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }
    // Get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }
}