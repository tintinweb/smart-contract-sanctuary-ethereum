/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */

contract VerifyContractTestV2 {

    function helloWorld() public returns (string memory){
        return "Hello World v5";
    }
}

pragma solidity ^0.8.0;

contract VerifyContractTestV3 {
    function helloWorld() public returns (string memory){
        return "Hello World v6";
    }
}