/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions{

    //setup

    string coinName = "Epic Coin";
    uint public myBalance = 1000;

    struct Coin{

        string Name;
        string Symbol;
        uint Supply;
    }

    mapping(address => Coin) internal myCoins; 

    //Functions

    function guessNumber(uint _guess) public pure returns (bool){

        if(_guess == 5){
            return true;
        }else{
            return false;
        }

        
    }

    //return a string

    function getMyCoinName() public view returns (string memory){

        return coinName;
    }

    //call externally

    function MultiplyBalance(uint _multiplier) external {

        myBalance = myBalance * _multiplier;
    }

    //a function that uses ForLoops 
}