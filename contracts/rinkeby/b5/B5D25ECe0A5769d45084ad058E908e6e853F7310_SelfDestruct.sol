//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SelfDestruct {
    address force = 0xa4dD9418bC5E4d77180B13bCD004647a8542e3ee;

    function getMoney() public payable {}

    function destroy() public {
        selfdestruct(payable(force));
    }
}