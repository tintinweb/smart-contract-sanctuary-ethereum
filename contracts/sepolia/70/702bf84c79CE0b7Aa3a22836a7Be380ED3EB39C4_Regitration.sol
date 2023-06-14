/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


error DB_ERROR();
error NotOwner();


contract Regitration {
    address[] public addressVefication;

    address[] public Verif;




    address owner_address = 0x113F3979D7774147D39AB7E097D23b6E5D567D39;

    function push(address i) public onlyOwner {
        Verif.push(i);
    }

    function addresVerification() public {

        for(uint i = 0; i < Verif.length; i++) {
            if (msg.sender != Verif[i]) {
                revert DB_ERROR();
            } else {
                addressVefication.push(msg.sender);
        }
        }
    }

    modifier onlyOwner {

        if (msg.sender != owner_address) {
            revert NotOwner();
        }
        _;
    }



    // Функция для добавление адресса в массив Verif - Ready
    // Сделать кастомную ошибку если адреса нету в массиве Verif
    // Выаодить на фронтенд кастомную ошибку 
    // Сделать триггер если аднес не зареган для переноса на страницу ввода рефки
    // Если зареган то на главную 
}