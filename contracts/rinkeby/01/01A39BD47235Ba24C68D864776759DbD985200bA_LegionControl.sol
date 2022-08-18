/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract LegionControl {

 
    function part1Condition(uint256 guess) public pure returns (bool) {
        // Add your code below here
    bool eq = guess == 1; return eq
        // Add your code above here

        ;}

    function part2IfThenElse(uint256 guess) public pure returns (bool) {
        // Add your code below here
        
    bool even;

   
           if(guess == 100)  {even = true
            ;
        }
           
        else   { even = false 
            ;
        }
        return even;
    }

    function part3ForLoop() public pure returns (uint) {
        uint count;
        for (
            // Add your code below here
    uint i=0; i<10; i++
            // Add your code above here
        ) {
            count++;
        }
        return count;
    }

   
    function part4WhileLoop() public pure returns (uint) {
        uint i;
        uint count;
        while (
            // Add your code below here
        i<10
            // Add your code above here
        ) {
            count++;
            i++;
        }
        return count;
    }


}