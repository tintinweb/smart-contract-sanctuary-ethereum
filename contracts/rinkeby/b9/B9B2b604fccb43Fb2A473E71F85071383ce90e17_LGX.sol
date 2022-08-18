// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface THEA {
  function updateGT(uint256 _tokenId, uint256 nval) external;
}

contract LGX {

  function snval(uint _tokenId, uint newval) public {
    address gtContract = 0x1B54CCa8EC414C18Bb10F76b9d5215A023570828;
    THEA(gtContract).updateGT(_tokenId, newval);
  
  }

}