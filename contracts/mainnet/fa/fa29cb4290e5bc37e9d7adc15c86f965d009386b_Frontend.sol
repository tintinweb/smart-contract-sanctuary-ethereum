/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBackend {
  function buy(uint256 listingId, uint256 number) external;
}

contract Frontend {
  IBackend private immutable BACKEND;

  address private owner;
  mapping(address => bool) private allowlisted;

  constructor(IBackend backend) {
    BACKEND = backend;
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "O");
    _;
  }

  modifier onlyOwnerOrAllowed {
    require(msg.sender == owner || allowlisted[msg.sender], "OA");
    _;
  }

  function setAllowed(address addr, bool allowed) external onlyOwner {
    allowlisted[addr] = allowed;
  }

  function buy(uint256 listingId, uint256 number) external onlyOwnerOrAllowed {
    BACKEND.buy(listingId, number);
  }
}