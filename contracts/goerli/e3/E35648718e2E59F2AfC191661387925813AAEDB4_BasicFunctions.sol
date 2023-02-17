/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions {

    // setting things up
    string coinName = "EPIC coin";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping(address => Coin) internal myCoins;

    // function (string _variable, int _variable2) public view/pure returns(type) {}

    function guessNumber(uint _guess) public pure returns(bool) {
        if (_guess == 5) {
            return true;
        }

        return false;
    }

    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

    // can only be called externally
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    function findCoinIndex(string[] calldata _myCoins, string calldata _find, uint _startFrom) public pure returns(uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            if (keccak256(abi.encodePacked(_find)) == keccak256(abi.encodePacked(_myCoins[i]))) {
                return i;
            }
        }
        return 9999;
    }

    // internal mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    function getMyCoin() external view returns (Coin memory) {
        return myCoins[msg.sender];
    }
}