/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Lottery {
  address private immutable _deployer;

  constructor() public payable {
    _deployer = msg.sender;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, 'not-deployer');
    _;
  }

  function play() external payable onlyDeployer {
    require(msg.value == 0.01 ether);
    bytes32 abc = keccak256(abi.encode(rndSource(), address(this).balance));
    if ((uint256(abc) % 10000) == 0) {
      payable(msg.sender).transfer(address(this).balance);
    }
  }

  function rndSource() public view returns (bytes32) {
    return blockhash(block.number - (block.number % 200));
  }

  fallback() external {
    revert();
  }
}