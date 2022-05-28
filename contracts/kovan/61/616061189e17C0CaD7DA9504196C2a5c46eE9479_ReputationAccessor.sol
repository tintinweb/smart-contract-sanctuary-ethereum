pragma solidity ^0.8.7;

interface IAPIConsumer {
    function requestReputationData(string memory) external returns (bytes32 requestId);

    function reputationData() external view returns (uint152);
}

contract ReputationAccessor {
    // Network: local
    // APIConsumer contract: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
    function requestReputationScore(
        address _api_consumer,
        string memory _query
    ) public returns (bytes32) {
        return IAPIConsumer(_api_consumer).requestReputationData(_query);
    }

    function getReputationScore(address _api_consumer) public view returns (uint152) {
        return IAPIConsumer(_api_consumer).reputationData();
    }
}