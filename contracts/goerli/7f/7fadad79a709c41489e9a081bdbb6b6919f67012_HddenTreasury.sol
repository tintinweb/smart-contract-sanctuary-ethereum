/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.9;

contract HddenTreasury {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;
    constructor(address admin_, uint256 delay_) {
        require(delay_ >= MINIMUM_DELAY, 'HddenTreasury::constructor: Delay must exceed minimum delay.');
        require(delay_ <= MAXIMUM_DELAY, 'HddenTreasury::setDelay: Delay must not exceed maximum delay.');

        admin = admin_;
        delay = delay_;
    }
    function setDelay(uint256 delay_) public {
        require(msg.sender == address(this), 'HddenTreasury::setDelay: Call must come from HddenTreasury.');
        require(delay_ >= MINIMUM_DELAY, 'HddenTreasury::setDelay: Delay must exceed minimum delay.');
        require(delay_ <= MAXIMUM_DELAY, 'HddenTreasury::setDelay: Delay must not exceed maximum delay.');
        delay = delay_;

        emit NewDelay(delay);
    }
    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, 'HddenTreasury::acceptAdmin: Call must come from pendingAdmin.');
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }
    function setPendingAdmin(address pendingAdmin_) public {
        require(
            msg.sender == address(this),
            'HddenTreasury::setPendingAdmin: Call must come from HddenTreasury.'
        );
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, 'HddenTreasury::queueTransaction: Call must come from admin.');
        require(
            eta >= getBlockTimestamp() + delay,
            'HddenTreasury::queueTransaction: Estimated execution block must satisfy delay.'
        );

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
        require(msg.sender == admin, 'HddenTreasury::cancelTransaction: Call must come from admin.');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction( address target, uint256 value, string memory signature, bytes memory data, uint256 eta ) public returns (bytes memory) {
        require(msg.sender == admin, 'HddenTreasury::executeTransaction: Call must come from admin.');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "HddenTreasury::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "HddenTreasury::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta + GRACE_PERIOD, 'HddenTreasury::executeTransaction: Transaction is stale.');

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, 'HddenTreasury::executeTransaction: Transaction execution reverted.');

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    receive() external payable {}

    fallback() external payable {}
}