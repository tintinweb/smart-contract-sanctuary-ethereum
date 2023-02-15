/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.8; 

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon
contract SimpleStorage {
    // This is initialized to zero. no = sign is 0
     uint256 favoriteNumber; 
     
    mapping(string => uint256) public nametoFavoriteNumber; //mapping
        
        struct People { 
        uint256 favoriteNumber;
        string name;
    }
    // uint256[]<creates array public favoriteNumbersList;
    People[] public people; //array
        
   function store(uint256 _favoriteNumber) public virtual {
         favoriteNumber = _favoriteNumber;
     }    
        
        
        // view, pure do not take gas 
    function retrieve() public view returns (uint256){
        return favoriteNumber;
     }

      function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));   // array
        nametoFavoriteNumber[_name] = _favoriteNumber; // mapping
      }
      
}

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4