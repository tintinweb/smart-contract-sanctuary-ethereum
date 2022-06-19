// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Greeter {
  string greet;

  function setGreet(string memory _greet) public { // записываем в память, 
  //так как это аргумент и существует до тех пор пока эта функция работает
  //как только мы выходим из функции - значение теряется
    greet = _greet; //установка сообщения. так как мы это присваиваем, то greet хранится в блокчейне
  }

  function getGreet() public view returns(string memory) {
    return greet;
  }
}