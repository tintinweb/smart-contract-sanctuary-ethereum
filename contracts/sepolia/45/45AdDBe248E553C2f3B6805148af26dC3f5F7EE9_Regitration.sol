/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


error DB_ERROR();


contract Regitration {
    address[] public funders;

    address[] public Verif;


    address my_address = 0x113F3979D7774147D39AB7E097D23b6E5D567D39;

    // function push(i) payable {
    //     constructor() public {
    //         Verif.push(i);
    //     }
    // }

    function Verification() public payable {
       if (msg.sender != my_address) {
        revert DB_ERROR();
       } else {
        funders.push(msg.sender);
       }
    }

    // Функция для добавление адресса в массив Verif
    // Сделать кастомную ошибку если адреса нету в массиве Verif
    // Выаодить на фронтенд кастомную ошибку 
    // Сделать триггер если аднес не зареган для переноса на страницу ввода рефки
    // Если зареган то на главную 
}