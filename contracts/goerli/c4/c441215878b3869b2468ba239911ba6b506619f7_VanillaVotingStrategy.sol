// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/// @title The interface for voting strategies
interface IVotingStrategy {
    /// @notice Get the voting power of an address at a given timestamp
    /// @param timestamp The snapshot timestamp to get the voting power at
    /// If a particular voting strategy requires a  block number instead of a timestamp,
    /// the strategy should resolve the timestamp to a block number.
    /// @param voterAddress The address to get the voting power of
    /// @param params The global parameters that can configure the voting strategy for a particular space
    /// @param userParams The user parameters that can be used in the voting strategy computation
    /// @return votingPower The voting power of the address at the given timestamp
    /// If there is no voting power, return 0.
    function getVotingPower(
        uint32 timestamp,
        address voterAddress,
        bytes calldata params,
        bytes calldata userParams
    ) external returns (uint256 votingPower);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IVotingStrategy.sol";

contract VanillaVotingStrategy is IVotingStrategy {
    function getVotingPower(
        uint32 /* timestamp */,
        address /* voterAddress */,
        bytes calldata /* params */,
        bytes calldata /* userParams */
    ) external pure override returns (uint256) {
        return 1;
    }
}