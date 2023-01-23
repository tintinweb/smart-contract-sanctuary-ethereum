// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract ShopWithBonusCards {
    string public shopName;
    address public owner;
    address otherContract;

    uint8 private constant MIN_VISITS_FOR_DISCOUNT = 3;
    bool locked=true;
    
    event VisitEvent(address indexed customerAddress,uint64 avaiableBoniCounter ,uint8 currentVisitCounter);//mit indexed kann man schneller nach etwas suchen
    event UseBonusEvent(address indexed customerAddress,uint64 avaiableBoniCounterAfterUse);
    event UseBonusEventError(address indexed customerAddress,string message);
    
    event Lock_UnlockEvent(address indexed customerAddress,bool locked);
    event VisitError(address indexed customerAddress,string message);
    //uint chainStartTime = block.timestamp;
    modifier onlyOwner(){
               require(msg.sender == owner, "Only the Shopowner is allowed to that");
        _;     // execute the rest of the code. Needed? satisfied while calling this function,
        // the function is executed and otherwise, an exception is thrown.
    }

    struct BonusCard{
        address customerAddress;
        uint8 visitsToGetDiscount;//LastVisitDate Possible to see in blockchain or own field and Update)?

        uint8 visitCounter;
        uint64 avaiableBoniCounter;//How often did he reach the visits
        
        bool isValid;
    }
    mapping(address=> BonusCard) private bonuscards;
  //  BonusCard[]  bonuscards;
    constructor(string memory shopname) {
        shopName=shopname;
         owner = msg.sender;//Should it be possible to change Owner?
    }

    function registerCustomer(address customerAdressToIncrease ) private  {//Should we calculate in Hours or visits
    //One Funtion for cutomer Where he is not allowed to set the
        require(!bonuscards[customerAdressToIncrease].isValid,"You are registered");
        bonuscards[customerAdressToIncrease]=BonusCard(msg.sender,MIN_VISITS_FOR_DISCOUNT,0,0,true);//This Should be the adress of the customer Check It !!!
    }
    function increaseVisitCounter(address customerAdressToIncrease) public onlyOwner  {//
         require(customerAdressToIncrease!=owner,"Owner is not allowed to have bonus cards");
        
         if(bonuscards[customerAdressToIncrease].isValid){
            require(bonuscards[customerAdressToIncrease].visitsToGetDiscount > 0,"Locked Card");
               BonusCard memory card=bonuscards[customerAdressToIncrease];
                card.visitCounter++; 
                if(card.visitCounter == card.visitsToGetDiscount ){
                  card.avaiableBoniCounter++;  //card.visitCounter=0;
                  card.visitCounter=0;//Count from begining
                }
            bonuscards[customerAdressToIncrease]=card;
            emit VisitEvent(customerAdressToIncrease,card.avaiableBoniCounter,card.visitCounter);//Also Log Counter?
        }else{
            registerCustomer(customerAdressToIncrease);
            BonusCard memory card=bonuscards[customerAdressToIncrease];
            card.visitCounter++;
            bonuscards[customerAdressToIncrease]=card;
            emit VisitEvent(customerAdressToIncrease, bonuscards[customerAdressToIncrease].avaiableBoniCounter, bonuscards[customerAdressToIncrease].visitCounter);//Also Log Counter?
        }
    }

    function useBonus(address customerAdressToUseBonus ) public onlyOwner {//Should
        require(bonuscards[customerAdressToUseBonus].isValid,"Invalid bonusCard\not registered");
        require(bonuscards[customerAdressToUseBonus].visitsToGetDiscount > 0,"Locked Card");
        require(bonuscards[customerAdressToUseBonus].avaiableBoniCounter > 0,"No Boni avaiable.Please make enough visit and dont forget to show your address");
        

            bonuscards[customerAdressToUseBonus].avaiableBoniCounter--;
            emit UseBonusEvent(customerAdressToUseBonus, bonuscards[customerAdressToUseBonus].avaiableBoniCounter);//Also Log Counter?
        
    }

    function useBonus( ) public {//Should
        require(bonuscards[msg.sender].isValid,"Invalid bonusCard\not registered");
        require(bonuscards[msg.sender].visitsToGetDiscount > 0,"Locked Card");
        require(bonuscards[msg.sender].avaiableBoniCounter > 0,"No Boni avaiable.Please make enough visit and dont forget to show your address");
        
        bonuscards[msg.sender].avaiableBoniCounter--;
        emit UseBonusEvent(msg.sender, bonuscards[msg.sender].avaiableBoniCounter);//Also Log Counter?
    }

    function lockCard(address customerAdressToLock) public onlyOwner {//Should
        require(bonuscards[customerAdressToLock].isValid,"Invalid bonusCard\not registered");
        require(bonuscards[customerAdressToLock].visitsToGetDiscount > 0,"Allready locked");

        bonuscards[customerAdressToLock].visitsToGetDiscount=0;
        emit Lock_UnlockEvent(customerAdressToLock,locked);
       
    }

    function unlockCard(address customerAdressToUnLock) public onlyOwner {//Should
        require(bonuscards[customerAdressToUnLock].isValid,"Invalid bonusCard\not registered");
        require(bonuscards[customerAdressToUnLock].visitsToGetDiscount == 0,"Allready unlocked");

        bonuscards[customerAdressToUnLock].visitsToGetDiscount=MIN_VISITS_FOR_DISCOUNT;
       emit Lock_UnlockEvent(customerAdressToUnLock,!locked);
       
    }


    function getBonuscard()public view returns (BonusCard memory) {
        return   bonuscards[msg.sender];
    }
    function getBonuscard(address customerAdressToUseBonus)public view returns (BonusCard memory) {//For Demo
        return   bonuscards[customerAdressToUseBonus];
    }


     function setOtherContract(address contractAddress)public onlyOwner {//For Demo The pointer to the next contract
        otherContract=contractAddress;
     }
    //Invalidate Cards could be implemented (With constant)?
    //Change maxVisits of one Customer
   
}