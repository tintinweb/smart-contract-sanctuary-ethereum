// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Force {
    function collect() public payable returns(uint) {
        return address(this).balance;
    }

    function selfDestroy() public {
        address addr = 0x22699e6AdD7159C3C385bf4d7e1C647ddB3a99ea;
        selfdestruct(payable(addr));
    }
}