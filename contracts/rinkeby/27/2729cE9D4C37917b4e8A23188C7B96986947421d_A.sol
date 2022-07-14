/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract A {

    /**
   * @dev This call is used to get the overall result of the contract.
   */
    function result() public pure returns(bool) {
        return false;
    }

    /**
    * @dev This call is used to get one result for the contract.
    */
    function getOne() public pure returns(bool) {
        bool r = result();
        return r;
    }
}