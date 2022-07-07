/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Lottery {

    struct Item { 
        uint itemId;          
        uint[] itemTokens;    
    }

    struct Person { 
        uint personId;        
        address addr;
        uint remainingTokens;
    }

    mapping(address => Person) tokenDetails; 
    Person [1000] public bidders;
    Item [3] public items;       
    address[3] public winners;   
    address payable public beneficiary;  
    uint CarbidderCount=0; 
    uint PhonebidderCount=0; 
    uint PCbidderCount=0; 
    address payable public admin;
   
     constructor()  payable{                    
        beneficiary = payable(msg.sender);    
        admin = payable(msg.sender);                 
        uint[] memory emptyArray; 
        items[0] = Item({itemId:0,itemTokens:emptyArray});
        items[1] = Item({itemId:1,itemTokens:emptyArray}); 
        items[2] = Item({itemId:2,itemTokens:emptyArray}); 
    }
    
    function bidCar() public payable notOwner Reg_Fee{
        uint count=1;
        //Αγορά λαχείου και τοποθέτηση bidder στον κλήρο
            bidders[CarbidderCount].personId = CarbidderCount;
            bidders[CarbidderCount].addr = (msg.sender);  
            bidders[CarbidderCount].remainingTokens = count;    
            tokenDetails[msg.sender]=bidders[CarbidderCount];
            CarbidderCount++; 
            //απαίτηση από τον παίκτη που καλεί να έχει επαρκές πλήθος λαχείων
            require( count > 0 && tokenDetails[msg.sender].remainingTokens >= count, "no tickets");
            //αφαιρεση των λαχείων που έκανε bid 
            (tokenDetails[msg.sender].remainingTokens -= count); 
            //Ενημέρωση για το υπολοιπο λαχείων του παίκτη         
            bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
            Item storage car = items[0];    
            for(uint i=0; i<count; i++) { 
                car.itemTokens.push(tokenDetails[msg.sender].personId); 
            } 
        }

    function bidPhone() public payable notOwner Reg_Fee{
    uint count=1;
        //Αγορά λαχείου και τοποθέτηση bidder στον κλήρο
            bidders[PhonebidderCount].personId = PhonebidderCount;
            bidders[PhonebidderCount].addr = (msg.sender);  
            bidders[PhonebidderCount].remainingTokens = count;    
            tokenDetails[msg.sender]=bidders[PhonebidderCount];
            PhonebidderCount++; 
        //απαίτηση από τον παίκτη που καλεί να έχει επαρκές πλήθος λαχείων
            require( count > 0 && tokenDetails[msg.sender].remainingTokens >= count, "no tickets");
            (tokenDetails[msg.sender].remainingTokens -= count);     
            bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
            Item storage phone = items[1];    
            for(uint i=0; i<count; i++) { 
                phone.itemTokens.push(tokenDetails[msg.sender].personId); 
            } 
        }

    function bidcomputer() public payable notOwner Reg_Fee{
          uint count=1;
        //Αγορά λαχείου και τοποθέτηση bidder στον κλήρο
            bidders[PCbidderCount].personId = PCbidderCount;
            bidders[PCbidderCount].addr = (msg.sender);  
            bidders[PCbidderCount].remainingTokens = count;    
            tokenDetails[msg.sender]=bidders[PCbidderCount];
            PCbidderCount++;          
        //απαίτηση από τον παίκτη που καλεί να έχει επαρκές πλήθος λαχείων
            require( count > 0 && tokenDetails[msg.sender].remainingTokens >= count, "no tickets");
            (tokenDetails[msg.sender].remainingTokens -= count);     
            bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
            Item storage computer = items[2];    
            for(uint i=0; i<count; i++) { 
                computer.itemTokens.push(tokenDetails[msg.sender].personId); 
             }
        }
    //κλήρωση αυτοκινήτου
   function revealCarWinners() public OwnerAndAdmin payable { 
        uint id = 0;
        Item storage car = items[id];
        if (car.itemTokens.length !=0){
                // παραγωγή τυχαίου αριθμού
                uint randomIndex = (block.number / car.itemTokens.length) % car.itemTokens.length; 
                // ανάκτηση του αριθμού παίκτη που είχε αυτό το λαχείο
                uint winnerId = car.itemTokens[randomIndex];
                // ενημέρωση του πίνακα winners με τη διεύθυνση του νικητή
                winners[id] = bidders[winnerId].addr;         
            }
        }

    //κλήρωση τηλεφώνου
        function revealPhoneWinner() public OwnerAndAdmin payable{
        uint id = 1;
        Item storage phone = items[id];           
        if (phone.itemTokens.length !=0){
                uint randomIndex = (block.number / phone.itemTokens.length) % phone.itemTokens.length; 
                uint winnerId = phone.itemTokens[randomIndex];
                winners[id] = bidders[winnerId].addr;    
            }                                    
        }
    
     //κλήρωση laptop
    function revealPCWinner() public OwnerAndAdmin payable {
        uint id = 2;
        Item storage computer = items[id];           
        if (computer.itemTokens.length!=0){
                uint randomIndex = (block.number / computer.itemTokens.length) % computer.itemTokens.length; 
                uint winnerId = computer.itemTokens[randomIndex];
                winners[id] = bidders[winnerId].addr;                                        
            }
        }
        
   //Ανάληωη χρημάτων
    function withdraw() public onlyOwner payable {
        beneficiary.transfer(address(this).balance);
    }

    //μεταφορά συμβολαίου σε νέο ιδιοκτήτη
    function transferOwner(address newOwner) external onlyOwner payable  {
        require(newOwner != address(0), "invalid address");
        beneficiary = payable(newOwner);
    }


    function addAddAdmin(address  AddAdmin) external onlyOwner payable {
        require(AddAdmin != address(0));
        admin =payable(0x153dfef4355E823dCB0FCc76Efe942BefCa86477);
    }
     function transferAdmin(address newAdmin) external OwnerAndAdmin payable  {
        require(newAdmin != address(0), "invalid address");
        admin = payable(newAdmin);
    }
    //καταστροφή συμβολαίου
    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
 //επιστροφή αριθμού bid κάθε αντικειμένου   
     function getCarBids() public view returns (uint) {
        return CarbidderCount ;
    }
      function getPCBids() public view returns (uint) {
        return PCbidderCount ;
    }
      function getPhoneBids() public view returns (uint) {
        return PhonebidderCount ;
    }   
   //επιστροφή διευθύνσεων νικητών 
     function getCarWin() public view returns (address) {
        return winners[0] ;
    }
     function getPhoneWin() public view returns (address) {
        return winners[1] ;
    }
     function getLaptopWin() public view returns (address) {
        return winners[2] ;
    }

    modifier onlyOwner() {                                 
        require (msg.sender == beneficiary );
        _;
    }
      modifier OwnerAndAdmin() {                                 
        require (msg.sender == beneficiary || msg.sender == admin );
        _;
     }

    modifier notOwner(){ // απόκληση της προσβασιμότητας του ιδιοκτήτη
       require (msg.sender != beneficiary && msg.sender != admin );
        _;
    }

     modifier Reg_Fee (){ // αναγκάζει την πληρωμή 0,01 ether 
       if (msg.value < 0.01 ether) {
            revert("You must pay a fee to register");
        }
      _;
    }
}