/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract A {
    uint public a; 
    function call_A(uint _a) public {
        a = _a;
    }
}

contract B {
    function call_A_A(uint _a, address _A) public {
        A(_A).call_A(_a);
    }
}

contract C {
    function call_B_A_A(uint _a, address _A, address _B) public {
        B(_B).call_A_A(_a, _A);
    }
}