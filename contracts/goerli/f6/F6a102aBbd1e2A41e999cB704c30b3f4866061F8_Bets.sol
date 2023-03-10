/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// File: contracts/Bets.sol

/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

//SPDX-License-Identifier: UNLICENSED

//CHALLENGE APUESTAS CON TOKEN ERC20:
//- hacer contrato mocktoken que mintee al msg sender 100 tokens y tenga una funcion publica que mintee 100 tokens a quien la llama
//- implementar en el contrato de apuestas la lógica necesaria para permitir apuestas con token ERC20
//- declarar interfaz IERC20
//- declarar variable del contrato del token que utilizaremos y setear en el constructor
//- implementar lógica en las funciones necesarias para transferir y enviar tokens desde el contrato 
//- testear y comprobar que funciona

pragma solidity 0.8.18;

struct Game {
    uint256[2] bet;
    uint256 finish_timestamp;
    uint8 winner; //0, 1, 2
}

interface IMock{
    function transfer(address to, uint256 amount) external returns (bool);
    //function transfer (address to, uint256 amount) external view returns (bool exito);
    //function approve(address spender, address amount)external view returns (bool exito);
    //function transferFrom(address from, address to, uint256 amount) external view returns (bool exito);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract Bets {
    Game[] public games;
    mapping(uint256 => mapping(address => uint256[2])) public userBets; //gameId => wallet => bet
    address public owner;
    //Esta direccion es donde se ha deployeado el contrato mockTokenERC20
    IMock private mockaddress;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isRegistered;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not admin");
        _;
    }

    modifier betExists(uint256 id){
        require(id < games.length, "that bet does not exist");
        _;
    }

    function _hasFinished(uint256 gameId) private view returns(bool) {
        if (block.timestamp >= games[gameId].finish_timestamp)
            return true;
        return false;
    }

    modifier hasFinished(uint256 gameId) {
        require(_hasFinished(gameId) == true, "Bet has not finished");
        _;
    }

    constructor(IMock direccionmock) {
        owner = tx.origin;
        isAdmin[msg.sender] = true;
        mockaddress= direccionmock;
    }

    function addAdmin(address wallet) public onlyOwner {
        require(isAdmin[wallet] == false, "Already admin");
        isAdmin[wallet] = true;
    }

    function removeAdmin(address wallet) public onlyOwner {
        require(isAdmin[wallet] == true, "Not admin");
        require(wallet != msg.sender, "Cannot remove yourself");
        isAdmin[wallet] = false;
    }

    function transferOwnership(address wallet) public onlyOwner {
        require(wallet != address(0), "Cannot transfer ownership to null");
        owner = wallet;
    }

    function createGame(uint256 h, uint256 m, uint256 s) public onlyOwner {
        Game memory game;
        game.finish_timestamp = block.timestamp + h * 1 hours + m * 1 minutes + s * 1 seconds;
        games.push(game);
    }

    function setWinner(uint256 gameId, uint8 option) public onlyAdmin hasFinished(gameId) {
        Game storage game = games[gameId];
        require(0 < option && option < 3, "Invalid option");
        game.winner = option;
    }

    function bet(uint256 gameId, uint256 betamount,uint8 option) public betExists(gameId) {
        //require(_hasFinished(gameId) == false, "Bet has finished");
        require(0 < option && option < 3, "Invalid option");
        mockaddress.transferFrom(msg.sender, address(this), betamount);
        userBets[gameId][msg.sender][option - 1] += betamount;
        games[gameId].bet[option - 1] += betamount;
    }

    function claimReward(uint256 gameId) public hasFinished(gameId) {
        Game storage game = games[gameId];

        uint8 winnerId = game.winner - 1;
        uint256 bettedAmount = userBets[gameId][msg.sender][winnerId];
        uint256 totalAmount = game.bet[0] + game.bet[1];

        uint256 owedAmount = totalAmount * bettedAmount / game.bet[winnerId];
        require(owedAmount > 0, "Nothing is owned to you");

        //Antigua logica con token nativo
        //(bool successOwner, ) = owner.call{value: owedAmount / 10}("");
        //(bool successUser, ) = msg.sender.call{value: (owedAmount * 90) / 100}("");
        (bool successUser) = IMock(mockaddress).transfer(msg.sender, (owedAmount *90)/100);
        require(successUser == true, "Transaction failed");

        // Actualizamos el valor de la apuesta a 0
        userBets[gameId][msg.sender][winnerId] = 0;
    }

    receive() external payable {}
}