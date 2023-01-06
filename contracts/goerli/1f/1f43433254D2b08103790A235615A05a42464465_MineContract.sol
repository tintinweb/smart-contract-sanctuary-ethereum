// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface MineAllInterface {
    
    function mine(uint256 _tokenId) external;

}

contract MineContract {

    //address MineContractAddress = 0x0F9B1418694ADAEe240Cb0d76B805d197da5ae8a;

    MineAllInterface MineA = MineAllInterface(0x0F9B1418694ADAEe240Cb0d76B805d197da5ae8a);

    function mineTokens(uint256[] calldata tokenIds) external {
      for (uint256 i = 0; i < tokenIds.length;) {
        MineA.mine(tokenIds[i]);
        unchecked { ++i; }
      }
    }
}