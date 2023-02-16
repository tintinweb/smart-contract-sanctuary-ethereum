// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract GVG {
    
    address owner = msg.sender;     //Ojo toca revisar como hacer que solo el que lanza el contrato pueda ordeñarlo

    //--------------------------------------------------------------------------------------------

    // struct BetAviable {
    //     string game;
    //     string condition;
    //     string image;
    //     uint256 deadline;
    //     bool activa;    //Creo que sera necesario una var de este tipo para determinados controles     
    // }
    // mapping(uint256 => BetAviable) public betsAviable;
    
    // uint256 public idBetAviable = 0;    //idBet

    //--------------------------------------------------------------------------------------------

    struct Bet {
        address hero;
        string game;
        string condition;
        uint256 amountOffer;
        uint256 amountAviable;    //maxBet - amountCollected = aviable amount for villanos  *Ojo amountAviable / oddsOffer = Max amountVillano
        uint256 amountCollected;    
        uint256 oddsOffer;
        uint256 oddsNeed;
        string image;
        uint256 deadline;
        address[] villanos;
        uint256[] amountForVillanos;
        bool activa;    //Creo que sera necesario una var de este tipo para determinados controles     
    }
    mapping(uint256 => Bet) public bets;
    
    uint256 public idHeroBet = 0;    //idBet
    
    //--------------------------------------------------------------------------------------------
    
    function createHeroBet(string memory _game, string memory _condition, 
    uint256 _amountOffer, uint256 _deadline, uint256 _oddsOffer, uint256 _oddsNeed, string memory _image)   

        public payable returns (uint256) {    
            uint256 amount = msg.value;
            Bet storage bet = bets[idHeroBet];

            require(bet.deadline < block.timestamp, "The deadline should be a date in the future.");  // aqui deadline siempre sera = 0. --> Esto sobra
            
            (bool sent,) = payable(owner).call{value: amount}("");            
            if(sent) { 
                bet.hero = msg.sender;
                bet.amountOffer =  amount;
                bet.game = _game;
                bet.condition = _condition;
                bet.deadline = _deadline;               // _deadline fecha del game tiempo max para aceptar apuestas Esto se controlara atraves de 1 api
                bet.amountOffer = _amountOffer;
                bet.amountAviable = _amountOffer;
                bet.oddsOffer = _oddsOffer;             // variables fijas una vez se crea la bet 
                bet.oddsNeed = _oddsNeed;               // variables fijas una vez se crea la bet 
                bet.amountCollected = 0;
                bet.image = _image;
                bet.activa = true;
                idHeroBet++;
                return idHeroBet - 1;
            }else { return idHeroBet; }
        }

    function addVillano(uint256 _id)   // Tras selecionar 1 heroBet, añade un villano
        public payable {
            uint256 amount = msg.value;
            Bet storage bet = bets[_id];
            uint256 splitBet = (bet.oddsOffer*amount)-amount;

            if (splitBet <= bet.amountAviable) {  //Este if tiene en cuenta las Odds para comprobar el monto aviable
                (bool sent,) = payable(owner).call{value: amount}("");      //añadimos la pasta al contrato 
                if(sent) { 
                    bet.villanos.push(msg.sender);                          //capturamos la wallet del que acepta la apuesta
                    bet.amountForVillanos.push(amount);                     //y la cantidad que quiere apostar
                    bet.amountCollected = bet.amountCollected + amount;
                    bet.amountAviable = bet.amountAviable - splitBet;
                }
            }
        } 

    function getVillanos(uint256 _id)   //Obtener los villanos de una determinada heroBet -- Devuelve array de Villanos junto con el monto de cada 1
        view public returns(address[] memory, uint256[] memory) {
            return (bets[_id].villanos, bets[_id].amountForVillanos); 
        }
    function getBets() public view returns (Bet[] memory) {
        Bet[] memory allBets = new Bet[](idHeroBet);
        
        for(uint i = 0; i < idHeroBet; i++) {
            Bet storage bet = bets[i];
            allBets[i] = bet;
        }
        return allBets;
    }
}