/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity >=0.4.16 <0.8.0;

contract Traffic_Light{    
    
    address owner;

    enum color {                
        Red, Green
    }


    constructor() public {           
        owner = msg.sender;
        Color = color.Red;
        TrafficLight[color.Red] = "Red";
        TrafficLight[color.Green] = "Green";
    }

    mapping(color=>string) TrafficLight; 

    color Color;
    
    modifier onlyOwner() {            
        require(msg.sender == owner);   
        _;                                  
    }
    
    function RedColorr() private   { 
        Color = color.Red;      
    }
    
    function GreenColorr() public onlyOwner {   
        Color = color.Green;
    }
    
    function showColor() public view returns(string memory){  
       return  TrafficLight[Color];
    }
}