/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface IBalances{
    function _mint(uint _type, address _who, uint _landID)external;
}

interface INuclear{
    function _set(address _who, uint _landID, uint _type)external;

    function _work(address _who, uint _type, uint _landID)external;

    function _claimCheck(address _who, uint _type, uint _landID, address _landOwner)external;

    function _destroy(address _who, uint _type, uint _landID)external;

    function _upgradeToWorkers(address _who, uint _landID)external;

    function _upgradeToTechnologists(address _who, uint _landID)external;

    function _checkCreateShip(address _who, uint _locationId, uint _type, string memory _name)external;

    function _sellFactoryCheck(uint _type)external view;

    function _buyFactoryCheck(address _buyer, address _seller, uint _type, uint _landId)external;
}

interface ILands{
    function _ownerCheck(uint _id)external view returns(address);   
}

interface IShips{
    function _finishShip(address _who, uint _shipyardId, uint _shipId)external;
}

contract Front { 
    uint private idList;
    uint private constant PRODUCTION_TIME = 2 hours;
    uint private constant BUILDING_TIME = 5 minutes;
    uint private constant SHIP_BUILDING_TIME = 10 minutes;
    uint private constant CRUISER_SHIP_EXTRA_BUILDING_TIME = 3 minutes;
    uint private constant STRUCTURE_BARGAIN_BAN_DURATION = 5 minutes;
    address private balances;
    address private nuclear;
    address private lands;
    address private ships;
    mapping(address => bool) private roleCall;
    mapping(uint => bool) private structureBargainBan;
    mapping(uint => uint) private structurePrice;
    mapping(uint => uint) private structureBargainBanStart;
    mapping(uint => address) private structureSeller;
    mapping(address => uint) public ownerBuildedSupply;
    mapping(uint => uint) private structureStartBuildTime;
    mapping(uint => uint) private structureWorkTime;
    mapping(uint => uint) private shipBuildStart;
    mapping(uint => uint) private shipType;

    event mintTheStructure(address indexed _who, uint _id, uint _type, uint indexed _land);
    event buildedTheStructure(address indexed _who, uint _id, uint indexed _land);
    event tradeTheStructure(address indexed _buyer, address indexed _seller, uint _id, uint indexed _land);

    modifier onlyRole(address _caller){
        require (roleCall[_caller] == true, "6x00");
        _;
    }

    modifier onlyOwner(uint _id) {
        require (structures[_id].owner == msg.sender, "6x01");
        _;
    }

    modifier idExist(uint _id) {
        require (_id < idList, "6x02");
        _;
    }

    modifier idBuilded(uint _id) {
        require (structures[_id].builded == true, "6x03");
        _;
    }

    constructor (){
        roleCall[msg.sender] = true;
    }

    Structure[] public structures;

    struct Structure {
        uint id;
        address owner;
        uint typeId;
        uint landId;
        bool builded;
        bool work;
        bool bargain;
        bool destroyed;
    }

    function setRole(address _caller1, address _caller2, address _caller3, address _caller4, address _caller5)external onlyRole(msg.sender){
        roleCall[_caller1] = true;
        roleCall[_caller2] = true;
        roleCall[_caller3] = true;
        roleCall[_caller4] = true;
        roleCall[_caller5] = true;
    }

    function setAddresses(address _balances, address _nuclear, address _lands, address _ships)external onlyRole(msg.sender){
        balances = _balances;
        nuclear = _nuclear;
        lands = _lands;
        ships = _ships;
    }

    function mintStructure(uint _type, uint _landId)external {
        require (_type != 8, "6x29");
        require (_type != 17, "6x30");
        address _who = msg.sender;
        IBalances(balances)._mint(_type, _who, _landId);
        Structure memory structure = Structure(idList, _who, _type, _landId, false, false, false, false); 
        structures.push(structure); 
        idList +=1;      

        emit mintTheStructure( _who, idList -1, _type, _landId);
    }

    function setToPlace(uint _id)external onlyOwner(_id) idExist(_id){
        require(structureStartBuildTime[_id] == 0, "6x04");
        require(structures[_id].builded == false, "6x05");
        address _who = msg.sender;
        structureStartBuildTime[_id] = block.timestamp;
        INuclear(nuclear)._set(_who, structures[_id].landId, structures[_id].typeId);
    }

    function buildFinish(uint _id)external onlyOwner(_id) idExist(_id){
        require(structures[_id].builded == false, "6x05");
        require((block.timestamp - structureStartBuildTime[_id]) >= BUILDING_TIME, "6x06");
        require(structureStartBuildTime[_id] > 0, "6x07");
        structures[_id].builded = true;
        structureStartBuildTime[_id] = 0;
        ownerBuildedSupply[msg.sender] += 1;

        emit buildedTheStructure(msg.sender, _id, structures[_id].landId);
    }

    function startWork(uint _id)external onlyOwner(_id) idExist(_id) idBuilded(_id){
        require (structures[_id].work == false, "6x08");
        require (structures[_id].bargain == false, "6x09");
        address _who = msg.sender;
        INuclear(nuclear)._work( _who, structures[_id].typeId, structures[_id].landId);
        structureWorkTime[_id] = block.timestamp;
        structures[_id].work = true;
    }

    function claim(uint _id)external onlyOwner(_id) idExist(_id){
        require (structures[_id].work == true, "6x10");
        require ((block.timestamp - structureWorkTime[_id]) >= PRODUCTION_TIME, "6x11");
        address _who = msg.sender;  
        address _landOwner = ILands(lands)._ownerCheck(structures[_id].landId);
        INuclear(nuclear)._claimCheck(_who, structures[_id].typeId, structures[_id].landId, _landOwner);       
        structures[_id].work = false;   
    }

    function destroy(uint _id)external onlyOwner(_id) idExist(_id) idBuilded(_id){
        require (structures[_id].bargain == false, "6x12");
        require (structures[_id].work == false, "6x08");
        address _who = msg.sender;
        INuclear(nuclear)._destroy(_who, structures[_id].typeId, structures[_id].landId);
        structures[_id].owner = address(0);
        structures[_id].destroyed = true;
        ownerBuildedSupply[_who] -= 1;
    }

    function upgradeToWorkers(uint _id)external onlyOwner(_id) idExist(_id) idBuilded(_id){
        require (structures[_id].typeId == 1, "6x13");
        address _who = msg.sender;
        INuclear(nuclear)._upgradeToWorkers(_who, structures[_id].landId);
        structures[_id].typeId = 8;
    }

    function upgradeToTechnologists(uint _id)external onlyOwner(_id) idExist(_id) idBuilded(_id){
        require (structures[_id].typeId == 8, "6x14");
        address _who = msg.sender;
        INuclear(nuclear)._upgradeToTechnologists(_who, structures[_id].landId);
        structures[_id].typeId = 17;
    }

    function createShip(uint _shipyardId, uint _type, string memory _name)external onlyOwner(_shipyardId) idBuilded(_shipyardId){
        require(_type != 0, "6x15");
        require(_type <= 4, "6x15");
        require(structures[_shipyardId].typeId == 12, "6x16");
        require(structures[_shipyardId].bargain == false, "6x17");
        require(structures[_shipyardId].work == false, "6x18");       
        address _who = msg.sender;
        INuclear(nuclear)._checkCreateShip(_who, _shipyardId, _type, _name);
        structures[_shipyardId].work = true;
        shipBuildStart[_shipyardId] = block.timestamp;       
        if (_type == 4){
            shipBuildStart[_shipyardId] = block.timestamp + CRUISER_SHIP_EXTRA_BUILDING_TIME;
        }        
    }

    function finishShip(uint _shipyardId, uint _shipId)external onlyOwner(_shipyardId) idBuilded(_shipyardId){
        require(structures[_shipyardId].typeId == 12, "6x16");
        require(structures[_shipyardId].work == true, "6x19"); 
        require((shipBuildStart[_shipyardId] + SHIP_BUILDING_TIME) >= block.timestamp, "6x20");
        address _who = msg.sender;
        IShips(ships)._finishShip(_who, _shipyardId, _shipId);
        structures[_shipyardId].work = false;
        shipBuildStart[_shipyardId] = block.timestamp;
    }

    function sellStructure(uint _id, uint _price)external onlyOwner(_id) idExist(_id){
        require(structures[_id].work == false, "6x21");
        require(structureBargainBan[_id] == false, "6x22");
        require(structures[_id].bargain == false, "6x23");
        INuclear(nuclear)._sellFactoryCheck(structures[_id].typeId);
        structures[_id].bargain = true;
        structurePrice[_id] = _price;
        structureSeller[_id] = msg.sender;
    }

    function buyStructure(uint _id)external payable idExist(_id){
        require(structures[_id].bargain == true, "6x24");
        require(msg.value == structurePrice[_id], "6x25");
        address _buyer = msg.sender;
        address payable _seller = payable(structureSeller[_id]);
        INuclear(nuclear)._buyFactoryCheck(_buyer, _seller, structures[_id].typeId, structures[_id].landId);
        (_seller).transfer(structurePrice[_id]);
        structures[_id].owner = _buyer;
        ownerBuildedSupply[_seller] -= 1;
        ownerBuildedSupply[_buyer] += 1;
        structures[_id].bargain = false;
        structureBargainBan[_id] = true;
        structureBargainBanStart[_id] = block.timestamp;

        emit tradeTheStructure(_buyer, _seller, _id, structures[_id].landId);
    }

    function cancelSellStructure(uint _id)external onlyOwner(_id) idExist(_id){
        require(structures[_id].bargain == true, "6x26");
        structures[_id].bargain = false;
    }

    function unbanStructureBargain(uint _id)external onlyOwner(_id) idExist(_id){
        require(structureBargainBan[_id] == true, "6x27");
        require(block.timestamp >= (structureBargainBanStart[_id] + STRUCTURE_BARGAIN_BAN_DURATION), "6x28");
        structureBargainBan[_id] = false;
    } 
}