// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { ICollectionNFTEligibilityPredicate } from "../../interfaces/ICollectionNFTEligibilityPredicate.sol";
import { ICollectionNFTTokenURIPredicate } from "../../interfaces/ICollectionNFTTokenURIPredicate.sol";
import { ICollectionNFTMintFeePredicate } from "../../interfaces/ICollectionNFTMintFeePredicate.sol";
import { ICollection } from "../../interfaces/ICollection.sol";

/**
 * @title  AllHashesEligibilityPredicate
 * @author David Matheson (modified by Cooki.eth)
 * @notice This is a helper contract used to determine token eligibility upon instantiating a new
 *         contract from CollectionNFTCloneableV1 to create a new Hashes NFT collection.
 *         This contract includes a function, isTokenEligibleToMint, where a tokenId
 *         and hashesTokenId is provided and the boolean true is then returned so that
 *         all hashes may be minted.
 */
contract AllHashesEligibilityPredicate is
    ICollectionNFTEligibilityPredicate,
    ICollectionNFTMintFeePredicate,
    ICollectionNFTTokenURIPredicate,
    ICollection
{
    /**
     * @notice This predicate function is used to determine the mint eligibility of a hashes token Id for
     *          a specified hashes collection and always returns a boolean value of true. This function is to
     *          be used when instantiating new hashes collections where all hash holders are eligible to mint.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return the boolean value of true
     */
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external pure override returns (bool) {
        return true;
    }

    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external pure override returns (uint256) {
        return 0.0e18;
    }

    function getTokenURI(
        uint256 _tokenId,
        uint256 _hashesTokenId,
        bytes32 _hashehash
    ) external pure override returns (string memory) {
        return "";
    }

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings
     * @param _settings ABI encoded ecosystem settings data. This should be empty for the 'Default' ecosystem.
     *
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        return _settings.length == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICollectionNFTEligibilityPredicate {
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICollection {
    function verifyEcosystemSettings(bytes memory _settings) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICollectionNFTTokenURIPredicate {
    function getTokenURI(
        uint256 _tokenId,
        uint256 _hashesTokenId,
        bytes32 _hashesHash
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICollectionNFTMintFeePredicate {
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view returns (uint256);
}