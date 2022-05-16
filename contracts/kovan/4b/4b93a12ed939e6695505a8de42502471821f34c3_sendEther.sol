/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract sendEther {
    uint public totalBalance;
    bytes public data;

    function transferEthTo(address _to) public payable {
        payable(_to).transfer(msg.value);
    }

    function sendEthTo(address payable _to) public payable {
        bool status = _to.send(msg.value);
        if (status) {
            totalBalance -= msg.value;
        }
    }

    function callEthTo(address payable _to) public payable {
        (bool status, bytes memory dataRe) = _to.call{value: msg.value}("");
        if (status) {
            totalBalance -= msg.value;
            data = dataRe;
        }
    }

    function deposit() public payable {
        totalBalance += msg.value;
    }

}