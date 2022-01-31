/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.8.7;

contract ChainlinkConsumer {
    uint256 constant private PHASE_OFFSET = 64;
    
    function addPhase(uint16 _phase, uint64 _originalId) public view returns (uint80)
    {
        return uint80(uint256(_phase) << PHASE_OFFSET | _originalId);
    }

    function parseIds(uint256 _roundId) public view returns (uint16, uint64)
    {
        uint16 phaseId = uint16(_roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(_roundId);

        return (phaseId, aggregatorRoundId);
    }
}