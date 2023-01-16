/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract BasicFunctions {
    // function_name(parameter_list) scope returns(return_type) {// block of code}
    // https://www.geeksforgeeks.org/solidity-functions/
    // function (string memory or calldata _variable1, int _variable2)
    // scope = either public
    // access specifier = view (looking else where) or pure (looking internally)

    // SETTING UP
    string coinName = "EPIC Coin";

    struct Coin {
        string name;
        string symbol;
        uint256 supply;
    }

    // MAPPING "ADDRESS" TO THE ABOVE STRUCTURE'S "Coin" ITEMS
    mapping(address => Coin) internal myCoins;

    // FUNCTION (string memory _variable, int 
    function guessNumber(uint256 _guess) public pure returns (bool) {
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    // FUNCTION (INTERNALLY RETURN A STRING)
    function getMyCoinName() public view returns (string memory) {
        return coinName;
    }

    uint public myBalance = 1000;

    // FUNCTION CALLING EXTERNALLY (OUTSIDE OF THE FUNCTION)
    function multiplyMyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // FUNCTION USING FOR LOOP 
    // ["BTC", "ETH", "MATIC"]
    function findCoinIndex(string[] memory _myCoins,  string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) {
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }            
        }
        return 9999;
    }

    // UPDATING A MAPPING
    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    // FUNCTION TO GET A COIN FROM MYCOIN MAPPING
    function getMycoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }
}


// ENUMS MODIFIERS, STORAGE, FALLBACKS, SENDING AND RECEIVING