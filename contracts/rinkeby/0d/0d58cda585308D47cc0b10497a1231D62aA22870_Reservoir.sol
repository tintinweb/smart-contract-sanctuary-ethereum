// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./EIP20Interface.sol";
import "./SafeMath.sol";
contract Reservoir {
  // @notice The block number when the Reservoir started (immutable)
  uint public dripStart;
  // @notice Tokens per block that to drip to target (immutable)
  uint public dripRate;
  // @notice Reference to token to drip (immutable)
  EIP20Interface public token;
  // @notice Target to receive dripped tokens (immutable)
  address public target;
  // @notice Amount that has already been dripped
  uint public dripped;
  constructor(uint dripRate_, EIP20Interface token_, address target_) public {
    dripStart = block.number;
    dripRate = dripRate_;
    token = token_;
    target = target_;
    dripped = 0;
  }
  function drip() public returns (uint) {
    // First, read storage into memory
    EIP20Interface token_ = token;
    uint reservoirBalance_ = token_.balanceOf(address(this)); // TODO: Verify this is a static call
    uint dripRate_ = dripRate;
    uint dripStart_ = dripStart;
    uint dripped_ = dripped;
    address target_ = target;
    uint blockNumber_ = block.number;
    // Next, calculate intermediate values
    uint dripTotal_ = SafeMath.mul(dripRate_, blockNumber_ - dripStart_, "dripTotal overflow");
    uint deltaDrip_ = SafeMath.sub(dripTotal_, dripped_, "deltaDrip underflow");
    uint toDrip_ = SafeMath.min(reservoirBalance_, deltaDrip_);
    uint drippedNext_ = SafeMath.add(dripped_, toDrip_, "tautological");
    // Finally, write new `dripped` value and transfer tokens to target
    dripped = drippedNext_;
    token_.transfer(target_, toDrip_);
    return toDrip_;
  }
}