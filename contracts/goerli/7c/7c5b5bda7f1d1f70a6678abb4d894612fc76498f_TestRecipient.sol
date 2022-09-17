// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

contract TestRecipient is IMessageRecipient {

    event ReceivedMessage(
        uint32 indexed origin,
        bytes32 indexed sender,
        string message
    );

    // solhint-disable-next-line payable-fallback
    fallback() external {
        revert("Fallback");
    }

    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata data
    ) external override {
        emit ReceivedMessage(origin, sender, string(data));
    }

}