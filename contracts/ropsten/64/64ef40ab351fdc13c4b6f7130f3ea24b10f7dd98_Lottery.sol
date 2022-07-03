/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity ^0.5.9;

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
    Person [1000] public  bidders;
    Item [3] public items;       
    address[3] public winners;   
    address payable public beneficiary;  
    uint bidderCount=0; 
    
     constructor() public payable{                    
        beneficiary = msg.sender;                         
        uint[] memory emptyArray; 
        items[0] = Item({itemId:0,itemTokens:emptyArray});
        items[1] = Item({itemId:1,itemTokens:emptyArray}); 
        items[2] = Item({itemId:2,itemTokens:emptyArray}); 

    }
   

    function bidCar() public payable notOwner Reg_Fee{
        uint count=1;
        //Αγορά λαχείου και τοποθέτηση bidder στον κλήρο
            bidders[bidderCount].personId = bidderCount;
            bidders[bidderCount].addr = (msg.sender);  
            bidders[bidderCount].remainingTokens = count;    
            tokenDetails[msg.sender]=bidders[bidderCount];
            bidderCount++; 
               
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

    function bidPhone() public payable notOwner{
    uint count=1;
        //Αγορά λαχείου και τοποθέτηση bidder στον κλήρο
            bidders[bidderCount].personId = bidderCount;
            bidders[bidderCount].addr = (msg.sender);  
            bidders[bidderCount].remainingTokens = count;    
            tokenDetails[msg.sender]=bidders[bidderCount];
            bidderCount++; 
               
        //απαίτηση από τον παίκτη που καλεί να έχει επαρκές πλήθος λαχείων
        require( count > 0 && tokenDetails[msg.sender].remainingTokens >= count, "no tickets");
        (tokenDetails[msg.sender].remainingTokens -= count);     
        bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
        Item storage phone = items[1];    
        for(uint i=0; i<count; i++) { 
            phone.itemTokens.push(tokenDetails[msg.sender].personId); 
        }
       
    }

    function bidcomputer() public payable notOwner{
          uint count=1;
        //Αγορά λαχείου και τοποθέτηση bidder στον κλήρο
            bidders[bidderCount].personId = bidderCount;
            bidders[bidderCount].addr = (msg.sender);  
            bidders[bidderCount].remainingTokens = count;    
            tokenDetails[msg.sender]=bidders[bidderCount];
            bidderCount++; 
               
        //απαίτηση από τον παίκτη που καλεί να έχει επαρκές πλήθος λαχείων
        require( count > 0 && tokenDetails[msg.sender].remainingTokens >= count, "no tickets");
        (tokenDetails[msg.sender].remainingTokens -= count);     
        bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
        Item storage computer = items[2];    
        for(uint i=0; i<count; i++) { 
            computer.itemTokens.push(tokenDetails[msg.sender].personId); 
        }
       
    }

    function revealWinners() public payable onlyOwner {
         for (uint id = 0; id < 3; id++) { 
             Item storage car = items[0];
             Item storage phone = items[1];    
             Item storage computer = items[2];           
               if (car.itemTokens.length >= 1){
                  // παραγωγή τυχαίου αριθμού
                  uint randomIndex = (block.number / car.itemTokens.length) % car.itemTokens.length; 
                  // ανάκτηση του αριθμού παίκτη που είχε αυτό το λαχείο
                  uint winnerId = car.itemTokens[randomIndex];
                  // ενημέρωση του πίνακα winners με τη διεύθυνση του νικητή
                  winners[id] = bidders[winnerId].addr;                                        
                }
                if (phone.itemTokens.length >= 1){
                    uint randomIndex = (block.number / phone.itemTokens.length) % phone.itemTokens.length; 
                    uint winnerId = phone.itemTokens[randomIndex];
                    winners[id] = bidders[winnerId].addr;    
                }                                    
                if (computer.itemTokens.length >= 1){
                    uint randomIndex = (block.number / computer.itemTokens.length) % computer.itemTokens.length; 
                    uint winnerId = computer.itemTokens[randomIndex];
                    winners[id] = bidders[winnerId].addr;                                        
                }
            }
        }

        function withdraw() public onlyOwner payable {
            beneficiary.transfer(address(this).balance);
        }

        //
        function endContact() onlyOwner public {
        selfdestruct(msg.sender);
    }


    modifier onlyOwner() {                                 
        require (msg.sender == beneficiary);
        _;
     }

    modifier notOwner(){ // απόκληση της προσβασιμότητας του ιδιοκτήτη
       require (msg.sender != beneficiary);
        _;
    }

   modifier Reg_Fee (){ // αναγκάζει την πληρωμή 0,01 ether 
       if (msg.value < 0.01 ether) {
            revert("You must pay a fee to register");
        }
      _;
    }


}