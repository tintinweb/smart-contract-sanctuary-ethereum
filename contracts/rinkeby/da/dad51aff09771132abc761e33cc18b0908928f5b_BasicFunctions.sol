/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0; 

contract BasicFunctions {
    
    // settings things up
    string coinName = "Epic Coin";
    uint mybalance = 1000;
  

    // fucntions
    function guessNumbers(uint _guess) public pure returns(bool){
 if(_guess == 5){return true;}else{return false;}
    }
    function getCoinName() public view returns(string memory){
        return coinName;
    }
    function multMybalance (uint _multiplier) external returns(uint){
      mybalance = _multiplier * mybalance ;
      return mybalance;
    }
    function FindCoinIndex (string[] memory _mycoins,string memory _find,uint _startFrom) public pure returns (uint){
        for (uint i = _startFrom;i< _mycoins.length;i++){
          string memory coin = _mycoins[i];
          if(keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
              return  i;
          }
        }
        return 99;
    }
    struct coin1{
      string  name;
      string  symbol;
      uint supply;

  }
    mapping (address => coin1) internal myCoins1;
// update a mapping
    function addCoin(string memory _name,string memory _symbol,uint _supply) external {
     myCoins1[msg.sender] = coin1(_name,_symbol,_supply);
    }
    // function get coin from mapping
    function getMyCoin() public view returns(coin1 memory){
        return myCoins1[msg.sender]; 
    }
}