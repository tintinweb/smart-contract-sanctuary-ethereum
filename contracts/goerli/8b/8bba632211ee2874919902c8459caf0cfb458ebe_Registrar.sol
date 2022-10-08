/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Registrar {

    uint256 public min_cost = 0.02 ether;
    uint256 public base_cost = 0.1 ether;

    event Foo(address indexed msgSender, address indexed owner, string indexed name, uint256 value);

    function register(
        address owner,
        string memory name
    ) external payable returns (bytes32) {

        emit Foo(msg.sender, owner, name, msg.value);
        sendValue(payable(msg.sender), msg.value);
        return (keccak256(abi.encodePacked(name)));
    }

    function getCost(string memory name) public view returns (uint256 cost) {
        bytes memory name_bytes = bytes(name);
        uint256 len = name_bytes.length;
        if (len >= 6) {
            cost = min_cost;
        } else {
            cost = (10**(5-len)) * base_cost;
        }

        return cost;
    }

    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }
}