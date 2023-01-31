// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IComp {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}

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

abstract contract TimestampResolver {
    error TimestampInFuture();
    error InvalidBlockNumber();

    mapping(uint32 => uint256) public timestampToBlockNumber;

    /// @notice Resolves a timestamp to a block number in such a way that the same timestamp
    /// always resolves to the same block number. If the timestamp is in the future, reverts.
    /// @param timestamp The timestamp to resolve
    /// @return blockNumber The block number that the timestamp resolves to
    function resolveSnapshotTimestamp(uint32 timestamp) internal returns (uint256 blockNumber) {
        if (timestamp > uint32(block.timestamp)) revert TimestampInFuture();
        if (block.number == 1) revert InvalidBlockNumber();

        blockNumber = timestampToBlockNumber[timestamp];
        if (blockNumber != 0) {
            // Timestamp already resolved, return the previously resolved block number
            return blockNumber;
        }
        // Timestamp not yet resolved, resolve it to the current block number - 1 and return it
        // We resolve to the current block number - 1 so that Comp style getPastVotes/getPriorVotes
        // functions can be used in same block as when the resolution is made
        blockNumber = block.number - 1;

        timestampToBlockNumber[timestamp] = blockNumber;
        return blockNumber;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IVotingStrategy.sol";
import "../interfaces/IComp.sol";
import "../utils/TimestampResolver.sol";

contract CompVotingStrategy is IVotingStrategy, TimestampResolver {
    error InvalidByteArray();

    function getVotingPower(
        uint32 timestamp,
        address voterAddress,
        bytes calldata params,
        bytes calldata /* userParams */
    ) external override returns (uint256) {
        address tokenAddress = BytesToAddress(params, 0);
        uint256 blockNumber = resolveSnapshotTimestamp(timestamp);
        return uint256(IComp(tokenAddress).getPriorVotes(voterAddress, blockNumber));
    }

    /// @notice Extracts an address from a byte array
    /// @param _bytes The byte array to extract the address from
    /// @param _start The index to start extracting the address from
    /// @dev Function from the library, with the require switched for a revert statement:
    /// https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function BytesToAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        if (_bytes.length < _start + 20) revert InvalidByteArray();
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
}