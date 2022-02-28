/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract Test {
    string private student;
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }
    function getStudent() public view onlyMe returns(string memory) {
        return student;
    }

    function addStudent(string memory st) external {
        student = st;
    }

    function destroy() external onlyMe {
        student = "";
    }

    modifier onlyMe {
        require(msg.sender == _owner, "You cannot access");
        _;
    }
}