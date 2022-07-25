// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSet.sol";

contract GoldenGeese is TokenSet {

    /**
     * Unordered List
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSet (
            "Golden Goose Trait",
            _registry,
            _traitId
        ) {
    }

}

// TODO: refactor to use permille calls
//
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IECRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
}

contract TokenSet  {

    IECRegistry                 public ECRegistry;
    uint16            immutable public traitId;
    bytes32                     public name;
    uint16                      public actualSize;
    mapping(uint16 => uint16)   public data;
    uint8                       public setType = 1;


    /**
     * Virtual data set, ordering not guaranteed because removal 
     * just replaces position with last item and decreases collection size
     */
    constructor(bytes32 _name, address _registry, uint16 _traitId) {
        name = _name;
        ECRegistry = IECRegistry(_registry);
        traitId = _traitId;
    }

    /**
     * @notice Add a token to the end of the list
     */
    function add(uint16 _id) public onlyAllowed {
        data[actualSize] = _id;
        actualSize++;
    }

    /**
     * @notice Add a token to the end of the list
     */
    function batchAdd(uint16[] calldata _id) public onlyAllowed {
        for(uint16 i = 0; i < _id.length; i++) {
            data[actualSize++] = _id[i];
        }
    }

    /**
     * @notice Remove the token at virtual position
     */
    function remove(uint32 _pos, uint16 _permille) public onlyAllowed {
        // copy value of last item in set to position and decrease length by 1
        actualSize--;
        data[getInternalPosition(_pos, _permille)] = data[actualSize];
    }

    /**
     * @notice Get the token at actual position
     */
    function getAtIndex(uint16 _index) public view returns (uint16) {
        return data[_index];
    }

    /**
     * @notice Get the token at virtual position
     */
    function get(uint32 _pos, uint16 _permille) public view returns (uint16) {
        return data[getInternalPosition(_pos, _permille)];
    }

    /**
     * @notice Retrieve list size
     */
    function size(uint16 _permille) public view returns (uint256) {
        return actualSize * _permille;
    }

    /**
     * @notice Retrieve internal position for a virtual position
     */
    function getInternalPosition(uint32 _pos, uint16 _permille) public view returns(uint16) {
        uint256 realPosition = _pos / _permille;
        require(realPosition < actualSize, "TokenSet: Index out of bounds.");
        return uint16(realPosition);
    }

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "TokenSet: Not Authorised" 
        );
        _;
    }

}