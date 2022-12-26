// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract A {
    uint[] nums;

    function getLength() public view returns(uint){
        return nums.length;
    }

    function pushNums(uint _a) public {
        nums.push(_a);
    }

    function returnBigger(uint _a, uint _b) public pure returns(uint) {
        if (_a > _b) {
            return _a;
        } else if (_a < _b) {
            return _b;
        }
        return _a;
    }
}