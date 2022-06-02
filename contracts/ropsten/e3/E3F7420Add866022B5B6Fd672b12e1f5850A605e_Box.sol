/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

contract Box {
    uint256 public value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    // constructor(uint _value) {
    //     value = _value;
    // }

    function initialize(uint256 _value) external {
        value = _value;
        emit ValueChanged(value);
    }
}