/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



contract cardsGame {

string[13] public names=["A", "2", "3", "4", "5", "6", "7", "8", "9","10" ,"J", "Q", "K"];

uint[13] public namesRank=[13,1,2,3,4,5,6,7,8,9,10,11,12];

string[4] public suits=[ "Diamonds", "Spades", "Clubs","Hearts"];

// uint MAX_PLAYER=10;
uint numberOfCards=52;
 
 struct Cards {
    string name;
    uint rank;
    string suit;
    //address _user;
 }

Cards[] public deck;

//  Global Variables
address[] public totalUsers;
uint numberOfUsers=0; //Number of users
uint cardHoldingsPerPlayer=0; //Number of cards a user has
uint winningPoints=0;


//  Mappings
mapping (uint => Cards) public cardMap;          // Index to Cards Struct (Prepare Cards Mapping)
mapping (uint => Cards) public shuffledMap;      // Index to Cards Struct (Shuffle Cards Mapping)
mapping (address => Cards[]) public ownerOf;     // Number of Shuffled Cards of any Player
// WINNING POINT MAPPING
mapping (address => uint) public winpoint;       // Win count of some user (address)

// NESTED MAPPING
mapping(address => mapping(uint256=>Cards)) public ownerOfCards;
mapping(address => uint) public winpoints;

   constructor(){

    }

//==== FUNCTIONS ====

//1
function prepareCards()public  returns(Cards[] memory){

    Cards[] memory Deckk = new Cards[](numberOfCards);  
    for(uint i=0; i<numberOfCards; i++){

        Deckk[i].name= names[i%13];      // Repeat after every 13th index
        Deckk[i].suit= suits[i/13];      // Same suit for every 13 cards
        Deckk[i].rank= namesRank[i%13];  // Repeat after every 13th index
        deck.push(Cards(Deckk[i].name,Deckk[i].rank,Deckk[i].suit)); // Saving the prepared cards in STRUCT Cards (Storage)
    }

   // MAPPING (CARDMAP)
   for(uint i=0; i<numberOfCards; i++){
       cardMap[i]=Deckk[i];
   }
     return Deckk;
}



// 2

 function shufflecards() public returns(Cards[] memory shufflecard)
    {
        uint nonce =0;
        shufflecard = new Cards[](numberOfCards);
       for(uint i=0;i<numberOfCards;i++)
       {
           nonce++;
           uint index = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,nonce))) % numberOfCards;
           if(index >0 && index <52)
           {

        shufflecard[i] = deck[index];
        deck[index] = shufflecard[i];
        shufflecard[i] = deck[index];


           }
       }

   //  MAPPING (SHUFFLED MAP)
       for(uint i =0;i<numberOfCards;i++)
       {
           shuffledMap[i] = shufflecard[i];
       }

       return shufflecard;
    }


// 3

function joinNewUser(address user) public returns (uint) {
totalUsers.push(user); // adding addresses to TotalUsers array
cardHoldingsPerPlayer =numberOfCards/ totalUsers.length; 
return totalUsers.length;

}
// numberOfUsers++;

//If we want to separate the extra card 
// uint x =numberOfCards % numberOfUsers; 
// cardHoldingsPerPlayer= (numberOfCards-x)/numberOfUsers;


// 4
 function distributeCard() public 
    {
        uint x =0;
       for(uint i =0;i<totalUsers.length;i++)
       {
           for(uint j =x;j<x+cardHoldingsPerPlayer;j++)
           {
               ownerOf[totalUsers[i]].push(shuffledMap[j]);
           }
           x=x+cardHoldingsPerPlayer;
       }
    }


// 5
    function startgame() external {
        uint x=0;
        uint max2 = 0;
        for(uint i=0;i<totalUsers.length;i++)
        {
            for(uint j=x;j<x+cardHoldingsPerPlayer;j++)
            {
                Cards[] memory c = ownerOf[totalUsers[i]];
                if(c[i].rank > c[i+1].rank)
                {
                    winningPoints = winningPoints+1;
                    winpoint[totalUsers[i]] = winningPoints;
                    max2 = c[i].rank;
                }
                else if(c[i].rank > max2)
                {
                     winningPoints = winningPoints+1;
                    winpoint[totalUsers[i]] = winningPoints +1;
                }
            }
            x=x+cardHoldingsPerPlayer;
        }
    }
 


//  function startGameXX() public{
       
       
//         uint gamePoint = 0;
//         uint gamePoint2 = 0;
//         uint gamePoint3 = 0;
//         uint temp = 0;
        
//         for (uint i = 0; i<cardHoldingsPerPlayer; i++) {
            
//             for (uint j = 0; j < totalUsers.length - 1; j++){
                
//                  Cards memory c1 = ownerOfCards[totalUsers[j]][i];
//                  Cards memory c2 = ownerOfCards[totalUsers[j+1]][i];
//                  Cards memory c3 = ownerOfCards[totalUsers[j+2]][i];


//                  if(c1.rank > c2.rank && c1.rank > c3.rank){
//                     gamePoint = gamePoint + 1;
//                     winpoint[totalUsers[j]] = gamePoint;
//                     temp = c1.rank;
//                  }
//                  else if(c2.rank > c1.rank && c2.rank >c3.rank) {
//                     gamePoint2 = gamePoint2 + 1;
//                     winpoint[totalUsers[j+1]] = gamePoint2;
//                  }
//                  else if(c3.rank > c1.rank && c3.rank >c2.rank) {
//                     gamePoint3 = gamePoint3 + 1;
//                     winpoint[totalUsers[j+2]] = gamePoint3;
//                  }    
//             }
//         }
//     }


// NOT WORKING
 function startgamenested() public {
        uint max2 = 0;
        for(uint j=0;j<cardHoldingsPerPlayer;j++)
        {
            for(uint i=0;i<totalUsers.length-1;i++)
            {
                Cards memory c1 = ownerOfCards[totalUsers[i]][j];
                Cards memory c2 = ownerOfCards[totalUsers[i+1]][j];

                if(c1.rank > c2.rank)
                {
                    winningPoints = winningPoints +1;
                    winpoints[totalUsers[i]] = winningPoints;
                    max2 = c1.rank;
                }
                else if(c1.rank > max2)
                {
                    winningPoints = winningPoints +1;
                    winpoints[totalUsers[i]] = winningPoints;
                }
            }
        }
    }
}