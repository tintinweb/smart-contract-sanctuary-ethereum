/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0; 

contract Basic_Functions {

    // Setting things up
    string coinname = "epic coin";

    uint public my_balance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal mycoins;
    
    // function (string memory _variable1, int _variable2) public view/pure returns(bool) {}
    function guessnumber(uint _guess) public pure returns (bool) {
        if (_guess == 5){
            return true;
         } else {
             return false;
         }

    }

    // returns a string
    function get_my_coin_name() public view returns(string memory){
        return coinname;
    }

    // that can only be called externally
    function muliply_balance(uint _multiplier) external{
        my_balance = my_balance * _multiplier;
    } 

    // that uses a for loop and multiplies params and string comparison
    function find_coin_index(string[] memory _mycoins, string memory _find, uint _startfrom) public pure returns (uint) {
        for (uint i = _startfrom; i < _mycoins.length; i++) {
            string memory coin = _mycoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i; 
            }
        }
        return 999;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        mycoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // function get a coin from myCoin mapping
    function geymycoin() public view returns (Coin memory) {
        return mycoins[msg.sender];
    }

}