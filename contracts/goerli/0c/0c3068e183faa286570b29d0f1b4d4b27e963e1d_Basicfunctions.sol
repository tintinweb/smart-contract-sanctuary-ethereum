/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Basicfunctions{

    // setting thing up
    string CoinName = "EPIC COIN";

    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }
    mapping  (address => Coin) internal myCoins;

    // function ( string memory _variable1, int _vairiable2) public view/pure return(bool) {}
    function guessNumber(uint _guess) public pure returns (bool) {
        if(_guess == 5){
            return true;
        }else {
            return false;
        }
    }

    //return a string
    function getmMyCoinName() public view returns(string memory) {
        return CoinName;
    }

    //that can only be called external
    function multiplyBalalnce(uint _multiplier) external {
        myBalance = myBalance *  _multiplier;
    }

    // that uses a for loop and multiplier param and string comparsion
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++){
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                
             return i;

            }
        }
        return 7777;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);

    }
    
    //function geta coin from myCoin mapping
    function getmyCoin() public view returns (Coin memory){
        return myCoins[msg.sender];

    }
}