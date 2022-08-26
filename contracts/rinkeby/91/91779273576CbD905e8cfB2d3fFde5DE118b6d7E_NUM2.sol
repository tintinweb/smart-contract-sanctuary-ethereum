// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract NUM2 {
    uint num;

    function update(uint _num) public {
        num = _num;
    }

    function get() public view returns(uint){
        return num;
    }

    function increment() public {
        num = num +1;
    }

}

// 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9