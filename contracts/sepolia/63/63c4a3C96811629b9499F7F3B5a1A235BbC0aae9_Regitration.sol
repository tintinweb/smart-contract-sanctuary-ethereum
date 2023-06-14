/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


error DB_ERROR();
error REF_ERROR();


contract Regitration {
    address[] public addressVefication;

    // address[] public Verif;
    // string[] public Ref;



    address my_address = 0x113F3979D7774147D39AB7E097D23b6E5D567D39;

    // function push(i) payable {
    //     constructor() public {
    //         Verif.push(i);
    //     }
    // }

    function addresVerification() public payable returns(uint256) {
       if (msg.sender != my_address) {
        return(1);
       } else {
        addressVefication.push(msg.sender);
        return(2);
       }
    }



    // Функция для добавление адресса в массив Verif
    // Сделать кастомную ошибку если адреса нету в массиве Verif
    // Выаодить на фронтенд кастомную ошибку 
    // Сделать триггер если аднес не зареган для переноса на страницу ввода рефки
    // Если зареган то на главную 
}