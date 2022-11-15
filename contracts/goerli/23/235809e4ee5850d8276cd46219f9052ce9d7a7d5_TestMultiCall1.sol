/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract TestMultiCall1 {
    struct MyStruct {
        uint num1;
        uint timestamp;
    }

    event Log(address indexed sender, MyStruct message);

    function test(uint _i) external returns (MyStruct memory) {
        MyStruct memory myStruct = MyStruct(_i, block.timestamp);
        emit Log(msg.sender, myStruct);
        return myStruct;
    }

    function getData(uint _i) external pure returns (bytes memory) {
        return abi.encodeWithSelector(this.test.selector, _i);
    }

    function decodeData(bytes calldata data) external pure returns (uint){
        return abi.decode(data[4 :], (uint));
    }
}