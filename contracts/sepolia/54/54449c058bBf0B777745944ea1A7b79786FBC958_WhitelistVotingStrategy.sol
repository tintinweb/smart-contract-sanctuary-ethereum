// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Voting Strategy Interface
interface IVotingStrategy {
    /// @notice Gets the voting power of an address at a given timestamp.
    /// @param timestamp The snapshot timestamp to get the voting power at. If a particular voting strategy
    ///                  requires a block number instead of a timestamp, the strategy should resolve the
    ///                  timestamp to a block number.
    /// @param voter The address to get the voting power of.
    /// @param params The global parameters that can configure the voting strategy for a particular Space.
    /// @param userParams The user parameters that can be used in the voting strategy computation.
    /// @return votingPower The voting power of the address at the given timestamp. If there is no voting power,
    ///                     return 0.
    function getVotingPower(
        uint32 timestamp,
        address voter,
        bytes calldata params,
        bytes calldata userParams
    ) external returns (uint256 votingPower);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

/// @title Whitelist Voting Strategy
/// @notice Allows a variable voting power whitelist to be used for voting power.
contract WhitelistVotingStrategy is IVotingStrategy {
    /// @dev Stores the data for each member of the whitelist.
    struct Member {
        // The address of the member.
        address addr;
        // The voting power of the member.
        uint256 vp;
    }

    /// @notice Returns the voting power of an address at a given timestamp.
    /// @param voter The address to get the voting power of.
    /// @param params Parameter array containing the encoded whitelist of addresses and their voting power.
    ///               The array should be an ABI encoded array of Member structs sorted by ascending addresses.
    /// @return votingPower The voting power of the address if it exists in the whitelist, otherwise 0.
    function getVotingPower(
        uint32 /* timestamp */,
        address voter,
        bytes calldata params,
        bytes calldata /* userParams */
    ) external pure override returns (uint256 votingPower) {
        Member[] memory members = abi.decode(params, (Member[]));

        uint256 high = members.length - 1;
        uint256 low;
        uint256 mid;
        address currentAddress;

        while (low < high) {
            mid = (high + low) / 2; // Expecting high and low to never overflow
            currentAddress = members[mid].addr;

            if (currentAddress < voter) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        if (members[high].addr == voter) {
            return (members[high].vp);
        } else {
            return (0);
        }
    }
}