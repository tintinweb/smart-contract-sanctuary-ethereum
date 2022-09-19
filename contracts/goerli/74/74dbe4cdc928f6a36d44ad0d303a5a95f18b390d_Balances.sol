/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface IToken{
    function transferFrom(address _sender, address _to, uint _value)external;

    function transfer(address _to, uint _value)external;
}

interface INuclear{
    function haveAllianceCore(uint _landId)external view returns(bool);
}

interface ILands{
    function _ownerCheck(uint _id)external view returns(address);

    function totalSupply()external view returns(uint);
}

interface IShips{
    function _createShip(string memory _name, uint _type, address _who, uint shipyardId)external;
}

contract Balances {
    uint private constant STORAGE = 20e18;
    uint private constant FEE = 1e18;
    uint private constant DEPOSIT_FEE = 33;
    address private dev;
    address private ships;
    address private nuclear;
    address private lands;
    mapping(address => bool) private roleCall;
    mapping(uint => address) private tokenAddress;
    mapping(address => mapping(uint => mapping(uint => uint))) public balances;
    mapping(address => mapping(uint => mapping(uint => uint))) public shipBalances;
    mapping(address => uint) public goldBalance;
    mapping(uint => uint) private plankCost;
    mapping(uint => uint) private fishCost;
    mapping(uint => uint) private brickCost;
    mapping(uint => uint) private steelCost;
    mapping(uint => uint) private liftCost;
    mapping(uint => uint) private meatCost;
    mapping(uint => uint) private rumCost;
    mapping(uint => uint) private goldCost;
    mapping(uint => uint) private structureResource;

    error NotEnoughResources();
    
    modifier onlyRole(address _caller){
        require (roleCall[_caller] == true, "1x00");
        _;
    }

    constructor(){
        tokenAddress[1] = 0xBc5688A88fe9043cAAE5ECDA4ad78Cd19BF758CF;  
        tokenAddress[2] = 0xfA401B13905Ffe465ae836043A66Da509cFf6cD9;  
        tokenAddress[3] = 0x59fE9a998bdA3e575630D49923e0333BEF9C3F63;  
        tokenAddress[4] = 0x7DA02931bf4e41EBE54b127fbB397e32cCa80229;  
        tokenAddress[5] = 0x68b3Ae28c585229b1B5446E945026d424627de1F;  
        tokenAddress[6] = 0x58A59EC6d996DCaD7Ad07ea3fb0926e4ad4EB9b3;  
        tokenAddress[7] = 0xd1BD83080dDb85Ec01837aEBaeF6A0d20261E1B2;  
        tokenAddress[8] = 0x3b68b1dE9c0f0cb530847C5fdaC8793a3B067F05;  
        tokenAddress[9] = 0x1CB63da292ABb4397339f9c661E158eAAFA26e6d;  
        tokenAddress[10] = 0x0f2a03ce79E1d268500A8f1cE9c55636cc79Fd2B; 
        tokenAddress[11] = 0x90A90c9E11418f5270A3b1B88c7Fe90C4F0b4f02; 
        tokenAddress[12] = 0x37468EAEc9Cc8F36a9D383D83cd13F44a857c179; 
        tokenAddress[13] = 0xF3cC2a75123bE41E3edddb5e7010BDf4e94B803d; 
        tokenAddress[14] = 0x702aADeFaaB0a7648B4295Be347C1C4DA9C03D2e; 
        tokenAddress[15] = 0x777eCfD22241299c9b59262733E2B1C6970cE561; 
        tokenAddress[16] = 0x462f54cc8C4b8A2ce58729CD9E9a7752EA9b6D94; 
        tokenAddress[17] = 0x32147Dc265bF05cB781b83b7456800Dd910e0bb8; 
        roleCall[msg.sender] = true;
        dev = msg.sender;
    }

    function setData(uint _type, uint _plank, uint _fish, uint _brick, uint _steel, uint _lift, uint _meat, uint _rum, uint _gold, uint _crude)external onlyRole(msg.sender){
        plankCost[_type] = _plank;
        fishCost[_type] = _fish;
        brickCost[_type] = _brick;
        steelCost[_type] = _steel;
        liftCost[_type] = _lift;
        meatCost[_type] = _meat;
        rumCost[_type] = _rum;
        goldCost[_type] = _gold;
        structureResource[_type] = _crude;
    }

    function setAddresses(address _ships, address _nuclear, address _lands)external onlyRole(msg.sender){
        ships = _ships;
        nuclear = _nuclear;
        lands = _lands;
    }

    function setRole(address _caller1, address _caller2, address _caller3, address _caller4, address _caller5)external onlyRole(msg.sender){
        roleCall[_caller1] = true;
        roleCall[_caller2] = true;
        roleCall[_caller3] = true;
        roleCall[_caller4] = true;
        roleCall[_caller5] = true;
    }

    function depositToken(uint _token, uint _value, uint _landId)external {
        require (ILands(lands).totalSupply() > _landId, "1x01");
        if (ILands(lands)._ownerCheck(_landId) != dev){
            require(INuclear(nuclear).haveAllianceCore(_landId) == true, "1x02");
        }
        IToken(tokenAddress[_token]).transferFrom(msg.sender, address(this), _value);
        uint _fee = _value / DEPOSIT_FEE;
        if (INuclear(nuclear).haveAllianceCore(_landId) == true){
            if (_token == 17){
                goldBalance[ILands(lands)._ownerCheck(_landId)] += _fee;
                goldBalance[msg.sender] += _value - _fee;
            } else {
                balances[ILands(lands)._ownerCheck(_landId)][_landId][_token] += _fee;
                balances[msg.sender][_landId][_token] += _value - _fee;
            }
        } else {
            if (_token == 17) {
                goldBalance[msg.sender] += _value - _fee;
            } else {
                balances[msg.sender][_landId][_token] += _value - _fee;
            }        
        }
    }

    function withdrawToken(uint _token, uint _value, uint _landId)external {
        require (ILands(lands).totalSupply() > _landId, "1x01");
        if (_landId != 0){
            require(INuclear(nuclear).haveAllianceCore(_landId) == true, "1x03");
        }
        require(balances[msg.sender][_landId][_token] >= _value, "1x04");
        IToken(tokenAddress[_token]).transfer(msg.sender, _value);
        if (_token == 17){
            goldBalance[msg.sender] -= _value;
        } else {
            balances[msg.sender][_landId][_token] -= _value;
        }       
    }

    function _mint(uint _type, address _who, uint _landID)external onlyRole(msg.sender){
        if (balances[_who][_landID][2] < plankCost[_type]){revert NotEnoughResources();}
        if (balances[_who][_landID][3] < fishCost[_type]){revert NotEnoughResources();}
        if (balances[_who][_landID][5] < brickCost[_type]){revert NotEnoughResources();}
        if (balances[_who][_landID][8] < steelCost[_type]){revert NotEnoughResources();}
        if (balances[_who][_landID][9] < liftCost[_type]){revert NotEnoughResources();}
        if (balances[_who][_landID][10] < meatCost[_type]){revert NotEnoughResources();}
        if (balances[_who][_landID][12] < rumCost[_type]){revert NotEnoughResources();}
        if (goldBalance[_who] < goldCost[_type]){revert NotEnoughResources();}
        balances[_who][_landID][2] -= plankCost[_type];
        balances[_who][_landID][3] -= fishCost[_type];
        balances[_who][_landID][5] -= brickCost[_type];
        balances[_who][_landID][8] -= steelCost[_type];
        balances[_who][_landID][9] -= liftCost[_type];
        balances[_who][_landID][10] -= meatCost[_type];
        balances[_who][_landID][12] -= rumCost[_type];
        goldBalance[_who] -= goldCost[_type];
    }

    function _startWork(address _who, uint _type, uint _landID)external onlyRole(msg.sender){
        if (_type == 3) {
            balances[_who][_landID][1] -= STORAGE;
        }
        if (_type == 6) {
            balances[_who][_landID][3] -= STORAGE;
            balances[_who][_landID][4] -= STORAGE;
        }
        if (_type == 11) {
            balances[_who][_landID][3] -= STORAGE;
            balances[_who][_landID][6] -= STORAGE;
            balances[_who][_landID][7] -= STORAGE;
        }
        if (_type == 14) {
            balances[_who][_landID][2] -= STORAGE;
            balances[_who][_landID][3] -= STORAGE;
            balances[_who][_landID][5] -= STORAGE;
            balances[_who][_landID][8] -= STORAGE;
        }
        if (_type == 15) {
            balances[_who][_landID][6] -= STORAGE;
        }
        if (_type == 19) {
            balances[_who][_landID][2] -= STORAGE;
            balances[_who][_landID][9] -= STORAGE;
            balances[_who][_landID][10] -= STORAGE;
            balances[_who][_landID][11] -= STORAGE;          
        }
        if (_type == 21) {
            balances[_who][_landID][2] -= STORAGE;
            balances[_who][_landID][8] -= STORAGE;
            balances[_who][_landID][10] -= STORAGE;
            balances[_who][_landID][13] -= STORAGE;          
        }
        if (_type == 24) {
            balances[_who][_landID][7] -= STORAGE;
            balances[_who][_landID][10] -= STORAGE;
            balances[_who][_landID][15] -= STORAGE;          
        }
        if (_type == 25) {
            balances[_who][_landID][7] -= STORAGE;
            balances[_who][_landID][9] -= STORAGE;
            balances[_who][_landID][10] -= STORAGE;
            balances[_who][_landID][14] -= STORAGE;
            balances[_who][_landID][16] -= STORAGE;      
        }
    }

    function _claim(address _who, uint _type, uint _landID, address _landOwner, bool _ownerBank)external onlyRole(msg.sender){
        if (_ownerBank == true){
            if (_type == 25){
                goldBalance[_who] += STORAGE - FEE;
                goldBalance[_landOwner] += FEE;
            } else {
                balances[_who][_landID][structureResource[_type]] += STORAGE - FEE;
                balances[_landOwner][_landID][structureResource[_type]] += FEE;
            }           
        } else {
            if (_type == 25) {
                goldBalance[_who] += STORAGE;
            } else {
                balances[_who][_landID][structureResource[_type]] += STORAGE;
            }   
        }    
    }

    function _destroyClaim(address _who, uint _type, uint _landID)external onlyRole(msg.sender){
        balances[_who][_landID][2] += plankCost[_type]/5;
        balances[_who][_landID][3] += fishCost[_type]/5;
        balances[_who][_landID][5] += brickCost[_type]/5;
        balances[_who][_landID][8] += steelCost[_type]/5;
        balances[_who][_landID][9] += liftCost[_type]/5;
        balances[_who][_landID][10] += meatCost[_type]/5;
        balances[_who][_landID][12] += rumCost[_type]/5;       
    }

    function _upgradeToWork(address _who, uint _landID)external onlyRole(msg.sender){
        balances[_who][_landID][2] -= 10e18;
        balances[_who][_landID][3] -= 8e18;
        balances[_who][_landID][5] -= 6e18;
        goldBalance[_who] -= 4e18;
    }

    function _upgradeToTech(address _who, uint _landID)external onlyRole(msg.sender){
        balances[_who][_landID][2] -= 15e18;
        balances[_who][_landID][3] -= 12e18;
        balances[_who][_landID][5] -= 10e18;
        balances[_who][_landID][8] -= 8e18;
        balances[_who][_landID][9] -= 6e18;
        balances[_who][_landID][10] -= 5e18;
        balances[_who][_landID][12] -= 3e18;
        goldBalance[_who] -= 8e18;
    }

    function _mintShip(address _who, uint _landID, uint _shipType, string memory _name)external onlyRole(msg.sender){
        if (_shipType == 1){
            balances[_who][_landID][2] -= 70e18; 
            balances[_who][_landID][3] -= 40e18;
            balances[_who][_landID][6] -= 25e18;
            balances[_who][_landID][8] -= 15e18;
            goldBalance[_who] -= 45e18;
        }
        if (_shipType == 2){
            balances[_who][_landID][2] -= 120e18;
            balances[_who][_landID][3] -= 60e18;
            balances[_who][_landID][6] -= 40e18;
            balances[_who][_landID][8] -= 35e18;
            goldBalance[_who] -= 90e18;
        }
        if (_shipType == 3){
            balances[_who][_landID][2] -= 140e18;
            balances[_who][_landID][3] -= 40e18;
            balances[_who][_landID][6] -= 50e18;
            balances[_who][_landID][8] -= 30e18;
            balances[_who][_landID][10] -= 25e18;
            goldBalance[_who] -= 130e18;
        }
        if (_shipType == 4){
            balances[_who][_landID][2] -= 250e18;
            balances[_who][_landID][3] -= 200e18;
            balances[_who][_landID][6] -= 140e18;
            balances[_who][_landID][8] -= 100e18;
            balances[_who][_landID][10] -= 70e18;
            balances[_who][_landID][12] -= 100e18;
            goldBalance[_who] -= 350e18;
        }
        IShips(ships)._createShip(_name, _shipType, _who, _landID);
    }

    function _loadShip(address _who, uint _shipId, uint _resType, uint _landId, uint _value)external onlyRole(msg.sender){
        balances[_who][_landId][_resType] -= _value;
        shipBalances[_who][_shipId][_resType] += _value;
    }

    function _unloadShip(address _who, uint _shipId, uint _resType, uint _landId, uint _value)external onlyRole(msg.sender){
        shipBalances[_who][_shipId][_resType] -= _value;
        balances[_who][_landId][_resType] += _value;     
    }

    function _createAlliance(address _who, uint _landId)external onlyRole(msg.sender){
        balances[_who][_landId][2] -= 100e18;
        balances[_who][_landId][3] -= 50e18;
        balances[_who][_landId][8] -= 50e18;
        balances[_who][_landId][10] -= 30e18;
        goldBalance[_who] -= 200e18;
    }

    function _joinToAlliance(address _who, uint _landId)external onlyRole(msg.sender){
        balances[_who][_landId][2] -= 20e18;
        balances[_who][_landId][3] -= 10e18;
        balances[_who][_landId][8] -= 10e18;
        goldBalance[_who] -= 10e18;
    }

}