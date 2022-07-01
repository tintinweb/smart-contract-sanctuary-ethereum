/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BasicFuntion {

    // Setting thigs up
    string coinName = "Epic Coin";
    uint public coinBalance = 100;

    struct Coin{
        string name;
        string symbol;
        uint supply;

    }

    mapping (address=> Coin) internal myCoins;

    // function functionName (string memory _variable1, uint _variable2) public pure/view returns(bool){}

    function guess (uint _guess) public pure returns(bool){
        if(_guess == 5){
            return true;
        }else{
            return false;
        }
    }

    // return string
    function getCoinName() public view returns(string memory){
        return coinName;
    }

    function multiplyBalance(uint _multiply) external{
        coinBalance = coinBalance * _multiply;
    }

    // for loop
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns(uint){
        for (uint i = _startFrom; i < _myCoins.length; i++){
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                return i;
            }
        }
        return 9999;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // get a coin from mapping
    function getCoin() public view returns(Coin memory){
        return myCoins[msg.sender];
    }


}