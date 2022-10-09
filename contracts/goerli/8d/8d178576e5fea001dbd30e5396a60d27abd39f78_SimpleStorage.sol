/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8 ; 

contract SimpleStorage {

    uint256 public favoriteNumber;

    
   
    struct People {
        uint256 favoriteNumber;
     string name;

    } 
    mapping (string => uint256) public nameTofavoriteNumber;
 

 People[] public peo;
function addperson(uint256 _favoriteNumber,string memory _name) public {
    People memory newper = People(_favoriteNumber,_name);
    peo.push(newper);
    nameTofavoriteNumber[_name]=_favoriteNumber;

}

    function store(uint256 _favoriteNumber) public {
                 favoriteNumber = _favoriteNumber;

    


    }
   


    function retrieve() public view returns(uint256){
         return favoriteNumber;

    }
}