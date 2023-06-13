// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

contract StructArrayContract {
    struct Struct {
        uint256 a;
        uint256 b;
        bool c;
    }

    event StructCalled(uint256 a, uint256 b, bool c);

    function run(Struct[] memory structs) public {
        uint256 length = structs.length;
        for (uint256 i = 0; i < length; ) {
            emit StructCalled(structs[i].a, structs[i].b, structs[i].c);

            unchecked {
                i++;
            }
        }
    }
}