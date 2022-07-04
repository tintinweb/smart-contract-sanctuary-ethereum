/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

contract VIPChecker {
    uint32 triedNumber;

    modifier counter() {
        triedNumber++;
        _;
    }

    function check(bytes32 key) counter public {
        uint16 mask = uint16(uint160 (msg.sender) >> 144);
        require (mask == 0, "You are not vip");
        uint160 shortKey = uint160 (uint256(key));
        require(uint160(msg.sender) & shortKey == 0x0, "Not the right key");
        payable(msg.sender). transfer(address(this). balance);
    }

    // function depositBy0wner() payable onlyOwner public {
    // }

}