/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "forge-std/console2.sol";

contract HelloGelato {
    uint256 public counter;

    function isUnder10() external view returns (bool) {
        return (counter < 10);
    }

    function increment() external {
        counter++;
    }
}