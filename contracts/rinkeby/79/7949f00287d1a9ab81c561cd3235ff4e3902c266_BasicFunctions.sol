/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

contract BasicFunctions {
   // function(string memory_variable1, string memory_variable2, uint _variable2) public view/pure returns(bool) {}

   //Setting variables
   string coinName = "Epic Coin";

   uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
      
    }

            mapping (address => Coin) internal myCoins;

            function guessNumber(uint _guess) public pure returns(bool) {
                if (_guess == 5) {
                return true;
                } else {
                    return false;
                }
            }

            //Function that returns a returns a string
            function getMyCoinName () public view returns(string memory) {
                return coinName;
            }

            //Functions that can only be called externally
            //Function that will multiply a balance
            function multiplyBalance (uint _multiplier) external {
                myBalance = myBalance * _multiplier;

            }

            //This is a function that uses a for loop and multiplies params and string comparisons
            function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
                for (uint i = _startFrom; i < _myCoins.length; i++){
                    string memory coin = _myCoins[i];
                    if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                        return i;
                    }

                }
                return 9999;
            }

            //This funciton updates a coin mapping
            function addCoin(string memory _name, string memory _symbol, uint _supply ) external {
                myCoins[msg.sender] = Coin(_name, _symbol, _supply);
            } 

            //Function to get a coin from myCoin mapping
            function getMyCoins() public view returns (Coin memory){
                return myCoins[msg.sender];
            }
}