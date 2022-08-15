/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract BasicFunctions{

    uint public myBalance = 1000;

    struct Coin{
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;

    function multiplyBalance (uint _multiplier) public {
        myBalance = myBalance * _multiplier;
    }

    // update a mapping
    function addCoin(string memory _name, string memory _symbol, uint _supply) external{
        myCoins[msg.sender]=Coin(_name,_symbol,_supply);
    }

    //function get a coin from myCoin mapping

    function getMyCoin() public view returns (Coin memory){
        return myCoins[msg.sender];
    }
}