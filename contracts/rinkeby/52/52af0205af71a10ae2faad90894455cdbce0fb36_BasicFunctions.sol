/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

//SPDX-License-Identifier:MIT
pragma solidity >= 0.7.0 <0.9.0;

contract BasicFunctions {

    //Setting things up
    string coinName = "EPIC Coin";

    uint public myBalance =300;


    //créée structure
    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    //mapper adresse avec nom du coin(comme un dict en python)
    mapping (address => Coin) internal myCoins;//key=address, value=Coin


    function guessNumber(uint _guess) public pure returns (bool) {
        if (_guess ==5) {
            return true;
        }else{
            return false;
        }
    }

    //afficher nom du coin stocké hors de la fonction
    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

 

    //can only be called externally
    function multiplyBalance(uint _multiplier) external{
        myBalance = myBalance * _multiplier;
    }

    //uses a for loop to multiply params and string comparison
    function findCoinIndex(string[] memory _myCoins,string memory _find,uint _startFrom) public pure returns (uint) {
        for (uint i =_startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) ==keccak256(abi.encodePacked(_find))){
                return i;
            }

        }
        return 9999;
    }

    //update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name,_symbol,_supply);
    }

    //function get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }

}