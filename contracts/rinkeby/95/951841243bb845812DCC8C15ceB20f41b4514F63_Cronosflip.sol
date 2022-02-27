/**
 * CoinFlip
 *
 * Juego de casino para apostar a cara o cruz. Se usa el timestamp del bloque de la blockchain
 * para simular un número random entre 0 y 1. Si el timestamp del bloque es un número par el
 * usuario gana el 190% del dinero invertido, si es un número impar pierde los ethers jugados.
 *
 * Al desplegar el contrato es necesario transferirle fondos para que pueda pagar el premio si
 * el usuario gana.
 *
 * Versión modificada para interfaz web
 *
 **/

pragma solidity ^0.8.0;

contract Cronosflip {
    address owner;
    uint256 payPercentage = 90;
    uint256 public MaxAmountToBet = 200000000000000000000; // = 0.2 Ether

    struct Game {
        address addr;
        uint256 blocknumber;
        uint256 blocktimestamp;
        uint256 bet;
        uint256 prize;
        bool winner;
    }

    Game[] lastPlayedGames;

    Game newGame;

    event Status(string _msg, address user, uint256 amount, bool winner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert();
        } else {
            _;
        }
    }

    function Play() public payable {
        if (msg.value > MaxAmountToBet) {
            revert();
        } else {
            if ((block.timestamp % 2) == 0) {
                if (
                    address(this).balance <
                    (msg.value * ((100 + payPercentage) / 100))
                ) {
                    payable(msg.sender).transfer(address(this).balance);
                    // No tenemos suficientes fondos para pagar el premio, así que transferimos todo lo que tenemos
                    emit Status(
                        "Congratulations, you win! Sorry, we didn't have enought money, we will deposit everything we have!",
                        msg.sender,
                        msg.value,
                        true
                    );

                    newGame = Game({
                        addr: msg.sender,
                        blocknumber: block.number,
                        blocktimestamp: block.timestamp,
                        bet: msg.value,
                        prize: address(this).balance,
                        winner: true
                    });
                    lastPlayedGames.push(newGame);
                } else {
                    uint256 _prize = (msg.value * (100 + payPercentage)) / 100;
                    emit Status(
                        "Congratulations, you win!",
                        msg.sender,
                        _prize,
                        true
                    );
                    payable(msg.sender).transfer(_prize);

                    newGame = Game({
                        addr: msg.sender,
                        blocknumber: block.number,
                        blocktimestamp: block.timestamp,
                        bet: msg.value,
                        prize: _prize,
                        winner: true
                    });
                    lastPlayedGames.push(newGame);
                }
            } else {
                emit Status("Sorry, you loose!", msg.sender, msg.value, false);

                newGame = Game({
                    addr: msg.sender,
                    blocknumber: block.number,
                    blocktimestamp: block.timestamp,
                    bet: msg.value,
                    prize: 0,
                    winner: false
                });
                lastPlayedGames.push(newGame);
            }
        }
    }

    function getGameCount() public returns (uint256) {
        return lastPlayedGames.length;
    }

    function getGameEntry(uint256 index)
        public
        returns (
            address addr,
            uint256 blocknumber,
            uint256 blocktimestamp,
            uint256 bet,
            uint256 prize,
            bool winner
        )
    {
        return (
            lastPlayedGames[index].addr,
            lastPlayedGames[index].blocknumber,
            lastPlayedGames[index].blocktimestamp,
            lastPlayedGames[index].bet,
            lastPlayedGames[index].prize,
            lastPlayedGames[index].winner
        );
    }

    function depositFunds(uint256 amount) public payable onlyOwner {
        if (payable(owner).send(amount)) {
            emit Status(
                "User has deposit some money!",
                msg.sender,
                msg.value,
                true
            );
        }
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        if (payable(owner).send(amount)) {
            emit Status("User withdraw some money!", msg.sender, amount, true);
        }
    }

    function setMaxAmountToBet(uint256 amount)
        public
        onlyOwner
        returns (uint256)
    {
        MaxAmountToBet = amount;
        return MaxAmountToBet;
    }

    function getMaxAmountToBet(uint256 amount) public returns (uint256) {
        return MaxAmountToBet;
    }

    function Kill() public onlyOwner {
        emit Status(
            "Contract was killed, contract balance will be send to the owner!",
            msg.sender,
            address(this).balance,
            true
        );
        selfdestruct(payable(owner));
    }
}