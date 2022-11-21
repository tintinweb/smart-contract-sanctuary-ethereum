// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICollection} from "../interfaces/ICollection.sol";
import {IEngine, SequenceData} from "../interfaces/IEngine.sol";

contract TestEngine is IEngine {
    function getTokenURI(address, uint256)
        external
        pure
        override
        returns (string memory)
    {
        return "ipfs://QmURW9DGiSD8N2Dc85ToDypqhbTedzwgnjmCR732TzcSHF";
    }

    function getRoyaltyInfo(
        address,
        uint256,
        uint256
    ) external pure override returns (address, uint256) {
        return (address(0), 0);
    }

    function mint(
        ICollection collection,
        uint16 sequenceId,
        string calldata etching
    ) external returns (uint256 tokenId) {
        return
            collection.mintRecord(
                msg.sender,
                sequenceId,
                uint64(block.timestamp),
                etching
            );
    }

    function configureSequence(
        uint16 sequenceId,
        SequenceData calldata sequenceData,
        bytes calldata engineData
    ) external {
        // could revert to block
        // could store msg.sender -> engineData association
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Collections are ERC721 contracts that contain records.
interface ICollection {
    /// @notice Mint a new record. Only callable by the sequence-specific engine.
    function mintRecord(
        address to,
        uint16 sequenceId,
        uint64 tokenData,
        string calldata etching
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Data stored in the collection for each sequence.
struct SequenceData {
    IEngine engine; // 20 bytes
    uint64 dropNodeId; // 10 bytes
    // 2 bytes remaining
    uint64 sealedBeforeTimestamp; // 8 bytes
    uint64 sealedAfterTimestamp; // 8 bytes
    uint64 maxSupply; // 8 bytes
    uint64 minted; // 8 bytes
}

/// @notice An engine contract powers record minting, metadata, and royalty
/// computation.
interface IEngine {
    /// @notice Called by the collection to resolve tokenURI.
    function getTokenURI(address collection, uint256 tokenId)
        external
        view
        returns (string memory);

    /// @notice Called by the collection to resolve royalties.
    function getRoyaltyInfo(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    /// @notice Called by the collection when a new sequence is configured.
    function configureSequence(
        uint16 sequenceId,
        SequenceData calldata sequence,
        bytes calldata engineData
    ) external;
}