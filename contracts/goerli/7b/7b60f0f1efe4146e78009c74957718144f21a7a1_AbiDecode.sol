/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract AbiDecode {
    struct MyStruct {
        string name;
        uint[2] nums;
    }

    event Encoded(bytes);
    event Decoded(uint, address, uint[], MyStruct);

    function encode(
        uint x,
        address addr,
        uint[] calldata arr,
        MyStruct calldata myStruct
    ) external returns (bytes memory) {
        emit Encoded(abi.encode(x, addr, arr, myStruct));
        return abi.encode(x, addr, arr, myStruct);
    }

    function decode(bytes calldata data)
        external
        returns (
            uint x,
            address addr,
            uint[] memory arr,
            MyStruct memory myStruct
        )
    {
        // (uint x, address addr, uint[] memory arr, MyStruct myStruct) = ...
        (x, addr, arr, myStruct) = abi.decode(data, (uint, address, uint[], MyStruct));
        emit Decoded(x, addr, arr, myStruct);
    }
}