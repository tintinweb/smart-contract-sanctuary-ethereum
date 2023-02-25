/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract BasicFunctions {
    // function (type _var1, string memory _var2) public view/pure returns (type) {}
    string coinName = "Epic Coin";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    function guessNumber(uint _guess) public pure returns (bool) {
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    } 


    function guessNumberint(uint _guess) public view returns (uint) {
        if (_guess == 5) {
            return _guess*5;
        } else {
            return myBalance;
        }
    } 

    // return a string
    function getMyCoinName () public view returns (string memory) {
        return coinName;
    }

    //function multipleBalance(uint _multiplier) external returns (uint) {
    function multipleBalance(uint _multiplier) public returns (uint) {
//myBalance = myBalance * _multiplier;
        return myBalance * _multiplier;
    }

// function that uses loop and multiple params and string comparison
    function findCoinIndex (string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i=_startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encode(coin)) == keccak256(abi.encode(_find)))
                return i;
        } 
        return 9999;
    }

// update a mapping
    function addCoin (string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

// function t get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }

}