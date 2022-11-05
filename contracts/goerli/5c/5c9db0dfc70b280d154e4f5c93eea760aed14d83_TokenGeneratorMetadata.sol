/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title TokenGeneratorMetadata
 * @author Create My Token (lgctoken.com)
 * @dev Implementation of the TokenGeneratorMetadata
 */
contract TokenGeneratorMetadata {
    string public constant _GENERATOR = "https://www.lgctoken.com/";
    string public constant _VERSION = "v2.0.3";

    function generator() public pure returns (string memory) {
        return _GENERATOR;
    }

    function version() public pure returns (string memory) {
        return _VERSION;
    }
}