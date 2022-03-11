/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestArray {

    uint[] public arr;

    function setter(uint _role) public {
        arr.push(_role);
    }

    function getter() public view returns(uint[] memory) {
        return arr;
    }

    function remove(uint _index) public {
        delete arr[_index];
    }
}