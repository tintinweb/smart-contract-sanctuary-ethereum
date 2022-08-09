/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fund {
    address[] funders;
    mapping(address => bool) mfunders;

    constructor(address[] memory _funders) {
        for (uint i = 0; i < _funders.length; i++) {
            funders.push(_funders[i]);
            mfunders[_funders[i]] = true;
        }
    }

    function exists(address addr) public view returns (bool) {
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

    function mexists(address addr) public view returns (bool) {
        return mfunders[addr];
    }
}