/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

// import "hardhat/console.sol";

contract SimpleStorage {
    uint256 storedData;

    constructor(uint256 _storedData) {
        // console.log("Deployed by: ", msg.sender);
        // console.log("Deployed with value: %s", _storedData);
        storedData = _storedData;
    }

    function set(uint256 x) public {
        // console.log("Set value to: %s", x);
        storedData = x;
    }

    function get() public view returns (uint256) {
        // console.log("Retrieved value: %s", storedData);
        return storedData;
    }
}