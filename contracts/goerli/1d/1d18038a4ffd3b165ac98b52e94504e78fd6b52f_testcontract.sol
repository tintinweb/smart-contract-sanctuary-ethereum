/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract testcontract {
    uint256 number = 555;

    function getNumber() external view returns(uint256) {
        return number;
    }

}