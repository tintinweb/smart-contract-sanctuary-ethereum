// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract GVG is Ownable {   //address owner = msg.sender;     //Only owner --> pueda ordeñarlo      //Quizas con openzeppelin ya se pueda hacer eso

    //address owner = msg.sender;
    uint256 public idCategory = 0;      //Optimizar uint256     
    uint256 public idTournament = 0;    //Optimizar uint256
    uint256 public idGame = 0;         //Optimizar uint256
    uint256 public idCondition = 0;     //Optimizar uint256
    uint256 public idBet = 0;           //Optimizar uint256

    struct Category {
            bool onOff;
            string name;
            string image;
            string[] tournaments;
    }       mapping(uint256 => Category) public categories;
    
    struct Tournament {
            bool onOff;
            uint256 idCategory;
            string name;
            string pais;
            string image;
            string[] games;
    }       mapping (uint256 => Tournament) public tournaments;
                                                                    //QUIZAS FUERA MAS INTELIGENTE INCLUIR DENTRO DE TOURNAMENTS EL ARRAY DE CONDICIONES
    struct Game {                                                   //CON LA IDEA DE QUE ASI SE APLICASEN ESAS CONDICIONES A TODOS LOS GAMES DEL TORNEO
            bool onOff;
            uint256 idTournament;
            string team1;
            string team2;
            string imageTeam1;
            string imageTeam2;
            string[] condition;
    }       mapping (uint256 => Game) public games;

    struct Condition {          //  PUEDE QUE SE REQUIERA ALGUN CAMPO MAS
            bool onOff;
            uint256 idGame;
            string name;
            string description;
    }       mapping (uint256 => Condition) public conditions;

    struct Bet {
            bool onOff;
            address hero;
            uint256 idCategory;
            uint256 idTournament;
            uint256 idGame;
            uint256 idCondition;
            uint256 deadline;
            uint256 oddsOffer;
            uint256 oddsNeed;
            uint256 amountOffer;
            uint256 amountAviable;    //maxBet - amountCollected = aviable amount for villanos  *Ojo amountAviable / oddsOffer = Max amountVillano
            uint256 amountCollected;    
            uint256 idVillanoBet;
            address[] villanos;             
            uint256[] amountForVillanos;
    }       mapping(uint256 => Bet) public bets;

    //--------------------------------------------------------------------------------------------

    function createCategory (string memory _name, string memory _image) onlyOwner
        public returns (uint256) {
            Category storage category = categories[idCategory];
            
            category.onOff = true;
            category.name = _name;
            category.image = _image;
            //category.tournaments = '';
            idCategory++;
            return idCategory - 1;
        }

    function createTournament (uint256 _idCategory, string memory _name, string memory _pais, string memory _image) onlyOwner
        public returns (uint256) {
            Tournament storage tournament = tournaments[idTournament];
            
            tournament.onOff = true;
            tournament.idCategory = _idCategory;
            tournament.name = _name;
            tournament.pais = _pais;
            tournament.image = _image;
            //tournament.games = '';
            idTournament++;
            return idTournament - 1;
        }

    function createGame (uint256 _idTournament, string memory _team1, string memory _team2, string memory _imageTeam1, string memory _imageTeam2) onlyOwner
        public returns (uint256) {
            Game storage game = games[idGame];
            
            game.onOff = true;
            game.idTournament = _idTournament;
            game.team1 = _team1;
            game.team2 = _team2;            
            game.imageTeam1 = _imageTeam1;
            game.imageTeam2 = _imageTeam2;
            //game.condition = '';
            idGame++;
            return idGame - 1;
        }

    function createCondition (uint256 _idGame, string memory _name, string memory _description) onlyOwner
        public returns (uint256) {
            Condition storage condition = conditions[idCondition];
            
            condition.onOff = true;
            condition.idGame = _idGame;
            condition.name = _name;
            condition.description = _description;
            idCondition++;
            return idCondition - 1;
        }

    function createBet(uint256 _idCategory, uint256 _idTournament, uint256 _idGame, uint256 _idCondition, uint256 _deadline, uint256 _oddsOffer, uint256 _oddsNeed)      
        public payable returns (uint256) {
            uint256 amount = msg.value;
            Bet storage bet = bets[idBet];

            require(bet.deadline < block.timestamp, "The deadline should be a date in the future.");
            
            (bool sent,) = payable(owner()).call{value: amount}("");            
            
            if(sent) {
                bet.onOff = true; 
                bet.hero = msg.sender;
                bet.idCategory = _idCategory;
                bet.idTournament = _idTournament;
                bet.idGame = _idGame;
                bet.idCondition = _idCondition;
                bet.deadline = _deadline;               // _deadline fecha del game tiempo max para aceptar apuestas Esto se controlara atraves de 1 api
                bet.oddsOffer = _oddsOffer;             // variables fijas una vez se crea la bet 
                bet.oddsNeed = _oddsNeed;               // variables fijas una vez se crea la bet 
                bet.amountOffer = amount;
                bet.amountAviable = ((amount * _oddsNeed)/100) - amount;   // si todo esta ok esto equivale al max que podria ganar si se cubre toda la apuesta
                bet.amountCollected = 0;
                bet.idVillanoBet = 0;
                idBet++;
                return idBet - 1;
            }else { return idBet; }
        }


    function addVillano(uint256 _idBet)   // Tras selecionar 1 heroBet, añade un villano 
        
        public payable {
            
            uint256 amount = msg.value;
            Bet storage bet = bets[_idBet];

            require(amount <= bet.amountAviable , "The splitBet should be <= amountAviable.");
            
            (bool sent,) = payable(owner()).call{value: amount}("");      //añadimos la pasta al contrato 
            
            if(sent) { 
                bet.villanos.push(msg.sender);                          //capturamos la wallet del que acepta la apuesta
                bet.amountForVillanos.push(amount);                     //y la cantidad que quiere apostar
                bet.amountCollected = bet.amountCollected + amount;
                bet.amountAviable = bet.amountAviable - amount;
                bet.idVillanoBet++;
            }
        } 


    function getVillanos(uint256 _idVillanoBet)   //Obtener los villanos de una determinada heroBet -- Devuelve array de Villanos junto con el monto de cada 1

        public view returns(address[] memory, uint256[] memory) { return (bets[_idVillanoBet].villanos, bets[_idVillanoBet].amountForVillanos); }


    function getCategories() 
        public view returns (Category[] memory) {
            Category[] memory allCategories = new Category[](idCategory);
        
            for(uint i = 0; i < idCategory; i++) {
              Category storage category = categories[i];
              allCategories[i] = category;
            }
            return allCategories;
        }

    function getTournaments() 
        public view returns (Tournament[] memory) {
            Tournament[] memory allTournaments = new Tournament[](idTournament);
        
            for(uint i = 0; i < idTournament; i++) {
              Tournament storage tournament = tournaments[i];
              allTournaments[i] = tournament;
            }
            return allTournaments;
        }

    function getGames() 
        public view returns (Game[] memory) {
            Game[] memory allGames = new Game[](idGame);
        
            for(uint i = 0; i < idGame; i++) {
              Game storage game = games[i];
              allGames[i] = game;
            }
            return allGames;
        }

    function getConditions() 
        public view returns (Condition[] memory) {
            Condition[] memory allConditions = new Condition[](idCondition);
        
            for(uint i = 0; i < idCondition; i++) {
              Condition storage condition = conditions[i];
              allConditions[i] = condition;
            }
            return allConditions;
        }

    function getBets() 
        public view returns (Bet[] memory) {
            Bet[] memory allBets = new Bet[](idBet);
        
            for(uint i = 0; i < idBet; i++) {
              Bet storage bet = bets[i];
              allBets[i] = bet;
            }
            return allBets;
        }


    // function payToWiner(bool heroWin, Bet storage bet)   // deadline or exception  
        
    //     private {
    //         //address payable winer = bet.hero;
    //         //requiere (condition != cancell)  que no se haya cancelado, en caso de cancel devolver a ambos
        
    //         if (heroWin = true){
    //             address payable winer =  payable(bet.hero);
    //             winer.transfer(bet.amountCollected);
    //         } else{               
    //             for(uint i = 0; i < bet.idVillanoBet; i++) {    //igual se debe utilizar length echar un ojo al pop y al push
    //             address payable winer = payable(bet.villanos[i]);
    //             //bet.villanos[bet.idVillanoBet].pop().push(bet.amountForVillanos[bet.idVillanoBet]); idea original
    //             winer.transfer(((bet.amountForVillanos[i] * bet.oddsOffer)/100)); //lo que esta dentro del push creo que es correcto
    //             }
    //         }
    //     }
}