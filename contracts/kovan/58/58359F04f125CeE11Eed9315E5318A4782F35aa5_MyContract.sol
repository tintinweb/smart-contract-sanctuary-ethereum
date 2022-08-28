/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

///SDPX-License-Identifier : MIT 
pragma solidity ^0.8.0;
contract MyContract{

string sname;
uint stemp;
uint soxygen;
uint spulse;



constructor(string memory name,uint temp ,uint oxygen, uint pulse){
    require(temp>0, "body temperature greater zero ");
    sname = name;
    stemp = temp;
    soxygen = oxygen;
    spulse = pulse;

}

function Temp() public view returns(uint temp){
    return stemp;
}
function Name() public view returns(string memory name){
    return sname;
}
function Oxygen() public view returns(uint oxygen){
    return soxygen;
}
function Pulse() public view returns(uint pulse){
    return spulse;
}

}