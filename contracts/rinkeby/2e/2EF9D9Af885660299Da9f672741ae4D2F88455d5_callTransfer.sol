// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract callTransfer {
  ITransfer public xx;
  function setTransferContract(address _transferContract) external {
    xx = ITransfer(_transferContract);
  }

  function transferNFT(address _from, address _to, uint tokenId) public {
    xx.safeTransferFrom(_from, _to, tokenId);
  }
}

interface ITransfer {
  function safeTransferFrom(address _from, address _to, uint tokenId) external;
}