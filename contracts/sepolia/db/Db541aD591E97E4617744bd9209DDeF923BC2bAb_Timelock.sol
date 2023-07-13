// SPDX-License-Identifier: NONE

pragma solidity ^0.8.9;

contract Timelock {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ValueReceived(address user, uint amount);

    uint public constant GRACE_PERIOD = 14 days;
    // uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MINIMUM_DELAY = 0; // For Demo
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    /**
     * @notice Construct a new TimeLock contract
     * @param admin_ - contract admin
     * @param delay_ - delay before successful proposal
     **/
    constructor(address admin_, uint delay_) {
        require(
            delay_ >= MINIMUM_DELAY,
            "Timelock::constructor: Delay must exceed minimum delay."
        );
        require(
            delay_ <= MAXIMUM_DELAY,
            "Timelock::constructor: Delay must not exceed maximum delay."
        );

        admin = admin_;
        delay = delay_;
    }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    function setDelay(uint delay_) public {
        require(
            msg.sender == address(this),
            "Timelock::setDelay: Call must come from Timelock."
        );
        require(
            delay_ >= MINIMUM_DELAY,
            "Timelock::setDelay: Delay must exceed minimum delay."
        );
        require(
            delay_ <= MAXIMUM_DELAY,
            "Timelock::setDelay: Delay must not exceed maximum delay."
        );
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin,
            "Timelock::acceptAdmin: Call must come from pendingAdmin."
        );
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        require(
            msg.sender == admin,
            "Timelock::setPendingAdmin: Call must come from Timelock."
        ); // for demo
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target_,
        uint value_,
        string memory signature_,
        bytes memory data_,
        uint eta_
    ) public returns (bytes32) {
        require(
            msg.sender == admin,
            "Timelock::queueTransaction: Call must come from admin."
        );
        require(
            eta_ >= getBlockTimestamp() + delay,
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(target_, value_, signature_, data_, eta_)
        );
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target_, value_, signature_, data_, eta_);
        return txHash;
    }

    function cancelTransaction(
        address target_,
        uint value_,
        string memory signature_,
        bytes memory data_,
        uint eta_
    ) public {
        require(
            msg.sender == admin,
            "Timelock::cancelTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target_, value_, signature_, data_, eta_)
        );
        queuedTransactions[txHash] = false;

        emit CancelTransaction(
            txHash,
            target_,
            value_,
            signature_,
            data_,
            eta_
        );
    }

    function executeTransaction(
        address target_,
        uint value_,
        string memory signature_,
        bytes memory data_,
        uint eta_
    ) public payable returns (bytes memory) {
        require(
            msg.sender == admin,
            "Timelock::executeTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target_, value_, signature_, data_, eta_)
        );
        require(
            queuedTransactions[txHash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            getBlockTimestamp() >= eta_,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta_ + GRACE_PERIOD,
            "Timelock::executeTransaction: Transaction is stale."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature_).length == 0) {
            callData = data_;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature_))),
                data_
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target_.call{value: value_}(
            callData
        );
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );

        emit ExecuteTransaction(
            txHash,
            target_,
            value_,
            signature_,
            data_,
            eta_
        );

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}