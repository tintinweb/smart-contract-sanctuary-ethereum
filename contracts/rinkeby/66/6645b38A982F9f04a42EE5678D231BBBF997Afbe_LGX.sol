// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface THEA {
  function updateGT(uint256 _tokenId, uint256 nval) external;
}

contract LGX {

  function snval(uint _tokenId, uint newval) public {
    address gtContract = 0xdB1777c57F7A63Bf35A982453583aF43445A44A2;
    THEA(gtContract).updateGT(_tokenId, newval);
  
  }

}