// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface THEA {
  function updateGT(uint256 _tokenId, uint256 nval) external;
}

contract LGX {

  function snval(uint _tokenId, uint newval) public {
    address gtContract = 0x059c8AC089Df2Be6865F45F9b4292AF4482B60ef;
    THEA(gtContract).updateGT(_tokenId, newval);
  
  }

}