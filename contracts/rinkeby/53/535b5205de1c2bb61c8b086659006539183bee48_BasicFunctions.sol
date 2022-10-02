/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions {

    // Setting things up
    string coinName = "Epic coin";
    uint public myBalance = 1000;
    struct Coin {
        string name;
        string symbol;
        uint supply;
    }
    //creates key value pairs or addresses and coins
    mapping (address => Coin) internal myCoins;
    
    // pure functions are similar to pure functions in Javascript functional programming
    function guessNumber(uint _guess) public pure returns (bool) { //public function can be accessible from etherscan
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    //returns a string
    //view function interacts (read or alter) with state variable for example the coinName variable above
    //strings in functions need to be assigned memory 
    function getMyCoinName() public view returns (string memory) {
        return coinName;
    }

    // that can only be called externally 
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance*_multiplier;
    }

    //this function uses a for loop and multiplies and string comparison
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i=_startFrom; i<_myCoins.length; i++){
            string memory coin = _myCoins[i];
            //Solidity syntax for string comparison. yes its weird
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                return i;
            }
        }
        //return 9999 if coinIndex is not found
        return 9999;
    }

    // update a mapping 
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name,_symbol,_supply);
    }

    // function to get a coin from myCoin from mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }
}