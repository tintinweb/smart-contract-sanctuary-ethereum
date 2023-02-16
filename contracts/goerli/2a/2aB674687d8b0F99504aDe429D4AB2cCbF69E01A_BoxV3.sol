/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/Box.sol

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint256 private _value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    // Stores a new value in the contract
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value;
    }
}

pragma solidity ^0.8.0;

contract BoxV3 is Box {
    uint256 private _value;
    
    function decrement() public {
        _value = _value - 1;
    }
}