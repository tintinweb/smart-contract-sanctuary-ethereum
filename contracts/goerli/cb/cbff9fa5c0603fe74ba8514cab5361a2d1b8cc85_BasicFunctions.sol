/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions{

    // State variable

    string coinName = "Script Coin";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping(address => Coin) internal myCoins;

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

    function multiplyBalance(uint _multiplier) external {
        myBalance *= _multiplier;
    }

    // Use a For loop to multiply params and do string comparisons
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns(uint) {
        for(uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];

            if(keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }
        }
        return 9999;
    }

    // Update mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    //Function get a coin from MyCoin Mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }


}