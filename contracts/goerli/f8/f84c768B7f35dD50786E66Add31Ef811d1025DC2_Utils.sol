/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;

contract Utils {
    function convertUint256ToAddress (uint256 data) public pure returns (address)  {
        address res =  address(uint160(uint256(data)));
        return res;
    }
}