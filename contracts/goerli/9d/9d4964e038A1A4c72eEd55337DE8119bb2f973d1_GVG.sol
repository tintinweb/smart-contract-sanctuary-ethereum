// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract GVG {
    
    address owner = msg.sender;     //Only owner --> pueda ordeñarlo

    struct Bet {
        address hero;
        string game;
        string condition;
        uint256 deadline;
        uint256 oddsOffer;
        uint256 oddsNeed;
        uint256 amountOffer;
        uint256 amountAviable;    //maxBet - amountCollected = aviable amount for villanos  *Ojo amountAviable / oddsOffer = Max amountVillano
        uint256 amountCollected;    
        //string image;
        uint256 idVillanoBet;
        address[] villanos;             //controlar el numero de villanos 
        uint256[] amountForVillanos;
        bool activa;    //Creo que sera necesario una var de este tipo para determinados controles     
    }
    mapping(uint256 => Bet) public bets;
    
    uint256 public idHeroBet = 0;    //idBet
    
    //--------------------------------------------------------------------------------------------
    
    function createBet(string memory _game, string memory _condition, uint256 _deadline, uint256 _oddsOffer, uint256 _oddsNeed /*string memory _image*/)      
        
        public payable returns (uint256) {    
            uint256 amount = msg.value;
            Bet storage bet = bets[idHeroBet];

            require(bet.deadline < block.timestamp, "The deadline should be a date in the future.");
            
            (bool sent,) = payable(owner).call{value: amount}("");            
            if(sent) { 
                bet.hero = msg.sender;
                bet.game = _game;
                bet.condition = _condition;
                bet.deadline = _deadline;               // _deadline fecha del game tiempo max para aceptar apuestas Esto se controlara atraves de 1 api
                bet.oddsOffer = _oddsOffer;             // variables fijas una vez se crea la bet 
                bet.oddsNeed = _oddsNeed;               // variables fijas una vez se crea la bet 
                bet.amountOffer = amount;
                bet.amountAviable = ((amount * _oddsNeed)/100) - amount;   // si todo esta ok esto equivale al max que podria ganar si se cubre toda la apuesta
                bet.amountCollected = 0;
                //bet.image = _image;
                bet.idVillanoBet = 0;
                bet.activa = true;
                idHeroBet++;
                return idHeroBet - 1;
            }else { return idHeroBet; }
        }

    function addVillano(uint256 _id)   // Tras selecionar 1 heroBet, añade un villano 
        public payable {
            uint256 amount = msg.value;
            Bet storage bet = bets[_id];

            require(amount <= bet.amountAviable , "The splitBet should be <= amountAviable.");
            
                (bool sent,) = payable(owner).call{value: amount}("");      //añadimos la pasta al contrato 
                if(sent) { 
                    bet.villanos.push(msg.sender);                          //capturamos la wallet del que acepta la apuesta
                    bet.amountForVillanos.push(amount);                     //y la cantidad que quiere apostar
                    bet.amountCollected = bet.amountCollected + amount;
                    bet.amountAviable = bet.amountAviable - amount;
                    bet.idVillanoBet++;
                }
        } 

    function getVillanos(uint256 _id)   //Obtener los villanos de una determinada heroBet -- Devuelve array de Villanos junto con el monto de cada 1
        view public returns(address[] memory, uint256[] memory) {
            return (bets[_id].villanos, bets[_id].amountForVillanos); 
        }
    function getBets() 
        public view returns (Bet[] memory) {
        Bet[] memory allBets = new Bet[](idHeroBet);
        
        for(uint i = 0; i < idHeroBet; i++) {
            Bet storage bet = bets[i];
            allBets[i] = bet;
        }
        return allBets;
        }
    function payToWiner(bool heroWin, Bet storage bet)   // deadline or exception  
        private {
            //address payable winer = bet.hero;
            //requiere (condition != cancell)  que no se haya cancelado, en caso de cancel devolver a ambos
        
            if (heroWin = true){
                address payable winer =  payable(bet.hero);
                winer.transfer(bet.amountCollected);
            } else{               
                for(uint i = 0; i < bet.idVillanoBet; i++) {    //igual se debe utilizar length echar un ojo al pop y al push
                address payable winer = payable(bet.villanos[i]);
                //bet.villanos[bet.idVillanoBet].pop().push(bet.amountForVillanos[bet.idVillanoBet]); idea original
                winer.transfer(((bet.amountForVillanos[i] * bet.oddsOffer)/100)); //lo que esta dentro del push creo que es correcto
                }
            }
        }
}