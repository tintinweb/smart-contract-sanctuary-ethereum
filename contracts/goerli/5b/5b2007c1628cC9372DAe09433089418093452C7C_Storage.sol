// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Storage {
    string public a;
    string public b;
 
    function foo() public {
        // a 是 31 个字节，b 是 32 个字节(1 个字母占 1 个字节空间)
        a = 'abcabcabcabcabcabcabcabcabcabca';
        b = 'abcabcabcabcabcabcabcabcabcabcab';
    }
}