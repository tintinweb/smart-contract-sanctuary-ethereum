/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity >=0.4.22 <0.7.0;

contract voing{

   struct people {
        bool doing;
    }

   mapping(address => people) eachperson;

   int public yes = 0;
   int public no = 0;
   int public abstention = 0;
   int public total = 0;

   constructor() public{
      yes = 0;
      no = 0;
      abstention = 0;
   }



   function vote(int option) public{
      people storage sender = eachperson[msg.sender];
      require(!sender.doing, "Already voted.");

      if(option == 1){
         yes = yes+1;
         total = total + 1;
         sender.doing = true;
      }
      if(option == 2){
         no = no+1;
         total = total + 1;
         sender.doing = true;
      }
      if(option == 3){
         abstention = abstention+1;
         total = total + 1;
         sender.doing = true;
      }
   }

   function show(int option) public view returns(int counts){
      if(option == 1){
         return yes;
      }
      if(option == 2){
         return no;
      }
      if(option == 3){
         return abstention;
      }
   }

   function checkdoing() public view returns(int checknum, address){
      people storage sender = eachperson[msg.sender];

      if(sender.doing == true){
         return (1, msg.sender);
      }
      if(sender.doing == false){
         return (2, msg.sender);
      }
   }

}