/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract what {
    mapping(uint256 => uint256) justMapping;
    function set(uint256 _key, uint256 _value) external {
        justMapping[_key] = _value;
    }
    function get(uint256 _x) external view returns(uint256) {
        return justMapping[_x];
    }
}