/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity >=0.8.0;

contract SVvetofor{    
    
    address owner;

    enum Color {               
        RED, GREEN
    }

    mapping(Color=>string) Svetofor; 

    Color color;

    constructor() public {           
        owner = msg.sender;
        color = Color.RED;
        Svetofor[Color.RED] = " RED ";
        Svetofor[Color.GREEN] = "  GREEN";
    }
    
    modifier onlyOwner() {            
        require(msg.sender == owner);  
        _;                                  
    }
    
    function changeColorToRed() public   { 
        color = Color.RED;      
    }
    
    function changeColorToGreen() public onlyOwner {   
        color = Color.GREEN;
    }
    
    function showColor() public view returns(string memory){  
       return  Svetofor[color];
    }
}