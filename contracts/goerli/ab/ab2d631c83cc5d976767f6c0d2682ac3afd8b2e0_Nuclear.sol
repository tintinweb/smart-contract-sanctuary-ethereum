/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface IBalances{
    function _claim(address _who, uint _type, uint _landID, address _landOwner, bool _ownerBank)external; 

    function _startWork(address _who, uint _type, uint _landID)external;

    function _destroyClaim(address _who, uint _type, uint _landID)external;

    function _upgradeToWork(address _who, uint _landID)external;

    function _upgradeToTech(address _who, uint _landID)external;

    function _mintShip(address _who, uint _landID, uint _shipType, string memory _name)external;

    function _createAlliance(address _who, uint _landId)external;
}

interface ILands{
    function _spaceCheck(address _who, uint _landID, uint _size, uint _slot)external returns(bool);

    function _spaceDisengage(uint _landID, uint _space, uint _slot)external;

    function _startWorkCheckGold(address _who, uint _landId)external view;

    function _ownerCheck(uint _id)external view returns(address);
}

contract Nuclear { 
    uint public constant FIRST_TIER_REQUIREMENT = 300;
    uint public constant SECOND_TIER_REQUIREMENT = 500;
    uint public constant ALLIANCE_REQUIREMENT = 600; 
    uint public constant NUMBER_OF_DWELLERS = 10;
    address private balances; 
    address private lands; 
    mapping(address => bool) private roleCall;
    mapping(address => mapping (uint => uint)) public colonists;
    mapping(address => mapping (uint => uint)) public colonistsFree;
    mapping(address => mapping (uint => bool)) public haveRialto;
    mapping(address => mapping (uint => bool)) public haveCathouse;
    mapping(address => mapping (uint => bool)) public haveUniversity;
    mapping(address => mapping (uint => bool)) public haveBank;
    mapping(uint => bool) public haveAllianceCore;

    modifier onlyRole(address _caller){
        require (roleCall[_caller] == true, "0x00");
        _;
    }

    modifier onlyType(uint _type){
        require (_type <= (structures.length-1) , "0x01");
        _;
    }

    constructor(){
        roleCall[msg.sender] = true;
    }

    Structure[] public structures;

    struct Structure {
        uint typeId;
        string name;
        uint farmersRequired;
        uint workersRequired;
        uint technologistsRequired;
        uint structureSize;
        uint structureSlot;
        bool structureFactory;
        bool structureRaw;
    }

    function setStructure
    (   string memory _name, 
        uint _farmersRequired,
        uint _workersRequired,
        uint _technologistsRequired,
        uint _structureSize,
        uint _structureSlot,
        bool _structureFactory,
        bool _structureRaw
    )
    external onlyRole(msg.sender) {
        Structure memory structure = Structure(
        structures.length,
        _name, 
        _farmersRequired,
        _workersRequired,
        _technologistsRequired,
        _structureSize,
        _structureSlot,
        _structureFactory,
        _structureRaw
        ); 
        structures.push(structure); 
    }

    function setRole(address _caller1, address _caller2, address _caller3, address _caller4, address _caller5)external onlyRole(msg.sender){
        roleCall[_caller1] = true;
        roleCall[_caller2] = true;
        roleCall[_caller3] = true;
        roleCall[_caller4] = true;
        roleCall[_caller5] = true;
    }

    function setAddresses(address _balances, address _lands)external onlyRole(msg.sender){
        balances = _balances;
        lands = _lands;
    }

    function _set(address _who, uint _landID, uint _type)external onlyType(_type) onlyRole(msg.sender){
        bool _alliance = ILands(lands)._spaceCheck(_who, _landID, structures[_type].structureSize, structures[_type].structureSlot);
        _setCheck(_who, _landID, _type, _alliance);      
    }

    function _setCheck(address _who, uint _landID, uint _type, bool _alliance)internal onlyType(_type) onlyRole(msg.sender){
        require (colonistsFree[_who][1] >= structures[_type].farmersRequired, "0x02");
        require (colonistsFree[_who][2] >= structures[_type].workersRequired, "0x03");
        require (colonistsFree[_who][3] >= structures[_type].technologistsRequired, "0x04");
        if (_type == 0){
            require (haveRialto[_who][_landID] == false, "0x05");
            haveRialto[_who][_landID] = true;
        }
        if (_type == 1){
            require (haveRialto[_who][_landID] == true, "0x06");
            colonists[_who][1] += NUMBER_OF_DWELLERS;
            colonistsFree[_who][1] += NUMBER_OF_DWELLERS;
            colonists[_who][4] += NUMBER_OF_DWELLERS;
        } 
        if (_type == 7){
            require (haveRialto[_who][_landID] == true, "0x07");
            require (haveCathouse[_who][_landID] == false, "0x08");
            haveCathouse[_who][_landID] = true;
        }
        if(_type == 13){
            require (ILands(lands)._ownerCheck(_landID) == _who, "0x24");
            haveBank[_who][_landID] = true;
        }
        if (_type == 16){
            require (haveCathouse[_who][_landID] == true, "0x09");
            require (haveUniversity[_who][_landID] == false, "0x10");
            haveUniversity[_who][_landID] = true;
        }
        if (_type == 22){
            require (haveAllianceCore[_landID] == false, "0x23");
            require (_alliance == true, "0x11");
            haveAllianceCore[_landID] = true;
        }   
        colonistsFree[_who][1] -= structures[_type].farmersRequired;
        colonistsFree[_who][2] -= structures[_type].workersRequired;
        colonistsFree[_who][3] -= structures[_type].technologistsRequired;
    }

    function _work(address _who, uint _type, uint _landID)external  onlyType(_type) onlyRole(msg.sender){
        require (structures[_type].structureFactory == true, "0x12");
        if (_type == 25){
            ILands(lands)._startWorkCheckGold(_who, _landID);
        }
        if (structures[_type].structureRaw == true) {
            IBalances(balances)._startWork(_who, _type, _landID);
        }       
    }

    function _claimCheck(address _who, uint _type, uint _landID, address _landOwner)external onlyType(_type) onlyRole(msg.sender){
        IBalances(balances)._claim(_who, _type, _landID, _landOwner, haveBank[_landOwner][_landID]);
    }

    function _destroy(address _who, uint _type, uint _landID)external onlyType(_type) onlyRole(msg.sender){
        ILands(lands)._spaceDisengage(_landID, structures[_type].structureSize, structures[_type].structureSlot);
        IBalances(balances)._destroyClaim(_who, _type, _landID);
        colonistsFree[_who][1] += structures[_type].farmersRequired;
        colonistsFree[_who][2] += structures[_type].workersRequired;
        colonistsFree[_who][3] += structures[_type].technologistsRequired;
        if(_type == 0){
            require (colonists[_who][1] == 0, "0x20");
            haveRialto[_who][_landID] = false;
        }
        if(_type == 1){
            require (colonistsFree[_who][1] >= NUMBER_OF_DWELLERS, "0x02");
            colonists[_who][1] -= NUMBER_OF_DWELLERS;
            colonists[_who][4] -= NUMBER_OF_DWELLERS;         
            colonistsFree[_who][1] -= NUMBER_OF_DWELLERS;
        }
        if(_type == 7){
            require (colonists[_who][2] == 0, "0x21");
            haveCathouse[_who][_landID] = false;
        }
        if(_type == 8){
            require (colonistsFree[_who][2] >= (NUMBER_OF_DWELLERS*2), "0x03");
            colonists[_who][2] -= NUMBER_OF_DWELLERS*2;
            colonists[_who][4] -= NUMBER_OF_DWELLERS*2;         
            colonistsFree[_who][2] -= NUMBER_OF_DWELLERS*2;
        }
        if(_type == 13){
            haveBank[_who][_landID] = false;
        }
        if(_type == 16){
            require (colonists[_who][3] == 0, "0x22");
            haveUniversity[_who][_landID] = false;
        }
        if(_type == 17){
            require (colonistsFree[_who][3] >= (NUMBER_OF_DWELLERS*4), "0x04");
            colonists[_who][3] -= NUMBER_OF_DWELLERS*4;
            colonists[_who][4] -= NUMBER_OF_DWELLERS*4;         
            colonistsFree[_who][3] -= NUMBER_OF_DWELLERS*4;           
        }
        if(_type == 22){
            haveAllianceCore[_landID] = false;
        }
    } 

    function _upgradeToWorkers(address _who, uint _landID)external onlyRole(msg.sender){
        require (colonists[_who][1] >= FIRST_TIER_REQUIREMENT, "0x13");
        require (colonistsFree[_who][1] >= NUMBER_OF_DWELLERS, "0x02");
        require (haveCathouse[_who][_landID] == true, "0x09");
        colonists[_who][1] -= NUMBER_OF_DWELLERS;
        colonistsFree[_who][1] -= NUMBER_OF_DWELLERS;
        colonists[_who][4] += NUMBER_OF_DWELLERS;
        colonists[_who][2] += NUMBER_OF_DWELLERS * 2;
        colonistsFree[_who][2] += NUMBER_OF_DWELLERS * 2;
        IBalances(balances)._upgradeToWork(_who, _landID);
    }

    function _upgradeToTechnologists(address _who, uint _landID)external onlyRole(msg.sender){
        require (colonists[_who][2] >= SECOND_TIER_REQUIREMENT, "0x14");
        require (colonistsFree[_who][2] >= (NUMBER_OF_DWELLERS * 2), "0x03");
        require (haveUniversity[_who][_landID] == true, "0x15");
        colonists[_who][2] -= NUMBER_OF_DWELLERS * 2;
        colonistsFree[_who][2] -= NUMBER_OF_DWELLERS * 2;
        colonists[_who][4] += NUMBER_OF_DWELLERS * 2;
        colonists[_who][3] += NUMBER_OF_DWELLERS * 4;
        colonistsFree[_who][3] += NUMBER_OF_DWELLERS * 4;
        IBalances(balances)._upgradeToTech(_who, _landID);
    }

    function _checkCreateShip(address _who, uint _locationId, uint _type, string memory _name)external onlyRole(msg.sender){
        if (_type == 1){
            require(haveCathouse[_who][_locationId] == true, "0x16");
        }
        if (_type == 2){
            require(haveCathouse[_who][_locationId] == true, "0x16");
        }
        if (_type == 3){
            require(haveUniversity[_who][_locationId] == true, "0x17");
        } 
        if (_type == 4){
            require(haveUniversity[_who][_locationId] == true, "0x17");
        }         
        IBalances(balances)._mintShip(_who, _locationId, _type, _name);
    }

    function _createAllianceCheck(address _who, uint _landId)external onlyRole(msg.sender){
        require (colonists[_who][4] >= ALLIANCE_REQUIREMENT, "0x18");
        IBalances(balances)._createAlliance(_who, _landId);
    }

    function _sellFactoryCheck(uint _type)external view onlyRole(msg.sender){
        require (structures[_type].structureFactory == true, "0x19");
    }

    function _buyFactoryCheck(address _buyer, address _seller, uint _type, uint _landId)external onlyRole(msg.sender){
        _setCheck( _buyer, _landId, _type, false);
        colonistsFree[_seller][1] += structures[_type].farmersRequired;
        colonistsFree[_seller][2] += structures[_type].workersRequired;
        colonistsFree[_seller][3] += structures[_type].technologistsRequired;
    }
}