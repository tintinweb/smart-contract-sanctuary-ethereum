/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

/*
1. Разработать смарт-контракт светофор. 
Сделать функцию изменения света.
Красный свет может ставить любой пользователь, зеленый только владелец смарт-контракта. 
*(усложнение) Желтый свет должен загораться через 1 минуту после изменения на любой цвет.
*/


pragma solidity >=0.4.16 < 0.8.0;
//Создания блока контракта
contract TrafficLight{
/*
    struct ColorLights{
        string G;
        string R;
        string Y;
    }
*/
    address owner;
    string ActColor  = "Yellow";
    uint time;
    constructor() public 
    {
    owner = msg.sender;
    }
    function setYellow() internal {

        if(block.timestamp - time >= 60 seconds) {
            ActColor = "Yellow";
        }

    }
    modifier onlyOwner(){
    require(msg.sender == owner);
    _;
    }
    function setRed(string memory wordForSetRed) public {
        ActColor = "Red";
        time = block.timestamp;
    }
    function setGreen(string memory wordForSetGreen) public onlyOwner {
        ActColor = "Green";
        time = block.timestamp;
    }
    function showColor() public view returns (string) {
        return (ActColor);
        
    }








}