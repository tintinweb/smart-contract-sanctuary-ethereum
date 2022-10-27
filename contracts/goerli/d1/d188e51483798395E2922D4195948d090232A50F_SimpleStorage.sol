// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 private age = 6;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => uint256) public AddressToAmountSended;

    function retrieve() public view returns (uint256) {
        return age;
    }

    function send_eth() public payable returns (uint256) {
        AddressToAmountSended[msg.sender] += msg.value;
        return uint256(msg.value);
    }

    function my_address() public view returns (address) {
        return owner;
    }

    function set_age(uint256 age_val) public returns (uint256) {
        age = age_val;
        return age;
    }
}