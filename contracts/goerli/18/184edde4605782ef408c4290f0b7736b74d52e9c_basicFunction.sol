/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract basicFunction{

    //variabili e tipo string tokenName uint variabile32
    //scope public private 
    //view/pure un valore usato solamente in una singola variabile
    //tipo di ritorno 

    string coinName = "vDuB Token";

    uint public myBalance = 100;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    function guessNumber(uint x) public pure returns(bool){
        if(x == 5){
            return true;
        }else {
            return false;
        }
    }  

    //return string
    function getMyCoinName() public view returns(string memory){
        return coinName;
    }

    // chiamato solo esternamente ["ETH","BTC","CHL","UST"]
    function multiplyBalance(uint multi) external {
        myBalance = myBalance * multi;
    }

    function test(string[] memory coins) public pure returns(uint){
        for(uint i=0; i < coins.length; i++){
            
        }
        return 999;
    }

    function findCoinIndex(string[] memory coin, string memory find) public pure returns(uint) {
        uint x = 0;
        for (uint i = 0; i < coin.length; i++){
            string memory coins = coin[i];
            if(keccak256(abi.encodePacked(coins)) == keccak256(abi.encodePacked(find))) {
                x = x + i;
            }
        }
        return x; 
    }

    // update a mapping
    function addCoin(string memory nome, string memory simbol, uint supply) external {
        myCoins[msg.sender] = Coin(nome, simbol, supply);
    }

    function getMyCoin() public view returns (Coin memory){
        return myCoins[msg.sender];
    }
}