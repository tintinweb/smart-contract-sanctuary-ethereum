// SPDX-License-Identifier: UNLICENSED
pragma solidity < 0.9.0;

import "./Pashanga.sol";

contract DonateBlood is Pashanga {

   event Donation (address from, address to,string message);

   address public possibleDonator;

   enum BloodTypes {
      oPlus,
      oMinus,
      bPlus,
      bMinus,
      aMinus,
      aPlus,
      abPlus,
      abMinus,
      notSpecified
   }

   struct Donater {
      address wallet;
      string name;
      BloodTypes bloodType;
      uint age;
      bool eligible;
      string country;
      uint minted;
   }

   mapping(address => Donater) public donaters;

   constructor () public {
      possibleDonator = msg.sender;
      Donater memory donater = Donater(
            address(0),
            "",
            BloodTypes.notSpecified,
            0,
            false,
            "",
            0);
            
      donaters[possibleDonator] = donater;
   }

   /* BLOOD TYPE SETTER */
   function setBloodType(BloodTypes newType) public {
      donaters[possibleDonator].bloodType = newType;
   }

   function setDonatorProfile(Donater memory donator) public{
      address walletAddress = donator.wallet;
      donaters[walletAddress] = donator;
   }

   function getDonatorProfile(address donatorAddress) public view returns (Donater memory) {
      return donaters[donatorAddress];
   }

   /* BLOOD TYPE GETTER */
   function getUserBloodType(address user) public view returns (BloodTypes) {
      return donaters[user].bloodType;
   }

   /* MODIFER TO MAKE SURE USER IS ALLOWED TO CHANGE */
   /* HIS/HER BLOOD TYPE ONLY ONCE */
   modifier onlyOnce() {
      require(donaters[possibleDonator].bloodType == BloodTypes.notSpecified,
            "YOU CAN CHANGE YOUR BLOOD TYPE ONCE");
      _;
   }

   /* DONATIONS ARE ALLOWED ONLY IF BLOODTYPE IS SPECIFIED */
   modifier onlySpecified (BloodTypes from, BloodTypes to) {
      require(from != BloodTypes.notSpecified && to != BloodTypes.notSpecified,
      "One of the parties did not specify his/her blood type");
      _;
   }

   function possibleDonationTsx (address from,address to) public view returns(bool) {
      return checkCompatibility(donaters[from].bloodType,
                                donaters[to].bloodType);
   }

   /* LOOP THROUGH BLOODTYPES AND DETERMINE IF THEY MATCH */
   function checkCompatibility(BloodTypes from, BloodTypes to) 
         private onlySpecified(from,to) pure returns (bool) {
      
      /* SAME BLOOD TYPE */
      /* OR AB+ RECIEVE ALL */
      if(from == to || to == BloodTypes.abPlus) return true;

      /* AB- => AB- A- O- B- */
      if(to == BloodTypes.abMinus && 
         from == BloodTypes.abMinus ||
         from == BloodTypes.aMinus ||
         from == BloodTypes.bMinus ||
         from == BloodTypes.oMinus) return true;

      /* A+ => O- O+ A+ A- */
      if(to == BloodTypes.aPlus && 
         from == BloodTypes.aPlus ||
         from == BloodTypes.aMinus ||
         from == BloodTypes.oPlus ||
         from == BloodTypes.oMinus) return true;

      /* A- => A- O- */
      if(to == BloodTypes.aMinus && 
         from == BloodTypes.aMinus ||
         from == BloodTypes.oMinus) return true;

      /* B+ => B- B+ O- O+ */
      if(to == BloodTypes.bPlus && 
         from == BloodTypes.bPlus ||
         from == BloodTypes.bMinus ||
         from == BloodTypes.oPlus ||
         from == BloodTypes.oMinus) return true;

      /* B- => B- O- */
      if(to == BloodTypes.bMinus && 
         from == BloodTypes.oMinus ||
         from == BloodTypes.bMinus) return true;

      /* O+ => O+ O- */
      if(to == BloodTypes.oPlus && 
         from == BloodTypes.oMinus ||
         from == BloodTypes.oPlus) return true;
      
      /* O+ => O+ O- */
      if(to == BloodTypes.oMinus && 
         from == BloodTypes.oMinus) return true;

      return false;
   }

   /* ONLY IF BLOOD TYPE ARE COMPATIBLE */
   modifier onlyIfCompatible(address from, address to) {
      BloodTypes fromType = donaters[from].bloodType;
      BloodTypes toType = donaters[to].bloodType;

      require(fromType != BloodTypes.notSpecified ||
              toType != BloodTypes.notSpecified,
              "DONATOR OR RECIEVER BLOOD TYPE IS UNSPECIFIED ");

      require(checkCompatibility(fromType, toType) == true,
      "You cannot donate due to Blood Types not compatible");
      _;
   }

   /* DONATION */
   function donate(address from, address to) public  onlyIfCompatible(from,to) {
      emit Donation(from, to,"THANK YOU FOR HELPING OTHERS !!");

      /* REWARD DONATOR WITH PSH */
      transfer(to, 200000);
   }
}