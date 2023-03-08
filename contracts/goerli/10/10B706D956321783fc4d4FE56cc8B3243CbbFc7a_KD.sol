/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
}

contract KD {
  IERC20 public ket;
  IERC20 public jet;

  event Achieve(uint256 indexed missionId, address userAddress, uint256 rewardAmount, uint256 proofId, bytes32 proofHash);

  modifier onlyJetHolder() {
    require(jet.balanceOf(msg.sender) > 0, 'KD: not JET holder');
    _;
  }

  constructor(address _ket, address _jet) {
    ket = IERC20(_ket);
    jet = IERC20(_jet);
  }

  function setAchievement(uint256 _missionId, address _userAddress, uint256 _rewardAmount, uint256 _proofId, bytes32 _proofHash) external onlyJetHolder returns (bool) {
    ket.mint(_userAddress, _rewardAmount);
    emit Achieve(_missionId, _userAddress, _rewardAmount, _proofId, _proofHash);
    return true;
  }
}