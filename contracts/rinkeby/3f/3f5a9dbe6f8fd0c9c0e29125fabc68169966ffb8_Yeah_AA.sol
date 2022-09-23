/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Yeah_AA{

    uint a;

    string[] sarray;

    function pushString(string memory s) public{
        sarray.push(s);
    }

    function getString(uint _n) public view returns(string memory){
        return sarray[_n-1];
    }

    //마지막 요소  길이 -1
    function lastNuber() public view returns(uint){
        return sarray.length;
    }
}