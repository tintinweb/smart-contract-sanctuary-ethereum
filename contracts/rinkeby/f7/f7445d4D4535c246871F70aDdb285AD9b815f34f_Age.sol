// SPDX-License-Indentifier: MIT

pragma solidity 0.8.13;

contract Age {
    uint public myAge;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function startkaro(uint _val) external {
        myAge = _val;
    }

}