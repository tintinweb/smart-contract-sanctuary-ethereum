// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.17;

contract Anonymous {
    address private immutable j;
    string private x;
    constructor(){ j = msg.sender;}
    modifier onlyGod{require(msg.sender == j, "Sorry, you are not god :(");
        _;
    }
    function fuck(string calldata y) public onlyGod {x = y;}
    function sex() public view onlyGod returns(string memory){return x;}
}