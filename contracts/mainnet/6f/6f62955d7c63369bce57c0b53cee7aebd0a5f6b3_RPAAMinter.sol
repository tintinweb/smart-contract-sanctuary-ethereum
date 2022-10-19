/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IEditions {
  function mint(address to, uint256 id, uint256 amount) external;
}

contract RPAAMinter {
  // Editions Contract 0x3C6Fe936f6e050C243B901D809AEA24084674687
  IEditions public editions;
  // Planned Parenthood Endaoment Address 0x8cb4C292af41eeeF3DF2259c9A413d160c5bB21d (https://app.endaoment.org/orgs/131644147)
  address public benefactor;

  constructor(IEditions _editions, address _benefactor) {
    editions = _editions;
    benefactor = _benefactor;
  }

  function mint(uint256 amount) external payable {
    require(msg.value == amount * 0.01 ether, 'Must pay 0.01 ETH per token');
    editions.mint(msg.sender, 1, amount);
    payable(benefactor).transfer(msg.value);
  }
}