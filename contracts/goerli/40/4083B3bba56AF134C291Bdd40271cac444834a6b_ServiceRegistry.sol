//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ServiceRegistry {
    mapping(bytes32 => uint256) public lastExecuted;
    mapping(address => bool) private trustedAddresses;
    mapping(bytes32 => address) private namedService;
    address public owner;

    uint256 public requiredDelay = 1800; // big enough that any power of miner over timestamp does not matter

    modifier validateInput(uint256 len) {
        require(msg.data.length == len, "registry/illegal-padding");
        _;
    }

    modifier delayedExecution() {
        bytes32 operationHash = keccak256(msg.data);
        uint256 reqDelay = requiredDelay;

        /* solhint-disable not-rely-on-time */
        if (lastExecuted[operationHash] == 0 && reqDelay > 0) {
            // not called before, scheduled for execution
            lastExecuted[operationHash] = block.timestamp;
            emit ChangeScheduled(msg.data, operationHash, block.timestamp + reqDelay);
        } else {
            require(
                block.timestamp - reqDelay > lastExecuted[operationHash],
                "registry/delay-too-small"
            );
            emit ChangeApplied(msg.data, block.timestamp);
            _;
            lastExecuted[operationHash] = 0;
        }
        /* solhint-enable not-rely-on-time */
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "registry/only-owner");
        _;
    }

    constructor(uint256 initialDelay) {
        require(initialDelay < type(uint256).max, "registry/risk-of-overflow");
        requiredDelay = initialDelay;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        owner = newOwner;
    }

    function changeRequiredDelay(uint256 newDelay)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        requiredDelay = newDelay;
    }

    function addTrustedAddress(address trustedAddress)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        trustedAddresses[trustedAddress] = true;
    }

    function removeTrustedAddress(address trustedAddress) external onlyOwner validateInput(36) {
        trustedAddresses[trustedAddress] = false;
    }

    function isTrusted(address testedAddress) external view returns (bool) {
        return trustedAddresses[testedAddress];
    }

    function getServiceNameHash(string memory name) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function addNamedService(bytes32 serviceNameHash, address serviceAddress)
        external
        onlyOwner
        validateInput(68)
        delayedExecution
    {
        require(namedService[serviceNameHash] == address(0), "registry/service-override");
        namedService[serviceNameHash] = serviceAddress;
    }

    function updateNamedService(bytes32 serviceNameHash, address serviceAddress)
        external
        onlyOwner
        validateInput(68)
        delayedExecution
    {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = serviceAddress;
    }

    function removeNamedService(bytes32 serviceNameHash) external onlyOwner validateInput(36) {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = address(0);
        emit RemoveApplied(serviceNameHash);
    }

    function getRegisteredService(string memory serviceName) external view returns (address) {
        return namedService[keccak256(abi.encodePacked(serviceName))];
    }

    function getServiceAddress(bytes32 serviceNameHash) external view returns (address) {
        return namedService[serviceNameHash];
    }

    function clearScheduledExecution(bytes32 scheduledExecution)
        external
        onlyOwner
        validateInput(36)
    {
        require(lastExecuted[scheduledExecution] > 0, "registry/execution-not-scheduled");
        lastExecuted[scheduledExecution] = 0;
        emit ChangeCancelled(scheduledExecution);
    }

    event ChangeScheduled(bytes data, bytes32 dataHash, uint256 firstPossibleExecutionTime);
    event ChangeCancelled(bytes32 data);
    event ChangeApplied(bytes data, uint256 firstPossibleExecutionTime);
    event RemoveApplied(bytes32 nameHash);
}