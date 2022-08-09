/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fund {
    uint public value;
    address[] funders;
    mapping(address => bool) mfunders;

    constructor(address[] memory _funders) {
        for (uint i = 0; i < _funders.length; i++) {
            funders.push(_funders[i]);
            mfunders[_funders[i]] = true;
        }
    }

    function exists1(address addr) public view returns (bool) {
        for (uint i = 0; i < funders.length; i++) {
            if (addr == funders[i]) return true;
        }
        return false;
    }

    function exists2(address addr) public view returns (bool) {
        address[] memory _funders = funders;
        for (uint i = 0; i < _funders.length; i++) {
            if (addr == _funders[i]) return true;
        }
        return false;
    }

    function exists3(address addr) public view returns (bool) {
        return mfunders[addr];
    }

    function set1() public {
        value = 1;
        exists1(0x97CB6e0F77B1f5c2A9F3724f9Cb59e89A6555cc7);
    }

    function set2() public {
        value = 2;
        exists1(0x97CB6e0F77B1f5c2A9F3724f9Cb59e89A6555cc7);
    }

    function set3() public {
        value = 3;
        exists1(0x97CB6e0F77B1f5c2A9F3724f9Cb59e89A6555cc7);
    }
}