/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract CardGame {

    string[13] public names=["A", "2", "3", "4", "5", "6", "7", "8", "9","10" ,"J", "Q", "K"];

    uint[13] public namesRank=[13,9,8,7,6,5,4,3,2,1,10,11,12];

    string[4] public suits=[ "Diamonds", "Spades", "Clubs","Hearts"];

    struct Card{
        string suit;
        string name;
        uint rank;
        // address owner;
    }

    Card[] public cards;

    uint  cardCount = 52;
    uint cardHoldingperPerson;
    address[] players;
    

    mapping (address => Card[]) public cardsOf;
    mapping (uint => Card) public cardId;
    mapping (address => uint) public winCount;
    mapping (address => mapping(uint256 => Card) ) public playersCards;
    //mapping (Card => address) public ownerOf;


    // 1. function prepare cards
    function prepareCards() public returns(Card[] memory) { 
        
        Card[] memory c = new Card[](cardCount);
       for(uint i=0;i<cardCount;i++)
       {
           c[i].suit = suits[i/13];
           c[i].name = names[i%13];
           c[i].rank = namesRank[i%13];
           cards.push(Card(c[i].suit, c[i].name, c[i].rank));
           
       }
        return c;
    }


    // 2. shufle cards
    function shuffleCards() public returns(Card[] memory shuffle) {

        uint count= 0;
        shuffle = new Card[](cardCount);
    
        for (uint i = 0; i < cardCount ; i++) {
            count ++;
            uint randId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender ,count))) % cardCount;
            if(randId >= 0 && randId < 52) {
                shuffle[i] = cards[randId];
                cards[randId] = shuffle[i];
                shuffle[randId] = cards[i];
            }
        }

        for (uint i = 0; i < cardCount ; i++) {
            cardId[i] = shuffle[i];
        }
        
        return shuffle;
    }



    // 3. new User
    function joinNewUser(address newUser) public {
        players.push(newUser);
        cardHoldingperPerson = cardCount/players.length;
    } 


    // 4. ditributed card function
    function distributeCard() public {
      
       uint x = 0;

        for(uint i=0; i<players.length; i++) {

            for (uint j=x; j<x+cardHoldingperPerson; j++) {

            playersCards[players[i]][j] = cardId[j];
            //cardsOf[players[i]].push(cardId[j]);

            }
             x = x + cardHoldingperPerson;

        }

    }

 //Card[] cc = new Card[](players.length);
    // 5. Start Game
    function startGame() public{
       
       
        uint gamePoint = 0;
        //uint min = 0;
        
        for (uint i = 0; i<cardHoldingperPerson; i++) {
            
            for (uint j = 0; j < players.length - 1; j++){
                
                 Card memory c1 = playersCards[players[j]][i];
                 Card memory c2 = playersCards[players[j+1]][i];

                 if(c1.rank < c2.rank){
                    gamePoint = gamePoint + 1;
                    winCount[players[j]] = gamePoint;
                   // min = c1.rank;
                 }else { //if(c2.rank <= min)
                    gamePoint = gamePoint + 1;
                    winCount[players[j+1]] = gamePoint;
                 }
                 
            }

        }

    }



}