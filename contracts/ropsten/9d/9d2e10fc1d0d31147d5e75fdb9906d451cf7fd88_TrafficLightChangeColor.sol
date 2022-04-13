/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity >=0.4.16 <0.8.0;

contract TrafficLightChangeColor{

address owner;
string color;


constructor () public {
    owner = msg.sender;
}

modifier OnlyOwner(){
    require(msg.sender == owner);
    _;
    }

function ChangeColorToRed() public {
    color = "Red";
}


function ChangeColorToGreen() public OnlyOwner {
    color = "Green";
}


function show() public view returns (string memory){
    return(color); 
    }

}