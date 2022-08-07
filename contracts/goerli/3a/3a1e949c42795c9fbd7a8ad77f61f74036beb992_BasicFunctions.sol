/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 < 0.9.0;
pragma experimental ABIEncoderV2;

contract BasicFunctions{
    
    // Setting things up
    string coinName = "Epic coin";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    // function (string memory _variable, int _variable2) public/internal/external view/pure returns(bool) {}
    // pure naudojam kai viskas vyksta vienoje function, t.y neinteractinam su kitais variables outside esamos function 
    function guessNumber(uint _guess) public pure returns (bool){
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    // returns a string
    function getMyCoinName() public view returns(string memory){
        return coinName;
    }

    // that can only be called externaly
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // that uses a for loop and multiplies params and string comparison
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint){
        for (uint i = _startFrom; i < _myCoins.length; i++){
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                return i;
            }
        }
        return 999;
    }

    // update and mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // function get a coin from myCoin mapping

    function getMyCoin() public view returns( Coin memory){
        return myCoins[msg.sender];
    }
}