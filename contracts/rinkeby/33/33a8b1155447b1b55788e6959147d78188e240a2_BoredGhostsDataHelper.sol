// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IBoredGhostsDataHelper.sol';

contract BoredGhostsDataHelper is IBoredGhostsDataHelper {
  function getNFTsData(
    IBoredGhostsAlphaExtended boredGhostsAddress,
    uint256 page,
    uint256 pageSize
  ) external view returns (NFT[] memory) {
    uint256 totalCount = boredGhostsAddress.count();
    uint256 startingId = page * pageSize;
    uint256 realPageSize = totalCount - startingId >= pageSize ? pageSize : totalCount - startingId;

    NFT[] memory nfts = new NFT[](realPageSize);

    for (uint256 i = startingId; i < startingId + realPageSize; i++) {
      nfts[i] = NFT({
        tokenId: i,
        owner: boredGhostsAddress.ownerOf(i),
        tokenURI: boredGhostsAddress.tokenURI(i),
        boringOutfit: boredGhostsAddress.getBoringOutfit(i)
      });
    }

    return nfts;
  }

  function getAvailableOutfits(
    IBoredGhostsAlphaExtended boredGhostsAddress,
    IBoringCollection[] calldata collections
  ) external view returns (ExtendedOutfit[] memory) {
    IBoredGhostsAlphaExtended.CollectionConfig[]
      memory collectionConfigs = new IBoredGhostsAlphaExtended.CollectionConfig[](
        collections.length
      );
    uint256 numberOfTotalOutfits = 0;
    uint256 numberOfAvailableOutfits = 0;
    for (uint256 i = 0; i < collections.length; i++) {
      collectionConfigs[i] = boredGhostsAddress.getCollectionConfig(address(collections[i]));
      numberOfTotalOutfits += collectionConfigs[i].outfitsCount;
    }

    ExtendedOutfit[] memory availableOutfits = new ExtendedOutfit[](numberOfTotalOutfits);
    if (numberOfTotalOutfits == 0) {
      return availableOutfits;
    }

    for (uint256 i = 0; i < collectionConfigs.length; i++) {
      for (uint8 j = 0; j < collectionConfigs[i].outfitsCount; j++) {
        if (collectionConfigs[i].woreMap & (2**j) == 0) {
          availableOutfits[numberOfAvailableOutfits++] = ExtendedOutfit({
            location: address(collections[i]),
            id: j,
            outfitURI: collections[i].getOutfit(j)
          });
        }
      }
    }

    // ._.
    assembly {
      mstore(availableOutfits, sub(numberOfTotalOutfits, numberOfAvailableOutfits))
    }

    return availableOutfits;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBoredGhostsAlpha} from '../interfaces/IBoredGhostsAlpha.sol';
import {IBoringCollection} from '../interfaces/IBoringCollection.sol';

interface IBoredGhostsAlphaExtended is IBoredGhostsAlpha {
  function ownerOf(uint256 id) external view returns (address owner);

  function tokenURI(uint256 id) external view returns (string memory);
}

interface IBoredGhostsDataHelper {
  struct NFT {
    uint256 tokenId;
    address owner;
    string tokenURI;
    IBoredGhostsAlpha.Outfit boringOutfit;
  }

  struct ExtendedOutfit {
    address location;
    uint8 id;
    string outfitURI;
  }

  function getNFTsData(
    IBoredGhostsAlphaExtended boredGhostsAddress,
    uint256 page,
    uint256 pageSize
  ) external view returns (NFT[] memory);

  function getAvailableOutfits(
    IBoredGhostsAlphaExtended boredGhostsAddress,
    IBoringCollection[] calldata collections
  ) external view returns (ExtendedOutfit[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoredGhostsAlpha {
  struct CollectionConfig {
    uint8 outfitsCount;
    uint240 woreMap;
  }

  struct Outfit {
    address location;
    uint8 id;
  }
  event NewSeasonArrived(address outfitLocation, uint256 count);
  event OutfitBorrowed(uint256 tokenId, address outfitLocation, uint64 outfitId);
  event OutfitReturned(uint256 tokenId, address outfitLocation, uint64 outfitId);

  function count() external view returns (uint256);

  function getCollectionConfig(address collection) external view returns (CollectionConfig memory);

  function getBoringOutfit(uint256 tokenId) external view returns (Outfit memory);

  function configureCollection(address[] calldata collections) external;

  function mint(address to) external;

  function wear(uint256 tokenId, Outfit calldata attributes) external;

  function casualOutfit() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoringCollection {
  function collectionSize() external view returns (uint8);

  function getOutfits(uint8 _from, uint8 _to) external view returns (string[] memory);

  function getOutfit(uint256 id) external view returns (string memory);
}