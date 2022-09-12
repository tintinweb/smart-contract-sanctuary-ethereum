/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BasicFunctions {

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    // that uses a for loop and multiplies params and string comparison
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns(uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }
        }
        return 9999;
    }

    // function update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // function get a coin from myCoin mapping
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }
}