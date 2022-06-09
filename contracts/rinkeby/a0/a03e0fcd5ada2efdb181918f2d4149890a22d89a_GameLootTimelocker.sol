/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GameLootTimelocker {
    uint256 public constant GRACE_PERIOD = 14 days;

    address public admin;
    uint256 public delay;

    mapping (bytes32 => bool) queuedTransactions;

    constructor(uint256 delay_){
        admin = msg.sender;
        delay = delay_;
    }

    event NewAdmin(address indexed newAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    /**
     * @dev Add new transaction to queue.
     */
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "GameLootTimelocker: Call must come from admin.");
        require(eta >= getBlockTimestamp() + delay, "GameLootTimelocker: Estimated execution block must satisfy delay.");
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;
        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "GameLootTimelocker: Call must come from admin.");
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;
        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "GameLootTimelocker: Call must come from admin.");
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "GameLootTimelocker: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "GameLootTimelocker: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta + GRACE_PERIOD, "GameLootTimelocker: Transaction is stale.");
        queuedTransactions[txHash] = false;
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string(returnData));
        emit ExecuteTransaction(txHash, target, value, signature, data, eta);
        return returnData;
    }

    function setAdmin(address pendingAdmin_) public {
        require(msg.sender == admin, "GameLootTimelocker: Call must come from admin.");
        admin = pendingAdmin_;

        emit NewAdmin(admin);
    }

    function setDelay(uint256 delay_) public{
        require(msg.sender == admin, "GameLootTimelocker: Call must come from admin.");
        delay = delay_;
        emit NewDelay(delay);
    }

    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}