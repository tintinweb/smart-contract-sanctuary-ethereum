/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
contract Registration{
    
  
    address person_address;
    uint Id;
    string _name;
    string _detail;
    address to;
    address from;
   

function setRegister(uint8 personId,string memory name, string memory details) public{
    person_address=msg.sender;
    Id=personId;
    _name=name;
    _detail=details;
}
function getData() public view returns (address,uint) {
    return(person_address,Id);

}
function transfer_property(address _to,address _from) public {
    to=_to;
    from=_from;

}
function getTranster()public view returns(address,address){
    return (to,from);
}

}