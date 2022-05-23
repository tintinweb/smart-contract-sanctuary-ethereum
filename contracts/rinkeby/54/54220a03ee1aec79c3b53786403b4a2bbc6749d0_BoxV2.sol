/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function storeV2() public {
        value += 6;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

}