// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

interface IOracleAdapter {
    /// @dev Returns the block header for a given block on a given chain.
    /// @param chainId Identifier for the chain to query.
    /// @param blockNumber Identifier for the block to query.
    /// @return blockHeader Block header reported by the oracle for the given block on the given chain.
    /// @notice MUST return bytes32(0) if the oracle has not yet reported a header for the given block.
    function getHeaderFromOracle(uint256 chainId, uint256 blockNumber) external view returns (bytes32 blockHeader);
}

/*
                  ███▄▄▄                               ,▄▄███▄
                  ████▀`                      ,╓▄▄▄████████████▄
                  ███▌             ,╓▄▄▄▄█████████▀▀▀▀▀▀╙└`
                  ███▌       ▀▀▀▀▀▀▀▀▀▀╙└└-  ████L
                  ███▌                      ████`               ╓██▄
                  ███▌    ╓▄    ╓╓╓╓╓╓╓╓╓╓╓████▄╓╓╓╓╓╓╓╓╓╓╓╓╓╓▄███████▄
                  ███▌  ▄█████▄ ▀▀▀▀▀▀▀▀▀▀████▀▀▀▀▀▀██▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
         ███████████████████████_       ▄███▀        ██µ
                 ▐███▌                ,███▀           ▀██µ
                 ████▌               ▄███▌,           ▄████▄
                ▐████▌             ▄██▀████▀▀▀▀▀▀▀▀▀▀█████▀███▄
               ,█████▌          ,▄██▀_ ▓███          ▐███_  ▀████▄▄
               ██████▌,       ▄██▀_    ▓███          ▐███_    ▀███████▄-
              ███▀███▌▀███▄  ╙"        ▓███▄▄▄▄▄▄▄▄▄▄▄███_      `▀███└
             ▄██^ ███▌  ^████▄         ▓███▀▀▀▀▀▀▀▀▀▀▀███_         `
            ▄██_  ███▌    ╙███         ▓██▀          └▀▀_        ▄,
           ██▀    ███▌      ▀└ ▐███▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄████▄µ
          ██^     ███▌         ▐███▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀██████▀
        ╓█▀       ███▌         ▐███⌐      µ          ╓          ▐███
        ▀         ███▌         ▐███⌐      ███▄▄▄▄▄▄▄████▄       ▐███
                  ███▌         ▐███⌐      ████▀▀▀▀▀▀▀████▀      ▐███
                  ███▌         ▐███⌐      ███▌      J███M       ▐███
                  ███▌         ▐███⌐      ███▌      J███M       ▐███
                  ███▌         ▐███⌐      ████▄▄▄▄▄▄████M       ▐███
                  ███▌         ▐███⌐      ███▌      ▐███M       ▐███
                  ███▌         ▐███⌐      ███▌       ▀▀_        ████
                  ███▌         ▐███⌐      ▀▀_             ▀▀▀███████
                  ███^         ▐███_                          ▐██▀▀　

                                           Made with ❤️ by Gnosis Guild
*/
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "./adapters/IOracleAdapter.sol";

contract Hashi {
    error NoOracleAdaptersGiven(address emitter);
    error OracleDidNotReport(address emitter, IOracleAdapter oracleAdapter);
    error OraclesDisagree(address emitter, IOracleAdapter oracleOne, IOracleAdapter oracleTwo);

    /// @dev Returns the block header reported by a given oracle for a given block.
    /// @param oracleAdapter Address of the oracle adapter to query.
    /// @param chainId Id of the chain to query.
    /// @param blockNumber Block number for which to return a header.
    /// @return blockHeader Block header reported by the given oracle adapter for the given block number.
    function getHeaderFromOracle(
        IOracleAdapter oracleAdapter,
        uint256 chainId,
        uint256 blockNumber
    ) public view returns (bytes32 blockHeader) {
        blockHeader = oracleAdapter.getHeaderFromOracle(chainId, blockNumber);
    }

    /// @dev Returns the block headers for a given block reported by a given set of oracles.
    /// @param oracleAdapters Array of address for the oracle adapters to query.
    /// @param chainId Id of the chain to query.
    /// @param blockNumber Block number for which to return headers.
    /// @return blockHeaders Array of block header reported by the given oracle adapters for the given block number.
    /// @notice This method MUST revert if the oracleAdapters array contains duplicates.
    function getHeadersFromOracles(
        IOracleAdapter[] memory oracleAdapters,
        uint256 chainId,
        uint256 blockNumber
    ) public view returns (bytes32[] memory) {
        if (oracleAdapters.length == 0) revert NoOracleAdaptersGiven(address(this));
        bytes32[] memory blockHeaders = new bytes32[](oracleAdapters.length);
        for (uint256 i = 0; i < oracleAdapters.length; i++) {
            blockHeaders[i] = getHeaderFromOracle(oracleAdapters[i], chainId, blockNumber);
        }
        return blockHeaders;
    }

    /// @dev Returns the block header unanimously agreed upon by a given set of oracles.
    /// @param oracleAdapters Array of address for the oracle adapters to query.
    /// @param chainId Id of the chain to query.
    /// @param blockNumber Block number for which to return headers.
    /// @return blockHeader Block header agreed on by the given set of oracle adapters.
    /// @notice MUST revert if oracles disagree on the header or if an oracle does not report.
    function getUnanimousHeader(
        IOracleAdapter[] memory oracleAdapters,
        uint256 chainId,
        uint256 blockNumber
    ) public view returns (bytes32 blockHeader) {
        bytes32[] memory blockHeaders = getHeadersFromOracles(oracleAdapters, chainId, blockNumber);
        blockHeader = blockHeaders[0];
        if (blockHeader == bytes32(0)) revert OracleDidNotReport(address(this), oracleAdapters[0]);
        if (blockHeaders.length > 1) {
            for (uint256 i = 1; i < blockHeaders.length; i++) {
                bytes32 previousHeader = blockHeader;
                blockHeader = blockHeaders[i];
                if (blockHeader == bytes32(0)) revert OracleDidNotReport(address(this), oracleAdapters[i]);
                if (blockHeader != previousHeader)
                    revert OraclesDisagree(address(this), oracleAdapters[i - 1], oracleAdapters[i]);
                previousHeader = blockHeader;
            }
        }
    }
}