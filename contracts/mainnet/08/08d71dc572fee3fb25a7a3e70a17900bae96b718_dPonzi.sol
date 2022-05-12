pragma solidity ^0.4.24;

contract dPonzi {
    address public manager;

    struct PlayerStruct {
        uint key;
        uint food;
        uint idx;
        uint gametime;
        uint flag;
    }

    struct RefStruct {
        address player;
        uint flag;
    }

    struct RefStructAdd {
        bool flag;
        string name;
    }

    struct PotCntStruct {
        address[] player;
        address lastPlayer;
        uint last;
        uint balance;
        uint keys;
        uint food;
        uint gtime;
        uint gameTime;
        uint lastRecord;
        uint entryAmount;
        mapping(string => PackageStruct) potStruct;
    }

    struct IdxStruct {
      mapping(address => PlayerStruct) playerStruct;
    }

    struct PackageStruct {
      uint entryAmount;
    }

    mapping(string => PotCntStruct) potCntInfo;
    mapping(string => IdxStruct) idxStruct;
    mapping(string => RefStruct) idxR;
    mapping(address => RefStructAdd) public idxRadd;


    constructor() public {
        manager = msg.sender;

        potCntInfo['d'].gameTime   = 0;
        potCntInfo['7'].gameTime   = 0;
        potCntInfo['30'].gameTime  = 0;
        potCntInfo['90'].gameTime  = 0;
        potCntInfo['180'].gameTime = 0;
        potCntInfo['365'].gameTime = 0;

        potCntInfo['i'].entryAmount   = 10;
        potCntInfo['d'].entryAmount   = 1;
        potCntInfo['7'].entryAmount   = 4;
        potCntInfo['30'].entryAmount  = 8;
        potCntInfo['90'].entryAmount  = 15;
        potCntInfo['180'].entryAmount = 25;
        potCntInfo['365'].entryAmount = 5;
        potCntInfo['l'].entryAmount   = 2;
    }

    function enter(string package, address advisor) public payable {
        require(msg.value >= 0.01 ether, "0 ether is not allowed");

        uint key = 0;
        uint multiplier = 100000000000000;

        if(keccak256(abi.encodePacked(package)) == keccak256("BasicK")) {
            require(msg.value == 0.01 ether, "Invalid Package Amount");
            key = 1;
        }
        else if (keccak256(abi.encodePacked(package)) == keccak256("PremiumK")){
            require(msg.value == 0.1 ether, "Invalid Package Amount");
            key = 11;
            multiplier = multiplier * 10;
        }
        else if (keccak256(abi.encodePacked(package)) == keccak256("LuxuryK")){
            require(msg.value == 1 ether, "Invalid Package Amount");
            key = 120;
            multiplier = multiplier * 100;
            addRoyLuxList('l', 'idxLuxury', now, 500);
        }
        else if (keccak256(abi.encodePacked(package)) == keccak256("RoyalK")){
            require(msg.value == 10 ether, "Invalid Package Amount");
            key = 1300;
            multiplier = multiplier * 1000;
            addRoyLuxList('r', 'idxRoyal', now, 100);
        }

        if (key > 0){
            if ( idxRadd[advisor].flag ) {
                advisor.transfer(potCntInfo['i'].entryAmount * multiplier);
            }
            else {
                potCntInfo['i'].balance += potCntInfo['i'].entryAmount * multiplier;
            }
            potCntInfo['d'].balance   += potCntInfo['d'].entryAmount    * multiplier;
            potCntInfo['7'].balance   += potCntInfo['7'].entryAmount    * multiplier;
            potCntInfo['30'].balance  += potCntInfo['30'].entryAmount   * multiplier;
            potCntInfo['90'].balance  += potCntInfo['90'].entryAmount   * multiplier;
            potCntInfo['180'].balance += potCntInfo['180'].entryAmount  * multiplier;
            potCntInfo['365'].balance += potCntInfo['365'].entryAmount  * multiplier;
            potCntInfo['l'].balance   += potCntInfo['l'].entryAmount    * multiplier;
            potCntInfo['r'].balance   += potCntInfo['365'].entryAmount  * multiplier;
            potCntInfo['i'].balance   += potCntInfo['i'].entryAmount    * multiplier;
            potCntInfo['dv'].balance  += potCntInfo['90'].entryAmount   * multiplier;

            addPlayerMapping('d',   'idxDaily',  key, 0, 0);
            addPlayerMapping('7',   'idx7Pot',   key, 60, 3600);
            addPlayerMapping('30',  'idx30Pot',  key, 90, 10800);
            addPlayerMapping('90',  'idx90Pot',  key, 120, 21600);
            addPlayerMapping('180', 'idx180Pot', key, 150, 43200);
            addPlayerMapping('365', 'idx365Pot', key, 0, 0);
        }
    }

    function addPlayerMapping(string x1, string x2, uint key, uint timeAdd, uint hardCap ) private{
      if(potCntInfo[x1].last <= now){
        potCntInfo[x1].last = now;
      }

      if(keccak256(abi.encodePacked(x1)) == keccak256("d")) {
          if (potCntInfo[x1].gameTime == 0) {
              potCntInfo[x1].gameTime   = now%86400 == 0 ? (now-28800) : now-28800-(now%86400);
              potCntInfo[x1].gtime   = now;
              potCntInfo[x1].last = potCntInfo[x1].gameTime + 1 days;
          }
      }
      else if(keccak256(abi.encodePacked(x1)) == keccak256("365")) {
        if (potCntInfo[x1].gameTime == 0) {
            potCntInfo[x1].gameTime = now%86400 == 0 ? (now-28800) : now-28800-(now%86400);
            potCntInfo[x1].gtime = now;
            potCntInfo[x1].last = potCntInfo[x1].gameTime + 365 days;
            potCntInfo['l'].gameTime = potCntInfo[x1].gameTime;
            potCntInfo['r'].gameTime = potCntInfo[x1].gameTime;
            potCntInfo['l'].gtime   = now;
            potCntInfo['r'].gtime   = now;
        }
      }else  {
          if (potCntInfo[x1].gameTime == 0) {
              potCntInfo[x1].gameTime   = now%86400 == 0 ? (now-28800) : now-28800-(now%86400);
              potCntInfo[x1].gtime   = now;
              potCntInfo[x1].last = (now + (key * timeAdd))>=now+hardCap ? now + hardCap : now + (key * timeAdd);
          }
          else {
              potCntInfo[x1].last = (potCntInfo[x1].last + (key * timeAdd))>=now+hardCap ? now + hardCap : potCntInfo[x1].last + (key * timeAdd);
          }
      }

      if (idxStruct[x2].playerStruct[msg.sender].flag == 0) {
          potCntInfo[x1].player.push(msg.sender);
          idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(key, 0, potCntInfo[x1].player.length, potCntInfo[x1].gtime, 1);
      }
      else if (idxStruct[x2].playerStruct[msg.sender].gametime != potCntInfo[x1].gtime){
          potCntInfo[x1].player.push(msg.sender);
          idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(key, 0, potCntInfo[x1].player.length, potCntInfo[x1].gtime, 1);
      }
      else {
          idxStruct[x2].playerStruct[msg.sender].key += key;
      }
      potCntInfo[x1].keys += key;
      potCntInfo[x1].lastPlayer = msg.sender;
    }

    function joinboard(string name) public payable {
        require(msg.value >= 0.01 ether, "0 ether is not allowed");

        if (idxR[name].flag == 0 ) {
            idxR[name] = RefStruct(msg.sender, 1);
            potCntInfo['i'].balance += msg.value;
            idxRadd[msg.sender].name = name;
            idxRadd[msg.sender].flag = true;
        }
        else {
            revert("Name is not unique");
        }
    }

    function pickFood(uint pickTime, string x1, string x2, uint num, uint c) public restricted {
        uint i = 0;
        uint pCounter = 0;
        uint food = 0;
        if (potCntInfo[x1].player.length > 0 && potCntInfo[x1].food < num) {
            do {
                pCounter = random(potCntInfo[x1].player.length, pickTime+i+pCounter+food);
                food = random(idxStruct[x2].playerStruct[potCntInfo[x1].player[pCounter]].key, pickTime+i+pCounter+food);
                if (potCntInfo[x1].food + food > num) {
                    idxStruct[x2].playerStruct[potCntInfo[x1].player[pCounter]].food += num-potCntInfo[x1].food;
                    potCntInfo[x1].food = num;
                    break;
                }
                else {
                    idxStruct[x2].playerStruct[potCntInfo[x1].player[pCounter]].food += food;
                    potCntInfo[x1].food += food;
                }
                i++;

                if(potCntInfo[x1].food == num) {
                    break;
                }
            }
            while (i < c);
            potCntInfo[x1].lastRecord = potCntInfo[x1].food == num ? 1 : 0;
        }
        else {
            potCntInfo[x1].lastRecord = 1;
        }
    }

    function pickWinner(uint pickTime, bool sendDaily, bool send7Pot, bool send30Pot, bool send90Pot, bool send180Pot, bool send365Pot) public restricted{
        hitPotProcess('7', send7Pot,  pickTime);
        hitPotProcess('30', send30Pot, pickTime);
        hitPotProcess('90', send90Pot, pickTime);
        hitPotProcess('180', send180Pot, pickTime);

        maturityProcess('d', sendDaily, pickTime, 86400);
        maturityProcess('7', send7Pot, pickTime, 604800);
        maturityProcess('30', send30Pot, pickTime, 2592000);
        maturityProcess('90', send90Pot, pickTime, 7776000);
        maturityProcess('180', send180Pot, pickTime, 15552000);
        maturityProcess('365', send365Pot, pickTime, 31536000);
        maturityProcess('l', send365Pot, pickTime, 31536000);
        maturityProcess('r', send365Pot, pickTime, 31536000);
    }

    function hitPotProcess(string x1, bool send, uint pickTime) private {
        if( pickTime > potCntInfo[x1].last) {
            if (potCntInfo[x1].balance > 0 && send) {
                if (pickTime - potCntInfo[x1].last >= 20) {
                    potCntInfo[x1].balance = 0;
                    potCntInfo[x1].food = 0;
                    potCntInfo[x1].keys = 0;
                    delete potCntInfo[x1].player;
                    potCntInfo[x1].gameTime = 0;
                    potCntInfo[x1].gtime = pickTime;
                }
            }
        }
    }

    function maturityProcess(string x1, bool send, uint pickTime, uint addTime) private {
      if( pickTime > potCntInfo[x1].gameTime) {
          if ( (pickTime - potCntInfo[x1].gameTime) >= addTime) {
            if (potCntInfo[x1].balance > 0 && send) {
                potCntInfo[x1].balance = 0;
                potCntInfo[x1].food = 0;
                potCntInfo[x1].keys = 0;
                delete potCntInfo[x1].player;
                potCntInfo[x1].gameTime = 0;
                potCntInfo[x1].gtime    = pickTime;
            }
        }
      }
    }

    modifier restricted() {
        require(msg.sender == manager, "Only manager is allowed");
        _;
    }

    function random(uint maxNum, uint timestamp) private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, timestamp, potCntInfo['d'].balance, potCntInfo['7'].balance, potCntInfo['30'].balance, potCntInfo['90'].balance, potCntInfo['180'].balance, potCntInfo['365'].balance))) % maxNum;
    }

    function addRoyLuxList(string x1, string x2, uint timestamp, uint num) private {
        uint pick;

        if ( potCntInfo[x1].player.length < num) {
            if (idxStruct[x2].playerStruct[msg.sender].flag == 0 ) {
                idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(0, 0, potCntInfo[x1].player.length, potCntInfo['365'].gtime, 1);
                potCntInfo[x1].player.push(msg.sender);
            }
            else if (idxStruct[x2].playerStruct[msg.sender].gametime != potCntInfo['365'].gtime ) {
                idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(0, 0, potCntInfo[x1].player.length, potCntInfo['365'].gtime, 1);
                potCntInfo[x1].player.push(msg.sender);
            }
        }
        else {
            if (idxStruct[x2].playerStruct[msg.sender].flag == 0 ) {
                pick = random(potCntInfo[x1].player.length, timestamp);
                idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(0, 0, idxStruct[x2].playerStruct[potCntInfo[x1].player[pick]].idx, potCntInfo['365'].gtime, 1);
                idxStruct[x2].playerStruct[potCntInfo[x1].player[pick]].flag = 0;
                potCntInfo[x1].player[pick] = msg.sender;
            }
            else if (idxStruct[x2].playerStruct[msg.sender].gametime != potCntInfo['365'].gtime ) {
                pick = random(potCntInfo[x1].player.length, timestamp);
                idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(0, 0, idxStruct[x2].playerStruct[potCntInfo[x1].player[pick]].idx, potCntInfo['365'].gtime, 1);
                idxStruct[x2].playerStruct[potCntInfo[x1].player[pick]].flag = 0;
                potCntInfo[x1].player[pick] = msg.sender;
            }
        }
    }

    function getPotCnt(string x) public constant returns(uint count, uint pLast, uint pot, uint keystore, uint gtime, uint gameTime, uint food) {
        return (potCntInfo[x].player.length, potCntInfo[x].last, potCntInfo[x].balance, potCntInfo[x].keys, potCntInfo[x].gtime, potCntInfo[x].gameTime, potCntInfo[x].food);
    }

    function getIdx(string x1, string x2, uint p) public constant returns(address p1, uint key, uint food, uint gametime, uint flag) {
        return (potCntInfo[x1].player[p], idxStruct[x2].playerStruct[potCntInfo[x1].player[p]].key, idxStruct[x2].playerStruct[potCntInfo[x1].player[p]].food, idxStruct[x2].playerStruct[potCntInfo[x1].player[p]].gametime, idxStruct[x2].playerStruct[potCntInfo[x1].player[p]].flag);
    }

    function getLast(string x) public constant returns(uint lastRecord) {
        return potCntInfo[x].lastRecord;
    }

    function getLastPlayer(string x) public constant returns(address lastPlayer) {
        return potCntInfo[x].lastPlayer;
    }

    function sendFood(address p, uint food) public restricted {
         p.transfer(food);
    }

    function sendFoods(address[500] p, uint[500] food) public restricted {
        for(uint k = 0; k < p.length; k++){
            if (food[k] == 0) {
                return;
            }
            p[k].transfer(food[k]);
        }
    }

    function sendItDv(string x1) public restricted {
        msg.sender.transfer(potCntInfo[x1].balance);
        potCntInfo[x1].balance = 0;
    }

    function sendDv(string x1) public restricted {
        potCntInfo[x1].balance = 0;
    }

    function getReffAdd(string x) public constant returns(address){
      if( idxR[x].flag == 1){
        return idxR[x].player;
      }else{
        revert("Not found!");
      }
    }

    function getReffName(address x) public constant returns(string){
      if( idxRadd[x].flag){
        return idxRadd[x].name;
      }else{
        revert("Not found!");
      }
    }
}