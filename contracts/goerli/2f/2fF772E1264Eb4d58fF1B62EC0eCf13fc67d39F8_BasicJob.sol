//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract BasicJob {
  error OnCooldown();
  error NotWorkable();

  event BasicWorked();
  event ComplexWorked();

  // mapping 0 = basic | 1 = complex => timestamp
  mapping(uint8 => uint256) public lastWorkAt;
  uint256 public workCooldown = 30 seconds;
  bool public trigger;

  function setWorkCooldown(uint256 _cooldown) external {
    workCooldown = _cooldown;
  }

  function basicWork() external {
    if (!basicWorkable()) revert OnCooldown();
    lastWorkAt[0] = block.timestamp;
    emit BasicWorked();
  }

  function complexWork(bool _trigger) external {
    if (!complexWorkable(_trigger)) revert NotWorkable();
    lastWorkAt[1] = block.timestamp;
    emit ComplexWorked();
  }

  function basicWorkable() public view returns (bool) {
    return block.timestamp > (lastWorkAt[0] + workCooldown);
  }

  function complexWorkable(bool _trigger) public view returns (bool) {
    return block.timestamp > (lastWorkAt[1] + workCooldown) && _trigger;
  }
}