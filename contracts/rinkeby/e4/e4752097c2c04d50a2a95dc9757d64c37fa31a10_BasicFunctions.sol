/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0.1

pragma solidity >= 0.7 < 0.9.0;

contract BasicFunctions {

    // function(string memory _var1, int _var2) public view/pure = doesn't interact w/ any other function returns(bool) {}

    string coinName = "EPIC Coin";
    uint public balance = 1000;
    string public odd = "tt";

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    function guessNumber(uint _guess) public pure returns(bool) {
        if (_guess == 5){
            return true;
        } else {
            return false;
        }
    }

    function getMyCoinName() public view returns(string memory)
    {
        return coinName;
    }

    function multiBal(uint multiBy) external {
        balance = balance * multiBy;
    }

    string[] public CoinNames = ["Chainlink", "Eth", "Doge"];
    uint[5] levels = [1,2,3,4,5];

    function findCoinIndex(string[] memory _coinArray, string memory coinName, uint _startFrom) public pure returns(uint) {    
        for (uint i = _startFrom; i < _coinArray.length; i++) {
            string memory coin = _coinArray[i];
            if (keccak256(abi.encodePacked(coinName)) == keccak256(abi.encodePacked(coin))) {
                return i;
            }
        }
        
    }

    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        Coin memory newCoin = Coin(_name, _symbol, _supply);
        myCoins[msg.sender] = newCoin;
        
    }

    function getMyCoin(uint _id) public view returns(Coin memory){
        return myCoins[msg.sender];
    }

}