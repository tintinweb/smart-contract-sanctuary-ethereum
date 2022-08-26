// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract NUM1 {
    uint num;

    function update(uint _num) public {
        num = _num;
    }

    function get() public view returns(uint){
        return num;
    }

}
// 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0