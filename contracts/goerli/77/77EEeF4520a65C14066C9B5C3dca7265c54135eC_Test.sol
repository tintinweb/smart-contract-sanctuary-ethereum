/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Test {
    enum E {
        V1, V2, V3, V4
    }
    struct A {
        E a;
        uint256[] b;
        B[] c;
    }

    struct B {
        uint256 d;
        uint256 e;
    }

    function get(uint256 x) external pure returns (A memory) {
        uint256[] memory b = new uint256[](3);
        b[0] = 1;
        b[1] = 2;
        b[2] = 3;
        B[] memory c = new B[](3);
        c[0] = B(1, 2);
        c[1] = B(3, 4);
        c[2] = B(5, 6);
        return A(E.V3, b, c);
    }
}