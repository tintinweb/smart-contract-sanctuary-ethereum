/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BasicFunctions {

    // setting things up

    string coinName = "Epic Token";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping(address => Coin) internal myCoins;


    // function(string memory _variable1, int _variable2) public view/pure returns(bool) {}
    // 'view' when function is interacting with another part of the smart contract

    // returns a bool
    function guessNumber(uint _guess) public pure returns(bool) {
        if(_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    // returns a string
    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

    // that can only be called externally
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // that uses a for loop, and multiplies params, and string comparison
    function findCoinIndex(string[] memory _myCoins, string memory _coinToFind, uint _startFrom) public pure returns(uint) {
        for(uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if(keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_coinToFind))) {
                return i;
            }
        }
        return 9999;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }

    
    
}