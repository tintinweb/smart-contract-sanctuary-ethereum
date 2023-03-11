// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

abstract contract MyAbstractContract {
    function myFunction() external virtual returns(uint8);
}

contract MyContract is MyAbstractContract {

    function myFunction() external override pure returns(uint8) {
        uint8 a = 10;
        return a;
    }
}