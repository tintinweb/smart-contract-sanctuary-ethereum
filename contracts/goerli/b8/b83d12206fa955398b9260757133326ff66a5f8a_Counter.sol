// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAMB {
    function send(
        uint256 value,
        address target,
        bytes calldata data
    ) external payable;
}

error AlreadyInitialized();
error OnlyAMB();

contract Counter {
    address AMB;
    uint256 public counter;
    uint8 initialized;
    address sendingCounter;
    address receivingCounter;

    function initialize(
        address _AMB,
        address _sendingCounter,
        address _receivingCounter
    ) public {
        if (initialized == 1) revert AlreadyInitialized();
        AMB = _AMB;
        sendingCounter = _sendingCounter;
        receivingCounter = _receivingCounter;
        initialized = 1;
    }

    function send() public payable {
        IAMB(AMB).send{value: msg.value}(
            0,
            receivingCounter,
            abi.encodePacked(bytes4(keccak256(bytes("increment()"))), "")
        );
    }

    function increment() public {
        if (msg.sender != AMB) revert OnlyAMB();
        counter++;
    }
}