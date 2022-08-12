// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IIkaniV2 } from "../interfaces/IIkaniV2.sol";

library IkaniV2SeriesLib {

    // TODO: De-dup event definitions.

    event ResetSeriesStartingIndexBlockNumber(
        uint256 indexed seriesIndex,
        uint256 startingIndexBlockNumber
    );

    event SetSeriesStartingIndex(
        uint256 indexed seriesIndex,
        uint256 startingIndex
    );

    event EndedSeries(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive,
        uint256 startingIndexBlockNumber
    );

    uint256 internal constant STARTING_INDEX_ADD_BLOCKS = 10;

    function trySetSeriesStartingIndex(
        mapping(uint256 => IIkaniV2.Series) storage _series_info_,
        uint256 seriesIndex
    )
        external
    {
        IIkaniV2.Series storage _series_ = _series_info_[seriesIndex];

        require(
            !_series_.startingIndexWasSet,
            "Starting index already set"
        );

        uint256 targetBlockNumber = _series_.startingIndexBlockNumber;
        require(
            targetBlockNumber != 0,
            "Series not ended"
        );

        require(
            block.number >= targetBlockNumber,
            "Starting index block not reached"
        );

        // If the hash for the target block is not available, set a new block number and exit.
        if (block.number - targetBlockNumber > 256) {
            uint256 newStartingIndexBlockNumber = block.number + STARTING_INDEX_ADD_BLOCKS;
            _series_.startingIndexBlockNumber = newStartingIndexBlockNumber;
            emit ResetSeriesStartingIndexBlockNumber(
                seriesIndex,
                newStartingIndexBlockNumber
            );
            return;
        }

        uint256 seriesSupply = getSeriesSupply(_series_info_, seriesIndex);
        uint256 startingIndex = uint256(blockhash(targetBlockNumber)) % seriesSupply;

        // Update storage.
        _series_.startingIndex = startingIndex;
        _series_.startingIndexWasSet = true;

        emit SetSeriesStartingIndex(
            seriesIndex,
            startingIndex
        );
    }

    function endCurrentSeries(
        IIkaniV2.Series storage _series_,
        uint256 seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive
    )
        external
    {
        uint256 startingIndexBlockNumber = block.number + STARTING_INDEX_ADD_BLOCKS;

        _series_.poemCreationDeadline = poemCreationDeadline;
        _series_.maxTokenIdExclusive = maxTokenIdExclusive;
        _series_.startingIndexBlockNumber = startingIndexBlockNumber;

        emit EndedSeries(
            seriesIndex,
            poemCreationDeadline,
            maxTokenIdExclusive,
            startingIndexBlockNumber
        );
    }

    function validateExpireBatch(
        mapping(uint256 => IIkaniV2.Series) storage _series_info_,
        uint256[] calldata tokenIds,
        uint256 seriesIndex
    )
        external
        view
    {
        IIkaniV2.Series storage _series_ = _series_info_[seriesIndex];

        require(
            _series_.startingIndexBlockNumber != 0,
            "Series not ended"
        );
        require(
            block.timestamp > _series_.poemCreationDeadline,
            "Series has not expired"
        );

        uint256 n = tokenIds.length;

        uint256 maxTokenIdExclusive = _series_.maxTokenIdExclusive;
        for (uint256 i = 0; i < n;) {
            require(
                tokenIds[i] < maxTokenIdExclusive,
                "Token ID not part of the series"
            );
            unchecked { ++i; }
        }

        if (seriesIndex > 0) {
            uint256 startTokenId = _series_info_[seriesIndex - 1].maxTokenIdExclusive;
            for (uint256 i = 0; i < n;) {
                require(
                    tokenIds[i] >= startTokenId,
                    "Token ID not part of the series"
                );
                unchecked { ++i; }
            }
        }
    }

    function getSeriesSupply(
        mapping(uint256 => IIkaniV2.Series) storage _series_info_,
        uint256 seriesIndex
    )
        public
        view
        returns (uint256)
    {
        IIkaniV2.Series storage _series_ = _series_info_[seriesIndex];

        require(
            _series_.startingIndexBlockNumber != 0,
            "Series not ended"
        );

        uint256 maxTokenIdExclusive = _series_.maxTokenIdExclusive;

        if (seriesIndex == 0) {
            return maxTokenIdExclusive;
        }

        IIkaniV2.Series storage _previous_series_ = _series_info_[seriesIndex - 1];

        return maxTokenIdExclusive - _previous_series_.maxTokenIdExclusive;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV2
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for the IkaniV1 ERC-721 NFT contract.
 */
interface IIkaniV2 {

    //---------------- Enums ----------------//

    enum Theme {
        NULL,
        SKY,
        OCEAN,
        MOUNTAIN,
        FLOWERS,
        TBA_THEME_5,
        TBA_THEME_6,
        TBA_THEME_7,
        TBA_THEME_8
    }

    enum Season {
        NONE,
        SPRING,
        SUMMER,
        AUTUMN,
        WINTER
    }

    enum Fabric {
        NULL,
        KOYAMAKI,
        SEIGAIHA,
        NAMI,
        KUMO,
        TBA_FABRIC_5,
        TBA_FABRIC_6,
        TBA_FABRIC_7,
        TBA_FABRIC_8
    }

    enum Foil {
        NONE,
        GOLD,
        PLATINUM,
        SUI_GENERIS
    }

    //---------------- Structs ----------------//

    /**
     * @notice The poem metadata traits.
     */
    struct PoemTraits {
        Theme theme;
        Season season;
        Fabric fabric;
        Foil foil;
    }

    /**
     * @notice Information about a series within the collection.
     */
    struct Series {
        string name;
        bytes32 provenanceHash;
        uint256 poemCreationDeadline;
        uint256 maxTokenIdExclusive;
        uint256 startingIndexBlockNumber;
        uint256 startingIndex;
        bool startingIndexWasSet;
    }

    /**
     * @notice Arguments to be signed by the mint authority to authorize a mint.
     */
    struct MintArgs {
        uint256 seriesIndex;
        uint256 mintPrice;
        uint256 maxTokenIdExclusive;
        uint256 nonce;
    }

    //---------------- Events ----------------//

    event SetRoyaltyReceiver(
        address royaltyReceiver
    );

    event SetRoyaltyBips(
        uint256 royaltyBips
    );

    event SetSeriesInfo(
        uint256 indexed seriesIndex,
        string name,
        bytes32 provenanceHash
    );

    event AdvancedPoemCreationDeadline(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline
    );

    event ResetSeriesStartingIndexBlockNumber(
        uint256 indexed seriesIndex,
        uint256 startingIndexBlockNumber
    );

    event SetSeriesStartingIndex(
        uint256 indexed seriesIndex,
        uint256 startingIndex
    );

    event EndedSeries(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive,
        uint256 startingIndexBlockNumber
    );

    event FinishedPoem(
        uint256 indexed tokenId
    );

    //---------------- Functions ----------------//

    function getPoemTraits(
        uint256 tokenId
    )
        external
        view
        returns (IIkaniV2.PoemTraits memory);
}