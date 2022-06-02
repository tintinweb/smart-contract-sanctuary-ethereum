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
     * @param target 目标合约 value 交易value signature 方法签名 data 编码好的 calldata eta 解锁此方法的时间戳
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
        // 计算交易标识
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        // 标记为pending状态
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
        // 使用同样的方式计算交易标识
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        // 更改状态
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
        // 使用同样的方式计算交易标识
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        // 检查是否在队列中
        require(queuedTransactions[txHash], "GameLootTimelocker: Transaction hasn't been queued.");
        // 是否已经解锁
        require(getBlockTimestamp() >= eta, "GameLootTimelocker: Transaction hasn't surpassed time lock.");
        // 是否已经超时
        require(getBlockTimestamp() <= eta + GRACE_PERIOD, "GameLootTimelocker: Transaction is stale.");
        queuedTransactions[txHash] = false;
        bytes memory callData;
        // 提供两个选项，可以在外部直接计算好callData，也可以直接在合约里计算
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            // 生成callData
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // 外部调用
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        // 检查执行状态
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