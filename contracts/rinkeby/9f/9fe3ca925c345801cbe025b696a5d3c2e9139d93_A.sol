/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 < 0.9.0;

contract A {
    uint lP = 0;
    uint hP = 0;
    uint lH = 0;
    uint hH = 0;
    
    function likeP() public returns(uint)   {
        lP += 1;
        return lP;
    }
    
    function hateP() public returns(uint)    {
        hP += 1;
        return hP;
    }

    function likeH() public returns(uint)    {
        lH += 1;
        return lH;
    }

    function hateH() public returns(uint)    {
        hH += 1;
        return hH;
    }
    function result() public view returns(uint, uint, uint, uint){
        return (lP, hP, lH, hH);
    }
}