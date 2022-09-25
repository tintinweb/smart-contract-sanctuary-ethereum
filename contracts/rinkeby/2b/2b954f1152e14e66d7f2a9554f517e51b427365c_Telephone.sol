// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Telephone {
    address public owner;

    function attack(address _contract, address _myAddress) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("changeOwner(address)", _myAddress)
        );
    }
}