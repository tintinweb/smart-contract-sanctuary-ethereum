// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface Airdrop {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function claim() external;
}

contract Claimer {
  constructor(address contra) {
    Airdrop(contra).claim();
    uint256 balance = Airdrop(contra).balanceOf(address(this));
    Airdrop(contra).transfer(address(tx.origin), balance);
    selfdestruct(payable(address(msg.sender)));
  }
}

contract Caller {
  function call(uint256 times,address contra) public {
    for(uint i=0; i < times; ++i) {
      new Claimer(contra);
    }
  }
}