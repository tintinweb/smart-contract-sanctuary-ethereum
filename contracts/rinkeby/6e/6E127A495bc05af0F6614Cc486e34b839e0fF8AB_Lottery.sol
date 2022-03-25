/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address[] public players;
    string public _name;
    uint public _blockStart;
    uint public _pretBilet;
    bool public _semafor;

    

    constructor()  {
        manager = msg.sender;
    }

    function creazaTombola(string calldata name, uint blockStart, uint pretBilet) public restrictie {
        require(blockStart > block.number);
        _name = name;
        _blockStart = blockStart;
        _pretBilet = pretBilet;
        _semafor = true; //stam la semafor
        

        players = new address[](0); //resetam loteria
    }

    function enter() public payable {
        require(_semafor);
        require(msg.value > _pretBilet); //banii de intrare

        players.push(msg.sender); //adaugare la lista de participanti a platitorului
    }

    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))); //un fel de rng
    }

    function pickFirstWinner(uint amount) private returns (uint) {  //aici intra modifierul 
        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        winner.transfer(amount); //da banii din contract primului castigatorului
        return index;
    }

    function pickSecondtWinner(uint ignoreIndex, uint amount) private {  //aici intra modifierul 
        uint index = random() % (players.length-1);
        if (index >= ignoreIndex) {
            index=index+1;
        }
        address payable winner = payable(players[index]);
        winner.transfer(amount);
    }

    function finalizeazaTombola() public restrictie{
        require(_semafor);
        uint firstWinnerAmount = address(this).balance*7/10;
        uint secondWinnerAmount = address(this).balance*25/100;
        uint firstWinner = pickFirstWinner(firstWinnerAmount);
        pickSecondtWinner(firstWinner, secondWinnerAmount);
        payable(manager).transfer(address(this).balance);

        _semafor = false;

     //   players = new address[](0); //resetam loteria
    }



    modifier restrictie() { //modifieru ne ajuta sa duplicam logica din functii
         require(msg.sender == manager); //doar managerul contr poate alege un castigator
         _;    // in locul underscorului apare functia care foloseste modifierul

    }

    function getPlayers() public view returns(address[] memory) {
        return players;
    }
}