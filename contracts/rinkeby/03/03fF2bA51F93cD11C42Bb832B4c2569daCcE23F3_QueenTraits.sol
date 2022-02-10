// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Address} from "Address.sol";
import {Strings} from "Strings.sol";
import {Address} from "Address.sol";
import {Pausable} from "Pausable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Ownable} from "Ownable.sol";

import {RoyalLibrary} from "RoyalLibrary.sol";
import {IQueenTraits} from "IQueenTraits.sol";

contract QueenTraits is IQueenTraits, Pausable, ReentrancyGuard, Ownable {
    address internal artist;

    bool internal onImplementation;

    RoyalLibrary.sTRAIT[] internal traits;
    RoyalLibrary.sRARITY[] internal rarities;
    mapping(uint256 => mapping(uint16 => RoyalLibrary.sART[])) arts;
    mapping(uint256 => mapping(uint16 => RoyalLibrary.sART[])) removedArts;

    /************************** vCONSTRUCTOR REGION *************************************************** */

    constructor() {
        onImplementation = true;

        traits.push(
            RoyalLibrary.sTRAIT({id: 1, traitName: "BACKGROUND", enabled: 1})
        );

        traits.push(
            RoyalLibrary.sTRAIT({id: 2, traitName: "MOLDURA", enabled: 1})
        );
        traits.push(
            RoyalLibrary.sTRAIT({id: 3, traitName: "ACESSORIO", enabled: 1})
        );
        traits.push(
            RoyalLibrary.sTRAIT({id: 4, traitName: "ROSTO", enabled: 1})
        );
        traits.push(
            RoyalLibrary.sTRAIT({id: 5, traitName: "CORPO", enabled: 1})
        );

        rarities.push(RoyalLibrary.sRARITY({id: 1, rarityName: "COMUM"}));

        rarities.push(RoyalLibrary.sRARITY({id: 2, rarityName: "RARO"}));

        rarities.push(RoyalLibrary.sRARITY({id: 3, rarityName: "ULTRA-RARO"}));
    }

    /************************** ^CONSTRUCTOR REGION *************************************************** */

    /************************** vCONTROLLER REGION *************************************************** */

    /**
     *IN
     *OUT
     */
    function implementationEnded() public onlyOwner {
        onImplementation = false;
    }

    /**
     *IN
     *OUT
     *status: current implementation status
     */
    function getImplementationStatus()
        public
        view
        onlyOwner
        returns (bool status)
    {
        return onImplementation;
    }

    /************************** ^vCONTROLLER REGION *************************************************** */

    /************************** vMODIFIERS REGION ***************************************************** */

    /**
     * @notice Require that message sender is either owner or artist.
     */
    modifier onlyOwnerOrArtist() {
        require(
            msg.sender == owner() || msg.sender == artist,
            "Not Owner nor Artist"
        );
        _;
    }

    modifier onlyOnImplementationOrVoted(uint256 requestId) {
        if (onImplementation) {
            require(onImplementation, "Not On Implementation");
            _;
        } else {
            //TODO: verify DAO permission
            require(onImplementation, "Not On Implementation");
            _;
        }
    }

    modifier onlyOnImplementationOrPaused() {
        require(
            onImplementation || paused(),
            "Not On Implementation nor Paused"
        );
        _;
    }

    /************************** ^MODIFIERS REGION ***************************************************** */

    /************************** vARTIST REGION ******************************************************** */

    /**
     *IN
     *OUT
     *currentArtit: current artist address allowed on contract
     */
    function getArtist() public view onlyOwner returns (address currentArtist) {
        return artist;
    }

    /**
     *IN
     *_newArtist: address of artist tha will upload arts to contract
     *OUT
     */
    function setArtist(address _newArtist)
        external
        override
        nonReentrant
        whenNotPaused
        onlyOwner
        onlyOnImplementationOrVoted(0)
        returns (address newArtist)
    {
        require(
            _newArtist != RoyalLibrary.burnAddress,
            "Invalid artist address! Burn address!"
        );

        require(!Address.isContract(_newArtist), "Must be a wallet address!");

        artist = _newArtist;
        return _newArtist;
    }

    /**
     *IN
     *_newArtist: address of artist tha will upload arts to contract
     *OUT
     */
    function _setArtist(address _newArtist)
        internal
        returns (address newArtist)
    {
        require(
            _newArtist != RoyalLibrary.burnAddress,
            "Invalid artist address! Burn address!"
        );

        require(!Address.isContract(_newArtist), "Must be a wallet address!");

        artist = _newArtist;
        newArtist = _newArtist;

        emit ArtistSet(_newArtist);
    }

    /************************** ^ARTIST REGION ******************************************************** */

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
        onlyOwner
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        for (uint256 idx = 0; idx < rarities.length; idx++) {
            if (rarities[idx].id == _rarityId) return rarities[idx];
        }

        return RoyalLibrary.sRARITY({id: 0, rarityName: ""});
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
        onlyOwner
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        for (uint256 idx = 0; idx < rarities.length; idx++) {
            if (
                keccak256(abi.encodePacked(rarities[idx].rarityName)) ==
                keccak256(abi.encodePacked(_rarityName))
            ) return rarities[idx];
        }

        return RoyalLibrary.sRARITY({id: 0, rarityName: ""});
    }

    /**
     *IN
     *OUT
     *rarities: Array with all rarities
     */
    function getRarities()
        public
        view
        onlyOwner
        returns (RoyalLibrary.sRARITY[] memory raritiesList)
    {
        return rarities;
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
        returns (uint256 rarityIdx, bool found)
    {
        require(_rarityId > 0, "Rarity id must be greater than zero!");

        for (uint256 idx = 0; idx < rarities.length; idx++) {
            if (rarities[idx].id == _rarityId) {
                return (idx, true);
            }
        }

        return (0, false);
    }

    /**
     *IN
     *_rarityName: Name of Rarity you want to consult
     *OUT
     *rarity: Rarity object updated
     */
    function setRarity(string memory _rarityName)
        external
        override
        nonReentrant
        whenNotPaused
        onlyOwner
        onlyOnImplementationOrVoted(0)
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        return _setRarity(_rarityName);
    }

    /**
     *IN
     *_rarityName: Name of Rarity you want to consult
     *OUT
     *rarity: Rarity object updated
     */
    function _setRarity(string memory _rarityName)
        internal
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        RoyalLibrary.sRARITY memory foundName = getRarityByName(_rarityName);
        if (foundName.id != 0) return foundName;

        //new rarity
        uint256 newIdx = rarities.length;
        rarity = RoyalLibrary.sRARITY({id: newIdx, rarityName: _rarityName});

        rarities.push(rarity);

        emit RarityCreated(newIdx, _rarityName);
    }

    /**
     *IN
     *_rarityId: Id of Rarity you want to change the name
     *OUT
     *rarity: Rarity object updated
     */
    function changeRarityName(uint256 _rarityId, string memory _rarityNewName)
        public
        onlyOwner
        onlyOnImplementationOrVoted(0)
        whenNotPaused
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        (uint256 idx, bool found) = getRarityIdxById(_rarityId);

        if (!found)
            //no rarity found for id
            return RoyalLibrary.sRARITY({id: 0, rarityName: ""});
        //update name
        rarities[idx].rarityName = _rarityNewName;

        return rarities[idx];
    }

    /************************** ^RARITY REGION ******************************************************** */

    /************************** vTRAITS REGION ******************************************************** */

    /**
     *IN
     *_idx: index of trait on array
     *OUT
     *trait: trait found in array
     */
    function getTrait(uint256 _idx)
        public
        view
        onlyOwnerOrArtist
        returns (RoyalLibrary.sTRAIT memory trait)
    {
        require(
            _idx >= 0 && _idx < traits.length,
            string(
                abi.encodePacked(
                    "Index out of range (min 0; max ",
                    Strings.toString(traits.length),
                    "}!"
                )
            )
        );

        trait = traits[_idx];
        return trait;
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
        onlyOwnerOrArtist
        returns (RoyalLibrary.sTRAIT memory trait)
    {
        require(
            keccak256(abi.encodePacked(_traitName)) !=
                keccak256(abi.encodePacked("")),
            "Trait name must have value!"
        );

        for (uint256 idx = 0; idx < traits.length; idx++) {
            if (
                keccak256(abi.encodePacked(traits[idx].traitName)) ==
                keccak256(abi.encodePacked(_traitName))
            ) return traits[idx];
        }

        return RoyalLibrary.sTRAIT({id: 0, traitName: "", enabled: 0});
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
            "Trait name must have value!"
        );

        for (uint256 idx = 0; idx < traits.length; idx++) {
            if (
                keccak256(abi.encodePacked(traits[idx].traitName)) ==
                keccak256(abi.encodePacked(_traitName))
            ) return idx;
        }

        return 0;
    }

    /**
     *IN
     *_traitId: Id of the trait
     *OUT
     *traitIdx: idx of trait found in array
     */
    function getTraitIdxById(uint256 _traitId)
        private
        view
        returns (uint256 traitIdx)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");

        for (uint256 idx = 0; idx < traits.length; idx++) {
            if (traits[idx].id == _traitId) return idx;
        }

        return 0;
    }

    /**
     *IN
     *OUT
     *traits: all traits written in contract
     */
    function getTraits()
        public
        view
        onlyOwnerOrArtist
        returns (RoyalLibrary.sTRAIT[] memory _traits)
    {
        return traits;
    }

    /**
     *IN
     *OUT
     *traits: all traits written in contract
     */
    function getEnabledTraits()
        public
        view
        onlyOwnerOrArtist
        returns (RoyalLibrary.sTRAIT[] memory _traits)
    {
        uint256 itens = 0;

        for (uint256 idx = 0; idx < traits.length; idx++) {
            if (checkTraitEnabled(traits[idx].id)) itens++;
        }

        RoyalLibrary.sTRAIT[] memory enabledTraits = new RoyalLibrary.sTRAIT[](
            itens
        );
        uint256 newIdx = 0;
        for (uint256 idx = 0; idx < traits.length; idx++) {
            if (checkTraitEnabled(traits[idx].id))
                enabledTraits[newIdx++] = traits[idx];
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
        onlyOwnerOrArtist
        onlyOnImplementationOrVoted(0)
        whenNotPaused
        returns (RoyalLibrary.sTRAIT memory trait)
    {
        require(
            keccak256(abi.encodePacked(_traitName)) !=
                keccak256(abi.encodePacked("")),
            "Trait name must have value!"
        );
        require(
            _enabled >= 0 && _enabled <= 1,
            "Enabled value is numeric boolean! Must be 0 or 1!"
        );

        //check is trait already exists
        uint256 traitIdx = getTraitIdxByName(_traitName);

        if (traitIdx >= 0) //already exists
        {
            traits[traitIdx].enabled = _enabled;
            return traits[traitIdx];
        } else {
            uint256 newIdx = traits.length;
            RoyalLibrary.sTRAIT memory newTrait = RoyalLibrary.sTRAIT({
                id: newIdx,
                traitName: _traitName,
                enabled: _enabled
            });
            traits.push(newTrait);
            return newTrait;
        }
    }

    /**
     *IN
     *OUT
     *traits: all traits written in contract
     */
    function checkTraitEnabled(uint256 _traitId)
        private
        view
        returns (bool enabled)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");
        return traits[getTraitIdxById(_traitId)].enabled == 1;
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
    function CheckIfArtAlreadyExists(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) private view returns (bool exists) {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        //retrieve arts array
        RoyalLibrary.sART[] memory artList = arts[_traitId][_rarityId];

        if (artList.length > 0) {
            for (uint256 idx = 0; idx < artList.length; idx++) {
                if (
                    keccak256(abi.encodePacked(artList[idx].uri)) ==
                    keccak256(abi.encodePacked(_artUri))
                ) return true;
            }
        }

        return false;
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *_artUri: Uri of art that want to be checked
     *OUT
     *exists: true if uri already exists in the contract as removed art, false if not
     */
    function CheckIfArtInRemoved(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) private view returns (bool exists) {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        //retrieve arts array
        RoyalLibrary.sART[] memory artList = removedArts[_traitId][_rarityId];

        if (artList.length > 0) {
            for (uint256 idx = 0; idx < artList.length; idx++) {
                if (
                    keccak256(abi.encodePacked(artList[idx].uri)) ==
                    keccak256(abi.encodePacked(_artUri))
                ) return true;
            }
        }

        return false;
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *_artUri: Uri of art that want to be checked
     *OUT
     *index: index of uri on art array
     *found: true if found uri in array, false if not
     */
    function GetArtIdxByUri(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) private view returns (uint256 index, bool found) {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        //retrieve arts array
        RoyalLibrary.sART[] memory artList = arts[_traitId][_rarityId];

        if (artList.length > 0) {
            for (uint256 idx = 0; idx < artList.length; idx++) {
                if (
                    keccak256(abi.encodePacked(artList[idx].uri)) ==
                    keccak256(abi.encodePacked(_artUri))
                ) return (idx, true);
            }
        }

        return (0, false);
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *_artUri: Uri of art that want to be checked
     *OUT
     *index: index of uri on art array
     *found: true if found uri in array, false if not
     */
    function GetRemovedArtIdxByUri(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) private view returns (uint256 index, bool found) {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        //retrieve arts array
        RoyalLibrary.sART[] memory artList = removedArts[_traitId][_rarityId];

        if (artList.length > 0) {
            for (uint256 idx = 0; idx < artList.length; idx++) {
                if (
                    keccak256(abi.encodePacked(artList[idx].uri)) ==
                    keccak256(abi.encodePacked(_artUri))
                ) return (idx, true);
            }
        }

        return (0, false);
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *_artUri: Uri of art that want to be checked
     *OUT
     *art: art found with uri
     */
    function GetArtByUri(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) public view onlyOwnerOrArtist returns (RoyalLibrary.sART memory art) {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        //retrieve arts array
        RoyalLibrary.sART[] memory artList = arts[_traitId][_rarityId];

        if (artList.length > 0) {
            for (uint256 idx = 0; idx < artList.length; idx++) {
                if (
                    keccak256(abi.encodePacked(artList[idx].uri)) ==
                    keccak256(abi.encodePacked(_artUri))
                ) return artList[idx];
            }
        }

        return RoyalLibrary.sART({traitId: 0, rarityId: 0, uri: ""});
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *_artUri: Uri of art that want to be checked
     *OUT
     *art: art found with uri
     */
    function GetRemovedArtByUri(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) public view onlyOwnerOrArtist returns (RoyalLibrary.sART memory art) {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        //retrieve arts array
        RoyalLibrary.sART[] memory artList = removedArts[_traitId][_rarityId];

        if (artList.length > 0) {
            for (uint256 idx = 0; idx < artList.length; idx++) {
                if (
                    keccak256(abi.encodePacked(artList[idx].uri)) ==
                    keccak256(abi.encodePacked(_artUri))
                ) return artList[idx];
            }
        }

        return RoyalLibrary.sART({traitId: 0, rarityId: 0, uri: ""});
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *OUT
     *quantity: quantity of arts found for trait and rarity
     */
    function GetArtCount(uint256 _traitId, uint16 _rarityId)
        public
        view
        onlyOwnerOrArtist
        returns (uint256 quantity)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");

        //retrieve arts array
        RoyalLibrary.sART[] memory artList = arts[_traitId][_rarityId];

        return artList.length;
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *_artIdx: index of art in array
     *OUT
     *art: sART object for given inputs
     */
    function GetArt(
        uint256 _traitId,
        uint16 _rarityId,
        uint256 _artIdx
    ) public view onlyOwnerOrArtist returns (RoyalLibrary.sART memory art) {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            arts[_traitId][_rarityId].length <= (_artIdx + 1),
            "No Art at given index!"
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
    function GetArts(uint256 _traitId, uint16 _rarityId)
        public
        view
        onlyOwnerOrArtist
        returns (RoyalLibrary.sART[] memory artsList)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");

        return arts[_traitId][_rarityId];
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *OUT
     *arts: list of sART objects for given trait:rarity in removed list
     */
    function GetRemovedArts(uint256 _traitId, uint16 _rarityId)
        public
        view
        onlyOwnerOrArtist
        returns (RoyalLibrary.sART[] memory artsList)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");

        return removedArts[_traitId][_rarityId];
    }

    /**
     *IN
     * _traitId: Id of the trait
     * _rarityId: rarity Id of the trait
     * _artUri: Uri of art on IPFS
     *OUT
     * art: final art object in store
     */
    //TODO: Change to set multiple arts in same transaction (limit to 10 and test)
    function SetArt(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    )
        public
        onlyOwnerOrArtist
        onlyOnImplementationOrVoted(0)
        whenNotPaused
        returns (RoyalLibrary.sART memory art)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );
        require(checkTraitEnabled(_traitId), "Trait is disabled!");

        require(
            !CheckIfArtAlreadyExists(_traitId, _rarityId, _artUri),
            "Art uri already in store"
        );

        //check if art is on removed list
        (uint256 index, bool found) = GetRemovedArtIdxByUri(
            _traitId,
            _rarityId,
            _artUri
        );

        if (found) {
            for (
                uint256 idx = index;
                idx < removedArts[_traitId][_rarityId].length;
                idx++
            ) {
                removedArts[_traitId][_rarityId][idx] = removedArts[_traitId][
                    _rarityId
                ][idx + 1];
            }
        }

        RoyalLibrary.sART memory finalArt = RoyalLibrary.sART({
            traitId: _traitId,
            rarityId: _rarityId,
            uri: _artUri
        });

        arts[_traitId][_rarityId].push(finalArt);

        return finalArt;
    }

    /**
     *IN
     * _traitId: Id of the trait
     * _rarityId: rarity Id of the trait
     * _artUri: Uri of art on IPFS
     *OUT
     * art: final art object in store
     */
    function RemoveArt(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    )
        public
        onlyOwnerOrArtist
        onlyOnImplementationOrVoted(0)
        whenNotPaused
        returns (bool result)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        (uint256 index, bool found) = GetArtIdxByUri(
            _traitId,
            _rarityId,
            _artUri
        );

        //require(found == true, "No art found for given data!");
        if (!found) return false;

        RoyalLibrary.sART memory artToRemove = arts[_traitId][_rarityId][index];

        if (!CheckIfArtInRemoved(_traitId, _rarityId, _artUri)) {
            removedArts[_traitId][_rarityId].push(artToRemove);
        }

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
        return true;
    }

    /**
     *IN
     * _traitId: Id of the trait
     * _rarityId: rarity Id of the trait
     * _artUri: Uri of art on IPFS
     *_requestId: id of the DAO voted request authorizing the purge
     *OUT
     * deleted: if art was purged
     */
    function PurgeArt(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri,
        uint256 _requestId
    )
        public
        onlyOwner
        onlyOnImplementationOrVoted(_requestId)
        returns (bool result)
    {
        require(_traitId > 0, "Trait id must be greater than zero!");
        require(_rarityId > 0, "Rarity must be greater than zero!");
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        (uint256 index, bool found) = GetArtIdxByUri(
            _traitId,
            _rarityId,
            _artUri
        );

        //require(found == true, "No art found for given data!");
        if (!found) return false;

        if (CheckIfArtInRemoved(_traitId, _rarityId, _artUri)) {
            (uint256 removedIdx, bool found) = GetRemovedArtIdxByUri(
                _traitId,
                _rarityId,
                _artUri
            );

            if (found) {
                for (
                    uint256 idx = removedIdx;
                    idx < removedArts[_traitId][_rarityId].length;
                    idx++
                ) {
                    removedArts[_traitId][_rarityId][idx] = removedArts[
                        _traitId
                    ][_rarityId][idx + 1];
                }
            }
            removedArts[_traitId][_rarityId].pop();
        }

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
        return true;
    }
    /************************** ^ART REGION ******************************************************** */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

import "Context.sol";

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

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.11;

library RoyalLibrary {
    struct sTRAIT {
        uint256 id;
        string traitName;
        uint8 enabled; //0 - disabled; 1 - enabled;
    }

    struct sRARITY {
        uint256 id;
        string rarityName;
    }

    struct sART {
        uint256 traitId;
        uint16 rarityId;
        string uri;
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

pragma solidity ^0.8.11;

import {RoyalLibrary} from "RoyalLibrary.sol";

interface IQueenTraits {
    event RarityCreated(uint256 indexed rarityId, string rarityName);
    event ArtistSet(address indexed artistAddress);

    function getRarityById(uint256 _rarityId)
        external
        returns (RoyalLibrary.sRARITY memory rarity);

    function getRarityByName(string memory _rarityName)
        external
        returns (RoyalLibrary.sRARITY memory rarity);

    function getRarities()
        external
        returns (RoyalLibrary.sRARITY[] memory raritiesList);

    function setRarity(string memory _rarityName)
        external
        returns (RoyalLibrary.sRARITY memory rarity);

    function changeRarityName(uint256 _rarityId, string memory _rarityNewName)
        external
        returns (RoyalLibrary.sRARITY memory rarity);

    function getTrait(uint256 _idx)
        external
        returns (RoyalLibrary.sTRAIT memory trait);

    function getTraitByName(string memory _traitName)
        external
        returns (RoyalLibrary.sTRAIT memory trait);

    function getTraits()
        external
        returns (RoyalLibrary.sTRAIT[] memory _traits);

    function getEnabledTraits()
        external
        returns (RoyalLibrary.sTRAIT[] memory _traits);

    function setTrait(string memory _traitName, uint8 _enabled)
        external
        returns (RoyalLibrary.sTRAIT memory trait);

    function GetArtByUri(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) external returns (RoyalLibrary.sART memory art);

    function GetArtCount(uint256 _traitId, uint16 _rarityId)
        external
        returns (uint256 quantity);

    function GetArt(
        uint256 _traitId,
        uint16 _rarityId,
        uint256 _artIdx
    ) external returns (RoyalLibrary.sART memory art);

    function GetArts(uint256 _traitId, uint16 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);

    function GetRemovedArts(uint256 _traitId, uint16 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);

    function SetArt(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) external returns (RoyalLibrary.sART memory art);

    function RemoveArt(
        uint256 _traitId,
        uint16 _rarityId,
        string memory _artUri
    ) external returns (bool result);

    function setArtist(address _newArtist) external returns (address newArtist);
}