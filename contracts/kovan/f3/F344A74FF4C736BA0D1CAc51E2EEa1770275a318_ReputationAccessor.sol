pragma solidity ^0.8.7;

interface IAPIConsumer {
    function requestReputationData(bytes32, bytes32) external returns (bytes32 requestId);

    function reputationData() external view returns (uint152);
}

contract ReputationAccessor {
    // Network: local
    // APIConsumer contract: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
    function requestReputationScore(
        address _api_consumer,
        bytes32 _target_id,
        bytes32 _chain_type
    ) public returns (bytes32) {
        return IAPIConsumer(_api_consumer).requestReputationData(_target_id, _chain_type);
    }

    function getReputationScore(address _api_consumer) public view returns (uint152) {
        return IAPIConsumer(_api_consumer).reputationData();
    }
}