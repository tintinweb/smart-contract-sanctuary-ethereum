/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract BasicFunction{
    string public coinName="EPIC Coin";

    struct  Coin{
        string name;
        string symbol;
        uint supply;
    }

    mapping(address=>Coin) internal myCoins;

    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender]=Coin(_name, _symbol, _supply);
    }

    function getMyCoin() public view returns(Coin memory){
        return myCoins[msg.sender];
    }



}