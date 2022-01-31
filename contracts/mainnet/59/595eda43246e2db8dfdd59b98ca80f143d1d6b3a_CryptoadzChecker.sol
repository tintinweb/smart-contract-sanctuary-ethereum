// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./CryptoadzInterface.sol";

contract CryptoadzChecker {
    CryptoadzInterface private cryptoadz = CryptoadzInterface(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6);

    function isToadHolder(address _address) public view returns(bool) {
      return cryptoadz.balanceOf(_address) > 0;
    }
}