//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Bank {
    function deposit() public payable {

    }
}

contract Caller {
    address callee;
    constructor(address _callee) {
        callee = _callee;
    }

    function deposit() public payable {
        Bank(callee).deposit{value: msg.value}();
    }
}