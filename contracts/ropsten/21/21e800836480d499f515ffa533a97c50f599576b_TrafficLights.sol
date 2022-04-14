/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.4.16 <0.8.0;

contract TrafficLights {
    uint start; 
    uint afterMin; 
    //перечисление для цветов светофора 
    enum COLOR{GREEN,YELLO,RED}
    address owner; 
    //переменная текущего цвета 
    COLOR public currentColor; 
    //переменная для наглядности цвета 
    string currentColor_; 
    // модификатор для отправителя 
        modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }
    //конструктор 
    constructor() public{
        owner=msg.sender; 
    }
    //установить красный цвет - для всех пользователей 
    function stateRed() public{
        currentColor = COLOR.RED; 
        currentColor_ = "Red"; 
    }
    //установить зеленый - только для owner 
    function stateGreen() public onlyOwner{
        currentColor = COLOR.GREEN; 
        currentColor_ = "Green"; 
    }
    //узнать текущий цвет 
    function checkCurrentColor() public view returns (string memory){
        return currentColor_; 
    }
    // Таймер. Не закончено, нужно сделать автономной 
    function time() public {
        if(block.timestamp>=start + afterMin * 60 seconds){
            currentColor = COLOR.YELLO; 
            currentColor_ = "Yello"; 
        }
    }

}