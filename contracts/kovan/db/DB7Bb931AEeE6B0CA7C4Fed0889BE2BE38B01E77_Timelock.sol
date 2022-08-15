/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// File: contracts\helpers\timelock\interfaces\ITimelock.sol
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

interface ITimelock {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event NewConfig(
        uint256 indexed gracePeriod,
        uint256 indexed minimumDelay,
        uint256 indexed maximumDelay
    );
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

    function setConfig(
        uint256 _gracePeriod,
        uint256 _minimumDelay,
        uint256 _maximumDelay
    ) external;

    function setDelay(uint256 delay_) external;

    function acceptAdmin() external;
    function setPendingAdmin(address pendingAdmin_) external;
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external;
}

// File: contracts\helpers\timelock\Timelock.sol


pragma solidity ^0.8.3;
contract Timelock is ITimelock {

    modifier isAdmin() {
        require(msg.sender == admin, "Call must come from admin");
        _;
    }

    modifier isSelfCall() {
        require(
            msg.sender == address(this),
            "Call must come from this contract"
        );
        _;
    }

    uint256 public gracePeriod = 14 days;
    uint256 public minimumDelay = 1;
    uint256 public maximumDelay = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(address _admin, uint256 _delay) {
        require(_delay >= minimumDelay, "Delay must exceed minimum delay");
        require(_delay <= maximumDelay, "Delay must not exceed maximum delay");

        admin = _admin;
        delay = _delay;
    }

    function setConfig(
        uint256 _gracePeriod,
        uint256 _minimumDelay,
        uint256 _maximumDelay
    ) external override isSelfCall {
        gracePeriod = _gracePeriod;
        minimumDelay = _minimumDelay;
        maximumDelay = _maximumDelay;
        emit NewConfig(gracePeriod, minimumDelay, maximumDelay);
    }

    function setDelay(uint256 delay_) external override isSelfCall {
        require(delay_ >= minimumDelay, "Delay must exceed minimum delay");
        require(delay_ <= maximumDelay, "Delay must not exceed maximum delay");
        delay = delay_;
        emit NewDelay(delay);
    }

    function acceptAdmin() public override {
        require(
            msg.sender == pendingAdmin,
            "Call must come from pendingAdmin."
        );
        admin = msg.sender;
        pendingAdmin = address(0);
        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) external override isSelfCall {
        pendingAdmin = pendingAdmin_;
        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external override isAdmin returns (bytes32) {
        require(
            eta >= getBlockTimestamp() + delay,
            "Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
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
    ) external override isAdmin {

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable isAdmin returns (bytes memory) {
        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        require(queuedTransactions[txHash], "Transaction hasn't been queued.");
        require(
            getBlockTimestamp() >= eta,
            "Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta + gracePeriod,
            "Transaction is stale."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(success, "Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}