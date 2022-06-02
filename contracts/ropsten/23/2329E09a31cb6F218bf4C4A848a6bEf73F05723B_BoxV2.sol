/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

contract BoxV2 {
    uint256 public value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    // function initialize(uint256 _value) public {
    //     value = _value;
    // }

    function increase() external {
        value += 1;
        emit ValueChanged(value);
    }
}