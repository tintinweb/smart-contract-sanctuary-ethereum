/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Array {
    uint[] public arr;
    uint[] public arr2 = [1,2,3];

    uint[10] public fixedArr;

    function get(uint _i) public view returns (uint) {
        return arr[_i];
    }

    function getArray() public view returns (uint[] memory) {
        return arr;
    }
    
    function push(uint _i) public {
        arr.push(_i);
    }

    function pop() public {
        arr.pop();
    }

    function getLength() public view returns (uint) {
        return arr.length;
    }

    function remove(uint _index) public {
        delete arr[_index];
    }

    function examples() external pure returns (uint[] memory) {
        uint[] memory a = new uint[](10);
        return a;
    }
}