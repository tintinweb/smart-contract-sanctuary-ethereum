// SPDX-License-Identifier: SimPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
contract SimpleStorage {
    uint myData;
    
    function setMyDatabn(uint newData) public {
        myData = newData;
    }
    
    function getMyDatabn() public view returns(uint) {
        return myData;
    }
}