pragma solidity ^0.4.24;

contract dPonzi {
    address public manager;//who originally create the contract

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

        potCntInfo['d'].gameTime = now;
        potCntInfo['7'].gameTime = now;
        potCntInfo['30'].gameTime = now;
        potCntInfo['90'].gameTime = now;
        potCntInfo['180'].gameTime = now;
        potCntInfo['365'].gameTime = now;
        potCntInfo['l'].gameTime = now;
        potCntInfo['r'].gameTime = now;

        potCntInfo['d'].gtime   = now;
        potCntInfo['7'].gtime   = now;
        potCntInfo['30'].gtime  = now;
        potCntInfo['90'].gtime  = now;
        potCntInfo['180'].gtime = now;
        potCntInfo['365'].gtime = now;
        potCntInfo['l'].gtime   = now;
        potCntInfo['r'].gtime   = now;

        potCntInfo['d'].last  = now;
        potCntInfo['7'].last  = now;
        potCntInfo['30'].last = now;
        potCntInfo['90'].last = now;
        potCntInfo['180'].last  = now;

        //declare precalculated entry amount to save gas during entry
        potCntInfo['i'].entryAmount     = 10;
        potCntInfo['d'].entryAmount     = 1;
        potCntInfo['7'].entryAmount     = 4;
        potCntInfo['30'].entryAmount    = 8;
        // pot 90 and  pot dividend share the same 15%
        potCntInfo['90'].entryAmount    = 15;
        potCntInfo['180'].entryAmount   = 25;
        //pot 365 and pot royal share the same 5%
        potCntInfo['365'].entryAmount   = 5;
        potCntInfo['l'].entryAmount     = 2;
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
            //Allocation
            potCntInfo['d'].balance   += potCntInfo['d'].entryAmount    * multiplier;
            potCntInfo['7'].balance   += potCntInfo['7'].entryAmount    * multiplier;
            potCntInfo['30'].balance  += potCntInfo['30'].entryAmount   * multiplier;
            potCntInfo['90'].balance  += potCntInfo['90'].entryAmount   * multiplier;
            potCntInfo['180'].balance += potCntInfo['180'].entryAmount  * multiplier;
            potCntInfo['365'].balance += potCntInfo['365'].entryAmount  * multiplier;
            potCntInfo['l'].balance   += potCntInfo['l'].entryAmount    * multiplier;
            potCntInfo['r'].balance   += potCntInfo['365'].entryAmount  * multiplier;
            //admin amount
            potCntInfo['i'].balance   += potCntInfo['i'].entryAmount    * multiplier;
            potCntInfo['dv'].balance  += potCntInfo['90'].entryAmount   * multiplier;

            addPlayerMapping('d',   'idxDaily',  key, 30);//30 + 20
            addPlayerMapping('7',   'idx7Pot',   key, 60);
            addPlayerMapping('30',  'idx30Pot',  key, 90);
            addPlayerMapping('90',  'idx90Pot',  key, 120);
            addPlayerMapping('180', 'idx180Pot', key, 150);
            addPlayerMapping('365', 'idx365Pot', key, 0);
        }
    }

    function addPlayerMapping(string x1, string x2, uint key, uint timeAdd ) private{
      //if smaller, which means the game is expired.
      if(potCntInfo[x1].last <= now){
        potCntInfo[x1].last = now;
      }
      /* potCntInfo[x1].last += (key * timeAdd); */
      potCntInfo[x1].last += (key * timeAdd);

      //Add into Players Mapping
      if (idxStruct[x2].playerStruct[msg.sender].flag == 0) {
          potCntInfo[x1].player.push(msg.sender);
          idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(key, 0, potCntInfo[x1].player.length, potCntInfo[x1].gtime, 1);
      }
      else if (idxStruct[x2].playerStruct[msg.sender].gametime != potCntInfo['d'].gtime){
          potCntInfo[x1].player.push(msg.sender);
          idxStruct[x2].playerStruct[msg.sender] = PlayerStruct(key, 0, potCntInfo[x1].player.length, potCntInfo[x1].gtime, 1);
      }
      else {
          idxStruct[x2].playerStruct[msg.sender].key += key;
      }
      potCntInfo[x1].keys += key;
    }

    function joinboard(string name) public payable {
        require(msg.value >= 0.01 ether, "0 ether is not allowed");

        if (idxR[name].flag == 0 ) {
            idxR[name] = RefStruct(msg.sender, 1);
            potCntInfo['i'].balance += msg.value;
            /* add to address mapping  */
            idxRadd[msg.sender].name = name;
            idxRadd[msg.sender].flag = true;
        }
        else {
            revert("Name is not unique");
        }
    }


    function pickFood(uint pickTime, string x1, string x2, uint num) public restricted {
        uint i=0;
        uint j=0;
        if (potCntInfo[x1].player.length > 0 && potCntInfo[x1].food <= num) {//if pot.player has player and pot has food less than pass in num
            do {
                j = potCntInfo[x1].keys < num ? j : random(potCntInfo[x1].player.length, pickTime);//random pick players in pot
                if (idxStruct[x2].playerStruct[potCntInfo[x1].player[j]].food > 0) {//if potplayer[address] has food > 0, get next potPlayer[address]
                    j++;
                }
                else {
                    idxStruct[x2].playerStruct[potCntInfo[x1].player[j]].food = potCntInfo[x1].keys < num ? idxStruct[x2].playerStruct[potCntInfo[x1].player[j]].key : random(idxStruct[x2].playerStruct[potCntInfo[x1].player[j]].key, pickTime);
                    if (potCntInfo[x1].food + idxStruct[x2].playerStruct[potCntInfo[x1].player[j]].food > num) {//if pot.food + potPlayer.food > num
                        idxStruct[x2].playerStruct[potCntInfo[x1].player[j]].food = num-potCntInfo[x1].food;
                        potCntInfo[x1].food = num;
                        break;
                    }
                    else {
                        potCntInfo[x1].food += idxStruct[x2].playerStruct[potCntInfo[x1].player[j]].food;
                    }
                    j++; i++;
                }

                if( potCntInfo[x1].keys < num && j == potCntInfo[x1].player.length) {//exit loop when pot.keys less than num
                    break;
                }

                if(potCntInfo[x1].food == num) {//exit loop when pot.food less than num
                    break;
                }
            }
            while (i<10);
            potCntInfo[x1].lastRecord = potCntInfo[x1].keys < num ? (potCntInfo[x1].keys == potCntInfo[x1].food ? 1 : 0) : (potCntInfo[x1].food == num ? 1 : 0);
        }
        else {
            potCntInfo[x1].lastRecord = 1;
        }
    }

    function pickWinner(uint pickTime, bool sendDaily, bool send7Pot, bool send30Pot, bool send90Pot, bool send180Pot, bool send365Pot) public restricted{

        //Hit the Daily pot
        hitPotProcess('d', sendDaily, pickTime);
        //Hit the 7 day pot
        hitPotProcess('7', send7Pot,  pickTime);
        //Hit the 30 day pot
        hitPotProcess('30', send30Pot, pickTime);
        //Hit the 90 day pot
        hitPotProcess('90', send90Pot, pickTime);
        //Hit the 180 day pot
        hitPotProcess('180', send180Pot, pickTime);

        //Hit daily pot maturity
        maturityProcess('d', sendDaily, pickTime, 86400);
        //Hit 7 pot maturity
        maturityProcess('7', send7Pot, pickTime, 604800);
        //Hit 30 pot maturity
        maturityProcess('30', send30Pot, pickTime, 2592000);
        //Hit 90 pot maturity
        maturityProcess('90', send90Pot, pickTime, 7776000);
        //Hit 180 pot maturity
        maturityProcess('180', send180Pot, pickTime, 15552000);
        //Hit 365 pot maturity
        maturityProcess('365', send365Pot, pickTime, 31536000);


        //Hit 365 days pot maturity
        if (potCntInfo['365'].balance > 0 && send365Pot) {
            if (pickTime - potCntInfo['365'].gameTime >= 31536000) {
                maturityProcess('l', send365Pot, pickTime, 31536000);
                maturityProcess('r', send365Pot, pickTime, 31536000);
            }
        }
    }

    function hitPotProcess(string x1, bool send, uint pickTime) private {
      if (potCntInfo[x1].balance > 0 && send) {
          if (pickTime - potCntInfo[x1].last >= 20) { //additional 20 seconds for safe
              potCntInfo[x1].balance = 0;
              potCntInfo[x1].food = 0;
              potCntInfo[x1].keys = 0;
              delete potCntInfo[x1].player;
              potCntInfo[x1].gtime = pickTime;
          }
      }
    }

    function maturityProcess(string x1, bool send, uint pickTime, uint addTime) private {
      if (potCntInfo[x1].balance > 0 && send) {
          if (pickTime - potCntInfo[x1].gameTime >= addTime) {
              potCntInfo[x1].balance = 0;
              potCntInfo[x1].food = 0;
              potCntInfo[x1].keys = 0;
              delete potCntInfo[x1].player;
              potCntInfo[x1].gameTime = pickTime;
              potCntInfo[x1].gtime = pickTime;
          }
      }
    }

    //Start : Util Function
    modifier restricted() {
        require(msg.sender == manager, "Only manager is allowed");//must be manager to call this function
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

    function getIdx(string x1, string x2, uint p) public constant returns(address p1, uint food, uint gametime, uint flag) {
        return (potCntInfo[x1].player[p], idxStruct[x2].playerStruct[potCntInfo[x1].player[p]].food, idxStruct[x2].playerStruct[potCntInfo[x1].player[p]].gametime, idxStruct[x2].playerStruct[potCntInfo[x1].player[p]].flag);
    }

    function getLast(string x) public constant returns(uint lastRecord) {
        return potCntInfo[x].lastRecord;
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

    //End : Util Function
}