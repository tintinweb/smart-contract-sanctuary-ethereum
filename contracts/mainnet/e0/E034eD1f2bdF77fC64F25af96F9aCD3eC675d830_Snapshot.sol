// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Snapshot {

    /// @notice Function used to get every holder address of token `startId` to `startId + size`.
    /// @param collection Specified ERC-721 contract address.
    /// @param startId Starting token ID.
    /// @param size The number of tokens in `collection`.
    function getHolders(
        address collection,
        uint256 startId,
        uint256 size
    ) external returns (address[] memory holders) {
        holders = new address[](size);
        for (uint256 id = startId; id < startId + size; id++) {
            (bool ok, bytes memory data) = collection.call(abi.encodeWithSignature('ownerOf(uint256)', id));
            if (!ok) revert();
            holders[id - startId] = abi.decode(data, (address));
        }
    }

}