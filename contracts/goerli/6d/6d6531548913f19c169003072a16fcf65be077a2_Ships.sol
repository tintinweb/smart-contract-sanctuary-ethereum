/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface IBalances{
    function _loadShip(address _who, uint _shipId, uint _resType, uint _landId, uint _value)external;

    function _unloadShip(address _who, uint _shipId, uint _resType, uint _landId, uint _value)external;
}

interface ILands{
    function _locationCheckX(uint _id)external view returns(uint);

    function _locationCheckY(uint _id)external view returns(uint);
 
    function warNow()external view returns(bool);

    function warLandNow()external view returns(uint);  

    function landsSupply()external view returns(uint);
}

interface IAlliances{
    function _joinToWar(address _who, uint _shipId, uint _shipPower)external;

    function _returnShipFromWar(address _who, uint _lostPower)external;
}

interface IOracle{
    function _shipSunk()external view returns(bool);
}

contract Ships {
    uint private totalSupply;
    uint private constant NUMBER_OF_RESOURCES = 16;
    uint private constant MERCHANT_SHIP_SPACE = 40e18;
    uint private constant CARGO_SHIP_SPACE = 100e18;
    uint private constant BATTLE_SHIP_POWER = 250;
    uint private constant CRUISER_SHIP_POWER = 1000;
    uint private constant TRAVEL_TIME_COEFFICIENT = 20;
    address private lands;
    address private balances;
    address private alliances;
    address private oracle;
    mapping(address => bool) private roleCall;
    mapping(uint => bool) private shipBuilded;
    mapping(uint => uint) private startJourney;
    mapping(uint => uint) private aimJourney;

    event shipBuildedStatus(address indexed _who, uint _shipId, uint _landId, uint _time);
    event shipStartToJourney(address indexed _who, uint indexed _shipId, uint _landId, uint _time);
    event shipFinishTheJourney(address indexed _who, uint indexed _shipId, uint _landId, uint _time);
    event shipJoinToWar(address indexed _who, uint indexed _shipId, uint indexed _landId, uint _time);
    event shipSunken(address indexed _who, uint indexed _shipId, uint _landId, uint _time);

    modifier onlyRole(address _caller){
        require (roleCall[_caller] == true, "4x00");
        _;
    }

    modifier onlyOwner(address _who, uint _id){
        require (_who == ships[_id].owner, "4x01");
        _;
    }

    modifier shipJourney(uint _id){
        require (ships[_id].journey == false, "4x02");
        _;
    }

    modifier shipExist(uint _id){
        require (_id < totalSupply, "4x03");
        _;
    }

    constructor(){
        roleCall[msg.sender] = true;
    }

    Ship[] public ships;

    struct Ship {
        uint id;
        string name;
        string shipType;
        address owner;
        uint locationId;
        uint space;
        uint freeSpace;
        uint power;
        bool journey;
        bool war;
        bool sunken;
    }

    function setAddresses(address _lands, address _balances, address _alliances, address _oracle)external onlyRole(msg.sender){
        balances = _balances;
        lands = _lands;
        alliances = _alliances;
        oracle = _oracle;
    }

    function _createShip(string memory _name, uint _type, address _who, uint _locationId)external onlyRole(msg.sender){
        if (_type == 1){
            Ship memory ship = Ship(totalSupply, _name, "Merchant", _who, _locationId, MERCHANT_SHIP_SPACE, MERCHANT_SHIP_SPACE, 0, true, false, false);
            ships.push(ship); 
        }
        if (_type == 2){
            Ship memory ship = Ship(totalSupply, _name, "Battleship", _who, _locationId, 0, 0, BATTLE_SHIP_POWER, true, false, false);
            ships.push(ship);
        }
        if (_type == 3){
            Ship memory ship = Ship(totalSupply, _name, "Cargo", _who, _locationId, CARGO_SHIP_SPACE, CARGO_SHIP_SPACE, 0, true, false, false);
            ships.push(ship);
        }
        if (_type == 4){
            Ship memory ship = Ship(totalSupply, _name, "Military Cruiser", _who, _locationId, 0, 0, CRUISER_SHIP_POWER, true, false, false);
            ships.push(ship);
        }     
        totalSupply += 1;
    }

    function setRole(address _caller1, address _caller2, address _caller3, address _caller4, address _caller5)external onlyRole(msg.sender){
        roleCall[_caller1] = true;
        roleCall[_caller2] = true;
        roleCall[_caller3] = true;
        roleCall[_caller4] = true;
        roleCall[_caller5] = true;
    }

    function _finishShip(address _who, uint _shipyardId, uint _shipId)external onlyOwner(_who, _shipId) shipExist(_shipId) onlyRole(msg.sender){
        require(ships[_shipId].locationId == _shipyardId, "4x04");
        ships[_shipId].journey = false;
        shipBuilded[_shipId] = true;

        emit shipBuildedStatus(_who, _shipId, ships[_shipId].locationId, block.timestamp);
    }

    function journey(uint _id, uint _toLandId)external onlyOwner(msg.sender, _id) shipJourney(_id) shipExist(_id){
        require(_toLandId < ILands(lands).landsSupply(), "4x16");
        aimJourney[_id] = _toLandId;
        ships[_id].journey = true;
        startJourney[_id] = block.timestamp;

        emit shipStartToJourney(msg.sender, _id, ships[_id].locationId, block.timestamp);
    }

    function finishJourney(uint _id)external onlyOwner(msg.sender, _id) shipExist(_id){
        require(shipBuilded[_id] == true, "4x05");
        require(ships[_id].journey == true, "4x06");
        uint time = _calculateRange(_id,  aimJourney[_id]);    
        require (block.timestamp >= (startJourney[_id] + time * TRAVEL_TIME_COEFFICIENT), "4x07");
        ships[_id].locationId =  aimJourney[_id];
        ships[_id].journey = false;
        

        emit shipFinishTheJourney(msg.sender, _id, ships[_id].locationId, block.timestamp);
    }

    function joinToWar(uint _shipId)external onlyOwner(msg.sender, _shipId) shipJourney(_shipId) shipExist(_shipId){
        require(ships[_shipId].power > 0, "4x08");
        require(ILands(lands).warNow() == true, "4x09");
        require(ships[_shipId].locationId == ILands(lands).warLandNow(), "4x10");
        address _who = msg.sender;
        IAlliances(alliances)._joinToWar(_who, _shipId, ships[_shipId].power);
        ships[_shipId].journey = true;
        ships[_shipId].war = true;

        emit shipJoinToWar(_who, _shipId, ships[_shipId].locationId, block.timestamp);
    }

    function returnShipFromWar(uint _shipId)external onlyOwner(msg.sender, _shipId) shipExist(_shipId){
        require(ships[_shipId].war == true, "4x11");
        require(ILands(lands).warNow() == true, "4x12");
        bool _sunken = IOracle(oracle)._shipSunk();
        if (_sunken == true){
            address _who = msg.sender;
            IAlliances(alliances)._returnShipFromWar(_who, ships[_shipId].power);
            ships[_shipId].owner = address(0);
            ships[_shipId].sunken = true;

            emit shipSunken(_who, _shipId, ships[_shipId].locationId, block.timestamp);
        }
        ships[_shipId].journey = false;
        ships[_shipId].war = false;      
    }

    function loadShip(uint _id, uint _resType, uint _value)external onlyOwner(msg.sender, _id) shipJourney(_id) shipExist(_id){
        require(_resType != 0, "4x13");
        require(_resType <= NUMBER_OF_RESOURCES, "4x13");
        require(_value <= ships[_id].freeSpace, "4x14");
        address _who = msg.sender;
        IBalances(balances)._loadShip( _who, _id, _resType, ships[_id].locationId, _value);
        ships[_id].freeSpace -= _value;
    }

    function unloadShip(uint _id, uint _resType, uint _value)external onlyOwner(msg.sender, _id) shipJourney(_id) shipExist(_id){
        require(_resType != 0, "4x13");
        require(_resType <= NUMBER_OF_RESOURCES, "4x13");
        require(ILands(lands).warNow() == false , "4x15");
        address _who = msg.sender;
        IBalances(balances)._unloadShip(_who, _id, _resType, ships[_id].locationId, _value);
        ships[_id].freeSpace += _value;
    }

    function _calculateRange(uint _id, uint _finishLandId)private view shipExist(_id) returns(uint){
        uint fX = ILands(lands)._locationCheckX(ships[_id].locationId);
        uint fY = ILands(lands)._locationCheckY(ships[_id].locationId);
        uint sX = ILands(lands)._locationCheckX(_finishLandId);
        uint sY = ILands(lands)._locationCheckY(_finishLandId);
        uint X;
        uint Y;
        if (fX >= sX){
            X = fX - sX;
        } else {
            X = sX - fX;
        }
        if (fY >= sY){
            Y = fY - sY;
        } else {
            Y = sY - fY;
        }
        uint result = X + Y;
        return result;
    }
}