/**
 *Submitted for verification at Etherscan.io on 2022-06-23
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
    Person [4] public  bidders;
    Item [3] public items;       
    address[3] public winners;   
    address public owner;  
    uint bidderCount=0; 
    
     constructor() public payable{                    
        owner = msg.sender;                         
        uint[] memory emptyArray; 
        items[0] = Item({itemId:0,itemTokens:emptyArray});
        items[1] = Item({itemId:1,itemTokens:emptyArray}); 
        items[2] = Item({itemId:2,itemTokens:emptyArray}); 

    }
   

    function buyBallot(uint count) public payable notOwner (){
            require(msg.value >= (0.01 ether)*count, "More eth required");
            bidders[bidderCount].personId = bidderCount;
            bidders[bidderCount].addr = (msg.sender);  
            bidders[bidderCount].remainingTokens = count;    
            tokenDetails[msg.sender]=bidders[bidderCount];
            bidderCount++;               
    }

    function bidCar(uint count) public payable notOwner{
        //απαίτηση από τον παίκτη που καλεί να έχει επαρκές πλήθος λαχείων
        require( count > 4 && tokenDetails[msg.sender].remainingTokens >= count, "You need to bid atleast 5 tickets");
        //αφαιρεση των λαχείων που έκανε bid 
        (tokenDetails[msg.sender].remainingTokens -= count); 
        //Ενημέρωση για το υπολοιπο λαχείων του παίκτη         
        bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
       Item storage car = items[0];    
        for(uint i=0; i<count; i++) { 
            car.itemTokens.push(tokenDetails[msg.sender].personId); 
        }
       
    }

    function bidPhone(uint count) public payable notOwner{
        require( count > 0 && tokenDetails[msg.sender].remainingTokens >= count, "You need to bid atleast 1 ticket");
        (tokenDetails[msg.sender].remainingTokens -= count);     
        bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
        Item storage phone = items[1];    
        for(uint i=0; i<count; i++) { 
            phone.itemTokens.push(tokenDetails[msg.sender].personId); 
        }
       
    }

    function bidcomputer(uint count) public payable notOwner{
        require( count > 2 && tokenDetails[msg.sender].remainingTokens >= count, "You need to bid atleast 3 tickets");
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
               if (car.itemTokens.length >= 5){
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
         }      if (computer.itemTokens.length >= 3){
                uint randomIndex = (block.number / computer.itemTokens.length) % computer.itemTokens.length; 
                uint winnerId = computer.itemTokens[randomIndex];
                winners[id] = bidders[winnerId].addr;                                        
         }


        }

             
    }
        //
        function endContact() onlyOwner public {
        selfdestruct(msg.sender);
    }


    modifier onlyOwner() {                                 
        require (msg.sender == owner);
        _;
     }

    modifier notOwner(){ // απόκληση της προσβασιμότητας του ιδιοκτήτη
       require (msg.sender != owner);
        _;
    }

}