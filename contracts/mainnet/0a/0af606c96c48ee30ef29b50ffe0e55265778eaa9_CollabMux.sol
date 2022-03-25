/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

struct StakingInfo {
  uint256 whaleId;
  uint256 alphaId;
  uint256 stakedAt;
}

abstract contract WhaleSharkContract {
  function balanceOf(address) virtual public view returns (uint256);
}
abstract contract StakingContract {
  function getTokensStaked(address) virtual public view returns (StakingInfo[] memory);
}

contract CollabMux {
  WhaleSharkContract public whaleSharkContract = WhaleSharkContract(0xA87121eDa32661C0c178f06F8b44F12f80ae4E88);
  StakingContract public stakingContract = StakingContract(0x5a20c57a7e76e967ED284b8894b26bEd8ef7e785);

  function balanceOf(address owner) public view returns (uint256) {
    uint256 numHoldingSharks = whaleSharkContract.balanceOf(owner);
    uint256 numStaked = stakingContract.getTokensStaked(owner).length;
    return numHoldingSharks + numStaked;
  }
}