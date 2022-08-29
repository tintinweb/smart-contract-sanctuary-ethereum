/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract apehash {
    constructor() {
    }

    function hashrate(uint256 rare, uint256 basehashrate, uint256 level) public pure returns(uint256) {
        uint256 _staticPower = 0;
        uint256 _staticPercent = 0;
        if(rare == 4){
            _staticPower = 50*(basehashrate-10)+2000;
            _staticPercent = 20;
        }else if(rare == 5){
            _staticPower = 50*(basehashrate-50)+5000;
            _staticPercent = 30;
        }
        uint256 currentHashrate = basehashrate + _staticPower * (level - 1) / 100 + (level / 5) * 1 + (level / 5) * _staticPower * _staticPercent / 200 / 100;
        return currentHashrate;
    }
}