/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract MyLoloCoin {

    uint supplyBalance;
    uint maxSupply;

    constructor(uint _supplyBalance, uint _maxSupply){
        supplyBalance = _supplyBalance;
        maxSupply = _maxSupply;
    }
}

contract MyLoloToken is MyLoloCoin {
    constructor(uint sb, uint ms) MyLoloCoin (sb, ms) {}

    function getSupplyBalance() public view returns (uint){
        return supplyBalance;

    }

    function getMaxSupply() public view returns (uint){
    return maxSupply;

    }

}