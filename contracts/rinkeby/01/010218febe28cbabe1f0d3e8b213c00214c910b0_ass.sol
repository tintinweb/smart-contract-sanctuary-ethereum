// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//0x010218febe28cbabe1f0d3e8b213c00214c910b0
contract ass {
    modifier isNotContract(address _a) {
        uint size;
        assembly {
            size := extcodesize(_a)
        }
            require(size == 0);
            _;
    }
}