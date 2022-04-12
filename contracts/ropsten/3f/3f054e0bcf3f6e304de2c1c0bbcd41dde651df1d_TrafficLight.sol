/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity <=0.8.0;

contract TrafficLight {

    address owner;

    uint startTime;

    enum Color {
        RED, YELLOW, GREEN
    }

    mapping (Color=>string) colorToStringMap;

    Color color;

    constructor() public {
        owner = msg.sender;
        color = Color.RED;
        colorToStringMap[Color.RED] = "red";
        colorToStringMap[Color.YELLOW] = "yellow";
        colorToStringMap[Color.GREEN] = "green";
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     modifier timeout() {
        require(block.timestamp - startTime >= 5 seconds);
        _;
    }

    function changeColorToRed() public   {
        color = Color.RED;      
        startTime = block.timestamp;
    }


    function changeColorToYellow() private {
        color = Color.YELLOW;
    }

    function changeColorToGreen() public onlyOwner {
        color = Color.GREEN;
        startTime = block.timestamp;
    }

    function showColor() public view returns(string memory){

        if(block.timestamp - startTime >= 60 seconds) {
            return "yellow";
        }

        return  colorToStringMap[color];
    }
}