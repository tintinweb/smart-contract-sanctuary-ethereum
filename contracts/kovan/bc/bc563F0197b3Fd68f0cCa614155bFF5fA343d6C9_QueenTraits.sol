// SPDX-License-Identifier: MIT

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IQueenTraits} from "../interfaces/IQueenTraits.sol";
import {IQueenPalace} from "../interfaces/IQueenPalace.sol";
import {QueenTraitsBase} from "./base/QueenTraitsBase.sol";
import {RoyalLibrary} from "./lib/RoyalLibrary.sol";

contract QueenTraits is QueenTraitsBase, IQueenTraits {
  using Strings for uint256;
  using RoyalLibrary for string;

  RoyalLibrary.sTRAIT[] private traits;
  RoyalLibrary.sRARITY[] private rarities;
  //(traitId => (rarityId => art))
  mapping(uint256 => mapping(uint256 => RoyalLibrary.sART[])) private arts;
  mapping(uint256 => bytes[]) private portraitDescriptions;

  uint256[] private _rarityPool;

  /************************** vCONSTRUCTOR REGION *************************************************** */

  constructor(
    IQueenPalace _queenPalace,
    bytes[] memory commonDescriptions,
    bytes[] memory rareDescriptions,
    bytes[] memory superRareDescriptions
  ) {
    //set ERC165 pattern
    _registerInterface(type(IQueenTraits).interfaceId);

    queenPalace = _queenPalace;

    //TRAITS
    traits.push(
      RoyalLibrary.sTRAIT({id: 1, traitName: "BACKGROUND", enabled: 1})
    );

    traits.push(RoyalLibrary.sTRAIT({id: 2, traitName: "FACE", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 3, traitName: "OUTFIT", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 4, traitName: "HEAD", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 5, traitName: "JEWELRY", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 6, traitName: "FRAME", enabled: 1}));

    //RARITIES
    rarities.push(
      RoyalLibrary.sRARITY({id: 1, rarityName: "COMMON", percentage: 85})
    );

    rarities.push(
      RoyalLibrary.sRARITY({id: 2, rarityName: "RARE", percentage: 10})
    );

    rarities.push(
      RoyalLibrary.sRARITY({id: 3, rarityName: "SUPER-RARE", percentage: 5})
    );
    //build rarity pool
    buildRarityPool();
    //Portrait Description Common
    portraitDescriptions[0] = commonDescriptions;
    //Portrait Description Rare
    portraitDescriptions[1] = rareDescriptions;
    //Portrait Description Super-Rare and Legendary
    portraitDescriptions[2] = superRareDescriptions;
  }

  /**
   *build rarity pool for lottery on mint
   */
  function buildRarityPool() private {
    //build rarity pool
    _rarityPool = new uint256[](100);
    uint256 poolIdx;
    uint256 percentageSum;

    for (uint256 idx = 0; idx < rarities.length; idx++) {
      percentageSum += rarities[idx].percentage;
    }

    for (uint256 idx = 0; idx < rarities.length; idx++) {
      for (
        uint256 counter = 1;
        counter <=
        rarities[idx].percentage + (idx == 0 ? (100 - percentageSum) : 0);
        counter++
      ) {
        _rarityPool[poolIdx++] = rarities[idx].id;
      }
    }
  }

  function rarityPool() external view override returns (uint256[] memory) {
    return _rarityPool;
  }

  /************************** ^CONSTRUCTOR REGION *************************************************** */

  /************************** vRARITY REGION ******************************************************** */

  /**
   *IN
   *_rarityId: Id of Rarity you want to consult
   *OUT
   *rarity: Rarity object found for given id
   */
  function getRarityById(uint256 _rarityId)
    public
    view
    override
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (rarities[idx].id == _rarityId) return rarities[idx];
    }

    return RoyalLibrary.sRARITY({id: 0, rarityName: "", percentage: 0});
  }

  /**
   *IN
   *_rarityName: Name of Rarity you want to consult
   *OUT
   *rarity: Rarity object found for given name
   */
  function getRarityByName(string memory _rarityName)
    public
    view
    override
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (
        keccak256(abi.encodePacked(rarities[idx].rarityName)) ==
        keccak256(abi.encodePacked(_rarityName))
      ) return rarities[idx];
    }

    return RoyalLibrary.sRARITY({id: 0, rarityName: "", percentage: 0});
  }

  /**
   *IN
   *_onlyWithArt: If should return only rarities with art in given traitId (obligatory to send valid tratId if this parameter is true. Send 0 otherwise)
   *_traitId: id of the trait to check if there is any art (obligatory to send valid tratId if _onlyWithArt is true. Send 0 otherwise)
   *OUT
   *rarities: Array with all rarities
   */
  function getRarities(bool _onlyWithArt, uint256 _traitId)
    public
    view
    override
    returns (RoyalLibrary.sRARITY[] memory raritiesList)
  {
    if (_onlyWithArt && _traitId <= 0)
      require(
        !_onlyWithArt || (_onlyWithArt && _traitId > 0),
        "Invalid Parameters!"
      );

    uint256 qtty = rarities.length;
    if (_onlyWithArt) {
      qtty = 0;
      for (uint256 idx = 0; idx < rarities.length; idx++) {
        if (arts[_traitId][rarities[idx].id].length > 0) qtty++;
      }
    }

    RoyalLibrary.sRARITY[]
      memory _availableRarities = new RoyalLibrary.sRARITY[](qtty);

    uint256 newIndex = 0;
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (_onlyWithArt) {
        if (arts[_traitId][rarities[idx].id].length > 0)
          _availableRarities[newIndex++] = rarities[idx];
      } else _availableRarities[newIndex++] = rarities[idx];
    }

    return _availableRarities;
  }

  /**
   *IN
   *_rarityId: Id of the rarity
   *OUT
   *rarityIdx: idx of rarity found in array
   */
  function getRarityIdxById(uint256 _rarityId)
    private
    view
    returns (uint256 rarityIdx)
  {
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (rarities[idx].id == _rarityId) {
        return idx;
      }
    }

    return 0;
  }

  /**
   *IN
   *_rarityName: Name of Rarity you want to consult
   *OUT
   *rarity: Rarity object updated
   */
  function setRarity(string memory _rarityName, uint256 _percentage)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    if (getRarityByName(_rarityName).id != 0)
      return getRarityByName(_rarityName);

    uint256 percSum = _percentage;
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      percSum += rarities[idx].percentage;
    }

    require(percSum <= 100, "Percentage Overflow");
    rarities.push(
      rarity = RoyalLibrary.sRARITY({
        id: rarities.length + 1,
        rarityName: _rarityName,
        percentage: _percentage
      })
    );

    buildRarityPool();
    emit RarityCreated(rarities.length, _rarityName, _percentage);
  }

  /**
   *IN
   *_rarityId: Id of Rarity you want to change the name
   *_percentage: if above 0, updates percentage. if not, dont
   *OUT
   *rarity: Rarity object updated
   */
  function updateRarity(
    uint256 _rarityId,
    uint256 _newPercentage,
    string memory _rarityNewName
  )
    external
    whenNotPaused
    onlyOwnerOrChiefDeveloperOrDAO
    onlyOnImplementationOrDAO
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    if (getRarityById(_rarityId).id <= 0)
      return RoyalLibrary.sRARITY({id: 0, rarityName: "", percentage: 0});

    rarities[getRarityIdxById(_rarityId)].rarityName = keccak256(
      abi.encodePacked(_rarityNewName)
    ) != keccak256(abi.encodePacked(""))
      ? _rarityNewName
      : rarities[getRarityIdxById(_rarityId)].rarityName;
    rarities[getRarityIdxById(_rarityId)].percentage = _newPercentage > 0
      ? _newPercentage
      : rarities[getRarityIdxById(_rarityId)].percentage;

    uint256 percSum;
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      percSum += rarities[idx].percentage;
    }
    require(percSum <= 100, "Percentage Overflow");

    buildRarityPool();

    emit RarityUpdated(
      rarities[getRarityIdxById(_rarityId)].id,
      rarities[getRarityIdxById(_rarityId)].rarityName,
      rarities[getRarityIdxById(_rarityId)].percentage
    );

    return rarities[getRarityIdxById(_rarityId)];
  }

  /************************** ^RARITY REGION ******************************************************** */

  /************************** DESCRIPTION REGION **************************************************** */

  /**
   *IN
   *_rarityId: Id of Rarity of QueenE
   *_index: Index of the phrase that we want to retrieve
   *OUT
   *description in given index
   */
  function getDescriptionByIdx(uint256 _rarityId, uint256 _index)
    public
    view
    override
    returns (bytes memory description)
  {
    if (_rarityId <= 1) return portraitDescriptions[_rarityId][_index];
    else return portraitDescriptions[2][_index];
  }

  /**
   *IN
   *_rarityId: rarity to count descriptions for
   *OUT
   *count: count of the descriptions
   */
  function getDescriptionsCount(uint256 _rarityId)
    public
    view
    override
    returns (uint256)
  {
    if (_rarityId <= 1) return portraitDescriptions[_rarityId].length;
    else return portraitDescriptions[2].length;
  }

  /**
   *IN
   *_rarityName: Name of Rarity you want to consult
   *OUT
   *rarity: Rarity object updated
   */
  function setDescription(uint256 _rarityId, bytes memory _description)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    bool alreadyExists = false;

    for (uint256 idx = 0; idx < portraitDescriptions[_rarityId].length; idx++) {
      bytes memory storedDesc = portraitDescriptions[_rarityId][idx];
      if (
        keccak256(abi.encodePacked(storedDesc)) ==
        keccak256(abi.encodePacked(_description))
      ) alreadyExists = true;
      break;
    }

    require(!alreadyExists, "QueenTraits::Descrption already exists");

    portraitDescriptions[_rarityId].push(_description);
  }

  /************************** ^DESCRIPTION REGION *************************************************** */

  /************************** vTRAITS REGION ******************************************************** */

  /**
   *IN
   *_idx: index of trait on array
   *OUT
   *trait: trait found in array
   */
  function getTrait(uint256 _id)
    public
    view
    override
    returns (RoyalLibrary.sTRAIT memory trait)
  {
    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (traits[idx].id == _id) return traits[idx];
    }
  }

  /**
   *IN
   *_traitName: name of the trait
   *OUT
   *trait: trait found in array
   */
  function getTraitByName(string memory _traitName)
    public
    view
    override
    returns (RoyalLibrary.sTRAIT memory trait)
  {
    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (
        keccak256(abi.encodePacked(traits[idx].traitName)) ==
        keccak256(abi.encodePacked(_traitName))
      ) return traits[idx];
    }
  }

  /**
   *IN
   *_traitName: name of the trait
   *OUT
   *traitIdx: idx of trait found in array
   */
  function getTraitIdxByName(string memory _traitName)
    private
    view
    returns (uint256 traitIdx)
  {
    require(
      keccak256(abi.encodePacked(_traitName)) !=
        keccak256(abi.encodePacked("")),
      "Name must have value!"
    );

    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (
        keccak256(abi.encodePacked(traits[idx].traitName)) ==
        keccak256(abi.encodePacked(_traitName))
      ) return idx;
    }
  }

  /**
   *IN
   *OUT
   *traits: all traits written in contract
   */
  function getTraits(bool _onlyEnabled)
    public
    view
    override
    returns (RoyalLibrary.sTRAIT[] memory _traits)
  {
    uint256 itens = 0;

    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (!_onlyEnabled) itens++;
      else if (traits[idx].enabled == 1) itens++;
    }

    RoyalLibrary.sTRAIT[] memory enabledTraits = new RoyalLibrary.sTRAIT[](
      itens
    );
    uint256 newIdx = 0;
    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (!_onlyEnabled) enabledTraits[newIdx++] = traits[idx];
      else {
        if (traits[idx].enabled == 1) enabledTraits[newIdx++] = traits[idx];
      }
    }

    return enabledTraits;
  }

  /**
   *IN
   * _traitName: Name of the trait
   * _enabled: If trait is enabled. 0 is disabled, 1 is enabled
   *OUT
   *trait: final trait object in store
   */
  function setTrait(string memory _traitName, uint8 _enabled)
    public
    whenNotPaused
    onlyOwnerOrArtistOrDAO
    onlyOnImplementationOrDAO
  {
    require(_enabled >= 0 && _enabled <= 1, "Enabled value invalid");

    if (getTraitByName(_traitName).id > 0) //already exists
    {
      traits[getTraitIdxByName(_traitName)].enabled = _enabled;
      if (_enabled == 0)
        emit TraitDisabled(
          traits[getTraitIdxByName(_traitName)].id,
          traits[getTraitIdxByName(_traitName)].traitName
        );
      else
        emit TraitEnabled(
          traits[getTraitIdxByName(_traitName)].id,
          traits[getTraitIdxByName(_traitName)].traitName
        );
    } else {
      traits.push(
        RoyalLibrary.sTRAIT({
          id: traits.length,
          traitName: _traitName,
          enabled: _enabled
        })
      );
      emit TraitCreated(traits.length, _traitName, _enabled);
    }
  }

  /************************** ^TRAITS REGION ******************************************************** */

  /************************** vART REGION ******************************************************** */

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *_artUri: Uri of art that want to be checked
   *OUT
   *exists: true if uri already exists in the contract, false if not
   */
  function checkIfArtAlreadyExists(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  ) private view returns (bool exists, uint256 index) {
    //retrieve arts array
    if (arts[_traitId][_rarityId].length > 0) {
      RoyalLibrary.sART[] memory _arts = arts[_traitId][_rarityId];
      for (uint256 idx = 0; idx < _arts.length; idx++) {
        if (
          keccak256(abi.encodePacked(_arts[idx].uri)) ==
          keccak256(abi.encodePacked(_artUri))
        ) return (true, idx);
      }
    }

    return (false, 0);
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *_artUri: Uri of art that want to be checked
   *OUT
   *art: art found with uri
   */
  function getArtByUri(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  ) external view override returns (RoyalLibrary.sART memory art) {
    //retrieve arts array
    if (arts[_traitId][_rarityId].length > 0) {
      RoyalLibrary.sART[] memory _arts = arts[_traitId][_rarityId];
      for (uint256 idx = 0; idx < _arts.length; idx++) {
        if (
          keccak256(abi.encodePacked(_arts[idx].uri)) ==
          keccak256(abi.encodePacked(_artUri))
        ) return _arts[idx];
      }
    }
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *OUT
   *quantity: quantity of arts found for trait and rarity
   */
  function getArtCount(uint256 _traitId, uint256 _rarityId)
    external
    view
    override
    returns (uint256)
  {
    if (_rarityId > 0) {
      return arts[_traitId][_rarityId].length;
    } else {
      uint256 qtty;

      for (uint256 idx = 0; idx < rarities.length; idx++) {
        qtty += arts[_traitId][rarities[idx].id].length;
      }

      return qtty;
    }
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *_artIdx: index of art in array
   *OUT
   *art: sART object for given inputs
   */
  function getArt(
    uint256 _traitId,
    uint256 _rarityId,
    uint256 _artIdx
  ) external view override returns (RoyalLibrary.sART memory art) {
    require(
      arts[_traitId][_rarityId].length >= (_artIdx + 1),
      "No Art at given index"
    );

    return arts[_traitId][_rarityId][_artIdx];
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarity: rarity of the art
   *OUT
   *arts: list of sART objects for given trait:rarity
   */
  function getArts(uint256 _traitId, uint256 _rarityId)
    external
    view
    override
    returns (RoyalLibrary.sART[] memory artsList)
  {
    return arts[_traitId][_rarityId];
  }

  /**
   *IN
   * _traitId: Id of the trait
   * _rarityId: rarity Id of the trait
   * _artUri: Uri of art on IPFS
   *OUT
   * art: final art object in store
   */
  function setArt(RoyalLibrary.sART[] memory _artUri)
    external
    whenNotPaused
    onlyOwnerOrArtistOrDAO
    onlyOnImplementationOrDAO
  {
    require(_artUri.length > 0, "Uri must have value!");

    for (uint256 index = 0; index < _artUri.length; index++) {
      require(_artUri[index].traitId > 0, "Trait id invalid!");
      require(_artUri[index].rarityId > 0, "Rarity id invalid!");
      require(getTrait(_artUri[index].traitId).enabled == 1, "Trait disabled!");

      (bool exists, ) = checkIfArtAlreadyExists(
        _artUri[index].traitId,
        _artUri[index].rarityId,
        _artUri[index].uri
      );

      if (exists) {
        //just go to the next
        continue;
      }

      arts[_artUri[index].traitId][_artUri[index].rarityId].push(
        RoyalLibrary.sART({
          traitId: _artUri[index].traitId,
          rarityId: _artUri[index].rarityId,
          artName: _artUri[index].artName,
          uri: _artUri[index].uri
        })
      );

      emit ArtCreated(
        _artUri[index].traitId,
        _artUri[index].rarityId,
        _artUri[index].artName,
        _artUri[index].uri
      );
    }
  }

  /**
   *IN
   * _traitId: Id of the trait
   * _rarityId: rarity Id of the trait
   * _artUri: Uri of art on IPFS
   *OUT
   * art: final art object in store
   */
  function removeArt(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  )
    external
    whenNotPaused
    onlyOwnerOrChiefArtist
    onlyOnImplementation
    returns (bool result)
  {
    require(
      keccak256(abi.encodePacked(_artUri)) != keccak256(abi.encodePacked("")),
      "Uri must have value!"
    );

    (bool found, uint256 index) = checkIfArtAlreadyExists(
      _traitId,
      _rarityId,
      _artUri
    );

    require(found, "No art found for given data!");

    //rearrenge array
    for (
      uint256 idx = index;
      idx < (arts[_traitId][_rarityId].length - 1);
      idx++
    ) {
      arts[_traitId][_rarityId][idx] = arts[_traitId][_rarityId][idx + 1];
    }

    //delete last index
    delete arts[_traitId][_rarityId][arts[_traitId][_rarityId].length - 1];
    arts[_traitId][_rarityId].pop();

    emit ArtRemoved(_traitId, _rarityId, _artUri);

    return true;
  }

  /************************** ^ART REGION ******************************************************** */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE Traits contract

pragma solidity ^0.8.9;

//import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRoyalContractBase} from "../interfaces/IRoyalContractBase.sol";
import {RoyalLibrary} from "../contracts/lib/RoyalLibrary.sol";

interface IQueenTraits is IRoyalContractBase {
  event RarityCreated(
    uint256 indexed rarityId,
    string rarityName,
    uint256 _percentage
  );
  event RarityUpdated(
    uint256 indexed rarityId,
    string rarityName,
    uint256 _percentage
  );

  event TraitCreated(
    uint256 indexed traitId,
    string _traitName,
    uint8 _enabled
  );

  event TraitEnabled(uint256 indexed traitId, string _traitName);
  event TraitDisabled(uint256 indexed traitId, string _traitName);

  event ArtCreated(
    uint256 traitId,
    uint256 rarityId,
    bytes artName,
    bytes artUri
  );
  event ArtRemoved(uint256 traitId, uint256 rarityId, bytes artUri);

  function rarityPool() external view returns (uint256[] memory);

  function getRarityById(uint256 _rarityId)
    external
    view
    returns (RoyalLibrary.sRARITY memory rarity);

  function getRarityByName(string memory _rarityName)
    external
    returns (RoyalLibrary.sRARITY memory rarity);

  function getRarities(bool onlyWithArt, uint256 _traitId)
    external
    view
    returns (RoyalLibrary.sRARITY[] memory raritiesList);

  function getTrait(uint256 _id)
    external
    view
    returns (RoyalLibrary.sTRAIT memory trait);

  function getTraitByName(string memory _traitName)
    external
    returns (RoyalLibrary.sTRAIT memory trait);

  function getTraits(bool _onlyEnabled)
    external
    view
    returns (RoyalLibrary.sTRAIT[] memory _traits);

  function getDescriptionByIdx(uint256 _rarityId, uint256 _index)
    external
    view
    returns (bytes memory description);

  function getDescriptionsCount(uint256 _rarityId)
    external
    view
    returns (uint256);

  function getArtByUri(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  ) external returns (RoyalLibrary.sART memory art);

  function getArtCount(uint256 _traitId, uint256 _rarityId)
    external
    view
    returns (uint256 quantity);

  function getArt(
    uint256 _traitId,
    uint256 _rarityId,
    uint256 _artIdx
  ) external view returns (RoyalLibrary.sART memory art);

  function getArts(uint256 _traitId, uint256 _rarityId)
    external
    returns (RoyalLibrary.sART[] memory artsList);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Queen Staff Contract

pragma solidity ^0.8.9;

import {IQueenLab} from "../interfaces/IQueenLab.sol";
import {IQueenTraits} from "../interfaces/IQueenTraits.sol";
import {IQueenE} from "../interfaces/IQueenE.sol";
import {IQueenAuctionHouse} from "../interfaces/IQueenAuctionHouse.sol";

interface IQueenPalace {
    function royalMuseum() external view returns (address);

    function isOnImplementation() external view returns (bool status);

    function artist() external view returns (address);

    function isArtist(address addr) external view returns (bool);

    function dao() external view returns (address);

    function daoExecutor() external view returns (address);

    function RoyalTowerAddr() external view returns (address);

    function developer() external view returns (address);

    function isDeveloper(address devAddr) external view returns (bool);

    function minter() external view returns (address);

    function QueenLab() external view returns (IQueenLab);

    function QueenTraits() external view returns (IQueenTraits);

    function QueenAuctionHouse() external view returns (IQueenAuctionHouse);

    function QueenE() external view returns (IQueenE);

    function whiteListed() external view returns (uint256);

    function isWhiteListed(address _addr) external view returns (bool);

    function QueenAuctionHouseProxyAddr() external view returns (address);
}

// SPDX-License-Identifier: MIT

/// @title A base contract with implementation control

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

//import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC165Storage} from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import {RoyalLibrary} from "../lib/RoyalLibrary.sol";
import {IRoyalContractBase} from "../../interfaces/IRoyalContractBase.sol";
import {IQueenPalace} from "../../interfaces/IQueenPalace.sol";

contract QueenTraitsBase is
    ERC165Storage,
    IRoyalContractBase,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    IQueenPalace internal queenPalace;

    /************************** vCONTROLLER REGION *************************************************** */

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     *newQueenPalace: new QueenPalace contract address
     */
    function setQueenPalace(IQueenPalace _queenPalace)
        external
        nonReentrant
        whenPaused
        onlyOwnerOrDAO
        onlyOnImplementationOrDAO
    {
        _setQueenPalace(_queenPalace);
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     *newQueenPalace: new QueenPalace contract address
     */
    function _setQueenPalace(IQueenPalace _queenPalace) internal {
        queenPalace = _queenPalace;
    }

    /************************** ^vCONTROLLER REGION *************************************************** */

    /************************** vMODIFIERS REGION ***************************************************** */
    modifier onlyOwnerOrDeveloperOrDAO() {
        isOwnerOrDeveloperOrDAO();
        _;
    }
    modifier onlyOwnerOrChiefDeveloperOrDAO() {
        isOwnerOrChiefDeveloperOrDAO();
        _;
    }
    modifier onlyOwnerOrArtistOrDAO() {
        isOwnerOrArtistOrDAO();
        _;
    }
    modifier onlyOwnerOrChiefArtist() {
        isOwnerOrChiefArtist();
        _;
    }
    modifier onlyOwnerOrChiefArtistOrDAO() {
        isOwnerOrChiefArtistOrDAO();
        _;
    }
    modifier onlyOnImplementationOrDAO() {
        isOnImplementationOrDAO();
        _;
    }
    modifier onlyOwnerOrDAO() {
        isOwnerOrDAO();
        _;
    }
    modifier onlyOnImplementationOrPaused() {
        isOnImplementationOrPaused();
        _;
    }
    modifier onlyOnImplementation() {
        isOnImplementation();
        _;
    }

    /************************** ^MODIFIERS REGION ***************************************************** */

    /**
     *IN
     *OUT
     *if given address is owner
     */
    function isOwner(address _address) external view override returns (bool) {
        return owner() == _address;
    }

    function isOwnerOrChiefArtist() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.artist(),
            "Not Owner, Chief Artist"
        );
    }

    function isOwnerOrChiefArtistOrDAO() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == queenPalace.artist() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Artist, DAO"
        );
    }

    function isOwnerOrChiefDeveloperOrDAO() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == queenPalace.developer() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Chief Developer, DAO"
        );
    }

    function isOwnerOrArtistOrDAO() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isArtist(msg.sender) ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Artist, DAO"
        );
    }

    function isOnImplementationOrDAO() internal view {
        require(
            queenPalace.isOnImplementation() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not On Implementation sender not DAO"
        );
    }

    function isOnImplementation() internal view {
        require(queenPalace.isOnImplementation(), "Not On Implementation");
    }

    function isOnImplementationOrPaused() internal view {
        require(
            queenPalace.isOnImplementation() || paused(),
            "Not On Implementation,Paused"
        );
    }

    function isOwnerOrDAO() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.daoExecutor(),
            "Not Owner, DAO"
        );
    }

    function isOwnerOrDeveloperOrDAO() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isDeveloper(msg.sender) ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Developer, DAO"
        );
    }
}

// SPDX-License-Identifier: MIT

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.9;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library RoyalLibrary {
    struct sTRAIT {
        uint256 id;
        string traitName;
        uint8 enabled; //0 - disabled; 1 - enabled;
    }

    struct sRARITY {
        uint256 id;
        string rarityName;
        uint256 percentage; //1 ~ 100
    }

    struct sART {
        uint256 traitId;
        uint256 rarityId;
        bytes artName;
        bytes uri;
    }

    struct sDNA {
        uint256 traitId;
        uint256 rarityId;
        uint256 trace;
    }

    struct sBLOOD {
        uint256 traitId;
        uint256 rarityId;
        string artName;
        string artUri;
    }

    struct sQUEEN {
        uint256 queeneId;
        uint256 description; //index of the description
        string finalArt;
        sDNA[] dna;
        uint8 queenesGallery;
        uint8 sirAward;
    }

    struct sSIR {
        address sirAddress;
        uint256 queene;
    }

    struct sAUCTION {
        uint256 queeneId;
        uint256 lastBidAmount;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 initialBidPrice;
        address payable bidder;
        bool ended;
    }

    enum queeneRarity {
        COMMON,
        RARE,
        SUPER_RARE,
        LEGENDARY
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
    uint8 constant houseOfLords = 1;
    uint8 constant houseOfCommons = 2;
    uint8 constant houseOfBanned = 3;

    error InvalidAddressError(string _caller, string _msg, address _address);
    error AuthorizationError(string _caller, string _msg, address _address);
    error MinterLockedError(
        string _caller,
        string _msg,
        address _minterAddress
    );
    error StorageLockedError(
        string _caller,
        string _msg,
        address _storageAddress
    );
    error LabLockedError(string _caller, string _msg, address _labAddress);
    error InvalidParametersError(
        string _caller,
        string _msg,
        string _arg1,
        string _arg2,
        string _arg3
    );

    function concat(string memory self, string memory part2)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(self, part2));
    }

    function stringEquals(string storage self, string memory b)
        public
        view
        returns (bool)
    {
        if (bytes(self).length != bytes(b).length) {
            return false;
        } else {
            return
                keccak256(abi.encodePacked(self)) ==
                keccak256(abi.encodePacked(b));
        }
    }

    function extractRevertReason(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.9;
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IRoyalContractBase is IERC165 {
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Noun Auction Houses

pragma solidity ^0.8.9;

import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {RoyalLibrary} from "../contracts/lib//RoyalLibrary.sol";
import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenE} from "./IQueenE.sol";

interface IQueenLab is IRoyalContractBase {
    function buildDna(uint256 queeneId, bool isSir)
        external
        view
        returns (RoyalLibrary.sDNA[] memory dna);

    function produceBlueBlood(RoyalLibrary.sDNA[] memory dna)
        external
        view
        returns (RoyalLibrary.sBLOOD[] memory blood);

    function generateQueen(uint256 _queenId, bool isSir)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function getQueenRarity(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (RoyalLibrary.queeneRarity finalRarity);

    function getQueenRarityBidIncrement(
        RoyalLibrary.sDNA[] memory _dna,
        uint256[] calldata map
    ) external pure returns (uint256 value);

    function getQueenRarityName(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (string memory rarityName);

    function constructTokenUri(
        RoyalLibrary.sQUEEN memory _queene,
        string memory _ipfsUri
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";

import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenLab} from "./IQueenLab.sol";
import {RoyalLibrary} from "../contracts/lib/RoyalLibrary.sol";
import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {IERC721} from "./IERC721.sol";

interface IQueenE is IRoyalContractBase, IERC721 {
    function _currentAuctionQueenE() external view returns (uint256);

    function contractURI() external view returns (string memory);

    function mint() external returns (uint256);

    function getQueenE(uint256 _queeneId)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function burn(uint256 queeneId) external;

    function lockMinter() external;

    function lockQueenTraitStorage() external;

    function lockQueenLab() external;

    function nominateSir(address _sir) external returns (bool);

    function getHouseSeats(uint8 _seatType) external view returns (uint256);

    function getHouseSeat(address addr) external view returns (uint256);

    function IsSir(address _address) external view returns (bool);

    function isSirReward(uint256 queeneId) external view returns (bool);

    function isMuseum(uint256 queeneId) external view returns (bool);

    function dnaMapped(uint256 dnaHash) external view returns (bool);

    function isHouseOfLordsFull() external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import {IBaseContractControllerUpgradeable} from "./IBaseContractControllerUpgradeable.sol";

interface IQueenAuctionHouse is IBaseContractControllerUpgradeable {
  event WithdrawnFallbackFunds(address withdrawer, uint256 amount);
  event AuctionSettled(
    uint256 indexed queeneId,
    address settler,
    uint256 amount
  );

  event AuctionStarted(
    uint256 indexed queeneId,
    uint256 startTime,
    uint256 endTime,
    uint256 initialBid
  );
  event AuctionExtended(uint256 indexed queeneId, uint256 endTime);

  event AuctionBid(
    uint256 indexed queeneId,
    address sender,
    uint256 value,
    bool extended
  );

  event AuctionEnded(uint256 indexed queeneId, address winner, uint256 amount);

  event AuctionTimeToleranceUpdated(uint256 timeBuffer);

  event AuctionInitialBidUpdated(uint256 initialBid);

  event AuctionDurationUpdated(uint256 duration);

  event AuctionMinBidIncrementPercentageUpdated(
    uint256 minBidIncrementPercentage
  );

  function endAuction() external;

  function bid(uint256 queeneId) external payable;

  function pause() external;

  function unpause() external;

  function setTimeTolerance(uint256 _timeTolerance) external;

  function setBidRaiseRate(uint8 _bidRaiseRate) external;

  function setInitialBid(uint256 _initialBid) external;

  function setDuration(uint256 _duration) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
/// @title IERC721 Interface

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

// LICENSE
// IERC721.sol modifies OpenZeppelin's interface IERC721.sol to user our own ERC165 standard:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol
//
// MODIFICATIONS:
// Its the latest `IERC721` interface from OpenZeppelin (v4.4.5) using our own ERC165 controller.

pragma solidity ^0.8.9;

import {IRoyalContractBase} from "../interfaces/IRoyalContractBase.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IRoyalContractBase {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.9;
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

interface IBaseContractControllerUpgradeable is IERC165Upgradeable {
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}