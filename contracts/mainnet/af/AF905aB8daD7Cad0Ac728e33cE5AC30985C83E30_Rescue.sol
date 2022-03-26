//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
Rescue.sol

Rescuing eth sent to a mainnet address representation of a testnet contract.

*/

contract Rescue {
    function pullFunds() public {
        (bool succ, ) = payable(0x7FD81Fc17F05A035521b70C636aC1De0FA4B2Bc8)
            .call{value: address(this).balance}("");
        require(succ, "transfer failed");
    }
}