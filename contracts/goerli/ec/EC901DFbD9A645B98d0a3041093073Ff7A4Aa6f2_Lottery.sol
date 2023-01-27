/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

contract Lottery {
    address payable[] public players;
    address public manager;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    //FUNZIONE STANDARD CHE ABILITA I PAGAMENTI VERSO IL CONTRATTO
    function buyTicket() external payable {
        //SETTO IL PREZZO DEL BIGLIETTO A 0.1 ETH
        require(msg.value == 0.1 ether);
        //PUSHA L'ADDRESS CHE INVIA ETH NELL'ARRAY PLAYER
        players.push(payable(msg.sender));
    }

    //RITORNA IL NUMERO DI GIOCATORI
    function getPlayers() public view returns (uint) {
        return players.length;
    }

    //RITORNA IL BILANCIO DEL CONTRATTO
    function getBalance() public view returns (uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    //GENERA UN GRANDE NUMERO CASUALE PER SCEGLIERE IL VINCITORE
    function random() public view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    //SCEGLIE IL VINCITORE TRAMITE IL NUMERO RANDOM E TRASFERISCE IL BILANCIO AL VINCITORE
    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);
        random();
        uint r = random();

        uint i = r % players.length;
        winner = players[i];

        uint managerFee = (getBalance() * 10) / 100;
        uint winnerPrize = (getBalance() * 90) / 100;

        winner.transfer(winnerPrize);
        payable(manager).transfer(managerFee);

        players = new address payable[](0); //RESET THE LOTTERY
    }
}