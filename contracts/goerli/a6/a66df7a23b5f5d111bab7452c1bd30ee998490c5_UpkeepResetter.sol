pragma solidity 0.7.6;

contract UpkeepResetter {

    function _ResetConsumerBenchmark(address upkeepAddress, uint256 testRange, uint256 averageEligibilityCadence, uint256 firstEligibleBuffer) private {
        KeeperConsumerBenchmark consumer = KeeperConsumerBenchmark(upkeepAddress);
        consumer.setFirstEligibleBuffer(firstEligibleBuffer);
        consumer.setSpread(testRange, averageEligibilityCadence);
        consumer.reset();
    }
    

    function ResetManyConsumerBenchmark(address[] memory upkeepAddresses, uint256 testRange, uint256 averageEligibilityCadence, uint256 firstEligibleBuffer) external {
        for (uint i=0; i<upkeepAddresses.length; i++) {
            _ResetConsumerBenchmark(upkeepAddresses[i], testRange, averageEligibilityCadence, firstEligibleBuffer);
        }
    }

    

}

interface KeeperConsumerBenchmark {
    function reset() external;
    function setSpread(uint256 _newTestRange, uint256 _newAverageEligibilityCadence) external;
    function setFirstEligibleBuffer(uint256 _firstEligibleBuffer) external;
}