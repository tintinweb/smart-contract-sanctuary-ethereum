// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

contract SelfDestructFacet {
  function destroyDiamond() public {
    (bool successB, bytes memory data) = address(this).call(abi.encodeWithSelector(bytes4(keccak256("owner()"))));

    require(successB, "SelfDestructFacet: owner() execution failed");
    require(abi.decode(data, (address)) == msg.sender, "SelfDestructFacet: Not authorized");

    selfdestruct(payable(address(this)));
  }
}