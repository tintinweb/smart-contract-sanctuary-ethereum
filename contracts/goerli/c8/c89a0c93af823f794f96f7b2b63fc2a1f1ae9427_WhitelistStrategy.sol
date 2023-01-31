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

contract WhitelistStrategy is IVotingStrategy {
    struct Member {
        address addy;
        uint256 vp;
    }

    /**
     * @notice  Binary search through `members` to find the voting power of `voterAddress`
     * @param   voterAddress  The voter address
     * @param   params  The list of members. Needs to be sorted in ascending `addy` order
     * @return  uint256  The voting power of `voterAddress` if it exists: else 0
     */
    function _getVotingPower(address voterAddress, bytes calldata params) internal returns (uint256) {
        Member[] memory members = abi.decode(params, (Member[]));

        uint256 high = members.length - 1;
        uint256 low = 0;
        uint256 mid;
        address currentAddress;

        while (low < high) {
            mid = (high + low) / 2; // Expecting high and low to never overflow
            currentAddress = members[mid].addy;

            if (currentAddress < voterAddress) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        if (high > members.length) {
            return (0);
        } else if (members[high].addy == voterAddress) {
            return (members[high].vp);
        } else {
            return (0);
        }
    }

    function getVotingPower(
        uint32 /* timestamp */,
        address voterAddress,
        bytes calldata params, // Need to be sorted by ascending `addy`s
        bytes calldata /* userParams */
    ) external override returns (uint256) {
        return _getVotingPower(voterAddress, params);
    }
}