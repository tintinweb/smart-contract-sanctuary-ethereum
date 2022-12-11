//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/* 
 *     █████  ██████  ██████   ██████  ██ ███    ██ ████████ ███    ███ ███████ ███    ██ ████████ 
 *    ██   ██ ██   ██ ██   ██ ██    ██ ██ ████   ██    ██    ████  ████ ██      ████   ██    ██    
 *    ███████ ██████  ██████  ██    ██ ██ ██ ██  ██    ██    ██ ████ ██ █████   ██ ██  ██    ██    
 *    ██   ██ ██      ██      ██    ██ ██ ██  ██ ██    ██    ██  ██  ██ ██      ██  ██ ██    ██    
 *    ██   ██ ██      ██       ██████  ██ ██   ████    ██    ██      ██ ███████ ██   ████    ██    
 *                                                                                                 
 *                                                                                                 
 *    ███████ ████████  ██████  ██████   █████   ██████  ███████                                   
 *    ██         ██    ██    ██ ██   ██ ██   ██ ██       ██                                        
 *    ███████    ██    ██    ██ ██████  ███████ ██   ███ █████                                     
 *         ██    ██    ██    ██ ██   ██ ██   ██ ██    ██ ██                                        
 *    ███████    ██     ██████  ██   ██ ██   ██  ██████  ███████                                   
 *
 *
 *    GALAXIS - Appointment Trait Storage
 *
 */

import "../interfaces/IECRegistry.sol";
// import "hardhat/console.sol";

contract UTAppointmentStorage {

    uint8       public constant     traitType = 4;     // Appointment trait

    uint16      public immutable    traitId;
    IECRegistry public              ECRegistry;

    // -- Trait storage per tokenID --
    // tokenID => uint8 value
    mapping(uint16 => uint8) data;

    // --- Event storage ---
    // event ID => tokenId
    // 0 is a sentinel value, so we store tokenId+1 in the mapping
    mapping( bytes32 => uint16 ) public tokenIdByEvent;
    // tokenID => event ID
    mapping( uint16 => bytes32 ) public eventByTokenId;

    // Events
    event updateTraitEvent(uint16 indexed _tokenId, uint8 _newData);

    constructor(
        address _registry,
        uint16 _traitId
    ) {
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    // Update multiple token values at once
    // EventIds could not be updated here, as those should be unique (use setValue per tokenId)!
    function setData(uint16[] memory _tokenIds, uint8[] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i]);
        }
    }

    // update one token value
    function setValue(uint16 _tokenId, uint8 _value, bytes32 _eventId) public onlyAllowed {
        data[_tokenId] = _value;
        // Reserve the eventId for the tokenId
        tokenIdByEvent[_eventId] = _tokenId + 1;        // 0 is sentinel value, so we add 1
        eventByTokenId[_tokenId] = _eventId;
        emit updateTraitEvent(_tokenId, _value);
    }

    // get trait value for one token
    function getValue(uint16 _tokenId) public view returns (uint8) {
        return data[_tokenId];
    }

    // get trait values for an array of tokens
    function getValues(uint16[] memory _tokenIds) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_tokenIds.length);
        for(uint16 i = 0; i < _tokenIds.length; i++) {
            retval[i] = data[_tokenIds[i]];
        }
        return retval;
    }

    // get trait values for a range of tokens
    function getValues(uint16 _start, uint16 _len) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_len);
        for(uint16 i = 0; i < _len; i++) {
            retval[i] = data[i+_start];
        }
        return retval;
    }

    // get token which has the eventId
    function getTokenForEvent(bytes32 _eventId) public view returns (uint16) {
        return tokenIdByEvent[_eventId];
    }

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "UTAppointmentStorage: Not Authorised"
        );
        _;
    }
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