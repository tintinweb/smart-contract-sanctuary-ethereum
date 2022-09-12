// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    event NewMsg(string _text);
    string public newText;
    bool public flag;

    function test(string memory _text) external shutDown {
        newText = _text;

        emit NewMsg(_text);
    }

    function pause() external {
        flag = false;
    }

    function unpause() external {
        flag = true;
    }

    modifier shutDown(){
        require(flag, " shutdown");
        _;
    }
}