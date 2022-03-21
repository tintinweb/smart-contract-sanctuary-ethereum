/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// // SPDX-License-Identifier: MIT

// pragma solidity 0.5.0;
    
// contract Raffle {
//   uint randNonce = 0;
//         uint[] rands;
//     function random() public{
//       // return block.timestamp;
//       // return uint(keccak256(block.difficulty, block.timestamp));
//       // randNonce = randNonce + 1;

//       for (uint i=0; i<6; i++) {
//         rands.push(i);
//       }
//       return rands;

//       // return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 13;
//       // return keccak256(abi.encodePacked(block.difficulty, block.timestamp, 0xea86d6Fd6F55bA94ec84e2f6e12c281e8F2D6286));
//     }
// }

pragma solidity ^0.5.0;  
   
// Creating a contract 
contract Types {  
  
    // Defining the array
    uint[] data; 
    
    // Defining the function to push 
    // values to the array
    event Display(uint[]);
    function array_push(
    ) public returns(uint[] memory){  

      

    for (uint i=0; i<6; i++) {
        data.push(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % 13);
      }
    
        // data.push(60);  
        // data.push(70);  
        // data.push(80);
    
    emit Display(data);
        return data;  
    }  
}