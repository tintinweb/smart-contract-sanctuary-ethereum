/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions {
  
  // Setting things up
  string coinName ="EPIC Coin";

  uint public myBalance =1000;

  struct Coin{
     string name;
     string symbol;
     uint supply;
   }
                                               // kani map to address se afto to coin
   mapping (address => Coin) internal myCoins; // internal only accessible by contracts within this contract or this contract

  // function (string memory _variable1,int_variable2) we need to specify the scope internal,external, public etc then view/pure
  // returns(type) evale bool sti parenthesi t return {}
  function guessNumber(uint _guess) public pure returns (bool) {
      if  (_guess == 5) { //== equal , != not equal similar to javascript
          return true;
      } else {
          return false;
      }
      
    }
 
    // returns a string
    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

    //that can only be called externally
    function multiplyBalance(uint _multiplier) external{
        myBalance = myBalance * _multiplier;
    }

    //function that uses a for loop and multiplies params and string comparison
    function findCoinIndex(string[]memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find)))  {
                return i;
            }
        }
        return 9999;
    }
    // function update a mapping...msg sender en wallet address
    function addCoin(string memory _name,string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }
    
    //function get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }

}