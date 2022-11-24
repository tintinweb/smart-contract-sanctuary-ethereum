/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract MyContract {
     mapping (address => uint256) favoriteNumber;

    function setMyNumber(uint256 _myNumber) public {
        favoriteNumber[msg.sender] = _myNumber;
    }

    function whatIsMyNumber() public view returns (uint256) {
        return favoriteNumber[msg.sender];
    }
    function get(address _addr) public view returns (uint256) {
        return favoriteNumber[_addr];
    }
}