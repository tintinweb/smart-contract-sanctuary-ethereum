/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.6;

contract Test {

    //setting thing up - State Variable
    string coinName = "EPIC";

    uint public myBalance = 100;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;



    //Functions (string memory _Variable, int _variable2) public/private view/pure(done in funtion and returned outside func.) return(bool) {}
    function guessNumber(uint _guess) public pure returns(bool) {
        if (_guess == 5) {
            return true;
        } else {
                return false;
            }
        
    }

    // returns a string
    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

    // only be called externally
    function multiplyBal(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // uses for loop and muiltiplues params and sting comparison
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            // check
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }
        }
        return 9999;
    }

    // update mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // function to get from myCoin mapping - overwrites the coin
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }

}