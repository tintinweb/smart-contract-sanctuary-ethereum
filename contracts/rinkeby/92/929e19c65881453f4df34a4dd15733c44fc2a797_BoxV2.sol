/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.14;


// This is the main building block for smart contracts.
contract BoxV2 {

    uint256 private _value;

    event ValueChanged(uint256 value);

    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(_value);
    }

    function retrieve() public view returns (uint256) {
        return _value;
    }
    
    function increament() public {
        _value =_value + 1;
        emit ValueChanged(_value);
    }
}