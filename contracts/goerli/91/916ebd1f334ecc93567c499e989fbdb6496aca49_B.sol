// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './4_MarkTest.sol';

contract B {
    function toSetData(MarkTest a,uint256 _data) public {
        a.store(_data);
    }

    function toGetData(MarkTest a) public view returns(uint256) {
        return a.retrieve();
    }
}