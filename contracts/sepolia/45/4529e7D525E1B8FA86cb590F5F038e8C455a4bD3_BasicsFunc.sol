/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7 < 0.9;

contract BasicsFunc {
    
    // Setting up vars
    string coinName = "EPIX";
    struct Coin {
        string name;
        string symbol;
        uint supply;
    }
    mapping (address => Coin) internal myCoins;
    // function (string _var1, int _var1) public view/pure returns (bool) { }
    function guessNum (uint _guess) public pure returns (bool){
        if (_guess == 69){
            return true;
        } else {
            return false;
        }
    }
    uint public myBalance = 1000;
    // return Coin name
    function getName () public view returns (string memory){
        return coinName;
    }

    // external
    function multiplyBalance (uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // looping and string comparisons
    function findCoinIndex (string[] memory _coinArray, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _coinArray.length; i++) {
            string memory coin = _coinArray[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }
        }
        return 909;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // get a coin from myCoins
    function getMyCoin () public view returns(Coin memory){
        return myCoins[msg.sender];
    }
}