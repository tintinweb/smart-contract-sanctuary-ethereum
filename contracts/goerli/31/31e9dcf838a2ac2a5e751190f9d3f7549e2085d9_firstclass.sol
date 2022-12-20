/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract firstclass {

    string count = "";
    
  

    
    function my_function() public view returns(string memory){
        return count; 
    }
    function my_function1(string memory txt) public {
        count = string.concat(count,txt); 
    }
  
}