/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: MIT




pragma solidity 0.8.15; 


contract Counter {
    int public count = -2; 


    function increment() public {

        count += 1;
    }

    function getCount() public view returns(int) {

          return count;
    }

    function decrement() public {
        count -= 1;
    }



}