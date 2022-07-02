/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;

contract BasicFunctions {

    //Settup
    string coinName = "EPIC coin";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    // function (string memory _myString, uint _myVariableInt) public view/pure returns (bool){}
    function guessNumber(uint _guess) public pure returns (bool) {
        if (_guess == 5){
            return true;
        } else {
            return false;
        }
    }

    //return string
    function getMyCoinName() public view returns (string memory){
        return coinName;
    }

    // that can only be called externalyy
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    //functions is using a loop and multiply params and strings comparisson
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint){
        for (uint i = _startFrom; i < _myCoins.length; i++ ){
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                return i;
            } 
        }
        return 9999;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    //function get coin from mapping
    function getsMyCoin() public view returns (Coin memory){
        return myCoins[msg.sender];
    }

}