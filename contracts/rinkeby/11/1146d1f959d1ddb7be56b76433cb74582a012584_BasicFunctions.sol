/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions {

    // State variable
    string coinName = "EPIC Coin";
    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    function guessNumber(uint guess) public pure returns(bool){
        if (guess == 5){
            return true;
        } else {
            return false;
        }
    }

    // returns a string
    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

    // that can only be called extrnally
    function multiplyBalance(uint multiplier) external {
        myBalance = myBalance * multiplier;
    }

    function findCoinIndex(string[] memory _myCoins, string memory find, uint startFrom) public pure returns (uint) {
        for (uint i = startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if(keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(find))){
                return i;
            }
        }
        return 999;
    }

    // update a mapping
    function addCoin (string memory name, string memory symbol, uint supply) external {
        myCoins[msg.sender] = Coin(name, symbol, supply);
    }

    // fuction get a coin from myCoin mapping
    function getMyCoin() public view returns(Coin memory) {
        return myCoins[msg.sender];
    }

}