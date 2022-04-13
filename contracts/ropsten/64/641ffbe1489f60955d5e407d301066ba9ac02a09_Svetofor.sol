/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity >=0.8.0;

contract Svetofor{    
    
    address owner;

    enum color {                /* указываем ограниченные значения, которые будем использовать, те 2 цвета */
        RED, GREEN
    }

    mapping(color=>string) TrafficLight; /* преобразуем свет в буквы */

    color Color;

    constructor() public {           /* собираем конструктор для инициализации контракта */
        owner = msg.sender;
        Color = color.RED;
        TrafficLight[color.RED] = "RedLight";
        TrafficLight[color.GREEN] = "GreenLight";
    }
    
    modifier onlyOwner() {            
        require(msg.sender == owner);   /* модификатор для проверки того, что функция может быть вызвана и выполнена только создателем */
        _;                                  /*объединяем код функции с кодом модификатора. */
    }
    
    function changeColorToRed() private   { /* функция смены цвета на красный */
        Color = color.RED;      
    }
    
    function changeColorToGreen() public onlyOwner {   /* функция смены цвета на зеленый */
        Color = color.GREEN;
    }
    
    function showColor() public view returns(string memory){  /* функция,показывающая цвет светофора */
       return  TrafficLight[Color];
    }
}