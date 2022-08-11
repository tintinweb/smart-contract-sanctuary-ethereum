/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract SDC {
    address payable private sdcAddress;

    constructor() {
        sdcAddress = payable(0x1B0911c3670e698bcA6977b27B3c8d369dddA5Dd);
    }

    function setAddressToSDC(string memory json) external payable {
        sdcAddress.transfer(msg.value);
        json;
    }

    function setAddressToAddress(address payable to) external payable {
        to.transfer(msg.value);
    }

    function getAddressBalance(address _address) external view returns(uint) {
        return _address.balance;
    }
}