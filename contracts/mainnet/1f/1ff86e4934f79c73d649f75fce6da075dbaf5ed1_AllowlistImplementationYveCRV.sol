/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract AllowlistImplementationYveCRV {
    function isCRV(address tokenAddress) public pure returns (bool) {
        return tokenAddress == 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function isYveCRV(address tokenAddress) public pure returns (bool) {
        return tokenAddress == 0xc5bDdf9843308380375a611c18B50Fb9341f502A;
    }
}