/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Test {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

     function flip() public view returns (bool) {
         uint256 blockValue = uint256(blockhash(block.number));

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        return side;
  }

  function flipMinus() public view returns (bool) {
         uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        return side;
  }
}