pragma solidity ^0.8.0;
 
contract Membership {

 
   address payable public owner;
   uint public totalMembers;
   mapping (address => uint) public members;
   mapping (address => bool) public payed;
   mapping (address => bool) public payedForStudies;
   mapping (address => address) public referrers;

   uint eduPrice = 1 ether;
 
   constructor() {
       owner = payable(msg.sender);
   }
 
    
   function becomeMember(address payable referrer) public payable  {
       require(msg.value == 0.05 ether, "Must pay 0.05 ether to become a member");
       
 
       // Add the new member to the list of members and set their referrer
       if(totalMembers == 0 || members[referrer] == 0) {
           referrer = owner;
       }
       totalMembers++;
       payed[msg.sender] = true;
       members[msg.sender] = msg.value;
       referrers[msg.sender] = referrer;

    //    if(referrer == owner) {
    //        referrer.transfer(msg.value);
    //    } 
       // If the referrer is already a member, give them 15 ether

       
        if (members[referrer] > 0) {
           referrer.transfer(0.015 ether);
 
           // If the referrer was referred by someone else, give them 10 ether
           if (referrers[referrer] != address(0)) {
               payable(referrers[referrer]).transfer(0.01 ether); 
 
               // If the person that referred them was also referred by someone else, give them 5 ether 
               if (referrers[referrers[referrer]] != address(0)) {
                   payable(referrers[referrers[referrer]]).transfer(0.005 ether); 
 
                   // Give the person that referred them 4 ether 
                   if(referrers[referrers[referrers[referrer]]] != address(0)) { 
                  payable(referrers[referrers[referrers[referrer]]]).transfer(0.004 ether);  }
 
                   // Give the person that referred them 3 ether 
                   if(referrers[referrers[referrers[referrers[referrer]]]] != address(0)) {
                   payable(referrers[referrers[referrers[referrers[referrer]]]]).transfer(0.004 ether);  }
 
                   // Give the person that referred them 2 ether 
                   if(referrers[referrers[referrers[referrers[referrers[referrer]]]]] != address(0)) {
                    payable(referrers[referrers[referrers[referrers[referrers[referrer]]]]]).transfer(0.004 ether);   }
 
                   // Give the person that referred them 1 ether 
                   if(referrers[referrers[referrers[referrers[referrers[referrers[referrer]]]]]] != address(0)) {
                  payable(referrers[referrers[referrers[referrers[referrers[referrers[referrer]]]]]]).transfer(0.004 ether);  }

                  if(referrers[referrers[referrers[referrers[referrers[referrers[referrer]]]]]] != address(0)) {
                  payable(referrers[referrers[referrers[referrers[referrers[referrers[referrers[referrer]]]]]]]).transfer(0.004 ether);  }
  

               } else {  // Otherwise, give all remaining funds to the owner
                  owner.transfer(address(this).balance);   
                
               } 
                   } else {      
                           owner.transfer(address(this).balance);    
                  
                   }}
                   else if(referrer == owner) {
                       owner.transfer(address(this).balance);    
                   }
                   } 


        function payToOwner() public payable {
             require(msg.value == 0.1 ether, "Must pay 1 ether to become a member");


       totalMembers++;
       payed[msg.sender] = true;
       members[msg.sender] = msg.value;
       referrers[msg.sender] = owner;

       owner.transfer(msg.value);

        }


                   
        function becomeStudent() public payable  {
             require(msg.value ==  eduPrice && payedForStudies[msg.sender] != true, "Must pay 1 ether to become a student");
             payedForStudies[msg.sender] = true;
             if(payed[msg.sender] == true) {
                 payable(msg.sender).transfer(0.05 ether);
             } 
          

    
    owner.transfer(address(this).balance);
        }

        function changeOwner(address payable newOwner) public {
            require(msg.sender == owner, "You are not the owner");

            owner = newOwner;
        }


    function addStudent(address _student) public {
        require(msg.sender == owner, "You are not the owner");
            payedForStudies[_student] = true;
    }

    function changePrice(uint newPrice) public {
        require(msg.sender == owner, "You are not the owner");

        eduPrice = newPrice;
    }
                   }