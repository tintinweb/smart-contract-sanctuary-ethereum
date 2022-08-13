/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Lottery {
  uint256 private constant _version = 1;
  address private immutable _your_team_account;

  constructor() public payable {
    _your_team_account = msg.sender;
  }

  modifier onlyYourTeam() {
    require(msg.sender == _your_team_account, 'not-your-team-account');
    _;
  }

  function play() external payable onlyYourTeam {
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