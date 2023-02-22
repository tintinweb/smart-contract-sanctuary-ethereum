//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITPLRevealedParts} from "../../TPLRevealedParts/ITPLRevealedParts.sol";

/// @title ITPLMechOrigin
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for TPLMechOrigin fetcher
interface ITPLMechOrigin {
    struct TPLPartOrigin {
        uint256 partId; // ID in the TPLRevealedParts contract
        ITPLRevealedParts.TokenData data;
    }

    struct MechOrigin {
        TPLPartOrigin[] parts;
        uint256 afterglow;
    }

    /// @notice returns all TPLRevealedParts IDs & TPLAfterglow ID used in crafting a Mech
    /// @param mechData the Mech extra data allowing to find its origin
    /// @return an array with the parts ids used
    /// @return the afterglow id
    function getMechPartsIds(uint256 mechData) external view returns (uint256[] memory, uint256);

    /// @notice returns all TPL Revealed Parts IDs (& their TokenData) used in crafting a Mech
    /// @param partsIds the parts ids
    /// @return an array containings each partsIds token data
    function getPartsOrigin(uint256[] memory partsIds) external view returns (TPLPartOrigin[] memory);

    /// @notice returns all TPL Revealed Parts IDs (& their TokenData) used in crafting a Mech
    /// @param mechData the Mech extra data allowing to find its origin
    /// @return a MechOrigin with all parts origin & afterglow
    function getMechOrigin(uint256 mechData) external view returns (MechOrigin memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITPLMechOrigin, ITPLRevealedParts} from "./ITPLMechOrigin.sol";

/// @title TPLMechOrigin
/// @author CyberBrokers
/// @author dev by @dievardump
/// @dev This contract allows to fetch all data abouts given parts
///
///      Today we only have one mech part contract, and Mechs are all built the same way: 7 packedIds
///      However future generations of Mechs could have different info in "mechData"
///
///      This is why this contract can be updated in TPLMech, in order to account for those future possible
///      changes
contract TPLMechOrigin is ITPLMechOrigin {
    address public immutable TPL_REVEALED;

    constructor(address tplRevealed) {
        TPL_REVEALED = tplRevealed;
    }

    /// @inheritdoc ITPLMechOrigin
    function getMechPartsIds(uint256 mechData) public pure returns (uint256[] memory, uint256) {
        uint256[] memory ids = _unpackIds(mechData);
        uint256[] memory revealedIds = new uint256[](6);

        for (uint256 i; i < 6; i++) {
            revealedIds[i] = ids[i];
        }

        return (revealedIds, ids[6]);
    }

    /// @inheritdoc ITPLMechOrigin
    function getPartsOrigin(uint256[] memory partsIds) public view returns (TPLPartOrigin[] memory) {
        ITPLRevealedParts.TokenData[] memory mechPartsData = ITPLRevealedParts(TPL_REVEALED).partDataBatch(partsIds);

        uint256 length = partsIds.length;

        TPLPartOrigin[] memory parts = new TPLPartOrigin[](length);

        for (uint256 i; i < length; i++) {
            parts[i] = TPLPartOrigin(partsIds[i], mechPartsData[i]);
        }

        return parts;
    }

    /// @inheritdoc ITPLMechOrigin
    function getMechOrigin(uint256 mechData) public view returns (MechOrigin memory) {
        (uint256[] memory mechPartsIds, uint256 afterglowId) = getMechPartsIds(mechData);

        ITPLMechOrigin.TPLPartOrigin[] memory parts = getPartsOrigin(mechPartsIds);

        return MechOrigin(parts, afterglowId);
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    /// @dev unpacks the 7 ids bitpacked into `packedIds`
    /// @param packedIds the packed ids
    function _unpackIds(uint256 packedIds) internal pure returns (uint256[] memory) {
        uint256[] memory unpackedIds = new uint256[](7);
        for (uint256 i; i < 7; i++) {
            unpackedIds[i] = uint256(uint32(packedIds));
            packedIds = packedIds >> 32;
        }

        return unpackedIds;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IBase721A} from "../../utils/tokens/ERC721/IBase721A.sol";

/// @title ITPLRevealedParts
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for the Revealed Parts contract.
interface ITPLRevealedParts is IBase721A {
    struct TokenData {
        uint256 generation;
        uint256 originalId;
        uint256 bodyPart;
        uint256 model;
        uint256[] stats;
    }

    /// @notice verifies that `account` owns all `tokenIds`
    /// @param account the account
    /// @param tokenIds the token ids to check
    /// @return if account owns all tokens
    function isOwnerOfBatch(address account, uint256[] calldata tokenIds) external view returns (bool);

    /// @notice returns a Mech Part data (body part and original id)
    /// @param tokenId the tokenId to check
    /// @return the Mech Part data (body part and original id)
    function partData(uint256 tokenId) external view returns (TokenData memory);

    /// @notice returns a list of Mech Part data (body part and original id)
    /// @param tokenIds the tokenIds to knoMechParts type of
    /// @return a list of Mech Part data (body part and original id)
    function partDataBatch(uint256[] calldata tokenIds) external view returns (TokenData[] memory);

    /// @notice Allows to burn tokens in batch
    /// @param tokenIds the tokens to burn
    function burnBatch(uint256[] calldata tokenIds) external;

    /// @notice Transfers the ownership of multiple NFTs from one address to another address
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenIds The NFTs to transfer
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBase721A {
    /// @notice Allows a `minter` to mint `amount` tokens to `to` with `extraData_`
    /// @param to to whom we need to mint
    /// @param amount how many to mint
    /// @param extraData extraData for these items
    function mintTo(
        address to,
        uint256 amount,
        uint24 extraData
    ) external;
}