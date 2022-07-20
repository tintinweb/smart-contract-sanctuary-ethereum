/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IVigils {
    function mintCandleWithPrestige(uint64) external payable;

    function totalSupply() external view returns (uint);

    function transferFrom(address, address, uint) external;
}

contract BulkVigils {
    IVigils immutable vigils;

    constructor(IVigils _vigils) {
        vigils = _vigils;
    }

    /// @notice Bulk mint non-disciple candles.
    function mintCandles(uint count) external payable {
        mintCandlesWithPrestige(count, 0);
    }

    /// @notice Bulk mint non-disciple candles, with a special prestige value.
    function mintCandlesWithPrestige(uint count, uint64 prestige) public payable {
        // Don't worry about overflow, since minting past uint max would fail anyway.
        unchecked {
            address minter = msg.sender;
            uint id = vigils.totalSupply();
            uint newSupply = id + count;

            uint value = msg.value / count;

            for (; id != newSupply; ++id) {
                vigils.mintCandleWithPrestige{value: value}(prestige);
                vigils.transferFrom(address(this), minter, id);
            }
        }
    }

    /// @notice Explicitily receive NFTs since WormsVigil uses safeMint.
    function onERC721Received(address, address, uint, bytes calldata) external pure returns(bytes4) {
        return 0x150b7a02;
    }
}