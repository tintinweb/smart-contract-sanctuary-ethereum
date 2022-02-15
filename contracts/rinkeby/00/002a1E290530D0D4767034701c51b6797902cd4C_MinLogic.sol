/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract MinLogic {

    address public someAddress = 0x661a3b8a02E70e3b4E0623C3673e78F0C6A202DD;

    event ValueChanged(address prevValue, address newValue);

    function initialize() external {
        emit ValueChanged(someAddress, address(0));
    }

    function setAddress(address newValue) external {
        someAddress = newValue;
        emit ValueChanged(someAddress, newValue);
    }
}