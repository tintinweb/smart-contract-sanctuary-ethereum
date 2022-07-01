// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract temp{
    string public tempMess;
    function setTempMess(string memory _tempMess)public {
        tempMess=_tempMess;
    }
}