// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error ReceiveReverted();
error OnlyAdmin();

contract AMB {
    address admin;

    event Send(uint256 gas, uint256 value, address target, bytes data);
    event Receive(uint256 value, address target, bytes data);
    event NewAMB(address oldAdmin, address newAdmin);

    constructor() {
        admin = msg.sender;
    }

    function send(
        uint256 value,
        address target,
        bytes calldata data
    ) external payable {
        uint256 gas = msg.value - value;
        emit Send(gas, value, target, data);
    }

    function receiveMsg(
        uint256 value,
        address target,
        bytes calldata data
    ) external onlyAdmin returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{value: value}(
            data
        );
        if (!success) revert ReceiveReverted();
        emit Receive(value, target, data);
        return returnData;
    }

    // ADMIN
    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        address oldAdmin = admin;
        admin = _admin;
        emit NewAMB(oldAdmin, admin);
    }
}