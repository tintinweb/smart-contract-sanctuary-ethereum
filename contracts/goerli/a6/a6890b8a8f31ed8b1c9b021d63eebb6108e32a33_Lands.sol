/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface INuclear{
    function haveAllianceCore(uint _landId)external view returns(bool);
}

interface IAlliances{
    function _changeNumberOfLands(address _seller, address _buyer)external;

    function memberStatus(address _who)external returns(bool);
}

contract Lands { 
    uint public landsSupply;
    uint public warLandNow;
    bool public warNow;  
    address private nuclear;
    address private alliances;
    uint private constant STORAGE = 20e18;
    uint private constant LAND_BARGAIN_BAN_DURATION = 1 minutes;
    uint private constant LAND_WAR_BAN_DURATION = 1 minutes;
    uint public constant WAR_DURATION = 10 minutes;
    uint public constant POST_WAR_DURATION = 10 minutes;
    mapping(address => uint) public ownerLandSupply;
    mapping(address => bool) private roleCall;
    mapping(uint => mapping(uint => bool)) public locationCheck;
    mapping(uint => bool) private warStatus;
    mapping(uint => uint) private warStart;
    mapping(uint => bool) private landBargain;
    mapping(uint => bool) private landBargainBan;
    mapping(uint => uint) private landPrice;
    mapping(uint => uint) private landBargainBanStart;
    mapping(uint => address) private landSeller;

    event openTheLand(uint indexed _landId, uint indexed _dataX, uint indexed _dataY, uint _time);
    event conquerTheLand(address indexed _who, uint _landId, uint _time);
    event tradeTheLand(address indexed _buyer, address indexed _seller, uint _id, uint _time);

    modifier onlyRole(address _caller){
        require (roleCall[_caller] == true, "2x00");
        _;
    }

    modifier onlyOwner(address _who, uint _id){
        require (_who == lands[_id].owner, "2x01");
        _;
    }

    modifier idExist(uint _id) {
        require (_id < landsSupply, "2x02");
        _;
    }

    constructor(){
        roleCall[msg.sender] = true;
    }

    Land[] public lands;

    struct Land {
        uint id;
        string name;
        address owner;
        uint locationX;
        uint locationY;
        uint space;
        uint freeSpace;
        uint fishSlot;
        uint mineSlot;
        uint shipSlot;
        uint goldAmount;
        uint goldPersonalAmount;
    }

    function createLand
    (   string memory _name, 
        uint _dataX, 
        uint _dataY, 
        uint _space, 
        uint _fishSlot, 
        uint _mineSlot,
        uint _shipSlot,
        uint _goldAmount,
        uint _goldPersonalAmount
    )
    external onlyRole(msg.sender){
        require (locationCheck[_dataX][_dataY] == false, "2x25");
        Land memory land = Land(landsSupply, _name, msg.sender, _dataX, _dataY, _space, _space, _fishSlot, _mineSlot, _shipSlot, _goldAmount, _goldPersonalAmount); 
        lands.push(land); 
        locationCheck[_dataX][_dataY] = true;
        ownerLandSupply[msg.sender] += 1;
        landsSupply += 1;

        emit openTheLand(landsSupply - 1, _dataX, _dataY, block.timestamp);
    }

    function setRole(address _caller1, address _caller2, address _caller3, address _caller4, address _caller5)external onlyRole(msg.sender){
        roleCall[_caller1] = true;
        roleCall[_caller2] = true;
        roleCall[_caller3] = true;
        roleCall[_caller4] = true;
        roleCall[_caller5] = true;
    }

    function setAddresses(address _nuclear, address _alliances)external onlyRole(msg.sender){
        nuclear = _nuclear;
        alliances = _alliances;
    }

    function startWar(uint _landId)external onlyRole(msg.sender){
        require(warNow == false, "2x03");
        require(_landId + 1 == landsSupply, "2x04");
        require(warStatus[_landId] == false, "2x03");
        require(lands[_landId].owner == msg.sender, "2x26");
        warNow = true;
        warLandNow = _landId;
        warStatus[_landId] = true;
        warStart[_landId] = block.timestamp;
    } 

    function finishWar()external onlyRole(msg.sender){
        require(warNow == true, "2x05");
        require(block.timestamp >= (warStart[warLandNow] + WAR_DURATION), "2x06");
        warNow = false;
        warLandNow = 0;
        warStatus[warStart[warLandNow]] = false;
        warStart[warStart[warLandNow]] = 0;
    }

    function sellLand(uint _id, uint _price)external onlyOwner(msg.sender,  _id) idExist(_id){
        require(landBargainBan[_id] ==false, "2x07");
        require(landBargain[_id] == false, "2x08");
        require(INuclear(nuclear).haveAllianceCore(_id) == false, "2x09");
        require(block.timestamp >= (warStart[_id] + WAR_DURATION + POST_WAR_DURATION + LAND_WAR_BAN_DURATION), "2x10");
        landBargain[_id] = true;
        landPrice[_id] = _price;
        landSeller[_id] = msg.sender;
    }

    function buyLand(uint _id)external payable idExist(_id){
        require(landBargain[_id] == true, "2x11");
        require(msg.value == landPrice[_id], "2x12");
        address _buyer = msg.sender;
        address payable _seller = payable(landSeller[_id]);
        IAlliances(alliances)._changeNumberOfLands(_seller, _buyer);
        (_seller).transfer(landPrice[_id]);
        lands[_id].owner = _buyer;
        ownerLandSupply[_seller] -= 1;
        ownerLandSupply[_buyer] += 1;
        landBargain[_id] = false;
        landBargainBan[_id] = true;
        landBargainBanStart[_id] = block.timestamp;

        emit tradeTheLand(_buyer, _seller, _id, block.timestamp);
    }

    function cancelSellLand(uint _id)external onlyOwner(msg.sender, _id) idExist(_id){
        require(landBargain[_id] == true, "2x13");
        landBargain[_id] = false;
    }

    function unbanLandBargain(uint _id)external onlyOwner(msg.sender, _id) idExist(_id){
        require(landBargainBan[_id] == true, "2x14");
        require(block.timestamp >= (landBargainBanStart[_id] + LAND_BARGAIN_BAN_DURATION), "2x15");
        landBargainBan[_id] = false;
    } 

    function _spaceCheck(address _who, uint _id, uint _space, uint _slot)external onlyRole(msg.sender) returns(bool){
        require(lands[_id].freeSpace >= _space, "2x16");
        lands[_id].freeSpace -= _space;      
        if (_slot == 1){
            require(lands[_id].fishSlot >= 1, "2x17");
            lands[_id].fishSlot -=1;
        }
        if (_slot == 2){
            require(lands[_id].mineSlot >= 1, "2x18");
            lands[_id].mineSlot -=1;
        }
        if (_slot == 3){
            require(lands[_id].shipSlot >= 1, "2x19");
            lands[_id].shipSlot -=1;
        } 
        bool result;
        bool _check = IAlliances(alliances).memberStatus(_who);
        if (_check == true) {           
            if (lands[_id].owner == _who){
                result = true;
            }
        }
        return result;
    }

    function _spaceDisengage(uint _id, uint _space, uint _slot)external onlyRole(msg.sender){
        require((lands[_id].freeSpace + _space) <= lands[_id].space, "2x20");
        lands[_id].freeSpace += _space;
        if (_slot == 1){
            lands[_id].fishSlot +=1;
        }
        if (_slot == 2){
            lands[_id].mineSlot +=1;
        }
        if (_slot == 3){
            lands[_id].shipSlot +=1;
        }
    }

    function _resultWar(address _winner)external onlyRole(msg.sender){
        require(warNow == false, "2x21");
        require(block.timestamp >= (warStart[landsSupply - 1] + WAR_DURATION + POST_WAR_DURATION), "2x22");
        lands[landsSupply - 1].owner = _winner;
        ownerLandSupply[_winner] += 1;

        emit conquerTheLand(_winner, landsSupply - 1,  block.timestamp);
    }

    function _startWorkCheckGold(address _who, uint _landId)external onlyRole(msg.sender){
        if (lands[_landId].owner == _who){
            require (lands[_landId].goldPersonalAmount >= STORAGE, "2x23");
            lands[_landId].goldPersonalAmount -= STORAGE;
        } else {
            require (lands[_landId].goldAmount >= STORAGE, "2x24");
            lands[_landId].goldAmount -= STORAGE;
        }       
    }

    function _locationCheckX(uint _id)external view onlyRole(msg.sender) returns(uint){
        return lands[_id].locationX;
    }

    function _locationCheckY(uint _id)external view onlyRole(msg.sender) returns(uint){
        return lands[_id].locationY;
    }

    function _ownerCheck(uint _id)external view onlyRole(msg.sender) returns(address){
        return lands[_id].owner;
    }
}