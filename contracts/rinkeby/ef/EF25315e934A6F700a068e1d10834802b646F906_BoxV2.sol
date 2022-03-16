// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract BoxV2 {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store (uint256 newValue) public {

        value = newValue;
        emit ValueChanged(newValue);
    }

    // function裡的variables, 需要與function裡的input做對應, 或最上面的variable做對應
    function retrieve() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);

    }

}