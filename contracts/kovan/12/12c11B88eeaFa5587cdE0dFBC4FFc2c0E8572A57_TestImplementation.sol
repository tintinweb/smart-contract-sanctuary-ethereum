/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

contract TestImplementation {
    uint256 amount;
    address recipient;
    uint256 newExchangeRate;

    event Slashed(uint256 amount, address recipient, uint256 newExchangeRate);

    function emitSlashed() external {
        emit Slashed(amount, recipient, newExchangeRate);
    }
}