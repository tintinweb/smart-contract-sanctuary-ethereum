// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract Iterate {
    uint256[] public vars;

    function addVars(uint256 amount) public {
        for (uint256 i = 0; i < amount; ++i) {
            vars.push(i);
        }
    }

    function length() public view returns (uint256) {
        return vars.length;
    }

    function read() public view returns (uint256 i) {
        uint256 len = length();
        for (i = 0; i < len; ++i) {
            if (i == len - 1) {
                return vars[i];
            }
        }
    }

}