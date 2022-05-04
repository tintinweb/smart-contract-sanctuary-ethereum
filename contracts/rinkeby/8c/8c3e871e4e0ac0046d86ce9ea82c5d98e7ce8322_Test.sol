/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Test {
    address public admin;

    address public impl;

    constructor() {
        admin = msg.sender;
        impl = 0xe4Cc45Bb5DBDA06dB6183E8bf016569f40497Aa5;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }    

    function getAdmin() external onlyAdmin returns (address) {
        return _admin();
    }

    function _admin() internal view returns (address) {
        return impl;
    }
}