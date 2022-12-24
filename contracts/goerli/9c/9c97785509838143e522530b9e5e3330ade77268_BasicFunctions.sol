/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions {

    // getting started
    string coinName = "BlayCoin";
    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    //mapping
    mapping (address => Coin) internal myCoins;


    // functions (string memory_variable1, int _variable2) public view/pure returns (bool);
    function guessNumber (uint _guess) public pure returns (bool) {
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    // getting string
    function getMyCoinName () public view returns (string memory){
        return coinName;
    }

    // External input
    function multiplier (uint _multiply) external {
        myBalance = myBalance * _multiply;
    }

    // for loop
    function loopFunc (string[] memory _myCoin, string memory _find, uint _startFrom) public pure returns(uint){
        for (uint i = _startFrom; i < _myCoin.length; i++){
            string memory coin = _myCoin[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                return i;
            }
        }
        return 9999;
    }

    //update mapping
    function addCoin (string memory _name, string memory _symbol, uint _supply) external{
        myCoins[msg.sender] = Coin(_name, _symbol, _supply );
    }
    //function to get coins from myCoins mapping
    function getMyCoins () public view returns (Coin memory){
        return myCoins[msg.sender];
    }
 
}