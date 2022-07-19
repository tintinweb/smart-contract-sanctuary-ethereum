/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract BasicsFunctions{

    string coinName = "Super Coin";
    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping(address => Coin) internal myCoins;

    //function (string _variable1, int _variable2) public view/pure returns(bool) {}

    function gessNumber(uint _num) public pure returns (bool){
        if(_num == 5){
            return true;
        }else{
            return false;
        }
    
    }

    function getMyCoinName() public view returns (string memory){
        return coinName;
    }

    function multiplyMyBalance(uint _multiplayer) external{
        myBalance = myBalance * _multiplayer;
    }

    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for(uint i = _startFrom; i < _myCoins.length; i++){
            string memory coin = _myCoins[i];
            if(keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                return i;
            }
        }
        return 9999;
    }

    //Update mapping
    function addCoin(string memory _name, string memory _symbol, uint _suply) external{
        myCoins[msg.sender] = Coin(_name, _symbol, _suply);
    }

    //function get myCoin from mapping
    function getMyCoin() public view returns (Coin memory){
        return myCoins[msg.sender];
    }
}