/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Voting {            // начало контракта
    struct Voter{                // структура "голосующий"
        bool voted;              // проголосовать
        uint vote; // за кого голосует
    }

    struct Condidate{               // структура "кондидат"
        string name;                // имя кондидата
        uint voteCount;             // счетчик голосов
    } 

    mapping (address => Voter) public voters;          // адрес голосующего публичный и он заносится в "голосующие"

    Condidate [] public condidates;                    // создание массива (публичный) заносится в "кондидаты"
    constructor (string [] memory NameCondidates){       // конструктор создания самого процесса голосования (список кондидатов)
        for (uint i = 0; i < NameCondidates.length; i++){       // ввод индекса
            condidates.push(Condidate({               // добавления кондидата (-ов)
                name: NameCondidates[i],              // привязка индека к имени кондидата
                voteCount: 0                            // изначальный счетчик голосов
            }));
        }
    }

    function voted (uint index) public{                // ввод переменной "индекс" и проверка голосов
       Voter storage sender = voters[msg.sender];      // sender = {voted: false, vote: 0} 
       require (sender.voted == false, "error");       // если этот адрес голосовал, то система выдает ошибку
       sender.voted = true;                            // если адрес голосовал, то "true"
       sender.vote = index;                            // отданный голос записывается в в переменную index
       condidates[index].voteCount++;                  // просмотр индекса кондидата и увеличение счетчика
    }
// sender.voted
    
}