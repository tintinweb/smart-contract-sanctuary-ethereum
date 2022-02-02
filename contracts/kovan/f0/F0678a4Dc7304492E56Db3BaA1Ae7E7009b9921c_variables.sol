/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract variables {
    uint256 public a;
    string public b;
    uint256[] public c;
    string[] public d;

    function setA(uint256 _a) public {
            a = _a;
    }

    function setB(string memory _b) public {
            b = _b;
    }

    function setC(uint256 _value) public {
            c.push(_value);
    }

    function setD(string memory _value) public {
            d.push(_value);
    }




}