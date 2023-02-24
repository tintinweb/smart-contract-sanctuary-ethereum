// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Send {
    function sends(address[] memory toList, uint256 _amount) external payable {
        for (uint i = 0; i < toList.length; i++) {
          payable(toList[i]).transfer(_amount);
        }
    }
}