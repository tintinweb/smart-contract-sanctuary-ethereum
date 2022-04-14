/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.7.0 <0.9.0;
contract trafficLight
{
address owner;
uint public LightsCount = 0;
uint public _start;
uint public _end;
struct Light{
    uint id;
    string color;
}
Light[] public lightBug;
modifier onlyOwner(){
    require(msg.sender==owner);
    _;
}
function waitSome(uint time) public{
    _start = block.timestamp;
    _end = block.timestamp+time;
    while(_start<_end){
        _start=block.timestamp;
    }
}    
constructor() public {
    owner = msg.sender;
} 
function incrementCount() internal{
    LightsCount++;
}
function addLight() public onlyOwner{
  incrementCount();
  lightBug[LightsCount]=Light(LightsCount,"red");
}
function setRed() public {
    lightBug[LightsCount]=Light(LightsCount,"red");
}
function setYellow() public {
    waitSome(60);
    lightBug[LightsCount]=Light(LightsCount,"yellow");
}
function setGreen() public onlyOwner{
    lightBug[LightsCount]=Light(LightsCount,"green");
}
function showColor() public view
            returns (string memory color)
    {
        return (lightBug[LightsCount].color);
    }
}