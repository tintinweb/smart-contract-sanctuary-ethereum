/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// "SPDX-License-Identifier: MIT"

pragma solidity >= 0.7.0 < 0.9.0;


contract BasicFunction {

    string coinName ="EPIC Coin";
    uint myBalance = 1000;

    struct Coin{
         string name;
         string symbol;
         uint supply;
          
    }
    mapping (address => Coin) internal myCoins;

    function guessNumber (uint _guess) public pure returns (bool){
        if (_guess == 5){
          return true;}
        else {
            return false;
    
        }  
    
    }
    function getMyCoinName () public view returns (string memory){
      return coinName;
    
    }
    function multiplyBalanced(uint _multiplier) external {

        myBalance = myBalance * _multiplier;
    }
    function findCoinIndex (string[] memory _myCoins, string memory _find, uint _startForm) public pure returns (uint){

      for (uint i = _startForm; i <= _myCoins.length; i++) {
           string memory coins = _myCoins[i];
           if (keccak256(abi.encodePacked(coins)) == keccak256(abi.encodePacked(_find))){
             return i;
         } 
      
      }
      return 9999;
    } 
    function addCoin (string memory _name, string memory _symbol, uint _supply) external {
  
      myCoins[msg.sender] = Coin (_name, _symbol, _supply);        
    }
    function getMyCoins () public view returns (Coin memory){
      return myCoins [msg.sender];
    }
}