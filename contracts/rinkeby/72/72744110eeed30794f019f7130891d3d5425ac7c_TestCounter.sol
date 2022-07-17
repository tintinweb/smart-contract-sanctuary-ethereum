/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestCounter {
    int private count = 0;
    int public steps=1;
    address private owner;

    function stepcount(int _step) public{

        if(_step<= 100 && _step >= -100   ){

            if( _step != 0){

               steps=_step;
            }
        }

        

    }

    function initialcounter(int k)public{
        count=k;
    }
    function increment() public {
        count += steps;
    }
    function decrement() public {
        count -= steps;
    }

    function viewcount() public view returns (int) {
        return count;
    }


    function reset()public {
        count=0;
    }

    function reset(int n )public {
        count=n;
    }

    

 function getOwner(
    ) public view returns (address) {    
        return owner;
    }

}