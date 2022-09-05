/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT 
 
pragma solidity 0.8.16; 
 
contract B { 
    uint internal a = type(uint).max;
    //uint m = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint[] public arr;
    
    function set() public {
        for(uint i = 0; i < a - 1; i++) {
            arr.push(i);
        }
    }

}