/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract LocationContract {
    struct Location  {     
       string date;
       string  longitude;
       string latitude;
       string label;
       
    }
   
    Location[] public locations;     
function AddLocation(string memory _date, string memory _longitude, string memory  _latitude, string memory _label) public{

  locations.push(Location(_date, _longitude,_latitude, _label));

}


function findIndex(string memory _label) public view returns (uint) {
        for (uint i = 0; i < locations.length; i++) {
            if (keccak256(abi.encodePacked(locations[i].label)) == (keccak256(abi.encodePacked(_label)))) {                
                return i;
            }
        }
        revert("Label not found");
    }
function GetLabel(string memory _label) public view returns (string memory, string memory, string memory, string memory) {
        uint index = findIndex(_label);
        return (locations[index].date, locations[index].longitude, locations[index].latitude, locations[index].label);
    }
 
 function GetAllLocations() public view returns (Location[] memory) {
        return locations;
       
     }

}