// SPDX-License-Identifier: MIT

/************************************************
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 *************************************************/

pragma solidity ^0.8.12;

import {IQueenTraits} from "IQueenTraits.sol";
import {IQueenStaff} from "IQueenStaff.sol";
import {BaseContractController} from "BaseContractController.sol";
import {RoyalLibrary} from "RoyalLibrary.sol";

//TODO: CREATE AND EMIT EVENTS
contract QueenTraits is BaseContractController, IQueenTraits {
    RoyalLibrary.sTRAIT[] internal traits;
    RoyalLibrary.sRARITY[] internal rarities;
    mapping(uint256 => mapping(uint256 => RoyalLibrary.sART[])) arts;
    mapping(uint256 => mapping(uint256 => RoyalLibrary.sART[])) removedArts;

    /************************** vCONSTRUCTOR REGION *************************************************** */

    constructor(IQueenStaff _queenStaff) {
        //set ERC165 pattern
        supportedInterfaces[type(IQueenTraits).interfaceId] = true;

        queenStaff = _queenStaff;

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

        rarities.push(
            RoyalLibrary.sRARITY({id: 1, rarityName: "COMUM", percentage: 89})
        );

        rarities.push(
            RoyalLibrary.sRARITY({id: 2, rarityName: "RARO", percentage: 10})
        );

        rarities.push(
            RoyalLibrary.sRARITY({
                id: 3,
                rarityName: "ULTRA-RARO",
                percentage: 1
            })
        );
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
        onlyEcosystemOrActor
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
        onlyEcosystemOrActor
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
        onlyEcosystemOrActor
        returns (RoyalLibrary.sRARITY[] memory raritiesList)
    {
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

        for (uint256 idx = 0; idx < rarities.length; idx++) {
            if (_onlyWithArt) {
                if (arts[_traitId][rarities[idx].id].length > 0)
                    _availableRarities[_availableRarities.length] = rarities[
                        idx
                    ];
            } else
                _availableRarities[_availableRarities.length] = rarities[idx];
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
        nonReentrant
        whenNotPaused
        onlyOwnerOrDeveloperOrDAO
        onlyOnImplementationOrDAO
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        return _setRarity(_rarityName, _percentage);
    }

    /**
     *IN
     *_rarityName: Name of Rarity you want to consult
     *OUT
     *rarity: Rarity object updated
     */
    function _setRarity(string memory _rarityName, uint256 _percentage)
        internal
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        if (getRarityByName(_rarityName).id != 0)
            return getRarityByName(_rarityName);

        //TODO: Make sure the sum of rarities percentage is 100

        rarities.push(
            rarity = RoyalLibrary.sRARITY({
                id: rarities.length,
                rarityName: _rarityName,
                percentage: _percentage
            })
        );

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
        nonReentrant
        whenNotPaused
        onlyOwnerOrDAO
        onlyOnImplementationOrDAO
        returns (RoyalLibrary.sRARITY memory rarity)
    {
        return _updateRarity(_rarityId, _newPercentage, _rarityNewName);
    }

    /**
     *IN
     *_rarityId: Id of Rarity you want to change the name
     *_percentage: if above 0, updates percentage. if not, dont
     *OUT
     *rarity: Rarity object updated
     */
    //TODO: Test scenario
    function _updateRarity(
        uint256 _rarityId,
        uint256 _newPercentage,
        string memory _rarityNewName
    ) internal returns (RoyalLibrary.sRARITY memory rarity) {
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

        emit RarityUpdated(
            rarities[getRarityIdxById(_rarityId)].id,
            rarities[getRarityIdxById(_rarityId)].rarityName,
            rarities[getRarityIdxById(_rarityId)].percentage
        );

        return rarities[getRarityIdxById(_rarityId)];
    }

    /************************** ^RARITY REGION ******************************************************** */

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
        onlyEcosystemOrActor
        returns (RoyalLibrary.sTRAIT memory trait)
    {
        for (uint256 idx = 0; idx < traits.length; idx++) {
            if (traits[idx].id == _id) return traits[idx];
        }

        return RoyalLibrary.sTRAIT({id: 0, traitName: "", enabled: 0});
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
        onlyEcosystemOrActor
        returns (RoyalLibrary.sTRAIT memory trait)
    {
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
     *OUT
     *traits: all traits written in contract
     */
    function getTraits(bool _onlyEnabled)
        public
        view
        override
        onlyEcosystemOrActor
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
                if (traits[idx].enabled == 1)
                    enabledTraits[newIdx++] = traits[idx];
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
        onlyOwnerOrArtistOrDAO
        onlyOnImplementationOrDAO
        whenNotPaused
    {
        require(
            _enabled >= 0 && _enabled <= 1,
            "Enabled value is numeric boolean! Must be 0 or 1!"
        );

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
    function CheckIfArtAlreadyExists(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    ) private view returns (bool exists, uint256 index) {
        //retrieve arts array
        if (arts[_traitId][_rarityId].length > 0) {
            for (
                uint256 idx = 0;
                idx < arts[_traitId][_rarityId].length;
                idx++
            ) {
                if (
                    keccak256(
                        abi.encodePacked(arts[_traitId][_rarityId][idx].uri)
                    ) == keccak256(abi.encodePacked(_artUri))
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
     *exists: true if uri already exists in the contract as removed art, false if not
     */
    function CheckIfArtInRemoved(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    ) private view returns (bool exists, uint256 index) {
        //retrieve arts array
        if (removedArts[_traitId][_rarityId].length > 0) {
            for (
                uint256 idx = 0;
                idx < removedArts[_traitId][_rarityId].length;
                idx++
            ) {
                if (
                    keccak256(
                        abi.encodePacked(
                            removedArts[_traitId][_rarityId][idx].uri
                        )
                    ) == keccak256(abi.encodePacked(_artUri))
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
    function GetArtByUri(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    )
        external
        view
        override
        onlyEcosystemOrActor
        returns (RoyalLibrary.sART memory art)
    {
        //retrieve arts array
        if (arts[_traitId][_rarityId].length > 0) {
            for (
                uint256 idx = 0;
                idx < arts[_traitId][_rarityId].length;
                idx++
            ) {
                if (
                    keccak256(
                        abi.encodePacked(arts[_traitId][_rarityId][idx].uri)
                    ) == keccak256(abi.encodePacked(_artUri))
                ) return arts[_traitId][_rarityId][idx];
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
        uint256 _rarityId,
        string memory _artUri
    ) public view onlyEcosystemOrActor returns (RoyalLibrary.sART memory art) {
        //retrieve arts array
        if (removedArts[_traitId][_rarityId].length > 0) {
            for (
                uint256 idx = 0;
                idx < removedArts[_traitId][_rarityId].length;
                idx++
            ) {
                if (
                    keccak256(
                        abi.encodePacked(
                            removedArts[_traitId][_rarityId][idx].uri
                        )
                    ) == keccak256(abi.encodePacked(_artUri))
                ) return removedArts[_traitId][_rarityId][idx];
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
    function GetArtCount(uint256 _traitId, uint256 _rarityId)
        external
        view
        override
        onlyEcosystemOrActor
        returns (uint256)
    {
        if (_rarityId > 0) return arts[_traitId][_rarityId].length;
        else {
            uint256 qtty = 0;

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
    function GetArt(
        uint256 _traitId,
        uint256 _rarityId,
        uint256 _artIdx
    )
        public
        view
        override
        onlyEcosystemOrActor
        returns (RoyalLibrary.sART memory art)
    {
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
    function GetArts(uint256 _traitId, uint256 _rarityId)
        public
        view
        override
        onlyEcosystemOrActor
        returns (RoyalLibrary.sART[] memory artsList)
    {
        return arts[_traitId][_rarityId];
    }

    /**
     *IN
     *_traitId: Id of the trait
     *_rarityId: rarity Id of the art
     *OUT
     *arts: list of sART objects for given trait:rarity in removed list
     */
    function GetRemovedArts(uint256 _traitId, uint256 _rarityId)
        public
        view
        override
        onlyEcosystemOrActor
        returns (RoyalLibrary.sART[] memory artsList)
    {
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
        uint256 _rarityId,
        string memory _artUri
    )
        external
        onlyOwnerOrArtistOrDAO
        onlyOnImplementationOrDAO
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
        require(getTrait(_traitId).enabled == 1, "Trait is disabled!");

        (bool exists, uint256 artIdx) = CheckIfArtAlreadyExists(
            _traitId,
            _rarityId,
            _artUri
        );
        require(
            !exists,
            string(abi.encodePacked("Art uri already in store (", artIdx, ")"))
        );

        //check if art is on removed list
        (exists, artIdx) = CheckIfArtInRemoved(_traitId, _rarityId, _artUri);

        if (exists) {
            for (
                uint256 idx = artIdx;
                idx < removedArts[_traitId][_rarityId].length - 1;
                idx++
            ) {
                removedArts[_traitId][_rarityId][idx] = removedArts[_traitId][
                    _rarityId
                ][idx + 1];
            }

            removedArts[_traitId][_rarityId].pop();
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
        uint256 _rarityId,
        string memory _artUri,
        bool _purge
    )
        public
        onlyActorOrDAO
        onlyOnImplementationOrDAO
        whenNotPaused
        returns (bool result)
    {
        require(
            keccak256(abi.encodePacked(_artUri)) !=
                keccak256(abi.encodePacked("")),
            "Art uri must have value!"
        );

        (bool found, uint256 index) = CheckIfArtAlreadyExists(
            _traitId,
            _rarityId,
            _artUri
        );

        //require(found == true, "No art found for given data!");
        if (!found) return false;

        (bool removedFound, uint256 removedIndex) = CheckIfArtInRemoved(
            _traitId,
            _rarityId,
            _artUri
        );

        if (!removedFound && !_purge) {
            removedArts[_traitId][_rarityId].push(
                arts[_traitId][_rarityId][index]
            );
        } else if (removedFound && _purge) {
            for (
                uint256 idx = removedIndex;
                idx < removedArts[_traitId][_rarityId].length - 1;
                idx++
            ) {
                removedArts[_traitId][_rarityId][idx] = removedArts[_traitId][
                    _rarityId
                ][idx + 1];
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

/// @title Interface for QueenE Traits contract

pragma solidity ^0.8.12;

//import {IERC165} from "IERC165.sol";

import {IBaseContractController} from "IBaseContractController.sol";
import {RoyalLibrary} from "RoyalLibrary.sol";

interface IQueenTraits is IBaseContractController {
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

    event ArtCreated(uint256 traitId, uint256 rarityId, uint256 requestId);
    event ArtRemoved(uint256 traitId, uint256 rarityId, uint256 requestId);
    event ArtPurged(uint256 traitId, uint256 rarityId, uint256 requestId);

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

    function GetArtByUri(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    ) external returns (RoyalLibrary.sART memory art);

    function GetArtCount(uint256 _traitId, uint256 _rarityId)
        external
        view
        returns (uint256 quantity);

    function GetArt(
        uint256 _traitId,
        uint256 _rarityId,
        uint256 _artIdx
    ) external view returns (RoyalLibrary.sART memory art);

    function GetArts(uint256 _traitId, uint256 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);

    function GetRemovedArts(uint256 _traitId, uint256 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);
}

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

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.12;

interface IBaseContractController {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.12;

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
        string uri;
    }

    struct sDNA {
        uint256 traitId;
        uint256 rarityId;
        uint256 trace;
    }

    struct sBLOOD {
        uint256 traitId;
        uint256 rarityId;
        string artUri;
    }

    struct sQUEEN {
        uint256 queeneId;
        sBLOOD[] blueBlood;
        sDNA[] dna;
        string finalArt;
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT

/// @title Interface for Queen Staff Contract

pragma solidity ^0.8.12;

interface IQueenStaff {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOnImplementation() external view returns (bool status);

    function artist() external view returns (address);

    function dao() external returns (address);

    function developer() external view returns (address);

    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT

/// @title A base contract with implementation control

/************************************************
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 *************************************************/

pragma solidity ^0.8.12;

//import {ERC165} from "ERC165.sol";
import {Pausable} from "Pausable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Ownable} from "Ownable.sol";
import {Address} from "Address.sol";

import {RoyalLibrary} from "RoyalLibrary.sol";
import {IBaseContractController} from "IBaseContractController.sol";
import {IQueenStaff} from "IQueenStaff.sol";

contract BaseContractController is
    IBaseContractController,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    IQueenStaff internal queenStaff;

    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping(address => bool) internal allowedEcosystem;

    /************************** vCONTROLLER REGION *************************************************** */

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return supportedInterfaces[interfaceID];
    }

    /**
     *IN
     *_allowee: address of contract to be allowed to use this contract
     *OUT
     *status: allow final result on mapping
     */
    function allowOnEcosystem(address _allowee)
        public
        onlyOwner
        returns (bool status)
    {
        require(Address.isContract(_allowee), "Invalid address!");

        allowedEcosystem[_allowee] = true;
        return allowedEcosystem[_allowee];
    }

    /**
     *IN
     *_disallowee: address of contract to be disallowed to use this contract
     *OUT
     *status: allow final result on mapping
     */
    function disallowOnEcosystem(address _disallowee)
        public
        onlyOwner
        returns (bool status)
    {
        require(Address.isContract(_disallowee), "Invalid address!");

        allowedEcosystem[_disallowee] = false;
        return allowedEcosystem[_disallowee];
    }

    /**
     *IN
     *_allowee: address to verify allowance
     *OUT
     *status: allow current status for contract
     */
    function isAllowedOnEconsystem(address _allowee)
        public
        view
        returns (bool status)
    {
        require(Address.isContract(_allowee), "Invalid address!");

        return allowedEcosystem[_allowee];
    }

    /**
     *IN
     *_queenStaff: address of queen staff contract
     *OUT
     *newQueenStaff: new QueenStaff contract address
     */
    function setQueenStaff(IQueenStaff _queenStaff)
        external
        nonReentrant
        whenNotPaused
        onlyOwnerOrDAO
        onlyOnImplementationOrDAO
    {
        _setQueenStaff(_queenStaff);
    }

    /**
     *IN
     *_queenStaff: address of queen staff contract
     *OUT
     *newQueenStaff: new QueenStaff contract address
     */
    function _setQueenStaff(IQueenStaff _queenStaff) internal {
        queenStaff = _queenStaff;
    }

    /************************** ^vCONTROLLER REGION *************************************************** */

    /************************** vMODIFIERS REGION ***************************************************** */

    modifier onlyArtist() {
        require(msg.sender == queenStaff.artist(), "Not Owner nor Artist");
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == queenStaff.developer(), "Not Owner nor Artist");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == queenStaff.minter(), "Not Owner nor Artist");
        _;
    }

    modifier onlyActor() {
        require(
            msg.sender == owner() ||
                msg.sender == queenStaff.artist() ||
                msg.sender == queenStaff.developer(),
            "Not a valid Actor"
        );
        _;
    }

    modifier onlyActorOrDAO() {
        require(
            msg.sender == owner() ||
                msg.sender == queenStaff.artist() ||
                msg.sender == queenStaff.developer() ||
                msg.sender == queenStaff.dao(),
            "Not a valid Actor"
        );
        _;
    }

    modifier onlyEcosystemOrActor() {
        require(
            msg.sender == owner() ||
                msg.sender == queenStaff.artist() ||
                msg.sender == queenStaff.developer() ||
                isAllowedOnEconsystem(msg.sender),
            "Not a valid Actor"
        );
        _;
    }

    modifier onlyEcosystemOrActorOrDAO() {
        require(
            msg.sender == owner() ||
                msg.sender == queenStaff.artist() ||
                msg.sender == queenStaff.developer() ||
                msg.sender == queenStaff.dao() ||
                isAllowedOnEconsystem(msg.sender),
            "Not a valid Actor"
        );
        _;
    }

    modifier onlyOwnerOrArtist() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.artist(),
            "Not Owner nor Artist"
        );
        _;
    }

    modifier onlyOwnerOrDeveloper() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.developer(),
            "Not Owner nor Artist"
        );
        _;
    }

    modifier onlyOwnerOrDeveloperOrDAO() {
        require(
            msg.sender == owner() ||
                msg.sender == queenStaff.developer() ||
                msg.sender == queenStaff.dao(),
            "Not Owner nor Developer nor DAO"
        );
        _;
    }

    modifier onlyOwnerOrArtistOrDAO() {
        require(
            msg.sender == owner() ||
                msg.sender == queenStaff.artist() ||
                msg.sender == queenStaff.dao(),
            "Not Owner nor Artist nor DAO"
        );
        _;
    }
    modifier onlyOwnerOrDAO() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.dao(),
            "Not Owner nor DAO"
        );
        _;
    }

    modifier onlyOwnerOrMinter() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.minter(),
            "Not Owner nor Artist"
        );
        _;
    }

    modifier onlyOnImplementationOrDAO() {
        require(
            queenStaff.isOnImplementation() || msg.sender == queenStaff.dao(),
            "Not On Implementation and sender is not DAO"
        );
        _;
    }

    modifier onlyOnImplementationOrPaused() {
        require(
            queenStaff.isOnImplementation() || paused(),
            "Not On Implementation nor Paused"
        );
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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