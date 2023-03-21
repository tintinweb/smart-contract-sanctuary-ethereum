//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/*
 *     █████  ██    ██ ████████  ██████   ██████  ██████   █████  ██████  ██   ██ 
 *    ██   ██ ██    ██    ██    ██    ██ ██       ██   ██ ██   ██ ██   ██ ██   ██ 
 *    ███████ ██    ██    ██    ██    ██ ██   ███ ██████  ███████ ██████  ███████ 
 *    ██   ██ ██    ██    ██    ██    ██ ██    ██ ██   ██ ██   ██ ██      ██   ██ 
 *    ██   ██  ██████     ██     ██████   ██████  ██   ██ ██   ██ ██      ██   ██ 
 *                                                                                
 *                                                                                
 *    ███████ ████████  ██████  ██████   █████   ██████  ███████                  
 *    ██         ██    ██    ██ ██   ██ ██   ██ ██       ██                       
 *    ███████    ██    ██    ██ ██████  ███████ ██   ███ █████                    
 *         ██    ██    ██    ██ ██   ██ ██   ██ ██    ██ ██                       
 *    ███████    ██     ██████  ██   ██ ██   ██  ██████  ███████                  
 *
 *
 *    GALAXIS - Autograph Trait Storage
 *
 */

import "./UTGenericDroppableStorage.sol";

contract UTAutographStorage is UTGenericDroppableStorage {

    uint8       public constant     TRAIT_TYPE = 5;    // Autograph Storage

    struct storageStruct {
        uint8   state;                  // The state of the Autograph
        string  ipfsHash;               // The IPFS hash of the Autograph (if it was signed)
    }

    // -- Trait storage per tokenID --
    // tokenID => storageStruct value
    mapping(uint16 => storageStruct) public data;

    // Events
    event updateTraitEvent(uint16 indexed _tokenId, uint8 _newData);

    constructor(
        address _registry,
        uint16 _traitId
    ) UTGenericStorage(_registry, _traitId) {
    }

    // update multiple token values at once
    function setData(uint16[] memory _tokenIds, storageStruct[] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i].state);
        }
    }

    // update one token value
    function setValue(uint16 _tokenId, storageStruct memory _value) public onlyAllowed {
        data[_tokenId] = _value;
        emit updateTraitEvent(_tokenId, _value.state);
    }

    // get trait value for one token
    function getValue(uint16 _tokenId) public view returns (storageStruct memory) {
        return data[_tokenId];
    }

    // get trait values for an array of tokens
    function getValues(uint16[] memory _tokenIds) public view returns (storageStruct[] memory) {
        storageStruct[] memory retval = new storageStruct[](_tokenIds.length);
        for(uint16 i = 0; i < _tokenIds.length; i++) {
            retval[i] = data[_tokenIds[i]];
        }
        return retval;
    }

    // get trait values for a range of tokens
    function getValues(uint16 _start, uint16 _len) public view returns (storageStruct[] memory) {
        storageStruct[] memory retval = new storageStruct[](_len);
        for(uint16 i = 0; i < _len; i++) {
            retval[i] = data[i+_start];
        }
        return retval;
    }

    // --- For interface: IGenericDroppableStorage ---
    // These functions must be implemented for this trait to be used with UTGenericDropper contract

    // Update one token value to TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return bool - was the trait actually opened (or already in a non initial state)?
    function addTraitToToken(uint16 _tokenId) public onlyAllowed returns(bool wasSet) {
        if (data[_tokenId].state == TRAIT_INITIAL_VALUE) {
            data[_tokenId].state = TRAIT_OPEN_VALUE;
            emit updateTraitEvent(_tokenId, TRAIT_OPEN_VALUE);
            return true;
        } else {
            return false;            
        }
    }

    // Update multiple token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: number of tokens actually set (not counting tokens already had the trait opened)
    // addTraitToToken() was not called from the loop to skip the recurring "onlyAllowed"
    function addTraitOnMultiple(uint16[] memory tokenIds) public onlyAllowed returns(uint16 changes) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            if (data[tokenIds[i]].state == TRAIT_INITIAL_VALUE) {
                data[tokenIds[i]].state = TRAIT_OPEN_VALUE;
                emit updateTraitEvent(tokenIds[i], TRAIT_OPEN_VALUE);
                changes++;
            }
        }
    }

    // Was the trait activated (meaning it has non zero uint8 value)
    function hasTrait(uint16 _tokenId) public view returns(bool) {
        return getValue(_tokenId).state != 0;
    }

    // Read the generic part of the trait (the uint8 status value)
    function getUint8Value(uint16 _tokenId) public view returns(uint8) {
        return getValue(_tokenId).state;
    }

    // Read the generic part of the trait for multiple tokens (the uint8 status value)
    function getUint8Values(uint16[] memory _tokenIds) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_tokenIds.length);
        for(uint16 i = 0; i < _tokenIds.length; i++) {
            retval[i] = data[_tokenIds[i]].state;
        }
        return retval;
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";
import "../interfaces/IGenericDroppableStorage.sol";
import "./UTGenericStorage.sol";

abstract contract UTGenericDroppableStorage is UTGenericStorage, IGenericDroppableStorage {
    uint8              constant     TRAIT_INITIAL_VALUE = 0;
    uint8              constant     TRAIT_OPEN_VALUE = 1;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IECRegistry {
    function addTrait(traitStruct[] memory) external; 
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    // ---- Change start ----
    function setTrait(uint16 traitID, uint16 tokenID, bool) external returns (bool);
    function setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) external;
    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool _value) external returns(uint16 changes);
    function setTraitOnMultipleUnchecked(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) external;
    function getTrait(uint16 id) external view returns (traitStruct memory);
    function getTraits() external view returns (traitStruct[] memory);
    // ---- Change end ----
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
    function getDefaultTraitControllerByType(uint8) external view returns (address);
    function setDefaultTraitControllerType(address, uint8) external;
    function setTraitControllerAccess(address, uint16, bool) external;
    function traitCount() external view returns (uint16);

    struct traitStruct {
        uint16  id;
        uint8   traitType;              // 0 normal (1bit), 1 range, 2 inverted range, >=3 with storageImplementer
        uint16  start;
        uint16  end;
        bool    enabled;
        address storageImplementer;     // address of the smart contract that will implement the storage for the trait
        string  ipfsHash;
        string  name;
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IGenericDroppableStorage {
    // Update one token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: bool - was the trait actually opened?
    function addTraitToToken(uint16 _tokenId) external returns(bool);

    // Update multiple token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: number of tokens actually set (not counting tokens already had the trait opened)
    function addTraitOnMultiple(uint16[] memory tokenIds) external returns(uint16 changes);

    // Was the trait activated (meaning it has non zero uint8 value)
    function hasTrait(uint16 _tokenId) external view returns(bool);

    // // Was the trait activated (meaning it has non zero uint8 value) on multiple token
    // function haveTrait(uint16[] memory _tokenId) external view returns(bool[] memory);

    // Read the generic part of the trait (the uint8 status value)
    function getUint8Value(uint16 _tokenId) external view returns(uint8);

    // Read the generic part of the trait for multiple tokens (the uint8 status value)
    function getUint8Values(uint16[] memory _tokenIds) external view returns (uint8[] memory);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";

abstract contract UTGenericStorage {
    uint16      public immutable    traitId;
    IECRegistry public immutable    ECRegistry;

    constructor(
        address _registry,
        uint16 _traitId
    ) {       
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "UTStorage: Not Authorised"
        );
        _;
    }
}