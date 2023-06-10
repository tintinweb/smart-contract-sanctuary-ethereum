// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.9 <0.9.0;

contract udo {
    string private localvar = "This is a beginning sample contract by udo";

    function getlocalvar() public view returns(string memory) {
        return localvar;
    }

    function setlocalvar(string memory localstr) public returns(bool) {
        localvar = localstr;
        return true;
    }
}