/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Convert {

    string public hi = "Hi from Remix";

    function bytesToUint(bytes32 _bytes) public pure returns(uint) {
        return uint(_bytes);
    }

    function getHi() public pure returns (string memory) {
        return "Hi";
    }

    function action() public {
        
    }

}