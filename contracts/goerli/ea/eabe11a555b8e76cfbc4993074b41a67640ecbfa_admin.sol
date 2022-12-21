/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0; // Указываем версию языка - любая, начиная с 0.4.2 до 0.5 не включительно

contract admin {
     // VARIABLES
     struct user {
          address addr;
          string name;  // '$uPeR_p0wner_1999'
          string desc;  // 'CEO & CTO'
     }

     user owner;
     mapping (address => user) adminInfo;
     mapping (address => bool) isAdmin;

     constructor (string memory _name, string memory _desc) {
          owner = user({
               addr : msg.sender, // msg - дефолтная переменная с информацией о пользователе
               name : _name,      // вызвавшем контракт. msg.sender - его адрес
               desc : _desc       // msg.value - сумма в wei, переданная контракту и т.д.
          });

          isAdmin[msg.sender] = true;
          adminInfo[msg.sender] = owner;
     }

// EVENTS
     event adminAdded(address _address, string _name, string _desc);
     event adminRemoved(address _address, string _name, string _desc);
     event moneySend(address _address, uint _amount);

//
     function addAdmin (address  _address, string memory _name, string memory _desc) public {
          if (owner.addr != msg.sender || isAdmin[_address]) revert();    // Только владелец может добавлять / удалять админов

            isAdmin[_address] = true;
            adminInfo[_address] = user({addr : _address, name : _name, desc : _desc});

           emit adminAdded(
             _address,
             _name,
             _desc
           ); // Call event
     }

     function removeAdmin (address _address) public {
          if (owner.addr != msg.sender || !isAdmin[_address]) revert();

          isAdmin[_address] = false;
          emit adminRemoved(
              _address,
              adminInfo[_address].name,
              adminInfo[_address].desc
          ); // Call event
          delete adminInfo[_address];
     }

     function getMoneyOut(address payable _receiver, uint _amount) public {
          if (owner.addr != msg.sender || _amount <= 0 || address(this).balance < _amount) revert();
          // Функцию может вызвать только владелец, требуемая сумма должна быть положительна
          // Последняя проверка - баланс контракта должен быть больше требуемой суммы

          if (_receiver.send(_amount)) 
             emit moneySend(_receiver, _amount); // В случае успеха - вызвать event
     }

     function killContract () public {
          if (owner.addr != msg.sender) revert();
          address payable addr = payable(owner.addr);
          selfdestruct(addr); // Все средства на счету контракта будут переведены на адрес владельца
     }

}