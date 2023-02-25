//Smartcontract en Solidity
pragma solidity ^0.5.1;
// Pseudo codigo:
// el juego se puede parar con la funcion StatusGame
// con fundContract se mete pasta en la bolsa
//flow del contrato:
// primer juego, se comprueba si la apuesta es mayor que 1 ether. Si es así se guarda este nuevo precio de apuesta. 
// si no toca, los siguientes jugadores que quieran probar, deben pagar más que lo que pago el ultimo usuario ( cada vez el precio sera mas alto)
// check random: genera un numero random del de 0 a 99999. si toca el 0, el usuario gana. 
// si toca, el jugador recivira el precio total menos el 1% de los fees, que pueden ser extraidos por el owner del contrato.
//hay una variable StatusGame que bloquea o inicia el juego/contato

// se esta usando 0.5.1 por los loles, con 0.8.0 se arreglarian problemas de posibles overflows (ojala $$), solo habria que cambiar dos tonterias, como el payable, etc. 
//yo mejoraria la cosa con un randomness de oraculo. y mas florituras,

contract PumpAndBox {
    address payable public owner;
    uint256 public totalPrize;
    uint256 public minimumBet;
    uint public random;
    uint256 fees;
    bool public gameStarted = false;

    //Constructor
    constructor() public {
        owner = msg.sender;
        minimumBet = 1 ether;
        fees = totalPrize * 1 / 100;
    }

    //Permite al owner fundear el smart contract
    function fundContract (uint256 _totalAmount) public {
        require (msg.sender == owner, "Only the owner can fund the contract!");
        totalPrize = _totalAmount;
        gameStarted = true;
    }
     function StatusGame(bool Start) public {
        require (msg.sender == owner, "Only the owner can start game");
        gameStarted = Start;
     }

    //Permite a los usuarios apostar
    function bet() payable public {
        require(gameStarted == true, "The game has not started yet!");
        require(msg.value >= minimumBet, "Minimum bet is enforced!");

        //Genera un numero random de 0 a 9999, si se consigue el 0, se gana.
        random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number))) % 10000;
        if (random == 0) {
            //Send the prize
            uint256 fees = totalPrize * 1 / 100;
            uint256 finalprice = totalPrize - fees;
            msg.sender.transfer(finalprice);
            totalPrize = 0;
            gameStarted = false;
        } else {
            //Increase the prize
            totalPrize += msg.value;
            minimumBet = msg.value;
        }
    }
    //Permite al owner retirar los fees
    function withdrawFees() public {
        require (msg.sender == owner, "Only the owner can withdraw the fees!");
        // esta via es para que el usuario este seguro que el owner no va hacer rugpll de todo, solo los fees
        uint256 fees = totalPrize * 1 / 100;
        owner.transfer(fees);
        //habria que chekear que no es cero el balance, etc para que no rompa.
        totalPrize -= fees;
    }
}