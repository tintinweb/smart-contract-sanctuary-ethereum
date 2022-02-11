/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract FirstContract {

    uint256 public value1;
    uint256 public value2;

    function setValues(uint256 _value1, uint256 _value2) public {
        value1 = _value1;
        value2 = _value2;
    }

    function getSum() public view returns(uint256) {
        return value1 + value2;
    }

}