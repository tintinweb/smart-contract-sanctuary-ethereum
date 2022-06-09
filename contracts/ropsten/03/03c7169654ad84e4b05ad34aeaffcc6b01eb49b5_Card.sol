/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Card{
    string[13] public Ranks =["Ace","2","3","4","5","6","7","8","9","10","Jack","Queen","King"];
    uint[13] public Powers = [13,1,2,3,4,5,6,7,8,9,10,11,12];
    string[4] public suits = ["Diamonds","Spades","Clubs","Hearts"];
    string[] public decksss;
    uint deckcount = 52;
    uint currentcard = 0;
    uint winningPoints = 0;
    address[] public ContractAddress = [0x8d8A049C42c907A823cAa0B687D3C5Da57E38b18,0x8d8A049C42c907A823cAa0B687D3C5Da57E38b18,0xe1e4F5074ac7c1Bf68145D5B40704d1d3aF75a28];
    uint public cardHoldingsPerPlayer = 0;
    struct Cards {
         string Suit;
         string Rank;
        uint Power;
    }
    Cards[] public deck;
    mapping(string => string[]) public cardsCreation;
    mapping(uint => Cards) public currentCard;
    mapping(uint => Cards) public shuffledCard;
    mapping(address => Cards[]) public ownerOf;
    mapping(address => mapping(uint256=>Cards)) public ownerOfCards;
    mapping(address => uint) public winpoint;
    constructor() 
    {
       
    }

    function preparedeck() public returns (Cards[] memory)
    {
       Cards[] memory c = new Cards[](deckcount);
       for(uint i=0;i<deckcount;i++)
       {
           c[i].Suit = suits[i/13];
           c[i].Rank = Ranks[i%13];
           c[i].Power = Powers[i%13];

           deck.push(Cards(c[i].Suit,c[i].Rank,c[i].Power));
       }
        
       for(uint i=0;i<deckcount;i++)
       {
           currentCard[i] = c[i];
       }
       return c;
        
    }

    function shufflecards() public returns(Cards[] memory shufflecard)
    {
        uint nonce =0;
        shufflecard = new Cards[](deckcount);
       for(uint i=0;i<deckcount;i++)
       {
           nonce++;
           uint index = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,nonce))) % deckcount;
           if(index >0 && index <52)
           {

        shufflecard[i] = deck[index];
        deck[index] = shufflecard[i];
        shufflecard[i] = deck[index];
           }
       }

       for(uint i =0;i<deckcount;i++)
       {
           shuffledCard[i] = shufflecard[i];
       }
    

       return shufflecard;
    }


    function joinnewUser(address Address) public returns (uint){
        ContractAddress.push(Address);
        cardHoldingsPerPlayer = deckcount/ContractAddress.length;
        return ContractAddress.length;
    }

    function distributeCard() public 
    {
        uint x =0;
       for(uint i =0;i<ContractAddress.length;i++)
       {
           for(uint j =x;j<x+cardHoldingsPerPlayer;j++)
           {
               ownerOfCards[ContractAddress[i]][j] = shuffledCard[j];
               ownerOf[ContractAddress[i]].push(shuffledCard[j]);
           }
           x=x+cardHoldingsPerPlayer;
       }
    }


//This is done without the nested mapping
    function startgame() public {
        uint x=0;
        uint max2 = 0;
        for(uint i=0;i<ContractAddress.length;i++)
        {
            for(uint j=x;j<x+cardHoldingsPerPlayer;j++)
            {
                Cards[] memory c = ownerOf[ContractAddress[i]];
                if(c[i].Power > c[i+1].Power)
                {
                    winpoint[ContractAddress[i]] = winningPoints +1;
                    max2 = c[i].Power;
                }
                else if(c[i].Power > max2)
                {
                    winpoint[ContractAddress[i]] = winningPoints +1;
                }
            }
            x=x+cardHoldingsPerPlayer;
        }
    }
//This is done without the nested mapping
// Its not working
    function startgamenested() public {
        uint x=0;
        uint max2 = 0;
        for(uint i=0;i<ContractAddress.length;i++)
        {
            for(uint j=x;j<x+cardHoldingsPerPlayer;j++)
            {
                Cards memory c = ownerOf[ContractAddress[i]][j];
                Cards memory c1 = ownerOfCards[ContractAddress[i+1]][j];
                if(c.Power > c1.Power)
                {
                    winpoint[ContractAddress[i]] = winningPoints +1;
                    max2 = c.Power;
                }
                else if(c.Power > max2)
                {
                    winpoint[ContractAddress[i]] = winningPoints +1;
                }
            }
            x=x+cardHoldingsPerPlayer;
        }
    }



 




   

    




}