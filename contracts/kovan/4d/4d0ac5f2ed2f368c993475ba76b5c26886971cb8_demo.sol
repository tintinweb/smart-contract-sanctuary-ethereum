/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract demo {
    string[] public student = ['Nikhil', 'Nirav', 'Akash'];

    function mem() public view {
        string[] memory s1 = student;
        s1[0] = 'Nk';
    }

    function sto() public {
        string[] storage s1 = student;
        s1[0] = 'Nk';
    }
}