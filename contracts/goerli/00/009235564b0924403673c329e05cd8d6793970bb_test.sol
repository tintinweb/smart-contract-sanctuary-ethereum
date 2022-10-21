/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract test {

    mapping(uint => uint) public a;
    mapping(uint => uint) public b;
    mapping(uint => uint) public c;

    /**
     @notice Bullshit contract.
     @dev STFU and do your work bro.
     @param _a, first array.
     @param _b, Second array.
     @param _c, third array.
     @param _d, fourth array.
     */
     
    function abc(uint[] memory _a, uint[] memory _b, uint[] memory _c, uint[] memory _d) public {
        for(uint i = 0; i < _a.length; i++) {
            a[_d[i]] = _a[i];
            b[_d[i]] = _b[i];
            c[_d[i]] = _c[i];

        }
    }

}