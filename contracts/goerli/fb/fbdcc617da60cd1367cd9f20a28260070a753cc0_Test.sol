/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    
    struct Coin {
        string name;
        string symbol;
        uint suply;
    }

    mapping(address => Coin) internal MyCoins;

    function addCoin (string memory _name, string memory _symbol, uint _supply) external {
        MyCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    function getCoin() public view returns (Coin memory) {
        return MyCoins[msg.sender];
        }

}