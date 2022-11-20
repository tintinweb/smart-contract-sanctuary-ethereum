/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >= 0.7.0 < 0.9.0;

contract MyEpicCoin {
    uint availableSupply;
    uint maxSupply;

    constructor(uint _startingSupply, uint _maxSupply){
        availableSupply = _startingSupply;
        maxSupply = _maxSupply;
    }
}

contract MyEpicToken is MyEpicCoin {
    constructor(uint ss, uint ms) MyEpicCoin(ss, ms) {}

    function getAvailableSupply() public view returns (uint){
        return availableSupply;
    }

    function getMaxSupply() public view returns (uint){
        return maxSupply;
    }
}