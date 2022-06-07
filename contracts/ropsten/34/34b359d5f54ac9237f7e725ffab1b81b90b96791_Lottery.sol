/**
 *Submitted for verification at Etherscan.io on 2022-06-07
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
        bool hasRegistered; //χρήση για την απαγόρευση επαναεγγραφής
    }

    mapping(address => Person) tokenDetails; 
    Person [4] public  bidders;
    Item [3] public items;       
    address[3] public winners;   
    address payable public  beneficiary;  
    uint bidderCount=0; 
    mapping(address  => Person) public alreadyRegistered; //χρήση για την απαγόρευση επαναεγγραφής

    enum Stage {Init, Reg, Bid, Done}
    Stage public stage;
    uint startTime;
    uint public timeNow;

        constructor() public payable{                    
        beneficiary = msg.sender;                         
        uint[] memory emptyArray; 
        items[0] = Item({itemId:0,itemTokens:emptyArray});
        items[1] = Item({itemId:1,itemTokens:emptyArray}); 
        items[2] = Item({itemId:2,itemTokens:emptyArray}); 

        stage = Stage.Init;
        startTime = now;
    }
   

    function register() public payable notOwner Reg_Fee (){
            //Εντοπισμός της διεύθυνσης αυτού που καλεί τη register και έλεγχος
            // για αν έκανε ήδη εγγραφή  
            Person storage currentBidder = alreadyRegistered[msg.sender];
            require(!currentBidder.hasRegistered,"You have already registered.");
            //αν δεν είναι ήδη εγγεγραμμένοι, τότε μπορούν να εγγραφούν
            currentBidder.personId;
            currentBidder.hasRegistered = true;

            bidders[bidderCount].personId = bidderCount;
            bidders[bidderCount].addr = (msg.sender);  
            bidders[bidderCount].remainingTokens = 5;          
            tokenDetails[msg.sender]=bidders[bidderCount];
            bidderCount++;  

            //εγγραφές παικτών να επιτρέπονται μόνο όταν η stage είναι Reg
            if (now > (startTime + 10 seconds)){stage = Stage.Reg; startTime = now;} 
    }


    function bid(uint itemId, uint count) public payable notOwner{

        //απαίτηση από τον παίκτη που καλεί να έχει επαρκές πλήθος λαχείων
        require(count > 0 && tokenDetails[msg.sender].remainingTokens >= count, "Not enough tokens");
        //απαίτηση από τον παίκτη που καλεί να έχει διαλέξει το σωστό αντικείμενο
        require(itemId >= 0 && itemId <= 2, "Item does not exists");       
        
        //αφαιρεση των λαχείων που έκανε bid 
        (tokenDetails[msg.sender].remainingTokens -= count); 

        //Ενημέρωση για το υπολοιπο λαχείων του παίκτη         
        bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;  
        Item storage bidItem = items[itemId]; 
        for(uint i=0; i<count; i++) { 
        bidItem.itemTokens.push(tokenDetails[msg.sender].personId); 
        }
        //τοποθετήσεις λαχείων σε κληρωτίδες μόνο όταν η stage είναι Bid
        if (now > (startTime + 10 seconds)){stage = Stage.Bid;} 
    }


    function revealWinners() public onlyOwner {
        
         for (uint id = 0; id < 3; id++) { 
             Item storage currentItem = items[id];       
               if (currentItem.itemTokens.length != 0){
                  // παραγωγή τυχαίου αριθμού
                  uint randomIndex = (block.number / currentItem.itemTokens.length) % currentItem.itemTokens.length; 
                  // ανάκτηση του αριθμού παίκτη που είχε αυτό το λαχείο
                  uint winnerId = currentItem.itemTokens[randomIndex];
                  // ενημέρωση του πίνακα winners με τη διεύθυνση του νικητή
                  winners[id] = bidders[winnerId].addr;                                        
            }     
        }
        //emit Winner (winners.addr,winners.currentItem,winners.itemTokens);

        //κληρώσεις να επιτρέπονται μόνο όταν η stage είναι Done
         if (now > (startTime + 10 seconds)) {stage = Stage.Done;}  
    }

    function withdraw() public onlyOwner payable {
        beneficiary.transfer(address(this).balance);
    }

    function reset() internal onlyOwner {
        
       /* delete items; 
         delete bidders;
         delete winners;*/
         
        //επαναφορα stage σε reg
        if(stage == Stage.Done){stage = Stage.Reg; return;} 
        
    }


    function advanceState() public onlyOwner{
        timeNow = now;
        if (timeNow > (startTime /*+  minutes*/)) {
            startTime = timeNow;
                if (stage == Stage.Init) {stage = Stage.Reg; return;}
                if (stage == Stage.Reg) {stage = Stage.Bid; return;}
                if (stage == Stage.Bid) {stage = Stage.Done; return;}
         return;
       }
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

    /*function getPersonDetails(uint id) public view returns(uint,uint,address){
      return (bidders[id].remainingTokens,bidders[id].personId,bidders[id].addr); 
    }*/

}