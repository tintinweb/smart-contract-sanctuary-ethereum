/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity >=0.4.16 <0.8.0; 

/*
Домашнее задание:
1. Разработать смарт-контракт светофор. Сделать функцию изменения света.
 Красный свет может ставить любой пользователь, зеленый только владелец смарт-контракта.
  *(усложнение) Желтый свет должен загораться через 1 минуту после изменения на любой цвет.
*/


contract TrafficLight 
{
  address owner;

  enum Color {red, green}

  mapping(Color=>string) ColorTrafficLight;

  Color color;

  constructor () public {
    owner = msg.sender;
    color = Color.red;
    ColorTrafficLight[Color.red] = "RED";
    ColorTrafficLight[Color.green] = "GREEN";
  }

  modifier onlyOwner() {            
        require(msg.sender == owner);   
        _;                        
  }

  function changeColorToRed() public onlyOwner { 
        color = Color.red;      
    }
    
    function changeColorToGreen() public {   
        color = Color.green;
    }
    
    function showColor() public view returns(string memory) {  
       return  ColorTrafficLight[color];
    }
}