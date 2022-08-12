// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Pet {
    uint256 petLevel;
    uint256 petXP;
    uint256 public bornTime; //time pet born seconds since the epoch
    uint256 public timePassed; //time pet born
    int public lastOnChainHP;
    uint256 public HPRemInterval; //at what hour interval we remove HP
     uint256 public HHRemInterval; //at what hour interval we remove HH
    uint256 public lastOnChainXP;
    int public lastOnChainHH;
    uint256 public lastHHGiven;
    int public healthTreat; //the ethereum amount (price) per 1 treat
    int public healthPerTreat; //the HP amount added per 1 treat
    int public happinessPerTreat; //the HP amount added per 1 treat
    uint256 public xpTreat; //the ethereum amount (price) per 1 treat
    uint256 public xpPerTreat; //the HP amount added per 1 treat
    address owner;

   struct User { 
   address petfeeder;
   bool allowedOne;
     bool allowedTwo;
       bool allowedThree;
         bool allowedFour;
           bool allowedFive;
             bool allowedSix;
               bool allowedSeven;
                 bool allowedEight;
                   bool allowedNine;
                     bool allowedTen;
                       bool allowedExtra;
}



  mapping (address => User) public users;

    address[] public user_accts;


constructor() {
    owner = msg.sender;
    bornTime = block.timestamp; //born time
    lastOnChainHP = 100; //starting HP of pet
    healthTreat = 0.0001 ether; // starting ethereum amount (price) per 1 treat
    healthPerTreat = 5; //starting with 1 treat = 5 HP
    HPRemInterval = 1;
    HHRemInterval = 1;
    happinessPerTreat = 1;
    lastOnChainHH = 5;
    lastHHGiven =block.timestamp;
    xpTreat = 0.0001 ether; // starting ethereum amount (price) per 1 treat
    xpPerTreat = 10; //starting with 1 treat = 5 HP

    // XP LU 0.1 | 0.2 | 0.5 | 1 | 3 | 7 | 15 | 25 | 50 | 100
    }

modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }

function addStructData(address _addr) internal {

    User storage newUser = users[_addr];


    if(levelUpPet()<=0){
   newUser.petfeeder=msg.sender;
   newUser.allowedOne=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>0 && levelUpPet()<=1){
 newUser.petfeeder=msg.sender;
   newUser.allowedTwo=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>1 && levelUpPet()<=2){
 newUser.petfeeder=msg.sender;
   newUser.allowedThree=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>2 && levelUpPet()<=3){
 newUser.petfeeder=msg.sender;
   newUser.allowedFour=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>3 && levelUpPet()<=4){
 newUser.petfeeder=msg.sender;
   newUser.allowedFive=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>4 && levelUpPet()<=5){
 newUser.petfeeder=msg.sender;
   newUser.allowedSix=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>5 && levelUpPet()<=6){
 newUser.petfeeder=msg.sender;
   newUser.allowedSeven=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>6 && levelUpPet()<=7){
 newUser.petfeeder=msg.sender;
   newUser.allowedEight=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>7 && levelUpPet()<=8){
 newUser.petfeeder=msg.sender;
   newUser.allowedNine=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>8 && levelUpPet()<=9){
 newUser.petfeeder=msg.sender;
   newUser.allowedTen=true;
   user_accts.push(msg.sender);
}else if(levelUpPet()>9 && levelUpPet()<=10){
 newUser.petfeeder=msg.sender;
   newUser.allowedExtra=true;
   user_accts.push(msg.sender);
}
}

function setHealthTreatPrice(int _ethAmt) public onlyOwner {
    healthTreat = _ethAmt;
    }

function setHealthPerTreat(int _Amt) public onlyOwner {
    healthPerTreat = _Amt;
    }

function sethappinessPerTreat(int _Amt) public onlyOwner {
    happinessPerTreat = _Amt;
    }

function setHPRemInterval(uint256 _Amt) public onlyOwner {
    HPRemInterval = _Amt;
    }

function addHP(int _amtTreats) public payable {
    require(
     int(msg.value) >= (healthTreat * _amtTreats),
    "not enough Ether sir"
        );

        addStructData(msg.sender);

if(getHP() <= 0){
        lastOnChainHP = (healthPerTreat * _amtTreats);
 } else{lastOnChainHP =  lastOnChainHP -int(((block.timestamp - bornTime) / 60) / HPRemInterval) + (healthPerTreat * _amtTreats);
       }

     bornTime =block.timestamp;
        
    }

function addHH(int _amtTreats) public payable {
        require(
            int(msg.value) >= (happinessPerTreat * _amtTreats),
            "not enough Ether sir"
        );

        addStructData(msg.sender);

       if(
             getHH() <= 0
       ){
             lastOnChainHH = (happinessPerTreat * _amtTreats);
       } else{
           lastOnChainHH = lastOnChainHH -int(((block.timestamp - lastHHGiven) / 60) / HHRemInterval)+ (happinessPerTreat * _amtTreats);
       }
         lastHHGiven =block.timestamp;

          addStructData(msg.sender);
    }

function addXP(uint256 _amtTreats) public payable {


require(msg.value >= (xpTreat * _amtTreats), "not enough Ether sir");
addStructData(msg.sender);

if(getHH() > 0){
lastOnChainXP = lastOnChainXP + (2 * xpPerTreat * _amtTreats);
}else{
lastOnChainXP = lastOnChainXP + (xpPerTreat * _amtTreats);
}
        
        
        
    }

function getLevel() public view returns (uint256) {

        // add level up logic
        return petLevel;
    }

function getHP() public view returns (int) {
        return
            lastOnChainHP -int(((block.timestamp - bornTime) / 60) / HPRemInterval);  // every 4 minnutes
    }

function getXP() public view returns (uint256) {
        return lastOnChainXP;
    }

function getHH() public view returns (int) {

        return lastOnChainHH -int(((block.timestamp - lastHHGiven) / 60) / HHRemInterval); // every 1 minnute
    }

function withdraw() public onlyOwner{

        payable(msg.sender).transfer(address(this).balance);
    }

function withdrawERC(address _tokenAddr) public onlyOwner{

        //add logic
    }


function levelUpPet()public view returns(uint){

    // XP LU 0.1 | 0.2 | 0.5 | 1 | 3 | 7 | 15 | 25 | 50 | 100
if(getXP() <= 10000){

    return 0;

}else if(getXP() <= 20000 && getXP()>10000){
 return 1;
}else if(getXP() <= 50000 && getXP()>20000){
     return 2;
}else if(getXP() <= 100000 && getXP()>50000){
     return 3;
}else if(getXP() <= 300000 && getXP()>100000){
     return 4;
}else if(getXP() <= 700000 && getXP()>300000){
     return 5;
}else if(getXP() <= 1500000 && getXP()>700000){
     return 6;
}else if(getXP() <= 2500000 && getXP()>1500000){
   return 7;
}else if(getXP() <= 5000000 && getXP()>2500000){
     return 8;
}else if(getXP() <= 10000000 && getXP()>5000000){
     return 9;
}else{
    return 10;
}

}

    /// @dev Allows contract to receive ETH
    receive() external payable {}
}