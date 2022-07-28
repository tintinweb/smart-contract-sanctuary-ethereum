// contracts/Test.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract Test {
    string constant public a = "a";
    string public b;
    uint public c;
    
    function setBC(string memory _b, uint _c) external {
        b = _b;
        c = _c;
    }
    function setB(string memory _b) external {
        b = _b;
    }

    function setC(uint _c) external {
        c = _c;
    }
}