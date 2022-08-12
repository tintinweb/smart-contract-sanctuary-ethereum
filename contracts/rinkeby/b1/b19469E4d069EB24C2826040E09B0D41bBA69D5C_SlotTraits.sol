// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SlotTraits {
    
  function getSlotsLength() public pure returns (uint256) {
    return getSlots().length;
  }

  function getSlots() public pure returns (string[2][3] memory) {
    return [
      ["Cherry", "QmT2gwPRPUa2wsZZv5zDie9CamMS7fUkSKr5sXcYyFGHyw"],
      ["Grape", "QmPBDsaeTrNv2EaRCX6qhihjtprUD88QoBUPmEesy4bVxt"],
      ["Watermelon", "QmR5qCmAx4Fy9L6TJ29T7sF2wQSe29MQPRzztNQvyeWcfw"]
    ];
  }
}