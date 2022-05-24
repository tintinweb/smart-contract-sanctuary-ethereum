/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;   

 contract testABC {
        function B(uint a, uint b) public returns (uint) {
            test T = test(0xD31d4155CFf3C0337C5C36a5B5DA67729f8A67A3);
            return T.A (a,b);          
            }
}

contract test {
    function A(uint a, uint b) public returns (uint) {
        return (a+b);
    }
        
}