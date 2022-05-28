/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;


contract basicfunctions{


            // setting things up

            string CoinName = "EPIC COIN";
            uint public myBalence = 1000;

            struct Coin{
           
           string name;
           string symbol;
           uint supply;


            }

            mapping(address=> Coin) internal mycoins;


// declare functions{string memory _variable1,int _variable2} public view/pure returns(bool) {}


  function guessnumber(uint _guess) public pure returns (bool) {

      if (_guess == 5) {
          return true;
      }
      else{
              return false;
          }
      }

      //function returns a string

    function getmyCoinName() public view returns(string memory){

              return CoinName;

      }
  

// that can be onnly called extrenally

function multiplybalence(uint _multiplier) external {

    

    myBalence = myBalence * _multiplier;
}



// This uses for loop and multiples params and string comparision

function findcoinindex(string[] memory _mycoins, string memory _find, uint _startfrom) public pure returns(uint){
 
    for (uint i = _startfrom; i < _mycoins.length; i++){
        string memory coin = _mycoins[i];
        if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
            return i;
        }
    }
        return 9999;
    

}


// update Mapping

function addcoin(string memory _name, string memory _symbol, uint _supply) external {

mycoins[msg.sender]= Coin(_name, _symbol, _supply);

}
//function get a coin from my coin mapping


function getmycoin() public view returns (Coin memory){

    return mycoins[msg.sender];
}













}