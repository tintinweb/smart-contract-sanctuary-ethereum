/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.4.16 <0.8.0;

contract Trafficlight {
    uint start; 
    enum Light{GREEN,YELLOW,RED}
    address owner; 
    Light public Color; 
    string Color_; 
        modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }
    constructor() public{
        owner=msg.sender; 
    }
    function state_red() public{
        Color = Light.RED; 
        Color_ = "Red"; 
    }
    function state_green() public onlyOwner{
        Color = Light.GREEN; 
        Color_ = "Green"; 
    }
    function checklight() public view returns (string memory){
        return Color_; 
    }
    
    function time() public {
        if(block.timestamp >= start + 60 seconds){
            Color = Light.YELLOW; 
            Color_ = "Yellow"; 
        }
    }

}