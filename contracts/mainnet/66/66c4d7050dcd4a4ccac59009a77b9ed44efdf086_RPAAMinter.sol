/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IEditions {
  function mint(address to, uint256 id, uint256 amount) external;
}

contract RPAAMinter {
  IEditions public editions;
  address public benefactor;
  address deployer;

  constructor(IEditions _editions, address _benefactor) {
    editions = _editions;
    benefactor = _benefactor;
    deployer = msg.sender;
  }

  function mint(uint256 amount) external payable {
    require(msg.value == amount * 0.01 ether, 'Must pay 0.01 ETH per token');
    editions.mint(msg.sender, 1, amount);
    payable(benefactor).transfer(msg.value);
  }

  function updateBenefactor(address _benefactor) external {
    require(msg.sender == deployer);
    benefactor = _benefactor;
  }
}